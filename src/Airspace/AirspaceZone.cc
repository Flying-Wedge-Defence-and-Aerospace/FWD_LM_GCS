/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AirspaceZone.h"

#include <QJsonArray>
#include <QJsonObject>

AirspaceZone::AirspaceZone(QObject* parent)
    : QObject(parent)
{
}

QColor AirspaceZone::zoneColor() const
{
    return typeToColor(_zoneType);
}

QList<QGeoCoordinate> AirspaceZone::polygon() const
{
    return _polygon;
}

QVariantList AirspaceZone::holes() const
{
    return _holes;
}

QColor AirspaceZone::typeToColor(const QString& zoneType)
{
    QString upper = zoneType.toUpper();
    if (upper.contains("RED")) {
        return QColor(255, 0, 0, 40);
    } else if (upper.contains("YELLOW")) {
        return QColor(255, 255, 0, 40);
    } else if (upper.contains("GREEN")) {
        return QColor(0, 255, 0, 40);
    }
    return QColor(128, 128, 128, 40);
}

AirspaceZone* AirspaceZone::fromGeoJsonFeature(const QJsonObject& feature)
{
    QJsonObject geometry = feature["geometry"].toObject();
    QJsonObject properties = feature["properties"].toObject();

    QJsonArray coords = geometry["coordinates"].toArray();
    if (coords.size() < 2) {
        return nullptr;
    }

    double lon = coords[0].toDouble();
    double lat = coords[1].toDouble();

    AirspaceZone* zone = new AirspaceZone();
    zone->setCenter(QGeoCoordinate(lat, lon));
    zone->setRadius(properties["radius"].toDouble(500.0));
    zone->setZoneType(properties["type"].toString("UNKNOWN"));
    zone->setName(properties["name"].toString());
    zone->setDesignator(properties["designator"].toString());
    zone->setLowerLimit(properties["lowerLimit"].toDouble(0.0));
    zone->setUpperLimit(properties["upperLimit"].toDouble(400.0));
    zone->setReason(properties["reason"].toString());

    return zone;
}
