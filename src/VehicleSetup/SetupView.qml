/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl                       1.0
import QGroundControl.AutoPilotPlugin       1.0
import QGroundControl.Palette               1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0

Rectangle {
    id:     setupView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ExclusiveGroup { id: setupButtonGroup }

    readonly property real      _defaultTextHeight: ScreenTools.defaultFontPixelHeight
    readonly property real      _defaultTextWidth:  ScreenTools.defaultFontPixelWidth
    readonly property real      _horizontalMargin:  _defaultTextWidth / 2
    readonly property real      _verticalMargin:    _defaultTextHeight / 2
    readonly property real      _buttonWidth:       _defaultTextWidth * 18
    readonly property string    _armedVehicleText:  qsTr("This operation cannot be performed while the vehicle is armed.")

    property bool   _vehicleArmed:                  QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.armed : false
    property string _messagePanelText:              qsTr("missing message panel text")
    property bool   _fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters
    property var    _corePlugin:                    QGroundControl.corePlugin
    property string _parameterPassword:             "12345678"

    function showSummaryPanel() {
        if (mainWindow.preventViewSwitch()) {
            return
        }
        _showSummaryPanel()
    }

    function _showSummaryPanel() {
        if (_fullParameterVehicleAvailable) {
            if (QGroundControl.multiVehicleManager.activeVehicle.autopilot.vehicleComponents.length === 0) {
                panelLoader.setSourceComponent(noComponentsVehicleSummaryComponent)
            } else {
                panelLoader.setSource("VehicleSummary.qml")
            }
        } else if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable) {
            panelLoader.setSourceComponent(missingParametersVehicleSummaryComponent)
        } else {
            panelLoader.setSourceComponent(disconnectedVehicleSummaryComponent)
        }
        summaryButton.checked = true
    }

    function showPanel(button, qmlSource) {
        if (mainWindow.preventViewSwitch()) {
            return
        }
        button.checked = true
        panelLoader.setSource(qmlSource)
    }

    function showVehicleComponentPanel(vehicleComponent)
    {
        if (mainWindow.preventViewSwitch()) {
            return
        }
        var autopilotPlugin = QGroundControl.multiVehicleManager.activeVehicle.autopilot
        var prereq = autopilotPlugin.prerequisiteSetup(vehicleComponent)
        if (prereq !== "") {
            _messagePanelText = qsTr("%1 setup must be completed prior to %2 setup.").arg(prereq).arg(vehicleComponent.name)
            panelLoader.setSourceComponent(messagePanelComponent)
        } else {
            panelLoader.setSource(vehicleComponent. setupSource, vehicleComponent)
            for(var i = 0; i < componentRepeater.count; i++) {
                var obj = componentRepeater.itemAt(i);
                if (obj.text === vehicleComponent.name) {
                    obj.checked = true
                    break;
                }
            }
        }
    }

    Component.onCompleted: _showSummaryPanel()

    Connections {
        target: QGroundControl.corePlugin
        onShowAdvancedUIChanged: {
            if(!QGroundControl.corePlugin.showAdvancedUI) {
                _showSummaryPanel()
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager
        onParameterReadyVehicleAvailableChanged: {
            if(!QGroundControl.skipSetupPage) {
                if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable || summaryButton.checked || setupButtonGroup.current != firmwareButton) {
                    // Show/Reload the Summary panel when:
                    //      A new vehicle shows up
                    //      The summary panel is already showing and the active vehicle goes away
                    //      The active vehicle goes away and we are not on the Firmware panel.
                    summaryButton.checked = true
                    _showSummaryPanel()
                }
            }
        }
    }

    Component {
        id: noComponentsVehicleSummaryComponent
        Rectangle {
            color: qgcPal.windowShade
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("%1 does not currently support setup of your vehicle type. ").arg(QGroundControl.appName) +
                                        "If your vehicle is already configured you can still Fly."
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: disconnectedVehicleSummaryComponent
        Rectangle {
            color: qgcPal.windowShade
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.largeFontPointSize
                text:                   qsTr("Vehicle settings and info will display after connecting your vehicle.") +
                                        (ScreenTools.isMobile || !_corePlugin.options.showFirmwareUpgrade ? "" : " Click Firmware on the left to upgrade your vehicle.")

                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: missingParametersVehicleSummaryComponent

        Rectangle {
            color: qgcPal.windowShade

            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("You are currently connected to a vehicle but it did not return the full parameter list. ") +
                                        qsTr("As a result, the full set of vehicle setup options are not available.")

                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }

    Component {
        id: messagePanelComponent

        Item {
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   _messagePanelText
            }
        }
    }

    QGCFlickable {
        id:                 buttonScroll
        width:              buttonColumn.width
        anchors.topMargin:  _defaultTextHeight / 2
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _horizontalMargin
        anchors.left:       parent.left
        contentHeight:      buttonColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        ColumnLayout {
            id:         buttonColumn
            spacing:    /*_defaultTextHeight / 2*/ 0

            Repeater {
                model:                  _corePlugin ? _corePlugin.settingsPages : []
                visible:                _corePlugin && _corePlugin.options.combineSettingsAndSetup
                SubMenuButton {
                    imageResource:      modelData.icon
                    setupIndicator:     false
                    exclusiveGroup:     setupButtonGroup
                    text:               modelData.title
                    visible:            _corePlugin && _corePlugin.options.combineSettingsAndSetup
                    onClicked:          showPanel(this, modelData.url)
                    Layout.fillWidth:   true
                }
            }

            SubMenuButton {
                id:                 summaryButton
                imageResource:      "/qmlimages/VehicleSummaryIcon.png"
                setupIndicator:     false
                checked:            true
                exclusiveGroup:     setupButtonGroup
                text:               qsTr("Summary")
                Layout.fillWidth:   true

                onClicked: showSummaryPanel()
            }

            SubMenuButton {
                id:                 firmwareButton
                imageResource:      "/qmlimages/FirmwareUpgradeIcon.png"
                setupIndicator:     false
                exclusiveGroup:     setupButtonGroup
                visible:            !ScreenTools.isMobile && _corePlugin.options.showFirmwareUpgrade
                text:               qsTr("Firmware")
                Layout.fillWidth:   true

                onClicked: showPanel(this, "FirmwareUpgrade.qml")
            }

            SubMenuButton {
                id:                 px4FlowButton
                exclusiveGroup:     setupButtonGroup
                visible:            QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.vehicleLinkManager.primaryLinkIsPX4Flow : false
                setupIndicator:     false
                text:               qsTr("PX4Flow")
                Layout.fillWidth:   true
                onClicked:          showPanel(this, "PX4FlowSensor.qml")
            }

            SubMenuButton {
                id:                 joystickButton
                imageResource:      "/qmlimages/Joystick.png"
                setupIndicator:     true
                setupComplete:      _activeJoystick ? _activeJoystick.calibrated || _buttonsOnly : false
                exclusiveGroup:     setupButtonGroup
                visible:            _fullParameterVehicleAvailable && joystickManager.joysticks.length !== 0
                text:               _forcedToButtonsOnly ? qsTr("Buttons") : qsTr("Joystick")
                Layout.fillWidth:   true
                onClicked:          showPanel(this, "JoystickConfig.qml")

                property var    _activeJoystick:        joystickManager.activeJoystick
                property bool   _buttonsOnly:           _activeJoystick ? _activeJoystick.axisCount === 0 : false
                property bool   _forcedToButtonsOnly:   !QGroundControl.corePlugin.options.allowJoystickSelection && _buttonsOnly
            }

            Repeater {
                id:     componentRepeater
                model:  _fullParameterVehicleAvailable ? QGroundControl.multiVehicleManager.activeVehicle.autopilot.vehicleComponents : 0

                SubMenuButton {
                    imageResource:      modelData.iconResource
                    setupIndicator:     modelData.requiresSetup
                    setupComplete:      modelData.setupComplete
                    exclusiveGroup:     setupButtonGroup
                    text:               modelData.name
                    visible:            modelData.setupSource.toString() !== ""
                    Layout.fillWidth:   true
                    onClicked:          showVehicleComponentPanel(modelData)
                }
            }

            SubMenuButton {
                id:                 parametersButton
                setupIndicator:     false
                exclusiveGroup:     setupButtonGroup
                visible:            QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable &&
                                    !QGroundControl.multiVehicleManager.activeVehicle.usingHighLatencyLink &&
                                    _corePlugin.showAdvancedUI
                text:               qsTr("Parameters")
                Layout.fillWidth:   true
                onClicked: {
                    checked = true
                    passwordDialog.visible = true
                }
            }

        }
    }

    Rectangle {
        id:                     divider
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.leftMargin:     _horizontalMargin
        anchors.left:           buttonScroll.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        width:                  1
        color:                  qgcPal.windowShade
    }

    Loader {
        id:                     panelLoader
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.leftMargin:     _horizontalMargin
        anchors.rightMargin:    _horizontalMargin
        anchors.left:           divider.right
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom

        function setSource(source, vehicleComponent) {
            panelLoader.source = ""
            panelLoader.vehicleComponent = vehicleComponent
            panelLoader.source = source
        }

        function setSourceComponent(sourceComponent, vehicleComponent) {
            panelLoader.sourceComponent = undefined
            panelLoader.vehicleComponent = vehicleComponent
            panelLoader.sourceComponent = sourceComponent
        }

        property var vehicleComponent
    }

    Rectangle {
        id: passwordDialog
        anchors.fill: parent
        visible: false
        color: "#88000000"
        z: 9999

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: dialogBox
            anchors.centerIn: parent
            width: Math.max(ScreenTools.defaultFontPixelWidth * 30, dialogColumn.implicitWidth + ScreenTools.defaultFontPixelWidth * 2)
            height: dialogColumn.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
            radius: ScreenTools.defaultFontPixelWidth
            color: qgcPal.window

            ColumnLayout {
                id: dialogColumn
                anchors.centerIn: parent
                width: parent.width - ScreenTools.defaultFontPixelWidth * 2
                spacing: ScreenTools.defaultFontPixelHeight / 2

                QGCLabel {
                    text: qsTr("Enter Password")
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize + 2
                    Layout.alignment: Qt.AlignHCenter
                }

                QGCTextField {
                    id: passwordField
                    echoMode: TextInput.Password
                    placeholderText: qsTr("Password")
                    Layout.fillWidth: true
                }

                QGCLabel {
                    id: passwordError
                    color: "red"
                    visible: false
                    text: qsTr("Incorrect password")
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCButton {
                        text: qsTr("Cancel")
                        onClicked: {
                            passwordField.text = ""
                            passwordError.visible = false
                            passwordDialog.visible = false
                        }
                    }

                    QGCButton {
                        text: qsTr("OK")
                        onClicked: {
                            if (passwordField.text === _parameterPassword) {
                                passwordField.text = ""
                                passwordError.visible = false
                                passwordDialog.visible = false
                                panelLoader.setSource("SetupParameterEditor.qml")
                            } else {
                                passwordError.visible = true
                            }
                        }
                    }
                }
            }
        }
    }
}
