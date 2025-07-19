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

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 400
    height: 800

    property string currentView: "welcome"
    property bool isDarkMode: true

    // Color palette
    property color primaryColor: isDarkMode ? "#6366f1" : "#4f46e5"
    property color primaryHover: isDarkMode ? "#7c3aed" : "#6366f1"
    property color backgroundColor: isDarkMode ? "#0f172a" : "#f8fafc"
    property color surfaceColor: isDarkMode ? "#1e293b" : "#ffffff"
    property color textPrimary: isDarkMode ? "#f1f5f9" : "#0f172a"
    property color textSecondary: isDarkMode ? "#94a3b8" : "#64748b"
    property color borderColor: isDarkMode ? "#334155" : "#e2e8f0"
    property color errorColor: "#ef4444"
    property color successColor: "#10b981"

    // Background with gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: backgroundColor }
            GradientStop { position: 1.0; color: isDarkMode ? "#020617" : "#e2e8f0" }
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: currentView === "welcome" ? 0
                      : (currentView === "signin" ? 1
                      : (currentView === "signup" ? 2
                      : 3))

        // WELCOME SCREEN
        Item {
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                Column {
                    anchors.centerIn: parent
                    spacing: 40
                    width: parent.width * 0.85

                    // Logo/Brand Section
                    Rectangle {
                        width: 120
                        height: 120
                        radius: 60
                        color: primaryColor
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: 80
                            height: 80
                            radius: 40
                            color: Qt.rgba(1, 1, 1, 0.2)
                            anchors.centerIn: parent

                            Text {
                                text: "A"
                                font.pixelSize: 48
                                font.bold: true
                                color: "white"
                                anchors.centerIn: parent
                            }
                        }
                    }

                    // Welcome Text
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Text {
                            text: "Welcome Back"
                            font.pixelSize: 32
                            font.weight: Font.Bold
                            color: textPrimary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Sign in to continue your journey"
                            font.pixelSize: 16
                            color: textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Action Buttons
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16
                        width: parent.width * 0.8

                        Button {
                            id: signInBtn
                            text: "Sign In"
                            width: parent.width
                            height: 56

                            background: Rectangle {
                                radius: 12
                                color: signInBtn.pressed ? primaryHover : primaryColor
                                border.width: 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Qt.rgba(1, 1, 1, 0.1)
                                    visible: signInBtn.hovered
                                }
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                welcomeTransition.start()
                                currentView = "signin"
                            }
                        }

                        Button {
                            id: signUpBtn
                            text: "Create Account"
                            width: parent.width
                            height: 56

                            background: Rectangle {
                                radius: 12
                                color: signUpBtn.pressed ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                border.width: 2
                                border.color: borderColor
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                welcomeTransition.start()
                                currentView = "signup"
                            }
                        }
                    }

                    // Theme Toggle
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Text {
                            text: isDarkMode ? "🌙" : "☀️"
                            font.pixelSize: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Switch {
                            checked: isDarkMode
                            onToggled: isDarkMode = !isDarkMode
                        }
                    }
                }
            }
        }

        // SIGN IN SCREEN
        Item {
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                ScrollView {
                    anchors.fill: parent
                    contentWidth: width

                    Column {
                        anchors.centerIn: parent
                        spacing: 24
                        width: parent.width * 0.85

                        // Header
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Text {
                                text: "Sign In"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: textPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Welcome back! Please enter your details"
                                font.pixelSize: 14
                                color: textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        // Form
                        Column {
                            width: parent.width
                            spacing: 20

                            // Username Field
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Username"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: loginUser.activeFocus ? 2 : 1
                                    border.color: loginUser.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: loginUser
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "Enter your username"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }
                                }
                            }

                            // Password Field
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Password"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: loginPass.activeFocus ? 2 : 1
                                    border.color: loginPass.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: loginPass
                                        anchors.left: parent.left
                                        anchors.right: showPasswordBtn.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "Enter your password"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        echoMode: showPasswordBtn.checked ? TextInput.Normal : TextInput.Password
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }

                                    Button {
                                        id: showPasswordBtn
                                        width: 40
                                        height: 40
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: 8
                                        checkable: true

                                        background: Rectangle {
                                            radius: 6
                                            color: parent.pressed ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                                        }

                                        contentItem: Text {
                                            text: parent.checked ? "👁️" : "👁️‍🗨️"
                                            font.pixelSize: 16
                                            anchors.centerIn: parent
                                        }
                                    }
                                }
                            }

                            // Forgot Password
                            Item {
                                width: parent.width
                                height: 24

                                Text {
                                    text: "Forgot Password?"
                                    font.pixelSize: 14
                                    color: primaryColor
                                    anchors.right: parent.right

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: currentView = "reset"
                                    }
                                }
                            }

                            // Sign In Button
                            Button {
                                id: loginBtn
                                text: "Sign In"
                                width: parent.width
                                height: 52

                                background: Rectangle {
                                    radius: 8
                                    color: loginBtn.pressed ? primaryHover : primaryColor
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    mainWindow.loginUserFunc(loginUser.text, loginPass.text)
                                }
                            }
                        }

                        // Back Button
                        Button {
                            text: "← Back to Welcome"
                            anchors.horizontalCenter: parent.horizontalCenter

                            background: Rectangle {
                                radius: 6
                                color: parent.pressed ? Qt.rgba(0, 0, 0, 0.05) : "transparent"
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 14
                                color: textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: currentView = "welcome"
                        }
                    }
                }
            }
        }

        // SIGN UP SCREEN
        Item {
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                ScrollView {
                    anchors.fill: parent
                    contentWidth: width

                    Column {
                        anchors.centerIn: parent
                        spacing: 24
                        width: parent.width * 0.85

                        // Header
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Text {
                                text: "Create Account"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: textPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Join us today! Please fill in your details"
                                font.pixelSize: 14
                                color: textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        // Form Fields
                        Column {
                            width: parent.width
                            spacing: 16

                            // Username
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Username"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: regUser.activeFocus ? 2 : 1
                                    border.color: regUser.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: regUser
                                        anchors.fill: parent
                                        width: parent.width
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "Choose a username"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }
                                }
                            }

                            // Display Name
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Display Name"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: regDisplay.activeFocus ? 2 : 1
                                    border.color: regDisplay.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: regDisplay
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "Your display name"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }
                                }
                            }

                            // Email
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Email"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: regEmail.activeFocus ? 2 : 1
                                    border.color: regEmail.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: regEmail
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "your.email@example.com"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }
                                }
                            }

                            // Password
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Password"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: regPass.activeFocus ? 2 : 1
                                    border.color: regPass.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: regPass
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "Create a strong password"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        echoMode: TextInput.Password
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }
                                }
                            }

                            // Confirm Password
                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: "Confirm Password"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: textPrimary
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 52
                                    radius: 8
                                    color: surfaceColor
                                    border.width: regConfirm.activeFocus ? 2 : 1
                                    border.color: regConfirm.activeFocus ? primaryColor : borderColor

                                    TextField {
                                        id: regConfirm
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        placeholderText: "Confirm your password"
                                        font.pixelSize: 16
                                        font.family: "Arial"
                                        color: textPrimary
                                        echoMode: TextInput.Password
                                        background: null
                                        selectByMouse: true
                                        z: 1
                                    }
                                }
                            }
                        }

                        // Action Buttons
                        Column {
                            width: parent.width
                            spacing: 12

                            Button {
                                id: signUpActionBtn
                                text: "Create Account"
                                width: parent.width
                                height: 52

                                background: Rectangle {
                                    radius: 8
                                    color: signUpActionBtn.pressed ? primaryHover : primaryColor
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

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
                                        mainWindow.registerUser(regUser.text, regDisplay.text, regEmail.text, regPass.text, regConfirm.text)
                                        currentView = "signin"
                                        QGroundControl.saveGlobalSetting("name", regDisplay.text)
                                        QGroundControl.saveGlobalSetting("email", regEmail.text)
                                    } else {
                                        mainWindow.showToastMessage("Passwords don't match");
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 4

                                Text {
                                    text: "Already have an account?"
                                    font.pixelSize: 14
                                    color: textSecondary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Button {
                                    text: "Sign In"

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 14
                                        color: primaryColor
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: currentView = "signin"
                                }
                            }
                        }

                        // Back Button
                        Button {
                            text: "← Back to Welcome"
                            anchors.horizontalCenter: parent.horizontalCenter

                            background: Rectangle {
                                radius: 6
                                color: parent.pressed ? Qt.rgba(0, 0, 0, 0.05) : "transparent"
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 14
                                color: textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: currentView = "welcome"
                        }
                    }
                }
            }
        }

        // RESET PASSWORD SCREEN
        Item {
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                Column {
                    anchors.centerIn: parent
                    spacing: 24
                    width: parent.width * 0.85

                    // Header
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: "Reset Password"
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            color: textPrimary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Enter your username and new password"
                            font.pixelSize: 14
                            color: textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Form
                    Column {
                        width: parent.width
                        spacing: 20

                        // Username Field
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "Username"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: textPrimary
                            }

                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: 8
                                color: surfaceColor
                                border.width: resetUser.activeFocus ? 2 : 1
                                border.color: resetUser.activeFocus ? primaryColor : borderColor

                                TextField {
                                    id: resetUser
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    placeholderText: "Enter your username"
                                    font.pixelSize: 16
                                    font.family: "Arial"
                                    color: textPrimary
                                    background: null
                                    selectByMouse: true
                                    z: 1
                                }
                            }
                        }

                        // New Password Field
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "New Password"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: textPrimary
                            }

                            Rectangle {
                                width: parent.width
                                height: 52
                                radius: 8
                                color: surfaceColor
                                border.width: newPassword.activeFocus ? 2 : 1
                                border.color: newPassword.activeFocus ? primaryColor : borderColor

                                TextField {
                                    id: newPassword
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    placeholderText: "Enter your new password"
                                    font.pixelSize: 16
                                    font.family: "Arial"
                                    color: textPrimary
                                    echoMode: TextInput.Password
                                    background: null
                                    selectByMouse: true
                                    z: 1
                                }
                            }
                        }
                    }

                    // Action Buttons
                    Column {
                        width: parent.width
                        spacing: 12

                        Button {
                            id: resetBtn
                            text: "Reset Password"
                            width: parent.width
                            height: 52

                            background: Rectangle {
                                radius: 8
                                color: resetBtn.pressed ? primaryHover : primaryColor
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (resetUser.text && newPassword.text) {
                                    mainWindow.resetPassword(resetUser.text, newPassword.text)
                                    currentView = "signin"
                                } else {
                                    mainWindow.showToastMessage("Please fill all fields");
                                }
                            }
                        }

                        Button {
                            text: "← Back to Sign In"
                            anchors.horizontalCenter: parent.horizontalCenter

                            background: Rectangle {
                                radius: 6
                                color: parent.pressed ? Qt.rgba(0, 0, 0, 0.05) : "transparent"
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 14
                                color: textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: currentView = "signin"
                        }
                    }
                }
            }
        }
    }





    // Transition Animation
    NumberAnimation {
        id: welcomeTransition
        target: root
        property: "opacity"
        from: 1.0
        to: 0.8
        duration: 150

        onFinished: {
            opacity = 1.0
        }
    }
}
