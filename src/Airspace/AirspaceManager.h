#pragma once

#include <QObject>
#include <QGeoCoordinate>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QUrl>
#include <unordered_set>
#include <vector>

#include "QGCToolbox.h"
#include "QmlObjectListModel.h"
#include "AirspaceZone.h"

struct RequestKey {
    int z, x, y;
    uintptr_t layerId;
    bool operator==(const RequestKey& o) const {
        return z == o.z && x == o.x && y == o.y && layerId == o.layerId;
    }
};

struct RequestKeyHash {
    size_t operator()(const RequestKey& k) const {
        return ((size_t)k.z << 20) ^ ((size_t)k.x << 12) ^ ((size_t)k.y << 4) ^ (size_t)k.layerId;
    }
};

class AirspaceManager : public QGCTool
{
    Q_OBJECT

    Q_PROPERTY(QmlObjectListModel*  zones       READ zones       NOTIFY zonesChanged)
    Q_PROPERTY(bool                 enabled     READ enabled     WRITE setEnabled    NOTIFY enabledChanged)
    Q_PROPERTY(bool                 busy        READ busy                             NOTIFY busyChanged)
    Q_PROPERTY(bool                 proxyConnected READ proxyConnected               NOTIFY proxyConnectedChanged)
    Q_PROPERTY(bool                 hasToken    READ hasToken                         NOTIFY hasTokenChanged)
    Q_PROPERTY(QString              token       READ token        WRITE setToken      NOTIFY tokenChanged)

public:
    AirspaceManager(QGCApplication* app, QGCToolbox* toolbox);
    ~AirspaceManager();

    QmlObjectListModel* zones           () { return &_zones; }
    bool                enabled         () const { return _enabled; }
    bool                busy            () const { return _busy; }
    bool                proxyConnected  () const { return _proxyConnected; }
    bool                hasToken        () const;
    QString             token           () const;

    void setEnabled(bool enabled);
    void setToken (const QString& token);

    Q_INVOKABLE void refresh(double minLat, double minLon, double maxLat, double maxLon);
    Q_INVOKABLE AirspaceZone* zoneAtCoordinate(double lat, double lon);
    Q_INVOKABLE bool isInRedZone(double lat, double lon);

    void setToolbox(QGCToolbox* toolbox);

signals:
    void zonesChanged         ();
    void enabledChanged       ();
    void busyChanged          ();
    void hasTokenChanged      ();
    void tokenChanged         ();
    void proxyConnectedChanged();

private:
    void _setBusy        (bool busy);
    void _clearZones     ();
    void _appendZone     (AirspaceZone* zone);
    void _doRefresh      ();
    void _abortPendingReplies ();
    void _swapZones      ();
    void _abortZoneInsertion ();
    void _onZoneInsertTick   ();

    void _fetchTiles     (double minLat, double minLon, double maxLat, double maxLon);
    void _startTileFetch (const QString& url, int z, int x, int y, const QString& layerName, const QString& zoneType, int seq);
    void _onTileReply    (QNetworkReply* reply, int z, int x, int y, const QString& zoneType, int seq);
    void _generateMock   (double minLat, double minLon, double maxLat, double maxLon);

    int  _bboxToZoom     (double minLat, double minLon, double maxLat, double maxLon) const;
    void _tileBounds     (double minLat, double minLon, double maxLat, double maxLon, int zoom,
                          int& minX, int& minY, int& maxX, int& maxY) const;

    static constexpr int kMaxTiles = 16;
    static constexpr int kDefaultZoom = 14;
    static constexpr int kRefreshTimeoutMs = 15000;
    static constexpr int kDebounceMs = 1000;

    bool                        _enabled        = false;
    bool                        _busy           = false;
    bool                        _proxyConnected = false;
    QNetworkAccessManager*      _netManager     = nullptr;
    QmlObjectListModel          _zones;
    QList<AirspaceZone*>        _pendingZones;
    QList<AirspaceZone*>        _zoneInsertQueue;
    int                         _oldZoneRemoveCount = 0;

    double _lastMinLat = 0.0;
    double _lastMinLon = 0.0;
    double _lastMaxLat = 0.0;
    double _lastMaxLon = 0.0;

    int                         _pendingCount   = 0;
    int                         _refreshSeq     = 0;
    std::unordered_set<RequestKey, RequestKeyHash> _requestedTiles;
    std::unordered_set<QString>  _seenCoords;
    QTimer*                     _timeoutTimer   = nullptr;
    QTimer*                     _debounceTimer  = nullptr;
    QTimer*                     _zoneInsertTimer = nullptr;
    QList<QNetworkReply*>       _pendingReplies;


};
