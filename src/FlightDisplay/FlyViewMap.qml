/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtLocation                   5.3
import QtPositioning                5.3
import QtQuick.Dialogs              1.2
import QtQuick.Layouts              1.11
import QtQuick.Shapes               1.0
import QtGraphicalEffects           1.0

import QGroundControl               1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

FlightMap {
    id:                         _root
    allowGCSLocationCenter:     true
    allowVehicleLocationCenter: !_keepVehicleCentered
    planView:                   false
    zoomLevel:                  QGroundControl.flightMapZoom
    center:                     QGroundControl.flightMapPosition

    property Item pipState: _pipState
    QGCPipState {
        id:         _pipState
        pipOverlay: _pipOverlay
        isDark:     _isFullWindowItemDark
    }

    property var    rightPanelWidth
    property var    planMasterController
    property bool   pipMode:                    false   // true: map is shown in a small pip mode
    property var    toolInsets                          // Insets for the center viewport area

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:      planMasterController
    property var    _geoFenceController:        planMasterController.geoFenceController
    property var    _rallyPointController:      planMasterController.rallyPointController
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
    property real   _toolButtonTopMargin:       parent.height - mainWindow.height + (ScreenTools.defaultFontPixelHeight / 2)
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property bool   _keepMapCenteredOnVehicle:  _flyViewSettings.keepMapCenteredOnVehicle.rawValue

    property bool   _disableVehicleTracking:    false
    property bool   _keepVehicleCentered:       pipMode ? true : false
    property bool   _saveZoomLevelSetting:      true
    property bool   missionEditMode:            false
    property int    _pendingInsertIndex:        -1
    property int    _dwCount:                   0
    property var    _oldRemainingPath:          []
    property var    _dynamicPath:               []
    property int    _firstDynamicSeq:           -1
    property int    _lastDynamicSeq:            -1
    property bool   _dynamicCompleted:          false

    function _updateDynamicPath() {
        var dynPath = []
        for (var i = 0; i < _dwModel.count; i++) {
            var item = _dwModel.get(i)
            dynPath.push(QtPositioning.coordinate(item.latitude, item.longitude))
        }
        _dynamicPath = dynPath
    }

    function _adjustMapZoomForPipMode() {
        _saveZoomLevelSetting = false
        if (pipMode) {
            if (QGroundControl.flightMapZoom > 3) {
                zoomLevel = QGroundControl.flightMapZoom - 3
            }
        } else {
            zoomLevel = QGroundControl.flightMapZoom
        }
        _saveZoomLevelSetting = true
    }

    onPipModeChanged: _adjustMapZoomForPipMode()

    onVisibleChanged: {
        if (visible) {
            // Synchronize center position with Plan View
            center = QGroundControl.flightMapPosition
        }
    }

    onZoomLevelChanged: {
        if (_saveZoomLevelSetting) {
            QGroundControl.flightMapZoom = zoomLevel
        }
        _updateAirspace()
    }
    onCenterChanged: {
        QGroundControl.flightMapPosition = center
        _updateAirspace()
    }

    Connections {
        target: QGroundControl.airspaceManager
        onEnabledChanged: {
            if (QGroundControl.airspaceManager.enabled) {
                _updateAirspace()
            }
        }
    }

    // We track whether the user has panned or not to correctly handle automatic map positioning
    Connections {
        target: gesture

        function onPanStarted() {       _disableVehicleTracking = true }
        function onFlickStarted() {     _disableVehicleTracking = true }
        function onPanFinished() {      panRecenterTimer.restart() }
        function onFlickFinished() {    panRecenterTimer.restart() }
    }

    function pointInRect(point, rect) {
        return point.x > rect.x &&
                point.x < rect.x + rect.width &&
                point.y > rect.y &&
                point.y < rect.y + rect.height;
    }

    property real _animatedLatitudeStart
    property real _animatedLatitudeStop
    property real _animatedLongitudeStart
    property real _animatedLongitudeStop
    property real animatedLatitude
    property real animatedLongitude

    onAnimatedLatitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)
    onAnimatedLongitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)

    NumberAnimation on animatedLatitude { id: animateLat; from: _animatedLatitudeStart; to: _animatedLatitudeStop; duration: 1000 }
    NumberAnimation on animatedLongitude { id: animateLong; from: _animatedLongitudeStart; to: _animatedLongitudeStop; duration: 1000 }

    function animatedMapRecenter(fromCoord, toCoord) {
        _animatedLatitudeStart = fromCoord.latitude
        _animatedLongitudeStart = fromCoord.longitude
        _animatedLatitudeStop = toCoord.latitude
        _animatedLongitudeStop = toCoord.longitude
        animateLat.start()
        animateLong.start()
    }

    // returns the rectangle formed by the four center insets
    // used for checking if vehicle is under ui, and as a target for recentering the view
    function _insetCenterRect() {
        return Qt.rect(toolInsets.leftEdgeCenterInset,
                       toolInsets.topEdgeCenterInset,
                       _root.width - toolInsets.leftEdgeCenterInset - toolInsets.rightEdgeCenterInset,
                       _root.height - toolInsets.topEdgeCenterInset - toolInsets.bottomEdgeCenterInset)
    }

    function _updateAirspace() {
        var airMgr = QGroundControl.airspaceManager
        if (!airMgr.enabled) return
        var c0 = _root.toCoordinate(Qt.point(0, 0), false)
        var c1 = _root.toCoordinate(Qt.point(_root.width - 1, _root.height - 1), false)
        airMgr.refresh(c0.latitude, c0.longitude, c1.latitude, c1.longitude)
    }

    // returns the four rectangles formed by the 8 corner insets
    // used for detecting if the vehicle has flown under the instrument panel, virtual joystick etc
    function _insetCornerRects() {
        var rects = {
        "topleft":      Qt.rect(0,0,
                               toolInsets.leftEdgeTopInset,
                               toolInsets.topEdgeLeftInset),
        "topright":     Qt.rect(_root.width-toolInsets.rightEdgeTopInset,0,
                               toolInsets.rightEdgeTopInset,
                               toolInsets.topEdgeRightInset),
        "bottomleft":   Qt.rect(0,_root.height-toolInsets.bottomEdgeLeftInset,
                               toolInsets.leftEdgeBottomInset,
                               toolInsets.bottomEdgeLeftInset),
        "bottomright":  Qt.rect(_root.width-toolInsets.rightEdgeBottomInset,_root.height-toolInsets.bottomEdgeRightInset,
                               toolInsets.rightEdgeBottomInset,
                               toolInsets.bottomEdgeRightInset)}
        return rects
    }

    function recenterNeeded() {
        var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
        var centerRect = _insetCenterRect()
        //return !pointInRect(vehiclePoint,insetRect)

        // If we are outside the center inset rectangle, recenter
        if(!pointInRect(vehiclePoint, centerRect)){
            return true
        }

        // if we are inside the center inset rectangle
        // then additionally check if we are underneath one of the corner inset rectangles
        var cornerRects = _insetCornerRects()
        if(pointInRect(vehiclePoint, cornerRects["topleft"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["topright"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["bottomleft"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["bottomright"])){
            return true
        }

        // if we are inside the center inset rectangle, and not under any corner elements
        return false
    }

    function updateMapToVehiclePosition() {
        if (animateLat.running || animateLong.running) {
            return
        }
        // We let FlightMap handle first vehicle position
        if (!_keepMapCenteredOnVehicle && firstVehiclePositionReceived && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            if (_keepVehicleCentered) {
                _root.center = _activeVehicleCoordinate
            } else {
                if (firstVehiclePositionReceived && recenterNeeded()) {
                    // Move the map such that the vehicle is centered within the inset area
                    var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
                    var centerInsetRect = _insetCenterRect()
                    var centerInsetPoint = Qt.point(centerInsetRect.x + centerInsetRect.width / 2, centerInsetRect.y + centerInsetRect.height / 2)
                    var centerOffset = Qt.point((_root.width / 2) - centerInsetPoint.x, (_root.height / 2) - centerInsetPoint.y)
                    var vehicleOffsetPoint = Qt.point(vehiclePoint.x + centerOffset.x, vehiclePoint.y + centerOffset.y)
                    var vehicleOffsetCoord = _root.toCoordinate(vehicleOffsetPoint, false /* clipToViewport */)
                    animatedMapRecenter(_root.center, vehicleOffsetCoord)
                }
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: {
        if (_keepMapCenteredOnVehicle && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            _root.center = _activeVehicleCoordinate
        }
    }

    Timer {
        id:         panRecenterTimer
        interval:   10000
        running:    false
        onTriggered: {
            _disableVehicleTracking = false
            updateMapToVehiclePosition()
        }
    }

    Timer {
        interval:       500
        running:        true
        repeat:         true
        onTriggered:    updateMapToVehiclePosition()
    }

    QGCMapPalette { id: mapPal; lightColors: isSatelliteMap }

    Connections {
        target:                 _missionController
        ignoreUnknownSignals:   true
        function onNewItemsFromVehicle() {
            var visualItems = _missionController.visualItems
            if (visualItems && visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
                firstVehiclePositionReceived = true
            }
        }
    }

    MapFitFunctions {
        id:                         mapFitFunctions // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        _root
        usePlannedHomePosition:     false
        planMasterController:       _planMasterController
    }

    ObstacleDistanceOverlayMap {
        id: obstacleDistance
        showText: !pipMode
    }

    // Short recent vehicle trail (last 40 seconds)
    MapPolyline {
        id:         trajectoryPolyline
        line.width: 3
        line.color: "red"
        z:          QGroundControl.zOrderTrajectoryLines
        visible:    !pipMode

        property var    _trailPoints:       []
        property int    _trailDurationMs:   40000   // 40 seconds
        property int    _sampleIntervalMs:  500

        Component.onCompleted: _resetTrail()

        function _resetTrail() {
            _trailPoints = []
            trajectoryPolyline.path = []
            if (_activeVehicle && _activeVehicle.coordinate.isValid) {
                _addPoint(_activeVehicle.coordinate)
            }
        }

        function _addPoint(coordinate) {
            if (!coordinate || !coordinate.isValid) {
                return
            }

            var now = Date.now()
            var last = _trailPoints.length > 0 ? _trailPoints[_trailPoints.length - 1] : null

            if (last && (now - last.time) < _sampleIntervalMs) {
                // Keep the trail end attached to the vehicle between samples.
                last.coordinate = coordinate
                trajectoryPolyline.replaceCoordinate(trajectoryPolyline.pathLength() - 1, coordinate)
            } else {
                _trailPoints.push({ coordinate: coordinate, time: now })
                trajectoryPolyline.addCoordinate(coordinate)
            }

            // Drop points older than the configured trail duration.
            while (_trailPoints.length > 0 && (now - _trailPoints[0].time) > _trailDurationMs) {
                _trailPoints.shift()
                trajectoryPolyline.removeCoordinate(0)
            }
        }

        function _clearTrail() {
            _trailPoints = []
            trajectoryPolyline.path = []
        }
    }

    Connections {
        target:                 QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) {
            trajectoryPolyline._resetTrail()
        }
    }

    Connections {
        target:                 _activeVehicle
        function onCoordinateChanged(coordinate) {
            trajectoryPolyline._addPoint(coordinate)
        }
    }

    // Add the vehicles to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: VehicleMapItem {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 4
            iconSource:     "/qmlimages/vehicleFixedWing.svg"
            z:              QGroundControl.zOrderVehicles
        }
    }
    // Add distance sensor view
    MapItemView{
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: ProximityRadarMapView {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            z:              QGroundControl.zOrderVehicles
        }
    }
    // Add ADSB vehicles to the map
    MapItemView {
        model: QGroundControl.adsbVehicleManager.adsbVehicles
        delegate: VehicleMapItem {
            coordinate:     object.coordinate
            altitude:       object.altitude
            callsign:       object.callsign
            heading:        object.heading
            alert:          object.alert
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 2.5
            z:              QGroundControl.zOrderVehicles
        }
    }

    // Add the items associated with each vehicles flight plan to the map
    Repeater {
        model: QGroundControl.multiVehicleManager.vehicles

        PlanMapItems {
            map:                    _root
            largeMapView:           !pipMode
            planMasterController:   masterController
            vehicle:                _vehicle
            firstDynamicSeq:        _firstDynamicSeq

            property var _vehicle: object

            PlanMasterController {
                id: masterController
                Component.onCompleted: startStaticActiveVehicle(object)
            }
        }
    }

    MapItemView {
        model: pipMode ? undefined : _missionController.directionArrows

        delegate: MapLineArrow {
            fromCoord:      object ? object.coordinate1 : undefined
            toCoord:        object ? object.coordinate2 : undefined
            arrowPosition:  2
            z:              QGroundControl.zOrderWaypointLines
        }
    }

    // Allow custom builds to add map items
    CustomMapItems {
        map:            _root
        largeMapView:   !pipMode
    }

    GeoFenceMapVisuals {
        map:                    _root
        myGeoFenceController:   _geoFenceController
        interactive:            false
        planView:               false
        homePosition:           _activeVehicle && _activeVehicle.homePosition.isValid ? _activeVehicle.homePosition :  QtPositioning.coordinate()
    }

    AirspaceMapVisuals {
        map:            _root
    }

    // AirspaceLegend {
    //     anchors.margins:    ScreenTools.defaultFontPixelHeight
    //     anchors.right:      parent.right
    //     anchors.bottom:     parent.bottom
    //     z: 9999
    // }

    // Rally points on map
    MapItemView {
        model: _rallyPointController.points

        delegate: MapQuickItem {
            id:             itemIndicator
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderMapItems

            sourceItem: MissionItemIndexLabel {
                id:         itemIndexLabel
                label:      qsTr("R", "rally point map item label")
            }
        }
    }   

    // Camera trigger points
    MapItemView {
        model: _activeVehicle ? _activeVehicle.cameraTriggerPoints : 0

        delegate: CameraTriggerIndicator {
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderTopMost
        }
    }

    // GoTo Location visuals
    MapQuickItem {
        id:             gotoLocationItem
        visible:        false
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Fly here", "Fly to location waypoint")
        }

        property bool inGotoFlightMode: _activeVehicle ? _activeVehicle.flightMode === _activeVehicle.gotoFlightMode : false

        onInGotoFlightModeChanged: {
            if (!inGotoFlightMode && gotoLocationItem.visible) {
                // Hide goto indicator when vehicle falls out of guided mode
                gotoLocationItem.visible = false
            }
        }

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                if (!activeVehicle) {
                    gotoLocationItem.visible = false
                }
            }
        }

        function show(coord) {
            gotoLocationItem.coordinate = coord
            gotoLocationItem.visible = true
        }

        function hide() {
            gotoLocationItem.visible = false
        }

        function actionConfirmed() {
            // We leave the indicator visible. The handling for onInGuidedModeChanged will hide it.
        }

        function actionCancelled() {
            hide()
        }
    }

    // Orbit editing visuals
    QGCMapCircleVisuals {
        id:             orbitMapCircle
        mapControl:     parent
        mapCircle:      _mapCircle
        visible:        false

        property alias center:              _mapCircle.center
        property alias clockwiseRotation:   _mapCircle.clockwiseRotation
        readonly property real defaultRadius: 30

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                if (!activeVehicle) {
                    orbitMapCircle.visible = false
                }
            }
        }

        function show(coord) {
            _mapCircle.radius.rawValue = defaultRadius
            orbitMapCircle.center = coord
            orbitMapCircle.visible = true
        }

        function hide() {
            orbitMapCircle.visible = false
        }

        function actionConfirmed() {
            // Live orbit status is handled by telemetry so we hide here and telemetry will show again.
            hide()
        }

        function actionCancelled() {
            hide()
        }

        function radius() {
            return _mapCircle.radius.rawValue
        }

        Component.onCompleted: globals.guidedControllerFlyView.orbitMapCircle = orbitMapCircle

        QGCMapCircle {
            id:                 _mapCircle
            interactive:        true
            radius.rawValue:    30
            showRotation:       true
            clockwiseRotation:  true
        }
    }

    // ROI Location visuals
    MapQuickItem {
        id:             roiLocationItem
        visible:        _activeVehicle && _activeVehicle.isROIEnabled
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY

        Connections {
            target: _activeVehicle
            onRoiCoordChanged: {
                roiLocationItem.show(centerCoord)
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                var roiEditMenu = popupMenuComponent.createObject(_root, { coord: roiLocationItem.coordinate, contentItemComponent: roiEditMenuComponent })
                var clickPoint = mapToItem(_root, mouse.x, mouse.y)
                roiEditMenu.setPosition(clickPoint.x, clickPoint.y)
                roiEditMenu.open()
            }
        }

        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("ROI here", "Make this a Region Of Interest")
        }

        //-- Visibilty controlled by actual state
        function show(coord) {
            roiLocationItem.coordinate = coord
        }
    }

    // Orbit telemetry visuals
    QGCMapCircleVisuals {
        id:             orbitTelemetryCircle
        mapControl:     parent
        mapCircle:      _activeVehicle ? _activeVehicle.orbitMapCircle : null
        visible:        _activeVehicle ? _activeVehicle.orbitActive : false
    }

    MapQuickItem {
        id:             orbitCenterIndicator
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        coordinate:     _activeVehicle ? _activeVehicle.orbitMapCircle.center : QtPositioning.coordinate()
        visible:        orbitTelemetryCircle.visible

        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Orbit", "Orbit waypoint")
        }
    }

    ListModel { id: _dwModel }
    ListModel { id: _persistentDWModel }
    ListModel { id: _oldRemainingWPModel }

    // Dynamic waypoint markers for edit mode
    MapItemView {
        model: _dwModel
        delegate: MapQuickItem {
            coordinate: QtPositioning.coordinate(latitude, longitude)
            anchorPoint.x: sourceItem.anchorPointX
            anchorPoint.y: sourceItem.anchorPointY
            z: QGroundControl.zOrderMapItems
            visible: missionEditMode
            property int dwIndex: index
            sourceItem: MissionItemIndexLabel {
                label: "D" + (dwIndex + 1)
                checked: true
            }
        }
    }

    // Persistent D markers shown after Execute
    MapItemView {
        model: _persistentDWModel
        delegate: MapQuickItem {
            coordinate: QtPositioning.coordinate(latitude, longitude)
            anchorPoint.x: sourceItem.anchorPointX
            anchorPoint.y: sourceItem.anchorPointY
            z: QGroundControl.zOrderMapItems + 1
            visible: !missionEditMode
            property int dwIndex: index
            sourceItem: MissionItemIndexLabel {
                label: "D" + (dwIndex + 1)
                checked: true
            }
        }
    }

    // Old remaining waypoint markers with original sequence numbers
    MapItemView {
        model: _oldRemainingWPModel
        delegate: MapQuickItem {
            coordinate: QtPositioning.coordinate(latitude, longitude)
            anchorPoint.x: sourceItem.anchorPointX
            anchorPoint.y: sourceItem.anchorPointY
            z: QGroundControl.zOrderMapItems + 1
            visible: !missionEditMode && _persistentDWModel.count > 0
            sourceItem: MissionItemIndexLabel {
                label: "Waypoint"
                index: originalSeq
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        
        onClicked: {
            if (missionEditMode) {
                orbitMapCircle.hide()
                gotoLocationItem.hide()
                var clickCoord = _root.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                var mapClickMenu = popupMenuComponent.createObject(_root, { coord: clickCoord, contentItemComponent: mapClickMenuComponent })
                mapClickMenu.setPosition(mouse.x, mouse.y)
                mapClickMenu.open()
            } else if (!globals.guidedControllerFlyView.guidedUIVisible && 
                (globals.guidedControllerFlyView.showGotoLocation || globals.guidedControllerFlyView.showOrbit || globals.guidedControllerFlyView.showROI || globals.guidedControllerFlyView.showSetHome || globals.guidedControllerFlyView.showSetEstimatorOrigin)) {
                orbitMapCircle.hide()
                gotoLocationItem.hide()
                var clickCoord = _root.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                var mapClickMenu = popupMenuComponent.createObject(_root, { coord: clickCoord, contentItemComponent: mapClickMenuComponent })
                mapClickMenu.setPosition(mouse.x, mouse.y)
                mapClickMenu.open()
            }
        }
    }
    
    Component {
        id: popupMenuComponent

        Popup {
            id: mapClickMenu
            modal: true

            QGCPalette { id: popupPal; colorGroupEnabled: true }

            property var coord
            property var contentItemComponent

            function setPosition(mouseX, mouseY) {
                var newX = mouseX
                var newY = mouseY

                // Filtering coordinates
                if (newX + mapClickMenu.width > _root.width) {
                    newX = _root.width - mapClickMenu.width
                }
                if (newY + mapClickMenu.height > _root.height) {
                    newY = _root.height - mapClickMenu.height
                }

                // Set coordiantes
                x = newX
                y = newY
            }

            background: Rectangle {
                radius: ScreenTools.defaultFontPixelHeight * 0.75
                color: "#CC700000"
                border.color: "#FFFFFF"
                border.width: 1

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 4
                    radius: 12
                    samples: 25
                    color: "#80000000"
                }
            }

            contentItem: Loader {
                sourceComponent: contentItemComponent

                property var mapClickCoord: mapClickMenu.coord
                property var popup:         mapClickMenu
            }
        }
    }

    Component {
        id: mapClickMenuComponent

        Rectangle {
            id: bgRect
            color: "#E61A0A0A"
            radius: ScreenTools.defaultFontPixelHeight * 0.5
            border.color: "#FFD700"
            border.width: 1
            opacity: 1.0

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 6
                radius: 16
                samples: 32
                color: "#A0000000"
            }

            QGCPalette { id: menuPal; colorGroupEnabled: true }

            property var    _vehicleCoord:      _root._activeVehicle ? _root._activeVehicle.coordinate : QtPositioning.coordinate()
            property real   _distanceToTarget:  _vehicleCoord.isValid ? _vehicleCoord.distanceTo(mapClickCoord) : -1
            property real   _bearingToTarget:   _vehicleCoord.isValid ? _vehicleCoord.azimuthTo(mapClickCoord) : -1
            property real   _maxGotoDistance:   _root._flyViewSettings.maxGoToLocationDistance.rawValue
            property bool   _gotoTooFar:        _distanceToTarget >= 0 && _distanceToTarget > _maxGotoDistance

            implicitWidth:  Math.max(column.implicitWidth + ScreenTools.defaultFontPixelWidth * 2.5, ScreenTools.defaultFontPixelWidth * 70)
            implicitHeight: column.implicitHeight + ScreenTools.defaultFontPixelHeight * 2

            ColumnLayout {
                id: column
                anchors.centerIn: parent
                anchors.margins: ScreenTools.defaultFontPixelWidth * 1.25
                spacing: ScreenTools.defaultFontPixelHeight * 0.6

                // --- Header label ---
                QGCLabel {
                    Layout.fillWidth: true
                    text: qsTr("MAP COMMAND")
                    font.family: ScreenTools.fixedFontFamily
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                }

                // --- Technical readout (2x2 grid of rectangles) ---
                GridLayout {
                    columns: 2
                    columnSpacing: 0
                    rowSpacing: 0
                    Layout.fillWidth: true

                    Rectangle {
                        Layout.fillWidth: true
                        height: ScreenTools.defaultFontPixelHeight * 2.6
                        color: "#CC2A2A2A"
                        border.color: "#80FFFFFF"
                        border.width: 1
                        radius: 0
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            QGCLabel { text: qsTr("LAT"); font.family: ScreenTools.fixedFontFamily; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize - 1; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                            QGCLabel { text: mapClickCoord.latitude.toFixed(6); font.family: ScreenTools.fixedFontFamily; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: ScreenTools.defaultFontPixelHeight * 2.6
                        color: "#CC2A2A2A"
                        border.color: "#80FFFFFF"
                        border.width: 1
                        radius: 0
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            QGCLabel { text: qsTr("LON"); font.family: ScreenTools.fixedFontFamily; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize - 1; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                            QGCLabel { text: mapClickCoord.longitude.toFixed(6); font.family: ScreenTools.fixedFontFamily; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: ScreenTools.defaultFontPixelHeight * 2.6
                        color: "#CC2A2A2A"
                        border.color: "#80FFFFFF"
                        border.width: 1
                        radius: 0
                        visible: globals.guidedControllerFlyView.showGotoLocation
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            QGCLabel { text: qsTr("DIST"); font.family: ScreenTools.fixedFontFamily; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize - 1; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                            QGCLabel { text: _distanceToTarget >= 0 ? (QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_distanceToTarget).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString) : qsTr("N/A"); font.family: ScreenTools.fixedFontFamily; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: ScreenTools.defaultFontPixelHeight * 2.6
                        color: "#CC2A2A2A"
                        border.color: "#80FFFFFF"
                        border.width: 1
                        radius: 0
                        visible: globals.guidedControllerFlyView.showGotoLocation
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            QGCLabel { text: qsTr("BRG"); font.family: ScreenTools.fixedFontFamily; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize - 1; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                            QGCLabel { text: _bearingToTarget >= 0 ? (_bearingToTarget.toFixed(0) + "°") : qsTr("N/A"); font.family: ScreenTools.fixedFontFamily; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }

                // --- Warning ---
                QGCLabel {
                    Layout.fillWidth: true
                    visible: globals.guidedControllerFlyView.showGotoLocation && _gotoTooFar
                    wrapMode: Text.WordWrap
                    color: "#FF6B6B"
                    font.family: ScreenTools.fixedFontFamily
                    font.bold: true
                    text: qsTr("!! TARGET BEYOND MAX RANGE (%1 %2)").arg(QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_maxGotoDistance).toFixed(0)).arg(QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString)
                }

                // --- Separator ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#40FFFFFF"
                }

                // --- Edit mode buttons ---
                QGCButton {
                    Layout.fillWidth: true
                    text: qsTr("ADD WP D%1").arg(_dwModel.count + 1)
                    visible: missionEditMode
                    onClicked: {
                        if (popup.opened) popup.close()
                        _dwModel.append({ latitude: mapClickCoord.latitude, longitude: mapClickCoord.longitude })
                        _updateDynamicPath()
                    }
                }
                QGCButton {
                    Layout.fillWidth: true
                    text: qsTr("UNDO LAST")
                    visible: missionEditMode && _dwModel.count > 0
                    onClicked: {
                        if (popup.opened) popup.close()
                        _dwModel.remove(_dwModel.count - 1, 1)
                        _updateDynamicPath()
                    }
                }
                QGCButton {
                    Layout.fillWidth: true
                    text: qsTr("CLEAR ALL (%1)").arg(_dwModel.count)
                    visible: missionEditMode && _dwModel.count > 0
                    onClicked: {
                        if (popup.opened) popup.close()
                        _dwModel.clear()
                        _updateDynamicPath()
                    }
                }

                // --- Normal mode buttons in 2-column grid ---
                GridLayout {
                    id: gridLayout
                    columns: 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth
                    rowSpacing: ScreenTools.defaultFontPixelHeight / 2
                    Layout.fillWidth: true

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 24
                        text: qsTr("FLY HERE")
                        iconSource: "/res/ArrowRight.svg"
                        visible: globals.guidedControllerFlyView.showGotoLocation
                        enabled: !_gotoTooFar
                        heightFactor: 0.6
                        Shape {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            ShapePath {
                                strokeColor: "#700000"
                                strokeWidth: 2
                                fillColor: "transparent"
                                PathAngleArc {
                                    centerX: parent.width / 2
                                    centerY: parent.height / 2
                                    radiusX: parent.width / 2
                                    radiusY: parent.height / 2
                                    startAngle: 0
                                    sweepAngle: 90
                                }
                            }
                            RotationAnimation on rotation { from: 0; to: 360; duration: 1500; loops: Animation.Infinite; running: parent.enabled }
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#4A0000" : (parent.hovered ? "#8B0000" : "#700000")
                            border.color: "#FFFFFF"
                            border.width: 1
                            radius: ScreenTools.defaultFontPixelHeight * 0.3
                        }
                        contentItem: Row {
                            property var btn: parent
                            spacing: ScreenTools.defaultFontPixelWidth / 2
                            anchors.centerIn: parent
                            QGCColoredImage {
                                source: parent.parent.iconSource
                                height: ScreenTools.defaultFontPixelHeight
                                width: height
                                color: "#FFFFFF"
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: height
                                visible: parent.parent.iconSource !== ""
                            }
                            Text {
                                text: parent.parent.text
                                color: "#FFFFFF"
                                font.family: ScreenTools.fixedFontFamily
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize - 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            if (popup.opened) popup.close()
                            gotoLocationItem.show(mapClickCoord)
                            globals.guidedControllerFlyView.confirmAction(
                                globals.guidedControllerFlyView.actionGoto,
                                mapClickCoord,
                                gotoLocationItem
                            )
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 24
                        text: qsTr("FLY HERE AT ALT")
                        iconSource: "/res/ArrowRight.svg"
                        visible: globals.guidedControllerFlyView.showGotoLocation
                        enabled: !_gotoTooFar
                        heightFactor: 0.6
                        Shape {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            ShapePath {
                                strokeColor: "#700000"
                                strokeWidth: 2
                                fillColor: "transparent"
                                PathAngleArc {
                                    centerX: parent.width / 2
                                    centerY: parent.height / 2
                                    radiusX: parent.width / 2
                                    radiusY: parent.height / 2
                                    startAngle: 0
                                    sweepAngle: 90
                                }
                            }
                            RotationAnimation on rotation { from: 0; to: 360; duration: 1500; loops: Animation.Infinite; running: parent.enabled }
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#4A0000" : (parent.hovered ? "#8B0000" : "#700000")
                            border.color: "#FFFFFF"
                            border.width: 1
                            radius: ScreenTools.defaultFontPixelHeight * 0.3
                        }
                        contentItem: Row {
                            property var btn: parent
                            spacing: ScreenTools.defaultFontPixelWidth / 2
                            anchors.centerIn: parent
                            QGCColoredImage {
                                source: parent.parent.iconSource
                                height: ScreenTools.defaultFontPixelHeight
                                width: height
                                color: "#FFFFFF"
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: height
                                visible: parent.parent.iconSource !== ""
                            }
                            Text {
                                text: parent.parent.text
                                color: "#FFFFFF"
                                font.family: ScreenTools.fixedFontFamily
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize - 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            if (popup.opened) popup.close()
                            gotoLocationItem.show(mapClickCoord)
                            globals.guidedControllerFlyView.confirmAction(
                                globals.guidedControllerFlyView.actionGotoAltitude,
                                mapClickCoord,
                                gotoLocationItem
                            )
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 24
                        text: qsTr("ORBIT")
                        iconSource: "/res/clockwise-arrow.svg"
                        visible: globals.guidedControllerFlyView.showOrbit
                        heightFactor: 0.6
                        Shape {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            ShapePath {
                                strokeColor: "#700000"
                                strokeWidth: 2
                                fillColor: "transparent"
                                PathAngleArc {
                                    centerX: parent.width / 2
                                    centerY: parent.height / 2
                                    radiusX: parent.width / 2
                                    radiusY: parent.height / 2
                                    startAngle: 0
                                    sweepAngle: 90
                                }
                            }
                            RotationAnimation on rotation { from: 0; to: 360; duration: 1500; loops: Animation.Infinite; running: parent.enabled }
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#4A0000" : (parent.hovered ? "#8B0000" : "#700000")
                            border.color: "#FFFFFF"
                            border.width: 1
                            radius: ScreenTools.defaultFontPixelHeight * 0.3
                        }
                        contentItem: Row {
                            property var btn: parent
                            spacing: ScreenTools.defaultFontPixelWidth / 2
                            anchors.centerIn: parent
                            QGCColoredImage {
                                source: parent.parent.iconSource
                                height: ScreenTools.defaultFontPixelHeight
                                width: height
                                color: "#FFFFFF"
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: height
                                visible: parent.parent.iconSource !== ""
                            }
                            Text {
                                text: parent.parent.text
                                color: "#FFFFFF"
                                font.family: ScreenTools.fixedFontFamily
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize - 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            if (popup.opened) popup.close()
                            orbitMapCircle.show(mapClickCoord)
                            globals.guidedControllerFlyView.confirmAction(
                                globals.guidedControllerFlyView.actionOrbit,
                                mapClickCoord,
                                orbitMapCircle
                            )
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 24
                        text: qsTr("ROI")
                        iconSource: "/res/target_icon"
                        visible: globals.guidedControllerFlyView.showROI
                        heightFactor: 0.6
                        Shape {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            ShapePath {
                                strokeColor: "#700000"
                                strokeWidth: 2
                                fillColor: "transparent"
                                PathAngleArc {
                                    centerX: parent.width / 2
                                    centerY: parent.height / 2
                                    radiusX: parent.width / 2
                                    radiusY: parent.height / 2
                                    startAngle: 0
                                    sweepAngle: 90
                                }
                            }
                            RotationAnimation on rotation { from: 0; to: 360; duration: 1500; loops: Animation.Infinite; running: parent.enabled }
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#4A0000" : (parent.hovered ? "#8B0000" : "#700000")
                            border.color: "#FFFFFF"
                            border.width: 1
                            radius: ScreenTools.defaultFontPixelHeight * 0.3
                        }
                        contentItem: Row {
                            property var btn: parent
                            spacing: ScreenTools.defaultFontPixelWidth / 2
                            anchors.centerIn: parent
                            QGCColoredImage {
                                source: parent.parent.iconSource
                                height: ScreenTools.defaultFontPixelHeight
                                width: height
                                color: "#FFFFFF"
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: height
                                visible: parent.parent.iconSource !== ""
                            }
                            Text {
                                text: parent.parent.text
                                color: "#FFFFFF"
                                font.family: ScreenTools.fixedFontFamily
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize - 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            if (popup.opened) popup.close()
                            globals.guidedControllerFlyView.executeAction(
                                globals.guidedControllerFlyView.actionROI,
                                mapClickCoord,
                                0,
                                false
                            )
                        }
                    }

                    QGCButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 24
                        text: qsTr("SET HOME HERE")
                        iconSource: "/res/ta_icon"
                        visible: globals.guidedControllerFlyView.showSetHome
                        heightFactor: 0.6
                        Shape {
                            anchors.centerIn: parent
                            width: parent.width + 8
                            height: parent.height + 8
                            ShapePath {
                                strokeColor: "#700000"
                                strokeWidth: 2
                                fillColor: "transparent"
                                PathAngleArc {
                                    centerX: parent.width / 2
                                    centerY: parent.height / 2
                                    radiusX: parent.width / 2
                                    radiusY: parent.height / 2
                                    startAngle: 0
                                    sweepAngle: 90
                                }
                            }
                            RotationAnimation on rotation { from: 0; to: 360; duration: 1500; loops: Animation.Infinite; running: parent.enabled }
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#4A0000" : (parent.hovered ? "#8B0000" : "#700000")
                            border.color: "#FFFFFF"
                            border.width: 1
                            radius: ScreenTools.defaultFontPixelHeight * 0.3
                        }
                        contentItem: Row {
                            property var btn: parent
                            spacing: ScreenTools.defaultFontPixelWidth / 2
                            anchors.centerIn: parent
                            QGCColoredImage {
                                source: parent.parent.iconSource
                                height: ScreenTools.defaultFontPixelHeight
                                width: height
                                color: "#FFFFFF"
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: height
                                visible: parent.parent.iconSource !== ""
                            }
                            Text {
                                text: parent.parent.text
                                color: "#FFFFFF"
                                font.family: ScreenTools.fixedFontFamily
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize - 1
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        onClicked: {
                            if (popup.opened) popup.close()
                            globals.guidedControllerFlyView.confirmAction(
                                globals.guidedControllerFlyView.actionSetHome,
                                mapClickCoord
                            )
                        }
                    }
                }

                // --- Footer ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#40FFFFFF"
                }
                QGCLabel {
                    Layout.fillWidth: true
                    text: qsTr("TAP OUTSIDE TO CLOSE")
                    font.family: ScreenTools.fixedFontFamily
                    font.pointSize: ScreenTools.defaultFontPointSize - 2
                    color: "#80FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }


    // Component {
    //     id: mapClickMenuComponent

    //     ColumnLayout {
    //         id: mainLayout
    //         spacing: ScreenTools.defaultFontPixelWidth / 2

    //         QGCButton {
    //             Layout.fillWidth:   true
    //             text:               qsTr("Go to location")
    //             visible:            globals.guidedControllerFlyView.showGotoLocation
    //             onClicked: {
    //                 if (popup.opened) {
    //                     popup.close()
    //                 }
    //                 gotoLocationItem.show(mapClickCoord)
    //                 globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionGoto, mapClickCoord, gotoLocationItem)
    //             }
    //         }

    //         QGCButton {
    //             Layout.fillWidth:   true
    //             text:               qsTr("Orbit at location")
    //             visible:            globals.guidedControllerFlyView.showOrbit
    //             onClicked: {
    //                 if (popup.opened) {
    //                     popup.close()
    //                 }
    //                 orbitMapCircle.show(mapClickCoord)
    //                 globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionOrbit, mapClickCoord, orbitMapCircle)
    //             }
    //         }

    //         QGCButton {
    //             Layout.fillWidth:   true
    //             text:               qsTr("ROI at location")
    //             visible:            globals.guidedControllerFlyView.showROI
    //             onClicked: {
    //                 if (popup.opened) {
    //                     popup.close()
    //                 }
    //                 globals.guidedControllerFlyView.executeAction(globals.guidedControllerFlyView.actionROI, mapClickCoord, 0, false)
    //             }
    //         }

    //         QGCButton {
    //             Layout.fillWidth:   true
    //             text:               qsTr("Set home here")
    //             visible:            globals.guidedControllerFlyView.showSetHome
    //             onClicked: {
    //                 if (popup.opened) {
    //                     popup.close()
    //                 }
    //                 globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionSetHome, mapClickCoord)
    //             }
    //         }

    //         ColumnLayout {
    //             spacing: 0
    //             QGCLabel { text: qsTr("Lat: %1").arg(mapClickCoord.latitude.toFixed(6)) }
    //             QGCLabel { text: qsTr("Lon: %1").arg(mapClickCoord.longitude.toFixed(6)) }
    //         }
    //     }
    // }

    Component {
        id: roiEditPositionDialogComponent

        EditPositionDialog {
            title:                  qsTr("Edit ROI Position")
            coordinate:             roiLocationItem.coordinate
            onCoordinateChanged: {
                roiLocationItem.coordinate = coordinate
                _activeVehicle.guidedModeROI(coordinate)
            }
        }
    }

    Component {
        id: roiEditMenuComponent

        ColumnLayout {
            id: mainLayout
            spacing: ScreenTools.defaultFontPixelWidth / 2

            QGCButton {
                Layout.fillWidth:   true
                text:               qsTr("Cancel ROI")
                onClicked: {
                    _activeVehicle.stopGuidedModeROI()
                    popup.close()
                }
            }

            QGCButton {
                Layout.fillWidth:   true
                text:               qsTr("Edit Position")
                onClicked: {         
                    roiEditPositionDialogComponent.createObject(mainWindow, { showSetPositionFromVehicle: false }).open()
                    popup.close()
                }
            }
        }
    }

    // --- Dynamic Mission Edit Controls ---
    // Rectangle {
    //     id:             _editPanel
    //     anchors.verticalCenter:    parent.verticalCenter
    //     anchors.left:  parent.left
    //     anchors.margins: ScreenTools.defaultFontPixelWidth
    //     width:          _editColumn.width + ScreenTools.defaultFontPixelWidth * 2
    //     height:         _editColumn.height + ScreenTools.defaultFontPixelHeight
    //     radius:         ScreenTools.defaultFontPixelHeight / 4
    //     color:          qgcPal.window
    //     border.color:   qgcPal.text
    //     z:              QGroundControl.zOrderTopMost

    //     ColumnLayout {
    //         id:         _editColumn
    //         anchors.centerIn: parent
    //         spacing:    ScreenTools.defaultFontPixelWidth / 2

    //         QGCButton {
    //             text: missionEditMode ?
    //                 qsTr("Execute Plan (%1)").arg(_dwModel.count) :
    //                 qsTr("Edit Mission")
    //             enabled: !missionEditMode || _dwModel.count > 0
    //             onClicked: {
    //                 if (!missionEditMode) {
    //                     missionEditMode = true
    //                     _oldRemainingPath = []
    //                     _dynamicPath = []
    //                 } else {
    //                     var missionController = _planMasterController.missionController
    //                     _pendingInsertIndex = missionController.currentMissionIndex + 1
    //                     // Capture old remaining waypoints BEFORE insertion
    //                     var oldPath = []
    //                     for (var j = _pendingInsertIndex; j < missionController.visualItems.count; j++) {
    //                         var vi = missionController.visualItems.get(j)
    //                         if (vi.coordinate && vi.coordinate.isValid) {
    //                             oldPath.push(vi.coordinate)
    //                         }
    //                     }
    //                     _oldRemainingPath = oldPath
    //                     // Insert dynamic waypoints into mission
    //                     for (var i = 0; i < _dwModel.count; i++) {
    //                         var item = _dwModel.get(i)
    //                         var coord = QtPositioning.coordinate(item.latitude, item.longitude)
    //                         missionController.insertSimpleMissionItem(coord, _pendingInsertIndex + i, false)
    //                     }
    //                     _planMasterController.sendToVehicle()
    //                     missionEditMode = false
    //                     _dwModel.clear()
    //                 }
    //             }
    //         }

            // QGCButton {
            //     text: qsTr("Cancel Edit")
            //     visible: missionEditMode
            //     onClicked: {
            //         missionEditMode = false
            //         _dwModel.clear()
            //         _pendingInsertIndex = -1
            //         _oldRemainingPath = []
            //         _dynamicPath = []
            //     }
            // }
    //     }
    // }

    // Rectangle {
    //     width: colLay.width + ScreenTools.defaultFontPixelWidth
    //     height: colLay.height + ScreenTools.defaultFontPixelHeight
    //     anchors.right: parent.right
    //     anchors.verticalCenter: ScreenTools.isMobile ? undefined : parent.verticalCenter
    //     anchors.bottom: ScreenTools.isMobile ? parent.bottom : undefined
    //     anchors.bottomMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : undefined
    //     color: qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
    //     anchors.margins: ScreenTools.defaultFontPixelWidth
    //     radius: ScreenTools.defaultFontPixelWidth / 2

    //     ColumnLayout {
    //         id: colLay
    //         anchors.centerIn: parent
    //         QGCColoredImage {
    //             id: dyn_bnutton
    //             // text: missionEditMode ?
    //             //     qsTr("Execute Plan (%1)").arg(_dwModel.count) :
    //             //     qsTr("Edit Mission")
    //             source: missionEditMode ? "/res/exe_icon" :"/res/dy_icon"
    //             enabled: !missionEditMode || _dwModel.count > 0
    //             width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 3.2 : ScreenTools.defaultFontPixelWidth * 5
    //             height: width
    //             Layout.fillWidth: true

    //             QGCMouseArea {
    //                 anchors.fill: parent
    //                 onClicked: {
    //                     if (!missionEditMode) {
    //                         missionEditMode = true
    //                         _oldRemainingPath = []
    //                         _dynamicPath = []
    //                         _firstDynamicSeq = -1
    //                         _lastDynamicSeq = -1
    //                         _dynamicCompleted = false
    //                         _persistentDWModel.clear()
    //                         _oldRemainingWPModel.clear()
    //                     } else {
    //                         var missionController = _planMasterController.missionController
    //                         _pendingInsertIndex = missionController.currentMissionIndex + 1
    //                         _firstDynamicSeq = _pendingInsertIndex
    //                         _lastDynamicSeq = _pendingInsertIndex + _dwModel.count - 1
    //                         _dynamicCompleted = false
    //                         // Capture old remaining waypoints BEFORE insertion
    //                         var oldPath = []
    //                         _oldRemainingWPModel.clear()
    //                         for (var j = _pendingInsertIndex; j < missionController.visualItems.count; j++) {
    //                             var vi = missionController.visualItems.get(j)
    //                             if (vi.coordinate && vi.coordinate.isValid) {
    //                                 oldPath.push(vi.coordinate)
    //                                 _oldRemainingWPModel.append({
    //                                     latitude: vi.coordinate.latitude,
    //                                     longitude: vi.coordinate.longitude,
    //                                     originalSeq: vi.sequenceNumber
    //                                 })
    //                             }
    //                         }
    //                         _oldRemainingPath = oldPath
    //                         // Insert dynamic waypoints into mission
    //                         for (var i = 0; i < _dwModel.count; i++) {
    //                             var item = _dwModel.get(i)
    //                             var coord = QtPositioning.coordinate(item.latitude, item.longitude)
    //                             missionController.insertSimpleMissionItem(coord, _pendingInsertIndex + i, false)
    //                         }
    //                         _planMasterController.sendToVehicle()
    //                         missionEditMode = false
    //                         // Save persistent D markers
    //                         _persistentDWModel.clear()
    //                         for (var k = 0; k < _dwModel.count; k++) {
    //                             var dw = _dwModel.get(k)
    //                             _persistentDWModel.append({ latitude: dw.latitude, longitude: dw.longitude })
    //                         }
    //                         _dwModel.clear()
    //                     }
    //                 }
    //             }
    //         }

    //         QGCLabel {
    //             text: missionEditMode ?
    //                 qsTr("Execute")/*.arg(_dwModel.count)*/ :
    //                 qsTr("Edit")
    //             Layout.fillWidth: true
    //             font.pointSize: ScreenTools.smallFontPointSize
    //             //visible: missionEditMode
    //         }

    //         QGCColoredImage {
    //             //text: qsTr("Cancel Edit")
    //             source:             "/res/XDelete.svg"
    //             Layout.fillWidth: true
    //             width: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 3.2 : ScreenTools.defaultFontPixelWidth * 5
    //             height: width
    //             visible: missionEditMode

    //             QGCMouseArea {
    //                 anchors.fill: parent
    //                 onClicked: {
    //                     missionEditMode = false
    //                     _dwModel.clear()
    //                     _pendingInsertIndex = -1
    //                     _oldRemainingPath = []
    //                     _dynamicPath = []
    //                     _firstDynamicSeq = -1
    //                     _lastDynamicSeq = -1
    //                     _dynamicCompleted = false
    //                     _persistentDWModel.clear()
    //                     _oldRemainingWPModel.clear()
    //                 }
    //             }
    //         }

    //         QGCLabel {
    //             text: "Cancel"
    //             Layout.fillWidth: true
    //             visible: missionEditMode
    //             font.pointSize: ScreenTools.smallFontPointSize
    //         }
    //     }
    // }

    // Connections {
    //     target: _planMasterController ? _planMasterController.missionController : null
    //     onSendComplete: {
    //         if (_pendingInsertIndex > 0) {
    //             _activeVehicle.setCurrentMissionSequence(_pendingInsertIndex)
    //             _pendingInsertIndex = -1
    //         }
    //     }
    // }

    // // Monitor dynamic mission progress
    // Timer {
    //     id: _dynamicMonitor
    //     interval: 200
    //     running: _firstDynamicSeq > 0 && !missionEditMode
    //     repeat: true
    //     onTriggered: {
    //         if (!_dynamicCompleted && _activeVehicle) {
    //             var cur = _planMasterController.missionController.currentMissionIndex
    //             if (cur > _lastDynamicSeq) {
    //                 _dynamicCompleted = true
    //                 _activeVehicle.setCurrentMissionSequence(_lastDynamicSeq)
    //                 _holdTimer.start()
    //                 _completionDialog.open()
    //             }
    //         }
    //     }
    // }

    // // Hold position by repeatedly targeting the last dynamic WP
    // Timer {
    //     id: _holdTimer
    //     interval: 500
    //     repeat: true
    //     running: false
    //     onTriggered: {
    //         if (_completionDialog.visible && _firstDynamicSeq > 0) {
    //             _activeVehicle.setCurrentMissionSequence(_lastDynamicSeq)
    //         }
    //     }
    // }

    // // Completion dialog
    // Popup {
    //     id: _completionDialog
    //     modal: true
    //     closePolicy: Popup.NoAutoClose
    //     x: (parent.width - width) / 2
    //     y: (parent.height - height) / 2
    //     width: ScreenTools.defaultFontPixelWidth * 30
    //     background: Rectangle {
    //         color: qgcPal.window
    //         radius: ScreenTools.defaultFontPixelHeight / 4
    //     }
    //     ColumnLayout {
    //         anchors.centerIn: parent
    //         spacing: ScreenTools.defaultFontPixelWidth
    //         QGCLabel {
    //             text: qsTr("Dynamic mission completed")
    //             font.bold: true
    //             font.pointSize: ScreenTools.defaultFontPointSize + 2
    //         }
    //         QGCLabel {
    //             text: qsTr("Choose next action:")
    //         }
    //         RowLayout {
    //             spacing: ScreenTools.defaultFontPixelWidth
    //             QGCButton {
    //                 text: qsTr("Replay Dynamic")
    //                 onClicked: {
    //                     _holdTimer.stop()
    //                     _activeVehicle.setCurrentMissionSequence(_firstDynamicSeq)
    //                     _dynamicCompleted = false
    //                     _completionDialog.close()
    //                 }
    //             }
    //             QGCButton {
    //                 text: qsTr("Resume Original")
    //                 onClicked: {
    //                     _holdTimer.stop()
    //                     _activeVehicle.setCurrentMissionSequence(_lastDynamicSeq + 1)
    //                     _completionDialog.close()
    //                 }
    //             }
    //         }
    //     }
    // }

    // Dynamic mission path (green, shown after Execute)
    MapPolyline {
        line.width: 4
        line.color: Qt.rgba(0, 1, 0, 0.8)
        z: QGroundControl.zOrderWaypointLines + 2
        visible: _dynamicPath.length > 0
        path: _dynamicPath
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       parent.left
        anchors.top:        parent.top
        mapControl:         _root
        buttonsOnLeft:      true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.windowState

        property real centerInset: visible ? parent.height - y : 0
    }

}
