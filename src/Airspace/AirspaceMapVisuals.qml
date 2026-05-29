/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.11
import QtLocation                   5.3
import QtPositioning                5.3
import QtQuick.Controls             2.4

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0

Item {
    id:             root
    visible:        QGroundControl.airspaceManager.enabled

    property var    map
    property var    _airspaceManager: QGroundControl.airspaceManager

    function colorForType(zoneType) {
        var upper = zoneType.toUpperCase()
        if (upper.indexOf("RED") !== -1) return Qt.rgba(1, 0, 0, 0.3)
        if (upper.indexOf("YELLOW") !== -1) return Qt.rgba(1, 1, 0, 0.3)
        //if (upper.indexOf("GREEN") !== -1) return Qt.rgba(0, 1, 0, 0.3)
        return Qt.rgba(0.5, 0.5, 0.5, 0.3)
    }

    function borderColorForType(zoneType) {
        return Qt.rgba(0, 0, 0, 0.9)
    }

    function _circlePath(zone) {
        // Approximate a circle as a 36-point polygon for point features
        var path = []
        var steps = 36
        var lat = zone.center.latitude
        var lon = zone.center.longitude
        var r = zone.radius
        // Convert radius in meters to degrees (approx)
        var rLat = r / 111320.0
        var rLon = r / (111320.0 * Math.cos(lat * Math.PI / 180))
        for (var i = 0; i < steps; i++) {
            var a = i * 2 * Math.PI / steps
            path.push(QtPositioning.coordinate(
                lat + rLat * Math.cos(a),
                lon + rLon * Math.sin(a)
            ))
        }
        return path
    }

    function showZoneInfo(zone) {
        zoneInfoName.text       = zone.name
        zoneInfoType.text       = qsTr("Type: %1").arg(zone.zoneType)
        zoneInfoRadius.text     = qsTr("Radius: %1 km").arg((zone.radius / 1000).toFixed(1))
        zoneInfoAlt.text        = qsTr("%1 - %2 ft AGL").arg(zone.lowerLimit).arg(zone.upperLimit)
        zoneInfoReason.text     = zone.reason
        zoneInfoPopup.visible   = true
    }

    Instantiator {
        model: _airspaceManager.zones

        delegate: MapPolygon {
            path:         object.polygon.length > 0 ? object.polygon : _circlePath(object)
            color:        object.isHole ? "transparent" : root.colorForType(object.zoneType)
            border.color: root.borderColorForType(object.zoneType)
            border.width: object.isHole ? 3 : 2
            visible: _airspaceManager.enabled
            // Hole borders render on top (black line at the hole edge)
            z:            object.isHole
                              ? QGroundControl.zOrderMapItems + 1
                              : QGroundControl.zOrderMapItems

            // MouseArea {
            //     anchors.fill: parent
            //     onClicked: showZoneInfo(object)
            // }
        }

        onObjectAdded: {
            object.parent = map
            map.addMapItem(object)
        }
        onObjectRemoved: map.removeMapItem(object)
    }

    Rectangle {
        id:             zoneInfoPopup
        visible:        false
        anchors.margins: ScreenTools.defaultFontPixelHeight
        anchors.left:   parent.left
        anchors.top:    parent.top
        width:          zoneInfoColumn.width + ScreenTools.defaultFontPixelWidth * 2
        height:         zoneInfoColumn.height + ScreenTools.defaultFontPixelHeight
        color:          Qt.rgba(0, 0, 0, 0.75)
        radius:         ScreenTools.defaultFontPixelWidth * 0.5

        Column {
            id:             zoneInfoColumn
            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.5
            anchors.centerIn: parent
            spacing:        ScreenTools.defaultFontPixelHeight * 0.25

            QGCLabel { id: zoneInfoName;   color: "white"; font.pointSize: ScreenTools.mediumFontPointSize }
            QGCLabel { id: zoneInfoType;   color: "white" }
            QGCLabel { id: zoneInfoRadius; color: "white" }
            QGCLabel { id: zoneInfoAlt;    color: "white" }
            QGCLabel { id: zoneInfoReason; color: "white"; width: ScreenTools.defaultFontPixelWidth * 20; wrapMode: Text.WordWrap }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: zoneInfoPopup.visible = false
        }
    }
}
