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

    property Fact _useChecklist:                QGroundControl.settingsManager.appSettings.useChecklist
    property Fact _enforceChecklist:            QGroundControl.settingsManager.appSettings.enforceChecklist
    property Fact _keepMapCenteredOnVehicle:    QGroundControl.settingsManager.flyViewSettings.keepMapCenteredOnVehicle
    property Fact _showLogReplayStatusBar:      QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar
    property Fact _showDumbCameraControl:       QGroundControl.settingsManager.flyViewSettings.showSimpleCameraControl
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property real   _valueFieldWidth:           ScreenTools.defaultFontPixelWidth * 16
    property Fact _updateHomePosition:          QGroundControl.settingsManager.flyViewSettings.updateHomePosition
    property Fact _virtualJoystick:                     QGroundControl.settingsManager.appSettings.virtualJoystick
    property Fact _virtualJoystickAutoCenterThrottle:   QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact _showAdditionalIndicatorsCompass: QGroundControl.settingsManager.flyViewSettings.showAdditionalIndicatorsCompass
    property Fact _lockNoseUpCompass: QGroundControl.settingsManager.flyViewSettings.lockNoseUpCompass


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
                    text:           qsTr("General")
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
                        visible: _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length

                        QGCLabel {
                            text: qsTr("Use Preflight Checklist")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            id: useCheckList
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _useChecklist
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                    }

                    RowLayout {
                        id: enfCL
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: useCheckList.visible && _enforceChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length

                        property bool isEnabled: QGroundControl.settingsManager.appSettings.useChecklist.value

                        QGCLabel {
                            text: qsTr("Enforce Preflight Checklist")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            opacity: enfCL.isEnabled ? 1.0 : 0.4
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            enabled:        QGroundControl.settingsManager.appSettings.useChecklist.value
                            opacity: enfCL.isEnabled ? 1.0 : 0.4
                            fact: _enforceChecklist
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
                        visible: _keepMapCenteredOnVehicle.visible

                        QGCLabel {
                            text: qsTr("Keep Map Centered On Vehicle")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _keepMapCenteredOnVehicle
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
                        visible: _showLogReplayStatusBar.visible

                        QGCLabel {
                            text: qsTr("Show Telemetry Log Replay Status Bar")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _showLogReplayStatusBar
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
                        visible:  _showDumbCameraControl.visible

                        QGCLabel {
                            text: qsTr("Show simple camera controls (DIGICAM_CONTROL)")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _showDumbCameraControl
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
                        visible:  _updateHomePosition.visible

                        QGCLabel {
                            text: qsTr("Update return to home position based on device location")
                            font.pointSize: 9
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _updateHomePosition
                        }
                    }
                }
            }

            Item {
                width:              ScreenTools.defaultFontPixelWidth * 75
                height:             gcsLabel.height
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.horizontalCenter: parent.horizontalCenter
                QGCLabel {
                    id:             guidedComm
                    text:           qsTr("Guided Commands")
                    font.pointSize: 11
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: guidedCommBox
                width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                height: guidedCommLayout.height + 20    // height to fit 3 numbers
                radius: 6
                color: "transparent"
                border.color: "#888"
                anchors.horizontalCenter: parent.horizontalCenter

                ColumnLayout {
                    id: guidedCommLayout
                    anchors.centerIn: parent
                    //anchors.margins: 8
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: guidedMinAltField.visible

                        QGCLabel {
                            text: qsTr("Minimum Altitude")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            id:                     guidedMinAltField
                            Layout.preferredWidth:  _valueFieldWidth
                            visible:                fact.visible
                            fact:                   _flyViewSettings.guidedMinimumAltitude
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
                        visible: guidedMaxAltField.visible

                        QGCLabel {
                            text: qsTr("Maximum Altitude")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            id:                     guidedMaxAltField
                            Layout.preferredWidth:  _valueFieldWidth
                            visible:                fact.visible
                            fact:                   _flyViewSettings.guidedMaximumAltitude
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
                        visible: locMaxDist.visible

                        QGCLabel {
                            text: qsTr("Go To Location Max Distance")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            id:                     locMaxDist
                            Layout.preferredWidth:  _valueFieldWidth
                            fact:                   _flyViewSettings.maxGoToLocationDistance
                        }
                    }
                }
            }

            Item {
                width:              ScreenTools.defaultFontPixelWidth * 75
                height:             gcsLabel.height
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.horizontalCenter: parent.horizontalCenter
                QGCLabel {
                    id:             virtJoy
                    text:           qsTr("Virtual Joystick")
                    font.pointSize: 11
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: virtJoyBox
                width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                height: virtJoyLayout.height + 20    // height to fit 3 numbers
                radius: 6
                color: "transparent"
                border.color: "#888"
                anchors.horizontalCenter: parent.horizontalCenter

                ColumnLayout {
                    id: virtJoyLayout
                    anchors.centerIn: parent
                    //anchors.margins: 8
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: _virtualJoystick.visible

                        QGCLabel {
                            text: qsTr("Enabled")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _virtualJoystick
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                    }

                    RowLayout {
                        id: act
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: _virtualJoystickAutoCenterThrottle.visible

                        property bool isEnabled: _virtualJoystick.value

                        QGCLabel {
                            text: qsTr("Auto-Center Throttle")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            opacity: act.isEnabled ? 1.0 : 0.4
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _virtualJoystickAutoCenterThrottle
                            enabled:        _virtualJoystick.value
                            opacity: act.isEnabled ? 1.0 : 0.4
                        }
                    }
                }
            }

            Item {
                width:              ScreenTools.defaultFontPixelWidth * 75
                height:             gcsLabel.height
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.horizontalCenter: parent.horizontalCenter
                QGCLabel {
                    id:             insPanel
                    text:           qsTr("Instrument Panel")
                    font.pointSize: 11
                    font.family:    ScreenTools.demiboldFontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: insPanelBox
                width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                height: insPanelLayout.height + 20    // height to fit 3 numbers
                radius: 6
                color: "transparent"
                border.color: "#888"
                anchors.horizontalCenter: parent.horizontalCenter

                ColumnLayout {
                    id: insPanelLayout
                    anchors.centerIn: parent
                    //anchors.margins: 8
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: _showAdditionalIndicatorsCompass.visible

                        QGCLabel {
                            text: qsTr("Show additional heading indicators on Compass")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _showAdditionalIndicatorsCompass
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
                        visible:  _lockNoseUpCompass.visible

                        QGCLabel {
                            text: qsTr("Lock Compass Nose-Up")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact: _lockNoseUpCompass
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
    //         text: "General"
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
                //     visible: _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length

                //     QGCLabel {
                //         text: qsTr("Use Preflight Checklist")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         id: useCheckList
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _useChecklist
                //     }
                // }

                // Rectangle {
                //     height: 1
                //     Layout.fillWidth: true
                //     color: "gray"
                // }

                // RowLayout {
                //     id: enfCL
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20
                //     visible: useCheckList.visible && _enforceChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length

                //     property bool isEnabled: QGroundControl.settingsManager.appSettings.useChecklist.value

                //     QGCLabel {
                //         text: qsTr("Enforce Preflight Checklist")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //         opacity: enfCL.isEnabled ? 1.0 : 0.4
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         enabled:        QGroundControl.settingsManager.appSettings.useChecklist.value
                //         opacity: enfCL.isEnabled ? 1.0 : 0.4
                //         fact: _enforceChecklist
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
                //     visible: _keepMapCenteredOnVehicle.visible

                //     QGCLabel {
                //         text: qsTr("Keep Map Centered On Vehicle")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _keepMapCenteredOnVehicle
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
                //     visible: _showLogReplayStatusBar.visible

                //     QGCLabel {
                //         text: qsTr("Show Telemetry Log Replay Status Bar")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _showLogReplayStatusBar
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
                //     visible:  _showDumbCameraControl.visible

                //     QGCLabel {
                //         text: qsTr("Show simple camera controls (DIGICAM_CONTROL)")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _showDumbCameraControl
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
                //     visible:  _updateHomePosition.visible

                //     QGCLabel {
                //         text: qsTr("Update return to home position based on device location")
                //         font.pointSize: 9
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _updateHomePosition
                //     }
                // }
    //         }
    //     }

    //     QGCLabel {
    //         text: "Guided Commands"
    //         font.bold: true
    //         font.pointSize: 11
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    //     }

    //     Rectangle {
    //         //id: smallBox
    //         width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
    //         height: guidedComLayout.height + 20    // height to fit 3 numbers
    //         radius: 6
    //         color: "transparent"
    //         border.color: "#888"
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    //         ColumnLayout {
    //             id: guidedComLayout
    //             anchors.centerIn: parent
    //             //anchors.margins: 8
    //             spacing: ScreenTools.defaultFontPixelWidth * 2

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20
                //     visible: guidedMinAltField.visible

                //     QGCLabel {
                //         text: qsTr("Minimum Altitude")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactTextField {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         id:                     guidedMinAltField
                //         Layout.preferredWidth:  _valueFieldWidth
                //         visible:                fact.visible
                //         fact:                   _flyViewSettings.guidedMinimumAltitude
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
                //     visible: guidedMaxAltField.visible

                //     QGCLabel {
                //         text: qsTr("Maximum Altitude")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactTextField {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         id:                     guidedMaxAltField
                //         Layout.preferredWidth:  _valueFieldWidth
                //         visible:                fact.visible
                //         fact:                   _flyViewSettings.guidedMaximumAltitude
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
                //     visible: locMaxDist.visible

                //     QGCLabel {
                //         text: qsTr("Go To Location Max Distance")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactTextField {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         id:                     locMaxDist
                //         Layout.preferredWidth:  _valueFieldWidth
                //         fact:                   _flyViewSettings.maxGoToLocationDistance
                //     }
                // }
    //         }
    //     }

    //     QGCLabel {
    //         text: "Virtual Joystick"
    //         font.bold: true
    //         font.pointSize: 11
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    //     }

    //     Rectangle {
    //         //id: smallBox
    //         width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
    //         height: joystickLayout.height + 20    // height to fit 3 numbers
    //         radius: 6
    //         color: "transparent"
    //         border.color: "#888"
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    //         ColumnLayout {
    //             id: joystickLayout
    //             anchors.centerIn: parent
    //             //anchors.margins: 8
    //             spacing: ScreenTools.defaultFontPixelWidth * 2

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20
                //     visible: _virtualJoystick.visible

                //     QGCLabel {
                //         text: qsTr("Enabled")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _virtualJoystick
                //     }
                // }

                // Rectangle {
                //     height: 1
                //     Layout.fillWidth: true
                //     color: "gray"
                // }

                // RowLayout {
                //     id: act
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20
                //     visible: _virtualJoystickAutoCenterThrottle.visible

                //     property bool isEnabled: _virtualJoystick.value

                //     QGCLabel {
                //         text: qsTr("Auto-Center Throttle")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //         opacity: act.isEnabled ? 1.0 : 0.4
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _virtualJoystickAutoCenterThrottle
                //         enabled:        _virtualJoystick.value
                //         opacity: act.isEnabled ? 1.0 : 0.4
                //     }
                // }
    //         }
    //     }

    //     QGCLabel {
    //         text: "Instrument Panel"
    //         font.bold: true
    //         font.pointSize: 11
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    //     }

    //     Rectangle {
    //         //id: smallBox
    //         width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
    //         height: joystickLayout.height + 20    // height to fit 3 numbers
    //         radius: 6
    //         color: "transparent"
    //         border.color: "#888"
    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    //         ColumnLayout {
    //             //id: joystickLayout
    //             anchors.centerIn: parent
    //             //anchors.margins: 8
    //             spacing: ScreenTools.defaultFontPixelWidth * 2

                // RowLayout {
                //     Layout.fillWidth: true
                //     Layout.alignment: Qt.AlignVCenter
                //     spacing: 20
                //     visible: _showAdditionalIndicatorsCompass.visible

                //     QGCLabel {
                //         text: qsTr("Show additional heading indicators on Compass")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _showAdditionalIndicatorsCompass
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
                //     visible:  _lockNoseUpCompass.visible

                //     QGCLabel {
                //         text: qsTr("Lock Compass Nose-Up")
                //         font.pointSize: 10
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                //         horizontalAlignment: Text.AlignLeft
                //     }

                //     Item { Layout.fillWidth: true }

                //     FactToggleSwitch {
                //         Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                //         fact: _lockNoseUpCompass
                //     }
                // }
    //         }
    //     }
    // }
    }
}
