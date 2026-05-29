/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                              2.11
import QtQuick.Controls                     2.4

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

//-------------------------------------------------------------------------
//-- Mode Indicator
QGCComboBox {
    anchors.verticalCenter: parent.verticalCenter
    alternateText:          _activeVehicle ? _activeVehicle.flightMode : ""
    model:                  _flightModes
    font.pointSize:         ScreenTools.mediumFontPointSize
    currentIndex:           -1
    sizeToContents:         true

    property bool showIndicator: true

    property var _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    // Only show specific flight modes (case-insensitive matching)
    property var _flightModes: _calcFilteredModes()
    property var _allowedModes: ["stabilize","stabilized","loiter","hold","guided","auto","mission","altitude hold","altitude","depth hold","rtl","return","land","surface"]
    function _calcFilteredModes() {
        if (!_activeVehicle) return []
        return _activeVehicle.flightModes.filter(function(m) { return _allowedModes.indexOf(m.toLowerCase()) !== -1 })
    }
    on_ActiveVehicleChanged: _flightModes = _calcFilteredModes()
    Connections {
        target: _activeVehicle
        onFlightModesChanged: _flightModes = _calcFilteredModes()
    }

    onActivated: {
        _activeVehicle.flightMode = _flightModes[index]
        currentIndex = -1
    }
}
