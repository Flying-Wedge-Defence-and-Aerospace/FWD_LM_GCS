#include "MvtDecoder.h"

#include <QtMath>
#include <QtEndian>
#include <QDebug>

// ---------------------------------------------------------------------------
// Reader — protobuf wire format
// ---------------------------------------------------------------------------

uint64_t MvtDecoder::Reader::readVarint()
{
    uint64_t result = 0;
    int shift = 0;
    while (pos < size) {
        uint8_t byte = data[pos++];
        result |= (uint64_t)(byte & 0x7F) << shift;
        shift += 7;
        if (!(byte & 0x80))
            return result;
    }
    return result;
}

std::pair<int,int> MvtDecoder::Reader::readFieldTag()
{
    uint64_t tag = readVarint();
    return { (int)(tag >> 3), (int)(tag & 0x7) };
}

QByteArray MvtDecoder::Reader::readLengthDelimited()
{
    uint64_t len = readVarint();
    if (pos + len > size)
        return QByteArray();
    QByteArray result((const char*)(data + pos), (int)len);
    pos += len;
    return result;
}

uint64_t MvtDecoder::Reader::readFixed64()
{
    if (pos + 8 > size) return 0;
    uint64_t val;
    memcpy(&val, data + pos, 8);
    pos += 8;
    return val;
}

uint32_t MvtDecoder::Reader::readFixed32()
{
    if (pos + 4 > size) return 0;
    uint32_t val;
    memcpy(&val, data + pos, 4);
    pos += 4;
    return val;
}

void MvtDecoder::Reader::skipField(int wireType)
{
    switch (wireType) {
    case 0: readVarint(); break;
    case 1: pos += 8; break;
    case 2: { uint64_t len = readVarint(); pos += len; break; }
    case 5: pos += 4; break;
    }
}

QByteArray MvtDecoder::Reader::readBytes(size_t n)
{
    if (pos + n > size) n = size - pos;
    QByteArray result((const char*)(data + pos), (int)n);
    pos += n;
    return result;
}

std::vector<uint32_t> MvtDecoder::Reader::readPackedUInt32()
{
    QByteArray bytes = readLengthDelimited();
    std::vector<uint32_t> result;
    const uint8_t* d = (const uint8_t*)bytes.constData();
    size_t s = bytes.size();
    size_t p = 0;
    while (p < s) {
        uint64_t val = 0;
        int shift = 0;
        while (p < s) {
            uint8_t b = d[p++];
            val |= (uint64_t)(b & 0x7F) << shift;
            shift += 7;
            if (!(b & 0x80)) break;
        }
        result.push_back((uint32_t)val);
    }
    return result;
}

// ---------------------------------------------------------------------------
// Value decoder
// ---------------------------------------------------------------------------

MvtDecoder::Value MvtDecoder::decodeValue(Reader& reader)
{
    Value val;
    QByteArray payload = reader.readLengthDelimited();
    Reader vr((const uint8_t*)payload.constData(), payload.size());
    while (vr.hasMore()) {
        auto [fn, wt] = vr.readFieldTag();
        switch (fn) {
        case 1: // string_value
            val.type = Value::String;
            val.stringValue = QString::fromUtf8(vr.readLengthDelimited());
            break;
        case 2: // float_value
            val.type = Value::Float;
            val.floatValue = vr.readFixed32();
            break;
        case 3: // double_value
            val.type = Value::Double;
            val.doubleValue = vr.readFixed64();
            break;
        case 4: // int_value
            val.type = Value::Int64;
            val.int64Value = (int64_t)vr.readVarint();
            break;
        case 5: // uint_value
            val.type = Value::UInt64;
            val.uint64Value = vr.readVarint();
            break;
        case 6: // sint_value
            val.type = Value::SInt64;
            val.int64Value = zigzag((uint32_t)vr.readVarint());
            break;
        case 7: // bool_value
            val.type = Value::Bool;
            val.boolValue = vr.readVarint() != 0;
            break;
        default:
            vr.skipField(wt);
            break;
        }
    }
    return val;
}

// ---------------------------------------------------------------------------
// Geometry helpers
// ---------------------------------------------------------------------------

int64_t MvtDecoder::zigzag(uint32_t val)
{
    return (int64_t)(val >> 1) ^ -(int64_t)(val & 1);
}

std::vector<std::vector<std::pair<int64_t,int64_t>>> MvtDecoder::decodeGeometry(
    const std::vector<uint32_t>& geom, int& geomType)
{
    std::vector<std::vector<std::pair<int64_t,int64_t>>> rings;
    std::vector<std::pair<int64_t,int64_t>> currentRing;
    int64_t cx = 0, cy = 0;
    size_t i = 0;

    while (i < geom.size()) {
        uint32_t cmd_word = geom[i++];
        int commandId = cmd_word & 0x07;
        int count = cmd_word >> 3;

        if (commandId == 1) { // MoveTo — start new ring
            if (!currentRing.empty()) {
                rings.push_back(std::move(currentRing));
                currentRing.clear();
            }
            for (int j = 0; j < count && i + 1 < geom.size(); j++) {
                int64_t dx = zigzag(geom[i++]);
                int64_t dy = zigzag(geom[i++]);
                cx += dx;
                cy += dy;
                currentRing.push_back({cx, cy});
            }
        } else if (commandId == 2) { // LineTo
            for (int j = 0; j < count && i + 1 < geom.size(); j++) {
                int64_t dx = zigzag(geom[i++]);
                int64_t dy = zigzag(geom[i++]);
                cx += dx;
                cy += dy;
                currentRing.push_back({cx, cy});
            }
        } else if (commandId == 7) { // ClosePath
            continue;
        }
    }

    if (!currentRing.empty()) {
        rings.push_back(std::move(currentRing));
    }

    return rings;
}

// ---------------------------------------------------------------------------
// Coordinate conversion
// ---------------------------------------------------------------------------

void MvtDecoder::tileToLatLon(int tx, int ty, double lx, double ly,
                               int zoom, double& lat, double& lon)
{
    double fx = tx + lx;
    double fy = ty + ly;
    double n = (double)(1 << zoom);
    lon = fx / n * 360.0 - 180.0;
    double latRad = atan(sinh(M_PI * (1.0 - 2.0 * fy / n)));
    lat = latRad * 180.0 / M_PI;
}

// ---------------------------------------------------------------------------
// Haversine
// ---------------------------------------------------------------------------

double MvtDecoder::haversine(double lat1, double lon1,
                              double lat2, double lon2)
{
    double R = 6371000.0;
    double dlat = (lat2 - lat1) * M_PI / 180.0;
    double dlon = (lon2 - lon1) * M_PI / 180.0;
    double a = sin(dlat / 2.0) * sin(dlat / 2.0) +
               cos(lat1 * M_PI / 180.0) * cos(lat2 * M_PI / 180.0) *
               sin(dlon / 2.0) * sin(dlon / 2.0);
    return R * 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
}

// ---------------------------------------------------------------------------
// Polygon centroid + radius
// ---------------------------------------------------------------------------

void MvtDecoder::polygonToCircle(
    const std::vector<std::pair<double,double>>& points,
    double& cLat, double& cLon, double& radius)
{
    if (points.empty()) {
        cLat = cLon = radius = 0;
        return;
    }
    double sumLat = 0, sumLon = 0;
    for (const auto& p : points) {
        sumLat += p.first;
        sumLon += p.second;
    }
    cLat = sumLat / points.size();
    cLon = sumLon / points.size();
    radius = 0;
    for (const auto& p : points) {
        double d = haversine(cLat, cLon, p.first, p.second);
        if (d > radius) radius = d;
    }
}

// ---------------------------------------------------------------------------
// Main decode entry point
// ---------------------------------------------------------------------------

std::vector<DecodedFeature> MvtDecoder::decode(
    const QByteArray& data, int tileX, int tileY, int zoom,
    const QString& zoneType)
{
    std::vector<DecodedFeature> features;

    if (data.isEmpty())
        return features;

    Reader tileReader((const uint8_t*)data.constData(), data.size());

    while (tileReader.hasMore()) {
        auto [fn, wt] = tileReader.readFieldTag();
        if (fn == 3 && wt == 2) {
            QByteArray layerBytes = tileReader.readLengthDelimited();
            Reader layerReader((const uint8_t*)layerBytes.constData(),
                               layerBytes.size());

            // Layer state we need to accumulate
            QString layerName;
            uint32_t extent = 4096;
            std::vector<QByteArray> layerKeys;      // raw key strings
            std::vector<Value>      layerValues;    // decoded values
            struct RawFeature {
                uint64_t id = 0;
                std::vector<uint32_t> tags;
                int geomType = 0;
                std::vector<uint32_t> geometry;
            };
            std::vector<RawFeature> rawFeatures;

            // Parse the layer sub-message
            while (layerReader.hasMore()) {
                auto [lfn, lwt] = layerReader.readFieldTag();
                switch (lfn) {
                case 1: // name
                    layerName = QString::fromUtf8(
                        layerReader.readLengthDelimited());
                    break;
                case 2: // features (repeated message)
                {
                    QByteArray featBytes = layerReader.readLengthDelimited();
                    Reader fr((const uint8_t*)featBytes.constData(),
                              featBytes.size());
                    RawFeature rf;
                    while (fr.hasMore()) {
                        auto [ffn, fwt] = fr.readFieldTag();
                        switch (ffn) {
                        case 1: rf.id = fr.readVarint(); break;
                        case 2: // tags (packed uint32)
                            rf.tags = fr.readPackedUInt32();
                            break;
                        case 3: // type (enum)
                            rf.geomType = (int)fr.readVarint();
                            break;
                        case 4: // geometry (packed uint32)
                            rf.geometry = fr.readPackedUInt32();
                            break;
                        default: fr.skipField(fwt); break;
                        }
                    }
                    rawFeatures.push_back(rf);
                    break;
                }
                case 3: // keys (repeated string)
                    layerKeys.push_back(
                        layerReader.readLengthDelimited());
                    break;
                case 4: // values (repeated message)
                    layerValues.push_back(
                        decodeValue(layerReader));
                    break;
                case 5: // extent
                    extent = (uint32_t)layerReader.readVarint();
                    break;
                default:
                    layerReader.skipField(lwt);
                    break;
                }
            }

            // Convert raw features to decoded features
            for (const auto& rf : rawFeatures) {
                // Skip Unknown geometry type
                if (rf.geomType == 0)
                    continue;

                // Build properties from tags
                QString propName, propDesignator;
                int propRadius = 500;
                double propLower = 0, propUpper = 400;
                QString propReason;

                for (size_t ti = 0; ti + 1 < rf.tags.size(); ti += 2) {
                    int keyIdx = (int)rf.tags[ti];
                    int valIdx = (int)rf.tags[ti + 1];
                    if (keyIdx < 0 || keyIdx >= (int)layerKeys.size())
                        continue;
                    if (valIdx < 0 || valIdx >= (int)layerValues.size())
                        continue;

                    QString key = QString::fromUtf8(layerKeys[keyIdx]);
                    const Value& val = layerValues[valIdx];

                    QString strVal;
                    double numVal = 0;
                    if (val.type == Value::String) {
                        strVal = val.stringValue;
                    } else if (val.type == Value::Float) {
                        numVal = val.floatValue;
                    } else if (val.type == Value::Double) {
                        numVal = val.doubleValue;
                    } else if (val.type == Value::Int64) {
                        numVal = (double)val.int64Value;
                        strVal = QString::number(val.int64Value);
                    } else if (val.type == Value::UInt64) {
                        numVal = (double)val.uint64Value;
                        strVal = QString::number(val.uint64Value);
                    }

                    // Map MVT properties to our fields
                    QString kl = key.toLower();
                    if (kl == "name") {
                        propName = strVal;
                    } else if (kl == "designator" || kl == "id") {
                        propDesignator = strVal;
                    } else if (kl == "radius") {
                        propRadius = (int)numVal;
                    } else if (kl == "lowerlimit" || kl == "lower_limit") {
                        propLower = numVal;
                    } else if (kl == "upperlimit" || kl == "upper_limit") {
                        propUpper = numVal;
                    } else if (kl == "reason" || kl == "description" ||
                               kl == "description_txt") {
                        propReason = strVal;
                    }
                }

                // Decode geometry
                int geomTypeCopy = rf.geomType;
                auto rings = decodeGeometry(rf.geometry, geomTypeCopy);

                if (rings.empty())
                    continue;

                DecodedFeature feat;
                feat.zoneType = zoneType;
                feat.name = propName;
                feat.designator = propDesignator;
                feat.radius = propRadius;
                feat.lowerLimit = propLower;
                feat.upperLimit = propUpper;
                feat.reason = propReason;

                if (rf.geomType == 1) {
                    // Point — use first coordinate
                    double lat, lon;
                    tileToLatLon(tileX, tileY,
                                 (double)rings[0][0].first / (double)extent,
                                 (double)rings[0][0].second / (double)extent,
                                 zoom, lat, lon);
                    feat.lat = lat;
                    feat.lon = lon;
                    feat.isPolygon = false;
                    features.push_back(feat);
                } else if (rf.geomType == 2 || rf.geomType == 3) {
                    // LineString or Polygon — convert all rings to geo coords
                    std::vector<std::vector<std::pair<double,double>>> geoRings;
                    for (const auto& ring : rings) {
                        std::vector<std::pair<double,double>> geoRing;
                        for (const auto& pt : ring) {
                            double lat, lon;
                            tileToLatLon(tileX, tileY,
                                         (double)pt.first / (double)extent,
                                         (double)pt.second / (double)extent,
                                         zoom, lat, lon);
                            geoRing.push_back({lat, lon});
                        }
                        geoRings.push_back(std::move(geoRing));
                    }

                    // Compute centroid + radius from outer ring
                    double cLat, cLon, rad;
                    polygonToCircle(geoRings[0], cLat, cLon, rad);
                    feat.lat = cLat;
                    feat.lon = cLon;
                    feat.radius = rad;
                    feat.isPolygon = true;

                    // Store all rings for QML MapPolygon (path + holes)
                    if (rf.geomType == 3) {
                        feat.polygon = geoRings[0];
                        feat.rings.assign(geoRings.begin() + 1, geoRings.end());
                    }
                    features.push_back(feat);
                }
            }
        } else {
            tileReader.skipField(wt);
        }
    }

    return features;
}
