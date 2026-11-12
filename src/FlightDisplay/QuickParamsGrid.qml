/****************************************************************************
 *
 * Quick Params Grid — 4x4 cards, Mission Planner style
 * Add/Edit via a single flat list of all available facts (right-click or click tile).
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
    id:                 quickParamsGrid
    color:              "#1a1a1a"
    radius:             2
    border.color:       "#ffffff"
    border.width:       1

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property int refreshTick: 0
    property int editIndex: -1
    property int targetIndex: -1
    property int activeTab: 0
    property int _pendingActionIndex: -1

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: refreshTick++
    }

    ListModel { id: paramsModel }

    Component.onCompleted: {
        _resetDefaults()
        _refreshOverrideDefaults()
    }

    on_ActiveVehicleChanged: _refreshOverrideDefaults()
    onActiveTabChanged: {
        if (activeTab === 1) _refreshOverrideDefaults()
    }

    Connections {
        target: quickParamsGrid._activeVehicle ? quickParamsGrid._activeVehicle.parameterManager : null
        onParametersReadyChanged: quickParamsGrid._refreshOverrideDefaults()
    }

    function _getFactGroup(grp) {
        if (!_activeVehicle) return null
        if (grp === "vehicle") return _activeVehicle
        try {
            var names = _activeVehicle.factGroupNames
            if (names.indexOf(grp) < 0) return null
            return _activeVehicle.getFactGroup(grp)
        } catch(e) { return null }
    }

    function _getVal(grp, name) {
        if (!_activeVehicle) return "—"
        if (grp === "empty") return "—"
        try {
            var g = _getFactGroup(grp)
            if (!g) return "—"
            if (g.factNames.indexOf(name) < 0) return "—"
            var fact = g.getFact(name)
            if (fact) {
                var v = fact.rawValue
                if (name === "flightTime") return _fmtTime(v)
                return _fmt(v)
            }
        } catch(e) {}
        return "—"
    }

    function _fmt(v) {
        if (v === "—" || v === undefined || v === null) return "—"
        if (typeof v === "number") return v.toFixed(1)
        return String(v)
    }

    function _fmtTime(s) {
        if (s === "—" || s === undefined || s === null) return "—"
        var total = Math.floor(s)
        var h = Math.floor(total / 3600)
        var m = Math.floor((total % 3600) / 60)
        var sec = total % 60
        var pad = function(n) { return (n < 10 ? "0" : "") + n }
        return pad(h) + "." + pad(m) + "." + pad(sec)
    }

    // Right-click anywhere opens the parameter picker
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                targetIndex = -1
                factPickerDialog.open()
            }
        }
    }

    // Tab bar (tab style) - wrapped so border stays visible
    Rectangle {
        id: tabBarContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: ScreenTools.defaultFontPixelWidth / 4
        height: tabBar.implicitHeight + 4
        color: "#1a1a1a"
        border.color: "white"
        border.width: 1
        radius: 2
        clip: true

        TabBar {
            id: tabBar
            anchors.fill: parent
            anchors.margins: 1
            background: Rectangle { color: "#1a1a1a" }

            palette.buttonText: "#ffffff"
            palette.text: "#ffffff"
            palette.highlightedText: "#ffffff"
            palette.window: "#1a1a1a"
            palette.highlight: "#555555"

            TabButton {
                text: qsTr("Quick")
                width: tabBarContainer.width / 2
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            TabButton {
                text: qsTr("Action")
                width: tabBarContainer.width / 2
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Binding {
                target: tabBar
                property: "currentIndex"
                value: activeTab
            }
        }
    }

    // sync activeTab with TabBar currentIndex
    Connections {
        target: tabBar
        onCurrentIndexChanged: activeTab = tabBar.currentIndex
    }

    // Grid
    Flickable {
        id: flick
        anchors.top: tabBarContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: addRowBtn.top
        anchors.margins: ScreenTools.defaultFontPixelWidth / 4
        anchors.bottomMargin: ScreenTools.defaultFontPixelWidth / 4
        contentWidth: width
        contentHeight: Math.max(grid.height, flick.height)
        clip: true
        visible: activeTab === 0

        Column {
            id: col
            width: flick.width
            spacing: ScreenTools.defaultFontPixelWidth / 4

            Grid {
                id: grid
                width: parent.width
                columns: 4
                rowSpacing: gap
                columnSpacing: gap

                property real gap:   ScreenTools.defaultFontPixelWidth / 4
                property real cellW: (width - 3 * gap) / 4
                property real cellH: (flick.height - 3 * gap) / 4

            Repeater {
                model: paramsModel

                Rectangle {
                    width: grid.cellW
                    height: grid.cellH
                    color: model.grp === "empty" ? "#1f1f1f" : "#2a2a2a"
                    radius: 2
                    border.color: model.grp === "empty" ? "#444444" : "#555555"
                    border.width: 1

                    property int _idx: index
                    property string _label: model.label
                    property string _grp: model.grp
                    property string _name: model.name

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        QGCLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: _label
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.6
                            font.pointSize: -1
                            font.bold: true
                            color: "#aaaaaa"
                        }

                        QGCLabel {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                var _ = refreshTick
                                if (model.grp === "empty") return "—"
                                if (model.label === "HORIZ DIST") {
                                    var alt = _activeVehicle && _activeVehicle.altitudeRelative ? _activeVehicle.altitudeRelative.rawValue : 0
                                    if (alt > 0) return (3.57 * Math.sqrt(alt) * 1000).toFixed(2)
                                    return "—"
                                }
                                if (model.label === "AOA") {
                                    if (_activeVehicle && _activeVehicle.aoa) return _fmt(_activeVehicle.aoa.rawValue)
                                    if (_activeVehicle && _activeVehicle.pitch && _activeVehicle.airSpeed && _activeVehicle.airSpeed.rawValue > 0) {
                                        return (_activeVehicle.pitch.rawValue - Math.atan2((_activeVehicle.climbRate ? _activeVehicle.climbRate.rawValue : 0), _activeVehicle.airSpeed.rawValue) * 180 / Math.PI).toFixed(1)
                                    }
                                    return "—"
                                }
                                var v = quickParamsGrid._getVal(_grp, _name)
                                return v
                            }
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.8
                            font.pointSize: -1
                            font.bold: true
                            font.family: ScreenTools.fixedFontFamily
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            quickParamsGrid.targetIndex = _idx
                            factPickerDialog.open()
                        }
                    }
                }
            }
        }
    }
    }

    // ---- In-flight overrides (Mission Planner Actions tab parity) -----------
    function _refreshOverrideDefaults() {
        changeAltField.text = "100"
        if (!_activeVehicle) {
            changeSpeedField.text = ""
            loiterRadiusField.text = ""
            return
        }

        var speed = _activeVehicle.defaultChangeSpeedMetersSecond()
        changeSpeedField.text = isNaN(speed)
                ? ""
                : QGroundControl.unitsConversion.metersSecondToAppSettingsSpeedUnits(speed).toFixed(1)

        var radius = _activeVehicle.loiterRadiusMeters()
        loiterRadiusField.text = isNaN(radius)
                ? ""
                : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(radius).toFixed(0)
    }

    // ---- Action tab helpers -------------------------------------------------
    function _actionLabel(index) {
        switch (index) {
        case 0: return qsTr("Preflight Reboot")
        case 1: return qsTr("Mission Start")
        case 2: return qsTr("Loiter Unlimited")
        case 3: return qsTr("Do Parachute")
        case 4: return qsTr("Scripting On")
        case 5: return qsTr("Scripting Off")
        case 6: return qsTr("Change Alt")
        case 7: return qsTr("Change Speed")
        case 8: return qsTr("Set Loiter Rad")
        }
        return qsTr("Action")
    }

    function _actionWarning(index) {
        var units = QGroundControl.unitsConversion
        switch (index) {
        case 0: return qsTr("The vehicle will reboot and the link will drop briefly.")
        case 1: return qsTr("The vehicle will start the loaded mission.")
        case 2: return qsTr("The vehicle will loiter at the current location indefinitely.")
        case 3: return qsTr("The parachute will be deployed. Use only in an emergency.")
        case 4: return qsTr("Scripting will be enabled on the vehicle.")
        case 5: return qsTr("Scripting will be disabled on the vehicle.")
        case 6: return qsTr("Change the target altitude to %1 %2 above home. The flight mode will not be changed.")
                       .arg(changeAltField.text).arg(units.appSettingsVerticalDistanceUnitsString)
        case 7: return qsTr("Change the target airspeed to %1 %2. The flight mode will not be changed.")
                       .arg(changeSpeedField.text).arg(units.appSettingsSpeedUnitsString)
        case 8: return qsTr("Set the loiter radius to %1 %2. Negative values mean counter-clockwise.")
                       .arg(loiterRadiusField.text).arg(units.appSettingsHorizontalDistanceUnitsString)
        }
        return ""
    }

    function _executeAction(index) {
        if (!_activeVehicle) return
        switch (index) {
        case 0: _activeVehicle.rebootVehicle(); break
        case 1: _activeVehicle.startMission(); break
        case 2: _activeVehicle.sendCommand(_activeVehicle.defaultComponentId(), 17, true); break
        case 3: _activeVehicle.sendCommand(_activeVehicle.defaultComponentId(), 208, true, 2); break
        case 4: _activeVehicle.sendParameter("SCR_ENABLE", 1); break
        case 5: _activeVehicle.sendParameter("SCR_ENABLE", 0); break
        case 6: {
            var alt = QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsToMeters(Number(changeAltField.text))
            if (!isNaN(alt)) _activeVehicle.guidedModeChangeAltitudeTo(alt)
            break
        }
        case 7: {
            var speed = QGroundControl.unitsConversion.appSettingsSpeedUnitsToMetersSecond(Number(changeSpeedField.text))
            if (!isNaN(speed)) _activeVehicle.guidedModeChangeEquivalentAirspeedMetersSecond(speed)
            break
        }
        case 8: {
            var radius = QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsToMeters(Number(loiterRadiusField.text))
            if (!isNaN(radius)) _activeVehicle.setLoiterRadiusMeters(radius)
            break
        }
        }
    }

    // Action tab panel (Mission Planner style: quick actions + in-flight overrides)
    Flickable {
        id: actionFlick
        anchors.top: tabBarContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: ScreenTools.defaultFontPixelWidth / 4
        contentWidth: width
        contentHeight: actionColumn.height
        clip: true
        visible: activeTab === 1

        ColumnLayout {
            id: actionColumn
            width: actionFlick.width
            spacing: ScreenTools.defaultFontPixelWidth / 2

            ComboBox {
                id: actionCombo
                Layout.fillWidth: true
                model: [
                    qsTr("Preflight Reboot"),
                    qsTr("Mission Start"),
                    qsTr("Loiter Unlimited"),
                    qsTr("Do Parachute"),
                    qsTr("Scripting On"),
                    qsTr("Scripting Off")
                ]
                palette.buttonText: "#ffffff"
                palette.text: "#ffffff"
                palette.window: "#1a1a1a"
                palette.highlight: "#555555"

                delegate: ItemDelegate {
                    width: actionCombo.width
                    text: modelData
                    hoverEnabled: true
                    contentItem: Text {
                        text: modelData
                        color: "#ffffff"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: ScreenTools.defaultFontPixelWidth
                    }
                    background: Rectangle {
                        color: (highlighted || hovered) ? "#333333" : "#1a1a1a"
                    }
                }

                background: Rectangle {
                    color: "#2a2a2a"
                    border.color: "#555555"
                    border.width: 1
                    radius: 4
                }
                contentItem: Text {
                    text: actionCombo.displayText
                    color: "#ffffff"
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: ScreenTools.defaultFontPixelWidth
                }
                popup: Popup {
                    width: actionCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 1
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: actionCombo.popup.visible ? actionCombo.delegateModel : null
                        currentIndex: actionCombo.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }
                    background: Rectangle {
                        color: "#1a1a1a"
                        border.color: "#555555"
                        border.width: 1
                    }
                }
            }

            QGCButton {
                Layout.fillWidth: true
                height: ScreenTools.defaultFontPixelHeight * 2.5
                text: qsTr("Do Action")
                onClicked: {
                    if (!_activeVehicle) return
                    if (actionCombo.currentIndex < 0) return
                    _pendingActionIndex = actionCombo.currentIndex
                    actionConfirmDialog.open()
                }
                background: Rectangle {
                    color: parent.pressed ? "#3a3a3a" : (parent.hovered ? "#333333" : "#2a2a2a")
                    border.color: "#555555"
                    border.width: 1
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: ScreenTools.defaultFontPointSize
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: ScreenTools.defaultFontPixelHeight / 4
                height: 1
                color: "#555555"
            }

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("In-flight Overrides")
                color: "#cccccc"
                font.bold: true
                font.pointSize: ScreenTools.defaultFontPointSize
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth / 2

                QGCLabel {
                    Layout.preferredWidth: actionColumn.width * 0.38
                    text: qsTr("Altitude (%1)").arg(QGroundControl.unitsConversion.appSettingsVerticalDistanceUnitsString)
                    color: "#ffffff"
                    elide: Text.ElideRight
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                }

                TextField {
                    id: changeAltField
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    text: "100"
                    color: "#ffffff"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    horizontalAlignment: TextInput.AlignRight
                    selectByMouse: true
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {
                        bottom: 0
                        top: 10000
                        decimals: 1
                        notation: DoubleValidator.StandardNotation
                    }
                    background: Rectangle {
                        color: "#2a2a2a"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                    }
                }

                QGCButton {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                    Layout.preferredHeight: changeAltField.height
                    text: qsTr("Set")
                    enabled: _activeVehicle !== null && changeAltField.acceptableInput
                    onClicked: {
                        if (!_activeVehicle) return
                        _pendingActionIndex = 6
                        actionConfirmDialog.open()
                    }
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#800000" : (parent.hovered ? "#4d0000" : "#2a2a2a")) : "#141414"
                        border.color: parent.enabled ? "#ffffff" : "#555555"
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#777777"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth / 2

                QGCLabel {
                    Layout.preferredWidth: actionColumn.width * 0.38
                    text: qsTr("Speed (%1)").arg(QGroundControl.unitsConversion.appSettingsSpeedUnitsString)
                    color: "#ffffff"
                    elide: Text.ElideRight
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                }

                TextField {
                    id: changeSpeedField
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    color: "#ffffff"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    horizontalAlignment: TextInput.AlignRight
                    selectByMouse: true
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {
                        bottom: 0
                        top: 1000
                        decimals: 1
                        notation: DoubleValidator.StandardNotation
                    }
                    background: Rectangle {
                        color: "#2a2a2a"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                    }
                }

                QGCButton {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                    Layout.preferredHeight: changeSpeedField.height
                    text: qsTr("Set")
                    enabled: _activeVehicle !== null && changeSpeedField.acceptableInput
                    onClicked: {
                        if (!_activeVehicle) return
                        _pendingActionIndex = 7
                        actionConfirmDialog.open()
                    }
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#800000" : (parent.hovered ? "#4d0000" : "#2a2a2a")) : "#141414"
                        border.color: parent.enabled ? "#ffffff" : "#555555"
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#777777"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth / 2

                QGCLabel {
                    Layout.preferredWidth: actionColumn.width * 0.38
                    text: qsTr("Loiter Rad (%1)").arg(QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString)
                    color: "#ffffff"
                    elide: Text.ElideRight
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                }

                TextField {
                    id: loiterRadiusField
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    color: "#ffffff"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    horizontalAlignment: TextInput.AlignRight
                    selectByMouse: true
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: DoubleValidator {
                        bottom: -10000
                        top: 10000
                        decimals: 0
                        notation: DoubleValidator.StandardNotation
                    }
                    background: Rectangle {
                        color: "#2a2a2a"
                        border.color: "#555555"
                        border.width: 1
                        radius: 4
                    }
                }

                QGCButton {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                    Layout.preferredHeight: loiterRadiusField.height
                    text: qsTr("Set")
                    enabled: _activeVehicle !== null && loiterRadiusField.acceptableInput
                    onClicked: {
                        if (!_activeVehicle) return
                        _pendingActionIndex = 8
                        actionConfirmDialog.open()
                    }
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#800000" : (parent.hovered ? "#4d0000" : "#2a2a2a")) : "#141414"
                        border.color: parent.enabled ? "#ffffff" : "#555555"
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#ffffff" : "#777777"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }
            }
        }
    }

    // Generic action confirmation dialog
    Dialog {
        id: actionConfirmDialog
        title: qsTr("Confirm Action")
        modal: true
        width: ScreenTools.defaultFontPixelWidth * 40
        height: ScreenTools.defaultFontPixelHeight * 15
        parent: Overlay.overlay
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0

        // Rebooting is not allowed while armed; show the reason instead of
        // silently doing nothing.
        property bool rebootBlocked: _pendingActionIndex === 0
                                      && _activeVehicle
                                      && _activeVehicle.armed

        // Reboot and parachute are destructive: require a longer hold.
        property bool dangerousAction: _pendingActionIndex === 0 || _pendingActionIndex === 3
        property int holdDurationMs: dangerousAction ? 2500 : 1500

        onClosed: {
            holdButton.holdCompleted = false
            holdButton.holdProgress = 0
        }

        // Maroon title bar, white text
        header: Label {
            text: actionConfirmDialog.title
            color: "#ffffff"
            font.bold: true
            font.pointSize: ScreenTools.defaultFontPointSize
            padding: ScreenTools.defaultFontPixelHeight * 0.5

            background: Rectangle {
                color: "#800000"
            }
        }

        background: Rectangle {
            color: "#0d0d0d"
            border.color: "#ffffff"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth
            spacing: ScreenTools.defaultFontPixelHeight

            QGCLabel {
                Layout.fillWidth: true
                text: qsTr("Execute \"%1\"?").arg(_actionLabel(_pendingActionIndex))
                color: "#ffffff"
                font.bold: true
                wrapMode: Text.WordWrap
            }

            QGCLabel {
                Layout.fillWidth: true
                text: actionConfirmDialog.rebootBlocked
                      ? qsTr("Vehicle is armed. Disarm before rebooting.")
                      : _actionWarning(_pendingActionIndex)
                color: actionConfirmDialog.rebootBlocked ? "#ffb3b3" : "#e6e6e6"
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                QGCButton {
                    Layout.fillWidth: true
                    text: qsTr("Cancel")
                    onClicked: actionConfirmDialog.close()
                    background: Rectangle {
                        color: parent.pressed ? "#800000" : (parent.hovered ? "#4d0000" : "#0d0d0d")
                        border.color: "#ffffff"
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }
                QGCButton {
                    id: holdButton
                    Layout.fillWidth: true
                    enabled: !actionConfirmDialog.rebootBlocked
                    text: holdButton.holdCompleted
                          ? qsTr("Executing…")
                          : (holdButton.pressed
                             ? qsTr("Keep holding… %1s").arg(((holdButton.holdDurationMs * (1 - holdButton.holdProgress)) / 1000).toFixed(1))
                             : qsTr("Hold to Execute"))

                    property bool holdCompleted: false
                    property real holdProgress: 0
                    property int holdDurationMs: actionConfirmDialog.holdDurationMs

                    onPressedChanged: {
                        if (pressed) {
                            holdCompleted = false
                            holdProgress = 0
                        } else if (!holdCompleted) {
                            // Released too early: snap back to the start.
                            holdProgress = 0
                        }
                    }

                    Timer {
                        id: holdTimer
                        interval: 16
                        repeat: true
                        running: holdButton.pressed
                                 && !holdButton.holdCompleted
                                 && actionConfirmDialog.visible
                        onTriggered: {
                            holdButton.holdProgress += interval / holdButton.holdDurationMs
                            if (holdButton.holdProgress >= 1.0) {
                                holdButton.holdProgress = 1.0
                                stop()
                                holdButton.holdCompleted = true
                                _executeAction(_pendingActionIndex)
                                closeTimer.restart()
                            }
                        }
                    }

                    Timer {
                        id: closeTimer
                        interval: 300
                        repeat: false
                        onTriggered: actionConfirmDialog.close()
                    }

                    background: Rectangle {
                        color: holdButton.enabled ? "#0d0d0d" : "#141414"
                        border.color: holdButton.enabled ? "#ffffff" : "#555555"
                        border.width: 1
                        radius: 4
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * holdButton.holdProgress
                            color: actionConfirmDialog.dangerousAction ? "#b3001b" : "#800000"
                        }
                    }
                    contentItem: Text {
                        text: holdButton.text
                        color: holdButton.enabled ? "#ffffff" : "#777777"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }
            }
        }
    }

    // Add row button (always visible at bottom of panel)
    QGCButton {
        id: addRowBtn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: ScreenTools.defaultFontPixelWidth / 4
        height: ScreenTools.defaultFontPixelHeight * 2
        visible: activeTab === 0
        text: qsTr("Add row (4 empty)")
        onClicked: _addRow()
        background: Rectangle {
            color: "#2a2a2a"
            border.color: "#555555"
            border.width: 1
            radius: 4
        }
        contentItem: Text {
            text: parent.text
            color: "#ffffff"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Large parameter picker dialog (Mission Planner style): flat list of all facts with checkboxes
    Dialog {
        id: factPickerDialog
        modal: true
        parent: Overlay.overlay
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0
        width:  Overlay.overlay ? Math.min(Math.round(Overlay.overlay.width * 0.8), 1200) : 900
        height: Overlay.overlay ? Math.min(Math.round(Overlay.overlay.height * 0.8), 850) : 650

        background: Rectangle {
            color:        "#1a1a1a"
            border.color: "#555555"
            border.width: 1
        }

        onOpened: {
            _buildFactList()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth

            QGCLabel {
                text: qsTr("Select Parameters")
                font.bold: true
                color: "#ffffff"
            }

            GridView {
                id: factGridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: factFilterModel
                cellWidth:  Math.floor(width / 4)
                cellHeight: ScreenTools.defaultFontPixelHeight * 2.3

                delegate: Item {
                    width: factGridView.cellWidth
                    height: factGridView.cellHeight
                    clip: true

                    QGCCheckBox {
                        id: cb
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: model.label
                        textColor: "#ffffff"
                        textFontPointSize: ScreenTools.defaultFontPointSize
                        onClicked: {
                            var wantChecked = quickParamsGrid._hasParam(model.grp, model.name) < 0
                            quickParamsGrid._toggleParam(model.grp, model.name, wantChecked)
                        }

                        Binding {
                            target: cb
                            property: "checked"
                            value: quickParamsGrid._hasParam(model.grp, model.name) >= 0
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                QGCLabel {
                    Layout.fillWidth: true
                    text: qsTr("Check a parameter to show it in the Quick grid.")
                    color: "#cccccc"
                }
                QGCButton {
                    text: qsTr("Reset to defaults")
                    onClicked: {
                        _resetDefaults()
                        _buildFactList()
                    }
                }
                QGCButton {
                    text: qsTr("Close")
                    onClicked: factPickerDialog.close()
                }
            }
        }
    }

    // Flat list models used by the picker
    ListModel { id: factListModel }
    ListModel { id: factFilterModel }

    function _buildFactList() {
        var entries = []
        if (!_activeVehicle) {
            _updateFilter()
            return
        }
        // Vehicle-level facts
        try {
            var vNames = _activeVehicle.factNames
            for (var vi = 0; vi < vNames.length; vi++) {
                entries.push({ grp: "vehicle", name: vNames[vi], label: "vehicle." + vNames[vi] })
            }
        } catch(e) {}
        // Child fact groups
        try {
            var groups = _activeVehicle.factGroupNames
            for (var gi = 0; gi < groups.length; gi++) {
                var grp = groups[gi]
                try {
                    var g = _activeVehicle.getFactGroup(grp)
                    if (!g) continue
                    var names = g.factNames
                    for (var ni = 0; ni < names.length; ni++) {
                        entries.push({ grp: grp, name: names[ni], label: grp + "." + names[ni] })
                    }
                } catch(e) {}
            }
        } catch(e) {}
        // Sort alphabetically by label
        entries.sort(function(a, b) {
            var la = String(a.label).toLowerCase()
            var lb = String(b.label).toLowerCase()
            if (la < lb) return -1
            if (la > lb) return 1
            return 0
        })
        factListModel.clear()
        factFilterModel.clear()
        for (var ei = 0; ei < entries.length; ei++) {
            factListModel.append(entries[ei])
        }
        _updateFilter()
    }

    function _updateFilter() {
        factFilterModel.clear()
        for (var i = 0; i < factListModel.count; i++) {
            factFilterModel.append(factListModel.get(i))
        }
    }

    function _hasParam(grp, name) {
        for (var i = 0; i < paramsModel.count; i++) {
            var it = paramsModel.get(i)
            if (it.grp === grp && it.name === name) return i
        }
        return -1
    }

    function _toggleParam(grp, name, isChecked) {
        var idx = _hasParam(grp, name)
        if (isChecked) {
            if (targetIndex >= 0 && targetIndex < paramsModel.count) {
                if (idx === targetIndex) {
                    // Already at the clicked place
                } else if (idx >= 0) {
                    // Move the selected parameter into the clicked tile (swap with what was there)
                    var oldTarget = paramsModel.get(targetIndex)
                    var selected = paramsModel.get(idx)
                    paramsModel.set(targetIndex, { label: selected.label, grp: selected.grp, name: selected.name })
                    paramsModel.set(idx, { label: oldTarget.label, grp: oldTarget.grp, name: oldTarget.name })
                } else {
                    // Put the newly selected parameter into the clicked tile
                    paramsModel.set(targetIndex, { label: name.toUpperCase(), grp: grp, name: name })
                }
            } else if (idx < 0) {
                paramsModel.append({ label: name.toUpperCase(), grp: grp, name: name })
            }
            targetIndex = -1
        } else {
            if (idx >= 0) paramsModel.remove(idx)
            if (targetIndex === idx) {
                targetIndex = -1
            } else if (targetIndex > idx) {
                targetIndex--
            }
        }
    }

    function _addRow() {
        for (var i = 0; i < 4; i++) paramsModel.append({ label: "+", grp: "empty", name: "" })
    }

    function _resetDefaults() {
        targetIndex = -1
        if (paramsModel.count > 0) paramsModel.clear()
        var defaults = [
            { label: "ROLL",       grp: "vehicle",  name: "roll" },
            { label: "PITCH",      grp: "vehicle",  name: "pitch" },
            { label: "YAW",        grp: "vehicle",  name: "heading" },
            { label: "TIME AIR",   grp: "vehicle",  name: "flightTime" },
            { label: "DIST TRV",   grp: "vehicle",  name: "flightDistance" },
            { label: "DIST HOME",  grp: "vehicle",  name: "distanceToHome" },
            { label: "ALT",        grp: "vehicle",  name: "altitudeRelative" },
            { label: "DIST WP",    grp: "vehicle",  name: "distanceToNextWP" },
            { label: "BAT USED",   grp: "battery",  name: "mahConsumed" },
            { label: "BAT CURR",   grp: "battery",  name: "current" },
            { label: "WIND VEL",   grp: "wind",     name: "speed" },
            { label: "CLIMB",      grp: "vehicle",  name: "climbRate" },
            { label: "BAT REM",    grp: "battery",  name: "percentRemaining" },
            { label: "CH3 %",      grp: "vehicle",  name: "rcChannel3Percent" },
            { label: "HORIZ DIST", grp: "computed", name: "horizonDist" },
            { label: "AOA",        grp: "vehicle",  name: "aoa" }
        ]
        for (var i = 0; i < defaults.length; i++) paramsModel.append(defaults[i])
    }
}
