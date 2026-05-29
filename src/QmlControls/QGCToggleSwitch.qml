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

Rectangle {
    id: toggleSwitch
    width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 4.5 : ScreenTools.defaultFontPixelWidth * 8.5
    height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 1 : ScreenTools.defaultFontPixelHeight * 1.5
    radius: height / 2
    color: checked ? "#2196F3" : "#5A7D9A"
    property bool checked: false

    Rectangle {
        id: knob
        width: parent.height - 6
        height: parent.height - 6
        radius: height / 2
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        x: toggleSwitch.checked ? parent.width - width - 3 : 3
        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            toggleSwitch.checked = !toggleSwitch.checked
                //console.log("Toggle:", toggleSwitch.checked)
        }
    }
}
