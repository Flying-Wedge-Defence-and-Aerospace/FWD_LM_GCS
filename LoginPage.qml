import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.15
import QtQuick.Window   2.11

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

Rectangle {
    id: loginMainRect
    width:   ScreenTools.isMobile ? Screen.width  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    height:  ScreenTools.isMobile ? Screen.height : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)

    color: "#700000"

    property int currentPage: 0

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#700000" }   // highlight
        GradientStop { position: 0.5; color: "#e00000" }   // deeper base
        GradientStop { position: 1.0; color: "#700000" }
    }


    signal loginSuccess()

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: loginMainRect.width * 0.25
            Layout.fillHeight: true
            color: "transparent"
            Layout.margins: ScreenTools.defaultFontPixelWidth * 2

            QGCLabel {
                text: " GROUND \nCONTROL\n STATION"
                font.bold: true
                color: "white"
                anchors.centerIn: parent
                //anchors.fill: parent
                font.pointSize: ScreenTools.isMobile ? 30 : 50
                //wrapMode: Text.WordWrap
            }
        }
        Rectangle {
            id:rightRect
            Layout.preferredWidth:  loginMainRect.width * 0.75
            Layout.fillHeight: true
            color: "transparent"

            Rectangle {
                id: centerRect
                width: rightRect.width * 0.90
                height: rightRect.height * 0.8
                color: "#511111"
                anchors.centerIn: parent
                radius: ScreenTools.defaultFontPixelWidth * 2

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        id: detailsRect
                        Layout.preferredWidth: centerRect.width * 0.35
                        Layout.fillHeight: true
                        color: "transparent"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: /*ScreenTools.defaultFontPixelWidth * 2*/ 0

                            Rectangle {
                                id: topRect
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height * 0.25
                                color:  "transparent"

                                ColumnLayout {
                                    spacing: 10   // space between image and text
                                    anchors.centerIn: parent

                                    Image {
                                        source: "/res/FWD_only_logo"
                                        fillMode: Image.PreserveAspectFit

                                        readonly property real baseSize:
                                            ScreenTools.defaultFontPixelHeight * 8

                                        width: ScreenTools.isTinyScreen
                                               ? Math.min(baseSize, 48)
                                               : Math.min(baseSize, 96)

                                        height: width

                                        Layout.preferredWidth:  width
                                        Layout.preferredHeight: height
                                        Layout.alignment: Qt.AlignHCenter
                                    }


                                    QGCLabel {
                                        text: "FWDGCS"
                                        font.pointSize: 25
                                        font.bold: true
                                        color: "blue"
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    // Rectangle {
                                    //     Layout.preferredWidth: topRect.width * 0.9
                                    //     Layout.preferredHeight: 1
                                    //     color: "#888"
                                    //     Layout.alignment: Qt.AlignHCenter
                                    // }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height * 0.4
                                color:  "transparent"

                                Loader {
                                    id: loader
                                    anchors.fill: parent
                                    anchors.margins: 30
                                    active: true
                                    sourceComponent: currentPage === 0 ? loginPage : registerPage
                                    property int formWidth: width
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height * 0.35
                                color:  "transparent"
                            }
                        }
                    }

                    Rectangle { // separator line
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: "#888"
                    }

                    Rectangle { // image rect
                        Layout.preferredWidth: centerRect.width * 0.65
                        Layout.fillHeight: true
                        color: "transparent"

                        Image {
                            id: bgImage
                            anchors.fill: parent
                            source: "/res/login_image"
                            fillMode: Image.Stretch
                            smooth: true
                        }
                    }
                }
            }
        }
    }

    Component {
        id: loginPage
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            //spacing: ScreenTools.defaultFontPixelWidth * 3   // controls vertical space

            QGCLabel {
                text: qsTr("Login")
                font.bold: true
                color: "white"
                font.pointSize: 20
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }

        //     ColumnLayout {
        //         Layout.fillWidth: true
        //         Layout.leftMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 5 : ScreenTools.defaultFontPixelWidth * 10
        //         Layout.rightMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 10 : 0

        //         QGCLabel {
        //             text: qsTr("Username")
        //             color: "lightgray"
        //             font.pointSize: 12
        //             font.bold: true
        //         }

        //         QGCTextField {
        //             id: username
        //             placeholderText: qsTr("Enter Username")
        //             font.pointSize: 10
        //             //Layout.fillWidth: true
        //             //Layout.preferredWidth: parent.width   // expand width
        //             Layout.preferredWidth: detailsRect.width * 0.6
        //         }
        //     }


        //     /* Email */
        //     ColumnLayout {
        //         Layout.fillWidth: true
        //         //spacing: ScreenTools.defaultFontPixelWidth
        //         Layout.leftMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 5 : ScreenTools.defaultFontPixelWidth * 10
        //         Layout.rightMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 10 : 0

        //         QGCLabel {
        //             text: qsTr("Email")
        //             color: "lightgray"
        //             font.pointSize: 12
        //             font.bold: true
        //         }

        //         QGCTextField {
        //             id: emailField
        //             placeholderText: qsTr("Enter Email")
        //             font.pointSize: 10
        //             //Layout.fillWidth: true
        //             Layout.preferredWidth: detailsRect.width * 0.6
        //         }
        //     }

        //     ColumnLayout {
        //         Layout.fillWidth: true
        //         Layout.leftMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 5 : ScreenTools.defaultFontPixelWidth * 10
        //         Layout.rightMargin: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 10 : 0

        //         QGCLabel {
        //             text: qsTr("Password")
        //             color: "lightgray"
        //             font.pointSize: 12
        //             font.bold: true
        //         }

        //         QGCTextField {
        //             id: pass
        //             placeholderText: qsTr("Enter password")
        //             font.pointSize: 10
        //             //Layout.fillWidth: true
        //             Layout.preferredWidth: detailsRect.width * 0.6
        //         }
        //     }

            QGCButton {
                text: "Login"
                Layout.alignment: Qt.AlignHCenter
                //Layout.fillWidth: true
                onClicked: {
                    // if (username.text === "" && pass.text === "") {
                        loginSuccess()
                        console.log("Success")
                    // } else {
                    //     console.log("Invalid credentials")
                    // }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                QGCLabel {
                    text: "Don't have an Account? "
                    font.bold: true
                }
                QGCLabel {
                    text: "<u>Register here</u>"
                    color: "blue"
                    font.pointSize: 10
                    font.bold: true
                    font.italic: true

                    QGCMouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentPage = 1
                            console.log("Register button clicked..!")
                        }
                    }
                }
            }
        }
    }

    Component {
        id: registerPage
        ColumnLayout {
            anchors.fill: parent
            spacing: ScreenTools.defaultFontPixelWidth * 3   // controls vertical space

            QGCLabel {
                text: qsTr("Register")
                font.bold: true
                color: "white"
                font.pointSize: 20
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
            }

            // ColumnLayout {
            //     Layout.fillWidth: true
            //     Layout.leftMargin: ScreenTools.defaultFontPixelWidth * 10
            //     Layout.rightMargin: ScreenTools.defaultFontPixelWidth * 10

            //     QGCLabel {
            //         text: qsTr("Username")
            //         color: "lightgray"
            //         font.pointSize: 12
            //         font.bold: true
            //     }

            //     QGCTextField {
            //         id: username
            //         placeholderText: qsTr("👤 Username")
            //         font.pointSize: 10
            //         Layout.fillWidth: true
            //         Layout.preferredWidth: parent.width   // expand width
            //     }
            // }

            // ColumnLayout {
            //     Layout.fillWidth: true
            //     //spacing: ScreenTools.defaultFontPixelWidth
            //     Layout.leftMargin: ScreenTools.defaultFontPixelWidth * 10
            //     Layout.rightMargin: ScreenTools.defaultFontPixelWidth * 10

            //     QGCLabel {
            //         text: qsTr("Email")
            //         color: "lightgray"
            //         font.pointSize: 12
            //         font.bold: true
            //     }

            //     QGCTextField {
            //         id: emailField
            //         placeholderText: qsTr("📧 Email")
            //         font.pointSize: 10
            //         Layout.fillWidth: true
            //         Layout.preferredWidth: parent.width
            //     }
            // }

            // ColumnLayout {
            //     Layout.fillWidth: true
            //     Layout.leftMargin: ScreenTools.defaultFontPixelWidth * 10
            //     Layout.rightMargin: ScreenTools.defaultFontPixelWidth * 10

            //     QGCLabel {
            //         text: qsTr("Password")
            //         color: "lightgray"
            //         font.pointSize: 12
            //         font.bold: true
            //     }

            //     QGCTextField {
            //         id: pass
            //         placeholderText: qsTr("🔑 Enter password")
            //         font.pointSize: 10
            //         Layout.fillWidth: true
            //         Layout.preferredWidth: parent.width
            //     }
            // }

            // ColumnLayout {
            //     Layout.fillWidth: true
            //     Layout.leftMargin: ScreenTools.defaultFontPixelWidth * 10
            //     Layout.rightMargin: ScreenTools.defaultFontPixelWidth * 10

            //     QGCLabel {
            //         text: qsTr("Password")
            //         color: "lightgray"
            //         font.pointSize: 12
            //         font.bold: true
            //     }

            //     QGCTextField {
            //         id: conPass
            //         placeholderText: qsTr("🔑 Re-Enter password")
            //         font.pointSize: 10
            //         Layout.fillWidth: true
            //         Layout.preferredWidth: parent.width
            //     }
            // }

            // QGCButton {
            //     text: "Register"
            //     Layout.alignment: Qt.AlignHCenter
            //     //Layout.fillWidth: true
            //     onClicked: {
            //         console.log("Account Registered...!")
            //     }
            // }

            QGCLabel {
                text: "Back to Login"
                color: "blue"
                font.pointSize: 10
                font.bold: true
                font.italic: true
                Layout.alignment: Qt.AlignHCenter

                QGCMouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentPage = 0
                    }
                }
            }
        }
    }

}

// import QtQuick 2.12
// import QtQuick.Controls 2.12

// Item {
//     signal loginSuccess()

//     Column {
//         anchors.centerIn: parent
//         spacing: 10

//         TextField {
//             id: usernameField
//             placeholderText: "Username"
//             width: 200
//         }

//         TextField {
//             id: passwordField
//             placeholderText: "Password"
//             echoMode: TextInput.Password
//             width: 200
//         }

//         Button {
//             text: "Login"
            // onClicked: {
            //     if (usernameField.text === "" && passwordField.text === "") {
            //         loginSuccess()
            //         console.log("Success")
            //     } else {
            //         console.log("Invalid credentials")
            //     }
            // }
//         }
//     }
// }


// import QtQuick 2.12
// import QtQuick.Controls 2.12

// Item {
//     signal loginSuccess()

//     Column {
//         anchors.centerIn: parent
//         spacing: 10

//         TextField {
//             id: usernameField
//             placeholderText: "Username"
//             width: 200
//         }

//         TextField {
//             id: passwordField
//             placeholderText: "Password"
//             echoMode: TextInput.Password
//             width: 200
//         }

        // Button {
        //     text: "Login"
        //     onClicked: {
        //         var xhr = new XMLHttpRequest()
        //         xhr.open("POST", "http://192.168.1.33:8000/login")
        //         xhr.setRequestHeader("Content-Type", "application/json")

        //         xhr.onreadystatechange = function() {
        //             if (xhr.readyState === XMLHttpRequest.DONE) {
        //                 if (xhr.status === 200) {
        //                     try {
        //                         var response = JSON.parse(xhr.responseText)
        //                         console.log(response.status)
        //                         if (response.status/*.success*/ === true) {
        //                             loginSuccess()
        //                             //console.log("Login successful")
        //                             console.log(response.message)
        //                             // Optionally store response.token
        //                         } else {
        //                             //console.log("Login failed: " + (response/*.message */|| "Unknown error"))
        //                             console.log(response.message)
        //                             console.log(response.status)
        //                             //console.log
        //                         }
        //                     } catch (e) {
        //                         console.log("Failed to parse JSON response")
        //                     }
        //                 } else {
        //                     console.log("HTTP error: " + xhr.status)
        //                 }
        //             }
        //         }

        //         // Matches your API requirement: JSON body with username and password as strings
        //         var payload = {
        //             username: usernameField.text,
        //             password: passwordField.text
        //         }
        //         xhr.send(JSON.stringify(payload))
        //     }
        // }
//     }
// }

//https://github.dev/mavlink/qgroundcontrol/blob/master/src/UI/MainWindow.qml
