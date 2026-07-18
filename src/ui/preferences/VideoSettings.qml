/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                  2.11
import QtQuick.Controls         2.4
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.2
import QtQuick.Controls.impl    2.4
import QtQuick.Templates        2.4 as T

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0
import QGroundControl.Controllers           1.0
import QGroundControl.SettingsManager       1.0

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    anchors.centerIn: parent
    radius: 12
    color: "transparent"

    property real   _valueFieldWidth:           ScreenTools.defaultFontPixelWidth * 15
    property var    _planViewSettings:          QGroundControl.settingsManager.planViewSettings
    property real   _comboFieldWidth:           ScreenTools.defaultFontPixelWidth * 25
    property var    _videoSettings:             QGroundControl.settingsManager.videoSettings
    property bool   _videoAutoStreamConfig:     QGroundControl.videoManager.autoStreamConfigured
    property bool   _showSaveVideoSettings:     _isGst || _videoAutoStreamConfig
    property bool   _isGst:                     QGroundControl.videoManager.isGStreamer
    property string _videoSource:               _videoSettings.rtspVideoSource
    property bool   _isUDP264:                  _isGst && _videoSource === _videoSettings.udp264VideoSource
    property bool   _isUDP265:                  _isGst && _videoSource === _videoSettings.udp265VideoSource
    property bool   _isRTSP:                    _isGst && _videoSource === _videoSettings.rtspVideoSource
    property bool   _isTCP:                     _isGst && _videoSource === _videoSettings.tcpVideoSource
    property bool   _isMPEGTS:                  _isGst && _videoSource === _videoSettings.mpegtsVideoSource

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: contentColumn.height
        contentWidth: parent.width
        clip: true
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: contentColumn
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: ScreenTools.defaultFontPixelWidth * 75

            QGCLabel {
                id: mainLabel
                text: "Video Source"
                font.bold: true
                font.pointSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                id: smallBox
                width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                //height: firstLayout.height + 20    // height to fit 3 numbers
                //implicitHeight: firstLayout.implicitHeight + 30
                radius: 6
                color: "transparent"
                border.color: "#888"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                ColumnLayout {
                    id: firstLayout
                    anchors.centerIn: parent
                    //anchors.margins: 8
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    onHeightChanged: smallBox.implicitHeight = height + 30

                    RowLayout {
                        id: sourceLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        //visible:    !_videoAutoStreamConfig && _videoSettings.videoSource.visible

                        QGCLabel {
                            id: vidSourceLabel
                            text: "Video Source"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        // FactComboBox {
                        //     id:                     videoSource
                        //     //Layout.preferredWidth:  _comboFieldWidth
                        //     indexModel:             false
                        //     fact:                   _videoSettings.videoSource
                        //     visible:                false
                        //     Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        //     Layout.preferredWidth: vidSourceTM.width + 40

                        //     TextMetrics {
                        //         id: vidSourceTM
                        //         text: videoSource.displayText   // displayText is the visible text in combo
                        //         font: videoSource.font
                        //     }

                        //     Component.onCompleted: {
                        //         console.log("Video source", videoSource.displayText)
                        //     }
                        // }

                        QGCLabel {
                            id: vidSourceLabel1
                            text: "RTSP Video Stream"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                        visible: udpPortLabel.visible
                    }

                    RowLayout {
                        //id: sourceLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: !_videoAutoStreamConfig && (_isUDP264 || _isUDP265 || _isMPEGTS) && _videoSettings.udpPort.visible // this is for label, so for avoid confusion i put here

                        QGCLabel {
                            id: udpPortLabel
                            text: "UDP Port"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            //id:                     videoSource
                            Layout.preferredWidth:  _comboFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            //indexModel:             false
                            fact:                    _videoSettings.udpPort
                            visible:                udpPortLabel.visible
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                        visible: rtspUrlLabel.visible
                    }

                    RowLayout {
                        //id: sourceLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: !_videoAutoStreamConfig && _isRTSP && _videoSettings.rtspUrl.visible // this is for label, so for avoid confusion i put here

                        QGCLabel {
                            id: rtspUrlLabel
                            text: "RTSP URL"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            //id:                     videoSource
                            Layout.preferredWidth:  _comboFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            //indexModel:             false
                            fact:                    _videoSettings.rtspUrl
                            visible:                rtspUrlLabel.visible
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                        visible: tcpUrlLabel.visible
                    }

                    RowLayout {
                        //id: sourceLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible: !_videoAutoStreamConfig && _isTCP && _videoSettings.tcpUrl.visible // this is for label, so for avoid confusion i put here

                        QGCLabel {
                            id: tcpUrlLabel
                            text: "TCP URL"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            //id:                     videoSource
                            Layout.preferredWidth:  _comboFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            //indexModel:             false
                            fact:                    _videoSettings.tcpUrl
                            visible:                tcpUrlLabel.visible
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                        visible: asRatioLabel.visible
                    }

                    RowLayout {
                        //id: sourceLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible:  !_videoAutoStreamConfig && _isGst && _videoSettings.aspectRatio.visible // this is for label, so for avoid confusion i put here

                        QGCLabel {
                            id: asRatioLabel
                            text: "Aspect Ratio"
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            //id:                     videoSource
                            Layout.preferredWidth:  _comboFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            //indexModel:             false
                            fact:                   _videoSettings.aspectRatio
                        }
                    }
                }
            }

            QGCLabel {
                text: "Local Video Storage"
                font.bold: true
                font.pointSize: 11
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                //id: smallBox
                width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
                //height: storageLayout.height + 20    // height to fit 3 numbers
                implicitHeight: storageLayout.implicitHeight + 30
                radius: 6
                color: "transparent"
                border.color: "#888"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                ColumnLayout {
                    id: storageLayout
                    anchors.centerIn: parent
                    //anchors.margins: 8
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        id: saveLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible:    _showSaveVideoSettings && _videoSettings.recordingFormat.visible

                        QGCLabel {
                            text:       qsTr("Record File Format")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            //visible: QGroundControl.settingsManager.appSettings.qLocaleLanguage.visible
                        }

                        Item { Layout.fillWidth: true }

                        FactComboBox {
                            id: fileFor
                            //Layout.preferredWidth:  _comboFieldWidth
                            fact:                   _videoSettings.recordingFormat
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            visible:                saveLayout.visible
                            Layout.preferredWidth: fileForMetrics.width + 40

                            TextMetrics {
                                id: fileForMetrics
                                text: fileFor.displayText   // displayText is the visible text in combo
                                font: fileFor.font
                            }
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                        visible: saveLayout.visible
                    }

                    RowLayout {
                        //id: saveLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        //visible:    !_videoAutoStreamConfig && _isGst && fact.visible

                        QGCLabel {
                            text:       qsTr("Auto-Delete Saved Recordings")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactToggleSwitch {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact:       _videoSettings.enableStorageLimit
                        }
                    }

                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        color: "gray"
                        visible: stoUsageLayout.visible
                    }

                    RowLayout {
                        id: stoUsageLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 20
                        visible:    _showSaveVideoSettings && _videoSettings.maxVideoSize.visible && _videoSettings.enableStorageLimit.value

                        QGCLabel {
                            id: maxSavedVideoStorageLabel
                            text:       qsTr("Max Storage Usage")
                            font.pointSize: 10
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                        }

                        Item { Layout.fillWidth: true }

                        FactTextField {
                            Layout.preferredWidth:  _comboFieldWidth
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            fact:                   _videoSettings.maxVideoSize
                            visible:                _showSaveVideoSettings && _videoSettings.enableStorageLimit.value && maxSavedVideoStorageLabel.visible
                        }
                    }
                }
            }
        }
    }
}
