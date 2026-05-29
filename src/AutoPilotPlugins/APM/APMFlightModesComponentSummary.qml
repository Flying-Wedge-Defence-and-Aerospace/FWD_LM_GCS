import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.3

import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Item {
    anchors.fill:   parent

    FactPanelController { id: controller; }

    property var    _vehicle:       controller.vehicle
    property bool   _roverFirmware: controller.parameterExists(-1, "MODE1") // This catches all usage of ArduRover firmware vehicle types: Rover, Boat...

    property Fact flightMode1: controller.getParameterFact(-1, _roverFirmware ? "MODE1" : "FLTMODE1")
    property Fact flightMode2: controller.getParameterFact(-1, _roverFirmware ? "MODE2" : "FLTMODE2")
    property Fact flightMode3: controller.getParameterFact(-1, _roverFirmware ? "MODE3" : "FLTMODE3")
    property Fact flightMode4: controller.getParameterFact(-1, _roverFirmware ? "MODE4" : "FLTMODE4")
    property Fact flightMode5: controller.getParameterFact(-1, _roverFirmware ? "MODE5" : "FLTMODE5")
    property Fact flightMode6: controller.getParameterFact(-1, _roverFirmware ? "MODE6" : "FLTMODE6")

    ColumnLayout {
        anchors.fill:       parent

        VehicleSummaryRow {
            labelText: qsTr("Flight Mode 1")
            valueText: flightMode1.enumStringValue
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
        }

        VehicleSummaryRow {
            labelText: qsTr("Flight Mode 2")
            valueText: flightMode2.enumStringValue
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
        }

        VehicleSummaryRow {
            labelText: qsTr("Flight Mode 3")
            valueText: flightMode3.enumStringValue
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
        }

        VehicleSummaryRow {
            labelText: qsTr("Flight Mode 4")
            valueText: flightMode4.enumStringValue
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
        }

        VehicleSummaryRow {
            labelText: qsTr("Flight Mode 5")
            valueText: flightMode5.enumStringValue
        }

        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelWidth * 0.1
            color: "#888"
        }

        VehicleSummaryRow {
            labelText: qsTr("Flight Mode 6")
            valueText: flightMode6.enumStringValue
        }
    }
}
