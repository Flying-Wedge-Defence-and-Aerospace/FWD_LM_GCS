/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick                          2.11
import QtQuick.Controls                 2.4
import QtQuick.Layouts 1.3

import QGroundControl                   1.0
import QGroundControl.FlightDisplay     1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0

Item {
    id:     root
    clip:   true

    property bool useSmallFont: true

    property double _ar:                QGroundControl.videoManager.aspectRatio
    property bool   _showGrid:          QGroundControl.settingsManager.videoSettings.gridLines.rawValue > 0
    property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
    property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
    property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
    property bool   _hasZoom:           _camera && _camera.hasZoom
    property int    _fitMode:           QGroundControl.settingsManager.videoSettings.videoFit.rawValue
    property real videoW: 1280
    property real videoH: 720

    property bool isFollowingTarget: false

    function getWidth() {
        return videoBackground.getWidth()
    }
    function getHeight() {
        return videoBackground.getHeight()
    }

    property double _thermalHeightFactor: 0.85 //-- TODO


    Image {
        id:             noVideo
        anchors.fill:   parent
        source:         "/res/NoVideoBackground.jpg"
        fillMode:       Image.PreserveAspectFill
        visible:        !(QGroundControl.videoManager.decoding)

        Rectangle {
            anchors.centerIn:   parent
            width:              noVideoLabel.contentWidth + ScreenTools.defaultFontPixelHeight
            height:             noVideoLabel.contentHeight + ScreenTools.defaultFontPixelHeight
            radius:             ScreenTools.defaultFontPixelWidth / 2
            color:              "black"
            opacity:            0.5
        }

        QGCLabel {
            id:                 noVideoLabel
            text:               QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue ? qsTr("WAITING FOR VIDEO") : qsTr("VIDEO DISABLED")
            font.family:        ScreenTools.demiboldFontFamily
            color:              "white"
            font.pointSize:     useSmallFont ? ScreenTools.smallFontPointSize : ScreenTools.largeFontPointSize
            anchors.centerIn:   parent
        }
    }

    Rectangle {
        id:             videoBackground
        anchors.fill:   parent
        color:          "black"
        visible:        QGroundControl.videoManager.decoding
        clip: true
        function getWidth() {
            //-- Fit Width or Stretch
            if(_fitMode === 0 || _fitMode === 2) {
                return parent.width
            }
            //-- Fit Height
            return _ar != 0.0 ? parent.height * _ar : parent.width
        }
        function getHeight() {
            //-- Fit Height or Stretch
            if(_fitMode === 1 || _fitMode === 2) {
                return parent.height
            }
            //-- Fit Width
            return _ar != 0.0 ? parent.width * (1 / _ar) : parent.height
        }

        // Component.onCompleted: {
        //     console.log("Video BG size:", width, height)
        // }
        // onWidthChanged:  console.log("Video BG width:", width)
        // onHeightChanged: console.log("Video BG height:", height)

        Component {
            id: videoBackgroundComponent

            QGCVideoBackground {
                id: videoContent
                anchors.centerIn: parent
                objectName: "videoContent"

                property real vx: 0
                property real vy: 0
                property real vw: width
                property real vh: height

                function updateVideoRect() {
                    if (_ar <= 0 || width <= 0 || height <= 0)
                        return

                    var videoAR = _ar
                    var itemAR = width / height

                    if (itemAR > videoAR) {
                        // pillarbox: black bars left/right
                        vh = height
                        vw = vh * videoAR
                        vx = (width - vw) / 2
                        vy = 0
                    } else {
                        // letterbox: black bars top/bottom
                        vw = width
                        vh = vw / videoAR
                        vx = 0
                        vy = (height - vh) / 2
                    }

                    // Resize video to fit rectangle exactly
                    videoContent.width = vw
                    videoContent.height = vh
                    videoContent.x = vx
                    videoContent.y = vy
                }

                onWidthChanged: updateVideoRect()
                onHeightChanged: updateVideoRect()
                Component.onCompleted: updateVideoRect()

                // Red rectangle
                Rectangle {
                    x: vx
                    y: vy
                    width: vw
                    height: vh
                    color: "transparent"
                    border.color: "red"
                    border.width: 2
                    z: 999
                }
            }
        }

        Loader {
            // GStreamer is causing crashes on Lenovo laptop OpenGL Intel drivers. In order to workaround this
            // we don't load a QGCVideoBackground object when video is disabled. This prevents any video rendering
            // code from running. Setting QGCVideoBackground.receiver = null does not work to prevent any
            // video OpenGL from being generated. Hence the Loader to completely remove it.
            //height:             parent.getHeight()
            //width:              parent.getWidth()
            // width:  videoBackground.width
            // height: videoBackground.height
            anchors.fill:   parent
            visible:            QGroundControl.videoManager.decoding
            sourceComponent:    videoBackgroundComponent

            property bool videoDisabled: QGroundControl.settingsManager.videoSettings.videoSource.rawValue === QGroundControl.settingsManager.videoSettings.disabledVideoSource
        }

        //-- Thermal Image
        Item {
            id:                 thermalItem
            width:              height * QGroundControl.videoManager.thermalAspectRatio
            height:             _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_FULL ? parent.height : (_camera.thermalMode === QGCCameraControl.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
            anchors.centerIn:   parent
            visible:            QGroundControl.videoManager.hasThermal && _camera.thermalMode !== QGCCameraControl.THERMAL_OFF
            function pipOrNot() {
                if(_camera) {
                    if(_camera.thermalMode === QGCCameraControl.THERMAL_PIP) {
                        anchors.centerIn    = undefined
                        anchors.top         = parent.top
                        anchors.topMargin   = mainWindow.header.height + (ScreenTools.defaultFontPixelHeight * 0.5)
                        anchors.left        = parent.left
                        anchors.leftMargin  = ScreenTools.defaultFontPixelWidth * 12
                    } else {
                        anchors.top         = undefined
                        anchors.topMargin   = undefined
                        anchors.left        = undefined
                        anchors.leftMargin  = undefined
                        anchors.centerIn    = parent
                    }
                }
            }
            Connections {
                target:                 _camera
                onThermalModeChanged:   thermalItem.pipOrNot()
            }
            onVisibleChanged: {
                thermalItem.pipOrNot()
            }
            QGCVideoBackground {
                id:             thermalVideo
                objectName:     "ther   malVideo"
                anchors.fill:   parent
                receiver:       QGroundControl.videoManager.thermalVideoReceiver
                opacity:        _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
            }
        }
        //-- Zoom
        PinchArea {
            id:             pinchZoom
            enabled:        _hasZoom
            anchors.fill:   parent
            onPinchStarted: pinchZoom.zoom = 0
            onPinchUpdated: {
                if(_hasZoom) {
                    var z = 0
                    if(pinch.scale < 1) {
                        z = Math.round(pinch.scale * -10)
                    } else {
                        z = Math.round(pinch.scale)
                    }
                    if(pinchZoom.zoom != z) {
                        _camera.stepZoom(z)
                    }
                }
            }
            property int zoom: 0
        }
    }

    // function getTrackingStatus() {
    //     var xhr = new XMLHttpRequest()
    //     xhr.open("GET", "http://192.168.144.60:8000/track_status")

    //     xhr.onreadystatechange = function () {
    //         if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
    //             getTracking =
    //                 JSON.parse(xhr.responseText).enabled
    //         }
    //     }

    //     xhr.send()
    // }
}


































// import QtQuick                          2.11
// import QtQuick.Controls                 2.4

// import QGroundControl                   1.0
// import QGroundControl.FlightDisplay     1.0
// import QGroundControl.FlightMap         1.0
// import QGroundControl.ScreenTools       1.0
// import QGroundControl.Controls          1.0
// import QGroundControl.Palette           1.0
// import QGroundControl.Vehicle           1.0
// import QGroundControl.Controllers       1.0

// Item {
//     id:     root
//     clip:   true

//     property bool useSmallFont: true

//     property double _ar:                QGroundControl.videoManager.aspectRatio
//     property bool   _showGrid:          QGroundControl.settingsManager.videoSettings.gridLines.rawValue > 0
//     property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
//     property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
//     property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
//     property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
//     property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
//     property bool   _hasZoom:           _camera && _camera.hasZoom
//     property int    _fitMode:           QGroundControl.settingsManager.videoSettings.videoFit.rawValue
//     property real videoW: 1280
//     property real videoH: 720

//     property bool isMouseMoving: false

//     property bool _isTrackingEnabled: false
//     property bool getTracking: false

//     property bool isFollowing: false

//     // function getWidth() {
//     //     return videoBackground.getWidth()
//     // }
//     // function getHeight() {
//     //     return videoBackground.getHeight()
//     // }

//     property double _thermalHeightFactor: 0.85 //-- TODO



//     Rectangle {
//         id: buttonRect
//         width: followButton.width
//         height: followButton.height + (ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight : (ScreenTools.defaultFontPixelHeight / 3))
//         anchors.top: parent.top
//         anchors.right: parent.right
//         anchors.topMargin: /*ScreenTools.toolbarHeight - */ScreenTools.defaultFontPixelWidth * 3
//         anchors.rightMargin: ScreenTools.defaultFontPixelWidth
//         color: "green"
//         z: 999
//         //radius: height / 2

//         QGCToolBarButton {
//             id: followButton
//             icon.source: isFollowing ? "/res/following_icon" : "/res/follow_icon"
//             anchors.fill: parent
//             z: 999

//             onClicked: {
//                 if(!isFollowing) {
//                     isFollowing = true
//                     _isTrackingEnabled = true
//                 } else {
//                     isFollowing = false
//                     _isTrackingEnabled = false
//                 }
//                 sendTrackingStatus(_isTrackingEnabled)
//             }
//         }
//     }

//     Image {
//         id:             noVideo
//         anchors.fill:   parent
//         source:         "/res/NoVideoBackground.jpg"
//         fillMode:       Image.PreserveAspectFill
//         visible:        !(QGroundControl.videoManager.decoding)

//         Rectangle {
//             anchors.centerIn:   parent
//             width:              noVideoLabel.contentWidth + ScreenTools.defaultFontPixelHeight
//             height:             noVideoLabel.contentHeight + ScreenTools.defaultFontPixelHeight
//             radius:             ScreenTools.defaultFontPixelWidth / 2
//             color:              "black"
//             opacity:            0.5
//         }

//         QGCLabel {
//             id:                 noVideoLabel
//             text:               QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue ? qsTr("WAITING FOR VIDEO") : qsTr("VIDEO DISABLED")
//             font.family:        ScreenTools.demiboldFontFamily
//             color:              "white"
//             font.pointSize:     useSmallFont ? ScreenTools.smallFontPointSize : ScreenTools.largeFontPointSize
//             anchors.centerIn:   parent
//         }
//     }

//     Rectangle {
//         id:             videoBackground
//         anchors.fill:   parent
//         color:          "black"
//         visible:        QGroundControl.videoManager.decoding
//         clip: true
//         function getWidth() {
//             //-- Fit Width or Stretch
//             if(_fitMode === 0 || _fitMode === 2) {
//                 return parent.width
//             }
//             //-- Fit Height
//             return _ar != 0.0 ? parent.height * _ar : parent.width
//         }
//         function getHeight() {
//             //-- Fit Height or Stretch
//             if(_fitMode === 1 || _fitMode === 2) {
//                 return parent.height
//             }
//             //-- Fit Width
//             return _ar != 0.0 ? parent.width * (1 / _ar) : parent.height
//         }

//         Component {
//             id: videoBackgroundComponent

//             QGCVideoBackground {
//                 id: videoContent
//                 anchors.centerIn: parent
//                 objectName: "videoContent"

//                 property real vx: 0
//                 property real vy: 0
//                 property real vw: width
//                 property real vh: height

//                 function updateVideoRect() {
//                     if (_ar <= 0 || width <= 0 || height <= 0)
//                         return

//                     var videoAR = _ar
//                     var itemAR = width / height

//                     if (itemAR > videoAR) {
//                         // pillarbox: black bars left/right
//                         vh = height
//                         vw = vh * videoAR
//                         vx = (width - vw) / 2
//                         vy = 0
//                     } else {
//                         // letterbox: black bars top/bottom
//                         vw = width
//                         vh = vw / videoAR
//                         vx = 0
//                         vy = (height - vh) / 2
//                     }

//                     // Resize video to fit rectangle exactly
//                     videoContent.width = vw
//                     videoContent.height = vh
//                     videoContent.x = vx
//                     videoContent.y = vy
//                 }

//                 onWidthChanged: updateVideoRect()
//                 onHeightChanged: updateVideoRect()
//                 Component.onCompleted: updateVideoRect()

//                 // Red rectangle
//                 Rectangle {
//                     x: vx
//                     y: vy
//                     width: vw
//                     height: vh
//                     color: "transparent"
//                     border.color: "red"
//                     border.width: 2
//                     z: 999
//                 }

//                 MouseArea {
//                     anchors.fill: parent
//                     z: 1000

//                     property real pressX: 0
//                     property real pressY: 0
//                     property bool dragging: false
//                     property real dragThreshold: 8   // pixels

//                     function insideVideo(mx, my) {
//                         return !(mx < vx || mx > vx + vw || my < vy || my > vy + vh)
//                     }

//                     function normX(mx) {
//                         return Math.max(0, Math.min(1, (mx - vx) / vw))
//                     }

//                     function normY(my) {
//                         return Math.max(0, Math.min(1, (my - vy) / vh))
//                     }

//                     onPressed: {
//                         if (!_isTrackingEnabled || !insideVideo(mouse.x, mouse.y))
//                             return

//                         pressX = mouse.x
//                         pressY = mouse.y
//                         dragging = false
//                     }

//                     onPositionChanged: {
//                         var dx = mouse.x - pressX
//                         var dy = mouse.y - pressY
//                         if (Math.sqrt(dx*dx + dy*dy) > dragThreshold)
//                             dragging = true
//                     }

//                     onReleased: {
//                         if (!_isTrackingEnabled || !insideVideo(mouse.x, mouse.y))
//                             return

//                         var x1 = normX(pressX)
//                         console.log("x1 is", x1)
//                         var y1 = normY(pressY)
//                         console.log("x2 is", y1)
//                         var x2 = normX(mouse.x)
//                         console.log("x2 is", x2)
//                         var y2 = normY(mouse.y)
//                         console.log("y2 is", y2)

//                         if (dragging) {
//                             console.log("It comes sendDragfunction")
//                             sendDrag(x1, y1, x2, y2)
//                         } else {
//                             console.log("It comes sendPointfunction")
//                             sendPoint(x2, y2)
//                         }
//                     }

//                     function sendPoint(x, y) {
//                         var xhr = new XMLHttpRequest()
//                         xhr.open("POST", "http://192.168.144.60:8000/track_point")
//                         xhr.setRequestHeader("Content-Type", "application/json")
//                         xhr.send(JSON.stringify({
//                             x_norm: x,
//                             y_norm: y,
//                             video_width: vw,
//                             video_height: vh
//                         }))
//                     }

//                     function sendDrag(x1, y1, x2, y2) {
//                         var xhr = new XMLHttpRequest()
//                         xhr.open("POST", "http://192.168.144.60:8000/drag_point")
//                         xhr.setRequestHeader("Content-Type", "application/json")
//                         xhr.send(JSON.stringify({
//                             x1_norm: x1,
//                             y1_norm: y1,
//                             x2_norm: x2,
//                             y2_norm: y2,
//                             video_width: vw,
//                             video_height: vh
//                         }))
//                     }
//                 }
//             }
//         }

//         Loader {
//             // GStreamer is causing crashes on Lenovo laptop OpenGL Intel drivers. In order to workaround this
//             // we don't load a QGCVideoBackground object when video is disabled. This prevents any video rendering
//             // code from running. Setting QGCVideoBackground.receiver = null does not work to prevent any
//             // video OpenGL from being generated. Hence the Loader to completely remove it.
//             //height:             parent.getHeight()
//             //width:              parent.getWidth()
//             // width:  videoBackground.width
//             // height: videoBackground.height
//             anchors.fill:   parent
//             visible:            QGroundControl.videoManager.decoding
//             sourceComponent:    videoBackgroundComponent

//             property bool videoDisabled: QGroundControl.settingsManager.videoSettings.videoSource.rawValue === QGroundControl.settingsManager.videoSettings.disabledVideoSource
//         }

//         //-- Thermal Image
//         Item {
//             id:                 thermalItem
//             width:              height * QGroundControl.videoManager.thermalAspectRatio
//             height:             _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_FULL ? parent.height : (_camera.thermalMode === QGCCameraControl.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
//             anchors.centerIn:   parent
//             visible:            QGroundControl.videoManager.hasThermal && _camera.thermalMode !== QGCCameraControl.THERMAL_OFF
//             function pipOrNot() {
//                 if(_camera) {
//                     if(_camera.thermalMode === QGCCameraControl.THERMAL_PIP) {
//                         anchors.centerIn    = undefined
//                         anchors.top         = parent.top
//                         anchors.topMargin   = mainWindow.header.height + (ScreenTools.defaultFontPixelHeight * 0.5)
//                         anchors.left        = parent.left
//                         anchors.leftMargin  = ScreenTools.defaultFontPixelWidth * 12
//                     } else {
//                         anchors.top         = undefined
//                         anchors.topMargin   = undefined
//                         anchors.left        = undefined
//                         anchors.leftMargin  = undefined
//                         anchors.centerIn    = parent
//                     }
//                 }
//             }
//             Connections {
//                 target:                 _camera
//                 onThermalModeChanged:   thermalItem.pipOrNot()
//             }
//             onVisibleChanged: {
//                 thermalItem.pipOrNot()
//             }
//             QGCVideoBackground {
//                 id:             thermalVideo
//                 objectName:     "ther   malVideo"
//                 anchors.fill:   parent
//                 receiver:       QGroundControl.videoManager.thermalVideoReceiver
//                 opacity:        _camera ? (_camera.thermalMode === QGCCameraControl.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
//             }
//         }
//         //-- Zoom
//         PinchArea {
//             id:             pinchZoom
//             enabled:        _hasZoom
//             anchors.fill:   parent
//             onPinchStarted: pinchZoom.zoom = 0
//             onPinchUpdated: {
//                 if(_hasZoom) {
//                     var z = 0
//                     if(pinch.scale < 1) {
//                         z = Math.round(pinch.scale * -10)
//                     } else {
//                         z = Math.round(pinch.scale)
//                     }
//                     if(pinchZoom.zoom != z) {
//                         _camera.stepZoom(z)
//                     }
//                 }
//             }
//             property int zoom: 0
//         }
//     }


//     function sendTrackingStatus(enabled) {
//         var xhr = new XMLHttpRequest()
//         xhr.open("POST", "http://192.168.144.60:8000/track_status")
//         xhr.setRequestHeader("Content-Type", "application/json")

//         xhr.onreadystatechange = function () {
//             if (xhr.readyState === XMLHttpRequest.DONE) {
//                 if (xhr.status === 200) {
//                     console.log("Tracking status sent:", enabled)
//                 } else {
//                     console.log("HTTP error:", xhr.status)
//                 }
//             }
//         }

//         var payload = {
//             trackingStatus: enabled
//         }

//         xhr.send(JSON.stringify(payload))
//     }



//     // function getTrackingStatus() {
//     //     var xhr = new XMLHttpRequest()
//     //     xhr.open("GET", "http://192.168.144.60:8000/track_status")

//     //     xhr.onreadystatechange = function () {
//     //         if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
//     //             getTracking =
//     //                 JSON.parse(xhr.responseText).enabled
//     //         }
//     //     }

//     //     xhr.send()
//     // }

// }\





// QGCToolBarButton {
//     id: followButton
//     icon.source: isFollowing ? "/res/following_icon" : "/res/follow_icon"
//     anchors.fill: parent
//     z: 999

//     onClicked: {
//         if(!isFollowing) {
//             isFollowing = true
//             _isTrackingEnabled = true
//         } else {
//             isFollowing = false
//             _isTrackingEnabled = false
//         }
//         sendTrackingStatus(_isTrackingEnabled)
//     }
// }
