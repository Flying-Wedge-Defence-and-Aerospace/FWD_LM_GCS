/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.11
import QtQuick.Layouts 1.11

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.MultiVehicleManager 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0

Item {
    id:                     _root
    Layout.preferredWidth:  rowLayout.width

    property real fontPointSize: ScreenTools.largeFontPointSize
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // Only show specific flight modes (case-insensitive matching)
    property var _filteredFlightModes: _calcFilteredModes()
    property var _allowedModes: ["stabilize","stabilized","loiter","hold","guided","auto","mission","altitude hold","altitude","depth hold","rtl","return","land","surface"]
    function _calcFilteredModes() {
        if (!activeVehicle) return []
        return activeVehicle.flightModes.filter(function(m) { return _allowedModes.indexOf(m.toLowerCase()) !== -1 })
    }
    onActiveVehicleChanged: _filteredFlightModes = _calcFilteredModes()
    Connections {
        target: activeVehicle
        onFlightModesChanged: _filteredFlightModes = _calcFilteredModes()
    }

    Component {
        id: flightModeMenu

        Rectangle {
            width: flickable.width + (ScreenTools.defaultFontPixelWidth * 2)
            height: flickable.height + (ScreenTools.defaultFontPixelWidth * 2)
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            color: qgcPal.window
            border.color: qgcPal.text

            QGCFlickable {
                id: flickable
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.top: parent.top
                anchors.left: parent.left
                width: mainLayout.width
                height: _fullWindowHeight <= mainLayout.height ? _fullWindowHeight : mainLayout.height
                flickableDirection: Flickable.VerticalFlick
                contentHeight: mainLayout.height
                contentWidth: mainLayout.width

                property real _fullWindowHeight: mainWindow.contentItem.height - (indicatorPopup.padding * 2) - (ScreenTools.defaultFontPixelWidth * 2)

                ColumnLayout {
                    id: mainLayout
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    Repeater {
                        model: _filteredFlightModes

                        QGCButton {
                            text: modelData
                            Layout.fillWidth: true
                            onClicked: {
                                activeVehicle.flightMode = text
                                mainWindow.hideIndicatorPopup()
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id:         rowLayout
        spacing:    0
        height:     parent.height

        QGCColoredImage {
            id:         flightModeIcon
            width:      ScreenTools.defaultFontPixelWidth * 2
            height:     ScreenTools.defaultFontPixelHeight * 0.75
            fillMode:   Image.PreserveAspectFit
            mipmap:     true
            color:      qgcPal.text
            source:     "/qmlimages/FlightModesComponentIcon.png"
            Layout.alignment:   Qt.AlignVCenter
        }

        Item {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth / 2
            height:                 1
        }

        QGCLabel {
            text:               activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
            font.pointSize:     fontPointSize
            Layout.alignment:   Qt.AlignVCenter
        }
    }

    QGCMouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorPopup(_root, flightModeMenu)
    }
}
