import QtQuick 2.12
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

Item {
    id:         _root
    visible:    QGroundControl.videoManager.hasVideo

    property bool isTheVideoFull: false

    property int    _track_rec_x:       0
    property int    _track_rec_y:       0

    signal requestTrackAndDrag()

    property bool _isTrackingEnabled: false
    property bool getTracking: false

    property bool isFollowing: false

    property int followState: 0
    property bool holdModeEnabled: false

    property real pressX: 0
    property real pressY: 0
    property real lastX: 0
    property real lastY: 0
    property var vw
    property var vh

    property string videoMode: "Zoom"

    property var    _videoStreamManager:                        QGroundControl.videoManager

    property var p: 0
    property bool showZoomControls: false
    property bool showGimbalControls: false
    property bool showVideoOptions: false
    property bool showThermalOptions: false
    property bool showColorCombo: false

    property bool isThermalMode: false

    property bool isStartTakeVideo: false
    property bool isFollowingTarget: false

    property real dragThreshold: 8
    property bool dragging: false

    property bool isLeftMenuVisible: true
    property bool isRightMenuVisible: true

    property bool isLaserOn: false
    property bool isMeasureOn: false

    function normalizedVideoPoint(mx, my) {
        vw = videoStreaming.getWidth()
        vh = videoStreaming.getHeight()

        var ox = (width  - vw) / 2
        var oy = (height - vh) / 2

        var x = Math.max(0, Math.min(mx - ox, vw))
        var y = Math.max(0, Math.min(my - oy, vh))

        //if(x >= 0 && x <= 1 && y >= 0 && y <= 1) {
            return Qt.point(x / vw, y / vh)
        //} else {
          //  return -1
        //}
    }

    QGCColoredImage {
        id: targetButton
        anchors.centerIn: parent
        height:     ScreenTools.defaultFontPixelHeight * 5
        width:      height
        source:     "/res/ta_icon"
        color:      "green"
        visible: isLaserOn
        z: 9999
    }

    Rectangle {
        id: hideRect
        z: 1000
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 5
        anchors.topMargin: ScreenTools.defaultFontPixelWidth * 4
        width: /*ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 3.4 :*/ rect1.width   // Rectangle size
        height: width / 2.3
        //radius: 5
        visible: _root.isTheVideoFull && QGroundControl.videoManager.decoding
        color: "#55ffffff"

        QGCColoredImage {
            id: lhbut
            anchors.centerIn: parent
            width: parent.width * 0.75
            height: width
            source: isLeftMenuVisible ? "/res/cheveron-up.svg" : "/res/cheveron-down.svg"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(isLeftMenuVisible === true) {
                    isLeftMenuVisible = false
                    showThermalOptions = false
                    showVideoOptions = false
                    showColorCombo = false
                    showGimbalControls = false
                } else {
                    isLeftMenuVisible = true
                }
            }
        }
    }

    Rectangle {
        id: rect1
        color: "#55ffffff"
        //anchors.top: parent.top
        anchors.top: hideRect.bottom
        anchors.left: parent.left
        //anchors.topMargin: ScreenTools.defaultFontPixelWidth
        anchors.topMargin: /*ScreenTools.defaultFontPixelWidth * 4*/ 12
        anchors.leftMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 5
        width: ScreenTools.defaultFontPixelWidth * 8
        implicitHeight: leftLayout.height + ScreenTools.defaultFontPixelHeight / 2
        visible: _root.isTheVideoFull && QGroundControl.videoManager.decoding
        opacity: isLeftMenuVisible ? 1 : 0
        z: 999
        //radius: ScreenTools.defaultFontPixelWidth

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        ColumnLayout {
            id: leftLayout
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            visible: isLeftMenuVisible && QGroundControl.videoManager.decoding

            QGCToolBarButton {
                z: 999
                normalIconColor: "black"
                text: "Track"
                font.pointSize: 8

                icon.source: {
                    switch (followState) {
                    case 0: return "/res/ufIcon"
                    case 1: return "/res/follow_icon"
                    case 2: return "/res/hold_icon"
                    }
                }

                onClicked: {
                    followState = (followState + 1) % 3
                    console.log("Follow state", followState)

                    _isTrackingEnabled = (followState !== 0)
                    holdModeEnabled    = (followState === 2)

                    if(followState === 0) {
                        sendClearTrackPoint()
                    }

                    //sendTrackingStatus(followState)
                }
            }

            QGCToolBarButton {
                id: gimbalButton
                z: 999
                normalIconColor: "black"
                icon.source: "/res/gimbalIcon"
                text: "Gimbal"
                font.pointSize: 8
                onClicked: {
                    if(showGimbalControls) {
                        showGimbalControls = false
                    } else {
                        showGimbalControls = true
                    }
                }
            }

            // QGCToolBarButton {
            //     id: switchButton
            //     z: 999
            //     icon.source: "/res/switchIcon"
            //     normalIconColor: "black"
            //     text: "Switch"
            //     font.pointSize: 8
            //     onClicked: {
            //         if (showVideoOptions) {
            //             showVideoOptions   = false
            //             showThermalOptions = false
            //             showColorCombo   = false
            //             showGimbalControls = false
            //         } else {
            //             showVideoOptions = true
            //             showGimbalControls = false
            //         }
            //     }
            // }

            // QGCToolBarButton {
            //     id: followingButton
            //     z: 999
            //     text: isFollowingTarget ? "Following" : "Follow"
            //     font.pointSize: 6.5
            //     icon.source: isFollowingTarget ? "/res/follow_target" :  "/res/unfollow_target"
            //     normalIconColor: "black"

            //     onClicked: {
            //         if (_activeVehicle) {
            //             //console.log("Available flight modes:", JSON.stringify(_activeVehicle.flightModes))
            //            // console.log("Current flight mode:", _activeVehicle.flightMode)
            //         }
            //         if(!isFollowingTarget) {
            //             isFollowingTarget = true
            //             sendStartFollow(isFollowingTarget)
            //             _activeVehicle.flightMode = "GUIDED"
            //             // for (var key in _activeVehicle) {
            //             //     console.log(key)
            //             // }

            //         } else {
            //             isFollowingTarget = false
            //             sendStopFollow(isFollowingTarget)
            //             _activeVehicle.flightMode = "LOITER"
            //             // _activeVehicle.setFlightMode("Loiter")
            //         }
            //     }
            // }

            QGCToolBarButton {
                id: centerButton
                z: 999
                icon.source: "/res/centerCam_icon"
                normalIconColor: "black"
                text: "Center"
                font.pointSize: 8
                onClicked: {
                    sendSetCenter()
                }
            }

            // QGCToolBarButton {
            //     id: laserButton
            //     z: 999
            //     normalIconColor: "black"
            //     icon.source: "/res/laser_icon"
            //     text: isLaserOn ? "Laser On" : "Laser Off"
            //     font.pointSize: 7
            //     onClicked: {
            //         if(isLaserOn) {
            //             isLaserOn = false
            //             if(isMeasureOn) {
            //                 isMeasureOn = false
            //             }
            //             sendLaserStatus(isLaserOn)
            //         } else {
            //             isLaserOn = true
            //             sendLaserStatus(isLaserOn)
            //         }

            //         // isLaserOn = !isLaserOn
            //         // sendLaserStatus(isLaserOn)
            //     }
            // }

            // QGCToolBarButton {
            //     id: measureButton
            //     z: 999
            //     normalIconColor: "black"
            //     icon.source: "/res/measureIcon"
            //     text: "Measure"
            //     font.pointSize: 7
            //     visible: isLaserOn
            //     onClicked: {
            //         isMeasureOn = !isMeasureOn
            //         sendMeasure(isMeasureOn)
            //     }
            // }
        }
    }

    Rectangle {
        id: gimbalPopup
        visible: showGimbalControls && _root.isTheVideoFull && QGroundControl.videoManager.decoding
        z: 1000
        radius: ScreenTools.defaultFontPixelWidth
        color: "#55ffffff"
        width: ScreenTools.defaultFontPixelWidth * 8
        implicitHeight: gimLay.height + ScreenTools.defaultFontPixelHeight
        anchors.left: rect1.right
        anchors.top: parent.top
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 5
        //anchors.verticalCenter: gimbalButton.verticalCenter
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth

        ColumnLayout {
            id: gimLay
            anchors.centerIn: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth

            QGCToolBarButton {
                icon.source: "/res/arrowUp"
                normalIconColor: "black"
                onPressed: sendGimbalUp()
                onReleased: sendStopGimbal()
            }

            QGCToolBarButton {
                icon.source: "/res/arrowDown"
                normalIconColor: "black"
                onPressed: sendGimbalDown()
                onReleased: sendStopGimbal()
            }

            QGCToolBarButton {
                icon.source: "/res/arrowLeft"
                normalIconColor: "black"
                onPressed: sendGimbalLeft()
                onReleased: sendStopGimbal()
            }

            QGCToolBarButton {
                icon.source: "/res/arrowRight"
                normalIconColor: "black"
                onPressed: sendGimbalRight()
                onReleased: sendStopGimbal()
            }
        }
    }

    // Rectangle {
    //     id: videoPopup
    //     visible: showVideoOptions && _root.isTheVideoFull && QGroundControl.videoManager.decoding
    //     z: 1000
    //     radius: ScreenTools.defaultFontPixelWidth
    //     color: "#55ffffff"
    //     width: ScreenTools.defaultFontPixelWidth * 9
    //     height: ScreenTools.defaultFontPixelHeight * 18
    //     //implicitHeight: vidLay.height + ScreenTools.defaultFontPixelHeight
    //     anchors.left: rect1.right
    //     anchors.top: parent.top
    //     anchors.topMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 15 : ScreenTools.defaultFontPixelWidth * 21
    //     //anchors.verticalCenter: switchButton.verticalCenter
    //     anchors.leftMargin: ScreenTools.defaultFontPixelWidth

    //     Flickable {
    //         id: flick
    //         anchors.fill: parent
    //         contentWidth: width
    //         contentHeight: vidLay.implicitHeight
    //         clip: true
    //         interactive: contentHeight > height

    //         ColumnLayout {
    //             id: vidLay
    //             width: flick.width
    //             anchors.horizontalCenter: parent.horizontalCenter
    //             spacing: 0

    //             QGCToolBarButton {
    //                 icon.source: "/res/zoomCamIcon"
    //                 text: "Zoom"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 property int camNum: 3

    //                 onClicked: {
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     videoMode = "Zoom"
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/arrowUp"
    //                 normalIconColor: "black"
    //                 text: "S_Z-W"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 visible: false
    //                 font.pointSize: 7
    //                 property int camNum: 4

    //                 onClicked: {
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 //anchors.fill: parent
    //                 text: "Wide"
    //                 icon.source: "/res/wideCamIcon"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 property int camNum: 5

    //                 onClicked: {
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     videoMode = "Wide"
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/arrowUp"
    //                 normalIconColor: "black"
    //                 text: "S_W-Z"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 visible: false
    //                 font.pointSize: 7
    //                 property int camNum: 6

    //                 onClicked: {
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/therCamIcon"
    //                 normalIconColor: "black"
    //                 text: "Thermal"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 property int camNum: 7

    //                 onClicked: {
    //                     if(showThermalOptions) {
    //                         videoMode = "Thermal"
    //                         showThermalOptions = false
    //                         showColorCombo = false
    //                         isThermalMode = true
    //                         showColorCombo = false
    //                         sendSwitchVideo(camNum)
    //                     } else {
    //                         showThermalOptions = true
    //                     }
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/arrowUp"
    //                 normalIconColor: "black"
    //                 text: "S_T-W"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 visible: false
    //                 font.pointSize: 7
    //                 property int camNum: 8

    //                 onClicked: {
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/ztIcon"
    //                 text: "Zoom-Th"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 property int camNum: 0

    //                 onClicked: {
    //                     videoMode = "Zoom - Thermal"
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/wtIcon"
    //                 text: "Wide_Th"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 property int camNum: 1

    //                 onClicked: {
    //                     videoMode = "Wide - Thermal"
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/zoomCamIcon"
    //                 text: "Zoom-Wide"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 property int camNum: 2

    //                 onClicked: {
    //                     videoMode = "Zoom - Wide"
    //                     isThermalMode = false
    //                     showThermalOptions = false
    //                     sendSwitchVideo(camNum)
    //                 }
    //             }
    //         }
    //     }
    // }

    // Rectangle {
    //     id: thermalPopup
    //     visible: showThermalOptions && QGroundControl.videoManager.decoding && _root.isTheVideoFull
    //     z: 1000
    //     radius: ScreenTools.defaultFontPixelWidth
    //     color: "#55ffffff"
    //     width: ScreenTools.defaultFontPixelWidth * 8
    //     height: ScreenTools.defaultFontPixelHeight * 11
    //     anchors.left: videoPopup.right
    //     anchors.top: parent.top
    //     anchors.topMargin: ScreenTools.defaultFontPixelWidth * 32
    //     //anchors.verticalCenter: switchButton.verticalCenter
    //     anchors.leftMargin: ScreenTools.defaultFontPixelWidth

    //     Flickable {
    //         id: thermFlick
    //         anchors.fill: parent
    //         contentWidth: width
    //         contentHeight: thermalLay.implicitHeight
    //         clip: true
    //         interactive: contentHeight > height

    //         ColumnLayout {
    //             id: thermalLay
    //             width: thermFlick.width
    //             anchors.horizontalCenter: parent.horizontalCenter
    //             spacing: 0

    //                 QGCToolBarButton {
    //                 id: colorButton
    //                 icon.source: "/res/colorIcon"
    //                 text: "Color"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7

    //                 onClicked: {
    //                     showColorCombo = !showColorCombo
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/gainIcon"
    //                 text: "Gain"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 onClicked: {
    //                     showColorCombo = false
    //                 }
    //             }

    //             QGCToolBarButton {
    //                 icon.source: "/res/tempIcon"
    //                 text: "Temp"
    //                 normalIconColor: "black"
    //                 Layout.alignment: Qt.AlignHCenter
    //                 font.pointSize: 7
    //                 onClicked: {
    //                     showColorCombo = false
    //                 }
    //             }
    //         }
    //     }
    // }

    // VideoControls {
    //     anchors.top: parent.top
    //     anchors.right: parent.right
    //     anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 5
    //     anchors.topMargin: ScreenTools.defaultFontPixelWidth * 4
    //     is_TheVideoFull: isTheVideoFull
    //     z: 9999
    // }

    Rectangle {
        id: hideRightRect
        z: 1000
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 5
        anchors.topMargin: ScreenTools.defaultFontPixelWidth * 4
        width: /*ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 3.4 : */fstRect.width   // Rectangle size
        height: width / 2.3
        //radius: 5
        visible: _root.isTheVideoFull && QGroundControl.videoManager.decoding
        color: "#55ffffff"

        QGCColoredImage {
            id: rhbut
            anchors.centerIn: parent       // Center inside rectangle
            width: parent.width * 0.75    // Button size smaller than rectangle
            height: width
            source: isRightMenuVisible ? "/res/cheveron-up.svg" : "/res/cheveron-down.svg"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(isRightMenuVisible === true) {
                    isRightMenuVisible = false
                } else {
                    isRightMenuVisible = true
                }
            }
        }
    }


    Rectangle {
        id: fstRect
        color:      /*qgcPal.toolbarBackground*/ "#55ffffff"
        //anchors.top: parent.top
        anchors.top: hideRightRect.bottom
        anchors.right: parent.right
        anchors.topMargin:/* ScreenTools.defaultFontPixelWidth * 6*/ 12
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 5
        width: ScreenTools.defaultFontPixelWidth * 8
        implicitHeight: rightLayout.height + ScreenTools.defaultFontPixelHeight
        visible: _root.isTheVideoFull && QGroundControl.videoManager.decoding
        opacity: isRightMenuVisible ? 1 : 0
        z: 999
        //radius: ScreenTools.defaultFontPixelWidth

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        ColumnLayout {
            id: rightLayout
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0
            visible: isRightMenuVisible && QGroundControl.videoManager.decoding

            QGCToolBarButton {
                id: takePhotoButton
                z: 999
                icon.source: "/res/cam_icon"
                normalIconColor: "black"
                text: "Photo"
                font.pointSize: 8
                onClicked: sendTakePhoto()
            }

            QGCToolBarButton {
                id: takeVideoButton
                z: 999
                text: "Video"
                font.pointSize: 8
                icon.source: isStartTakeVideo ? "/res/videoStop_icon" : "/res/play_icon"
                normalIconColor: "black"

                onClicked: {
                    if(!isStartTakeVideo) {
                        isStartTakeVideo = true
                        sendStartTakeVideo()
                    } else {
                        isStartTakeVideo = false
                        sendStopTakeVideo()
                        //QGroundControl.saveVideo()
                    }
                }
            }

            QGCToolBarButton {
                icon.source: "/res/zin_icon"
                normalIconColor: "black"
                text: "Z-IN"
                font.pointSize: 8
                onPressed: sendZoomIn()
                onReleased: sendStopZoom()
            }

            QGCToolBarButton {
                icon.source: "/res/zout_icon"
                normalIconColor: "black"
                text: "Z-OUT"
                font.pointSize: 8
                onPressed: sendZoomOut()
                onReleased: sendStopZoom()
            }

            QGCToolBarButton {
                id: clearButton
                z: 999
                text: "Clear"
                font.pointSize: 8
                icon.source: "/res/clearIcon"
                normalIconColor: "black"

                onClicked: {
                    sendClearTrackPoint()
                }
            }

            QGCToolBarButton {
                id: clearButton1
                z: 999
                text: "Full Scr"
                font.pointSize: 8
                icon.source: "/res/fs_icon"
                normalIconColor: "black"

                onClicked: {
                    QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen
                }
            }
        }
    }

    property Item pipState: videoPipState

    QGCPipState {
        id:         videoPipState
        pipOverlay: _pipOverlay
        isDark:     true

        onWindowAboutToOpen: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onWindowAboutToClose: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onStateChanged: {
            if (pipState.state !== pipState.fullState) {
                QGroundControl.videoManager.fullScreen = false
            }
        }
    }

    Timer {
        id:           videoStartDelay
        interval:     2000;
        running:      false
        repeat:       false
        onTriggered:  QGroundControl.videoManager.startVideo()
    }

    //-- Video Streaming
    FlightDisplayViewVideo {
        id:             videoStreaming
        anchors.fill:   parent
        useSmallFont:   _root.pipState.state !== _root.pipState.fullState
        visible:        QGroundControl.videoManager.isGStreamer
    }

    onRequestTrackAndDrag: {
            console.log("requestTrackAndDrag received in FlyViewVideo")
            videoStreaming.performTrackAndDrag()
        }

    Connections {
        target: _activeVehicle
        enabled: !!_activeVehicle

        onArmedChanged: {
            if (armed) {
                if (!isStartTakeVideo) {
                    isStartTakeVideo = true
                    sendStartTakeVideo()
                }
            } else {
                if (isStartTakeVideo) {
                    isStartTakeVideo = false
                    sendStopTakeVideo()
                    //QGroundControl.saveVideo()
                }
            }
        }
    }

    Connections {
        target: QGroundControl.multiVehicleManager

        onActiveVehicleChanged: {
            if(_activeVehicle && _activeVehicle.armed && !isStartTakeVideo) {
                console.log("Vehicle already armed on connect, start recording")
                isStartTakeVideo = true
                sendStartTakeVideo()
            }
        }
    }

    //-- UVC Video (USB Camera or Video Device)
    Loader {
        id:             cameraLoader
        anchors.fill:   parent
        visible:        !QGroundControl.videoManager.isGStreamer
        source:         QGroundControl.videoManager.uvcEnabled ? "qrc:/qml/FlightDisplayViewUVC.qml" : "qrc:/qml/FlightDisplayViewDummy.qml"
    }

    // QGCLabel {
    //     text: qsTr("Double-click to exit full screen")
    //     font.pointSize: ScreenTools.largeFontPointSize
    //     visible: QGroundControl.videoManager.fullScreen && flyViewVideoMouseArea.containsMouse
    //     anchors.centerIn: parent

    //     onVisibleChanged: {
    //         if (visible) {
    //             labelAnimation.start()
    //         }
    //     }

    //     PropertyAnimation on opacity {
    //         id: labelAnimation
    //         duration: 10000
    //         from: 1.0
    //         to: 0.0
    //         easing.type: Easing.InExpo
    //     }
    // }

    OnScreenGimbalController {
        id:                      onScreenGimbalController
        anchors.fill:            parent
        screenX:                 flyViewVideoMouseArea.mouseX
        screenY:                 flyViewVideoMouseArea.mouseY
        cameraTrackingEnabled:   videoStreaming._camera && videoStreaming._camera.trackingEnabled
    }

    MouseArea {
        id:                         flyViewVideoMouseArea
        anchors.fill:               parent
        enabled:                    pipState.state === pipState.fullState
        hoverEnabled:               true

        property double x0:         0
        property double x1:         0
        property double y0:         0
        property double y1:         0
        property double offset_x:   0
        property double offset_y:   0
        property double radius:     20
        property var trackingROI:   null
        property var trackingStatus: trackingStatusComponent.createObject(flyViewVideoMouseArea, {})

        onClicked: {
            onScreenGimbalController.clickControl()
        }

        // onDoubleClicked: {
        //     console.log("Double clicked on the video...!")
        //     QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen
        // }

        onPressed: {
            if(QGroundControl.videoManager.decoding) {
                p = normalizedVideoPoint(mouse.x, mouse.y)
                //if(p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1) {
                if(p.x > 0 && p.x < 1 && p.y > 0 && p.y < 1) { // condition to eliminate the black bar and the black box.
                    //console.log("Normalized:", p.x, p.y)
                    if (followState === 1) {
                        pressX = p.x
                        pressY = p.y
                        dragging = false
                    }

                    if (followState === 2) {
                        pressX = p.x
                        pressY = p.y
                        sendHoldPoint(pressX, pressY)
                    }

                } else {
                    pressX = 0
                    pressY = 0
                    console.log("Invalid value")
                }
            }

            onScreenGimbalController.pressControl()

            _track_rec_x = mouse.x
            _track_rec_y = mouse.y

            //create a new rectangle at the wanted position
            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    trackingROI = trackingROIComponent.createObject(flyViewVideoMouseArea, {
                        "x": mouse.x,
                        "y": mouse.y
                    });
                }
            }
        }

        onPositionChanged: {
            //on move, update the width of rectangle
            if (trackingROI !== null) {
                if (mouse.x < trackingROI.x) {
                    trackingROI.x = mouse.x
                    trackingROI.width = Math.abs(mouse.x - _track_rec_x)
                } else {
                    trackingROI.width = Math.abs(mouse.x - trackingROI.x)
                }
                if (mouse.y < trackingROI.y) {
                    trackingROI.y = mouse.y
                    trackingROI.height = Math.abs(mouse.y - _track_rec_y)
                } else {
                    trackingROI.height = Math.abs(mouse.y - trackingROI.y)
                }
            }

            if(QGroundControl.videoManager.decoding) {
                if (followState !== 1)
                    return

                var dx = mouse.x - pressX
                var dy = mouse.y - pressY

                if (Math.sqrt(dx*dx + dy*dy) > dragThreshold)
                    dragging = true
            }
        }

        onReleased: {
            onScreenGimbalController.releaseControl()

            if(QGroundControl.videoManager.decoding) {
                if((pressX > 0 && pressX < 1 && pressY > 0 && pressY < 1) && (followState ===1) && (!dragging)) {
                    sendPoint(pressX, pressY)
                    console.log(pressX, pressY)
                    console.log("it comes send point function")
                    if(isThermalMode) {
                        sendThermalCoordinates(pressX, pressY)
                    }
                } else if (dragging) {
                    var dp = normalizedVideoPoint(mouse.x, mouse.y)
                    lastX = dp.x
                    lastY = dp.y
                    //var y2 = normalizedVideoPoint(mouse.y)
                    console.log(pressX, pressY, lastX, lastY)
                    console.log("It comes drag sending function")
                    sendDrag(pressX, pressY, lastX, lastY)
                } else {
                    console.log(pressX, pressY)
                    console.log("It wont send")
                }
            }

            //if there is already a selection, delete it
            if (trackingROI !== null) {
                trackingROI.destroy();
            }

            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    // order coordinates --> top/left and bottom/right
                    x0 = Math.min(_track_rec_x, mouse.x)
                    x1 = Math.max(_track_rec_x, mouse.x)
                    y0 = Math.min(_track_rec_y, mouse.y)
                    y1 = Math.max(_track_rec_y, mouse.y)

                    //calculate offset between video stream rect and background (black stripes)
                    offset_x = (parent.width - videoStreaming.getWidth()) / 2
                    offset_y = (parent.height - videoStreaming.getHeight()) / 2

                    //convert absolute coords in background to absolute video stream coords
                    x0 = x0 - offset_x
                    x1 = x1 - offset_x
                    y0 = y0 - offset_y
                    y1 = y1 - offset_y

                    //convert absolute to relative coordinates and limit range to 0...1
                    x0 = Math.max(Math.min(x0 / videoStreaming.getWidth(), 1.0), 0.0)
                    x1 = Math.max(Math.min(x1 / videoStreaming.getWidth(), 1.0), 0.0)
                    y0 = Math.max(Math.min(y0 / videoStreaming.getHeight(), 1.0), 0.0)
                    y1 = Math.max(Math.min(y1 / videoStreaming.getHeight(), 1.0), 0.0)

                    //use point message if rectangle is very small
                    if (Math.abs(_track_rec_x - mouse.x) < 10 && Math.abs(_track_rec_y - mouse.y) < 10) {
                        var pt  = Qt.point(x0, y0)
                        videoStreaming._camera.startTracking(pt, radius / videoStreaming.getWidth())
                    } else {
                        var rec = Qt.rect(x0, y0, x1 - x0, y1 - y0)
                        videoStreaming._camera.startTracking(rec)
                    }
                    _track_rec_x = 0
                    _track_rec_y = 0
                }
            }
        }

        Component {
            id: trackingROIComponent

            Rectangle {
                color:              Qt.rgba(0.1,0.85,0.1,0.25)
                border.color:       "green"
                border.width:       1
            }
        }

        Component {
            id: trackingStatusComponent

            Rectangle {
                color:              "transparent"
                border.color:       "red"
                border.width:       5
                radius:             5
            }
        }

        Timer {
            id: trackingStatusTimer
            interval:               50
            repeat:                 true
            running:                true
            onTriggered: {
                if (videoStreaming._camera) {
                    if (videoStreaming._camera.trackingEnabled && videoStreaming._camera.trackingImageStatus) {
                        var margin_hor = (parent.parent.width - videoStreaming.getWidth()) / 2
                        var margin_ver = (parent.parent.height - videoStreaming.getHeight()) / 2
                        var left = margin_hor + videoStreaming.getWidth() * videoStreaming._camera.trackingImageRect.left
                        var top = margin_ver + videoStreaming.getHeight() * videoStreaming._camera.trackingImageRect.top
                        var right = margin_hor + videoStreaming.getWidth() * videoStreaming._camera.trackingImageRect.right
                        var bottom = margin_ver + !isNaN(videoStreaming._camera.trackingImageRect.bottom) ? videoStreaming.getHeight() * videoStreaming._camera.trackingImageRect.bottom : top + (right - left)
                        var width = right - left
                        var height = bottom - top

                        flyViewVideoMouseArea.trackingStatus.x = left
                        flyViewVideoMouseArea.trackingStatus.y = top
                        flyViewVideoMouseArea.trackingStatus.width = width
                        flyViewVideoMouseArea.trackingStatus.height = height
                    } else {
                        flyViewVideoMouseArea.trackingStatus.x = 0
                        flyViewVideoMouseArea.trackingStatus.y = 0
                        flyViewVideoMouseArea.trackingStatus.width = 0
                        flyViewVideoMouseArea.trackingStatus.height = 0
                    }
                }
            }
        }
    }

    ProximityRadarVideoView{
        anchors.fill:   parent
        vehicle:        QGroundControl.multiVehicleManager.activeVehicle
    }

    ObstacleDistanceOverlayVideo {
        id: obstacleDistance
        showText: pipState.state === pipState.fullState
    }

    function sendPoint(x, y) {
        console.log("Sending function")
        sendJson("/track_point", {
            x_norm: x,
            y_norm: y,
            video_width: vw,
            video_height: vh
        })
    }

    function sendThermalCoordinates(pressX, pressY) {
        console.log("Thermal coordinates function")
        console.log("X and Y is thermal", pressX, pressY)
        sendJson("/thermal/temperature", {
            x: pressX,
            y: pressY
        })
    }

    function sendDrag(x1, y1, x2, y2) {
        sendJson("/drag_point", {
        x1_norm: x1,
        y1_norm: y1,
        x2_norm: x2,
        y2_norm: y2,
        video_width: vw,
        video_height: vh
        })
    }

    function sendHoldPoint(x, y) {
        console.log("It comes here for send hold point]")
        sendJson("/hold_point", {
            hold_x: x,
            hold_y: y,
            video_width: vw,
            video_height: vh
        })
    }

    function sendZoomIn(meter) {
        console.log("It comes zoom in function")
        sendJson("/zoom_in", {})
    }

    function sendStopZoom() {
        console.log("Stopping zoom")
        sendJson("/stop_zoom", {})
    }

    function sendZoomOut(meter) {
        console.log("It comes zoom out function")
        sendJson("/zoom_out", {})
    }

    function sendTakePhoto() {
        console.log("It comes take photo function")
        sendJson("/take_photo", {})
        //_videoStreamManager.grabImage()
        QGroundControl.saveScreenshot()
    }

    function sendStartTakeVideo() {
        console.log("It comes start video function")
        sendJson("/start_recording", {})
        if(QGroundControl.videoManager.decoding) {
            _videoStreamManager.startRecording()
        } else {
            console.log("Start video streaming for record the video")
        }
    }

    function sendStopTakeVideo(flag) {
        console.log("It comes stop video function")
        sendJson("/stop_recording", {})
        _videoStreamManager.stopRecording()
    }

    function sendSetCenter() {
        console.log("It comes set center function")
        sendJson("/center", {})
    }

    // function sendLaserStatus(isLaserOn) {
    //     console.log("It comes send laser function")
    //     console.log("Laser status", isLaserOn)
    //     console.log("Measure status in laser function", isMeasureOn)
    //     sendJson("/laser_status", {
    //         laser_status: isLaserOn})
    // }

    // function sendMeasure(isMeasureOn) {
    //     console.log("It comes measure function")
    //     console.log("Measure status", isMeasureOn)
    //     sendJson("/measure", {
    //         measure_status: isMeasureOn
    //         })
    // }

    function sendGimbalUp() {
        console.log("It comes up")
        sendJson("/pitch_up", {})
    }

    function sendGimbalDown() {
        console.log("It comes down")
        sendJson("/pitch_down", {})
    }

    function sendGimbalLeft() {
        console.log("It comes left")
        sendJson("/yaw_left", {})
    }

    function sendGimbalRight() {
        console.log("It comes right")
        sendJson("/yaw_right", {})
    }

    function sendStopGimbal() {
        console.log("Gimbal stop")
        sendJson("/stop_gimbal", {})
    }

    function sendClearTrackPoint() {
        console.log("Clear track point")
        sendJson("/clear_track", {})
    }

    // function sendStartFollow(isFollowingTarget) {
    //     console.log("Start follow")
    //     console.log("isFollowing in start", isFollowingTarget)
    //     // sendJson("/follow/enable", {
    //     //     enabled: isFollowingTarget
    //     // })
    //     sendJson("/follow/enable", {})
    // }

    // function sendStopFollow(isFollowingTarget) {
    //     console.log("Stop follow")
    //     console.log("isFollowing in stop", isFollowingTarget)
    //     // sendJson("/follow/disable", {
    //     //     enabled: isFollowingTarget
    //     // })
    //     sendJson("/follow/disable", {})
    // }

    function sendSwitchVideo(num) {
        console.log("Switch the video")
        console.log("Number is", num)
        sendJson("/image_mode", {
        mode: num})
    }

    function sendColorMode(mode) {
        console.log("Color mode function")
        console.log("Color mode num", mode)
        sendJson("/thermal/palette", {
            palette: mode
        })
    }

    function sendJson(endpoint, payload) {
        var xhr = new XMLHttpRequest()
        //xhr.open("POST", "http://127.0.0.1:8000" + endpoint)
        xhr.open("POST", "http://192.168.144.60:8000" + endpoint)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify(payload))
    }

    ComboBox {
        id: colorCombo
        visible: showColorCombo && QGroundControl.videoManager.decoding && _root.isTheVideoFull
        z: 2000
        width: ScreenTools.defaultFontPixelWidth * 30
        height: 50
        anchors.left: thermalPopup.right
        anchors.top: parent.top
        anchors.topMargin: ScreenTools.defaultFontPixelWidth * 31
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth

        model: ListModel {
            ListElement { text: "White Hot";  value: 0 }
            ListElement { text: "Sepia";      value: 2 }
            ListElement { text: "Ironbow";    value: 3 }
            ListElement { text: "Rainbow";    value: 4 }
            ListElement { text: "Night";      value: 5 }
            ListElement { text: "Aurora";     value: 6 }
            ListElement { text: "Red Hot";    value: 7 }
            ListElement { text: "Jungle";     value: 8 }
            ListElement { text: "Medical";    value: 9 }
            ListElement { text: "Black Hot";  value: 10 }
            ListElement { text: "Glory Hot";  value: 11 }
        }

        textRole: "text"

        onActivated: {
            var entry = model.get(index)
            console.log("Color:", entry.text, "Value:", entry.value)
            sendColorMode(entry.value)
        }
    }


    Rectangle {
        id: paramRect

        property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight
        width: rowLayout.implicitWidth + ScreenTools.defaultFontPixelWidth * 2
        height: rowLayout.implicitHeight + ScreenTools.defaultFontPixelHeight / 2
        color: Qt.rgba(0, 0, 0, 0.5)
        radius: ScreenTools.defaultFontPixelWidth / 2
        visible: QGroundControl.videoManager.decoding && mapControl.pipState.state === mapControl.pipState.pipState
        //visible: false
        z: 999

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: ScreenTools.defaultFontPixelWidth * 2

            ColumnLayout {
                spacing: 2
                QGCLabel {
                    text: _activeVehicle ? _activeVehicle.altitudeRelative.valueString : "N/A"
                    font.pointSize: ScreenTools.defaultFontPointSize + 2
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCLabel {
                    text: "Alt Rel"
                    font.pointSize: ScreenTools.defaultFontPointSize - 2
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                width: 1
                height: parent.height * 0.7
                color: "#66ffffff"
                //anchors.verticalCenter: parent.verticalCenter
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 2
                QGCLabel {
                    text: _activeVehicle ? _activeVehicle.flightTime.valueString : "N/A"
                    font.pointSize: ScreenTools.defaultFontPointSize + 2
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCLabel {
                    text: "Flight Time"
                    font.pointSize: ScreenTools.defaultFontPointSize - 2
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                width: 1
                height: parent.height * 0.7
                color: "#66ffffff"
                //anchors.verticalCenter: parent.verticalCenter
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 2
                QGCLabel {
                    text: _activeVehicle ? _activeVehicle.distanceToHome.valueString : "N/A"
                    font.pointSize: ScreenTools.defaultFontPointSize + 2
                    font.bold: true
                    color: "white"
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCLabel {
                    text: "Dist to Home"
                    font.pointSize: ScreenTools.defaultFontPointSize - 2
                    color: "#cccccc"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
