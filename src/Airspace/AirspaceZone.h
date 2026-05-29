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
#include <QGeoCoordinate>
#include <QColor>
#include <QJsonObject>
#include <QVariantList>

class AirspaceZone : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QGeoCoordinate center     READ center       CONSTANT)
    Q_PROPERTY(double         radius     READ radius       CONSTANT)
    Q_PROPERTY(QString        zoneType   READ zoneType     CONSTANT)
    Q_PROPERTY(QString        name       READ name         CONSTANT)
    Q_PROPERTY(QString        designator READ designator   CONSTANT)
    Q_PROPERTY(double         lowerLimit READ lowerLimit   CONSTANT)
    Q_PROPERTY(double         upperLimit READ upperLimit   CONSTANT)
    Q_PROPERTY(QString        reason     READ reason       CONSTANT)
    Q_PROPERTY(QColor         zoneColor  READ zoneColor    CONSTANT)
    Q_PROPERTY(QList<QGeoCoordinate> polygon    READ polygon      CONSTANT)
    Q_PROPERTY(QVariantList         holes      READ holes        CONSTANT)
    Q_PROPERTY(bool                 isHole     READ isHole       CONSTANT)

public:
    AirspaceZone(QObject* parent = nullptr);

    QGeoCoordinate  center      () const { return _center; }
    double          radius      () const { return _radius; }
    QString         zoneType    () const { return _zoneType; }
    QString         name        () const { return _name; }
    QString         designator  () const { return _designator; }
    double          lowerLimit  () const { return _lowerLimit; }
    double          upperLimit  () const { return _upperLimit; }
    QString         reason      () const { return _reason; }
    QColor          zoneColor   () const;
    QList<QGeoCoordinate> polygon     () const;
    QVariantList          holes       () const;
    bool                  isHole      () const { return _isHole; }

    void setCenter     (const QGeoCoordinate& center)    { _center = center; }
    void setRadius     (double radius)                   { _radius = radius; }
    void setZoneType   (const QString& zoneType)         { _zoneType = zoneType; }
    void setName       (const QString& name)             { _name = name; }
    void setDesignator (const QString& designator)       { _designator = designator; }
    void setLowerLimit (double lowerLimit)               { _lowerLimit = lowerLimit; }
    void setUpperLimit (double upperLimit)               { _upperLimit = upperLimit; }
    void setReason     (const QString& reason)           { _reason = reason; }
    void setPolygon    (const QList<QGeoCoordinate>& polygon)  { _polygon = polygon; }
    void setHoles      (const QVariantList& holes)       { _holes = holes; }
    void setIsHole     (bool isHole)                     { _isHole = isHole; }

    static AirspaceZone* fromGeoJsonFeature(const QJsonObject& feature);
    static QColor typeToColor(const QString& zoneType);

private:
    QGeoCoordinate  _center;
    double          _radius     = 0.0;
    QString         _zoneType;
    QString         _name;
    QString         _designator;
    double          _lowerLimit = 0.0;
    double          _upperLimit = 400.0;
    QString         _reason;
    QList<QGeoCoordinate> _polygon;
    QVariantList          _holes;
    bool                  _isHole = false;
};
