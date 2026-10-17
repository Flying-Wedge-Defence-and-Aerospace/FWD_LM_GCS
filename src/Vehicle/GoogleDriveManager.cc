/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "GoogleDriveManager.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "GoogleDriveSettings.h"
#include "Fact.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QHttpMultiPart>
#include <QHttpPart>
#include <QAbstractOAuth>
#include <QAbstractOAuth2>
#include <QOAuth2AuthorizationCodeFlow>
#include <QOAuthHttpServerReplyHandler>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QFileInfo>
#include <QUrl>
#include <QUrlQuery>
#include <QDesktopServices>
#include <QSettings>
#include <QDateTime>
#include <QQmlEngine>

QGC_LOGGING_CATEGORY(GoogleDriveManagerLog, "GoogleDriveManagerLog")

static const char* kAuthorizationUrl  = "https://accounts.google.com/o/oauth2/v2/auth";
static const char* kAccessTokenUrl    = "https://oauth2.googleapis.com/token";
static const char* kDriveScope        = "https://www.googleapis.com/auth/drive.file";
static const char* kDriveApiBase      = "https://www.googleapis.com/drive/v3";
static const char* kDriveUploadBase   = "https://www.googleapis.com/upload/drive/v3/files";
static const char* kSettingsGroupKey  = "GoogleDrive";

// Hardcoded Google OAuth 2.0 "Desktop app" client + target folder. These are
// baked into the build so no configuration UI is required.
static const char* kClientId          = "615132916263-n67kdju3i6835rdotnvnm4ulpht4t6qk.apps.googleusercontent.com";
static const char* kClientSecret      = "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";
static const char* kFolderName        = "FWD LM GCS Logs";
// Obfuscated baked-in refresh token for the dedicated Drive account
// (flyingwedge26@gmail.com). Plain-text never appears in the binary; instead
// two fragments are recombined, base64-decoded and XOR-masked at runtime using
// kPayloadKey. This only slows down casual reverse engineering (root dump still
// defeats it). Replace both fragments via tools/seal_gdrive_token.py if rotating.
static const char*     kPayloadPartA = "IA0cdDIlRtvqY9/8m+u8xlJFag0UNDbJ3kLr6IKqqNJdG3o2DD8u46FVwMm+vomLWUR9Ig==";
static const char*     kPayloadPartB = "G18jzqgy7oqIr6rGTmt3fXgyGuX3Q/rQg4movUV0dBI3Fhzhqnbmz6u2u7BCZEsybTwU";
static const quint8     kPayloadKey[32] = {
    0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
    0x99, 0x00, 0xaa, 0xbb, 0xcc, 0xdd, 0xee,0xff,
    0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
    0x99, 0x00, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff
};

//-----------------------------------------------------------------------------
GoogleDriveManager::GoogleDriveManager(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
{
}

//-----------------------------------------------------------------------------
GoogleDriveManager::~GoogleDriveManager()
{
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);

    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
    qmlRegisterUncreatableType<GoogleDriveManager>("QGroundControl.GoogleDriveManager", 1, 0, "GoogleDriveManager", "Reference only");

    _setupOAuth();
    _loadTokens();

    emit credentialsConfiguredChanged();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_setupOAuth()
{
    _nam = new QNetworkAccessManager(this);

    _oauth = new QOAuth2AuthorizationCodeFlow(_nam, this);
    _oauth->setAuthorizationUrl(QUrl(kAuthorizationUrl));
    _oauth->setAccessTokenUrl(QUrl(kAccessTokenUrl));
    _oauth->setScope(kDriveScope);
    _oauth->setClientIdentifier(kClientId);
    _oauth->setClientIdentifierSharedKey(kClientSecret);

    // Request an offline refresh token and force the consent screen so a refresh
    // token is always issued (Google only returns one on the first consent).
    _oauth->setModifyParametersFunction([](QAbstractOAuth::Stage stage, QVariantMap* parameters) {
        if (stage == QAbstractOAuth::Stage::RequestingAuthorization) {
            (*parameters)["access_type"] = "offline";
            (*parameters)["prompt"]      = "consent";
        }
    });

    _replyHandler = new QOAuthHttpServerReplyHandler(this);
    _oauth->setReplyHandler(_replyHandler);

    connect(_oauth, &QAbstractOAuth::authorizeWithBrowser, this, [](const QUrl& url) {
        QDesktopServices::openUrl(url);
    });
    connect(_oauth, &QOAuth2AuthorizationCodeFlow::granted, this, &GoogleDriveManager::_onTokenUpdated);
    connect(_oauth, &QAbstractOAuth2::tokenChanged,          this, &GoogleDriveManager::_onTokenUpdated);
    connect(_oauth, &QAbstractOAuth2::error,                 this, &GoogleDriveManager::_oauthError);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_loadTokens()
{
    _loadingTokens = true;

    QSettings settings;
    settings.beginGroup(kSettingsGroupKey);
    const QString token        = settings.value("accessToken", "").toString();
    const QString refreshToken = settings.value("refreshToken", "").toString();
    _expiresAt                 = settings.value("expiresAt").toDateTime();
    settings.endGroup();

    QString bootToken = refreshToken;
    if (bootToken.isEmpty()) {
        bootToken = _unsealBakedRefreshToken();
        qCDebug(GoogleDriveManagerLog) << "No persisted refresh token, using baked credential";
    }

    _oauth->setToken(token);
    _oauth->setRefreshToken(bootToken);
    // Treat any non-empty refresh token as linked (even without a fresh access token)
    _linked = !token.isEmpty() || !bootToken.isEmpty();

    _loadingTokens = false;

    if (_linked) {
        _setStatus(tr("Connected to Google Drive"));
        emit linkedChanged();
        if (_oauth->token().isEmpty() || _tokenNeedsRefresh()) {
            // Silently obtain a fresh access token from the stored refresh token.
            // This avoids prompting the user to sign in again.
            qCDebug(GoogleDriveManagerLog) << "Refreshing stored/baked Google Drive session";
            _oauth->refreshAccessToken();
        } else {
            _fetchAccountEmail();
        }
    } else {
        qCWarning(GoogleDriveManagerLog) << "Google Drive refresh token unavailable after baked unseal";
        _setStatus(tr("Google Drive not provisioned"));
    }
}

//-----------------------------------------------------------------------------
QString
GoogleDriveManager::_unsealBakedRefreshToken()
{
    QByteArray raw = QByteArray::fromBase64(kPayloadPartA)
                   + QByteArray::fromBase64(kPayloadPartB);
    for (int i = 0; i < raw.size(); ++i)
        raw[i] = static_cast<char>(raw.at(i) ^ kPayloadKey[i % 32]);
    return QString::fromUtf8(raw);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_saveTokens()
{
    QSettings settings;
    settings.beginGroup(kSettingsGroupKey);
    settings.setValue("accessToken",  _oauth->token());
    // Only persist the server-minted access/refresh token. If empty, keep the
    // baked token implicit on next boot.
    settings.setValue("refreshToken", _oauth->refreshToken().isEmpty()
                                        ? _unsealBakedRefreshToken()
                                        : _oauth->refreshToken());
    settings.setValue("expiresAt",    _expiresAt);
    settings.endGroup();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_clearTokens()
{
    QSettings settings;
    settings.beginGroup(kSettingsGroupKey);
    settings.remove(QString());
    settings.endGroup();
}

//-----------------------------------------------------------------------------
bool
GoogleDriveManager::credentialsConfigured() const
{
    return qstrlen(kClientId) > 0 && qstrlen(kClientSecret) > 0;
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::link()
{
    if (!credentialsConfigured()) {
        _setError(tr("Google OAuth client ID/secret are not configured."));
        return;
    }

    _setError(QString());
    _setStatus(tr("Opening browser for Google sign-in..."));
    qCDebug(GoogleDriveManagerLog) << "Starting Google Drive authorization flow";
    _oauth->grant();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::signOut()
{
    _abortActiveReply();
    _queue.clear();
    emit pendingCountChanged();

    _oauth->setToken(QString());
    _oauth->setRefreshToken(QString());
    _clearTokens();

    _linked = false;
    _accountEmail.clear();
    emit linkedChanged();
    emit accountEmailChanged();

    _setStatus(tr("Signed out of Google Drive"));
    qCDebug(GoogleDriveManagerLog) << "Signed out of Google Drive";
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::uploadFile(const QString& filePath)
{
    if (!_enabled()) {
        _setError(tr("Google Drive upload is disabled in Application Settings > Google Drive."));
        return;
    }
    if (!_linked && _oauth->refreshToken().isEmpty()) {
        _setError(tr("Google Drive is not linked. Sign in first."));
        return;
    }
    _enqueue(filePath);
    _startNextUpload();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::onLogDownloadCompleted(const QString& filePath)
{
    if (!_enabled() || !_autoUpload()) {
        return;
    }
    if (!_linked && _oauth->refreshToken().isEmpty()) {
        qCWarning(GoogleDriveManagerLog) << "Downloaded log cannot be auto-uploaded, Google Drive not linked:" << filePath;
        return;
    }
    qCDebug(GoogleDriveManagerLog) << "Auto-uploading downloaded log to Google Drive:" << filePath;
    _enqueue(filePath);
    _startNextUpload();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::cancel()
{
    _abortActiveReply();
    _queue.clear();
    emit pendingCountChanged();

    _uploading = false;
    _progress  = 0.0;
    _waitingForToken = false;
    emit uploadingChanged();
    emit progressChanged();

    _setStatus(tr("Google Drive upload cancelled"));
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_enqueue(const QString& filePath)
{
    if (filePath.isEmpty()) {
        return;
    }
    if (_queue.contains(filePath) || filePath == _currentFile) {
        return;
    }
    _queue.append(filePath);
    emit pendingCountChanged();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_startNextUpload()
{
    if (_uploading) {
        return;
    }
    if (_queue.isEmpty()) {
        _progress = 0.0;
        emit progressChanged();
        return;
    }

    if (_oauth->token().isEmpty() || _tokenNeedsRefresh()) {
        if (!_oauth->refreshToken().isEmpty()) {
            _waitingForToken = true;
            _setStatus(tr("Refreshing Google Drive session..."));
            _oauth->refreshAccessToken();
            return;
        } else if (_oauth->token().isEmpty()) {
            _queue.clear();
            emit pendingCountChanged();
            _setError(tr("Google Drive is not linked. Sign in first."));
            return;
        }
    }

    _currentFile = _queue.first();
    _currentName = QFileInfo(_currentFile).fileName();

    _uploading = true;
    _progress  = 0.0;
    emit uploadingChanged();
    emit progressChanged();

    _resolveFolder();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_resolveFolder()
{
    if (!_folderId.isEmpty()) {
        _beginUpload();
        return;
    }

    QUrl url(QString("%1/files").arg(kDriveApiBase));
    QUrlQuery query;
    query.addQueryItem("q", QString("name='%1' and mimeType='application/vnd.google-apps.folder' and trashed=false")
                                 .arg(QString(_folderName()).replace("'", "\\'")));
    query.addQueryItem("spaces", "drive");
    query.addQueryItem("fields", "files(id,name)");
    url.setQuery(query);

    _setStatus(tr("Locating Google Drive folder..."));
    QNetworkReply* reply = _oauth->get(url);
    _activeReply = reply;
    connect(reply, &QNetworkReply::finished, this, &GoogleDriveManager::_folderLookupFinished);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_folderLookupFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        _finishCurrent(false, tr("Folder lookup failed"));
        return;
    }
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        _finishCurrent(false, tr("Folder lookup failed: %1").arg(reply->errorString()));
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(reply->readAll()).object();
    const QJsonArray  files = root.value("files").toArray();
    qCDebug(GoogleDriveManagerLog) << "Folder lookup returned" << files.size() << "match(es) for" << _folderName();
    if (!files.isEmpty()) {
        _folderId = files.first().toObject().value("id").toString();
    }

    if (!_folderId.isEmpty()) {
        _beginUpload();
    } else {
        _createFolder();
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_createFolder()
{
    QUrl url(QString("%1/files").arg(kDriveApiBase));

    QJsonObject metadata;
    metadata["name"]     = _folderName();
    metadata["mimeType"] = "application/vnd.google-apps.folder";

    _setStatus(tr("Creating Google Drive folder..."));
    qCDebug(GoogleDriveManagerLog) << "Creating Google Drive folder" << _folderName();

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(QStringLiteral("application/json")));
    request.setRawHeader("Authorization", QByteArrayLiteral("Bearer ") + _oauth->token().toUtf8());
    QNetworkReply* reply = _oauth->networkAccessManager()->post(request, QJsonDocument(metadata).toJson(QJsonDocument::Compact));
    _activeReply = reply;
    connect(reply, &QNetworkReply::finished, this, &GoogleDriveManager::_folderCreateFinished);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_folderCreateFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        _finishCurrent(false, tr("Folder creation failed"));
        return;
    }
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        _finishCurrent(false, tr("Folder creation failed: %1").arg(reply->errorString()));
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(reply->readAll()).object();
    _folderId = root.value("id").toString();
    qCDebug(GoogleDriveManagerLog) << "Created Google Drive folder" << _folderName() << "id" << _folderId;
    if (_folderId.isEmpty()) {
        _finishCurrent(false, tr("Folder creation failed"));
        return;
    }

    _beginUpload();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_beginUpload()
{
    if (_currentFile.isEmpty()) {
        _finishCurrent(false, tr("No file to upload"));
        return;
    }

    QFileInfo fi(_currentFile);
    if (!fi.exists()) {
        _finishCurrent(false, tr("File not found: %1").arg(_currentFile));
        return;
    }

    QFile* file = new QFile(_currentFile);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        _finishCurrent(false, tr("Unable to open file: %1").arg(_currentFile));
        return;
    }

    QHttpMultiPart* multiPart = new QHttpMultiPart(QHttpMultiPart::RelatedType);

    QJsonObject metadata;
    metadata["name"] = _currentName;
    QJsonArray parents;
    parents.append(_folderId);
    metadata["parents"] = parents;

    QHttpPart metadataPart;
    metadataPart.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json; charset=UTF-8"));
    metadataPart.setBody(QJsonDocument(metadata).toJson(QJsonDocument::Compact));
    multiPart->append(metadataPart);

    QHttpPart filePart;
    filePart.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
    filePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                       QString("form-data; name=\"file\"; filename=\"%1\"").arg(_currentName));
    filePart.setBodyDevice(file);
    multiPart->append(filePart);
    file->setParent(multiPart);

    QUrl url(QString("%1?uploadType=multipart").arg(kDriveUploadBase));
    _setStatus(tr("Uploading %1...").arg(_currentName));
    qCDebug(GoogleDriveManagerLog) << "Uploading" << _currentFile << "to folder" << _folderId;

    multiPart->setContentType(QHttpMultiPart::RelatedType);
    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QByteArrayLiteral("Bearer ") + _oauth->token().toUtf8());
    QNetworkReply* reply = _oauth->networkAccessManager()->post(request, multiPart);
    multiPart->setParent(reply);
    _activeReply = reply;

    connect(reply, &QNetworkReply::uploadProgress, this, &GoogleDriveManager::_uploadProgress);
    connect(reply, &QNetworkReply::finished,       this, &GoogleDriveManager::_uploadFinished);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_uploadProgress(qint64 bytesSent, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        _progress = static_cast<qreal>(bytesSent) / static_cast<qreal>(bytesTotal);
        emit progressChanged();
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_uploadFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }

    const int      httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QByteArray data     = reply->readAll();
    const QString  errorStr   = reply->errorString();
    const bool     ok         = (reply->error() == QNetworkReply::NoError) && (httpStatus == 200 || httpStatus == 201);
    reply->deleteLater();

    if (ok) {
        _finishCurrent(true, tr("Uploaded %1 to Google Drive").arg(_currentName));
    } else {
        const QString detail = QString::fromUtf8(data).left(200);
        _finishCurrent(false, tr("Upload failed (%1): %2 %3").arg(httpStatus).arg(errorStr).arg(detail));
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_finishCurrent(bool success, const QString& message)
{
    const QString filePath = _currentFile;

    if (!_queue.isEmpty() && _queue.first() == _currentFile) {
        _queue.removeFirst();
    } else {
        _queue.removeAll(_currentFile);
    }
    emit pendingCountChanged();

    _uploading = false;
    _progress  = 0.0;
    emit uploadingChanged();
    emit progressChanged();

    if (success) {
        _setStatus(message);
        qCDebug(GoogleDriveManagerLog) << message;
    } else {
        _setError(message);
        qCWarning(GoogleDriveManagerLog) << message;
    }

    if (!filePath.isEmpty()) {
        emit uploadCompleted(filePath, success, message);
    }

    _currentFile.clear();
    _currentName.clear();

    _startNextUpload();
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_abortActiveReply()
{
    if (_activeReply) {
        QNetworkReply* reply = _activeReply.data();
        _activeReply = nullptr;
        disconnect(reply, nullptr, this, nullptr);
        reply->abort();
        reply->deleteLater();
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_fetchAccountEmail()
{
    QUrl url(QString("%1/about").arg(kDriveApiBase));
    QUrlQuery query;
    query.addQueryItem("fields", "user(emailAddress,displayName)");
    url.setQuery(query);

    QNetworkReply* reply = _oauth->get(url);
    connect(reply, &QNetworkReply::finished, this, &GoogleDriveManager::_aboutFinished);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_aboutFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qCDebug(GoogleDriveManagerLog) << "Google Drive account lookup failed:" << reply->errorString();
        return;
    }

    const QJsonObject root = QJsonDocument::fromJson(reply->readAll()).object();
    const QJsonObject user = root.value("user").toObject();
    const QString email    = user.value("emailAddress").toString();
    if (!email.isEmpty() && email != _accountEmail) {
        _accountEmail = email;
        emit accountEmailChanged();
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_onTokenUpdated()
{
    if (_loadingTokens) {
        return;
    }

    const bool wasLinked = _linked;
    _linked    = !_oauth->token().isEmpty();
    _expiresAt = _oauth->expirationAt();
    _saveTokens();

    if (_linked) {
        if (!wasLinked) {
            _setStatus(tr("Connected to Google Drive"));
            emit linkedChanged();
        }
        if (_accountEmail.isEmpty()) {
            _fetchAccountEmail();
        }
    }

    if (_waitingForToken) {
        _waitingForToken = false;
        _startNextUpload();
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_oauthError(const QString& error, const QString& errorDescription, const QUrl& uri)
{
    Q_UNUSED(uri);
    qCWarning(GoogleDriveManagerLog) << "OAuth error:" << error << errorDescription;
    _setError(tr("Google authorization error: %1").arg(errorDescription.isEmpty() ? error : errorDescription));

    if (_waitingForToken) {
        _waitingForToken = false;
        if (_uploading) {
            _finishCurrent(false, tr("Google Drive session could not be refreshed"));
        }
    }
}

//-----------------------------------------------------------------------------
bool
GoogleDriveManager::_tokenNeedsRefresh() const
{
    if (_oauth->token().isEmpty()) {
        return true;
    }
    if (_expiresAt.isValid()) {
        return QDateTime::currentDateTime().secsTo(_expiresAt) < 60;
    }
    return false;
}

//-----------------------------------------------------------------------------
bool
GoogleDriveManager::_enabled() const
{
    return true;
}

//-----------------------------------------------------------------------------
bool
GoogleDriveManager::_autoUpload() const
{
    return true;
}

//-----------------------------------------------------------------------------
QString
GoogleDriveManager::_folderName() const
{
    return QString(kFolderName);
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_setStatus(const QString& text)
{
    if (_statusText != text) {
        _statusText = text;
        emit statusTextChanged();
    }
}

//-----------------------------------------------------------------------------
void
GoogleDriveManager::_setError(const QString& text)
{
    if (_lastError != text) {
        _lastError = text;
        emit lastErrorChanged();
    }
}
