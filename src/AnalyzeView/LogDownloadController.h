/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#ifndef LogDownloadController_H
#define LogDownloadController_H

#include <QObject>
#include <QTimer>
#include <QAbstractListModel>
#include <QLocale>
#include <QElapsedTimer>

#include <memory>

#include "UASInterface.h"
#include "AutoPilotPlugin.h"
#include "QGCToolbox.h"

class  MultiVehicleManager;
class  UASInterface;
class  Vehicle;
class  QGCLogEntry;
struct LogDownloadData;

Q_DECLARE_LOGGING_CATEGORY(LogDownloadLog)

//-----------------------------------------------------------------------------
class QGCLogModel : public QAbstractListModel
{
    Q_OBJECT
public:

    enum QGCLogModelRoles {
        ObjectRole = Qt::UserRole + 1
    };

    QGCLogModel(QObject *parent = nullptr);

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_INVOKABLE QGCLogEntry* get(int index);

    int         count           (void) const;
    void        append          (QGCLogEntry* entry);
    void        clear           (void);
    QGCLogEntry*operator[]      (int i);

    int         rowCount        (const QModelIndex & parent = QModelIndex()) const;
    QVariant    data            (const QModelIndex & index, int role = Qt::DisplayRole) const;

signals:
    void        countChanged    ();

protected:
    QHash<int, QByteArray> roleNames() const;
private:
    QList<QGCLogEntry*> _logEntries;
};

//-----------------------------------------------------------------------------
class QGCLogEntry : public QObject {
    Q_OBJECT
    Q_PROPERTY(uint         id          READ id                             CONSTANT)
    Q_PROPERTY(QDateTime    time        READ time                           NOTIFY timeChanged)
    Q_PROPERTY(uint         size        READ size                           NOTIFY sizeChanged)
    Q_PROPERTY(QString      sizeStr     READ sizeStr                        NOTIFY sizeChanged)
    Q_PROPERTY(bool         received    READ received                       NOTIFY receivedChanged)
    Q_PROPERTY(bool         selected    READ selected   WRITE setSelected   NOTIFY selectedChanged)
    Q_PROPERTY(QString      status      READ status                         NOTIFY statusChanged)

public:
    QGCLogEntry(uint logId, const QDateTime& dateTime = QDateTime(), uint logSize = 0, bool received = false);

    uint        id          () const { return _logID; }
    uint        size        () const { return _logSize; }
    QString     sizeStr     () const;
    QDateTime   time        () const { return _logTimeUTC; }
    bool        received    () const { return _received; }
    bool        selected    () const { return _selected; }
    QString     status      () const { return _status; }

    void        setId       (uint id_)          { _logID = id_; }
    void        setSize     (uint size_)        { _logSize = size_;     emit sizeChanged(); }
    void        setTime     (QDateTime date_)   { _logTimeUTC = date_;  emit timeChanged(); }
    void        setReceived (bool rec_)         { _received = rec_;     emit receivedChanged(); }
    void        setSelected (bool sel_)         { _selected = sel_;     emit selectedChanged(); }
    void        setStatus   (QString stat_)     { _status = stat_;      emit statusChanged(); }

signals:
    void        idChanged       ();
    void        timeChanged     ();
    void        sizeChanged     ();
    void        receivedChanged ();
    void        selectedChanged ();
    void        statusChanged   ();

private:
    uint        _logID;
    uint        _logSize;
    QDateTime   _logTimeUTC;
    bool        _received;
    bool        _selected;
    QString     _status;
};

//-----------------------------------------------------------------------------
class LogDownloadController : public QGCTool
{
    Q_OBJECT

public:
    LogDownloadController(QGCApplication* app, QGCToolbox* toolbox);

    // Overrides from QGCTool
    void setToolbox(QGCToolbox* toolbox) override;

    Q_PROPERTY(QGCLogModel* model           READ model              NOTIFY modelChanged)
    Q_PROPERTY(bool         requestingList  READ requestingList     NOTIFY requestingListChanged)
    Q_PROPERTY(bool         downloadingLogs READ downloadingLogs    NOTIFY downloadingLogsChanged)
    Q_PROPERTY(bool         autoDownloadActive READ autoDownloadActive NOTIFY autoDownloadActiveChanged)

    QGCLogModel*    model                   () { return &_logEntriesModel; }
    bool            requestingList          () const{ return _requestingLogEntries; }
    bool            downloadingLogs         () const{ return _downloadingLogs; }
    bool            autoDownloadActive      () const{ return _autoMode; }

    Q_INVOKABLE void refresh                ();
    Q_INVOKABLE void download               (QString path = QString());
    Q_INVOKABLE void eraseAll               ();
    Q_INVOKABLE void cancel                 ();
    Q_INVOKABLE QVariantList telemetryLogFiles();

    void downloadToDirectory(const QString& dir);

signals:
    void requestingListChanged  ();
    void downloadingLogsChanged ();
    void modelChanged           ();
    void selectionChanged       ();
    void autoDownloadActiveChanged ();
    void autoDownloadFinished   (int downloaded, int failed, int skipped);

    /// Emitted when an onboard log file has been fully downloaded to disk.
    /// @param filePath Absolute path of the downloaded log file.
    void logDownloadCompleted   (const QString& filePath);

private slots:
    void _setActiveVehicle  (Vehicle* vehicle);
    void _logEntry          (UASInterface *uas, uint32_t time_utc, uint32_t size, uint16_t id, uint16_t num_logs, uint16_t last_log_num);
    void _logData           (UASInterface *uas, uint32_t ofs, uint16_t id, uint8_t count, const uint8_t *data);
    void _processDownload   ();
    void _vehicleInitialConnectComplete ();
    void _vehicleArmedChanged           (bool armed);
    void _autoActiveCheckTimeout        ();
    void _ftpDownloadComplete           (const QString& file, const QString& errorMsg);
    void _ftpDownloadProgress           (float value);

private:
    bool _entriesComplete   ();
    bool _chunkComplete     () const;
    bool _logComplete       () const;
    void _findMissingEntries();
    void _receivedAllEntries();
    void _listingComplete   ();
    void _receivedAllData   ();
    void _resetSelection    (bool canceled = false);
    void _findMissingData   ();
    void _requestNextDataSpan();
    void _requestLogList    (uint32_t start, uint32_t end);
    void _requestLogData    (uint16_t id, uint32_t offset, uint32_t count, int retryCount = 0);
    bool _prepareLogDownload();
    void _setDownloading    (bool active);
    void _setListing        (bool active);
    void _updateDataRate    ();
    void _updateCommunicationLostEnabled ();
    uint32_t _currentRequestSize() const;
    void _abortCurrentLogDownload();

    // FTP based fast download support
    bool _ftpLogDownloadSupported () const;
    bool _startFtpDownload        ();
    bool _startFtpCandidate       ();
    void _ftpDownloadFailed       ();
    void _startLegacyDownload     ();
    void _cancelFtpDownload       ();

    // Auto download support
    bool    _autoDownloadEnabled     () const;
    void    _maybeStartAutoDownload  ();
    void    _autoSelectAndDownload   ();
    void    _cancelAutoDownload      ();
    QString _dedupeGroup             () const;
    QString _logFingerprint          (const QGCLogEntry* entry) const;
    bool    _isLogAlreadyDownloaded  (const QGCLogEntry* entry) const;
    void    _markLogDownloaded       (const QGCLogEntry* entry, const QString& filePath);

    QGCLogEntry* _getNextSelected();

    UASInterface*       _uas;
    LogDownloadData*    _downloadData;
    QTimer              _timer;
    QGCLogModel         _logEntriesModel;
    Vehicle*            _vehicle;
    bool                _requestingLogEntries;
    bool                _downloadingLogs;
    int                 _retries;
    int                 _apmOneBased;
    QString             _downloadPath;

    // Auto download / robustness
    bool                _autoMode;
    int                 _autoDownloadedCount;
    int                 _autoFailedCount;
    int                 _autoSkippedCount;
    bool                _autoStabilityCheck;
    uint16_t            _autoNewestId;
    uint32_t            _autoNewestSize;
    QTimer              _autoStabilityTimer;
    QElapsedTimer       _progressTimer;
    uint32_t            _requestSize;
    uint32_t            _lastReqOffset;             ///< Offset of the last legacy LOG_REQUEST_DATA burst
    uint32_t            _lastReqCount;              ///< Size of the last legacy LOG_REQUEST_DATA burst
    QElapsedTimer       _lastReqTimer;              ///< Time of the last legacy LOG_REQUEST_DATA burst

    // FTP based fast download state
    bool                _ftpActive;
    QStringList         _ftpCandidateUris;      ///< Candidate FTP URIs for the current entry (tried in order)
    int                 _ftpCandidateIndex;     ///< Index into _ftpCandidateUris currently in flight
    qreal               _ftpMaxProgress;        ///< Highest progress fraction seen for the in-flight FTP transfer
    QElapsedTimer       _ftpProgressTimer;      ///< Time since the FTP progress fraction last increased
};

#endif
