/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#include "LogDownloadController.h"
#include "MultiVehicleManager.h"
#include "QGCMAVLink.h"
#include "UAS.h"
#include "QGCApplication.h"
#include "QGCToolbox.h"
#include "QGCMapEngine.h"
#include "ParameterManager.h"
#include "Vehicle.h"
#include "FTPManager.h"
#include "SettingsManager.h"
#include "AppSettings.h"

#include <QDebug>
#include <QSettings>
#include <QUrl>
#include <QBitArray>
#include <QDir>
#include <QFileInfo>
#include <QtCore/qmath.h>
#include <algorithm>

#define kTimeOutMilliseconds 2000
#define kGUIRateMilliseconds 250
#define kTableBins           512
#define kChunkSize           (kTableBins * MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN)
// Request block cap used for over-the-air legacy downloads. 512 bins (46 KB) is
// Wi-Fi friendly but floods weak radio links; send modest bursts instead.
#define kLegacyRequestBins    512
#define kLegacyRequestBytes  (kLegacyRequestBins * MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN)
// Maximum time with no download progress before an entry is aborted (watchdog)
#define kDownloadTimeoutMilliseconds 30000
// How often the download watchdog is polled while a transfer is active
#define kWatchdogPollMilliseconds    5000
// Maximum time an FTP transfer may show no *new* progress before it is treated as stalled
// and handed off to the legacy protocol. FTPManager re-writes missing blocks and emits
// commandProgress for those retransmits, which must not keep a dead transfer alive.
#define kFtpStallMilliseconds        20000
// Minimum interval between identical legacy LOG_REQUEST_DATA bursts. Out-of-order / duplicate
// LOG_DATA packets otherwise re-trigger the same request several times a second, flooding both
// the radio link and the main thread without making progress.
#define kMinRequestIntervalMilliseconds 1000
// Floor for the adaptive per-request size used on lossy links
#define kMinRequestSize      (MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN * 32)
// Interval used to confirm whether the newest log is still being written (size growing)
#define kActiveLogCheckMilliseconds 4000

QGC_LOGGING_CATEGORY(LogDownloadLog, "LogDownloadLog")

//-----------------------------------------------------------------------------
struct LogDownloadData {
    LogDownloadData(QGCLogEntry* entry);
    QBitArray     chunk_table;
    uint32_t      current_chunk;
    QFile         file;
    QString       filename;
    uint          ID;
    QGCLogEntry*  entry;
    uint          written;
    size_t        rate_bytes;
    qreal         rate_avg;
    QElapsedTimer elapsed;
    // Set when an FTP transfer for this entry failed and we should retry the same entry
    // using the legacy chunked protocol instead.
    bool          legacyFallback;
    // Byte range of the most recent legacy LOG_REQUEST_DATA burst. Used to chain the next
    // request as soon as the current burst's last packet arrives instead of waiting for the
    // retry timeout (which otherwise caps throughput to one burst per timeout interval).
    uint32_t      reqStart;
    uint32_t      reqEnd;

    void advanceChunk()
    {
           current_chunk++;
           chunk_table = QBitArray(chunkBins(), false);
    }

    // The number of MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN bins in the current chunk
    uint32_t chunkBins() const
    {
        return qMin(qCeil((entry->size() - current_chunk*kChunkSize)/static_cast<qreal>(MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN)),
                    kTableBins);
    }

    // The number of kChunkSize chunks in the file
    uint32_t numChunks() const
    {
        return qCeil(entry->size() / static_cast<qreal>(kChunkSize));
    }

    // True if all bins in the chunk have been set to val
    bool chunkEquals(const bool val) const
    {
        return chunk_table == QBitArray(chunk_table.size(), val);
    }

};

//----------------------------------------------------------------------------------------
LogDownloadData::LogDownloadData(QGCLogEntry* entry_)
    : ID(entry_->id())
    , entry(entry_)
    , written(0)
    , rate_bytes(0)
    , rate_avg(0)
    , legacyFallback(false)
    , reqStart(0)
    , reqEnd(0)
{

}

//----------------------------------------------------------------------------------------
QGCLogEntry::QGCLogEntry(uint logId, const QDateTime& dateTime, uint logSize, bool received)
    : _logID(logId)
    , _logSize(logSize)
    , _logTimeUTC(dateTime)
    , _received(received)
    , _selected(false)
{
    _status = tr("Pending");
}

//----------------------------------------------------------------------------------------
QString
QGCLogEntry::sizeStr() const
{
    return QGCMapEngine::bigSizeToString(_logSize);
}

//----------------------------------------------------------------------------------------
LogDownloadController::LogDownloadController(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
    , _uas(nullptr)
    , _downloadData(nullptr)
    , _vehicle(nullptr)
    , _requestingLogEntries(false)
    , _downloadingLogs(false)
    , _retries(0)
    , _apmOneBased(0)
    , _autoMode(false)
    , _autoDownloadedCount(0)
    , _autoFailedCount(0)
    , _autoSkippedCount(0)
    , _autoStabilityCheck(false)
    , _autoNewestId(0)
    , _autoNewestSize(0)
    , _requestSize(kLegacyRequestBytes)
    , _lastReqOffset(0)
    , _lastReqCount(0)
    , _ftpActive(false)
    , _ftpCandidateIndex(0)
    , _ftpMaxProgress(0)
{
    connect(&_timer, &QTimer::timeout, this, &LogDownloadController::_processDownload);
    connect(&_autoStabilityTimer, &QTimer::timeout, this, &LogDownloadController::_autoActiveCheckTimeout);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);
    MultiVehicleManager *manager = toolbox->multiVehicleManager();
    connect(manager, &MultiVehicleManager::activeVehicleChanged, this, &LogDownloadController::_setActiveVehicle);
    _setActiveVehicle(manager->activeVehicle());
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_processDownload()
{
    if(_requestingLogEntries) {
        _findMissingEntries();
    } else if(_downloadingLogs) {
        if (_ftpActive) {
            // FTP reports progress explicitly. Treat a lack of *new* progress as a stall so a
            // transfer that only keeps re-writing missing blocks is handed to the legacy protocol.
            if (!_ftpProgressTimer.isValid() || _ftpProgressTimer.elapsed() > kFtpStallMilliseconds) {
                qWarning() << "FTP log download stalled (no progress) for entry" << (_downloadData ? _downloadData->ID : 0);
                _cancelFtpDownload();
                _ftpDownloadFailed();
            } else {
                _timer.start(kWatchdogPollMilliseconds);
            }
        } else if (_downloadData && _progressTimer.isValid() && _progressTimer.elapsed() > kDownloadTimeoutMilliseconds) {
            // Watchdog: if no bytes have been received within the timeout, abort this entry
            qWarning() << "Log download timed out (no progress) for entry" << _downloadData->ID;
            _downloadData->entry->setStatus(tr("Timed out"));
            if (_autoMode) {
                _autoFailedCount++;
            }
            _abortCurrentLogDownload();
        } else {
            _findMissingData();
        }
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_setActiveVehicle(Vehicle* vehicle)
{
    //-- Abort any transfer in progress; it no longer belongs to a valid vehicle
    if (_downloadingLogs || _requestingLogEntries || _downloadData) {
        _cancelFtpDownload();
        _timer.stop();
        _autoStabilityTimer.stop();
        delete _downloadData;
        _downloadData = nullptr;
        _requestingLogEntries = false;
        _downloadingLogs = false;
        _autoMode = false;
        _autoStabilityCheck = false;
        emit requestingListChanged();
        emit downloadingLogsChanged();
        emit autoDownloadActiveChanged();
    }

    if(_uas) {
        _logEntriesModel.clear();
        disconnect(_uas, &UASInterface::logEntry, this, &LogDownloadController::_logEntry);
        disconnect(_uas, &UASInterface::logData,  this, &LogDownloadController::_logData);
        _uas = nullptr;
    }
    if (_vehicle) {
        disconnect(_vehicle, &Vehicle::initialConnectComplete, this, &LogDownloadController::_vehicleInitialConnectComplete);
        disconnect(_vehicle, &Vehicle::armedChanged,            this, &LogDownloadController::_vehicleArmedChanged);
        if (_vehicle->ftpManager()) {
            disconnect(_vehicle->ftpManager(), nullptr, this, nullptr);
        }
    }
    _vehicle = vehicle;
    if(_vehicle) {
        _uas = vehicle->uas();
        connect(_uas, &UASInterface::logEntry, this, &LogDownloadController::_logEntry);
        connect(_uas, &UASInterface::logData,  this, &LogDownloadController::_logData);
        connect(_vehicle, &Vehicle::initialConnectComplete, this, &LogDownloadController::_vehicleInitialConnectComplete);
        connect(_vehicle, &Vehicle::armedChanged,            this, &LogDownloadController::_vehicleArmedChanged);
        if (_vehicle->ftpManager()) {
            connect(_vehicle->ftpManager(), &FTPManager::downloadComplete, this, &LogDownloadController::_ftpDownloadComplete);
            connect(_vehicle->ftpManager(), &FTPManager::commandProgress,  this, &LogDownloadController::_ftpDownloadProgress);
        }
        // Vehicle may already be connected when it becomes active
        if (_vehicle->isInitialConnectComplete()) {
            _maybeStartAutoDownload();
        }
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_vehicleInitialConnectComplete()
{
    _maybeStartAutoDownload();
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_vehicleArmedChanged(bool armed)
{
    // Safety: never run an automatic download while the vehicle is armed
    if (armed && _autoMode) {
        qCDebug(LogDownloadLog) << "Vehicle armed, aborting automatic log download";
        _cancelAutoDownload();
    }
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_autoDownloadEnabled() const
{
    return false;
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_maybeStartAutoDownload()
{
    if (!_vehicle || !_uas) {
        return;
    }
    if (!_autoDownloadEnabled()) {
        return;
    }
    if (_vehicle->armed()) {
        return;
    }
    if (_requestingLogEntries || _downloadingLogs) {
        return;
    }
    qCDebug(LogDownloadLog) << "Starting automatic onboard log download";
    _autoMode = true;
    _autoDownloadedCount = 0;
    _autoFailedCount = 0;
    _autoSkippedCount = 0;
    _autoStabilityCheck = false;
    _autoStabilityTimer.stop();
    emit autoDownloadActiveChanged();
    refresh();
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_autoSelectAndDownload()
{
    const int num_logs = _logEntriesModel.count();
    if (num_logs == 0) {
        qCDebug(LogDownloadLog) << "No onboard logs to download";
        _autoMode = false;
        emit autoDownloadActiveChanged();
        emit autoDownloadFinished(0, 0, 0);
        return;
    }

    // The newest log may still be open (being written by the vehicle). LOG_* messages only
    // download completed logs and there is no explicit "open" flag in LOG_ENTRY, so confirm
    // the newest log has stopped growing before deciding to download it. This means a vehicle
    // with a single finalized log still gets it downloaded, while a log that is actively
    // growing is skipped and picked up on a later connect.
    QGCLogEntry* newestEntry = _logEntriesModel[num_logs - 1];

    if (newestEntry && !_autoStabilityCheck && !_isLogAlreadyDownloaded(newestEntry)) {
        _autoStabilityCheck = true;
        _autoNewestId       = newestEntry->id();
        _autoNewestSize     = newestEntry->size();
        qCDebug(LogDownloadLog) << "Auto download: checking whether newest log" << _autoNewestId << "is still being written";
        _autoStabilityTimer.start(kActiveLogCheckMilliseconds);
        return;
    }

    bool newestIsActive = false;
    if (_autoStabilityCheck && newestEntry && newestEntry->id() == _autoNewestId) {
        newestIsActive = (newestEntry->size() != _autoNewestSize);
        if (newestIsActive) {
            qCDebug(LogDownloadLog) << "Newest log" << _autoNewestId << "is still being written, skipping";
        }
    }

    int selected = 0;
    for (int i = 0; i < num_logs; i++) {
        QGCLogEntry* entry = _logEntriesModel[i];
        if (!entry) {
            continue;
        }
        // Skip empty entries
        if (entry->size() == 0) {
            _autoSkippedCount++;
            continue;
        }
        // Skip the newest log only if it is still being written
        if (newestIsActive && entry->id() == _autoNewestId) {
            entry->setStatus(tr("Active"));
            _autoSkippedCount++;
            continue;
        }
        // Skip logs we have already downloaded on a previous connect
        if (_isLogAlreadyDownloaded(entry)) {
            entry->setStatus(tr("Already downloaded"));
            _autoSkippedCount++;
            continue;
        }
        entry->setSelected(true);
        selected++;
    }

    if (selected == 0) {
        qCDebug(LogDownloadLog) << "No new onboard logs to download";
        _autoMode = false;
        emit autoDownloadActiveChanged();
        emit autoDownloadFinished(0, 0, _autoSkippedCount);
        return;
    }

    qCDebug(LogDownloadLog) << "Auto downloading" << selected << "new onboard log(s)";
    emit selectionChanged();
    downloadToDirectory(qgcApp()->toolbox()->settingsManager()->appSettings()->logSavePath());
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_autoActiveCheckTimeout()
{
    if (!_autoMode || !_vehicle || !_uas) {
        return;
    }
    // Re-request the log list (without clearing) so we can compare the newest log's size
    qCDebug(LogDownloadLog) << "Auto download: re-listing to confirm newest log stability";
    _requestLogList(0, 49);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_cancelAutoDownload()
{
    if (!_autoMode) {
        return;
    }
    _timer.stop();
    _autoStabilityTimer.stop();
    _cancelFtpDownload();
    if (_downloadData) {
        if (_downloadData->file.exists()) {
            _downloadData->file.remove();
        }
        delete _downloadData;
        _downloadData = nullptr;
    }
    _resetSelection(true);
    _setDownloading(false);
    _setListing(false);
    _autoMode = false;
    emit autoDownloadActiveChanged();
}

//----------------------------------------------------------------------------------------
QString
LogDownloadController::_dedupeGroup() const
{
    if (!_vehicle) {
        return QString();
    }
    const quint64 uid = _vehicle->vehicleUID();
    if (uid != 0) {
        return QStringLiteral("AutoLogDownload/%1").arg(uid);
    }
    return QStringLiteral("AutoLogDownload/sys_%1_cmp_%2")
            .arg(_vehicle->id())
            .arg(_vehicle->defaultComponentId());
}

//----------------------------------------------------------------------------------------
QString
LogDownloadController::_logFingerprint(const QGCLogEntry* entry) const
{
    // id + UTC time + size uniquely identifies a log for a given vehicle
    return QStringLiteral("%1_%2_%3")
            .arg(entry->id())
            .arg(entry->time().toUTC().toString(Qt::ISODate))
            .arg(entry->size());
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_isLogAlreadyDownloaded(const QGCLogEntry* entry) const
{
    QSettings settings;
    settings.beginGroup(_dedupeGroup());
    const QString filePath = settings.value(_logFingerprint(entry)).toString();
    settings.endGroup();
    return !filePath.isEmpty() && QFileInfo::exists(filePath);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_markLogDownloaded(const QGCLogEntry* entry, const QString& filePath)
{
    QSettings settings;
    settings.beginGroup(_dedupeGroup());
    settings.setValue(_logFingerprint(entry), filePath);
    settings.endGroup();

    emit logDownloadCompleted(filePath);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_logEntry(UASInterface* uas, uint32_t time_utc, uint32_t size, uint16_t id, uint16_t num_logs, uint16_t /*last_log_num*/)
{
    //-- Do we care?
    if(!_uas || uas != _uas || !_requestingLogEntries) {
        return;
    }
    //-- If this is the first, pre-fill it
    if(!_logEntriesModel.count() && num_logs > 0) {
        //-- Is this APM? They send a first entry with bogus ID and only the
        //   count is valid. From now on, all entries are 1-based.
        if(_vehicle->firmwareType() == MAV_AUTOPILOT_ARDUPILOTMEGA) {
            _apmOneBased = 1;
        }
        for(int i = 0; i < num_logs; i++) {
            QGCLogEntry *entry = new QGCLogEntry(i);
            _logEntriesModel.append(entry);
        }
    }
    //-- Update this log record
    if(num_logs > 0) {
        //-- Skip if empty (APM first packet)
        if(size || _vehicle->firmwareType() != MAV_AUTOPILOT_ARDUPILOTMEGA) {
            id -= _apmOneBased;
            if(id < _logEntriesModel.count()) {
                QGCLogEntry* entry = _logEntriesModel[id];
                entry->setSize(size);
                entry->setTime(QDateTime::fromSecsSinceEpoch(time_utc));
                entry->setReceived(true);
                entry->setStatus(tr("Available"));
            } else {
                qWarning() << "Received log entry for out-of-bound index:" << id;
            }
        }
    } else {
        //-- No logs to list
        _listingComplete();
    }
    //-- Reset retry count
    _retries = 0;
    //-- Do we have it all?
    if(_entriesComplete()) {
        _listingComplete();
    } else {
        //-- Reset timer
        _timer.start(kTimeOutMilliseconds);
    }
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_entriesComplete()
{
    //-- Iterate entries and look for a gap
    int num_logs = _logEntriesModel.count();
    for(int i = 0; i < num_logs; i++) {
        QGCLogEntry* entry = _logEntriesModel[i];
        if(entry) {
            if(!entry->received()) {
               return false;
            }
        }
    }
    return true;
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_resetSelection(bool canceled)
{
    int num_logs = _logEntriesModel.count();
    for(int i = 0; i < num_logs; i++) {
        QGCLogEntry* entry = _logEntriesModel[i];
        if(entry) {
            if(entry->selected()) {
                if(canceled) {
                    entry->setStatus(tr("Canceled"));
                }
                entry->setSelected(false);
            }
        }
    }
    emit selectionChanged();
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_receivedAllEntries()
{
    _timer.stop();
    _setListing(false);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_listingComplete()
{
    _receivedAllEntries();
    // If this listing was started automatically, pick up any new logs and download them
    if (_autoMode) {
        _autoSelectAndDownload();
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_findMissingEntries()
{
    int start = -1;
    int end   = -1;
    int num_logs = _logEntriesModel.count();
    //-- Iterate entries and look for a gap
    for(int i = 0; i < num_logs; i++) {
        QGCLogEntry* entry = _logEntriesModel[i];
        if(entry) {
            if(!entry->received()) {
                if(start < 0)
                    start = i;
                else
                    end = i;
            } else {
                if(start >= 0) {
                    break;
                }
            }
        }
    }
    //-- Is there something missing?
    if(start >= 0) {
        //-- Have we tried too many times?
        if(_retries++ > 2) {
            for(int i = 0; i < num_logs; i++) {
                QGCLogEntry* entry = _logEntriesModel[i];
                if(entry && !entry->received()) {
                    entry->setStatus(tr("Error"));
                }
            }
            //-- Give up
            _receivedAllEntries();
            qWarning() << "Too many errors retreiving log list. Giving up.";
            if (_autoMode) {
                _cancelAutoDownload();
            }
            return;
        }
        //-- Is it a sequence or just one entry?
        if(end < 0) {
            end = start;
        }
        //-- APM "Fix"
        start += _apmOneBased;
        end   += _apmOneBased;
        //-- Request these entries again
        _requestLogList((uint32_t)start, (uint32_t) end);
    } else {
        _listingComplete();
    }
}

void LogDownloadController::_updateDataRate(void)
{
    if (_downloadData->elapsed.elapsed() >= kGUIRateMilliseconds) {
        //-- Update download rate
        qreal rrate = _downloadData->rate_bytes / (_downloadData->elapsed.elapsed() / 1000.0);
        _downloadData->rate_avg = (_downloadData->rate_avg * 0.95) + (rrate * 0.05);
        _downloadData->rate_bytes = 0;

        //-- Update status
        const QString status = QString("%1 (%2/s)").arg(QGCMapEngine::bigSizeToString(_downloadData->written),
                                                        QGCMapEngine::bigSizeToString(_downloadData->rate_avg));

        _downloadData->entry->setStatus(status);
        _downloadData->elapsed.start();
    }
}


//----------------------------------------------------------------------------------------
void
LogDownloadController::_logData(UASInterface* uas, uint32_t ofs, uint16_t id, uint8_t count, const uint8_t* data)
{
    if(!_uas || uas != _uas || !_downloadData) {
        return;
    }
    //-- APM "Fix"
    id -= _apmOneBased;
    if(_downloadData->ID != id) {
        qWarning() << "Received log data for wrong log";
        return;
    }

    if ((ofs % MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN) != 0) {
        qWarning() << "Ignored misaligned incoming packet @" << ofs;
        return;
    }

    bool result = false;
    uint32_t timeout_time = kTimeOutMilliseconds;
    if(ofs < _downloadData->entry->size()) {
        const uint32_t chunk = ofs / kChunkSize;
        if (chunk != _downloadData->current_chunk) {
            qWarning() << "Ignored packet for out of order chunk actual:expected" << chunk << _downloadData->current_chunk;
            return;
        }
        const uint16_t bin = (ofs - chunk*kChunkSize) / MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN;
        const bool inRange = bin < _downloadData->chunk_table.size();
        const bool duplicate = inRange && _downloadData->chunk_table.testBit(bin);
        if (!inRange) {
            qWarning() << "Out of range bin received";
        } else if (!duplicate) {
            _downloadData->chunk_table.setBit(bin);
        }

        // Clamp to the declared file size so a stray/oversized packet cannot grow the file
        const uint32_t writeLen = qMin<uint32_t>(count, _downloadData->entry->size() - ofs);

        if (_downloadData->file.pos() != ofs) {
            // Seek to correct position
            if (!_downloadData->file.seek(ofs)) {
                qWarning() << "Error while seeking log file offset";
                return;
            }
        }

        //-- Write chunk to file
        if(_downloadData->file.write((const char*)data, writeLen)) {
            //-- Only count newly received bytes; retransmitted/duplicate packets must not
            //   inflate the progress total past the actual file size.
            if (!duplicate) {
                _downloadData->written += writeLen;
                _downloadData->rate_bytes += writeLen;
                //-- reset retries only for genuinely new data; duplicate/retransmitted packets
                //   must not keep resetting the retry counter or a stuck gap never gives up.
                _retries = 0;
            }
            _updateDataRate();
            result = true;
            //-- Track progress for watchdog
            _progressTimer.restart();
            //-- Restore the adaptive request size on success so a single lossy
            //   span doesn't hold the whole transfer at the minimum chunk size.
            if (_requestSize < kChunkSize) {
                _requestSize = qMin(static_cast<uint32_t>(kLegacyRequestBytes), _requestSize * 2);
            }
            //-- Reset timer
            _timer.start(timeout_time);
            //-- Only make new requests based on genuinely new data. Acting on duplicate/
            //   retransmitted packets re-issues the same request and creates a request storm.
            if (duplicate) {
                return;
            }
            //-- Do we have it all?
            if(_logComplete()) {
                _downloadData->entry->setStatus(tr("Downloaded"));
                _markLogDownloaded(_downloadData->entry, _downloadData->file.fileName());
                if (_autoMode) {
                    _autoDownloadedCount++;
                }
                //-- Check for more
                _receivedAllData();
            } else if (_chunkComplete()) {
                _downloadData->advanceChunk();
                _retries = 0;
                _requestSize = kLegacyRequestBytes;
                _requestLogData(_downloadData->ID,
                                _downloadData->current_chunk*kChunkSize,
                                _currentRequestSize());
            } else if (ofs < _downloadData->reqEnd && ofs + count >= _downloadData->reqEnd) {
                //-- Current burst fully received: immediately request the next span so the link
                //   stays saturated instead of idling until the retry timeout fires. The
                //   `ofs < reqEnd` guard ensures out-of-order packets (whose offset
                //   lies beyond a short gap-fill request) don't trigger a request storm.
                _requestNextDataSpan();
            } else if (bin < _downloadData->chunk_table.size() - 1 && _downloadData->chunk_table.at(bin+1)) {
                // Likely to be grabbing fragments and got to the end of a gap
                _findMissingData();
            }
        } else {
            qWarning() << "Error while writing log file chunk";
        }
    } else {
        qWarning() << "Received log offset greater than expected";
    }
    if(!result) {
        _downloadData->entry->setStatus(tr("Error"));
        if (_autoMode) {
            _autoFailedCount++;
        }
        // Write/seek failure (e.g. disk full): stop chasing this entry instead of retrying forever
        _abortCurrentLogDownload();
    }
}


//----------------------------------------------------------------------------------------
bool
LogDownloadController::_chunkComplete() const
{
    return _downloadData->chunkEquals(true);
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_logComplete() const
{
    return _chunkComplete() && (_downloadData->current_chunk+1) == _downloadData->numChunks();
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_receivedAllData()
{
    _timer.stop();
    //-- Anything queued up for download?
    if(_prepareLogDownload()) {
        //-- Use the legacy chunked protocol as the primary transfer. It is request/response
        //   (flow-controlled by the request size) and retries whole spans, so it degrades
        //   gracefully on lossy/constrained radio links. The FTP burst-read floods such links,
        //   loses large contiguous regions and then re-reads them one 239-byte block per
        //   round-trip (FTPManager::_fillMissingBlocks), which is dramatically slower and
        //   causes a confusing progress reset when it falls back. FTP remains available as a
        //   fast path for clean links via _startFtpDownload when explicitly requested.
        _startLegacyDownload();
    } else {
        _resetSelection();
        _setDownloading(false);
        if (_autoMode) {
            const int downloaded = _autoDownloadedCount;
            const int failed     = _autoFailedCount;
            const int skipped    = _autoSkippedCount;
            _autoMode = false;
            emit autoDownloadActiveChanged();
            emit autoDownloadFinished(downloaded, failed, skipped);
        }
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_abortCurrentLogDownload()
{
    _cancelFtpDownload();
    if (_downloadData) {
        if (_downloadData->file.exists()) {
            _downloadData->file.remove();
        }
        delete _downloadData;
        _downloadData = nullptr;
    }
    // Move on to the next selected log (or finish)
    _receivedAllData();
}

//----------------------------------------------------------------------------------------
uint32_t
LogDownloadController::_currentRequestSize() const
{
    if (!_downloadData) {
        return _requestSize;
    }
    // Never request more than the current chunk holds
    const uint32_t chunkBytes = _downloadData->chunk_table.size() * MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN;
    return qMin(_requestSize, chunkBytes);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_findMissingData()
{
    if (_logComplete()) {
         _receivedAllData();
         return;
    } else if (_chunkComplete()) {
        _downloadData->advanceChunk();
    }

    _retries++;
    //-- Give up after sustained silence on a gap instead of hammering it forever
    if (_retries >= 15) {
        qWarning() << "Log download retry limit reached for entry" << _downloadData->ID;
        if (_downloadData && _downloadData->entry) {
            _downloadData->entry->setStatus(tr("Timed out"));
        }
        _abortCurrentLogDownload();
        return;
    }
    //-- Adaptive request size: shrink on retries so lossy/incomplete responses are less likely
    if (_retries > 0 && _requestSize > kMinRequestSize) {
        _requestSize = qMax<uint32_t>(kMinRequestSize, _requestSize / 2);
    }
#if 0
    // Trying the change to infinite log download. This way if retries hit 100% failure the data rate will
    // slowly fall to 0 and the user can Cancel. This should work better on really crappy links.
    if(_retries > 5) {
        _downloadData->entry->setStatus(tr("Timed Out"));
        //-- Give up
        qWarning() << "Too many errors retreiving log data. Giving up.";
        _receivedAllData();
        return;
    }
#endif

    _updateDataRate();

    uint16_t start = 0, end = 0;
    const int size = _downloadData->chunk_table.size();
    for (; start < size; start++) {
        if (!_downloadData->chunk_table.testBit(start)) {
            break;
        }
    }

    for (end = start; end < size; end++) {
        if (_downloadData->chunk_table.testBit(end)) {
            break;
        }
    }

    const uint32_t pos = _downloadData->current_chunk*kChunkSize + start*MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN;
    const uint32_t len = qMin(static_cast<uint32_t>((end - start)*MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN), _currentRequestSize());
    _requestLogData(_downloadData->ID, pos, len, _retries);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_requestNextDataSpan()
{
    //-- Request the next span of missing data immediately, without counting it as a retry.
    //   This keeps the legacy download flowing back-to-back rather than one burst per timeout.
    if (!_downloadData) {
        return;
    }

    uint16_t start = 0, end = 0;
    const int size = _downloadData->chunk_table.size();

    for (; start < size; start++) {
        if (!_downloadData->chunk_table.testBit(start)) {
            break;
        }
    }

    if (start >= size) {
        //-- Chunk is actually complete now: advance and keep going
        _downloadData->advanceChunk();
        _retries = 0;
        _requestSize = kLegacyRequestBytes;
        _requestLogData(_downloadData->ID,
                        _downloadData->current_chunk*kChunkSize,
                        _currentRequestSize());
        return;
    }

    for (end = start; end < size; end++) {
        if (_downloadData->chunk_table.testBit(end)) {
            break;
        }
    }

    const uint32_t pos = _downloadData->current_chunk*kChunkSize + start*MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN;
    const uint32_t len = qMin(static_cast<uint32_t>((end - start)*MAVLINK_MSG_LOG_DATA_FIELD_DATA_LEN), _currentRequestSize());
    _requestLogData(_downloadData->ID, pos, len, _retries);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_requestLogData(uint16_t id, uint32_t offset, uint32_t count, int retryCount)
{
    //-- Drop an identical request fired again too soon after the previous one. Duplicate/out-of-
    //   order packets otherwise re-issue the same burst many times per second, which floods the
    //   link and starves the data we are actually waiting for.
    if (offset == _lastReqOffset && count == _lastReqCount &&
        _lastReqTimer.isValid() && _lastReqTimer.elapsed() < kMinRequestIntervalMilliseconds) {
        return;
    }

    if (_vehicle) {
        WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();
        if (!weakLink.expired()) {
            SharedLinkInterfacePtr sharedLink = weakLink.lock();

            //-- APM "Fix"
            id += _apmOneBased;
            _lastReqOffset = offset;
            _lastReqCount  = count;
            _lastReqTimer.restart();
            qCDebug(LogDownloadLog) << "Request log data (id:" << id << "offset:" << offset << "size:" << count << "retryCount" << retryCount << ")";
            if (_downloadData) {
                _downloadData->reqStart = offset;
                _downloadData->reqEnd   = offset + count;
            }
            mavlink_message_t msg;
            mavlink_msg_log_request_data_pack_chan(
                        qgcApp()->toolbox()->mavlinkProtocol()->getSystemId(),
                        qgcApp()->toolbox()->mavlinkProtocol()->getComponentId(),
                        sharedLink->mavlinkChannel(),
                        &msg,
                        _vehicle->id(), _vehicle->defaultComponentId(),
                        id, offset, count);
            _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
        }
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::refresh(void)
{
    _logEntriesModel.clear();
    //-- Get first 50 entries
    _requestLogList(0, 49);
}

//----------------------------------------------------------------------------------------
QVariantList
LogDownloadController::telemetryLogFiles(void)
{
    QVariantList list;

    const QString dirPath = qgcApp()->toolbox()->settingsManager()->appSettings()->telemetrySavePath();
    if (dirPath.isEmpty()) {
        return list;
    }

    QDir dir(dirPath);
    if (!dir.exists()) {
        return list;
    }

    QFileInfoList files = dir.entryInfoList(QStringList() << QStringLiteral("*.tlog"), QDir::Files, QDir::Time);
    std::sort(files.begin(), files.end(), [](const QFileInfo& a, const QFileInfo& b) {
        return a.lastModified() > b.lastModified();
    });

    for (const QFileInfo& fileInfo : files) {
        QVariantMap entry;
        entry.insert(QStringLiteral("name"), fileInfo.fileName());
        entry.insert(QStringLiteral("path"), fileInfo.absoluteFilePath());
        entry.insert(QStringLiteral("date"), fileInfo.lastModified());
        entry.insert(QStringLiteral("size"), static_cast<qulonglong>(fileInfo.size()));
        list.append(entry);
    }

    return list;
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_requestLogList(uint32_t start, uint32_t end)
{
    if(_vehicle && _uas) {
        qCDebug(LogDownloadLog) << "Request log entry list (" << start << "through" << end << ")";
        _setListing(true);
        WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();
        if (!weakLink.expired()) {
            SharedLinkInterfacePtr sharedLink = weakLink.lock();

            mavlink_message_t msg;
            mavlink_msg_log_request_list_pack_chan(
                        qgcApp()->toolbox()->mavlinkProtocol()->getSystemId(),
                        qgcApp()->toolbox()->mavlinkProtocol()->getComponentId(),
                        sharedLink->mavlinkChannel(),
                        &msg,
                        _vehicle->id(),
                        _vehicle->defaultComponentId(),
                        start,
                        end);
            _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
        }
        //-- Wait 5 seconds before bitching about not getting anything
        _timer.start(5000);
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::download(QString path)
{
    QString dir = path;
    if (dir.isEmpty()) {
        dir = qgcApp()->toolbox()->settingsManager()->appSettings()->logSavePath();
    }
    downloadToDirectory(dir);
}

void LogDownloadController::downloadToDirectory(const QString& dir)
{
    //-- Stop listing just in case
    _receivedAllEntries();
    //-- Reset downloads, again just in case
    delete _downloadData;
    _downloadData = nullptr;

    _downloadPath = dir;
    if(!_downloadPath.isEmpty()) {
        if(!_downloadPath.endsWith(QDir::separator()))
            _downloadPath += QDir::separator();
        //-- Make sure the destination directory exists (user configured path may not)
        if (!QDir().mkpath(_downloadPath)) {
            qWarning() << "Failed to create log download directory:" << _downloadPath;
            if (_autoMode) {
                _autoFailedCount++;
                _autoMode = false;
                emit autoDownloadActiveChanged();
                emit autoDownloadFinished(_autoDownloadedCount, _autoFailedCount, _autoSkippedCount);
            }
            return;
        }
        //-- Iterate selected entries: already-downloaded logs are not re-fetched, their
        //   existing file is just re-queued for upload (e.g. after a disconnect mid-upload).
        //   Only genuinely new logs are marked waiting and downloaded.
        bool anyPending = false;
        int num_logs = _logEntriesModel.count();
        for(int i = 0; i < num_logs; i++) {
            QGCLogEntry* entry = _logEntriesModel[i];
            if(entry && entry->selected()) {
                if (_isLogAlreadyDownloaded(entry)) {
                    QSettings settings;
                    settings.beginGroup(_dedupeGroup());
                    const QString filePath = settings.value(_logFingerprint(entry)).toString();
                    settings.endGroup();
                    entry->setSelected(false);
                    emit selectionChanged();
                    entry->setStatus(tr("Already downloaded"));
                    if (!filePath.isEmpty() && QFileInfo::exists(filePath)) {
                        emit logDownloadCompleted(filePath);
                    }
                } else {
                    entry->setStatus(tr("Waiting"));
                    anyPending = true;
                }
            }
        }
        //-- Start download process only if there are pending downloads
        if (anyPending) {
            _setDownloading(true);
            _receivedAllData();
        } else {
            _resetSelection();
        }
    }
}


//----------------------------------------------------------------------------------------
QGCLogEntry*
LogDownloadController::_getNextSelected()
{
    //-- Iterate entries and look for a selected file
    int num_logs = _logEntriesModel.count();
    for(int i = 0; i < num_logs; i++) {
        QGCLogEntry* entry = _logEntriesModel[i];
        if(entry) {
            if(entry->selected()) {
               return entry;
            }
        }
    }
    return nullptr;
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_prepareLogDownload()
{
    delete _downloadData;
    _downloadData = nullptr;

    QGCLogEntry* entry = _getNextSelected();
    if(!entry) {
        return false;
    }
    //-- Deselect file
    entry->setSelected(false);
    emit selectionChanged();
    QString ftime;
    if(entry->time().date().year() < 2010) {
        ftime = tr("UnknownDate");
    } else {
        ftime = entry->time().toString(QStringLiteral("yyyy-M-d-hh-mm-ss"));
    }
    _downloadData = new LogDownloadData(entry);
    _downloadData->filename = QString("log_") + QString::number(entry->id()) + "_" + ftime;
    if (_vehicle->firmwareType() == MAV_AUTOPILOT_PX4) {
        QString loggerParam = QStringLiteral("SYS_LOGGER");
        if (_vehicle->parameterManager()->parameterExists(FactSystem::defaultComponentId, loggerParam) &&
                _vehicle->parameterManager()->getParameter(FactSystem::defaultComponentId, loggerParam)->rawValue().toInt() == 0) {
            _downloadData->filename += ".px4log";
        } else {
            _downloadData->filename += ".ulg";
        }
    } else {
        _downloadData->filename += ".bin";
    }
    _downloadData->file.setFileName(_downloadPath + _downloadData->filename);
    //-- Append a number to the end if the filename already exists
    if (_downloadData->file.exists()){
        uint num_dups = 0;
        QStringList filename_spl = _downloadData->filename.split('.');
        do {
            num_dups +=1;
            _downloadData->filename = filename_spl[0] + '_' + QString::number(num_dups) + '.' + filename_spl[1];
            _downloadData->file.setFileName(_downloadPath + _downloadData->filename);
        } while( _downloadData->file.exists());
    }
    return true;
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_ftpLogDownloadSupported() const
{
    if (!_vehicle) {
        return false;
    }
    // Only ArduPilot exposes onboard logs through the MAVLink FTP server. PX4 logs (.ulg)
    // continue to use the legacy log download protocol.
    if (_vehicle->firmwareType() != MAV_AUTOPILOT_ARDUPILOTMEGA) {
        return false;
    }
    return _vehicle->ftpManager() != nullptr;
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_startFtpDownload()
{
    if (!_downloadData || _downloadData->legacyFallback || !_ftpLogDownloadSupported()) {
        return false;
    }

    // ArduPilot stores DataFlash logs as <log_dir>/<8 digit log number>.BIN where the log
    // number is one based. The log directory depends on the board: real ChibiOS vehicles
    // expose /APM/LOGS while SITL/Linux exposes /logs. Try each in turn; _ftpDownloadComplete
    // advances to the next candidate on failure before finally falling back to legacy.
    const uint logNumber = _downloadData->ID + _apmOneBased;
    const QString fileName = QStringLiteral("%1.BIN").arg(logNumber, 8, 10, QLatin1Char('0'));
    _ftpCandidateUris.clear();
    _ftpCandidateUris << QStringLiteral("/APM/LOGS/%1").arg(fileName)
                      << QStringLiteral("/logs/%1").arg(fileName);
    _ftpCandidateIndex = 0;

    return _startFtpCandidate();
}

//----------------------------------------------------------------------------------------
bool
LogDownloadController::_startFtpCandidate()
{
    if (!_downloadData || !_vehicle || _ftpCandidateIndex >= _ftpCandidateUris.size()) {
        return false;
    }

    FTPManager* ftpManager = _vehicle->ftpManager();
    if (!ftpManager) {
        return false;
    }

    const QString uri = _ftpCandidateUris[_ftpCandidateIndex];
    if (!ftpManager->download(MAV_COMP_ID_AUTOPILOT1, uri, _downloadPath, _downloadData->filename, true)) {
        // FTPManager is busy with another operation or rejected the URI. Retry this entry with
        // the legacy protocol rather than dropping it.
        qWarning() << "FTP log download could not be started for" << uri << "- falling back to legacy";
        return false;
    }

    qCDebug(LogDownloadLog) << "Started FTP log download for entry" << _downloadData->ID << "uri" << uri;
    _ftpActive = true;
    _downloadData->elapsed.start();
    _progressTimer.start();
    _ftpMaxProgress = 0;
    _ftpProgressTimer.start();
    _downloadData->entry->setStatus(tr("Downloading"));
    _timer.start(kWatchdogPollMilliseconds);
    return true;
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_startLegacyDownload()
{
    if (!_downloadData) {
        return;
    }
    bool result = false;
    if (_downloadData->file.open(QIODevice::WriteOnly)) {
        //-- Preallocate file
        if (_downloadData->file.resize(_downloadData->entry->size())) {
            _downloadData->current_chunk = 0;
            _downloadData->chunk_table = QBitArray(_downloadData->chunkBins(), false);
            _downloadData->elapsed.start();
            //-- Reset adaptive request size and progress watchdog for this entry
            _requestSize = kLegacyRequestBytes;
            _progressTimer.start();
            _lastReqTimer.invalidate();
            result = true;
        } else {
            qWarning() << "Failed to allocate space for log file:" << _downloadData->filename;
        }
    } else {
        qWarning() << "Failed to create log file:" << _downloadData->filename;
    }
    if (!result) {
        if (_downloadData->file.exists()) {
            _downloadData->file.remove();
        }
        _downloadData->entry->setStatus(tr("Error"));
        if (_autoMode) {
            _autoFailedCount++;
        }
        _abortCurrentLogDownload();
        return;
    }
    //-- Request Log
    _requestLogData(_downloadData->ID, 0, _currentRequestSize());
    _timer.start(kTimeOutMilliseconds);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_cancelFtpDownload()
{
    if (_ftpActive && _vehicle && _vehicle->ftpManager()) {
        _vehicle->ftpManager()->cancel();
    }
    _ftpActive = false;
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_ftpDownloadProgress(float value)
{
    if (!_ftpActive || !_downloadData) {
        return;
    }
    // Only *new* progress keeps the transfer alive. FTPManager emits commandProgress while it
    // re-writes missing blocks, so advancing on every callback would hide a stalled transfer.
    if (value > _ftpMaxProgress) {
        _ftpMaxProgress = value;
        _ftpProgressTimer.restart();
    }
    _progressTimer.restart();

    const uint32_t fileSize = _downloadData->entry->size();
    const uint32_t written  = static_cast<uint32_t>(value * fileSize);
    _downloadData->written = written;

    //-- Compute and show the download rate
    const qint64 elapsedMs = _downloadData->elapsed.elapsed();
    qreal rate = 0;
    if (elapsedMs > 0) {
        rate = written / (elapsedMs / 1000.0);
    }
    const QString status = QString("%1% (%2, %3/s)")
            .arg(qRound(value * 100.0))
            .arg(QGCMapEngine::bigSizeToString(written))
            .arg(QGCMapEngine::bigSizeToString(rate));
    _downloadData->entry->setStatus(status);
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_ftpDownloadComplete(const QString& file, const QString& errorMsg)
{
    // Ignore completions that arrive after we already moved on (e.g. the terminate ack from a
    // cancel issued while aborting a timed out transfer).
    if (!_ftpActive) {
        return;
    }
    _ftpActive = false;
    _timer.stop();

    if (!_downloadData) {
        _receivedAllData();
        return;
    }

    if (!errorMsg.isEmpty()) {
        qWarning() << "FTP log download failed for entry" << _downloadData->ID << ":" << errorMsg;
        _ftpDownloadFailed();
        return;
    }

    qCDebug(LogDownloadLog) << "FTP log download complete for entry" << _downloadData->ID << "file" << file;
    _downloadData->entry->setStatus(tr("Downloaded"));
    _markLogDownloaded(_downloadData->entry, file);
    if (_autoMode) {
        _autoDownloadedCount++;
    }
    _receivedAllData();
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_ftpDownloadFailed()
{
    // Called on an FTP error or a stalled transfer. Advances to the next FTP candidate and,
    // failing that, retries the same entry once with the legacy chunked protocol.
    if (!_downloadData) {
        return;
    }

    // Try the next candidate log directory (e.g. /logs on SITL when /APM/LOGS is not present)
    if (_ftpCandidateIndex + 1 < _ftpCandidateUris.size()) {
        _ftpCandidateIndex++;
        if (_downloadData->file.exists()) {
            _downloadData->file.remove();
        }
        _downloadData->written = 0;
        _downloadData->rate_avg = 0;
        if (_startFtpCandidate()) {
            return;
        }
    }

    // No further FTP candidate worked. Retry this same entry once using the legacy chunked
    // protocol.
    if (!_downloadData->legacyFallback) {
        _downloadData->legacyFallback = true;
        if (_downloadData->file.exists()) {
            _downloadData->file.remove();
        }
        _downloadData->written = 0;
        _downloadData->rate_avg = 0;
        _startLegacyDownload();
        return;
    }

    _downloadData->entry->setStatus(tr("Error"));
    if (_autoMode) {
        _autoFailedCount++;
    }
    _abortCurrentLogDownload();
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_setDownloading(bool active)
{
    if (_downloadingLogs != active) {
        _downloadingLogs = active;
        _updateCommunicationLostEnabled();
        emit downloadingLogsChanged();
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_setListing(bool active)
{
    if (_requestingLogEntries != active) {
        _requestingLogEntries = active;
        _updateCommunicationLostEnabled();
        emit requestingListChanged();
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::_updateCommunicationLostEnabled()
{
    //-- Only suppress "Communication Lost" while we are actually using the link
    if (_vehicle) {
        _vehicle->vehicleLinkManager()->setCommunicationLostEnabled(!(_requestingLogEntries || _downloadingLogs));
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::eraseAll(void)
{
    if(_vehicle && _uas) {
        WeakLinkInterfacePtr weakLink = _vehicle->vehicleLinkManager()->primaryLink();
        if (!weakLink.expired()) {
            SharedLinkInterfacePtr sharedLink = weakLink.lock();

            mavlink_message_t msg;
            mavlink_msg_log_erase_pack_chan(
                        qgcApp()->toolbox()->mavlinkProtocol()->getSystemId(),
                        qgcApp()->toolbox()->mavlinkProtocol()->getComponentId(),
                        sharedLink->mavlinkChannel(),
                        &msg,
                        qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()->id(), qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()->defaultComponentId());
            _vehicle->sendMessageOnLinkThreadSafe(sharedLink.get(), msg);
        }
        refresh();
    }
}

//----------------------------------------------------------------------------------------
void
LogDownloadController::cancel(void)
{
    _cancelFtpDownload();
    if(_uas){
        _receivedAllEntries();
    }
    if(_downloadData) {
        _downloadData->entry->setStatus(tr("Canceled"));
        if (_downloadData->file.exists()) {
            _downloadData->file.remove();
        }
        delete _downloadData;
        _downloadData = 0;
    }
    _resetSelection(true);
    _setDownloading(false);
}

//-----------------------------------------------------------------------------
QGCLogModel::QGCLogModel(QObject* parent)
    : QAbstractListModel(parent)
{

}

//-----------------------------------------------------------------------------
QGCLogEntry*
QGCLogModel::get(int index)
{
    if (index < 0 || index >= _logEntries.count()) {
        return nullptr;
    }
    return _logEntries[index];
}

//-----------------------------------------------------------------------------
int
QGCLogModel::count() const
{
    return _logEntries.count();
}

//-----------------------------------------------------------------------------
void
QGCLogModel::append(QGCLogEntry* object)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    QQmlEngine::setObjectOwnership(object, QQmlEngine::CppOwnership);
    _logEntries.append(object);
    endInsertRows();
    emit countChanged();
}

//-----------------------------------------------------------------------------
void
QGCLogModel::clear(void)
{
    if(!_logEntries.isEmpty()) {
        beginRemoveRows(QModelIndex(), 0, _logEntries.count() - 1);
        while (_logEntries.count()) {
            QGCLogEntry* entry = _logEntries.last();
            if(entry) entry->deleteLater();
            _logEntries.removeLast();
        }
        endRemoveRows();
        emit countChanged();
    }
}

//-----------------------------------------------------------------------------
QGCLogEntry*
QGCLogModel::operator[](int index)
{
    return get(index);
}

//-----------------------------------------------------------------------------
int
QGCLogModel::rowCount(const QModelIndex& /*parent*/) const
{
    return _logEntries.count();
}

//-----------------------------------------------------------------------------
QVariant
QGCLogModel::data(const QModelIndex & index, int role) const {
    if (index.row() < 0 || index.row() >= _logEntries.count())
        return QVariant();
    if (role == ObjectRole)
        return QVariant::fromValue(_logEntries[index.row()]);
    return QVariant();
}

//-----------------------------------------------------------------------------
QHash<int, QByteArray>
QGCLogModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[ObjectRole] = "logEntry";
    return roles;
}
