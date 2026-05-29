import QtQuick                  2.15
import QtQuick.Controls         2.15
// import QtQuick.Dialogs          1.3
// import QtQuick.Layouts          1.12

// import QtLocation               5.3
// import QtPositioning            5.3
// import QtQuick.Window           2.2
// import QtQml.Models             2.1
// //import QtQuick.Controls 2.4

// import QGroundControl               1.0
// import QGroundControl.Controllers   1.0
// import QGroundControl.Controls      1.0
// import QGroundControl.FactSystem    1.0
// import QGroundControl.FlightDisplay 1.0
// import QGroundControl.FlightMap     1.0
// import QGroundControl.Palette       1.0
// import QGroundControl.ScreenTools   1.0
// import QGroundControl.Vehicle       1.0

Item {
    id: _root

//     property bool is_TheVideoFull: false
//     property bool isRightMenuVisible: true

//     Rectangle {
//         id: hideRightRect
//         z: 1000
//         anchors.right: parent.right
//         anchors.topMargin:/* ScreenTools.defaultFontPixelWidth * 6*/ 12
//         anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 5
//         width: /*ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 3.4 : */fstRect.width   // Rectangle size
//         //width: 30
//         height: width / 2.3
//         //radius: 5
//         visible: _root.is_TheVideoFull && QGroundControl.videoManager.decoding
//         color: "#55ffffff"

//         QGCColoredImage {
//             id: rhbut
//             anchors.centerIn: parent       // Center inside rectangle
//             width: parent.width * 0.75    // Button size smaller than rectangle
//             height: width
//             source: isRightMenuVisible ? "/res/cheveron-up.svg" : "/res/cheveron-down.svg"
//         }
//         MouseArea {
//             anchors.fill: parent
//             onClicked: {
//                 if(isRightMenuVisible === true) {
//                     isRightMenuVisible = false
//                 } else {
//                     isRightMenuVisible = true
//                 }
//             }
//         }
//     }

//     Rectangle {
//         id: fstRect
//         color:      /*qgcPal.toolbarBackground*/ "#55ffffff"
//         //anchors.top: parent.top
//         anchors.top: hideRightRect.bottom
//         anchors.right: parent.right
//         anchors.topMargin:/* ScreenTools.defaultFontPixelWidth * 6*/ 12
//         anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 5
//         width: ScreenTools.defaultFontPixelWidth * 8
//         implicitHeight: rightLayout.height + ScreenTools.defaultFontPixelHeight
//         visible: _root.is_TheVideoFull && QGroundControl.videoManager.decoding
//         opacity: isRightMenuVisible ? 1 : 0
//         z: 999
//         //radius: ScreenTools.defaultFontPixelWidth

//         Behavior on anchors.topMargin {
//             NumberAnimation {
//                 duration: 300
//                 easing.type: Easing.InOutCubic
//             }
//         }

//         Behavior on opacity {
//             NumberAnimation { duration: 200 }
//         }

//         ColumnLayout {
//             id: rightLayout
//             anchors.horizontalCenter: parent.horizontalCenter
//             spacing: 0
//             visible: isRightMenuVisible && QGroundControl.videoManager.decoding

//             QGCToolBarButton {
//                 id: takePhotoButton
//                 z: 999
//                 icon.source: "/res/cam_icon"
//                 normalIconColor: "black"
//                 text: "Photo"
//                 font.pointSize: 8
//                 onClicked: sendTakePhoto()
//             }

//             QGCToolBarButton {
//                 id: takeVideoButton
//                 z: 999
//                 text: "Video"
//                 font.pointSize: 8
//                 icon.source: isStartTakeVideo ? "/res/videoStop_icon" : "/res/play_icon"
//                 normalIconColor: "black"

//                 onClicked: {
//                     if(!isStartTakeVideo) {
//                         isStartTakeVideo = true
//                         sendStartTakeVideo()
//                     } else {
//                         isStartTakeVideo = false
//                         sendStopTakeVideo()
//                     }
//                 }
//             }

//             QGCToolBarButton {
//                 icon.source: "/res/zin_icon"
//                 normalIconColor: "black"
//                 text: "Z-IN"
//                 font.pointSize: 8
//                 onPressed: sendZoomIn()
//                 onReleased: sendStopZoom()
//             }

//             QGCToolBarButton {
//                 icon.source: "/res/zout_icon"
//                 normalIconColor: "black"
//                 text: "Z-OUT"
//                 font.pointSize: 8
//                 onPressed: sendZoomOut()
//                 onReleased: sendStopZoom()
//             }

//             QGCToolBarButton {
//                 id: clearButton
//                 z: 999
//                 text: "Clear"
//                 font.pointSize: 8
//                 icon.source: "/res/clearIcon"
//                 normalIconColor: "black"

//                 onClicked: {
//                     sendClearTrackPoint()
//                 }
//             }
//         }
//     }

//     function sendZoomIn(meter) {
//         console.log("It comes zoom in function")
//         sendJson("/zoom_in", {})
//     }

//     function sendStopZoom() {
//         console.log("Stopping zoom")
//         sendJson("/stop_zoom", {})
//     }

//     function sendZoomOut(meter) {
//         console.log("It comes zoom out function")
//         sendJson("/zoom_out", {})
//     }

//     function sendTakePhoto() {
//         console.log("It comes take photo function")
//         sendJson("/take_photo", {})
//     }

//     function sendStartTakeVideo() {
//         console.log("It comes start video function")
//         sendJson("/start_recording", {})
//     }

//     function sendStopTakeVideo(flag) {
//         console.log("It comes stop video function")
//         sendJson("/stop_recording", {})
//     }

//     function sendClearTrackPoint() {
//         console.log("Clear track point")
//         sendJson("/clear_track", {})
//     }
}
