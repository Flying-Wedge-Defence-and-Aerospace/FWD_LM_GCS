/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


// import QtQuick                  2.3
// import QtQuick.Controls         1.2
// import QtQuick.Controls.Styles  1.4
// import QtQuick.Dialogs          1.2
// import QtQuick.Layouts          1.2

// import QGroundControl                       1.0
// import QGroundControl.FactSystem            1.0
// import QGroundControl.FactControls          1.0
// import QGroundControl.Controls              1.0
// import QGroundControl.ScreenTools           1.0
// import QGroundControl.MultiVehicleManager   1.0
// import QGroundControl.Palette               1.0
// import QGroundControl.Controllers           1.0
// import QGroundControl.SettingsManager       1.0

// Rectangle {
//     id:                 _root
//     color:              qgcPal.window
//     anchors.fill:       parent
//     anchors.margins:    ScreenTools.defaultFontPixelWidth

//     property real _valueWidth:          ScreenTools.defaultFontPixelWidth * 24
    //  property real   _comboFieldWidth:           ScreenTools.defaultFontPixelWidth * 30
    // property real   _valueFieldWidth:           ScreenTools.defaultFontPixelWidth * 10
    // property string gpsDisabled: "Disabled"
    // property string gpsUdpPort:  "UDP Port"

//     ColumnLayout {
//         id: mainLayout
//         anchors.top: parent.top
//         anchors.horizontalCenter: parent.horizontalCenter
//         spacing: 10
//         Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        // QGCLabel {
        //     text: "AutoConnect"
        //     font.bold: true
        //     font.pointSize: 11
        //     Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        // }

        // Rectangle {
        //     id: smallBox
        //     width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
        //     height: firstLayout.height + 20    // height to fit 3 numbers
        //     radius: 6
        //     color: "transparent"
        //     border.color: "#888"
        //     Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        //     visible:    QGroundControl.settingsManager.autoConnectSettings.visible

        //     ColumnLayout {
        //         id: firstLayout
        //         anchors.centerIn: parent
        //         spacing: ScreenTools.defaultFontPixelWidth * 2

        //         Repeater {
        //             model: [
        //                 { text: "Pixhawk                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectPixhawk },
        //                 { text: "SiK Radio                      ", fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectSiKRadio },
        //                 { text: "PX4Flow                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectPX4Flow },
        //                 { text: "LibrePilot                     ", fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectLibrePilot },
        //                 { text: "UDP                            ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectUDP },
        //                 { text: "RTK GPS                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS },
        //                 { text: "Zero-Conf                      ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectZeroConf }
        //             ]

        //             RowLayout {
        //                 Layout.fillWidth: true
        //                 Layout.alignment: Qt.AlignVCenter
        //                 spacing: 50

        //                 QGCLabel {
        //                     text: modelData.text
        //                     font.pointSize: 10
        //                     Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
        //                     horizontalAlignment: Text.AlignLeft
        //                 }

        //                 Item { Layout.fillWidth: true }

        //                 FactToggleSwitch {
        //                     Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        //                     fact: modelData.fact
        //                 }
        //             }
        //         }
        //     }
        // }

        // QGCLabel {
        //     text: "NMEA GPS"
        //     font.bold: true
        //     font.pointSize: 11
        //     Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
        // }

//         Rectangle {
//             //id: smallBox
//             width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
//             height: nmeaGPS.height + 20    // height to fit 3 numbers
//             radius: 6
//             color: "transparent"
//             border.color: "#888"
//             Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

//             ColumnLayout {
//                 id: nmeaGPS
//                 anchors.centerIn: parent
//                 //anchors.margins: 8
//                 spacing: ScreenTools.defaultFontPixelWidth * 2

            //     RowLayout {
            //         Layout.fillWidth: true
            //         Layout.alignment: Qt.AlignVCenter
            //         spacing: 20

            //         QGCLabel {
            //             text: "Device"
            //             font.pointSize: 10
            //             Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            //             horizontalAlignment: Text.AlignLeft
            //         }

            //         Item { Layout.fillWidth: true }

            //         QGCComboBox {
            //             id:                     nmeaPortCombo
            //             Layout.preferredWidth:  _comboFieldWidth

            //             model:  ListModel {
            //             }

            //             onActivated: {
            //                 if (index != -1) {
            //                     QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = textAt(index);
            //                 }
            //             }
            //             Component.onCompleted: {
            //                 model.append({text: gpsDisabled})
            //                 model.append({text: gpsUdpPort})

            //                 for (var i in QGroundControl.linkManager.serialPorts) {
            //                     nmeaPortCombo.model.append({text:QGroundControl.linkManager.serialPorts[i]})
            //                 }
            //                 var index = nmeaPortCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString);
            //                 nmeaPortCombo.currentIndex = index;
            //                 if (QGroundControl.linkManager.serialPorts.length === 0) {
            //                     nmeaPortCombo.model.append({text: "Serial <none available>"})
            //                 }
            //             }
            //         }
            //     }

            //     Rectangle {
            //         height: 1
            //         Layout.fillWidth: true
            //         color: "gray"
            //         visible: nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
            //     }

            //     RowLayout {
            //         Layout.fillWidth: true
            //         Layout.alignment: Qt.AlignVCenter
            //         spacing: 20
            //         visible:          nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled

            //         QGCLabel {
            //             text:             qsTr("NMEA GPS Baudrate")
            //             font.pointSize: 10
            //             Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            //             horizontalAlignment: Text.AlignLeft
            //         }

            //         Item { Layout.fillWidth: true }

            //         QGCComboBox {
            //             visible:                nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
            //             id:                     nmeaBaudCombo
            //             Layout.preferredWidth:  _comboFieldWidth
            //             model:                  [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]

            //             onActivated: {
            //                 if (index != -1) {
            //                     QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = textAt(index);
            //                 }
            //             }
            //             Component.onCompleted: {
            //                 var index = nmeaBaudCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString);
            //                 nmeaBaudCombo.currentIndex = index;
            //             }
            //         }
            //     }

            //     Rectangle {
            //         height: 1
            //         Layout.fillWidth: true
            //         color: "gray"
            //         visible:    nmeaPortCombo.currentText === gpsUdpPort
            //     }

            //     RowLayout {
            //         Layout.fillWidth: true
            //         Layout.alignment: Qt.AlignVCenter
            //         spacing: 20
            //         visible:    nmeaPortCombo.currentText === gpsUdpPort

            //         QGCLabel {
            //             text:       qsTr("NMEA stream UDP port")
            //             font.pointSize: 10
            //             Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            //             horizontalAlignment: Text.AlignLeft
            //         }

            //         Item { Layout.fillWidth: true }

            //         FactTextField {
            //             visible:                nmeaPortCombo.currentText === gpsUdpPort
            //             Layout.preferredWidth:  _valueFieldWidth
            //             fact:                   QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
            //         }
            //     }
            // }
//         }

//         QGCLabel {
//             text: "Links"
//             font.bold: true
//             font.pointSize: 11
//             Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
//         }

//     }
// }




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
    id:                 _linkRoot
    color:              qgcPal.window
    anchors.fill:       parent
    anchors.margins:    ScreenTools.defaultFontPixelWidth
    //color: "red"

    property var _currentSelection:     null
    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2

    property real   _comboFieldWidth:           ScreenTools.defaultFontPixelWidth * 30
    property real   _valueFieldWidth:           ScreenTools.defaultFontPixelWidth * 10
    property string gpsDisabled: "Disabled"
    property string gpsUdpPort:  "UDP Port"

    QGCPalette {
        id:                 qgcPal
        colorGroupEnabled:  enabled
    }

    function openCommSettings(originalLinkConfig) {
        settingsLoader.originalLinkConfig = originalLinkConfig
        if (originalLinkConfig) {
            // Editing existing link config
            settingsLoader.editingConfig = QGroundControl.linkManager.startConfigurationEditing(originalLinkConfig)
        } else {
            // Create new link configuration
            settingsLoader.editingConfig = QGroundControl.linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
        }
        settingsLoader.sourceComponent = commSettings
    }

    Component.onDestruction: {
        if (settingsLoader.sourceComponent) {
            settingsLoader.sourceComponent = null
            QGroundControl.linkManager.cancelConfigurationEditing(settingsLoader.editingConfig)
        }
    }

    QGCFlickable {
        anchors.fill: parent
        anchors.bottom: parent.bottom
        anchors.bottomMargin: buttonRow.height + (ScreenTools.defaultFontPixelHeight)
        anchors.horizontalCenter: parent.horizontalCenter
        flickableDirection: Flickable.VerticalFlick
        contentHeight:      linksColumn.height
        contentWidth:       linksColumn.width
        clip: true

        Column {
            id: linksColumn
            width: _linkRoot.width
            height: commRect.height
            spacing:            ScreenTools.defaultFontPixelHeight * 0.5
            anchors.margins:    ScreenTools.defaultFontPixelWidth


            Rectangle {
                id: commRect
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 30 : ScreenTools.defaultFontPixelWidth * 50
                height: first_Layout.height + 20
                color: "transparent"

                ColumnLayout {
                    id: first_Layout
                    anchors.centerIn: parent
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    QGCLabel {
                        text: "AutoConnect"
                        font.bold: true
                        font.pointSize: 11
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    }

                    Rectangle {
                        id: smallBox
                        width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                        height: firstLayout.height + 20    // height to fit 3 numbers
                        radius: 6
                        color: "transparent"
                        border.color: "#888"
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        visible:    QGroundControl.settingsManager.autoConnectSettings.visible

                        ColumnLayout {
                            id: firstLayout
                            anchors.centerIn: parent
                            spacing: ScreenTools.defaultFontPixelWidth * 2

                            Repeater {
                                model: [
                                    { text: "Pixhawk                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectPixhawk },
                                    { text: "SiK Radio                      ", fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectSiKRadio },
                                    { text: "PX4Flow                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectPX4Flow },
                                    { text: "LibrePilot                     ", fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectLibrePilot },
                                    { text: "UDP                            ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectUDP },
                                    { text: "RTK GPS                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS },
                                    { text: "Zero-Conf                      ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectZeroConf }
                                ]

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 50

                                    QGCLabel {
                                        text: modelData.text
                                        font.pointSize: 10
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                        horizontalAlignment: Text.AlignLeft
                                    }

                                    Item { Layout.fillWidth: true }

                                    FactToggleSwitch {
                                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                        fact: modelData.fact
                                    }
                                }
                            }
                        }
                    }

                    QGCLabel {
                        text: "NMEA GPS"
                        font.bold: true
                        font.pointSize: 11
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    }

                    Rectangle {
                        id: nextBox
                        width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                        implicitHeight: nmeaLayout.implicitHeight + 20    // height to fit 3 numbers
                        radius: 6
                        color: "transparent"
                        border.color: "#888"
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                        visible:    QGroundControl.settingsManager.autoConnectSettings.visible

                        ColumnLayout {
                            id: nmeaLayout
                            anchors.centerIn: parent
                            spacing: ScreenTools.defaultFontPixelWidth * 2

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 20

                                QGCLabel {
                                    text: "Device"
                                    font.pointSize: 10
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    horizontalAlignment: Text.AlignLeft
                                }

                                Item { Layout.fillWidth: true }

                                QGCComboBox {
                                    id:                     nmeaPortCombo
                                    Layout.preferredWidth:  _comboFieldWidth

                                    model:  ListModel {
                                    }

                                    onActivated: {
                                        if (index != -1) {
                                            QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = textAt(index);
                                        }
                                    }
                                    Component.onCompleted: {
                                        model.append({text: gpsDisabled})
                                        model.append({text: gpsUdpPort})

                                        for (var i in QGroundControl.linkManager.serialPorts) {
                                            nmeaPortCombo.model.append({text:QGroundControl.linkManager.serialPorts[i]})
                                        }
                                        var index = nmeaPortCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString);
                                        nmeaPortCombo.currentIndex = index;
                                        if (QGroundControl.linkManager.serialPorts.length === 0) {
                                            nmeaPortCombo.model.append({text: "Serial <none available>"})
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                //Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                                //spacing: 20
                                visible:    nmeaPortCombo.currentText === gpsUdpPort

                                QGCLabel {
                                    text:       qsTr("NMEA stream UDP port")
                                    font.pointSize: 10
                                    Layout.alignment: Qt.AlignVCenter /*| Qt.AlignLeft*/
                                    //horizontalAlignment: Text.AlignLeft
                                }

                                //Item { Layout.fillWidth: true }

                                FactTextField {
                                    visible:                nmeaPortCombo.currentText === gpsUdpPort
                                    Layout.preferredWidth:  _valueFieldWidth
                                    fact:                   QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter |Qt.AlignHCenter
                                //spacing: 20
                                visible:          nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled

                                QGCLabel {
                                    text:             qsTr("NMEA GPS Baudrate")
                                    font.pointSize: 10
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                                    //horizontalAlignment: Text.AlignLeft
                                }

                                QGCComboBox {
                                    visible:                nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
                                    id:                     nmeaBaudCombo
                                    Layout.preferredWidth:  _comboFieldWidth
                                    model:                  [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]

                                    onActivated: {
                                        if (index != -1) {
                                            QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = textAt(index);
                                        }
                                    }
                                    Component.onCompleted: {
                                        var index = nmeaBaudCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString);
                                        nmeaBaudCombo.currentIndex = index;
                                    }
                                }
                            }
                        }
                    }

                    QGCLabel {
                        id: linksLabel
                        text: "Links"
                        font.bold: true
                        font.pointSize: 11
                        anchors.top: commRect.bottom
                        anchors.topMargin: ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: btnRepeater.count > 0
                    }

                    Rectangle {
                        width: ScreenTools.defaultFontPixelWidth * 75
                        height: noConnectionsLabel.height + (ScreenTools.defaultFontPixelWidth * 2)
                        anchors.top: linksLabel.bottom
                        visible: btnRepeater.count === 1
                        radius: 6
                        color: "transparent"
                        border.color: "#888"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: ScreenTools.defaultFontPixelWidth
                    // "No connections available" label (shown when there are none)
                        QGCLabel {
                            id: noConnectionsLabel
                            anchors.centerIn: parent
                            text: "No active connections. Click 'Add' to add connection..!"
                            font.pointSize: 10
                            font.italic: true
                            color: "gray"
                            anchors.topMargin: ScreenTools.defaultFontPixelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // The section that shows buttons
                    // QGCFlickable {
                    //     id: commButton
                    //     clip: true
                    //     anchors.top: linksLabel.bottom
                    //     anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
                    //     width: parent.width
                    //     height: parent.height - buttonRow.height
                    //     contentHeight: settingsColumn.height
                    //     contentWidth: _linkRoot.width
                    //     flickableDirection: Flickable.VerticalFlick
                    //     visible: btnRepeater.count > 1

                        Column {
                            id: settingsColumn
                            width: _linkRoot.width
                            anchors.margins: ScreenTools.defaultFontPixelWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: ScreenTools.defaultFontPixelHeight / 2

                            Repeater {
                                id: btnRepeater
                                model: QGroundControl.linkManager.linkConfigurations
                                delegate: QGCButton {
                                    id: linkButton
                                    anchors.horizontalCenter: settingsColumn.horizontalCenter
                                    width: _linkRoot.width * 0.2
                                    text: object.name
                                    autoExclusive: true
                                    visible: !object.dynamic
                                    onClicked: {
                                        checked = true
                                        _currentSelection = object
                                        console.log("clicked", object, object.link)
                                    }
                                }
                            }

                            Component.onCompleted: {
                                    console.log("Initial repeater count:", btnRepeater.count)
                                }
                        }
                    //}

                    Connections {
                        target: btnRepeater
                        onCountChanged: linksLabel.visible = btnRepeater.count > 0
                    }
                }
            }
        }
    }

    Row {
        id:                 buttonRow
        spacing:            ScreenTools.defaultFontPixelWidth
        anchors.bottom:     parent.bottom
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        anchors.horizontalCenter: parent.horizontalCenter
        QGCButton {
            width:      ScreenTools.defaultFontPixelWidth * 10
            text:       qsTr("Delete")
            enabled:    _currentSelection && !_currentSelection.dynamic
            onClicked:  deleteDialog.visible = true

            MessageDialog {
                id:         deleteDialog
                visible:    false
                icon:       StandardIcon.Warning
                standardButtons: StandardButton.Yes | StandardButton.No
                title:      qsTr("Remove Link Configuration")
                text:       _currentSelection ? qsTr("Remove %1. Is this really what you want?").arg(_currentSelection.name) : ""

                onYes: {
                    QGroundControl.linkManager.removeConfiguration(_currentSelection)
                    _currentSelection = null
                    deleteDialog.visible = false
                }
                onNo: deleteDialog.visible = false
            }
        }
        QGCButton {
            text:       qsTr("Edit")
            enabled:    _currentSelection && !_currentSelection.link
            onClicked:  _linkRoot.openCommSettings(_currentSelection)
        }
        QGCButton {
            text:       qsTr("Add")
            onClicked:  _linkRoot.openCommSettings(null)
        }
        QGCButton {
            text:       qsTr("Connect")
            enabled:    _currentSelection && !_currentSelection.link
            onClicked:  QGroundControl.linkManager.createConnectedLink(_currentSelection)
        }
        QGCButton {
            text:       qsTr("Disconnect")
            enabled:    _currentSelection && _currentSelection.link
            onClicked:  {
                _currentSelection.link.disconnect()
                _currentSelection.linkChanged()
            }
        }
        QGCButton {
            text:       qsTr("MockLink Options")
            visible:    _currentSelection && _currentSelection.link && _currentSelection.link.isMockLink
            onClicked:  mockLinkOptionDialog.open()

            MockLinkOptionsDlg {
                id:     mockLinkOptionDialog
                link:   _currentSelection ? _currentSelection.link : undefined
            }
        }
    }

    // Rectangle {
    //     id: commRect
    //     anchors.top: parent.top
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     width: ScreenTools.defaultFontPixelWidth * 75
    //     height: first_Layout.height + 20
    //     color: "green"

    //     ColumnLayout {
    //         id: first_Layout
    //         anchors.centerIn: parent
    //         spacing: ScreenTools.defaultFontPixelWidth * 2

    //         QGCLabel {
    //             text: "AutoConnect"
    //             font.bold: true
    //             font.pointSize: 11
    //             Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    //         }

            // Rectangle {
            //     id: smallBox
            //     width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
            //     height: firstLayout.height + 20    // height to fit 3 numbers
            //     radius: 6
            //     color: "transparent"
            //     border.color: "#888"
            //     Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            //     visible:    QGroundControl.settingsManager.autoConnectSettings.visible

            //     ColumnLayout {
            //         id: firstLayout
            //         anchors.centerIn: parent
            //         spacing: ScreenTools.defaultFontPixelWidth * 2

            //         Repeater {
            //             model: [
            //                 { text: "Pixhawk                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectPixhawk },
            //                 { text: "SiK Radio                      ", fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectSiKRadio },
            //                 { text: "PX4Flow                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectPX4Flow },
            //                 { text: "LibrePilot                     ", fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectLibrePilot },
            //                 { text: "UDP                            ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectUDP },
            //                 { text: "RTK GPS                        ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS },
            //                 { text: "Zero-Conf                      ",   fact: QGroundControl.settingsManager.autoConnectSettings.autoConnectZeroConf }
            //             ]

            //             RowLayout {
            //                 Layout.fillWidth: true
            //                 Layout.alignment: Qt.AlignVCenter
            //                 spacing: 50

            //                 QGCLabel {
            //                     text: modelData.text
            //                     font.pointSize: 10
            //                     Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            //                     horizontalAlignment: Text.AlignLeft
            //                 }

            //                 Item { Layout.fillWidth: true }

            //                 FactToggleSwitch {
            //                     Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            //                     fact: modelData.fact
            //                 }
            //             }
            //         }
            //     }
            // }

            // QGCLabel {
            //     text: "NMEA GPS"
            //     font.bold: true
            //     font.pointSize: 11
            //     Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            // }

            // Rectangle {
            //     id: nextBox
            //     width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
            //     implicitHeight: nmeaLayout.implicitHeight + 20    // height to fit 3 numbers
            //     radius: 6
            //     color: "transparent"
            //     border.color: "#888"
            //     Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            //     visible:    QGroundControl.settingsManager.autoConnectSettings.visible

            //     ColumnLayout {
            //         id: nmeaLayout
            //         anchors.centerIn: parent
            //         spacing: ScreenTools.defaultFontPixelWidth * 2

            //         RowLayout {
            //             Layout.fillWidth: true
            //             Layout.alignment: Qt.AlignVCenter
            //             spacing: 20

            //             QGCLabel {
            //                 text: "Device"
            //                 font.pointSize: 10
            //                 Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            //                 horizontalAlignment: Text.AlignLeft
            //             }

            //             Item { Layout.fillWidth: true }

            //             QGCComboBox {
            //                 id:                     nmeaPortCombo
            //                 Layout.preferredWidth:  _comboFieldWidth

            //                 model:  ListModel {
            //                 }

            //                 onActivated: {
            //                     if (index != -1) {
            //                         QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.value = textAt(index);
            //                     }
            //                 }
            //                 Component.onCompleted: {
            //                     model.append({text: gpsDisabled})
            //                     model.append({text: gpsUdpPort})

            //                     for (var i in QGroundControl.linkManager.serialPorts) {
            //                         nmeaPortCombo.model.append({text:QGroundControl.linkManager.serialPorts[i]})
            //                     }
            //                     var index = nmeaPortCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaPort.valueString);
            //                     nmeaPortCombo.currentIndex = index;
            //                     if (QGroundControl.linkManager.serialPorts.length === 0) {
            //                         nmeaPortCombo.model.append({text: "Serial <none available>"})
            //                     }
            //                 }
            //             }
            //         }

                    // Rectangle {
                    //     height: 1
                    //     Layout.fillWidth: true
                    //     color: "gray"
                    //     visible: nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
                    // }

                    // RowLayout {
                    //     Layout.fillWidth: true
                    //     Layout.alignment: Qt.AlignVCenter
                    //     spacing: 20
                    //     visible:          nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled

                    //     QGCLabel {
                    //         text:             qsTr("NMEA GPS Baudrate")
                    //         font.pointSize: 10
                    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    //         horizontalAlignment: Text.AlignLeft
                    //     }

                    //     Item { Layout.fillWidth: true }

                    //     QGCComboBox {
                    //         visible:                nmeaPortCombo.currentText !== gpsUdpPort && nmeaPortCombo.currentText !== gpsDisabled
                    //         id:                     nmeaBaudCombo
                    //         Layout.preferredWidth:  _comboFieldWidth
                    //         model:                  [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600]

                    //         onActivated: {
                    //             if (index != -1) {
                    //                 QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.value = textAt(index);
                    //             }
                    //         }
                    //         Component.onCompleted: {
                    //             var index = nmeaBaudCombo.find(QGroundControl.settingsManager.autoConnectSettings.autoConnectNmeaBaud.valueString);
                    //             nmeaBaudCombo.currentIndex = index;
                    //         }
                    //     }
                    // }

                    // Rectangle {
                    //     height: 1
                    //     Layout.fillWidth: true
                    //     color: "gray"
                    //     visible:    nmeaPortCombo.currentText === gpsUdpPort
                    // }

                    // RowLayout {
                    //     Layout.fillWidth: true
                    //     Layout.alignment: Qt.AlignVCenter
                    //     spacing: 20
                    //     visible:    nmeaPortCombo.currentText === gpsUdpPort

                    //     QGCLabel {
                    //         text:       qsTr("NMEA stream UDP port")
                    //         font.pointSize: 10
                    //         Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    //         horizontalAlignment: Text.AlignLeft
                    //     }

                    //     Item { Layout.fillWidth: true }

                    //     FactTextField {
                    //         visible:                nmeaPortCombo.currentText === gpsUdpPort
                    //         Layout.preferredWidth:  _valueFieldWidth
                    //         fact:                   QGroundControl.settingsManager.autoConnectSettings.nmeaUdpPort
                    //     }
                    // }
    //             }
    //         }
    //     }
    // }

    // // "Links" label (shown only when there are link buttons)
    // QGCLabel {
    //     id: linksLabel
    //     text: "Links"
    //     font.bold: true
    //     font.pointSize: 11
    //     anchors.top: commRect.bottom
    //     anchors.topMargin: ScreenTools.defaultFontPixelWidth
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     visible: btnRepeater.count > 0
    // }

    // Rectangle {
    //     width: ScreenTools.defaultFontPixelWidth * 75
    //     height: noConnectionsLabel.height + (ScreenTools.defaultFontPixelWidth * 2)
    //     anchors.top: linksLabel.bottom
    //     visible: btnRepeater.count === 1
    //     radius: 6
    //     color: "transparent"
    //     border.color: "#888"
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.topMargin: ScreenTools.defaultFontPixelWidth
    // // "No connections available" label (shown when there are none)
    //     QGCLabel {
    //         id: noConnectionsLabel
    //         anchors.centerIn: parent
    //         text: "No active connections. Click Add to add connection..!"
    //         font.pointSize: 10
    //         font.italic: true
    //         color: "gray"
    //         anchors.topMargin: ScreenTools.defaultFontPixelWidth
    //         anchors.horizontalCenter: parent.horizontalCenter
    //     }
    // }

    // // The section that shows buttons
    // QGCFlickable {
    //     id: commButton
    //     clip: true
    //     anchors.top: linksLabel.bottom
    //     anchors.topMargin: ScreenTools.defaultFontPixelWidth * 2
    //     width: parent.width
    //     height: parent.height - buttonRow.height
    //     contentHeight: settingsColumn.height
    //     contentWidth: _linkRoot.width
    //     flickableDirection: Flickable.VerticalFlick
    //     visible: btnRepeater.count > 1

    //     Column {
    //         id: settingsColumn
    //         width: _linkRoot.width
    //         anchors.margins: ScreenTools.defaultFontPixelWidth
    //         spacing: ScreenTools.defaultFontPixelHeight / 2

    //         Repeater {
    //             id: btnRepeater
    //             model: QGroundControl.linkManager.linkConfigurations
    //             delegate: QGCButton {
    //                 id: linkButton
    //                 anchors.horizontalCenter: settingsColumn.horizontalCenter
    //                 width: _linkRoot.width * 0.2
    //                 text: object.name
    //                 autoExclusive: true
    //                 visible: !object.dynamic
    //                 onClicked: {
    //                     checked = true
    //                     _currentSelection = object
    //                     console.log("clicked", object, object.link)
    //                 }
    //             }
    //         }

    //         Component.onCompleted: {
    //                 console.log("Initial repeater count:", btnRepeater.count)
    //             }
    //     }
    // }

    // Connections {
    //     target: btnRepeater
    //     onCountChanged: linksLabel.visible = btnRepeater.count > 0
    // }

    // Row {
    //     id:                 buttonRow
    //     spacing:            ScreenTools.defaultFontPixelWidth
    //     anchors.bottom:     parent.bottom
    //     anchors.margins:    ScreenTools.defaultFontPixelWidth
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     QGCButton {
    //         width:      ScreenTools.defaultFontPixelWidth * 10
    //         text:       qsTr("Delete")
    //         enabled:    _currentSelection && !_currentSelection.dynamic
    //         onClicked:  deleteDialog.visible = true

    //         MessageDialog {
    //             id:         deleteDialog
    //             visible:    false
    //             icon:       StandardIcon.Warning
    //             standardButtons: StandardButton.Yes | StandardButton.No
    //             title:      qsTr("Remove Link Configuration")
    //             text:       _currentSelection ? qsTr("Remove %1. Is this really what you want?").arg(_currentSelection.name) : ""

    //             onYes: {
    //                 QGroundControl.linkManager.removeConfiguration(_currentSelection)
    //                 _currentSelection = null
    //                 deleteDialog.visible = false
    //             }
    //             onNo: deleteDialog.visible = false
    //         }
    //     }
    //     QGCButton {
    //         text:       qsTr("Edit")
    //         enabled:    _currentSelection && !_currentSelection.link
    //         onClicked:  _linkRoot.openCommSettings(_currentSelection)
    //     }
    //     QGCButton {
    //         text:       qsTr("Add")
    //         onClicked:  _linkRoot.openCommSettings(null)
    //     }
    //     QGCButton {
    //         text:       qsTr("Connect")
    //         enabled:    _currentSelection && !_currentSelection.link
    //         onClicked:  QGroundControl.linkManager.createConnectedLink(_currentSelection)
    //     }
    //     QGCButton {
    //         text:       qsTr("Disconnect")
    //         enabled:    _currentSelection && _currentSelection.link
    //         onClicked:  {
    //             _currentSelection.link.disconnect()
    //             _currentSelection.linkChanged()
    //         }
    //     }
    //     QGCButton {
    //         text:       qsTr("MockLink Options")
    //         visible:    _currentSelection && _currentSelection.link && _currentSelection.link.isMockLink
    //         onClicked:  mockLinkOptionDialog.open()

    //         MockLinkOptionsDlg {
    //             id:     mockLinkOptionDialog
    //             link:   _currentSelection ? _currentSelection.link : undefined
    //         }
    //     }
    // }

    Loader {
        id:             settingsLoader
        anchors.fill:   parent
        visible:        sourceComponent ? true : false

        property var originalLinkConfig:    null
        property var editingConfig:      null
    }

    //---------------------------------------------
    // Comm Settings
    Component {
        id: commSettings
        Rectangle {
            id:             settingsRect
            color:          qgcPal.window
            anchors.fill:   parent
            property real   _panelWidth:    width * 0.8

            QGCFlickable {
                id:                 settingsFlick
                clip:               true
                anchors.fill:       parent
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                contentHeight:      mainLayout.height
                contentWidth:       mainLayout.width

                ColumnLayout {
                    id:         mainLayout
                    spacing:    _rowSpacing

                    QGCGroupBox {
                        title: originalLinkConfig ? qsTr("Edit Link Configuration Settings") : qsTr("Create New Link Configuration")

                        ColumnLayout {
                            spacing: _rowSpacing

                            GridLayout {
                                columns:        2
                                columnSpacing:  _colSpacing
                                rowSpacing:     _rowSpacing

                                QGCLabel { text: qsTr("Name") }
                                QGCTextField {
                                    id:                     nameField
                                    Layout.preferredWidth:  _secondColumnWidth
                                    Layout.fillWidth:       true
                                    text:                   editingConfig.name
                                    placeholderText:        qsTr("Enter name")
                                }

                                QGCLabel { text:               qsTr("Automatically Connect on Start") }

                                QGCToggleSwitch {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    checked: editingConfig.autoConnect
                                    onCheckedChanged: editingConfig.autoConnect = checked
                                }

                                // QGCCheckBox {
                                //     Layout.columnSpan:  2
                                //     text:               qsTr("Automatically Connect on Start")
                                //     checked:            editingConfig.autoConnect
                                //     onCheckedChanged:   editingConfig.autoConnect = checked
                                // }

                                QGCLabel { text:               qsTr("High Latency") }
                                QGCToggleSwitch {
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                    checked: editingConfig.highLatency
                                    onCheckedChanged: editingConfig.highLatency = checked
                                }

                                // QGCCheckBox {
                                //     Layout.columnSpan:  2
                                //     text:               qsTr("High Latency")
                                //     checked:            editingConfig.highLatency
                                //     onCheckedChanged:   editingConfig.highLatency = checked
                                // }

                                QGCLabel { text: qsTr("Type") }
                                QGCComboBox {
                                    Layout.preferredWidth:  _secondColumnWidth
                                    Layout.fillWidth:       true
                                    enabled:                originalLinkConfig == null
                                    model:                  QGroundControl.linkManager.linkTypeStrings
                                    currentIndex:           editingConfig.linkType

                                    onActivated: {
                                        if (index !== editingConfig.linkType) {
                                            // Save current name
                                            var name = nameField.text
                                            // Create new link configuration
                                            editingConfig = QGroundControl.linkManager.createConfiguration(index, name)
                                        }
                                    }
                                }
                            }

                            Loader {
                                id:     linksettingsLoader
                                source: subEditConfig.settingsURL

                                property var subEditConfig: editingConfig
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment:   Qt.AlignHCenter
                        spacing:            _colSpacing

                        QGCButton {
                            width:      ScreenTools.defaultFontPixelWidth * 10
                            text:       qsTr("OK")
                            enabled:    nameField.text !== ""

                            onClicked: {
                                // Save editing
                                linksettingsLoader.item.saveSettings()
                                editingConfig.name = nameField.text
                                settingsLoader.sourceComponent = null
                                if (originalLinkConfig) {
                                    QGroundControl.linkManager.endConfigurationEditing(originalLinkConfig, editingConfig)
                                } else {
                                    // If it was edited, it's no longer "dynamic"
                                    editingConfig.dynamic = false
                                    QGroundControl.linkManager.endCreateConfiguration(editingConfig)
                                }
                            }
                        }

                        QGCButton {
                            width:      ScreenTools.defaultFontPixelWidth * 10
                            text:       qsTr("Cancel")
                            onClicked: {
                                settingsLoader.sourceComponent = null
                                QGroundControl.linkManager.cancelConfigurationEditing(settingsLoader.editingConfig)
                            }
                        }
                    }
                }
            }
        }
    }
}
