/****************************************************************************
 *
 * (c) 2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Layouts          1.12
import QtQuick.Controls         2.4

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:                 quickValuesBar
    height:             quickLayout.height + (_toolsMargin * 2)
    width:              quickLayout.width + (_toolsMargin * 2)
    color:              qgcPal.window
    radius:             ScreenTools.defaultFontPixelWidth / 2

    property bool       _toolsMargin: ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    DeadMouseArea { anchors.fill: parent }

    ColumnLayout {
        id:                 quickLayout
        anchors.margins:    _toolsMargin
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left

        QGCLabel {
            text: qsTr("QUICK")
            font.bold: true
            color: qgcPal.text
        }

        HorizontalFactValueGrid {
            id:                     valueArea
            userSettingsGroup:      "QuickValuesUserSettings"
            defaultSettingsGroup:   "QuickValuesDefaultSettings"
            settingsUnlocked:       false
        }
    }

    // Right-click context menu for add/remove (Mission Planner style)
    MouseArea {
        anchors.fill: valueArea
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                ctxMenu.x = mouse.x
                ctxMenu.y = mouse.y
                ctxMenu.open()
            }
        }
    }

    Menu {
        id: ctxMenu
        MenuItem {
            text: qsTr("Add column")
            onTriggered: valueArea.appendColumn()
        }
        MenuItem {
            text: qsTr("Remove last column")
            enabled: valueArea.columns.count > 1
            onTriggered: valueArea.deleteLastColumn()
        }
        MenuItem {
            text: qsTr("Add row")
            onTriggered: valueArea.appendRow()
        }
        MenuItem {
            text: qsTr("Remove last row")
            enabled: valueArea.rowCount > 1
            onTriggered: valueArea.deleteLastRow()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Reset to defaults")
            onTriggered: valueArea.resetToDefaults()
        }
    }
}