import QtQuick                  2.12
import QtQuick.Controls         2.5
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12
import QtQml            2.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QtGraphicalEffects 1.0

import QGroundControl               1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0


Item {
    id: root

    width:  parent ? parent.width : 200
    height: parent ? parent.height : 200

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool isParamVisible : true

    property var factValueGrid

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    function getFactSafe(factName) {
        let v = QGroundControl.multiVehicleManager.activeVehicle;
        if (!v) return null;

        // Handle battery facts specially
        if (factName.startsWith("battery[")) {
            let match = factName.match(/battery\[(\d+)\]\.(.+)/);
            if (match && v.batteries) {
                let index = parseInt(match[1]);
                let propName = match[2];
                if (index >= 0 && index < v.batteries.count) {
                    let batt = v.batteries.get(index);
                    if (batt && batt[propName] !== undefined) {
                        return batt[propName];
                    }
                }
            }
            return null;
        }

        let f = v.getFact(factName);
        if (!f || f.name === "" || f.value === undefined)
            return null;

        return f;
    }

    property var displayedFacts: [
        "altitudeRelative",
        "distanceToHome",
        "flightTime",
        "battery[0].voltage",
        "groundSpeed",
        "distanceToNextWP",
        "flightDistance",
        "roll",
        "pitch",
        "heading",
        "climbRate",
    ]

    function getAllFacts() {

        console.log("VEHICLE KEYS:", Object.keys(_activeVehicle))

        let result = []

        if (!_activeVehicle) {
            console.log("No active vehicle")
            return result
        }

        // Top-level Facts
        for (let key in _activeVehicle) {
            let fact = _activeVehicle[key]

            if (fact && fact.value !== undefined && fact.name !== undefined) {
                // This is a Fact
                result.push({
                    group: "Vehicle",
                    name: fact.name,
                    fullName: fact.name
                })
            }
        }

        // FactGroups
        const groups = [
            "batteries", "gps", "gps2", "wind", "vibration", "temperature",
            "localPosition", "localPositionSetpoint", "escStatus",
            "estimatorStatus", "battery", "clock", "efi", "terrain",
            "distanceSensor", "setpoint", "hygrometer", "generator"
        ]

        groups.forEach(g => {
            let groupObj = _activeVehicle[g]
            if (!groupObj) return

            for (let key in groupObj) {
                let fact = groupObj[key]
                if (fact && fact.value !== undefined) {
                    result.push({
                        group: g,
                        name: fact.name,
                        fullName: g + "." + fact.name
                    })
                }
            }
        })

        // BATTERIES
        if (_activeVehicle.batteries) {
            let list = _activeVehicle.batteries

            for (let i = 0; i < list.count; i++) {
                let batt = list.get(i)

                for (let key in batt) {
                    let fact = batt[key]

                    // ✔ Detect Fact objects correctly
                    if (fact && fact.name !== undefined && fact.value !== undefined) {
                        result.push({
                            group: "battery[" + i + "]",
                            name: fact.name,
                            fullName: "battery[" + i + "]." + fact.name
                        })
                    }
                }
            }
        }


        for (let prop in _activeVehicle) {
            if (prop.startsWith("distanceSensor")) {
                let groupObj = _activeVehicle[prop]
                for (let key in groupObj) {
                    let fact = groupObj[key]
                    if (fact && fact.value !== undefined) {
                        result.push({
                            group: prop,
                            name: fact.name,
                            fullName: prop + "." + fact.name
                        })
                    }
                }
            }
        }

        //console.log("FACT LIST:", JSON.stringify(result))
        return result
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true
            height: topLayout.height + (ScreenTools.isMobile ? 10 : 0)
            color: "transparent"

            RowLayout {
                id: topLayout
                anchors.horizontalCenter: parent.horizontalCenter

                QGCLabel {
                    text: "TELEMETRY"
                    font.pointSize: ScreenTools.isMobile ? 6 : 10
                    Layout.alignment: Qt.AlignLeft
                    Layout.leftMargin: ScreenTools.defaultFontPixelWidth / 3
                    font.bold: true
                    color: qgcPal.buttonText
                }

                Item { Layout.fillWidth: true }


                Rectangle {
                    Layout.alignment: Qt.AlignRight
                    width: ScreenTools.isMobile ? 60 : 38
                    height: ScreenTools.isMobile ? 60 : 38
                    color: "transparent"

                    QGCColoredImage {
                        width: parent.width * 0.7
                        height: parent.height * 0.7
                        anchors.centerIn: parent
                        source: "/res/edit"
                        color: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue ? "#aaffffff" : "#aa000000"

                        MouseArea {
                            enabled: _activeVehicle
                            anchors.fill: parent
                            onClicked: {
                                popupDialog.open()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
        }

        Flickable {
            id:             flick
            //anchors.fill:   parent
            clip:           true
            Layout.fillHeight: true
            Layout.fillWidth: true
            contentWidth:   width
            contentHeight:  grid.implicitHeight
            visible: isParamVisible
            //anchors.margins: 2

            GridLayout {
                id:             grid
                width:          flick.width
                rows:           0
                columns:        ScreenTools.isMobile ? 2 : 2
                rowSpacing:     -1
                columnSpacing:  -1

                Repeater {
                    model: root.displayedFacts.length

                    FactDisplayItem {
                        id:                 factItem
                        Layout.fillWidth:   true
                        Layout.fillHeight:  true
                        fact:               getFactSafe(displayedFacts[index])
                        onOpenIconList: {
                            iconPopup.open()
                        }
                    }
                }

                // QGCButton {
                //     iconSource:         "/res/addParam_icon"
                //     Layout.fillWidth:   true
                //     Layout.fillHeight:  true

                //     contentItem: Item {
                //         anchors.fill: parent

                //         Image {
                //             source:             "/res/addParam_icon"
                //             anchors.centerIn:   parent
                //             width:              parent.width * 0.6
                //             height:             parent.height * 0.6
                //             fillMode:           Image.PreserveAspectFit
                //         }
                //     }

                //     onClicked: {
                //         popupDialog.loadFactGroups()
                //         if (popupDialog.factGroups.length > 0) {
                //             popupDialog.selectedGroup = popupDialog.factGroups[0]
                //             popupDialog.loadFactNames(popupDialog.selectedGroup)
                //         }
                //         popupDialog.open()
                //     }
                // }
            }
        }
    }

    Popup {
        id:                 popupDialog
        modal:              true
        width:              Math.max(ScreenTools.defaultFontPixelWidth * 40, Math.max(comboRow.width, valueRow.width) + 48)
        height:             mainLayout.height + (ScreenTools.defaultFontPixelWidth * 5)
        background:         Rectangle { color: qgcPal.window; radius: 8 }
        anchors.centerIn:   Overlay.overlay

        property var    factGroups: []
        property var    factNames: []
        property string selectedGroup: ""
        property string selectedFact: ""

        // GENERAL SAFE CONVERSION TO ARRAY
        function _toArray(listLike) {
            let out = []
            if (!listLike) return out

            if (listLike.count !== undefined && typeof listLike.get === "function") {
                for (let i = 0; i < listLike.count; i++)
                    out.push(listLike.get(i))
                return out
            }

            if (Array.isArray(listLike))
                return listLike.slice()

            if (typeof listLike.length === "number") {
                for (let i = 0; i < listLike.length; i++)
                    out.push(listLike[i])
                return out
            }

            for (let k in listLike) {
                try { out.push(listLike[k]) } catch(e) {}
            }
            return out
        }

        // LOAD FACT GROUPS

        function loadFactGroups() {
            factGroups = []
            if (!_activeVehicle) {
                console.log("loadFactGroups: No active vehicle")
                return
            }

            let gList = _activeVehicle.factGroupNameList || _activeVehicle.factGroupNames || _activeVehicle.factGroupList || []

            let names = _toArray(gList)

            // If empty, scan keys
            if (names.length === 0) {
                console.log("Scanning _activeVehicle keys for fact groups")
                let keys = Object.keys(_activeVehicle)
                keys.forEach(k => {
                    if (
                        k === "batteries" ||
                        k.toLowerCase().includes("battery") ||
                        k.toLowerCase().includes("distance") ||
                        k === "gps" || k === "gps2" ||
                        k === "wind" || k === "temperature" ||
                        k === "estimatorStatus" ||
                        k === "localPosition" ||
                        k === "efi" || k === "generator"
                    ) {
                        if (!names.includes(k))
                            names.push(k)
                    }
                })
            }

            names.push("Vehicle")

            factGroups = names
        }

        // LOAD FACT NAMES FOR SELECTED GROUP

        function loadFactNames(groupName) {
            if (!_activeVehicle) {
                factNames = []
                return
            }

            let list = []

            if (groupName === "Vehicle") {
                // Top-level facts
                for (let key in _activeVehicle) {
                    let f = _activeVehicle[key]
                    if (f && f.name !== undefined && f.value !== undefined)
                        list.push(f.name)
                }

            } else {
                let group = _activeVehicle.getFactGroup(groupName)
                if (group) {
                    let arr = _toArray(group.factNames)
                    arr.forEach(n => list.push(n))
                }
            }

            factNames = list
        }

        // POPUP OPENED → AUTO-SELECT FIRST GROUP + LOAD NAMES

        onOpened: {
            loadFactGroups()

            if (factGroups.length > 0) {
                selectedGroup = factGroups[0]
                loadFactNames(selectedGroup)
                // Auto-select first fact
                if (factNames.length > 0) {
                    selectedFact = factNames[0]
                }
            } else {
                selectedGroup = ""
                factNames = []
                selectedFact = ""
            }
        }

        ColumnLayout {
            id:                 mainLayout
            anchors.margins:    12
            spacing:            10

            QGCLabel {
                text:       "Select Telemetry Value"
                color:      qgcPal.buttonText
                font.bold:  true
            }

            Rectangle {
                id:             mainRect
                width:          popupDialog.width - 24
                height:         comboRow.height + (ScreenTools.defaultFontPixelWidth * 2)
                radius:         ScreenTools.defaultFontPixelWidth * 0.8
                color:          qgcPal.window
                border.color:   "#888"

                RowLayout {
                    id:                 comboRow
                    anchors.centerIn:   parent
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.margins:    10
                    spacing:            10

                    QGCLabel {
                        text:               qsTr("Group")
                        Layout.alignment:   Qt.AlignLeft
                        Layout.preferredWidth: 60
                        font.bold:          true
                        color:      qgcPal.buttonText
                    }

                    QGCComboBox {
                        id:                 comboGroup
                        Layout.fillWidth:   true
                        Layout.alignment:   Qt.AlignRight
                        model:              popupDialog.factGroups

                        onActivated: {
                            popupDialog.selectedGroup = currentText
                            popupDialog.loadFactNames(currentText)
                        }
                    }
                }
            }

            // ---------- FACT NAME COMBO ----------

            Rectangle {
                width:          popupDialog.width - 24
                height:         valueRow.height + (ScreenTools.defaultFontPixelWidth * 2)
                radius:         ScreenTools.defaultFontPixelWidth * 0.8
                color:      qgcPal.window
                border.color:   "#888"

                RowLayout {
                    id:                 valueRow
                    anchors.centerIn:   parent
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.margins:    10
                    spacing:            10

                    QGCLabel {
                        text:               qsTr("Value")
                        Layout.alignment:   Qt.AlignLeft
                        Layout.preferredWidth: 60
                        font.bold:          true
                        color:      qgcPal.buttonText
                    }

                    QGCComboBox {
                        id:                 comboFact
                        Layout.fillWidth:   true
                        Layout.alignment:   Qt.AlignRight
                        model:              popupDialog.factNames

                        onActivated: {
                            popupDialog.selectedFact = currentText
                        }
                    }
                }
            }

            // Rectangle {
            //     width:          popupDialog.width - 24
            //     height:         iconRow.height + (ScreenTools.defaultFontPixelWidth * 2)
            //     radius:         ScreenTools.defaultFontPixelWidth * 0.8
            //     color:      qgcPal.window
            //     border.color:   "#888"
            //     visible:        /*ScreenTools.isMobile ?*/ false /*: true*/

            //     RowLayout {
            //         id:                 iconRow
            //         anchors.centerIn:   parent
            //         anchors.left:       parent.left
            //         anchors.right:      parent.right
            //         anchors.margins:    10
            //         spacing:            10

            //         QGCLabel {
            //             text:               qsTr("Icon")
            //             Layout.alignment:   Qt.AlignLeft
            //             font.bold:          true
            //             color:      qgcPal.buttonText
            //         }

            //         QGCColoredImage {
            //             id:                             valueIcon
            //             property string selectedIcon:   IconProvider.iconNames[0]
            //             source:                         selectedIcon !== "" ? "qrc:/InstrumentValueIcons/" + selectedIcon : ""
            //             width:                          ScreenTools.defaultFontPixelWidth * 5.5
            //             height:                         width
            //             Layout.alignment:               Qt.AlignRight

            //             MouseArea {
            //                 anchors.fill:   parent
            //                 onClicked:      iconPopup.open()
            //             }
            //         }
            //         // Component.onCompleted: {
            //         //     console.log("IconProvider.iconNames =", IconProvider.iconNames)
            //         // }
            //     }
            // }

            QGCButton {
                text:   "Add"
                width:  parent.width
                onClicked: {
                    if (popupDialog.selectedGroup === "" || popupDialog.selectedFact === "") {
                        console.log("Select both group + fact")
                        return
                    }

                    let fullName
                    if (popupDialog.selectedGroup === "Vehicle") {
                        fullName = popupDialog.selectedFact
                    } else {
                        fullName = popupDialog.selectedGroup + "." + popupDialog.selectedFact
                    }

                    console.log("ADDING FACT:", fullName)
                    root.displayedFacts = root.displayedFacts.concat([fullName])

                    popupDialog.close()
                }
            }
        }

        Connections {
            target: QGroundControl.multiVehicleManager

            onActiveVehicleChanged: {
                //console.log("Vehicle is now available:", activeVehicle)
                _activeVehicle = activeVehicle
            }
        }
    }

    QGCPopupDialog {
        id:             iconPopup
        title:          qsTr("Icon List")
        width:          ScreenTools.defaultFontPixelWidth * 60
        height:         ScreenTools.defaultFontPixelHeight * 60
        destroyOnClose: false

        GridView {
            anchors.fill:   parent
            model:          IconProvider.iconNames
            cellWidth:      48
            cellHeight:     48

            delegate: MouseArea {
                width:  40
                height: 40

                QGCColoredImage {
                    anchors.centerIn:   parent
                    width:              32
                    height:             32
                    source:             "qrc:/InstrumentValueIcons/" + modelData
                }

                onClicked: {
                    valueIcon.selectedIcon = modelData
                    iconPopup.close()
                }
            }
        }
    }
}
