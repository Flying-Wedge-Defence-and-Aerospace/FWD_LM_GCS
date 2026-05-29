/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick          2.3
import QtQuick.Window   2.2
import QtQuick.Controls 1.2
import QtQml.Models 2.12

import QGroundControl           1.0
import QGroundControl.Controls  1.0

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist
    property var   activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
    property bool  _initialConnectComplete: activeVehicle ? activeVehicle.initialConnectComplete : false
     property bool  _isVehicleArmed:         _initialConnectComplete ? activeVehicle.armed : false
    property bool  _grip_enable:            _initialConnectComplete ? activeVehicle.hasGripper : false

    model: [
        // ToolStripAction {
        //     text:           qsTr("Plan")
        //     iconSource:     "/qmlimages/Plan.svg"
        //     onTriggered:    mainWindow.showPlanView()
        // },
        PreFlightCheckListShowAction {id: checkList;  onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff {id: takeOff },
        GuidedActionLand {id: actionLand },
        GuidedActionRTL {id: rtl },
        GuidedActionPause {id: pause },
        GuidedActionActionList {id: actionList },
        GuidedActionGripper {id: gripper }
    ]
}
