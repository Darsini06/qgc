import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette

ApplicationWindow {
    id: mainWindow
    minimumWidth: ScreenTools.isMobile ? ScreenTools.screenWidth : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight: ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible: true

    property string planType: "Standard"
    property var _linkManager: QGroundControl.linkManager
    property alias toolSource: pageLoader.source

    Rectangle {
        color: "lightgray"
        anchors.fill: parent

        // 🔝 Top bar with profile icon
        Rectangle {
            id: topBar
            color: "#f0f0f0"
            height: 50
            width: parent.width
            anchors.top: parent.top

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Image {
                    id: profileIcon
                    width: 32
                    height: 32
                    source: "qrc:/InstrumentValueIcons/home.svg"  // Replace with your profile icon path
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            stackView.push("newscreen.qml")
                        }
                    }
                }

                Item { Layout.fillWidth: true }  // Pushes profile icon to the right
            }
        }

        // 📝 Main content area
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "Welcome to the profile screen!"
                font.pixelSize: 24
                Layout.alignment: Qt.AlignHCenter
            }

            // User button in the center of the page
            Button {
                id: userButton
                text: "User"
                Layout.alignment: Qt.AlignHCenter
                onClicked: userPopup.open()
            }
        }

        // Popup for user details (centered)
        Popup {
            id: userPopup
            width: 300
            height: 200
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
            anchors.centerIn: parent

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10

                TextField {
                    id: nameField
                    placeholderText: "Name"
                }

                TextField {
                    id: emailField
                    placeholderText: "Email"
                }

                TextField {
                    id: passwordField
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                }

                Button {
                    text: "Save"
                    onClicked: {
                        saveUserData(nameField.text, emailField.text, passwordField.text)
                        userPopup.close()
                    }
                }
            }
        }

        Loader {
            id: pageLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: toolDrawerToolbar.bottom
            anchors.bottom: parent.bottom

            Connections {
                target: pageLoader.item
                ignoreUnknownSignals: true
                onPopout: toolDrawer.visible = false
            }
        }
    }

    function saveUserData(name, email, password) {
        // Here you can implement the logic to store the data in QGC
        console.log("Name:", name)
        console.log("Email:", email)
        console.log("Password:", password)

        // Example: Store data in QGroundControl settings
        QGroundControl.settingsManager.appSettings.userName = name
        QGroundControl.settingsManager.appSettings.userEmail = email
        QGroundControl.settingsManager.appSettings.userPassword = password

        // Show a message to the user that the data has been saved
        messageDialog.text = "User data saved successfully!"
        messageDialog.open()
    }

    Dialog {
        id: messageDialog
        title: "Success"
        standardButtons: Dialog.Ok
        onAccepted: close()
    }
}
