#pragma once

#include <QByteArray>
#include <QString>
#include <QGeoCoordinate>
#include <cmath>
#include <vector>
#include <cstdint>
#include <utility>
#include <unordered_map>

struct DecodedFeature {
    double lat = 0.0;
    double lon = 0.0;
    double radius = 0.0;
    bool   isPolygon = false;
    std::vector<std::pair<double,double>> polygon;
    std::vector<std::vector<std::pair<double,double>>> rings;

    QString zoneType;
    QString name;
    QString designator;
    double  lowerLimit = 0.0;
    double  upperLimit = 400.0;
    QString reason;
};

class MvtDecoder {
public:
    static std::vector<DecodedFeature> decode(
        const QByteArray& data, int tileX, int tileY, int zoom,
        const QString& zoneType);

private:
    struct Reader {
        const uint8_t* data;
        size_t size;
        size_t pos;

        Reader(const uint8_t* d, size_t s) : data(d), size(s), pos(0) {}

        uint64_t readVarint();
        std::pair<int,int> readFieldTag();
        QByteArray readLengthDelimited();
        uint64_t readFixed64();
        uint32_t readFixed32();
        void skipField(int wireType);
        std::vector<uint32_t> readPackedUInt32();
        QByteArray readBytes(size_t n);
        bool hasMore() const { return pos < size; }
    };

    struct Value {
        enum Type { String, Float, Double, Int64, UInt64, SInt64, Bool, None };
        Type type = None;
        QString stringValue;
        float floatValue = 0;
        double doubleValue = 0;
        int64_t int64Value = 0;
        uint64_t uint64Value = 0;
        bool boolValue = false;
    };

    static int64_t zigzag(uint32_t val);
    static std::vector<std::vector<std::pair<int64_t,int64_t>>> decodeGeometry(
        const std::vector<uint32_t>& geom, int& geomType);
    static void tileToLatLon(int tx, int ty, double lx, double ly,
                             int zoom, double& lat, double& lon);
    static double haversine(double lat1, double lon1,
                            double lat2, double lon2);
    static void polygonToCircle(
        const std::vector<std::pair<double,double>>& points,
        double& cLat, double& cLon, double& radius);
    static Value decodeValue(Reader& reader);
};
