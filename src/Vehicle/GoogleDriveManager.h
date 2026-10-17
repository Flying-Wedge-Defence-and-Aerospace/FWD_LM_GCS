/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QDateTime>
#include <QPointer>

#include "QGCLoggingCategory.h"
#include "QGCToolbox.h"

class QNetworkAccessManager;
class QNetworkReply;
class QOAuth2AuthorizationCodeFlow;
class QOAuthHttpServerReplyHandler;

Q_DECLARE_LOGGING_CATEGORY(GoogleDriveManagerLog)

/// Manages Google Drive authentication (OAuth 2.0) and uploading of onboard
/// vehicle log files to a Google Drive folder.
///
/// The OAuth 2.0 client ID/secret are read from GoogleDriveSettings. They must be
/// provisioned from a Google Cloud "Desktop app" OAuth client. Until real
/// credentials are configured the feature stays inert.
class GoogleDriveManager : public QGCTool
{
    Q_OBJECT

public:
    GoogleDriveManager(QGCApplication* app, QGCToolbox* toolbox);
    ~GoogleDriveManager() override;

    Q_PROPERTY(bool     linked          READ linked         NOTIFY linkedChanged)
    Q_PROPERTY(bool     uploading       READ uploading      NOTIFY uploadingChanged)
    Q_PROPERTY(qreal    progress        READ progress       NOTIFY progressChanged)
    Q_PROPERTY(QString  statusText      READ statusText     NOTIFY statusTextChanged)
    Q_PROPERTY(QString  lastError       READ lastError      NOTIFY lastErrorChanged)
    Q_PROPERTY(int      pendingCount    READ pendingCount   NOTIFY pendingCountChanged)
    Q_PROPERTY(QString  accountEmail    READ accountEmail   NOTIFY accountEmailChanged)
    Q_PROPERTY(bool     credentialsConfigured READ credentialsConfigured NOTIFY credentialsConfiguredChanged)

    bool        linked                  () const { return _linked; }
    bool        uploading               () const { return _uploading; }
    qreal       progress                () const { return _progress; }
    QString     statusText              () const { return _statusText; }
    QString     lastError               () const { return _lastError; }
    int         pendingCount            () const { return _queue.count(); }
    QString     accountEmail            () const { return _accountEmail; }
    bool        credentialsConfigured   () const;

    /// Starts the interactive OAuth 2.0 authorization flow (opens the system browser).
    Q_INVOKABLE void link();
    /// Revokes local tokens and forgets the linked account.
    Q_INVOKABLE void signOut();
    /// Queue a single log file for upload to Google Drive.
    Q_INVOKABLE void uploadFile(const QString& filePath);
    /// Abort the current upload and clear the queue.
    Q_INVOKABLE void cancel();

    // Override from QGCTool
    void setToolbox(QGCToolbox* toolbox) override;

public slots:
    /// Connected to LogDownloadController::logDownloadCompleted
    void onLogDownloadCompleted(const QString& filePath);

signals:
    void linkedChanged();
    void uploadingChanged();
    void progressChanged();
    void statusTextChanged();
    void lastErrorChanged();
    void pendingCountChanged();
    void accountEmailChanged();
    void credentialsConfiguredChanged();
    void uploadCompleted(const QString& filePath, bool success, const QString& message);

private slots:
    void _onTokenUpdated();
    void _oauthError(const QString& error, const QString& errorDescription, const QUrl& uri);
    void _folderLookupFinished();
    void _folderCreateFinished();
    void _aboutFinished();
    void _uploadFinished();
    void _uploadProgress(qint64 bytesSent, qint64 bytesTotal);

private:
    void    _setupOAuth();
    void    _loadTokens();
    void    _saveTokens();
    void    _clearTokens();
    void    _setStatus(const QString& text);
    void    _setError(const QString& text);
    void    _enqueue(const QString& filePath);
    void    _startNextUpload();
    void    _resolveFolder();
    void    _createFolder();
    void    _beginUpload();
    void    _finishCurrent(bool success, const QString& message);
    void    _abortActiveReply();
    void    _fetchAccountEmail();
    bool    _tokenNeedsRefresh() const;
    bool    _enabled() const;
    bool    _autoUpload() const;
    QString _folderName() const;
    static QString _unsealBakedRefreshToken();

    QOAuth2AuthorizationCodeFlow*   _oauth          = nullptr;
    QOAuthHttpServerReplyHandler*   _replyHandler   = nullptr;
    QNetworkAccessManager*          _nam            = nullptr;

    bool    _linked         = false;
    bool    _uploading      = false;
    bool    _waitingForToken = false;
    bool    _loadingTokens  = false;
    qreal   _progress       = 0.0;
    QString _statusText;
    QString _lastError;
    QString _accountEmail;
    QStringList _queue;
    QDateTime _expiresAt;

    QString                 _folderId;
    QString                 _currentFile;
    QString                 _currentName;
    QPointer<QNetworkReply> _activeReply;
};
