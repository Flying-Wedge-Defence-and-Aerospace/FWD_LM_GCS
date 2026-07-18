/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0
import QGroundControl.Controllers           1.0
import QGroundControl.SettingsManager       1.0

Rectangle {
    id:                 _root
    color:              qgcPal.window
    anchors.fill:       parent
    anchors.margins:    ScreenTools.defaultFontPixelWidth

    property real   _valueFieldWidth:           ScreenTools.defaultFontPixelWidth * 15
    property var    _planViewSettings:          QGroundControl.settingsManager.planViewSettings

    QGCFlickable {
        anchors.fill: parent
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        flickableDirection: Flickable.VerticalFlick
        contentHeight:      settingsColumn.height
        contentWidth:       settingsColumn.width
        clip: true

        Column {
            id:                 settingsColumn
            width:              _root.width
            spacing:            ScreenTools.defaultFontPixelHeight * 0.5
            anchors.margins:    ScreenTools.defaultFontPixelWidth

            Item {
                width:              ScreenTools.defaultFontPixelWidth * 75
                height:             gcsLabel.height
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.horizontalCenter: parent.horizontalCenter
                QGCLabel {
                    id:             gcsLabel
                    text:           qsTr("Plan View Settings")
                    font.pointSize: 11
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: generalBox
                width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                height: firstLayout.height + 20    // height to fit 3 numbers
                radius: 6
                color: "transparent"
                border.color: "#888"
                anchors.horizontalCenter: parent.horizontalCenter

                ColumnLayout {
                    id: firstLayout
                    anchors.centerIn: parent
                    //anchors.margins: 8
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20

                        QGCLabel {
                            text: "Default Mission Altitude"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            Layout.preferredWidth:  _valueFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact:                   QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20

                        QGCLabel {
                            text: "VTOL Transition Distance"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            Layout.preferredWidth:  _valueFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact:                   QGroundControl.settingsManager.planViewSettings.vtolTransitionDistance
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20

                        QGCLabel {
                            text: "Use MAV_CMD_CONDITION_GATE for pattern generation"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            fact:   QGroundControl.settingsManager.planViewSettings.useConditionGate
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible:    _planViewSettings.takeoffItemNotRequired.visible

                        QGCLabel {
                            text: "Missions Do Not Require Takeoff Item"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            fact:       _planViewSettings.takeoffItemNotRequired
                        }
                    }
                }
            }
        }
    }

    // ColumnLayout {
    //     id: mainLayout
    //     anchors.top: parent.top
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     spacing: 10
    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

    //     QGCLabel {
    //         text: "Plan View Settings"
    //         font.bold: true
    //         font.pointSize: 11
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    //     }

    //     Rectangle {
    //         id: smallBox
    //         width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
    //         height: firstLayout.height + 20    // height to fit 3 numbers
    //         radius: 6
    //         color: "transparent"
    //         border.color: "#888"
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    //         ColumnLayout {
    //             id: firstLayout
    //             anchors.centerIn: parent
    //             //anchors.margins: 8
    //             spacing: ScreenTools.defaultFontPixelWidth * 2

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20

                //     QGCLabel {
                //         text: "Default Mission Altitude"
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //         visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactTextField {
                //         Layout.preferredWidth:  _valueFieldWidth
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact:                   QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
                //     }
                // }

                // Rectangle {
                //     height: 1
                //     Layout.fillWidth: true
                //     color: "gray"
                // }

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20

                //     QGCLabel {
                //         text: "VTOL Transition Distance"
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //         visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactTextField {
                //         Layout.preferredWidth:  _valueFieldWidth
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact:                   QGroundControl.settingsManager.planViewSettings.vtolTransitionDistance
                //     }
                // }

                // Rectangle {
                //     height: 1
                //     Layout.fillWidth: true
                //     color: "gray"
                // }

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20

                //     QGCLabel {
                //         text: "Use MAV_CMD_CONDITION_GATE for pattern generation"
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //         visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         fact:   QGroundControl.settingsManager.planViewSettings.useConditionGate
                //     }
                // }

                // Rectangle {
                //     height: 1
                //     Layout.fillWidth: true
                //     color: "gray"
                // }

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20
                //     visible:    _planViewSettings.takeoffItemNotRequired.visible

                //     QGCLabel {
                //         text: "Missions Do Not Require Takeoff Item"
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //         visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         fact:       _planViewSettings.takeoffItemNotRequired
                //     }
                // }
    //         }
    //     }
    // }
}
