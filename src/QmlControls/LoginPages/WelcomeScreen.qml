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
    anchors.fill: parent

    property string currentView: "welcome"
    property bool isDarkMode: true

    // Color palette
    property color primaryColor: isDarkMode ? "#6366f1" : "#4f46e5"
    property color primaryHover: isDarkMode ? "#7c3aed" : "#6366f1"
    property color backgroundColor: isDarkMode ? "#0f172a" : "#f8fafc"
    property color surfaceColor: "#ffffff" //isDarkMode ? "#1e293b" : "#ffffff"
    property color textPrimary: isDarkMode ? "#f1f5f9" : "#0f172a"
    property color textSecondary: isDarkMode ? "#94a3b8" : "#64748b"
    property color borderColor: isDarkMode ? "#334155" : "#e2e8f0"
    property color errorColor: "#ef4444"
    property color successColor: "#10b981"


    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio

    function dp(value) {
        return value * baseUnit;
    }

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
            ScrollView {
                anchors.fill: parent
                clip: true

                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                // Content container
                Item {
                    width: parent.width
                    // Make height at least the viewport height to enable centering
                    height: Math.max(contentColumn.height, parent.height)

                    Column {
                        id: contentColumn
                        width: parent.width
                        spacing: dp(5)
                        // Center vertically when content is smaller than viewport
                        anchors.verticalCenter: parent.height > contentColumn.height ?
                                                    parent.verticalCenter : undefined
                        anchors.top: parent.height <= contentColumn.height ?
                                         parent.top : undefined

                        // Logo/Brand Section
                        Rectangle {
                            width: dp(20)
                            height: dp(20)
                            radius: width / 2
                            color: primaryColor
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: dp(15)
                                height: dp(15)
                                radius: width / 2
                                color: Qt.rgba(1, 1, 1, 0.2)
                                anchors.centerIn: parent

                                Text {
                                    text: "A"
                                    font.pixelSize: dp(10)
                                    font.bold: true
                                    color: "white"
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        // Welcome Text
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: dp(1.5)
                            width: parent.width * 0.85

                            Text {
                                text: "Welcome Back"
                                //font.pixelSize: dp(6)
                                font.pointSize:     ScreenTools.largeFontPointSize
                                font.weight: Font.Bold
                                color: textPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                text: "Sign in to continue your journey"
                                //font.pixelSize: dp(3)
                                font.pointSize:     ScreenTools.smallFontPointSize
                                color: textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Action Buttons
                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: dp(4)
                            width: parent.width * 0.3

                            Button {
                                id: signInBtn
                                text: "Sign In"
                                width: parent.width
                                height: dp(10)

                                background: Rectangle {
                                    radius: dp(1.5)
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
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize
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
                                height: dp(10)

                                background: Rectangle {
                                    radius: dp(1.5)
                                    color: signUpBtn.pressed ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                    border.width: 2
                                    border.color: borderColor
                                }

                                contentItem: Text {
                                    text: parent.text
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
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
                            spacing: dp(1.5)
                            visible: false

                            Text {
                                text: isDarkMode ? "Night" : "Day"
                                font.pixelSize: dp(2.5)
                                anchors.verticalCenter: parent.verticalCenter
                                color: "white"
                            }

                            Switch {
                                checked: isDarkMode
                                onToggled: isDarkMode = !isDarkMode
                            }
                        }
                    }
                }
            }
        }

        // SIGN IN SCREEN
        Item {
            // Back arrow at top left with margins
            Item {
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: dp(10) // Outer margins
                }

                width: dp(10)
                height: dp(10)
                z: 1 // Ensure it's above the ScrollView

                QGCColoredImage {
                    anchors.centerIn: parent
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    fillMode: Image.PreserveAspectFit
                    width: 25
                    height: 25
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        currentView = "welcome"
                        loginUser.text = "";
                        loginPass.text = "";
                    }
                }
            }
            ScrollView {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: dp(12) // Add top margin to avoid overlapping with back button
                }
                clip: true
                contentWidth: -1 // Let content determine width

                // Container to ensure proper centering
                Item {
                    width: parent.width
                    height: Math.max(signInColumn.implicitHeight, parent.height)

                    Column {
                        id: signInColumn
                        width: parent.width * 0.85
                        spacing: dp(4)
                        anchors.centerIn: parent

                        // Header
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Sign In"
                                //font.pixelSize: dp(6)
                                font.pointSize:     ScreenTools.largeFontPointSize
                                font.weight: Font.Bold
                                color: textPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Welcome back! Please enter your details"
                                //font.pixelSize: dp(3)
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Form
                        Column {
                            width: parent.width
                            spacing: dp(4)
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Username Field
                            Column {
                                width: parent.width
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter


                                Text {
                                    text: "Username"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    color: textPrimary
                                    x: parent.width * 0.25
                                }

                                Rectangle {
                                    width: parent.width * 0.5
                                    height: dp(10) // Use dp instead of relative height
                                    radius: dp(1) // 8/8=1
                                    color: surfaceColor
                                    border.width: loginUser.activeFocus ? 2 : 1
                                    border.color: loginUser.activeFocus ? primaryColor : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    TextField {
                                        id: loginUser
                                        anchors.fill: parent
                                        //anchors.margins: dp(2) // 16/8=2
                                        placeholderText: "Enter your username"
                                        //font.pixelSize: dp(4)
                                        font.pointSize:     ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black"//textPrimary
                                        background: null
                                        selectByMouse: true
                                    }
                                }
                            }

                            // Password Field
                            Column {
                                width: parent.width
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "Password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    color: textPrimary
                                    x: parent.width * 0.25
                                }

                                Rectangle {
                                    width: parent.width * 0.5
                                    height: dp(10) // Use dp instead of relative height
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: loginPass.activeFocus ? 2 : 1
                                    border.color: loginPass.activeFocus ? primaryColor : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    TextField {
                                        id: loginPass
                                        anchors {
                                            left: parent.left
                                            right: showPasswordBtn.left
                                            top: parent.top
                                            bottom: parent.bottom
                                            //margins: dp(2)
                                        }
                                        placeholderText: "Enter your password"
                                        //font.pixelSize: dp(4)
                                        font.pointSize:     ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black" //textPrimary
                                        echoMode: showPasswordBtn.checked ? TextInput.Normal : TextInput.Password
                                        background: null
                                        selectByMouse: true
                                    }

                                    Button {
                                        id: showPasswordBtn
                                        width: dp(6) // Adjusted size
                                        height: dp(6)
                                        anchors {
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            margins: dp(1)
                                        }
                                        checkable: true

                                        background: Rectangle {
                                            radius: dp(0.75) // 6/8=0.75
                                            color: parent.pressed ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                                        }

                                        contentItem: Text {
                                            text: parent.checked ? "👁️" : "👁️‍🗨️"
                                            font.pixelSize: dp(3) // Adjusted size
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                // Forgot Password
                                Text {
                                    text: "Forgot Password?"
                                    //font.pixelSize: dp(3.5) // Adjusted size
                                    font.pointSize:     ScreenTools.smallFontPointSize
                                    color: primaryColor
                                    x: parent.width * 0.6

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            currentView = "reset"
                                            loginUser.text = "";
                                            loginPass.text = "";
                                        }
                                    }
                                }
                            }

                            // Sign In Button
                            Button {
                                id: loginBtn
                                text: "Sign In"
                                width: parent.width * 0.2
                                height: dp(10) // Adjusted size
                                anchors.horizontalCenter: parent.horizontalCenter

                                background: Rectangle {
                                    radius: dp(1)
                                    color: loginBtn.pressed ? primaryHover : primaryColor
                                }

                                contentItem: Text {
                                    text: parent.text
                                    //font.pixelSize: dp(4) // Adjusted size
                                    font.pointSize:     ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {

                                    if (loginUser.text.trim() === "" || loginPass.text === "") {
                                        mainWindow.showToastMessage("Please fill all fields");
                                        return;
                                    }

                                    mainWindow.loginUserFunc(loginUser.text, loginPass.text, function(result) {

                                        QGroundControl.saveGlobalSetting("username", loginUser.text.trim());
                                        console.log("userName put in SharedPreference : ",loginUser.text)

                                        if(result){
                                            loginUser.text = "";
                                            loginPass.text = "";
                                        }
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        // SIGN UP SCREEN
        Item {
            // Back arrow at top left with margins
            Item {
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: dp(10)
                }
                width: dp(10)
                height: dp(10)
                z: 10 // Ensure it's above the ScrollView

                QGCColoredImage {
                    anchors.centerIn: parent
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    fillMode: Image.PreserveAspectFit
                    width: 25
                    height: 25

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {

                            currentView = "welcome"

                            regUser.text = "";
                            regDisplay.text = "";
                            regEmail.text = "";
                            regPass.text = "";
                            regConfirm.text = "";
                        }
                    }
                }
            }

            ScrollView {
                anchors.fill: parent
                clip: true
                contentWidth: -1

                Column {
                    id: signUpColumn
                    width: parent.width * 0.85
                    spacing: dp(4)
                    anchors.horizontalCenter: parent.horizontalCenter

                    // Header
                    Column {
                        width: parent.width
                        spacing: dp(2)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "Create Account"
                            //font.pixelSize: dp(6)
                            font.pointSize:     ScreenTools.largeFontPointSize
                            font.weight: Font.Bold
                            color: textPrimary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "Join us today! Please fill in your details"
                            //font.pixelSize: dp(3)
                            font.pointSize:     ScreenTools.smallFontPointSize
                            color: textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Form Fields
                    Column {
                        width: parent.width
                        spacing: dp(4)
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Username
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Username"
                                //font.pixelSize: dp(4)
                                font.pointSize:     ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                color: textPrimary
                                x: parent.width * 0.25
                            }

                            Rectangle {
                                width: parent.width * 0.5
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regUser.activeFocus ? 2 : 1
                                border.color: regUser.activeFocus ? primaryColor : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regUser
                                    anchors.fill: parent
                                    placeholderText: "Choose a username"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    background: null
                                    selectByMouse: true

                                    validator: RegularExpressionValidator {
                                        regularExpression: /^[a-zA-Z\s]*$/ // Allows only letters and spaces
                                    }
                                }
                            }
                        }

                        // Display Name
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Display Name"
                                //font.pixelSize: dp(4)
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                color: textPrimary
                                x: parent.width * 0.25
                            }

                            Rectangle {
                                width: parent.width * 0.5
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regDisplay.activeFocus ? 2 : 1
                                border.color: regDisplay.activeFocus ? primaryColor : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regDisplay
                                    anchors.fill: parent
                                    placeholderText: "Your display name"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    background: null
                                    selectByMouse: true

                                    validator: RegularExpressionValidator {
                                        regularExpression: /^[a-zA-Z\s]*$/ // Allows only letters and spaces
                                    }
                                }
                            }
                        }

                        // Email
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Email"
                                //font.pixelSize: dp(4)
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                color: textPrimary
                                x: parent.width * 0.25
                            }

                            Rectangle {
                                width: parent.width * 0.5
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regEmail.activeFocus ? 2 : 1
                                border.color: regEmail.activeFocus ? primaryColor : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regEmail
                                    anchors.fill: parent
                                    placeholderText: "your.email@example.com"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    background: null
                                    selectByMouse: true

                                    validator: RegularExpressionValidator {
                                        regularExpression: /^[a-zA-Z0-9@._-]*$/ // Email allowed characters
                                    }
                                    inputMethodHints: Qt.ImhEmailCharactersOnly
                                }
                            }
                        }

                        // Password
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Password"
                                //font.pixelSize: dp(4)
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                color: textPrimary
                                x: parent.width * 0.25
                            }

                            Rectangle {
                                width: parent.width * 0.5
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regPass.activeFocus ? 2 : 1
                                border.color: regPass.activeFocus ? primaryColor : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regPass
                                    anchors.fill: parent
                                    placeholderText: "Create a strong password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    echoMode: TextInput.Password
                                    background: null
                                    selectByMouse: true
                                }
                            }
                        }

                        // Confirm Password
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Confirm Password"
                                //font.pixelSize: dp(4)
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                color: textPrimary
                                x: parent.width * 0.25
                            }

                            Rectangle {
                                width: parent.width * 0.5
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regConfirm.activeFocus ? 2 : 1
                                border.color: regConfirm.activeFocus ? primaryColor : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regConfirm
                                    anchors.fill: parent
                                    placeholderText: "Confirm your password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    echoMode: TextInput.Password
                                    background: null
                                    selectByMouse: true
                                }
                            }
                        }
                    }

                    // Action Buttons
                    Column {
                        width: parent.width
                        spacing: dp(3)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Button {
                            id: signUpActionBtn
                            text: "Create Account"
                            width: parent.width * 0.5
                            height: dp(10)
                            anchors.horizontalCenter: parent.horizontalCenter

                            background: Rectangle {
                                radius: dp(1)
                                color: signUpActionBtn.pressed ? primaryHover : primaryColor
                            }

                            contentItem: Text {
                                text: parent.text
                                //font.pixelSize: dp(4)
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                // Execute validations in order
                                if (!mainWindow.validateUsername(regUser.text,regUser)) return;
                                if (!mainWindow.validateDisplayName(regDisplay.text,regDisplay)) return;
                                if (!mainWindow.validateEmail(regEmail.text,regEmail)) return;
                                if (!mainWindow.validatePassword(regPass.text,regPass)) return;
                                if (!mainWindow.validateConfirmPassword(regPass.text, regConfirm.text,regConfirm)) return;

                                mainWindow.registerUser(regUser.text, regDisplay.text, regEmail.text, regPass.text, regConfirm.text, function(result) {
                                    if (result) {

                                        mainWindow.showToastMessage("Account created successfully!");

                                        currentView = "signin";

                                        QGroundControl.saveGlobalSetting("username", regUser.text);
                                        QGroundControl.saveGlobalSetting("name", regDisplay.text);
                                        QGroundControl.saveGlobalSetting("email", regEmail.text);

                                        regUser.text = "";
                                        regDisplay.text = "";
                                        regEmail.text = "";
                                        regPass.text = "";
                                        regConfirm.text = "";
                                    }
                                });

                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: dp(0.5)

                            Text {
                                text: "Already have an account?"
                                //font.pixelSize: dp(3.5)
                                font.pointSize: ScreenTools.defaultFontPointSize
                                color: textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Button {
                                text: "Sign In"
                                width: undefined

                                background: Rectangle {
                                    color: "transparent"
                                }

                                contentItem: Text {
                                    text: parent.text
                                    //font.pixelSize: dp(3.5)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    color: primaryColor
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

        // RESET PASSWORD SCREEN
        Item {
            // Back arrow at top left with margins
            Item {
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: dp(8)
                }
                width: dp(10)
                height: dp(10)
                z: 1 // Ensure it's above the ScrollView

                QGCColoredImage {
                    anchors.centerIn: parent
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    fillMode: Image.PreserveAspectFit
                    width: 25
                    height: 25
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentView = "signin" // Go back to sign in instead of welcome
                }
            }

            ScrollView {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: dp(12) // Add top margin to avoid overlapping with back button
                }
                clip: true
                contentWidth: -1

                // Container to ensure proper centering
                Item {
                    width: parent.width
                    height: Math.max(resetColumn.implicitHeight, parent.height)

                    Column {
                        id: resetColumn
                        width: parent.width * 0.85
                        spacing: dp(4)
                        anchors.centerIn: parent

                        // Header
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Reset Password"
                                //font.pixelSize: dp(6)
                                font.pointSize: ScreenTools.largeFontPointSize
                                font.weight: Font.Bold
                                color: textPrimary
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Enter your username and new password"
                                //font.pixelSize: dp(3)
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Form
                        Column {
                            width: parent.width
                            spacing: dp(4)
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Username Field
                            Column {
                                width: parent.width
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "Username"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    color: textPrimary
                                    x: parent.width * 0.25
                                }

                                Rectangle {
                                    width: parent.width * 0.5
                                    height: dp(10)
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: resetUser.activeFocus ? 2 : 1
                                    border.color: resetUser.activeFocus ? primaryColor : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    TextField {
                                        id: resetUser
                                        anchors.fill: parent
                                        placeholderText: "Enter your username"
                                        //font.pixelSize: dp(4)
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black"
                                        background: null
                                        selectByMouse: true
                                    }
                                }
                            }

                            // New Password Field
                            Column {
                                width: parent.width
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "New Password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    color: textPrimary
                                    x: parent.width * 0.25
                                }

                                Rectangle {
                                    width: parent.width * 0.5
                                    height: dp(10)
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: newPassword.activeFocus ? 2 : 1
                                    border.color: newPassword.activeFocus ? primaryColor : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    TextField {
                                        id: newPassword
                                        anchors.fill: parent
                                        placeholderText: "Enter your new password"
                                        //font.pixelSize: dp(4)
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black"
                                        echoMode: TextInput.Password
                                        background: null
                                        selectByMouse: true
                                    }
                                }
                            }
                        }

                        // Action Buttons
                        Column {
                            width: parent.width
                            spacing: dp(3)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                id: resetBtn
                                text: "Reset Password"
                                width: parent.width * 0.5  // Increased width for better visibility
                                height: dp(10)
                                anchors.horizontalCenter: parent.horizontalCenter

                                background: Rectangle {
                                    radius: dp(1)
                                    color: resetBtn.pressed ? primaryHover : primaryColor
                                }

                                contentItem: Text {
                                    text: parent.text
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    // Basic validation
                                    if (resetUser.text.trim() === "" || newPassword.text === "") {
                                        mainWindow.showToastMessage("Please fill all fields");
                                        return;
                                    }

                                    if (newPassword.text.length < 8) {
                                        mainWindow.showToastMessage("Password must be at least 8 characters");
                                        newPassword.focus = true;
                                        return;
                                    }

                                    // Disable button during operation
                                    resetBtn.enabled = false;
                                    resetBtn.text = "Resetting...";

                                    // Call the resetPassword function with a callback
                                    mainWindow.resetPassword(resetUser.text, newPassword.text, function(result) {
                                        if (result.success) {
                                            mainWindow.showToastMessage(result.message);
                                            currentView = "signin";
                                            resetUser.text = "";
                                            newPassword.text = "";
                                        } else {
                                            mainWindow.showToastMessage(result.message);
                                            resetUser.focus = true;
                                        }

                                        // Re-enable button
                                        resetBtn.enabled = true;
                                        resetBtn.text = "Reset Password";
                                    });
                                }
                            }
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
