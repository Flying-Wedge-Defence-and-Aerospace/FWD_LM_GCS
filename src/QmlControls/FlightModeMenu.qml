/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.12
import QtQuick.Controls             2.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

// Label control whichs pop up a flight mode change menu when clicked
QGCLabel {
    id:     _root
    text:   currentVehicle ? currentVehicle.flightMode : qsTr("N/A", "No data to display")

    property var    currentVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   mouseAreaLeftMargin:    0

    Menu {
        id: flightModesMenu
    }

    Component {
        id: flightModeMenuItemComponent

        MenuItem {
            enabled: true
            onTriggered: currentVehicle.flightMode = text
        }
    }

    property var flightModesMenuItems: []

    // Only show specific flight modes (case-insensitive matching)
    property var _allowedModes: ["stabilize","stabilized","loiter","hold","guided","auto","mission","altitude hold","altitude","depth hold","rtl","return","land","surface"]

    function _filterModes(modes) {
        if (!modes) return []
        return modes.filter(function(m) { return _allowedModes.indexOf(m.toLowerCase()) !== -1 })
    }

    function updateFlightModesMenu() {
        if (currentVehicle && currentVehicle.flightModeSetAvailable) {
            var i;
            var filteredModes = _filterModes(currentVehicle.flightModes)
            // Remove old menu items
            for (i = 0; i < flightModesMenuItems.length; i++) {
                flightModesMenu.removeItem(flightModesMenuItems[i])
            }
            flightModesMenuItems.length = 0
            // Add new items
            for (i = 0; i < filteredModes.length; i++) {
                var menuItem = flightModeMenuItemComponent.createObject(null, { "text": filteredModes[i] })
                flightModesMenuItems.push(menuItem)
                flightModesMenu.insertItem(i, menuItem)
            }
        }
    }

    Component.onCompleted: _root.updateFlightModesMenu()

    Connections {
        target:                 QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) { _root.updateFlightModesMenu() }
    }
    Connections {
        target:                 currentVehicle
        onFlightModesChanged:   _root.updateFlightModesMenu()
    }

    MouseArea {
        id:                 mouseArea
        visible:            currentVehicle && currentVehicle.flightModeSetAvailable
        anchors.leftMargin: mouseAreaLeftMargin
        anchors.fill:       parent
        onClicked:          flightModesMenu.popup((_root.width - flightModesMenu.width) / 2, _root.height)
    }
}
