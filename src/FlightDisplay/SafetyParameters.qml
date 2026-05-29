import QtQuick                  2.12
import QtQuick.Controls         2.15
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12
import Qt.labs.platform 1.1


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
import QGroundControl.FactControls  1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0


Item {
    id: root

    // Make size flexible for parent
    width: parent ? parent.width : 200
    height: parent ? parent.height : 200

    FactPanelController { id: controller; }

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    //property var _fenceController: _activeVehicle ? _activeVehicle.fenceController : null

    property int    _editingLayer:                      layerTabBar.currentIndex ? _layers[layerTabBar.currentIndex] : _layerMessage

    readonly property var       _layers:                [_layerMessage, _layerCustom]

    readonly property int       _layerMessage:              1
    readonly property int       _layerCustom:               2

    signal takeScreenshot
    signal requestShowBigMessages
    property bool showBigMessages: false
    property alias messageModel: messageListModel

    function populate_FromFormattedMessages() {
        messagesSection.populateFromFormattedMessages()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            //anchors.centerIn: parent
            //border.color: "white"

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - ScreenTools.defaultFontPixelWidth
                height: parent.height /*- ScreenTools.defaultFontPixelHeight * 0.1*/
                color: "transparent"
                border.color: "#888"
                radius: ScreenTools.defaultFontPixelWidth / 2

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#2A2A2A"
                        border.color: "#666"

                        ColumnLayout {
                            anchors.fill: parent

                            QGCLabel {
                                text: qsTr("Battery Profile")
                                font.bold: true
                                font.pixelSize: ScreenTools.defaultFontPixelHeight
                                Layout.alignment: Qt.AlignHCenter
                                color: "white"
                            }

                            GridLayout {
                                columns: 2
                                rowSpacing: 0
                                columnSpacing: 0
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignHCenter

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: qsTr("Voltage (V)")
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: (_activeVehicle && _activeVehicle.batteries && _activeVehicle.batteries.count > 0
                                        && _activeVehicle.batteries.get(0))
                                        ? _activeVehicle.batteries.get(0).voltage.valueString
                                        : "N/A"
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: qsTr("Current (A)")
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: (_activeVehicle && _activeVehicle.batteries && _activeVehicle.batteries.count > 0
                                        && _activeVehicle.batteries.get(0))
                                        ? _activeVehicle.batteries.get(0).current.valueString
                                        : "N/A"
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#2A2A2A"
                        border.color: "#666"

                        ColumnLayout {
                            anchors.fill: parent

                            QGCLabel {
                                text: qsTr("GPS Profile")
                                font.bold: true
                                font.pixelSize: ScreenTools.defaultFontPixelHeight
                                Layout.alignment: Qt.AlignHCenter
                                color: "white"
                            }

                            GridLayout {
                                columns: 2
                                rowSpacing: 0
                                columnSpacing: 0
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignHCenter

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: qsTr("HDOP")
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: (_activeVehicle && _activeVehicle.gps && _activeVehicle.gps.hdop)
                                                  ? _activeVehicle.gps.hdop.valueString
                                                  : "N/A"
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: qsTr("VDOP")
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }

                                Rectangle {
                                    color: "#2A2A2A"
                                    border.color: "#666"
                                    border.width: 1
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: (_activeVehicle && _activeVehicle.gps && _activeVehicle.gps.vdop)
                                                  ? _activeVehicle.gps.vdop.valueString
                                                  : "N/A"
                                        font.bold: true
                                        font.pixelSize: ScreenTools.defaultFontPixelHeight
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: "white"

            QGCTabBar {
                id:         layerTabBar
                width:      parent.width
                Component.onCompleted: currentIndex = 0
                anchors.top: parent.top
                anchors.topMargin: ScreenTools.defaultFontPixelWidth / 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
                anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                QGCTabButton {
                    text:       qsTr("Message")
                    font.pointSize: ScreenTools.isMobile ? 8 : 12
                }
                QGCTabButton {
                    text:       qsTr("Custom")
                    font.pointSize: ScreenTools.isMobile ? 8 : 12
                    //enabled:    _geoFenceController.supported
                }
            }

            Rectangle {
                id: messagesSection
                width: parent.width * 0.97
                height: ScreenTools.isMobile ? parent.height * 0.98 : parent.height * 0.80
                anchors.top: layerTabBar.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.centerIn: parent
                color: /*Qt.rgba(0.9, 0.9, 0.9, 0.6)*/ "#bb000000"
                border.color: "#888"
                border.width: 1
                radius: ScreenTools.defaultFontPixelWidth / 2
                visible: _editingLayer == _layerMessage

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               qsTr("No Messages...!")
                    visible:            !_activeVehicle
                    font.bold: true
                    font.pointSize: ScreenTools.isMobile ? 6 : 12
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        //console.log("SafetyParameters: requestShowBigMessages")
                        requestShowBigMessages()
                    }
                }

                /*x: telemetryPanel.x - 350
                y: telemetryPanel.y - 165  */ // places below timeDate

                property bool expanded: false
                property int collapsedHeight: 40
                property int expandedHeight: 200

                onVisibleChanged: {
                    if (visible) {
                       x = 10
                       y = parent.height - height - 10
                    }
                }

                onHeightChanged: {
                   y = parent.height - height - 10
                }

                //height: /*expanded ? */expandedHeight /*: collapsedHeight*/

                Behavior on height {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }

                // Rectangle {
                //     id: msgHeader
                //     width: parent.width
                //     height: ScreenTools.defaultFontPixelWidth * 7
                //     color: "transparent"
                //     // border.color: "white"
                //     // border.width: 1

                //     RowLayout {
                //         anchors.fill: parent
                //         anchors.margins: 10
                //         spacing: 50

                //         Text {
                //             text: "Messages"
                //             font.bold: true
                //             font.pointSize: 13
                //             color: "white"
                //             Layout.alignment: Qt.AlignVCenter | Qt.AlignCenter
                //         }
                //     }
                // }

                ListModel { id: messageListModel }

                ListView {
                    id: listView
                    anchors.top: parent.top
                    anchors.topMargin: ScreenTools.isMobile ? 0 : ScreenTools.defaultFontPixelWidth * 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    model: messageListModel

                    delegate: Rectangle {
                        width: listView.width
                        color: "transparent"
                        implicitHeight: label.implicitHeight + 10

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                //console.log("SafetyParameters: requestShowBigMessages")
                                requestShowBigMessages()
                            }
                        }

                        QGCLabel {
                            id: label
                            text: model.text
                            textFormat: Text.RichText
                            renderType: Text.NativeRendering
                            wrapMode: Text.Wrap
                            width: parent.width - 10
                            anchors.left: parent.left
                            anchors.margins: 5
                            color: "white"
                            font.pointSize: ScreenTools.isMobile ? 10 : 12
                            //height: contentHeigh
                        }
                        //height: childrenRect.height + 10
                    }
                }

                // Fill history when opened
                function populateFromFormattedMessages() {
                    messageListModel.clear()
                    if (!_activeVehicle || !_activeVehicle.formattedMessages) return
                    var lines = _activeVehicle.formattedMessages.split("\n")
                    for (var i = 0; i < lines.length; ++i) {
                        var line = lines[i].trim()
                        if (line.length > 0) {
                            messageListModel.append({ text: line })
                        }
                    }
                    Qt.callLater(function(){ listView.positionViewAtEnd() })
                }

                // Handle new incoming messages
                Connections {
                    target: QGroundControl.multiVehicleManager
                    onActiveVehicleChanged: {
                        if (QGroundControl.multiVehicleManager.activeVehicle) {
                            _activeVehicle = QGroundControl.multiVehicleManager.activeVehicle
                            if (messagesSection.expanded) populateFromFormattedMessages()
                        }
                    }
                }

                Connections {
                    target: _activeVehicle
                    onNewFormattedMessage: function(msg) {
                        // add empty entry for the new message
                        var newIndex = messageListModel.count
                        messageListModel.append({ text: "" })

                        // typewriter effect
                        var buffer = ""
                        var i = 0
                        var timer = Qt.createQmlObject('import QtQuick 2.0; Timer { interval: 30; repeat: true }',
                                                       listView, "typewriterTimer")
                        timer.triggered.connect(function() {
                            if (i < msg.length) {
                                // append next character
                                // var current = messageListModel.get(newIndex).text
                                buffer += msg[i]
                                messageListModel.setProperty(newIndex, "text", buffer)
                                i++
                                listView.positionViewAtEnd()
                            } else {
                                timer.stop()
                                timer.destroy()
                            }
                        })
                        timer.start()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        //console.log("SafetyParameters: requestShowBigMessages")
                        root.requestShowBigMessages()
                    }
                }
            }

            Rectangle {
                id: customSection
                width: parent.width * 0.97
                height: parent.height * 0.80
                anchors.top: layerTabBar.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.centerIn: parent
                color: /*Qt.rgba(0.9, 0.9, 0.9, 0.6)*/ "#bb000000"
                border.color: "#888"
                border.width: 1
                radius: ScreenTools.defaultFontPixelWidth / 2
                visible: _editingLayer == _layerCustom

                MouseArea {
                    anchors.fill: parent
                }

                // QGCButton {
                //     text: "ScreenShot"
                //     anchors.centerIn: parent
                //     onClicked: {
                //         takeScreenshot()
                //     }
                // }

                RowLayout {
                    anchors.fill: parent
                // QGCButton {
                //     text: "RC5"
                //     onClicked: {
                //         console.log("Cmd 5 btn clicked")
                //         if(_activeVehicle) {
                //             //_activeVehicle.testOverride()
                //             //_activeVehicle._sendOverrideValue(5, 1460)
                //             rcDialog.channelNo = 5
                //             rcDialog.open()
                //         }
                //     }
                // }

                // QGCButton {
                //     text: "RC6"
                //     onClicked: {
                //         console.log("Cmd 5 btn clicked")
                //         if(_activeVehicle) {
                //             //_activeVehicle.testOverride()
                //             //_activeVehicle._sendOverrideValue(5, 1460)
                //             rcDialog.channelNo = 6
                //             rcDialog.open()
                //         }
                //     }
                // }
                }
            }
        }
    }

    // Dialog {
    //     id: rcDialog
    //     property int selectedValue: 1500
    //     property int channelNo: -1
    //     standardButtons: StandardButton.Ok | StandardButton.Cancel

    //     ColumnLayout {

    //         Slider {
    //             id: rcSlider
    //             from: 1200
    //             to: 1800
    //             stepSize: 1
    //             value: rcDialog.selectedValue
    //             onValueChanged: rcDialog.selectedValue = Math.round(value)
    //             width: 300
    //         }

    //         Text {
    //             text: "Selected: " + rcDialog.selectedValue
    //         }
    //     }

    //     onAccepted: {
    //         if(rcDialog.channelNo > 0) {
    //             _activeVehicle.setRcOverride(rcDialog.channelNo, rcDialog.selectedValue)
    //             //_activeVehicle.startOverride()
    //         }
    //     }
    // }


    Rectangle {
        id: bigMessages
        visible: showBigMessages
        width: parent.width * 0.8
        height: parent.height * 0.8
        radius: ScreenTools.defaultFontPixelWidth
        color: "#dd000000"
        border.color: "#888"
        border.width: 1
        z: 1000

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        // 🔹 DRAG SUPPORT (does not break clicks)
        DragHandler {
            target: bigMessages
            grabPermissions: PointerHandler.CanTakeOverFromItems
        }

        // 🔹 HEADER BAR
        Rectangle {
            id: header
            height: ScreenTools.defaultFontPixelHeight * 3
            width: parent.width
            color: "#aa000000"
            radius: parent.radius

            QGCLabel {
                text: qsTr("Messages")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                font.bold: true
                color: "white"
            }

            // ❌ CLOSE BUTTON
            QGCLabel {
                text: "✕"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 12
                font.bold: true
                font.pointSize: 16
                color: "white"

                MouseArea {
                    anchors.fill: parent
                    onClicked: showBigMessages = false
                }
            }
        }

        // 🔹 MESSAGE LIST (reuse same model)
        ListView {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            model: messageListModel

            delegate: Rectangle {
                width: listView.width
                color: "transparent"
                QGCLabel {
                    text: model.text
                    wrapMode: Text.Wrap
                    anchors.margins: 8
                    anchors.left: parent.left
                    width: parent.width - 16
                    color: "white"
                    font.pointSize: ScreenTools.isMobile ? 8 : 12
                }
                height: childrenRect.height + 10
            }
        }

        function populateFromFormattedMessages() {
            messageListModel.clear()
            if (!_activeVehicle || !_activeVehicle.formattedMessages) return
            var lines = _activeVehicle.formattedMessages.split("\n")
            for (var i = 0; i < lines.length; ++i) {
                var line = lines[i].trim()
                if (line.length > 0) {
                    messageListModel.append({ text: line })
                }
            }
        }
    }


    // function takeScreenshot() {
    //     console.log("Button clicked of ss")

    //     // ✅ Choose a REAL visible item
    //     var item = videoControl   // or mapControl or _root

    //     if (!item || !item.visible || item.width === 0 || item.height === 0) {
    //         console.warn("Item not ready for screenshot")
    //         return
    //     }

    //     Qt.callLater(function () {
    //         item.grabToImage(function (result) {
    //             if (!result) {
    //                 console.warn("grabToImage returned null")
    //                 return
    //             }

    //             // ✅ Remove file://
    //             var basePath = StandardPaths.writableLocation(
    //                                StandardPaths.PicturesLocation
    //                            ).replace("file://", "")

    //             var path = basePath + "/QGC_Screenshot_" + Date.now() + ".png"

    //             console.log("Saving to:", path)

    //             if (result.saveToFile(path)) {
    //                 console.log("✅ Screenshot saved at:", path)
    //             } else {
    //                 console.log("❌ Failed to save screenshot")
    //             }
    //         })
    //     })
    // }


}


