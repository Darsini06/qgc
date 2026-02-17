import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.LocalStorage 2.0


import QtQuick.Layouts 1.15

Item {
    id: root
    width: 400
    height: 800

    property string currentView: "welcome"  // options: welcome, signup, signin

    StackLayout {
        anchors.fill: parent
        //currentIndex: currentView === "welcome" ? 0 : (currentView === "signin" ? 1 : 2)
        currentIndex: currentView === "welcome" ? 0
                      : (currentView === "signin" ? 1
                      : (currentView === "signup" ? 2
                      : 3))  // New: forgot password screen is index 3

        // WELCOME SCREEN
        Rectangle {
            color: "#D3D3D3"
            anchors.fill: parent

            Column {
                spacing: 20
                width: parent.width * 0.8
                anchors.centerIn: parent
                Rectangle {
                    width: parent.width
                    height: 300
                    radius: 20
                    color: "#808080"
                    Column {
                        //width: parent.width
                        anchors.centerIn: parent
                        spacing: 20
                        Text {
                            text: "WELCOME TO FLYTUTOR APP"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#e0e4ff"
                            //horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 20
                            Button {
                                text: "Sign IN"
                                onClicked: currentView = "signin"

                                font.bold: true
                                font.pixelSize: 16
                                anchors.leftMargin: 40   // Left padding
                                            anchors.rightMargin: 40  // Right padding
                                            anchors.topMargin: 10    // Top padding
                                            anchors.bottomMargin: 10
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "white"  // Set text color
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    anchors.leftMargin: 40   // Left padding
                                                anchors.rightMargin: 40  // Right padding
                                                anchors.topMargin: 10    // Top padding
                                                anchors.bottomMargin: 10 // Bottom padding
                                }
                                background: Rectangle {
                                    color: "#007AFF"  // Blue color (iOS-style button)
                                    radius: 20  // Curved button
                                    border.color: "#005BBB"  // Border color
                                    border.width: 2
                                }
                            }
                            Button {
                                text: "Sign UP"
                                onClicked: currentView = "signup"
                                anchors.leftMargin: 40   // Left padding
                                            anchors.rightMargin: 40  // Right padding
                                            anchors.topMargin: 10    // Top padding
                                            anchors.bottomMargin: 10
                                font.bold: true
                                            font.pixelSize: 16
                                            contentItem: Text {
                                                text: parent.text
                                                font: parent.font
                                                color: "white"  // Set text color
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                anchors.leftMargin: 40   // Left padding
                                                            anchors.rightMargin: 40  // Right padding
                                                            anchors.topMargin: 10    // Top padding
                                                            anchors.bottomMargin: 10 // Bottom padding
                                            }
                                background: Rectangle {
                                    color: "#007AFF"  // Blue color (iOS-style button)
                                    radius: 20  // Curved button
                                    border.color: "#005BBB"  // Border color
                                    border.width: 2
                                }
                            }
                        }
                    }
                }
            }
        }

        // SIGN IN SCREEN
        Rectangle {
            color: "#D3D3D3"
            anchors.fill: parent

            // Main vertical layout
            Column {
                anchors.centerIn: parent
                spacing: 15
                width: parent.width * 0.5

                // Centered Sign In text
                Text {
                    text: "Sign In"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                TextField {
                    id: loginUser
                    placeholderText: "User Name"
                    width: parent.width
                }

                TextField {
                    id: loginPass
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    width: parent.width
                }

                // Forgot Password aligned bottom-right of password field
                Item {
                    width: parent.width
                    height: 20

                    Text {
                        text: "Forgot Password?"
                        font.pixelSize: 14
                        color: "blue"
                        anchors.right: parent.right
                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                currentView = "reset"
                                console.log("Forgot Password clicked")
                            }

                        }
                    }
                }

                Button {
                    text: "Log IN"
                    width: 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        // loginUserFunc(loginUser.text, loginPass.text)
                        mainWindow.loginUserFunc(loginUser.text, loginPass.text)
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"  // Set text color
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        anchors.leftMargin: 40   // Left padding
                                    anchors.rightMargin: 40  // Right padding
                                    anchors.topMargin: 10    // Top padding
                                    anchors.bottomMargin: 10 // Bottom padding
                    }
                }
            }

            // Back to Home in bottom-left
            Button {
                text: "Back to Home"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 20
                onClicked: currentView = "welcome"
            }
        }

        // SIGN UP SCREEN
        Rectangle {
            color: "#D3D3D3"
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                spacing: 15
                width: parent.width * 0.5

                Text { text: "SIGN UP";
                    font.pixelSize: 20;
                    font.bold: true;
                    width: parent.width;
                horizontalAlignment: Text.AlignHCenter}

                TextField { id: regUser; placeholderText: "User Name";width: parent.width}
                TextField { id: regDisplay; placeholderText: "Display Name";width: parent.width }
                TextField { id: regEmail; placeholderText: "Email";width: parent.width }
                TextField { id: regPass; placeholderText: "Password"; echoMode: TextInput.Password;width: parent.width }
                TextField { id: regConfirm; placeholderText: "Confirm Password"; echoMode: TextInput.Password;width: parent.width }

                Row {

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Button {
                        text: "Log IN"
                        onClicked: currentView = "signin"
                    }

                    Button {
                        text: "Sign UP"
                        onClicked: {
                            function validateField(field, message) {
                                        if (field.text === "") {
                                            mainWindow.showToastMessage(message);
                                            return false;
                                        }
                                        return true;
                                    }

                                    if (!validateField(regUser, "Please Enter User Name")) return;
                                    if (!validateField(regDisplay, "Please Enter Display Name")) return;
                                    if (!validateField(regEmail, "Please Enter Email")) return;
                                    if (!validateField(regPass, "Please Enter Password")) return;
                                    if (!validateField(regConfirm, "Please Enter Confirm Password")) return;


                             if (regPass.text === regConfirm.text) {
                                // registerUser(regUser.text, regPass.text)
                                MapGlobals.registerUser(regUser.text,regDisplay.text,regEmail.text, regPass.text,regConfirm.text)
                                 currentView = "signin"
                            } else {
                                console.log("Passwords don't match")
                                mainWindow.showToastMessage("Passwords don't match");
                            }
                        }
                    }
                }

                // Text { text: "or" }

                // Row {
                //     spacing: 10
                //     Image { source: "google.png"; width: 30; height: 30 }
                //     Image { source: "facebook.png"; width: 30; height: 30 }
                //     Image { source: "linkedin.png"; width: 30; height: 30 }
                // }
            }

            Button {
                text: "Back to Home"
                onClicked: currentView = "welcome"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 20
            }
        }


        // FORGOT PASSWORD SCREEN
        Rectangle {
            color: "#D3D3D3"
            anchors.fill: parent

            Column {
                anchors.centerIn: parent
                spacing: 15
                width: parent.width * 0.5

                Text {
                    text: "Reset Password"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                TextField {
                    id: resetUser
                    placeholderText: "Enter your username"
                    width: parent.width
                }

                TextField {
                    id: newPassword
                    placeholderText: "New Password"
                    echoMode: TextInput.Password
                    width: parent.width
                }

                Button {
                    text: "Reset"
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        if (resetUser.text && newPassword.text) {
                            mainWindow.resetPassword(resetUser.text, newPassword.text)
                            currentView = "signin"

                        } else {
                            mainWindow.showToastMessage("Please fill all fields");
                            console.log("Please fill all fields")
                        }
                    }
                }

                Button {
                    text: "Back to Login"
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: currentView = "signin"
                }
            }
        }


    //     Rectangle {
    //         color: "#D3D3D3"
    //         anchors.fill: parent

    //         Column {
    //             anchors.centerIn: parent
    //             spacing: 15

    //             Text { text: "SIGN UP"; font.pixelSize: 20; font.bold: true }

    //             TextField { id: regUser; placeholderText: "User Name" }
    //             TextField { id: regDisplay; placeholderText: "Display Name" }
    //             TextField { id: regEmail; placeholderText: "Email" }
    //             TextField { id: regPass; placeholderText: "Password"; echoMode: TextInput.Password }
    //             TextField { id: regConfirm; placeholderText: "Confirm Password"; echoMode: TextInput.Password }

    //             Row {
    //                 spacing: 10
    //                 Button {
    //                     text: "Log IN"
    //                     onClicked: currentView = "signin"
    //                 }

    //                 Button {
    //                     text: "Sign UP"
    //                     onClicked: {
    //                         if (regPass.text === regConfirm.text) {
    //                             // registerUser(regUser.text, regPass.text)
    //                         } else {
    //                             console.log("Passwords don't match")
    //                         }
    //                     }
    //                 }
    //             }

    //             Text { text: "or" }

    //             Row {
    //                 spacing: 10
    //                 Image { source: "google.png"; width: 30; height: 30 }
    //                 Image { source: "facebook.png"; width: 30; height: 30 }
    //                 Image { source: "linkedin.png"; width: 30; height: 30 }
    //             }

    //             Button {
    //                 text: "Back to Home"
    //                 onClicked: currentView = "welcome"
    //             }
    //         }
    //     }

    }


}
