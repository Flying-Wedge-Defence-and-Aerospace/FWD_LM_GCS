// // /****************************************************************************
// //  *
// //  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
// //  *
// //  * QGroundControl is licensed according to the terms in the file
// //  * COPYING.md in the root of the source code directory.
// //  *
// //  ****************************************************************************/

// // import QtQuick          2.3
// // import QtQuick.Controls 2.4

// // import QGroundControl               1.0
// // import QGroundControl.Controls      1.0
// // import QGroundControl.Palette       1.0
// // import QGroundControl.ScreenTools   1.0

// // // Important Note: Toolbar buttons must manage their checked state manually in order to support
// // // view switch prevention. This means they can't be checkable or autoExclusive.

// // Button {
// //     id:                 button
// //     height:             ScreenTools.defaultFontPixelHeight * 3
// //     leftPadding:        _horizontalMargin
// //     rightPadding:       _horizontalMargin
// //     checkable:          false

// //     property bool logo: false

// //     property real _horizontalMargin: ScreenTools.defaultFontPixelWidth

// //     onCheckedChanged: checkable = false

// //     background: Rectangle {
// //         anchors.fill:   parent
// //         color:          button.checked ? qgcPal.buttonHighlight : Qt.rgba(0,0,0,0)
// //         border.color:   "red"
// //         border.width:   QGroundControl.corePlugin.showTouchAreas ? 3 : 0
// //     }

// //     contentItem: Row {
// //         spacing:                ScreenTools.defaultFontPixelWidth
// //         anchors.verticalCenter: button.verticalCenter
// //         QGCColoredImage {
// //             id:                     _icon
// //             height:                 ScreenTools.defaultFontPixelHeight * 2
// //             width:                  height
// //             sourceSize.height:      parent.height
// //             fillMode:               Image.PreserveAspectFit
// //             color:                  logo ? "transparent" : (button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText)
// //             source:                 button.icon.source
// //             anchors.verticalCenter: parent.verticalCenter
// //         }
// //         Label {
// //             id:                     _label
// //             visible:                text !== ""
// //             text:                   button.text
// //             color:                  button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
// //             anchors.verticalCenter: parent.verticalCenter
// //         }
// //     }
// // }


// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  ****************************************************************************/

// import QtQuick          2.3
// import QtQuick.Controls 2.4

// import QGroundControl               1.0
// import QGroundControl.Controls      1.0
// import QGroundControl.Palette       1.0
// import QGroundControl.ScreenTools   1.0

// Button {
//     id: button
//     height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight - 60 : ScreenTools.defaultFontPixelHeight * 1.5
//     leftPadding:/* _horizontalMargin*/ 0
//     rightPadding: /*_horizontalMargin*/ 0
//     checkable: false

//     property bool logo: false
//     property real iconSize: ScreenTools.defaultFontPixelHeight * (ScreenTools.isMobile ? 1.7 : 2)
//     property real _horizontalMargin: ScreenTools.defaultFontPixelWidth / 2

//     // Hover handling
//     hoverEnabled: true
//     //property bool hovered: false

//     // Custom colors
//     property color normalColor: "transparent"
//     property color hoverColor: "#23233d"
//     property color pressedColor: "#23233d"
//     property color normalIconColor: "#8a8aa3"
//     property color hoverIconColor: "#ffffff"
//     property color pressedIconColor: "#ffffff"

//     background: Rectangle {
//         anchors.fill: parent
//         width: parent.width * 0.9
//         height: parent.height * 0.9
//         color: button.down
//                ? button.pressedColor
//                : button.hovered
//                     ? button.hoverColor
//                     : button.normalColor
//         radius: 6
//         border.width: 0
//         border.color: "transparent"
//     }

//     contentItem: Column {
//         spacing: /*ScreenTools.defaultFontPixelWidth*/ -1
//         anchors.horizontalCenter: button.horizontalCenter

//         QGCColoredImage {
//             id: _icon
//             height: button.iconSize
//             width: height
//             sourceSize.height: parent.height
//             fillMode: Image.PreserveAspectFit
//             color: logo
//                 ? "transparent"
//                 : (button.down
//                     ? button.pressedIconColor
//                     : button.hovered
//                         ? button.hoverIconColor
//                         : button.normalIconColor)
//             source: button.icon.source
//             anchors.horizontalCenter: parent.horizontalCenter
//         }

//         Label {
//             id: _label
//             visible: text !== ""
//             text: button.text
//             color: button.down
//                     ? button.pressedIconColor
//                     : button.hovered
//                         ? button.hoverIconColor
//                         : button.normalIconColor
//             anchors.horizontalCenter: parent.horizontalCenter
//         }
//     }
// }





// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick          2.3
// import QtQuick.Controls 2.4

// import QGroundControl               1.0
// import QGroundControl.Controls      1.0
// import QGroundControl.Palette       1.0
// import QGroundControl.ScreenTools   1.0

// // Important Note: Toolbar buttons must manage their checked state manually in order to support
// // view switch prevention. This means they can't be checkable or autoExclusive.

// Button {
//     id:                 button
//     height:             ScreenTools.defaultFontPixelHeight * 3
//     leftPadding:        _horizontalMargin
//     rightPadding:       _horizontalMargin
//     checkable:          false

//     property bool logo: false

//     property real _horizontalMargin: ScreenTools.defaultFontPixelWidth

//     onCheckedChanged: checkable = false

//     background: Rectangle {
//         anchors.fill:   parent
//         color:          button.checked ? qgcPal.buttonHighlight : Qt.rgba(0,0,0,0)
//         border.color:   "red"
//         border.width:   QGroundControl.corePlugin.showTouchAreas ? 3 : 0
//     }

//     contentItem: Row {
//         spacing:                ScreenTools.defaultFontPixelWidth
//         anchors.verticalCenter: button.verticalCenter
//         QGCColoredImage {
//             id:                     _icon
//             height:                 ScreenTools.defaultFontPixelHeight * 2
//             width:                  height
//             sourceSize.height:      parent.height
//             fillMode:               Image.PreserveAspectFit
//             color:                  logo ? "transparent" : (button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText)
//             source:                 button.icon.source
//             anchors.verticalCenter: parent.verticalCenter
//         }
//         Label {
//             id:                     _label
//             visible:                text !== ""
//             text:                   button.text
//             color:                  button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
//             anchors.verticalCenter: parent.verticalCenter
//         }
//     }
// }


/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 2.4

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Button {
    id: button
    height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight - 60 : ScreenTools.defaultFontPixelHeight * 1.5
    leftPadding:/* _horizontalMargin*/ 0
    rightPadding: /*_horizontalMargin*/ 0
    checkable: false

    property bool logo: false
    property real _horizontalMargin: ScreenTools.defaultFontPixelWidth / 2

    // Hover handling
    hoverEnabled: true
    //property bool hovered: false

    // Custom colors
    property color normalColor: "transparent"
    property color hoverColor: "#40FFFFFF"          // light semi-transparent white
    property color pressedColor: "#80FFFFFF"        // brighter when pressed
    property color normalIconColor: /*qgcPal.buttonText*/ "white"
    property color hoverIconColor: qgcPal.buttonHighlight
    property color pressedIconColor: qgcPal.buttonHighlightText

    // Detect hover state
   // onHoveredChanged: hovered = hovered

    background: Rectangle {
        anchors.fill: parent
        width: parent.width * 0.9    // Reduce hover background size
        height: parent.height * 0.9
        color: button.down
               ? button.pressedColor
               : button.hovered
                    ? button.hoverColor
                    : button.normalColor
        radius: 6
        border.width: QGroundControl.corePlugin.showTouchAreas ? 2 : 0
        border.color: "transparent"
    }

    contentItem: Column {
        spacing: /*ScreenTools.defaultFontPixelWidth*/ -1
        anchors.horizontalCenter: button.horizontalCenter

        QGCColoredImage {
            id: _icon
            height: ScreenTools.defaultFontPixelHeight * (ScreenTools.isMobile ? 1.7 : 2)
            width: height
            sourceSize.height: parent.height
            fillMode: Image.PreserveAspectFit
            color: logo
                ? "transparent"
                : (button.down
                    ? button.pressedIconColor
                    : button.hovered
                        ? button.hoverIconColor
                        : button.normalIconColor)
            source: button.icon.source
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: _label
            visible: text !== ""
            text: button.text
            color: button.down
                    ? button.pressedIconColor
                    : button.hovered
                        ? button.hoverIconColor
                        : button.normalIconColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}

