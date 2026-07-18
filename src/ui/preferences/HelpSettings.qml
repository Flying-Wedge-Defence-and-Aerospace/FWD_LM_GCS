/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Layouts  1.11

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

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

    QGCLabel {
        text: "Help"
        anchors.centerIn: parent
    }


}


// Rectangle {
//     color:          qgcPal.window
//     anchors.fill:   parent

//     readonly property real _margins: ScreenTools.defaultFontPixelHeight

//     QGCPalette { id: qgcPal; colorGroupEnabled: true }

//     QGCFlickable {
//         anchors.margins:    _margins
//         anchors.fill:       parent
//         contentWidth:       grid.width
//         contentHeight:      grid.height
//         clip:               true

//         GridLayout {
//             id:         grid
//             columns:    2

//             QGCLabel { text: qsTr("QGroundControl User Guide") }
//             QGCLabel {
//                 linkColor:          qgcPal.text
//                 text:               "<a href=\"https://docs.qgroundcontrol.com\">https://docs.qgroundcontrol.com</a>"
//                 onLinkActivated:    Qt.openUrlExternally(link)
//             }

//             QGCLabel { text: qsTr("PX4 Users Discussion Forum") }
//             QGCLabel {
//                 linkColor:          qgcPal.text
//                 text:               "<a href=\"http://discuss.px4.io/c/qgroundcontrol\">http://discuss.px4.io/c/qgroundcontrol</a>"
//                 onLinkActivated:    Qt.openUrlExternally(link)
//             }

//             QGCLabel { text: qsTr("ArduPilot Users Discussion Forum") }
//             QGCLabel {
//                 linkColor:          qgcPal.text
//                 text:               "<a href=\"https://discuss.ardupilot.org/c/ground-control-software/qgroundcontrol\">https://discuss.ardupilot.org/c/ground-control-software/qgroundcontrol</a>"
//                 onLinkActivated:    Qt.openUrlExternally(link)
//             }
//         }
//     }
// }
