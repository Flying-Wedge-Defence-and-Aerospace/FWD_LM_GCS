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

    property var  adsbSettings:    QGroundControl.settingsManager.adsbVehicleManagerSettings

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        Rectangle {
            id: smallBox
            width: ScreenTools.defaultFontPixelWidth * 75  /*ScreenTools.defaultFontPixelWidth * 8 * (Screen.pixelDensity / 160)*/     // small width
            height: firstLayout.height + 20    // height to fit 3 numbers
            radius: 6
            color: "transparent"
            border.color: "#888"
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            ColumnLayout {
                id: firstLayout
                anchors.centerIn: parent
                //anchors.margins: 8
                spacing: ScreenTools.defaultFontPixelWidth * 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 20
                    visible: adsbSettings.adsbServerConnectEnabled.visible

                    QGCLabel {
                        text: "Connect to ADSB SBS server"
                        font.pointSize: 10
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        horizontalAlignment: Text.AlignLeft
                    }

                    Item { Layout.fillWidth: true }

                    FactToggleSwitch {
                        id: adsbSwitch
                        fact:       adsbSettings.adsbServerConnectEnabled
                    }
                }

                Rectangle {
                    height: 1
                    Layout.fillWidth: true
                    color: "gray"
                    visible: serverLayout.visible
                }

                RowLayout {
                    id: serverLayout
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 20
                    visible: adsbSettings.adsbServerConnectEnabled.visible

                    QGCLabel {
                        text: adsbSettings.adsbServerHostAddress.shortDescription
                        font.pointSize: 10
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        horizontalAlignment: Text.AlignLeft
                        opacity: adsbSwitch.checked ? 1.0 : 0.4
                    }

                    Item { Layout.fillWidth: true }

                    FactTextField {
                        fact:       adsbSettings.adsbServerHostAddress
                        enabled: adsbSwitch.checked
                        opacity: adsbSwitch.checked ? 1.0 : 0.4
                    }
                }

                Rectangle {
                    height: 1
                    Layout.fillWidth: true
                    color: "gray"
                    visible: portLayout.visible
                }

                RowLayout {
                    id: portLayout
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 20
                    visible: adsbSettings.adsbServerPort.visible

                    QGCLabel {
                        text: adsbSettings.adsbServerPort.shortDescription
                        font.pointSize: 10
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        horizontalAlignment: Text.AlignLeft
                        opacity: adsbSwitch.checked ? 1.0 : 0.4
                    }

                    Item { Layout.fillWidth: true }

                    FactTextField {
                        fact:       adsbSettings.adsbServerPort
                        enabled: adsbSwitch.checked
                        opacity: adsbSwitch.checked ? 1.0 : 0.4
                    }
                }
            }
        }
    }
}
