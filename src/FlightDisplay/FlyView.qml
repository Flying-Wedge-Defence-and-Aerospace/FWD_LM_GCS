    /****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.15
import QtQuick.Controls         2.15
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1
//import QtQuick.Controls 2.4

import QGroundControl               1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

/*****************Main********************/
Item {
    id: _root
    anchors.fill: parent
    anchors.top: parent.top
    anchors.topMargin: QGroundControl.videoManager.fullScreen ? 0 : ScreenTools.toolbarHeight
    width: parent.width
    height: parent.width * 0.74

    // Required controllers for internal logic
    property var planController: _planController
    property var guidedController: _guidedController

    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }

    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedActionList:      guidedActionList
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 47
    property var    _mapControl:            mapControl
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    property bool videoFullScreen: false
    property real normalMapWidth: 0
    property real normalVideoWidth: 0

    property bool messVisible: true
    property bool hudVisible: true
    property bool paramVisible: true

    property bool videoIsFullscreen: false
    property Item videoOriginalParent
    property int videoOriginalIndex


    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipOverlay.visible ? _pipOverlay.x + _pipOverlay.width : 0
        bottomEdgeLeftInset:    _pipOverlay.visible ? parent.height - _pipOverlay.y : 0
    }

    FlyViewWidgetLayer {
        id:                     widgetLayer
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
        z:                      _fullItemZorder + 1
        parentToolInsets:       _toolInsets
        mapControl:             _mapControl
        visible:                !QGroundControl.videoManager.fullScreen
    }

    FlyViewCustomLayer {
        id:                 customOverlay
        anchors.fill:       widgetLayer
        z:                  _fullItemZorder + 2
        parentToolInsets:   widgetLayer.totalToolInsets
        mapControl:         _mapControl
        visible:            !QGroundControl.videoManager.fullScreen
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        //anchors.left:       toolStrip.right
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      true
        visible:           /* !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.fullState*/ false

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    GuidedActionsController {
        id:                 guidedActionsController
        missionController: _missionController
        actionList:         _guidedActionList
        guidedValueSlider:  _guidedValueSlider
    }

    GuidedActionList {
        id:                         guidedActionList
        anchors.margins:            8
        anchors.bottom:             parent.bottom
        anchors.horizontalCenter:   parent.horizontalCenter
        z: QGroundControl.          zOrderTopMost
        guidedController:           _guidedController
    }

    GuidedValueSlider {
        id:                 guidedValueSlider
        anchors.margins:    8
        anchors.right:      parent.right
        anchors.top:        parent.top
        anchors.topMargin: ScreenTools.toolbarHeight
        anchors.bottom:     parent.bottom
        z:                  QGroundControl.zOrderTopMost
        radius:             8
        width:              120
        color:              "gray"
        visible:            false
    }

    ToolStrip {
        //id: toolstrip
        //width: parent.width
        //height: ScreenTools.defaultFontPixelHeight * 8.7
        maxHeight: parent.height
        anchors.leftMargin: _toolsMargin + 5
        anchors.top: parent.top
        anchors.topMargin: ScreenTools.isMobile ? ScreenTools.toolbarHeight / 3 : ScreenTools.toolbarHeight / 2
        anchors.left: parent.left
        z: 1
        visible: videoControl.pipState.state === videoControl.pipState.pipState
        //orientation: Qt.Vertical
        id: __root

        signal displayPreFlightChecklis

        FlyViewToolStripActionList {
            id: flyViewToolStripActionList
            onDisplayPreFlightChecklist: __root.displayPreFlightChecklist()
        }

        model: flyViewToolStripActionList.model
    }

    // ColumnLayout {
    //     id: topLayout
    //     width: parent.width
    //     height: videoFullScreen ? parent.height : parent.height * 0.75
    //     //height: parent.height * 0.75
    //     spacing: 0

    //     SplitView {
    //         id: splitView
    //         Layout.fillWidth: true
    //         Layout.preferredHeight: parent.height
    //         //Layout.preferredHeight: parent.height * 0.72

    //         orientation: Qt.Horizontal
    //         //topPadding: ScreenTools.toolbarHeight   // 👈 THIS is the key

    //         FlyViewMap {
    //             id: mapControl
    //             SplitView.preferredWidth: parent.width * 0.5
    //             SplitView.minimumWidth: 200

    //             planMasterController: _planController
    //             mapName: "FlightMapTopLeft"
    //             pipMode: false
    //             toolInsets: Qt.rect(0, 0, 0, 0)
    //         }

    //         FlyViewVideo {
    //             id: videoControl
    //             SplitView.preferredWidth: parent.width * 0.5
    //             SplitView.minimumWidth: 200
    //         }
    //     }
    // }

    FlyViewMap {
        id: mapControl
        width: parent.width
        height: parent.height
        planMasterController: _planController
        mapName: "FlightMapTopLeft"
        pipMode: false
        toolInsets: Qt.rect(0, 0, 0, 0)
        anchors.top: parent.top
    }

    FlyViewVideo {
        id: videoControl
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        isTheVideoFull: isVideoFull
    }

    // FlyViewInstrumentPanel {
    //     id:                         instrumentPanel
    //     width:                      ScreenTools.isMobile ? _rightPanelWidth : ScreenTools.defaultFontPixelWidth * 35
    //     //anchors.centerIn:  parent
    //     //anchors.centerIn: centerRect.Center
    //     //height: 50
    //     //anchors.left: parent.left
    //     //anchors.leftMargin: ScreenTools.isMobile ? 90 : 130
    //     //anchors.top: parent.top
    //     //anchors.bottom: parent.bottom
    //     //anchors.bottomMargin: 40
    //     //anchors.topMargin: ScreenTools.isMobile ? 45 : 90
    //     anchors.bottom: parent.bottom
    //     // anchors.bottomMargin: 5
    //     anchors.horizontalCenter: parent.horizontalCenter
    // }

    Loader {
        source: "qrc:/qml/QGCInstrumentWidget.qml"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: videoControl.pipState.state === videoControl.pipState.pipState && multiVehiclePanelSelector.showSingleVehiclePanel
    }

    Rectangle {
        id: messBut
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: ScreenTools.defaultFontPixelWidth
        width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 5.5 : ScreenTools.defaultFontPixelWidth * 8
        height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 2.2 : ScreenTools.defaultFontPixelHeight * 2.6
        color: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue ? "#aa000000" : "#aaffffff"
        radius: height * 4
        border.width: 1
        border.color: "white"
        Loader {
            source: "qrc:/toolbar/MessageIndicator.qml"
            anchors.centerIn: parent
            z: 999
        }
    }

    Rectangle {
        id: ssBut
        anchors.bottom: messBut.top
        anchors.right: parent.right
        anchors.margins: ScreenTools.defaultFontPixelWidth
        width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 5.5 : ScreenTools.defaultFontPixelWidth * 8
        height: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 2.2 : ScreenTools.defaultFontPixelHeight * 2.6
        color: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue ? "#aa000000" : "#aaffffff"
        radius: height * 4
        border.width: 1
        border.color: "white"

        QGCColoredImage {
            id: ssbut
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: width
            source: "/res/ssIcon"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                QGroundControl.saveScreenshot()
            }
        }
    }

    Rectangle {
        id: botRect1
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 2.5
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * (ScreenTools.isMobile ? 1.7 : 1)
        width: parent.width * (ScreenTools.isMobile ? 0.20 : 0.15)
        height: parent.height * (ScreenTools.isMobile ? 0.35 : 0.275)
        //color: "#aa000000"
        color: QGroundControl.settingsManager.appSettings.indoorPalette.rawValue ? "#aa000000" : "#aaffffff"
        visible: videoControl.pipState.state === videoControl.pipState.pipState
        anchors.bottomMargin: paramVisible ? 0 : -height
        z: 999

        ParameterDetails {
            //Layout.margins: 20
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    QGCButton {
        id:                 disconnectButton
        text:               qsTr("Disconnect")
        onClicked:          _activeVehicle.closeVehicle()
        visible:            _activeVehicle && _communicationLost
        anchors.top: parent.top
        anchors.topMargin: ScreenTools.toolbarHeight + (ScreenTools.defaultFontPixelWidth)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Row {
    //     id:                 multiVehiclePanelSelector
    //     anchors.margins:    _toolsMargin
    //     anchors.top:        parent.top
    //     anchors.topMargin: ScreenTools.toolbarHeight + (ScreenTools.defaultFontPixelWidth * 2)
    //     anchors.right:      parent.right
    //     width:              _rightPanelWidth
    //     spacing:            ScreenTools.defaultFontPixelWidth
    //     visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList

    //     property bool showSingleVehiclePanel:  !visible || singleVehicleRadio.checked

    //     QGCMapPalette { id: mapPal; lightColors: true }

    //     QGCRadioButton {
    //         id:             singleVehicleRadio
    //         text:           qsTr("Single")
    //         checked:        true
    //         textColor:      /*mapPal.text*/"black"
    //     }

    //     QGCRadioButton {
    //         text:           qsTr("Multi-Vehicle")
    //         textColor:      /*mapPal.text*/"black"
    //     }
    // }

    Rectangle {
        id: multiVehiclePanelSelector
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins:    _toolsMargin
        //anchors.rightMargin: 60
        width:  multiVehiclePanelSelector1.implicitWidth
        height: multiVehiclePanelSelector1.implicitHeight
        color:              qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList
        property bool showSingleVehiclePanel:  !visible ||   singleVehicleRadio.checked

        QGCMapPalette { id: mapPal; lightColors: true }

        RowLayout {
            id: multiVehiclePanelSelector1
            anchors.fill: parent

            QGCRadioButton {
                id:             singleVehicleRadio
                text:           qsTr("SINGLE")
                font.bold: true
                checked:        true
            }

            QGCRadioButton {
                text:           qsTr("MULTI-VEHICLE")
                font.bold: true
            }
        }
    }

    MultiVehicleList {
        id: mulVL
        //anchors.margins:    _toolsMargin
        //anchors.top:        parent.top
        //anchors.left: parent.left
        // anchors.right: parent.right

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        //anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 1.2
        //anchors.centerIn: parent
        width:              ScreenTools.isMobile ? _rightPanelWidth : _rightPanelWidth + ScreenTools.defaultFontPixelWidth * 18
        height:            ScreenTools.isMobile ? parent.height - 560 : parent.height - y + 34 /*- _toolsMargin*/
        visible:            !multiVehiclePanelSelector.showSingleVehiclePanel
        z: 999
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.topMargin:          ScreenTools.toolbarHeight + (ScreenTools.defaultFontPixelWidth * 2)
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
    }

    QGCPipOverlay {
        id:                     _pipOverlay
        //anchors.left:           parent.left
        //anchors.bottom: videoControl.pipState.state === videoControl.pipState.pipState ? hideParam.top : parent.bottom
        //anchors.bottom: parent.bottom
        //anchors.right:          parent.right
        //anchors.verticalCenter: parent.verticalCenter
        anchors.margins:        _toolsMargin
        //anchors.rightMargin: 10
        item1IsFullSettingsKey: "MainFlyWindowIsMap"
        item1:                  mapControl
        item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
        fullZOrder:             _fullItemZorder
        pipZOrder:              _pipItemZorder
        x: _toolsMargin
        y: /*videoControl.pipState.state === videoControl.pipState.pipState
               ? hideParam.y - height - _toolsMargin
               :*/ parent.height - height - _toolsMargin
        //visible: false
        //onVideoClose: photoVideoControl.visible = false
        //onVideoOpen: photoVideoControl.visible = true

        DragHandler {
            target: _pipOverlay
            grabPermissions: PointerHandler.CanTakeOverFromItems
        }
    }

    property bool isVideoFull: _pipOverlay._fullItem === videoControl
}
