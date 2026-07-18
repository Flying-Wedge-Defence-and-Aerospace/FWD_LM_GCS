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
    width: /*ScreenTools.isMobile ? 150 : 120*/ 40
    height: /*ScreenTools.isMobile ? 123 : 77*/ ScreenTools.isMobile ? 90 : 71

    property Fact fact
    signal openIconList

    function removeFactAt(i) {
        if (i >= 0 && i < displayedFacts.length) {
            displayedFacts.splice(i, 1)  // remove 1 element
            displayedFacts = displayedFacts  // force QML to re-evaluate model
        }
    }

    property int indexInModel: index

    Rectangle { // outer rectangle
        anchors.fill: parent
        color: "transparent"
        //border.color: "white"

        // Button { // delete button
        //     width: ScreenTools.isMobile ? 35 : 20
        //     height: ScreenTools.isMobile ? 25 : 20
        //     anchors.top: parent.top
        //     anchors.right: parent.right
        //     anchors.rightMargin: ScreenTools.isMobile ? 0 : ScreenTools.defaultFontPixelWidth / 2
        //     anchors.topMargin: ScreenTools.isMobile ? 4 : 0
        //     anchors.bottomMargin: ScreenTools.defaultFontPixelWidth
        //     z: 999

        //     background: Rectangle {
        //         //anchors.centerIn: parent
        //         anchors.top: parent.top
        //         anchors.topMargin: 10
        //         color: "blue"
        //         Text {
        //             anchors.centerIn: parent
        //             text: "x"
        //             color: "white"
        //             font.pointSize: ScreenTools.isMobile ? 7 : 12
        //         }
        //         radius: 7
        //     }

        //     onClicked: root.removeFactAt(indexInModel)

        // }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * (ScreenTools.isMobile ? 0.96 : 0.98)
            height: parent.height * (ScreenTools.isMobile ? 0.96 : 0.96)
            color: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue ? "#aa000000" : "#aaffffff"
            // border.color: "#505050"
            // border.width: 1

            Rectangle {
                width: parent.width * 0.7
                height: parent.height
                color: "transparent"
                anchors.horizontalCenter: parent.horizontalCenter
                //anchors.leftMargin: -13
                visible: ScreenTools.isMobile ? false : true

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    QGCLabel {
                        text: fact ? fact.valueString + (fact.units !== "" ? " " + fact.units : "") : "--"
                        font.pointSize: ScreenTools.isMobile ? 10 : 12
                        color: qgcPal.text
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.bold: true
                    }

                    QGCLabel {
                        text: fact && fact.name ? fact.name.charAt(0).toUpperCase() + fact.name.slice(1) : "N/A"

                        font.bold: true
                        font.italic: true
                        font.pointSize: ScreenTools.isMobile ? 8 : 9
                        color: qgcPal.text
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: ScreenTools.isMobile ? 0 : 6
                visible: ScreenTools.isMobile ? true : false

                QGCLabel {
                    text: fact && fact.name
                          ? fact.name.charAt(0).toUpperCase() + fact.name.slice(1)
                          : "N/A"
                    font.bold: true
                    font.pointSize: ScreenTools.isMobile ? 6 : 9
                    color: qgcPal.text
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                QGCLabel {
                    text: fact ? fact.valueString + (fact.units !== "" ? " " + fact.units : "") : "--"
                    font.pointSize: ScreenTools.isMobile ? 8 : 12
                    color: qgcPal.text
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                deletePopup.x = root.width/2 - deletePopup.width/2
                deletePopup.y = -deletePopup.height - 4   // 👈 above tile
                deletePopup.open()
            }
        }
    }

    Popup {
        id: deletePopup
        modal: false
        focus: true
        padding: 6
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

        background: Rectangle {
            radius: 6
            color: "#99000000"
        }

        contentItem: Column {
            spacing: 6

            QGCButton {
                text: "Delete"
                onClicked: {
                    deletePopup.close()
                    root.removeFactAt(indexInModel)
                }
            }
        }
    }


}
