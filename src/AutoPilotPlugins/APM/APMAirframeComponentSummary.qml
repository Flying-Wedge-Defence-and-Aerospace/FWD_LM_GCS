import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.3

import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Controls 1.0
import QGroundControl.Controllers 1.0
import QGroundControl.Palette 1.0
import QGroundControl.ScreenTools   1.0

Item {
    anchors.fill:       parent

    APMAirframeComponentController {id: controller; }

    property Fact _frameClass:          controller.getParameterFact(-1, "FRAME_CLASS")
    property Fact _frameType:           controller.getParameterFact(-1, "FRAME_TYPE", false)
    property bool _frameTypeAvailable:  controller.parameterExists(-1, "FRAME_TYPE")

    ColumnLayout {
        anchors.fill:       parent

        VehicleSummaryRow {
            labelText:  qsTr("Frame Class")
            valueText:  _frameClass.enumStringValue
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
            visible: _frameTypeAvailable
        }

        VehicleSummaryRow {
            labelText:  qsTr("Frame Type")
            valueText:  visible ? _frameType.enumStringValue : ""
            visible:    _frameTypeAvailable
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
        }

        VehicleSummaryRow {
            labelText: qsTr("Firmware Version")
            valueText: globals.activeVehicle.firmwareMajorVersion === -1 ? qsTr("Unknown") : globals.activeVehicle.firmwareMajorVersion + "." + globals.activeVehicle.firmwareMinorVersion + "." + globals.activeVehicle.firmwarePatchVersion + globals.activeVehicle.firmwareVersionTypeString
        }
    }
}
