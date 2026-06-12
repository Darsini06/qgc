import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: changePasswordRoot
    anchors.fill: parent

    property color app_color:     MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#262626"
    property color accent_color:  MapGlobals.rootWindow ? MapGlobals.rootWindow.accent_color : "#262626"
    property color bg_color:      "#f8f9fa"

    property bool showOldPass:     false
    property bool showNewPass:     false
    property bool showConfirmPass: false

    signal backClicked()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        /* ================= LEFT SIDEBAR ================= */
        Rectangle {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.45
            color: "#000000"
            clip: true

            // Background Gradient
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#1A1A1A" }
                    GradientStop { position: 1.0; color: "#000000" }
                }
            }

            // Decorative Accent
            Rectangle {
                width: 300; height: 300; radius: 150
                color: Qt.rgba(255,255,255,0.03)
                anchors.bottom: parent.bottom
                anchors.right:  parent.right
                anchors.bottomMargin: -50
                anchors.rightMargin:  -50
            }

            // Back Arrow pinned to top-left
            Rectangle {
                width: 44; height: 44; radius: 12
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.topMargin:  20
                anchors.leftMargin: 20
                z: 10
                color:        backMouse.containsMouse ? Qt.rgba(255,255,255,0.2) : Qt.rgba(255,255,255,0.08)
                border.color: Qt.rgba(255,255,255,0.2)

                QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    width: 22; height: 22; color: "white"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: changePasswordRoot.backClicked()
                }
            }

            // Centered sidebar content
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 60
                spacing: 24

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Change Password"
                        color: "white"
                        font.bold: true
                        font.pointSize: 24
                        font.family: "Outfit"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        text: "Keep your account secure by\nupdating your password regularly."
                        color: Qt.rgba(255,255,255,0.6)
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.family: "Outfit"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Tip box
                Rectangle {
                    Layout.fillWidth: true
                    height: tipCol.implicitHeight + 20
                    radius: 12
                    color: Qt.rgba(255,255,255,0.08)
                    border.color: Qt.rgba(255,255,255,0.12)

                    ColumnLayout {
                        id: tipCol
                        anchors.centerIn: parent
                        width: parent.width - 24
                        spacing: 6

                        Text {
                            text: "PASSWORD TIPS"
                            color: Qt.rgba(255,255,255,0.5)
                            font.pointSize: 7; font.bold: true
                            font.letterSpacing: 1.2
                            font.family: "Outfit"
                        }
                        // REPLACE WITH:
                        Text { text: "• Minimum 6 characters";                    color: Qt.rgba(255,255,255,0.7); font.pointSize: ScreenTools.smallFontPointSize; font.family: "Outfit" }
                        Text { text: "• At least one uppercase letter (A-Z)";     color: Qt.rgba(255,255,255,0.7); font.pointSize: ScreenTools.smallFontPointSize; font.family: "Outfit" }
                        Text { text: "• At least one lowercase letter (a-z)";     color: Qt.rgba(255,255,255,0.7); font.pointSize: ScreenTools.smallFontPointSize; font.family: "Outfit" }
                        Text { text: "• At least one number (0-9)";               color: Qt.rgba(255,255,255,0.7); font.pointSize: ScreenTools.smallFontPointSize; font.family: "Outfit" }
                        Text { text: "• At least one special character (!@#$%)";  color: Qt.rgba(255,255,255,0.7); font.pointSize: ScreenTools.smallFontPointSize; font.family: "Outfit" }
                    }
                }
            }
        }

        /* ================= RIGHT SIDE (Form) ================= */
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: bg_color

            Flickable {
                anchors.fill: parent
                contentHeight: formColumn.height + 100
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: formColumn
                    width: Math.min(parent.width - 80, 480)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 50
                    spacing: 24

                    // Heading
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "UPDATE PASSWORD"
                            color: "#94a3b8"
                            font.pointSize: 9; font.bold: true
                            font.letterSpacing: 1.2
                            font.family: "Outfit"
                        }
                        Text {
                            text: "Enter your current password and set a new one"
                            color: "#64748b"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.family: "Outfit"
                        }
                    }

                    // Divider
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#e2e8f0" }

                    // Current Password
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Row {
                            spacing: 4
                            Text { text: "Current Password";  font.pointSize: ScreenTools.defaultFontPointSize * 0.9; font.weight: Font.DemiBold; color: "#1e293b"; font.family: "Outfit" }
                            Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "#ef4444" }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10
                            border.color: oldPasswordInput.activeFocus ? app_color : "#e2e8f0"
                            border.width:  oldPasswordInput.activeFocus ? 2 : 1
                            color: "#ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14; anchors.rightMargin: 8
                                spacing: 8

                                TextField {
                                    id: oldPasswordInput
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    echoMode:        changePasswordRoot.showOldPass ? TextInput.Normal : TextInput.Password
                                    placeholderText: "Enter current password"
                                    font.pointSize:  ScreenTools.defaultFontPointSize
                                    font.family:     "Outfit"
                                    color:           "#1e293b"
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: null
                                }

                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    color: "transparent"
                                    Image {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        fillMode: Image.PreserveAspectFit
                                        source: changePasswordRoot.showOldPass
                                                ? "/qmlimages/NewImages/password_visible.svg"
                                                : "/qmlimages/NewImages/password_hidden.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: changePasswordRoot.showOldPass = !changePasswordRoot.showOldPass
                                    }
                                }
                            }
                        }
                    }

                    // New Password
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Row {
                            spacing: 4
                            Text { text: "New Password"; font.pointSize: ScreenTools.defaultFontPointSize * 0.9; font.weight: Font.DemiBold; color: "#1e293b"; font.family: "Outfit" }
                            Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "#ef4444" }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10
                            border.color: newPasswordInput.activeFocus ? app_color : "#e2e8f0"
                            border.width:  newPasswordInput.activeFocus ? 2 : 1
                            color: "#ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14; anchors.rightMargin: 8
                                spacing: 8

                                TextField {
                                    id: newPasswordInput
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    echoMode:        changePasswordRoot.showNewPass ? TextInput.Normal : TextInput.Password
                                    placeholderText: "Minimum 6 characters"
                                    font.pointSize:  ScreenTools.defaultFontPointSize
                                    font.family:     "Outfit"
                                    color:           "#1e293b"
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: null
                                }

                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    color: "transparent"
                                    Image {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        fillMode: Image.PreserveAspectFit
                                        source: changePasswordRoot.showNewPass
                                                ? "/qmlimages/NewImages/password_visible.svg"
                                                : "/qmlimages/NewImages/password_hidden.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: changePasswordRoot.showNewPass = !changePasswordRoot.showNewPass
                                    }
                                }
                            }
                        }
                    }

                    // Confirm Password
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Row {
                            spacing: 4
                            Text { text: "Confirm Password"; font.pointSize: ScreenTools.defaultFontPointSize * 0.9; font.weight: Font.DemiBold; color: "#1e293b"; font.family: "Outfit" }
                            Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "#ef4444" }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 10
                            border.color: confirmPasswordInput.activeFocus ? app_color : "#e2e8f0"
                            border.width:  confirmPasswordInput.activeFocus ? 2 : 1
                            color: "#ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14; anchors.rightMargin: 8
                                spacing: 8

                                TextField {
                                    id: confirmPasswordInput
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    echoMode:        changePasswordRoot.showConfirmPass ? TextInput.Normal : TextInput.Password
                                    placeholderText: "Confirm new password"
                                    font.pointSize:  ScreenTools.defaultFontPointSize
                                    font.family:     "Outfit"
                                    color:           "#1e293b"
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: null
                                }

                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    color: "transparent"
                                    Image {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        fillMode: Image.PreserveAspectFit
                                        source: changePasswordRoot.showConfirmPass
                                                ? "/qmlimages/NewImages/password_visible.svg"
                                                : "/qmlimages/NewImages/password_hidden.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: changePasswordRoot.showConfirmPass = !changePasswordRoot.showConfirmPass
                                    }
                                }
                            }
                        }
                    }

                    // Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Button {
                            id: cancelBtn
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 48
                            text: "Cancel"

                            background: Rectangle {
                                radius: 10
                                color: cancelBtn.hovered ? "#dc2626" : "#ef4444"   // Dark red on hover
                                border.color: "#b91c1c"
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }

                            contentItem: Text {
                                text: cancelBtn.text
                                color: "white"
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                font.family: "Outfit"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                oldPasswordInput.text    = ""
                                newPasswordInput.text    = ""
                                confirmPasswordInput.text = ""
                                changePasswordRoot.showOldPass     = false
                                changePasswordRoot.showNewPass     = false
                                changePasswordRoot.showConfirmPass = false
                                changePasswordRoot.backClicked()
                            }
                        }

                        Button {
                            id: saveBtn
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 48
                                text: "Save"
                            background: Rectangle {
                                radius: 10
                                color: saveBtn.pressed ? Qt.darker(app_color, 1.15) : (saveBtn.hovered ? Qt.lighter(app_color, 1.1) : app_color)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            contentItem: Text {
                                text: parent.text; color: "white"
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.DemiBold; font.family: "Outfit"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                            }
                            onClicked: {
                                if (oldPasswordInput.text === "") {
                                    showMessage("Enter current password!")
                                    return
                                }
                                if (newPasswordInput.text !== confirmPasswordInput.text) {
                                    showMessage("Passwords do not match!")
                                    return
                                }
                                var pwd = newPasswordInput.text
                                if (pwd.length < 6) {
                                    showMessage("Password must be at least 6 characters!")
                                    return
                                }
                                if (!/[A-Z]/.test(pwd)) {
                                    showMessage("Password must contain at least one uppercase letter!")
                                    return
                                }
                                if (!/[a-z]/.test(pwd)) {
                                    showMessage("Password must contain at least one lowercase letter!")
                                    return
                                }
                                if (!/[0-9]/.test(pwd)) {
                                    showMessage("Password must contain at least one number!")
                                    return
                                }
                                if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(pwd)) {
                                    showMessage("Password must contain at least one special character!")
                                    return
                                }
                                changePasswordAPI()
                            }
                        }
                    }
                }
            }
        }
    }

    // Message Dialog
    Dialog {
        id: messageDialog
        modal: true
        anchors.centerIn: parent
        width: 320
        padding: 0

        property string messageDialogText: ""

        background: Rectangle { color: "white"; radius: 12 }

        contentItem: Item {
            implicitHeight: msgCol.implicitHeight + 48

            ColumnLayout {
                id: msgCol
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 24

                Text {
                    text: messageDialog.messageDialogText
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.05
                    font.weight: Font.Medium; font.family: "Outfit"
                    color: "#1e293b"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Button {
                    id: msgOkBtn
                    Layout.fillWidth: true; height: 45
                    text: "OK"
                    background: Rectangle {
                        radius: 8
                        color: msgOkBtn.pressed ? Qt.darker(app_color, 1.15) : (msgOkBtn.hovered ? Qt.lighter(app_color, 1.1) : app_color)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    contentItem: Text {
                        text: parent.text; color: "white"
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.DemiBold; font.family: "Outfit"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                    }
                    onClicked: messageDialog.close()
                }
            }
        }

        Overlay.modal: Rectangle { color: Qt.rgba(0,0,0,0.5) }
    }

    function showMessage(msg) {
        messageDialog.messageDialogText = msg
        messageDialog.open()
    }

    function changePasswordAPI() {
        var xhr = new XMLHttpRequest()
        var url = MapGlobals.backendUrl + "/change-password"
        xhr.open("POST", url)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var res = JSON.parse(xhr.responseText)
                    showMessage(res.message)
                    oldPasswordInput.text     = ""
                    newPasswordInput.text     = ""
                    confirmPasswordInput.text = ""
                    changePasswordRoot.backClicked()
                } else {
                    try {
                        var err = JSON.parse(xhr.responseText)
                        showMessage(err.message || "Error occurred")
                    } catch (e) {
                        showMessage("Server error, please try again")
                    }
                }
            }
        }

        xhr.onerror = function() { showMessage("Network error") }

        xhr.send(JSON.stringify({
            username:    QGroundControl.loadGlobalSetting("username", ""),
            oldPassword: oldPasswordInput.text,
            newPassword: newPasswordInput.text
        }))
    }
}
