#include "AirspaceManager.h"
#include "MvtDecoder.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include "AppSettings.h"
#include <QUrl>
#include <QNetworkRequest>
#include <QTimer>
#include <QtMath>
#include <QDebug>
#include <cmath>
#include <algorithm>
#include <QList>

// ---------------------------------------------------------------------------
// Douglas-Peucker polygon simplification
// ---------------------------------------------------------------------------

// Perpendicular distance from pt to line a-b, in degrees
static double _perpDistDeg(const QGeoCoordinate& pt,
                            const QGeoCoordinate& a,
                            const QGeoCoordinate& b)
{
    double dx = b.longitude() - a.longitude();
    double dy = b.latitude() - a.latitude();
    double mag = std::sqrt(dx*dx + dy*dy);
    if (mag < 1e-12)
        return std::sqrt(std::pow(pt.latitude() - a.latitude(), 2) +
                         std::pow(pt.longitude() - a.longitude(), 2));
    return std::fabs((pt.longitude() - a.longitude()) * dy -
                     (pt.latitude() - a.latitude()) * dx) / mag;
}

static void _dpSimplify(const QList<QGeoCoordinate>& pts, int first, int last,
                         double tolDeg, QList<QGeoCoordinate>& out)
{
    if (last - first <= 1) {
        out.append(pts[first]);
        out.append(pts[last]);
        return;
    }
    double maxDist = 0;
    int maxIdx = first;
    for (int i = first + 1; i < last; i++) {
        double d = _perpDistDeg(pts[i], pts[first], pts[last]);
        if (d > maxDist) {
            maxDist = d;
            maxIdx = i;
        }
    }
    if (maxDist > tolDeg) {
        _dpSimplify(pts, first, maxIdx, tolDeg, out);
        out.removeLast();
        _dpSimplify(pts, maxIdx, last, tolDeg, out);
    } else {
        out.append(pts[first]);
        out.append(pts[last]);
    }
}

static QList<QGeoCoordinate> simplifyPolygon(const QList<QGeoCoordinate>& pts,
                                              double toleranceMeters)
{
    if (pts.size() < 10) return pts;
    double lat = pts[0].latitude();
    double metersPerDeg = 111320.0 * std::cos(lat * M_PI / 180.0);
    double tolDeg = toleranceMeters / metersPerDeg;

    // De-close
    QList<QGeoCoordinate> ring = pts;
    if (ring.first().latitude()  == ring.last().latitude() &&
        ring.first().longitude() == ring.last().longitude())
        ring.removeLast();

    if (ring.size() < 10) return pts;

    QList<QGeoCoordinate> result;
    _dpSimplify(ring, 0, ring.size() - 1, tolDeg, result);

    // Re-close
    if (result.size() >= 2 &&
        (result.first().latitude()  != result.last().latitude() ||
         result.first().longitude() != result.last().longitude()))
        result.append(result.first());

    return result;
}

static QList<QGeoCoordinate> capVertices(const QList<QGeoCoordinate>& pts, int maxVerts)
{
    if (pts.size() <= maxVerts) return pts;
    QList<QGeoCoordinate> capped;
    capped.reserve(maxVerts + 1);
    double step = (double)(pts.size() - 1) / maxVerts;
    for (int i = 0; i <= maxVerts; i++) {
        int idx = qMin((int)round(i * step), pts.size() - 1);
        capped.append(pts[idx]);
    }
    return capped;
}

// ---------------------------------------------------------------------------
// Layer definitions — mirrors Python proxy's TILE_URLS + LAYER_TYPE_MAP
// ---------------------------------------------------------------------------

struct LayerDef {
    const char* name;
    const char* urlTemplate;   // use {z}/{x}/{y} placeholders
    const char* zoneType;
    int minZoom = 2;
    int maxZoom = 14;
};

static const LayerDef kLayers[] = {
    { "red_zones",
      "https://digitalsky.aai.aero/maps/dataserver_5000/red_zones/{z}/{x}/{y}",
      "RED", 2, 14 },
    { "temp_red_zones",
     "https://digitalsky.aai.aero/maps/dataserver_5000/tem_red_zones/{z}/{x}/{y}",
     "RED", 0, 5 },
    { "airport_yellow",
     "https://digitalsky.aai.aero/maps/dataserver_5000/airport_yellow_5_8/{z}/{x}/{y}",
     "YELLOW", 5, 8 },
    { "airport_yellow",
      "https://digitalsky.aai.aero/maps/dataserver_5000/airport_yellow_8_12/{z}/{x}/{y}",
      "YELLOW", 8, 12 },
    // { "metro",
    //  "https://digitalsky.aai.aero/maps/dataserver_5000/rsc/tiles/metro/{z}/{x}/{y}",
    //  "RED", 5, 14 },
};

// static constexpr int kLayerCount = sizeof(kLayers) / sizeof(kLayers[0]);

// ---------------------------------------------------------------------------
// Tile math helpers (inline in file)
// ---------------------------------------------------------------------------

static void latLonToTile(double lat, double lon, int zoom, int& x, int& y)
{
    int n = 1 << zoom;
    x = (int)floor((lon + 180.0) / 360.0 * n);
    double latRad = lat * M_PI / 180.0;
    y = (int)floor((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / M_PI) / 2.0 * n);
}

// ---------------------------------------------------------------------------
// AirspaceManager
// ---------------------------------------------------------------------------

AirspaceManager::AirspaceManager(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
{
    _netManager = new QNetworkAccessManager(this);

    _debounceTimer = new QTimer(this);
    _debounceTimer->setSingleShot(true);
    connect(_debounceTimer, &QTimer::timeout, this, &AirspaceManager::_doRefresh);

    _timeoutTimer = new QTimer(this);
    _timeoutTimer->setSingleShot(true);
    connect(_timeoutTimer, &QTimer::timeout, this, [this]() {
        qWarning() << "Airspace: tile fetch timed out — keeping existing zones visible";
        _abortPendingReplies();
        _setBusy(false);
        // Discard pending zones, keep old zones visible
        for (AirspaceZone* z : _pendingZones)
            delete z;
        _pendingZones.clear();
        _pendingCount = 0;
        _requestedTiles.clear();
        // Don't emit zonesChanged — old zones stay on map
    });

    _zoneInsertTimer = new QTimer(this);
    _zoneInsertTimer->setInterval(50);
    connect(_zoneInsertTimer, &QTimer::timeout, this, &AirspaceManager::_onZoneInsertTick);
}

AirspaceManager::~AirspaceManager()
{
}

void AirspaceManager::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);
}

bool AirspaceManager::hasToken() const
{
    AppSettings* appSettings = qgcApp()->toolbox()->settingsManager()->appSettings();
    if (!appSettings) return false;
    QString t = appSettings->digitalSkyToken()->rawValue().toString();
    return !t.isEmpty();
}

QString AirspaceManager::token() const
{
    AppSettings* appSettings = qgcApp()->toolbox()->settingsManager()->appSettings();
    if (!appSettings) return QString();
    return appSettings->digitalSkyToken()->rawValue().toString();
}

void AirspaceManager::setToken(const QString& token)
{
    AppSettings* appSettings = qgcApp()->toolbox()->settingsManager()->appSettings();
    if (appSettings) {
        appSettings->digitalSkyToken()->setRawValue(token);
        emit tokenChanged();
        emit hasTokenChanged();
    }
}

void AirspaceManager::setEnabled(bool enabled)
{
    if (_enabled != enabled) {
        _enabled = enabled;
        if (!enabled) {
            _abortZoneInsertion();
            _abortPendingReplies();
            _timeoutTimer->stop();
            for (AirspaceZone* z : _pendingZones) delete z;
            _pendingZones.clear();
            _pendingCount = 0;
            _clearZones();
            emit zonesChanged();
        } else {
            if (_lastMinLat != 0.0 || _lastMinLon != 0.0)
                refresh(_lastMinLat, _lastMinLon, _lastMaxLat, _lastMaxLon);
        }
        emit enabledChanged();
    }
}

// ---------------------------------------------------------------------------
// refresh — entry point called from QML
// ---------------------------------------------------------------------------

void AirspaceManager::refresh(double minLat, double minLon,
                               double maxLat, double maxLon)
{
    if (!_enabled) return;

    // Normalize bbox: QGC may send minLat > maxLat (it treats minLat as north)
    if (minLat > maxLat) std::swap(minLat, maxLat);
    if (minLon > maxLon) std::swap(minLon, maxLon);

    _lastMinLat = minLat;
    _lastMinLon = minLon;
    _lastMaxLat = maxLat;
    _lastMaxLon = maxLon;

    // Debounce: wait for pan/zoom to settle before fetching
    _debounceTimer->start(kDebounceMs);
}

void AirspaceManager::_abortPendingReplies()
{
    for (QNetworkReply* reply : _pendingReplies) {
        reply->disconnect();
        reply->abort();
        reply->deleteLater();
    }
    _pendingReplies.clear();
}

void AirspaceManager::_doRefresh()
{
    _refreshSeq++;
    _abortZoneInsertion();
    _abortPendingReplies();
    _pendingZones.clear();
    _seenCoords.clear();
    _fetchTiles(_lastMinLat, _lastMinLon, _lastMaxLat, _lastMaxLon);
}

// ---------------------------------------------------------------------------
// Tile fetching
// ---------------------------------------------------------------------------

int AirspaceManager::_bboxToZoom(double minLat, double minLon,
                                  double maxLat, double maxLon) const
{
    double dlat = maxLat - minLat;
    double dlon = maxLon - minLon;
    if (dlat <= 0 || dlon <= 0) return kDefaultZoom;
    double diagDeg = sqrt(dlat * dlat + dlon * dlon);
    double targetTiles = 1.5;
    int zoom = (int)round(log2(360.0 / diagDeg * targetTiles));
    return qBound(2, zoom, 14);
}

void AirspaceManager::_tileBounds(double minLat, double minLon,
                                   double maxLat, double maxLon,
                                   int zoom, int& minX, int& minY,
                                   int& maxX, int& maxY) const
{
    int x1, y1, x2, y2;
    latLonToTile(minLat, minLon, zoom, x1, y1);
    latLonToTile(maxLat, maxLon, zoom, x2, y2);
    minX = std::min(x1, x2);
    maxX = std::max(x1, x2);
    minY = std::min(y1, y2);
    maxY = std::max(y1, y2);
    int n = 1 << zoom;
    minX = qBound(0, minX, n - 1);
    maxX = qBound(0, maxX, n - 1);
    minY = qBound(0, minY, n - 1);
    maxY = qBound(0, maxY, n - 1);
}

void AirspaceManager::_fetchTiles(double minLat, double minLon,
                                   double maxLat, double maxLon)
{
    _setBusy(true);
    _pendingCount = 0;
    _requestedTiles.clear();

    int baseZoom = _bboxToZoom(minLat, minLon, maxLat, maxLon);

    QString cookie = token();

    for (const auto& layer : kLayers) {
        int layerZoom = qBound(layer.minZoom, baseZoom, layer.maxZoom);

        // Build tile list for this layer at its zoom
        int minX, minY, maxX, maxY;
        _tileBounds(minLat, minLon, maxLat, maxLon, layerZoom, minX, minY, maxX, maxY);

        struct TileCoord { int x, y; };
        std::vector<TileCoord> coords;
        for (int x = minX; x <= maxX; x++) {
            for (int y = minY; y <= maxY; y++) {
                coords.push_back({x, y});
            }
        }

        // If too many tiles, reduce zoom for this layer
        int effectiveZoom = layerZoom;
        while ((int)coords.size() > kMaxTiles && effectiveZoom > layer.minZoom) {
            effectiveZoom--;
            _tileBounds(minLat, minLon, maxLat, maxLon, effectiveZoom,
                        minX, minY, maxX, maxY);
            coords.clear();
            for (int x = minX; x <= maxX; x++) {
                for (int y = minY; y <= maxY; y++) {
                    coords.push_back({x, y});
                }
            }
        }

        if (coords.empty() || (int)coords.size() > kMaxTiles)
            continue;

        // qDebug() << "Airspace: layer" << layer.name << "fetching"
        //          << coords.size() << "tiles at zoom" << effectiveZoom;

        QString urlTemplate = QString::fromLatin1(layer.urlTemplate);

        for (const auto& tc : coords) {
            RequestKey key = { effectiveZoom, tc.x, tc.y,
                              reinterpret_cast<uintptr_t>(&layer) };
            if (_requestedTiles.count(key))
                continue;
            _requestedTiles.insert(key);

            QString url = QString(urlTemplate)
                .replace("{z}", QString::number(effectiveZoom))
                .replace("{x}", QString::number(tc.x))
                .replace("{y}", QString::number(tc.y));

            _startTileFetch(url, effectiveZoom, tc.x, tc.y,
                            QString::fromLatin1(layer.name),
                            QString::fromLatin1(layer.zoneType),
                            _refreshSeq);
        }
    }

    if (_pendingCount == 0) {
        _setBusy(false);
        emit zonesChanged();
        return;
    }

    _timeoutTimer->start(kRefreshTimeoutMs);
}

void AirspaceManager::_startTileFetch(const QString& urlString,
                                       int z, int x, int y,
                                       const QString& layerName,
                                       const QString& zoneType,
                                       int seq)
{
    _pendingCount++;

    QUrl url(urlString);
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent",
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36");
    request.setRawHeader("Accept", "*/*");
    request.setRawHeader("Referer", "https://digitalsky.aai.aero/");

    QString cookie = token();
    if (!cookie.isEmpty()) {
        request.setRawHeader("Cookie", cookie.toUtf8());
    }

    request.setTransferTimeout(8000);
    QNetworkReply* reply = _netManager->get(request);
    _pendingReplies.append(reply);

    connect(reply, &QNetworkReply::finished, this,
            [this, reply, z, x, y, zoneType, seq]() {
        _onTileReply(reply, z, x, y, zoneType, seq);
    });
}

void AirspaceManager::_onTileReply(QNetworkReply* reply,
                                    int z, int x, int y,
                                    const QString& zoneType,
                                    int seq)
{
    _pendingReplies.removeOne(reply);
    reply->deleteLater();
    _pendingCount--;

    if (seq != _refreshSeq) {
        // Stale reply from a previous refresh — ignore
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Airspace: tile fetch error" << z << x << y
                   << reply->errorString();
    } else {
        QByteArray data = reply->readAll();
        if (data.isEmpty()) {
            // empty tile — nothing to decode
        } else if (data.startsWith('<')) {
            // qWarning() << "Airspace: tile returned HTML instead of MVT —"
            //            << "requires authentication" << z << x << y << zoneType;
        } else {
            // Decode MVT
            std::vector<DecodedFeature> features =
                MvtDecoder::decode(data, x, y, z, zoneType);

            if (!features.empty() && !_proxyConnected) {
                _proxyConnected = true;
                emit proxyConnectedChanged();
            }

            // qDebug() << "Airspace: decoded" << features.size()
            //          << "features from" << zoneType << z << x << y;

            for (const auto& f : features) {
                // Cap total zones to prevent memory blowup
                if (_pendingZones.size() >= 40)
                    break;

                // qDebug() << "  feature:" << f.name << "polygon pts:" << f.polygon.size()
                //          << "hole rings:" << f.rings.size() << "type:" << zoneType;
                // Dedup key: (lon, lat, zoneType, radius/100).
                // Radius (rounded to nearest 100m) distinguishes inner/outer rings
                // at the same center better than polygon vertex count and doesn't
                // collide when capping brings both rings to the same vertex limit.
                QString key = QString("%1,%2,%3,%4")
                    .arg((int)round(f.lon * 1e4))
                    .arg((int)round(f.lat * 1e4))
                    .arg(f.zoneType)
                    .arg((int)round(f.radius / 100.0));
                if (_seenCoords.count(key))
                    continue;
                _seenCoords.insert(key);

                // Create main zone
                AirspaceZone* zone = new AirspaceZone(this);
                zone->setCenter(QGeoCoordinate(f.lat, f.lon));
                zone->setRadius(f.radius > 0 ? f.radius : 500.0);
                zone->setZoneType(f.zoneType);
                zone->setName(f.name);
                zone->setDesignator(f.designator);
                zone->setLowerLimit(f.lowerLimit);
                zone->setUpperLimit(f.upperLimit);
                zone->setReason(f.reason);
                if (!f.polygon.empty()) {
                    QList<QGeoCoordinate> poly;
                    for (const auto& pt : f.polygon)
                        poly.append(QGeoCoordinate(pt.first, pt.second));
                    // Always simplify + cap — even donut features, because raw polygons
                    // with hundreds of vertices cause MapPolygon fill to fail on OpenGL ES
                    zone->setPolygon(capVertices(simplifyPolygon(poly, 10.0), 50));
                }
                _pendingZones.append(zone);

                // For each hole ring: create a border-only zone (transparent fill + black border)
                // to trace the hole edge
                for (const auto& ring : f.rings) {
                    if (ring.size() < 3) continue;
                    if (_pendingZones.size() >= 40) break;

                    QList<QGeoCoordinate> holeRing;
                    for (const auto& pt : ring)
                        holeRing.append(QGeoCoordinate(pt.first, pt.second));

                    AirspaceZone* hole = new AirspaceZone(this);
                    hole->setZoneType(f.zoneType);
                    hole->setName(f.name);
                    hole->setDesignator(f.designator);
                    hole->setLowerLimit(f.lowerLimit);
                    hole->setUpperLimit(f.upperLimit);
                    hole->setReason(f.reason);
                    hole->setIsHole(true);
                    hole->setPolygon(capVertices(simplifyPolygon(holeRing, 10.0), 50));
                    _pendingZones.append(hole);
                }
            }
        }
    }

    if (_pendingCount == 0) {
        _timeoutTimer->stop();
        _swapZones();
        _setBusy(false);

        if (_zones.count() == 0) {
            qWarning() << "Airspace: all tiles returned empty or failed — no zones to show";
        }

        emit zonesChanged();
    }
}

// ---------------------------------------------------------------------------
// Mock fallback
// ---------------------------------------------------------------------------

void AirspaceManager::_generateMock(double minLat, double minLon,
                                     double maxLat, double maxLon)
{
    if (_proxyConnected) {
        _proxyConnected = false;
        emit proxyConnectedChanged();
    }

    double cLat = (minLat + maxLat) / 2.0;
    double cLon = (minLon + maxLon) / 2.0;

    _clearZones();

    auto addZone = [&](const QString& type, const QString& name,
                       const QString& desig, double latOff, double lonOff,
                       int radiusM, double lower, double upper,
                       const QString& reason)
    {
        AirspaceZone* zone = new AirspaceZone(this);
        zone->setZoneType(type);
        zone->setName(name);
        zone->setDesignator(desig);
        zone->setCenter(QGeoCoordinate(cLat + latOff, cLon + lonOff));
        zone->setRadius(static_cast<double>(radiusM));
        zone->setLowerLimit(lower);
        zone->setUpperLimit(upper);
        zone->setReason(reason);
        _appendZone(zone);
    };

    addZone("RED",    "MOCK-P101 Prohibited Zone",     "P-101",
            0.055, -0.080, 1500, 0, 500,
            "MOCK - Military airfield perimeter");
    addZone("RED",    "MOCK-R102 Restricted Zone",     "R-102",
            -0.040, 0.095, 800, 0, 300,
            "MOCK - Government sensitive infrastructure");
    addZone("YELLOW", "MOCK-CTR Controlled Zone",      "VAAH-CTR",
            0.010, 0.035, 5000, 0, 1500,
            "MOCK - ATC clearance required above 400ft");
    addZone("YELLOW", "MOCK-TMA Terminal Area",        "VAAH-TMA",
            -0.080, -0.050, 3500, 300, 3000,
            "MOCK - High-traffic approach corridor");
    addZone("GREEN",  "MOCK-G201 Uncontrolled Area",   "UAS-G201",
            -0.060, 0.075, 4000, 0, 400,
            "MOCK - BVLOS requires NPNT approval");
    addZone("GREEN",  "MOCK-G202 Uncontrolled Rural",  "UAS-G202",
            0.090, 0.090, 3000, 0, 400,
            "MOCK - Standard DGCA rules apply");

    emit zonesChanged();
}

// ---------------------------------------------------------------------------
// Zone lookup
// ---------------------------------------------------------------------------

AirspaceZone* AirspaceManager::zoneAtCoordinate(double lat, double lon)
{
    QGeoCoordinate point(lat, lon);
    for (int i = 0; i < _zones.count(); i++) {
        AirspaceZone* zone = _zones.value<AirspaceZone*>(i);
        double distance = point.distanceTo(zone->center());
        if (distance <= zone->radius()) {
            return zone;
        }
    }
    return nullptr;
}

bool AirspaceManager::isInRedZone(double lat, double lon)
{
    QGeoCoordinate point(lat, lon);
    for (int i = 0; i < _zones.count(); i++) {
        AirspaceZone* zone = _zones.value<AirspaceZone*>(i);
        if (zone->zoneType().toUpper() != "RED") continue;
        if (zone->isHole()) continue;

        QList<QGeoCoordinate> poly = zone->polygon();
        if (poly.size() < 3) {
            // Circle zone — use radius check
            double dist = point.distanceTo(zone->center());
            if (dist <= zone->radius()) return true;
        } else {
            // Ray casting: odd count = inside
            bool inside = false;
            int j = poly.size() - 1;
            for (int k = 0; k < poly.size(); k++) {
                double latK = poly[k].latitude();
                double lonK = poly[k].longitude();
                double latJ = poly[j].latitude();
                double lonJ = poly[j].longitude();
                if (((latK > lat) != (latJ > lat)) &&
                    (lon < (lonJ - lonK) * (lat - latK) / (latJ - latK) + lonK)) {
                    inside = !inside;
                }
                j = k;
            }
            if (inside) return true;
        }
    }
    return false;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

void AirspaceManager::_setBusy(bool busy)
{
    if (_busy != busy) {
        _busy = busy;
        emit busyChanged();
    }
}

void AirspaceManager::_clearZones()
{
    QList<QObject*> oldItems = *_zones.objectList();
    _zones.beginReset();
    _zones.clear();
    _zones.endReset();
    for (QObject* obj : oldItems) {
        delete obj;
    }
}

void AirspaceManager::_appendZone(AirspaceZone* zone)
{
    _zones.append(zone);
}

void AirspaceManager::_swapZones()
{
    _abortZoneInsertion();

    // Save count of old zones — we'll remove them gradually
    _oldZoneRemoveCount = _zones.count();

    // Start batch-inserting new zones over multiple frames
    _zoneInsertQueue = _pendingZones;
    _pendingZones.clear();

    if (_zoneInsertQueue.isEmpty() && _oldZoneRemoveCount == 0) {
        return;
    }

    if (_zoneInsertQueue.isEmpty()) {
        // No new zones — just delete old ones one at a time
        _zoneInsertTimer->start();
        return;
    }

    _zoneInsertTimer->start();
}

void AirspaceManager::_abortZoneInsertion()
{
    _zoneInsertTimer->stop();
    for (AirspaceZone* z : _zoneInsertQueue)
        delete z;
    _zoneInsertQueue.clear();
    _oldZoneRemoveCount = 0;
}

void AirspaceManager::_onZoneInsertTick()
{
    // Remove 1 old zone per tick (always at index 0 — model shifts down)
    if (_oldZoneRemoveCount > 0) {
        delete _zones.removeAt(0);
        _oldZoneRemoveCount--;
    }

    // Insert 2 new zones per tick
    for (int i = 0; i < 2 && !_zoneInsertQueue.isEmpty(); i++)
        _zones.append(_zoneInsertQueue.takeFirst());

    if (_oldZoneRemoveCount == 0 && _zoneInsertQueue.isEmpty()) {
        _zoneInsertTimer->stop();
        emit zonesChanged();
    }
}
