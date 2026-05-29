/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import MAVLink                              1.0

//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    id:             _root
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    implicitWidth: batteryIndicatorRow.implicitWidth
    implicitHeight: batteryIndicatorRow.implicitHeight
    //width:          batteryIndicatorRow.width

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Repeater {
            id: batteryRepeater
            model: _activeVehicle ? _activeVehicle.batteries : 0

            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                sourceComponent:    batteryVisual

                property var battery: object
            }
        }

        Loader {
            visible: !_activeVehicle
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceComponent: batteryNoVehicleVisual
        }

    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, batteryPopup)
        }
    }

    Component {
        id: batteryVisual

        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            function getBatteryColor() {
                switch (battery.chargeState.rawValue) {
                case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                    return qgcPal.text
                case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                    return qgcPal.colorOrange
                case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                    return qgcPal.colorRed
                default:
                    return "white"
                }
            }

            function getBatteryPercentageText() {
                if (!isNaN(battery.percentRemaining.rawValue)) {
                    if (battery.percentRemaining.rawValue > 98.9) {
                        return qsTr("100%")
                    } else {
                        return battery.percentRemaining.valueString + battery.percentRemaining.units
                    }
                } else if (!isNaN(battery.voltage.rawValue)) {
                    return battery.voltage.valueString + battery.voltage.units
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return ""
            }

            QGCColoredImage {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              ScreenTools.isMobile ? height / 2 : height - 30
                sourceSize.width:   width
                source:             "/res/battery_icon"
                opacity:            (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? 1 : 0.5
                fillMode:           Image.PreserveAspectFit
                color:              /*getBatteryColor()/* _activeVehicle ? getBatteryColor() : "white"*/ "white"
            }

            // QGCLabel {
            //     text:                   /*getBatteryPercentageText()*/ _activeVehicle ? getBatteryPercentageText() : "N/A"
            //     //font.pointSize:         ScreenTools.mediumFontPointSize
            //     //color:                  "white" /*getBatteryColor()*/ _activeVehicle ? getBatteryColor() :*/
            //     color: "white"
            //     anchors.verticalCenter: parent.verticalCenter
            //     font.pointSize: ScreenTools.isMobile ? 8 : 12
            // }

            // QGCLabel {
            //     text:                   "  "
            //     //font.pointSize:         ScreenTools.mediumFontPointSize
            //     //color:                  "white" /*getBatteryColor()*/ _activeVehicle ? getBatteryColor() :*/
            //     color: "white"
            //     anchors.verticalCenter: parent.verticalCenter
            //     font.pointSize: ScreenTools.isMobile ? 8 : 12
            // }

            QGCLabel {
                text: (_activeVehicle && _activeVehicle.batteries && _activeVehicle.batteries.count > 0
                        && _activeVehicle.batteries.get(0))
                      ? _activeVehicle.batteries.get(0).voltage.valueString + "V"
                      : "N/A"
                //font.pointSize:         ScreenTools.mediumFontPointSize
                //color:                  "white" /*getBatteryColor()*/ _activeVehicle ? getBatteryColor() :*/
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                font.pointSize: ScreenTools.isMobile ? 8 : 12
            }
        }
    }

    Component {
        id: batteryNoVehicleVisual

        Row {
            spacing: 5
            anchors.top:    parent.top
            anchors.bottom: parent.bottom

            QGCColoredImage {
                anchors.top: parent.top
                source: "/res/battery_icon"
                anchors.bottom:     parent.bottom
                width:              height > 0 ? height / 2 : 30
                sourceSize.width:   width
                color: "white"
                opacity: 0.5
                fillMode: Image.PreserveAspectFit
            }


            QGCLabel {
                text: "N/A"
                //font.pointSize: ScreenTools.mediumFontPointSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                font.pointSize: ScreenTools.isMobile ? 8 : 8

                // ToolTip.visible: batteryInfo.containsMouse
                // ToolTip.text: "Battery Percentage"

                // MouseArea {
                //     id: batteryInfo
                //     anchors.fill: parent
                //     hoverEnabled: true
                // }
            }
        }
    }

    Component {
        id: batteryValuesAvailableComponent

        QtObject {
            property bool functionAvailable:        battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
            property bool temperatureAvailable:     !isNaN(battery.temperature.rawValue)
            property bool currentAvailable:         !isNaN(battery.current.rawValue)
            property bool mahConsumedAvailable:     !isNaN(battery.mahConsumed.rawValue)
            property bool timeRemainingAvailable:   !isNaN(battery.timeRemaining.rawValue)
            property bool chargeStateAvailable:     battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
        }
    }

    Component {
        id: batteryPopup

        Rectangle {
            width:          mainLayout.width   + mainLayout.anchors.margins * 2
            height:         mainLayout.height  + mainLayout.anchors.margins * 2
            radius:         ScreenTools.defaultFontPixelHeight / 2
            color:          qgcPal.window
            border.color:   qgcPal.text

            ColumnLayout {
                id:                 mainLayout
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.top:        parent.top
                anchors.right:      parent.right
                spacing:            ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.alignment:   Qt.AlignCenter
                    text:               qsTr("Battery Status")
                    font.family:        ScreenTools.demiboldFontFamily
                    font.pointSize: ScreenTools.isMobile ? 8 : 12
                }

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    ColumnLayout {
                        Repeater {
                            model: _activeVehicle ? _activeVehicle.batteries : 0

                            ColumnLayout {
                                spacing: 0

                                property var batteryValuesAvailable: nameAvailableLoader.item

                                Loader {
                                    id:                 nameAvailableLoader
                                    sourceComponent:    batteryValuesAvailableComponent

                                    property var battery: object
                                }

                                QGCLabel { text: qsTr("Battery %1").arg(object.id.rawValue); font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Charge State");                          visible: batteryValuesAvailable.chargeStateAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Remaining");                             visible: batteryValuesAvailable.timeRemainingAvailable; color: ScreenTools.isMobile ? "white" : "white" ;font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Remaining"); font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Voltage"); font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Consumed");                              visible: batteryValuesAvailable.mahConsumedAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Temperature");                           visible: batteryValuesAvailable.temperatureAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: qsTr("Function");                              visible: batteryValuesAvailable.functionAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                            }
                        }
                    }

                    ColumnLayout {
                        Repeater {
                            model: _activeVehicle ? _activeVehicle.batteries : 0

                            ColumnLayout {
                                spacing: 0

                                property var batteryValuesAvailable: valueAvailableLoader.item

                                Loader {
                                    id:                 valueAvailableLoader
                                    sourceComponent:    batteryValuesAvailableComponent

                                    property var battery: object
                                }

                                QGCLabel { text: "" ; font.pointSize: ScreenTools.isMobile ? 8 : 12}
                                QGCLabel { text: object.chargeState.enumStringValue;                                        visible: batteryValuesAvailable.chargeStateAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: object.timeRemainingStr.value;                                             visible: batteryValuesAvailable.timeRemainingAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: object.percentRemaining.valueString + " " + object.percentRemaining.units; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: object.voltage.valueString + " " + object.voltage.units; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: object.mahConsumed.valueString + " " + object.mahConsumed.units;           visible: batteryValuesAvailable.mahConsumedAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: object.temperature.valueString + " " + object.temperature.units;           visible: batteryValuesAvailable.temperatureAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                                QGCLabel { text: object.function.enumStringValue;                                           visible: batteryValuesAvailable.functionAvailable; font.pointSize: ScreenTools.isMobile ? 8 : 12 }
                            }
                        }
                    }
                }
            }
        }
    }
}
