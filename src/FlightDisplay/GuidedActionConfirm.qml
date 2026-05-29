// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick          2.12
// import QtQuick.Controls 2.4
// import QtQuick.Layouts  1.12

// import QGroundControl               1.0
// import QGroundControl.ScreenTools   1.0
// import QGroundControl.Controls      1.0
// import QGroundControl.Palette       1.0

// Rectangle {
//     id:         _root
//     width:      ScreenTools.defaultFontPixelWidth * 50
//     height:     mainLayout.height + (_margins * 6)
//     radius:     ScreenTools.defaultFontPixelWidth / 2
//     color:      /*qgcPal.window*/ "#55000000"
//     visible:    false
//     border.color: "white"
//     border.width: 2

//     property var    guidedController
//     property var    guidedValueSlider
//     property string title                                       // Currently unused
//     property alias  message:            messageText.text
//     property int    action
//     property var    actionData
//     property bool   hideTrigger:        false
//     property var    mapIndicator
//     property alias  optionText:         optionCheckBox.text
//     property alias  optionChecked:      optionCheckBox.checked

//     property real _margins:         ScreenTools.defaultFontPixelWidth / 2
//     property bool _emergencyAction: action === guidedController.actionEmergencyStop

//     Component.onCompleted: guidedController.confirmDialog = this

//     onVisibleChanged: {
//         if (visible) {
//             slider.focus = true
//         }
//     }

//     onHideTriggerChanged: {
//         if (hideTrigger) {
//             confirmCancelled()
//         }
//     }

//     function show(immediate) {
//         if (immediate) {
//             visible = true
//         } else {
//             // We delay showing the confirmation for a small amount in order for any other state
//             // changes to propogate through the system. This way only the final state shows up.
//             visibleTimer.restart()
//         }
//     }

//     function confirmCancelled() {
//         guidedValueSlider.visible = false
//         visible = false
//         hideTrigger = false
//         visibleTimer.stop()
//         if (mapIndicator) {
//             mapIndicator.actionCancelled()
//             mapIndicator = undefined
//         }
//     }

//     Timer {
//         id:             visibleTimer
//         interval:       1000
//         repeat:         false
//         onTriggered:    visible = true
//     }

//     QGCPalette { id: qgcPal }

//     ColumnLayout {
//         id:                 mainLayout
//         anchors.margins:    _margins + 20
//         anchors.left:       parent.left
//         anchors.right:      parent.right
//         spacing:            _margins + 10

//         QGCLabel {
//             id:                     messageText
//             Layout.fillWidth:       true
//             horizontalAlignment:    Text.AlignHCenter
//             Layout.topMargin: 10
//             wrapMode:               Text.WordWrap
//             font.pointSize:         ScreenTools.mediumFontPointSize
//             font.bold: true
//             font.italic: true
//             color: "yellow"
//         }

//         QGCCheckBox {
//             id:                 optionCheckBox
//             Layout.alignment:   Qt.AlignHCenter
//             text:               ""
//             visible:            text !== ""
//         }

//         Rectangle {
//             Layout.fillWidth: true
//             color: "white"
//             height: 2
//         }

//         RowLayout {
//             Layout.fillWidth:   true
//             spacing:            ScreenTools.defaultFontPixelWidth

//             // SliderSwitch {
//             //     id:                 slider
//             //     confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
//             //     Layout.fillWidth:   true

//             //     onAccept: {
//             //         _root.visible = false
//             //         var sliderOutputValue = 0
//             //         if (guidedValueSlider.visible) {
//             //             sliderOutputValue = guidedValueSlider.getOutputValue()
//             //             guidedValueSlider.visible = false
//             //         }
//             //         hideTrigger = false
//             //         guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
//             //         if (mapIndicator) {
//             //             mapIndicator.actionConfirmed()
//             //             mapIndicator = undefined
//             //         }
//             //     }
//             // }

//             QGCLabel {
//                 id:                 slider
//                 //confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
//                 text: qsTr("Click for above action")
//                 font.pointSize: 10
//                 font.bold: true
//             }

//             Item {
//                 Layout.fillWidth: true
//             }

//             // Rectangle {
//             //     height: slider.height + 16
//             //     width:  height
//             //     radius: height / 2
//             //     color:  qgcPal.primaryButton

//             //     QGCColoredImage {
//             //         anchors.margins:    parent.height / 4
//             //         anchors.fill:       parent
//             //         source:             "/res/XDelete.svg"
//             //         fillMode:           Image.PreserveAspectFit
//             //         color:              qgcPal.text
//             //     }

//             //     QGCMouseArea {
//             //         fillItem:   parent
//             //         onClicked:  confirmCancelled()
//             //     }
//             // }

//             Rectangle {
//                 height: slider.height + 16
//                 width:  height
//                 radius: height / 2
//                 color:  qgcPal.primaryButton

//                 QGCColoredImage {
//                     anchors.margins:    parent.height / 4
//                     anchors.fill:       parent
//                     source:             "/res/tick_icon"
//                     fillMode:           Image.PreserveAspectFit
//                     color:              qgcPal.text
//                 }

//                 QGCMouseArea {
//                     fillItem:   parent
//                     onClicked: {
//                         _root.visible = false
//                         var sliderOutputValue = 0
//                         if (guidedValueSlider.visible) {
//                             sliderOutputValue = guidedValueSlider.getOutputValue()
//                             guidedValueSlider.visible = false
//                         }
//                         hideTrigger = false
//                         guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
//                         if (mapIndicator) {
//                             mapIndicator.actionConfirmed()
//                             mapIndicator = undefined
//                         }
//                     }
//                 }

//                 Rectangle {
//                     height: slider.height + 16
//                     width:  height
//                     radius: height / 2
//                     color:  qgcPal.primaryButton

//                     QGCColoredImage {
//                         anchors.margins:    parent.height / 4
//                         anchors.fill:       parent
//                         source:             "/res/XDelete.svg"
//                         fillMode:           Image.PreserveAspectFit
//                         color:              qgcPal.text
//                     }

//                     QGCMouseArea {
//                         fillItem:   parent
//                         onClicked:  confirmCancelled()
//                     }
//                 }
//             }
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

import QtQuick          2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.12

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:         _root
    width:      ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 40 : ScreenTools.defaultFontPixelWidth * 50
    height:     mainLayout.height + (_margins * 6)
    radius:     /*ScreenTools.defaultFontPixelWidth / 4*/ 10
    color: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue ? "#aa000000" : "#aaffffff"
    visible:    false
    border.color: "gray"
    border.width: 2

    property var    guidedController
    property var    guidedValueSlider
    property string title                                       // Currently unused
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth / 2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            slider.focus = true
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        guidedValueSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    QGCPalette { id: qgcPal }

    ColumnLayout {
        id:                 mainLayout
        anchors.margins:    _margins + 20
        anchors.left:       parent.left
        anchors.right:      parent.right
        spacing:            _margins + 10

        QGCLabel {
            id:                     messageText
            Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            Layout.topMargin: 10
            wrapMode:               Text.WordWrap
            font.pointSize:         ScreenTools.mediumFontPointSize
            font.bold: true
            font.italic: true
        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
        }

        // Rectangle {
        //     id: borderedBox
        //     Layout.fillWidth: true
        //    //height: messageLayout.height + 15
        //     color: "transparent"
        //     border.color: "white"
        //     border.width: 1
        //     radius: 6
        //     Layout.margins: 15

        //    implicitHeight: messageLayout.implicitHeight + 20

        //     ColumnLayout {
        //        id: messageLayout
        //        anchors.fill: parent
        //        anchors.centerIn: parent
        //         spacing: 8
        //        //anchors.margins: 10

        //         QGCLabel {
        //            id:                     messageText
        //            Layout.fillWidth:       true
        //            horizontalAlignment:    Text.AlignHCenter
        //            wrapMode:               Text.WordWrap
        //             font.pointSize:         ScreenTools.mediumFontPointSize
        //         }

        //         QGCCheckBox {
        //            id:                 optionCheckBox
        //            Layout.alignment:   Qt.AlignHCenter
        //            text:               ""
        //            visible:            text !== ""
        //         }
        //     }
        // }

        Rectangle {
            Layout.fillWidth: true
            color: "gray"
            height: 2
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth


            // SliderSwitch {
            //     id:                 slider
            //     confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
            //     Layout.fillWidth:   true

            //     onAccept: {
            //         _root.visible = false
            //         var sliderOutputValue = 0
            //         if (guidedValueSlider.visible) {
            //             sliderOutputValue = guidedValueSlider.getOutputValue()
            //             guidedValueSlider.visible = false
            //         }
            //         hideTrigger = false
            //         guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
            //         if (mapIndicator) {
            //             mapIndicator.actionConfirmed()
            //             mapIndicator = undefined
            //         }
            //     }
            // }

            Rectangle {
                height: slider.height + 20
                width:  height
                radius: height / 2
                color:  qgcPal.primaryButton

                QGCColoredImage {
                    anchors.margins:    parent.height / 4
                    anchors.fill:       parent
                    source:             "/res/tick_icon"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.text
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked: {
                        _root.visible = false
                        var sliderOutputValue = 0
                        if (guidedValueSlider.visible) {
                            sliderOutputValue = guidedValueSlider.getOutputValue()
                            guidedValueSlider.visible = false
                        }
                        hideTrigger = false
                        guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                        if (mapIndicator) {
                            mapIndicator.actionConfirmed()
                            mapIndicator = undefined
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }


            QGCLabel {
                id:                 slider
                //confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
                text: qsTr("Click for above action")
                font.pointSize: 10
                font.bold: true
                //Layout.fillWidth:   true

                // onClicked: {
                //     _root.visible = false
                //     var sliderOutputValue = 0
                //     if (guidedValueSlider.visible) {
                //         sliderOutputValue = guidedValueSlider.getOutputValue()
                //         guidedValueSlider.visible = false
                //     }
                //     hideTrigger = false
                //     guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                //     if (mapIndicator) {
                //         mapIndicator.actionConfirmed()
                //         mapIndicator = undefined
                //     }
                // }
            }
            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                height: slider.height + 20
                width:  height
                radius: height / 2
                color:  qgcPal.primaryButton

                QGCColoredImage {
                    anchors.margins:    parent.height / 4
                    anchors.fill:       parent
                    source:             "/res/XDelete.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.text
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  confirmCancelled()
                }
            }
        }
    }
}


