/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtQuick.Layouts              1.11

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:             root

    width:          legendColumn.width + ScreenTools.defaultFontPixelWidth * 2
    height:         legendColumn.height + ScreenTools.defaultFontPixelHeight
    color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.85)
    radius:         ScreenTools.defaultFontPixelWidth * 0.5

    property var _airspaceManager: QGroundControl.airspaceManager

    QGCPalette { id: qgcPal }

    function toggle() {
        _airspaceManager.enabled = !_airspaceManager.enabled
    }

    // Column {
    //     id:             legendColumn
    //     anchors.margins: ScreenTools.defaultFontPixelHeight * 0.5
    //     anchors.centerIn: parent
    //     spacing:        ScreenTools.defaultFontPixelHeight * 0.25

    //     QGCLabel {
    //         text:           qsTr("🛡 Airspace Zones")
    //         font.pointSize: ScreenTools.smallFontPointSize
    //         font.bold:      true
    //     }

    //     Row {
    //         spacing: ScreenTools.defaultFontPixelWidth * 0.5

    //         QGCButton {
    //             text:       _airspaceManager.enabled ? qsTr("Hide") : qsTr("Show")
    //             width:      ScreenTools.defaultFontPixelWidth * 6
    //             height:     ScreenTools.defaultFontPixelHeight * 1.2
    //             onClicked:  root.toggle()
    //         }

    //         QGCLabel {
    //             text:       _airspaceManager.enabled ? qsTr("⏳ %1 zones").arg(_airspaceManager.zones.count) : qsTr("Disabled")
    //             anchors.verticalCenter: parent.verticalCenter
    //             font.pointSize: ScreenTools.smallFontPointSize
    //         }
    //     }

    //     Rectangle {
    //         width:  legendColumn.width
    //         height: 1
    //         color:  qgcPal.text
    //     }

    //     Row {
    //         spacing: ScreenTools.defaultFontPixelWidth * 0.5

    //         Rectangle {
    //             width:  ScreenTools.defaultFontPixelWidth * 1.5
    //             height: ScreenTools.defaultFontPixelWidth * 1.5
    //             radius: width * 0.5
    //             color:  Qt.rgba(1, 0, 0, 0.15)
    //             border.color: Qt.rgba(1, 0, 0, 0.6)
    //             border.width: 1
    //         }
    //         QGCLabel {
    //             text:       qsTr("RED = No fly")
    //             anchors.verticalCenter: parent.verticalCenter
    //             font.pointSize: ScreenTools.smallFontPointSize
    //         }
    //     }

    //     Row {
    //         spacing: ScreenTools.defaultFontPixelWidth * 0.5

    //         Rectangle {
    //             width:  ScreenTools.defaultFontPixelWidth * 1.5
    //             height: ScreenTools.defaultFontPixelWidth * 1.5
    //             radius: width * 0.5
    //             color:  Qt.rgba(1, 1, 0, 0.15)
    //             border.color: Qt.rgba(1, 1, 0, 0.6)
    //             border.width: 1
    //         }
    //         QGCLabel {
    //             text:       qsTr("YELLOW = Permission required")
    //             anchors.verticalCenter: parent.verticalCenter
    //             font.pointSize: ScreenTools.smallFontPointSize
    //         }
    //     }

    //     Row {
    //         spacing: ScreenTools.defaultFontPixelWidth * 0.5

    //         Rectangle {
    //             width:  ScreenTools.defaultFontPixelWidth * 1.5
    //             height: ScreenTools.defaultFontPixelWidth * 1.5
    //             radius: width * 0.5
    //             color:  Qt.rgba(0, 1, 0, 0.15)
    //             border.color: Qt.rgba(0, 1, 0, 0.6)
    //             border.width: 1
    //         }
    //         QGCLabel {
    //             text:       qsTr("GREEN = Free")
    //             anchors.verticalCenter: parent.verticalCenter
    //             font.pointSize: ScreenTools.smallFontPointSize
    //         }
    //     }

    //     Rectangle {
    //         width:  parent.width
    //         height: ScreenTools.defaultFontPixelHeight * 1.5
    //         color:  "transparent"
    //         radius: ScreenTools.defaultFontPixelWidth * 0.3

    //         Row {
    //             anchors.verticalCenter: parent.verticalCenter
    //             spacing: ScreenTools.defaultFontPixelWidth * 0.5

    //             Rectangle {
    //                 width:  ScreenTools.defaultFontPixelWidth * 0.8
    //                 height: ScreenTools.defaultFontPixelWidth * 0.8
    //                 radius: width * 0.5
    //                 anchors.verticalCenter: parent.verticalCenter
    //                 color: {
    //                     if (!_airspaceManager.hasToken)         return "gray"
    //                     if (_airspaceManager.proxyConnected)    return "#00cc00"
    //                     return "#cc0000"
    //                 }
    //             }

    //             QGCLabel {
    //                 anchors.verticalCenter: parent.verticalCenter
    //                 font.pointSize: ScreenTools.smallFontPointSize
    //                 text: {
    //                     if (!_airspaceManager.hasToken)         return qsTr("No cookie set")
    //                     if (_airspaceManager.proxyConnected)    return qsTr("Live DGCA data")
    //                     return qsTr("All tiles failed — showing demo zones")
    //                 }
    //                 color: {
    //                     if (!_airspaceManager.hasToken)         return qgcPal.warningText
    //                     if (_airspaceManager.proxyConnected)    return qgcPal.text
    //                     return qgcPal.warningText
    //                 }
    //             }
    //         }
    //     }
    // }
}
