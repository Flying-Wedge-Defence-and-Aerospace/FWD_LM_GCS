/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.4

import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Button {
    id: _rootButton
    property var imageColor: undefined
    property string imageResource: "/qmlimages/subMenuButtonImage.png"
    property size sourceSize: Qt.size(ScreenTools.defaultFontPixelHeight * 2, ScreenTools.defaultFontPixelHeight * 2)

    text: "Button"
    activeFocusOnPress: true

    implicitHeight: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 2 : ScreenTools.defaultFontPixelHeight * 2.5//ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3.5 : ScreenTools.defaultFontPixelHeight * 2.5
    implicitWidth: __panel.implicitWidth

    onCheckedChanged: checkable = false

    property bool indicatorGreen: false ///< true: no indicator shown, false: red indicator shown
    property url iconSource: ""
    property bool showIndicator: true

    style: ButtonStyle {
        id: buttonStyle

        QGCPalette {
            id: qgcPal
            colorGroupEnabled: control.enabled
        }

        property bool showHighlight: control.pressed | control.checked

        background: Rectangle {
            id: innerRect
            color: !_rootButton.enabled ? "gray" : control.checked ? "#1aa1a1" : _rootButton.hovered ? "#16c2c2" : "#2c3e50"

            Behavior on color { ColorAnimation { duration: 150 } }

            //radius: 10
            implicitWidth: titleBar.x + titleBar.contentWidth + (ScreenTools.isMobile ? 0 : ScreenTools.defaultFontPixelHeight)

            QGCColoredImage {
                id: image
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 1 : ScreenTools.defaultFontPixelHeight * 2
                height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 1 : ScreenTools.defaultFontPixelHeight * 2
                fillMode: Image.PreserveAspectFit
                mipmap: true
                color: /*imageColor ? imageColor : (control.setupComplete ? qgcPal.button : "red")*/ "white"
                source: control.imageResource
                sourceSize: _rootButton.sourceSize
            }

            QGCLabel {
                id: titleBar
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left: image.right
                anchors.verticalCenter: parent.verticalCenter
                verticalAlignment: TextEdit.AlignVCenter
                font.family: "Courier New"
                color: "white"
                text: control.text
                font.pointSize: ScreenTools.isMobile ? 8 : 9
            }
        }
        label: Item {}
    }

    Rectangle {
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 3
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:                  radius * 2
        height:                 width
        radius:                 (ScreenTools.defaultFontPixelHeight * .75) / 2
        color:                  "red"
        visible:                enabled && !indicatorGreen && showIndicator
    }
}


// import QtQuick          2.3
// import QtQuick.Controls 1.2

// import QGroundControl.Controls      1.0
// import QGroundControl.Palette       1.0
// import QGroundControl.ScreenTools   1.0

// /// Works just like a regular button but it can have a red indicator on the right side displayed
// QGCButton {
//     property bool indicatorGreen: false ///< true: no indicator shown, false: red indicator shown

//     Rectangle {
//         anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 3
//         anchors.right:          parent.right
//         anchors.verticalCenter: parent.verticalCenter
//         width:                  radius * 2
//         height:                 width
//         radius:                 (ScreenTools.defaultFontPixelHeight * .75) / 2
//         color:                  "red"
//         visible:                enabled && !indicatorGreen
//     }
// }
