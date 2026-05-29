// // main.qml
// // import QtQuick 2.12
// // import QtQuick.Controls 2.12

// // import QGroundControl.ScreenTools   1.0

// import QtQuick          2.11
// import QtQuick.Controls 2.4
// import QtQuick.Dialogs  1.3
// import QtQuick.Layouts  1.11
// import QtQuick.Window   2.11

// import QGroundControl               1.0
// import QGroundControl.Palette       1.0
// import QGroundControl.Controls      1.0
// import QGroundControl.ScreenTools   1.0
// import QGroundControl.FlightDisplay 1.0
// import QGroundControl.FlightMap     1.0

// ApplicationWindow {
//     id: rootApp
//     //minimumWidth:   ScreenTools.isMobile ? Screen.width  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
//     //minimumHeight:  ScreenTools.isMobile ? Screen.height : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
//     width: 500
//     height: 500
//     visible: true
//     //title: qsTr("QGroundControl")

//     property bool loggedIn: false

//     header: MainToolBar {
//             id: toolBar
//             visible: mainWindow.isLoggedIn
//         }

//     footer: LogReplayStatusBar {
//         visible: mainWindow.isLoggedIn
//     }

//     Loader {
//         id: pageLoader
//         anchors.fill: parent
//         source: loggedIn ? "qrc:/qml/MainRootWindow.qml" : "qrc:/qml/LoginPage.qml"
//     }

//     // Listen for loginSuccess signal emitted from LoginPage.qml
    // Connections {
    //     target: pageLoader.item
    //     onLoginSuccess: {
    //         loggedIn = true
    //     }
    // }
// }


import QtQuick          2.11
import QtQuick.Controls 2.4
import QtQuick.Dialogs  1.3
import QtQuick.Layouts  1.11
import QtQuick.Window   2.11

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0

// ApplicationWindow {
//     id: mainWindow
//     visible: true
//     width: 1280
//     height: 720
//     //title: qsTr("QGroundControl with Login")

//     // Control whether user is logged in
//     property bool loggedIn: false

//     // Show toolbar only after login
//     header: MainToolBar {
//         id: toolBar
//         visible: mainWindow.isLoggedIn
//     }

//     footer: LogReplayStatusBar {
//         visible: mainWindow.isLoggedIn
//     }

//     Loader {
//         id: mainLoader
//         anchors.fill: parent
//         source: isLoggedIn ? "MainRootWindow.qml" : "LoginPage.qml"

//         // Pass references to loaded QML
//         onLoaded: {
//             if (item && mainWindow.isLoggedIn) {
//                 item.toolBar = toolBar   // toolbar into MainRootWindow
//             }
//         }
//     }

//     Connections {
//         target: mainLoader.item
//         onLoginSuccess: {
//             loggedIn = true
//         }
//     }
// }


ApplicationWindow {
    id: mainRootItem
    visible: true
    width: 1280
    height: 720
    visibility: "Maximized"

    property bool loggedIn: false

    // Component.onCompleted: {
    //     mainWindow.showFullScreen()
    // }

    header: MainToolBar {
        id: toolbar
        visible: mainRootItem.loggedIn
        onToolSelectClicked: {
            if (mainLoader.item && mainLoader.item.showToolSelectDialog) {
                mainLoader.item.showToolSelectDialog()
            } else {
                console.warn("⚠️ showToolSelectDialog not found on mainLoader.item")
            }
        }
    }

    footer: LogReplayStatusBar {
        visible: mainRootItem.loggedIn
    }

    Loader {
        id: mainLoader
        anchors.fill: parent
        source: mainRootItem.loggedIn ? "MainRootWindow.qml" : "LoginPage.qml"

        onLoaded: {
            if (item && mainRootItem.loggedIn) {
                item.toolbar = toolbar
            }
        }
    }

    Connections {
        target: mainLoader.item
        onLoginSuccess: {
            mainRootItem.loggedIn = true
        }
    }
}
