/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.15
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QtGraphicalEffects 1.0

import QGroundControl               1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

Rectangle {
    id: _root
    color: "#700000"

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool openProfile: false

    // Only show these flight modes. Matching ignores case, spaces and
    // punctuation so ArduPilot's own names match, e.g. "QHover" -> "qhover"
    // matches "q-hover", and "FBWA" matches "fbw a".
    property var _filteredFlightModes: _calcFilteredModes()
    property var _allowedModes: ["fbw a","stabilize","rtl","auto","guided","q-stabilize","q-hover","q-loiter","q-land","q-rtl"]

    // QGC's own fallback list (used only if the vehicle does not answer
    // AVAILABLE_MODES) spells the Q modes out in full. This maps those to
    // the canonical names above. It only affects matching - the label shown
    // is always whatever the vehicle/plugin reported.
    property var _modeAliases: {
        "quadplanestabilize": "q-stabilize",
        "quadplanehover":     "q-hover",
        "quadplaneloiter":    "q-loiter",
        "quadplaneland":      "q-land",
        "quadplanertl":       "q-rtl"
    }

    function _normalizeModeName(mode) {
        return mode.toLowerCase().replace(/[^a-z0-9]/g, "")
    }

    function _canonicalModeName(mode) {
        var normalized = _normalizeModeName(mode)
        if (_modeAliases[normalized] !== undefined) {
            return _normalizeModeName(_modeAliases[normalized])
        }
        return normalized
    }

    function _isModeAllowed(mode) {
        var canonical = _canonicalModeName(mode)
        for (var i = 0; i < _allowedModes.length; i++) {
            if (_normalizeModeName(_allowedModes[i]) === canonical) {
                return true
            }
        }
        return false
    }

    function _calcFilteredModes() {
        if (!_activeVehicle) return []
        var modes = _activeVehicle.flightModes
        //console.log("FWDGCS flightModes from vehicle:", JSON.stringify(modes))
        return modes.filter(function(m) { return _isModeAllowed(m) })
    }
    on_ActiveVehicleChanged: _filteredFlightModes = _calcFilteredModes()
    Connections {
        target: _activeVehicle
        onFlightModesChanged: _filteredFlightModes = _calcFilteredModes()
    }

    signal logOutRequested

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
                            backRadius: 7
                            Layout.fillWidth: true
                            onClicked: {
                                _activeVehicle.flightMode = text
                                mainWindow.hideIndicatorPopup()
                            }
                        }
                    }
                }
            }
        }
    }

    QGCColoredImage {
        id: logo
        height:     ScreenTools.defaultFontPixelHeight * 2.5
        width:      height + 8
        source: "/res/FWD_only_logo"
        color: "white"
        anchors.left: parent.left
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
        //anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    QGCFlickable {
        id: toolsFlickable
        visible: planView.visible
        anchors.left: logo.right
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 3
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: toolsRightLayout.left
        contentWidth: indicatorLoader.x + indicatorLoader.width
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        Loader {
            id: indicatorLoader
            x: ScreenTools.defaultFontPixelWidth / 2
            y: ScreenTools.defaultFontPixelWidth / 2
            source: planView.visible ? "qrc:/qml/PlanToolBarIndicators.qml" : ""
        }
    }

    // RowLayout {
    //     id: toolsLayout
    //     anchors.left: parent.left
    //     anchors.top: parent.top
    //     anchors.bottom: parent.bottom
    //     spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 1

    //     Item {
    //         Layout.fillHeight: true
    //     }

    //     QGCToolBarButton {
    //         id: profileButton
    //         icon.source: "/res/profile_icon"
    //         onClicked:{
    //             if(!openProfile){
    //                 openProfile = true
    //             } else {
    //                 openProfile = false
    //             }
    //         }
    //     }

    //     Rectangle {
    //         Layout.preferredHeight: parent.height
    //         width: 1
    //         opacity: 0.5
    //     }

    //     // QGCLabel {
    //     //     text: _activeVehicle ? /*_activeVehicle.firmwareTypeString + " - " +*/ _activeVehicle.vehicleTypeString
    //     //                          : qsTr("No Vehicle")
    //     //     color: "white"
    //     //     font.bold: true
    //     // }

    //     // Rectangle {
    //     //     Layout.preferredHeight: parent.height
    //     //     width: 1
    //     //     opacity: 0.5
    //     // }

        // QGCToolBarButton {
        //     id: settingsButton
        //     icon.source: "/res/settings_icon"
        //     onClicked: mainWindow.showSettingsTool()
        // }

        // Rectangle {
        //     Layout.preferredHeight: parent.height
        //     width: 1
        //     opacity: 0.5
        // }

    //     QGCToolBarButton {
    //         onClicked: mainWindow.showAnalyzeTool()
    //         icon.source: "/res/log_icon"
    //     }

    //     Rectangle {
    //         Layout.preferredHeight: parent.height
    //         width: 1
    //         opacity: 0.5
    //     }

    //     QGCToolBarButton {
    //         onClicked: mainWindow.showSetupTool()
    //         icon.source: "/res/uav"
    //     }

    //     Rectangle {
    //         Layout.preferredHeight: parent.height
    //         width: 1
    //         opacity: 0.5
    //     }

    //     QGCToolBarButton {
    //         id: planButton
    //         onClicked: mainWindow.showPlanView()
    //         icon.source: "/res/plan_icon"
    //     }

    //     Rectangle {
    //         Layout.preferredHeight: parent.height
    //         width: 1
    //         opacity: 0.5
    //     }

    //     QGCToolBarButton {
    //         id: flyButton
    //         onClicked: mainWindow.showFlyView()
    //         icon.source: "/res/fly_icon"
    //     }

    //     Rectangle {
    //         Layout.preferredHeight: parent.height
    //         width: 1
    //         opacity: 0.5
    //     }

    //     Loader {
    //         id: mvls
    //         //Layout.leftMargin: 12
    //         //Layout.fillHeight: true
    //         Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    //         Layout.preferredWidth: item ? item.implicitWidth : 0
    //         Layout.preferredHeight: item ? item.implicitHeight : 0
    //         source: "qrc:/toolbar/MultiVehicleSelector.qml"
    //         visible:                QGroundControl.multiVehicleManager.vehicles.count >= 2
    //     }

    //     Rectangle {
    //         Layout.preferredHeight: parent.height
    //         width: 1
    //         visible: mvls.visible
    //         opacity: 0.5
    //     }
    // }

    RowLayout {
        id: toolsRightLayout
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: ScreenTools.defaultFontPixelWidth * 1.5

        Rectangle {
            Layout.preferredHeight: parent.height
            width: 1
            opacity: 0.5
        }

        Loader {
            id: mvls
            //Layout.leftMargin: 12
            //Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.preferredWidth: item ? item.implicitWidth : 0
            Layout.preferredHeight: item ? item.implicitHeight : 0
            source: "qrc:/toolbar/MultiVehicleSelector.qml"
            visible:                QGroundControl.multiVehicleManager.vehicles.count >= 2 && !planView.visible
        }

        Rectangle {
            Layout.preferredHeight: parent.height
            width: 1
            visible: mvls.visible
            opacity: 0.5
        }

        // Item {
        //     id: rightToolsContainer
        //     Layout.preferredWidth: ScreenTools.isMobile ? toolsRow.width /*(ScreenTools.defaultFontPixelWidth * 45)*/ : toolsRow.width
        //     Layout.fillHeight: true

        //     Flickable {
        //         anchors.fill: parent
        //         contentWidth: toolsRow.implicitWidth
        //         contentHeight: height
        //         flickableDirection: Flickable.HorizontalFlick
        //         clip: true

        //         RowLayout {
        //             id: toolsRow
        //             spacing: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth / 3 : ScreenTools.defaultFontPixelWidth * 4

                    // Rectangle {
                    //     Layout.preferredHeight: _root.height
                    //     width: 1
                    //     opacity: 0.5
                    //     color: "white"
                    // }

                    MainStatusIndicator {
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter
                        visible: !planView.visible
                    }

                    Rectangle {
                        Layout.preferredHeight: _root.height
                        width: 1
                        opacity: 0.5
                        color: "white"
                        visible: !planView.visible
                    }

                    Item {
                        id: centerContainer
                        implicitWidth: ScreenTools.isMobile ? 200 : mainStatusRect.width + (ScreenTools.defaultFontPixelWidth)
                        height: parent.height
                        visible: !planView.visible

                        Rectangle {
                            id: mainStatusRect
                            color: "gray" // or dynamic color
                            radius: 15
                            anchors.centerIn: parent
                            width: modeLabel.contentWidth + 20
                            height: ScreenTools.isMobible ? modeLabel.contentHeight + 20 : modeLabel.contentHeight + 15

                            QGCLabel {
                                id: modeLabel
                                anchors.centerIn: parent
                                text: _activeVehicle ? _activeVehicle.flightMode : qsTr("N/A")
                                color: "white"
                                font.pointSize: ScreenTools.isMobile ? 8 : 11

                                ToolTip.visible: flightMode.containsMouse
                                ToolTip.text: "Mode"
                            }

                            MouseArea {
                                id: flightMode
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (_activeVehicle) {
                                        mainWindow.showIndicatorPopup(modeLabel, flightModeMenu)
                                    }
                                }
                            }
                        }
                    }

                    // Rectangle {
                    //     Layout.preferredHeight: parent.height
                    //     width: 1
                    //     opacity: 0.5
                    //     color: "white"
                    // }

                    // Loader {
                    //     id: messageIndicatorLoader
                    //     //Layout.leftMargin: 12
                    //     Layout.fillHeight: true
                    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    //     Layout.preferredWidth: item ? item.implicitWidth : 0
                    //     Layout.preferredHeight: item ? item.implicitHeight : 0
                    //     //Layout.preferredWidth: ScreenTools.isMobile ? 120 : 65
                    //     source: "qrc:/toolbar/MessageIndicator.qml"
                    //     //visible: item && item.showIndicator
                    // }


                    Rectangle {
                        Layout.preferredHeight: _root.height
                        width: 1
                        opacity: 0.5
                        color: "white"
                        visible: !planView.visible
                    }

                    Loader {
                        id: messageIndicatorLoader1
                        //Layout.leftMargin: 12
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.preferredWidth: item ? item.implicitWidth : 0
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        source: "qrc:/toolbar/GPSIndicator.qml"
                        visible: !planView.visible
                    }

                    Rectangle {
                        Layout.preferredHeight: _root.height
                        width: 1
                        opacity: 0.5
                        color: "white"
                        visible: !planView.visible
                    }

                    Loader {
                        id: batteryIndicatorLoader
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.preferredWidth: item ? item.implicitWidth : 0
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        source: "qrc:/toolbar/BatteryIndicator.qml"
                        visible: !planView.visible
                    }

                    Rectangle {
                        Layout.preferredHeight: _root.height
                        width: 1
                        opacity: 0.5
                        color: "white"
                        visible: !planView.visible
                    }

                    Loader {
                        id: rcRssiLoader
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        Layout.preferredWidth: item ? item.implicitWidth : 0
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        source: "qrc:/toolbar/RCRSSIIndicator.qml"
                        visible: !planView.visible
                    }

                    Rectangle {
                        Layout.preferredHeight: parent.height
                        width: 1
                        opacity: 0.5
                    }

                    QGCToolBarButton {
                        id: flyButton
                        onClicked: mainWindow.showFlyView()
                        icon.source: "/res/fly_icon"
                    }

                    Rectangle {
                        Layout.preferredHeight: parent.height
                        width: 1
                        opacity: 0.5
                    }

                    QGCToolBarButton {
                        id: planButton
                        onClicked: mainWindow.showPlanView()
                        icon.source: "/res/plan_icon"
                    }

                    Rectangle {
                        Layout.preferredHeight: parent.height
                        width: 1
                        opacity: 0.5
                    }

                    QGCToolBarButton {
                        onClicked: mainWindow.showSetupTool()
                        icon.source: "/res/uav"
                    }

                    Rectangle {
                        Layout.preferredHeight: parent.height
                        width: 1
                        opacity: 0.5
                    }

                    QGCToolBarButton {
                        onClicked: mainWindow.showAnalyzeTool()
                        icon.source: "/res/log_icon"
                    }

                    Rectangle {
                        Layout.preferredHeight: _root.height
                        width: 1
                        opacity: 0.5
                        color: "white"
                    }

                    QGCToolBarButton {
                        id: settingsButton
                        icon.source: "/res/settings_icon"
                        onClicked: mainWindow.showSettingsTool()
                    }

                    // Rectangle {
                    //     Layout.preferredHeight: _root.height
                    //     width: 1
                    //     opacity: 0.5
                    //     color: "white"
                    // }

                    // // Item {
                    // //     Layout.fillHeight: true
                    // // }

                    // Loader {
                    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    //     Layout.preferredWidth: item ? item.implicitWidth : 0
                    //     Layout.preferredHeight: /*item ? item.implicitHeight : 0*/ 40
                    //     source: "qrc:/toolbar/GimbalIndicator.qml"
                    //     //visible: item && item.showIndicator
                    // }

                    // Rectangle {
                    //     Layout.preferredHeight: parent.height
                    //     width: 1
                    //     opacity: 0.5
                    //     color: "white"
                    // }

                    // Loader {
                    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    //     Layout.preferredWidth: item ? item.implicitWidth : 0
                    //     Layout.preferredHeight: ScreenTools.defaultFontPixelWidth * 5
                    //     source: "qrc:/toolbar/RemoteIDIndicator.qml"
                    // }

                    // Rectangle {
                    //     Layout.preferredHeight: parent.height
                    //     width: 1
                    //     opacity: 0.5
                    //     color: "white"
                    // }

                    // Loader {
                    //     Layout.fillHeight: true
                    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    //     Layout.preferredWidth: item ? item.implicitWidth : 0
                    //     Layout.preferredHeight: 40
                    //     source: "qrc:/toolbar/TelemetryRSSIIndicator.qml"
                    // }

                    // Rectangle {
                    //     Layout.preferredHeight: parent.height
                    //     width: 1
                    //     opacity: 0.5
                    //     color: "white"
                    // }

                    // Loader {
                    //     //id: batteryIndicatorLoader
                    //     //Layout.leftMargin: ScreenTools.isMobile? 20 : 12
                    //     Layout.fillHeight: true
                    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    //     Layout.preferredWidth: item ? item.implicitWidth : 0
                    //     Layout.preferredHeight: 40
                    //     //implicitWidth: contentItem.implicitWidth
                    //     //Layout.preferredWidth: ScreenTools.isMobile ? 145 : 100
                    //     source: "qrc:/toolbar/MultiVehicleSelector.qml"
                    //     //visible: item && item.showIndicator
                    // }

                    // Loader {
                    //     //id: batteryIndicatorLoader
                    //     //Layout.leftMargin: ScreenTools.isMobile? 20 : 12
                    //     //Layout.fillHeight: true
                    //     Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    //     Layout.preferredWidth: item ? item.implicitWidth : 0
                    //     Layout.preferredHeight: 30
                    //     //implicitWidth: contentItem.implicitWidth
                    //     //Layout.preferredWidth: ScreenTools.isMobile ? 145 : 100
                    //     source: "qrc:/toolbar/GPSRTKIndicator.qml"
                    //     //visible: item && item.showIndicator
                    // }

                    Item {
                        Layout.fillHeight: true
                    }
            //    }
          //  }
        //}
    }

    Rectangle {
        id: profileInfo
        implicitWidth: infoLayout.width + (ScreenTools.defaultFontPixelWidth *5)
        implicitHeight: infoLayout.height + (ScreenTools.defaultFontPixelWidth * 2)
        color: "#88000000"
        visible: openProfile
        radius: ScreenTools.defaultFontPixelWidth

        anchors.top: parent.top
        anchors.topMargin: ScreenTools.toolbarHeight + (ScreenTools.defaultFontPixelWidth)
        anchors.left: parent.left
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 2

        ColumnLayout {
            id: infoLayout
            anchors.centerIn: parent

            QGCLabel {
                text: "Profile Status"
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                QGCLabel {
                    //Layout.alignment: Qt.AlignHCenter
                    text: "Username"
                }
                QGCLabel {
                    Layout.alignment: Qt.AlignHCenter
                    text: "---"
                }
            }

            QGCButton {
                text: "Logout"
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    logOutRequested()
                }
            }
        }
    }

}
