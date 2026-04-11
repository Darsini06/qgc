import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.15

import MapGlobals 1.0

import Qt.labs.lottieqt 1.0


Item {
    id: root
    anchors.fill: parent
    property var rootWindow: MapGlobals.rootWindow
    property string currentView: "signin"   // signin // signup
    property bool otpSent: false
    property bool isOtpVerified: false

    property string rightSide: "signup"

    property color primaryHover: "#5e3a8a"   // Lighter shade of #301934
    property color surfaceColor: "#ffffff"
    property color textSecondary: "#64748b"

    property color borderColor: "#e2e8f0"

    property color errorColor: "#ef4444"
    property color successColor: "#10b981"

    property color textPrimary: "#000000"

    property color app_color: "#301934"

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio
    property real adaptiveScale: 1.0
       property string pipResizeIcon: ""
       property string pipState: "shrunk"
       property var instrumentPanel: null
       property string _controllerSyncInProgressA: ""





    function dp(value) {
        return value * baseUnit;
    }

    Component.onCompleted: {
        // Set your deployed backend URL
        // MapGlobals.backendUrl = "http://192.168.137.1:5000";
        console.log("Backend server address set to: " + MapGlobals.backendUrl)
    }
    /* ========= BACKGROUND IMAGE ========= */
    /* ========= BACKGROUND IMAGE ========= */
    Image {
        id: bgImage
        anchors.fill: parent
        source: "qrc:/qmlimages/NewImages/background_home.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    Rectangle {
        id: authCard
        width: parent.width * 0.85
        height: parent.height * 0.9
        radius: 12
        anchors.centerIn: parent
        color: surfaceColor
        z: 1

        // Shadow rectangle (keep as is)
        Rectangle {
            id: shadowSource
            // ...
        }

        MultiEffect {
            // ...
        }

        // === SLIDING OVERLAY PANEL - MOVE THIS BEFORE THE FORMS ===
        Rectangle {
            id: overlayPanel
            width: parent.width / 2
            height: parent.height
            radius: 12
            clip: true
            z: 2  // Add z-index to ensure it's above background but below forms? Actually no

            x: currentView === "signin" ? parent.width/2 : 0

            Behavior on x {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }

            Image {
                anchors.fill: parent
                source: "qrc:/qmlimages/NewImages/background_login_premium.png"
                fillMode: Image.PreserveAspectCrop
                smooth: true

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(48/255, 25/255, 52/255, 0.4) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
                    }
                }
            }
        }

        // === BASE FORM LAYER - This should be AFTER overlayPanel? No, overlayPanel should be on top? ===
        // Actually, the overlayPanel should be a SLIDING panel that covers the right side
        // Your forms should be visible on the left

        Item {
            anchors.fill: parent
            z: 1  // Make sure forms are below overlay? This is complex

            Row {
                anchors.fill: parent

                Item {
                    width: parent.width / 2
                    height: parent.height
                    Loader {
                        anchors.fill: parent
                        sourceComponent: signInComponent
                    }
                }

                Item {
                    width: parent.width / 2
                    height: parent.height
                    Loader {
                        anchors.fill: parent
                        sourceComponent: rightSide === "reset" ? resetpwdComponent : signUpComponent
                    }
                }
            }
        }
    }
    // === COMPONENTS ===

    Component {
        id: signInComponent

        ScrollView {
            width: parent.width * 0.6
            height: parent.height
            clip: true

            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Item {
                id: container
                width: parent.width
                height: Math.max(contentColumn.implicitHeight, parent.height)

                Column {
                    id: contentColumn
                    width: parent.width * 0.85
                    spacing: dp(4)

                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: dp(4)

                    // ---------------- HEADER ----------------
                    Column {
                        width: parent.width
                        spacing: dp(2)

                        Text {
                            text: "Welcome Back"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.weight: Font.Bold
                            color: app_color
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }

                        Text {
                            text: "Sign in to continue your journey"
                            font.pointSize: ScreenTools.smallFontPointSize
                            color: textSecondary
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                        }
                    }

                    // ---------------- FORM ----------------
                    Column {
                        id: formColumn
                        width: parent.width * 0.9
                        spacing: dp(3)
                        anchors.horizontalCenter: parent.horizontalCenter

                        // -------- Username --------
                        Column {
                            width: parent.width
                            spacing: dp(2)

                            Row {
                                spacing: dp(1)

                                Text {
                                    text: "Email"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }

                                Text {
                                    text: "*"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                    color: "red"
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor

                                border.width: loginUser.activeFocus ? 2 : 1
                                border.color: loginUser.activeFocus ? app_color : borderColor

                                TextField {
                                    id: loginUser
                                    anchors.fill: parent
                                    placeholderText: "username or email"
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    color: "black"
                                    background: null
                                    selectByMouse: true
                                }
                            }
                        }

                        // -------- Password --------
                        Column {
                            width: parent.width
                            spacing: dp(2)

                            Row {
                                spacing: dp(1)
                                Text {
                                    text: "Password"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }
                                Text {
                                    text: "*"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                    color: "red"
                                }
                            }

                            Rectangle {
                                id: passwordBox
                                width: parent.width
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: loginPass.activeFocus ? 2 : 1
                                border.color: loginPass.activeFocus ? app_color : borderColor

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: dp(2)
                                    spacing: dp(2)

                                    TextField {
                                        id: loginPass
                                        width: parent.width - showPasswordBtn.width - parent.spacing  // Calculate available width
                                        anchors.verticalCenter: parent.verticalCenter
                                        placeholderText: "Enter your password"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        color: "black"
                                        echoMode: showPasswordBtn.checked ? TextInput.Normal : TextInput.Password
                                        background: null
                                        selectByMouse: true
                                        clip: true  // Clips text that exceeds the TextField bounds
                                    }

                                    Button {
                                        id: showPasswordBtn
                                        width: dp(6)
                                        height: dp(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        checkable: true

                                        background: Rectangle {
                                            radius: dp(0.75)
                                            color: parent.pressed ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                                        }

                                        contentItem: QGCColoredImage {
                                            anchors.fill: parent
                                            anchors.margins: dp(1)
                                            fillMode: Image.PreserveAspectFit
                                            source: parent.checked
                                                    ? "/qmlimages/NewImages/password_visible.svg"
                                                    : "/qmlimages/NewImages/password_hidden.svg"
                                            color: app_color
                                        }
                                    }
                                }
                            }
                        }
                        // -------- Sign In Button --------
                        Button {
                            id: loginBtn
                            width: parent.width
                            height: dp(10)

                            background: Rectangle {
                                radius: dp(1)
                                color: loginBtn.pressed
                                       ? Qt.darker(app_color, 1.2)
                                       : app_color
                            }

                            contentItem: Item {
                                anchors.fill: parent

                                Row {
                                    anchors.centerIn: parent  // Centers the Row both horizontally and vertically
                                    spacing: dp(2)

                                    Text {
                                        text: "Sign In"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.weight: Font.Medium
                                        color: "white"
                                        anchors.verticalCenter: parent.verticalCenter  // Aligns text vertically with icon
                                    }

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/signIn.svg"
                                        width: 18
                                        height: 18
                                        fillMode: Image.PreserveAspectFit
                                        anchors.verticalCenter: parent.verticalCenter  // Aligns icon vertically with text
                                    }
                                }
                            }
                            onClicked: {
                                if (loginUser.text.trim() === "" || loginPass.text === "") {
                                    rootWindow.showToastMessage("Please fill all fields")
                                    return
                                }

                                // Direct login with correct API endpoint
                                var xhr = new XMLHttpRequest();
                                var url = MapGlobals.backendUrl +'/login';
                                xhr.open('POST', url, true);
                                xhr.setRequestHeader('Content-Type', 'application/json');

                                xhr.onreadystatechange = function() {
                                    if (xhr.readyState === XMLHttpRequest.DONE) {
                                        if (xhr.status === 200) {
                                            var response = JSON.parse(xhr.responseText);
                                            if (response.success) {
                                                rootWindow.showToastMessage("Login successful!");
                                                // Save user data
                                                QGroundControl.saveGlobalSetting("username", response.user.username);
                                                QGroundControl.saveGlobalSetting("name", response.user.displayname);
                                                QGroundControl.saveGlobalSetting("email", response.user.email);
                                                QGroundControl.saveBoolGlobalSetting("login", true);
                                                // Clear fields
                                                loginUser.text = "";
                                                loginPass.text = "";
                                                // Go to homescreen
                                                MapGlobals.rootWindow.homescreen();
                                            } else {
                                                rootWindow.showToastMessage(response.message || "Login failed");
                                            }
                                        } else {
                                            rootWindow.showToastMessage("Login failed. Server error: " + xhr.status);
                                        }
                                    }
                                };

                                xhr.onerror = function() {
                                    rootWindow.showToastMessage("Network error. Check your connection.");
                                };

                                xhr.send(JSON.stringify({
                                    userInput: loginUser.text.trim(),
                                    password: loginPass.text
                                }));
                            }
                        }


                        Row {
                            spacing: dp(1)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Don't have an account?"
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: textSecondary
                            }

                            Item {
                                width: signUpText.implicitWidth
                                height: signUpText.implicitHeight

                                Text {
                                    id: signUpText
                                    text: "Sign Up"
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    font.weight: Font.Medium
                                    color: signUpMouse.containsMouse ? Qt.darker(app_color, 1.2) : app_color
                                }

                                MouseArea {
                                    id: signUpMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        currentView = "signup"
                                        rightSide = "signup"
                                        loginUser.text = ""
                                        loginPass.text = ""
                                    }
                                }
                            }
                        }

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: forgotText.implicitWidth
                            height: forgotText.implicitHeight

                            Text {
                                id: forgotText
                                text: "Forgot Password?"
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: forgotMouse.containsMouse ? Qt.darker(app_color, 1.2) : app_color
                            }

                            MouseArea {
                                id: forgotMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    currentView = "reset"
                                    rightSide = "reset"
                                    loginUser.text = ""
                                    loginPass.text = ""
                                }
                            }
                        }

                    }

                    // Bottom spacer (ensures proper scroll padding)
                    //      Item {
                    //          width: 1
                    //          height: dp(6)
                    //      }

                }
            }
        }
    }

    Component {
        id: signUpComponent

        Item {
            id: scrollcontent
            width: parent.width * 0.6
            height: parent.height
            clip: true

            Column {
                anchors.fill: parent
                spacing: 0

                // ================= HEADER (STATIC) =================
                Item {
                    id: headerArea
                    width: parent.width
                    height: dp(18)   // adjust if needed

                    // Back button
                    // Rectangle {
                    //     id: backButton_create
                    //     width: dp(10)
                    //     height: dp(10)
                    //     color: "transparent"
                    //     z: 10

                    //     anchors {
                    //         top: parent.top
                    //         left: parent.left
                    //         topMargin: dp(2)
                    //         leftMargin: dp(2)
                    //     }

                    //     MouseArea {
                    //         anchors.fill: parent
                    //         cursorShape: Qt.PointingHandCursor
                    //         onClicked: currentView = "welcome"
                    //     }

                    //     QGCColoredImage {
                    //         anchors.centerIn: parent
                    //         source: "qrc:/InstrumentValueIcons/arrow-simple-left.svg"
                    //         width: dp(6)
                    //         height: dp(6)
                    //         color: textPrimary
                    //     }
                    // }

                    // Title + Subtitle
                    Column {
                        width: parent.width * 0.85
                        spacing: dp(1.5)
                        anchors.centerIn: parent

                        Text {
                            text: "Create Account"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.weight: Font.Bold
                            color: app_color
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Text {
                            text: "Join us today! Please fill in your details"
                            font.pointSize: ScreenTools.smallFontPointSize
                            color: textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
                    }
                }

                // ================= SCROLLABLE BODY =================
                Flickable {
                    id: flickable
                    width: parent.width
                    height: parent.height - headerArea.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    contentWidth: width
                    contentHeight: formColumn.implicitHeight + dp(8)

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    Column {
                        id: formColumn
                        width: flickable.width * 0.85
                        spacing: dp(4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: dp(2)

                        // Display Name
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            //anchors.horizontalCenter: parent.horizontalCenter

                            Row {
                                //anchors.horizontalCenter: parent.horizontalCenter
                                x: parent.width * 0.05
                                spacing: dp(1)

                                Text {
                                    text: "Full Name"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }

                                Text {
                                    text: "*"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                    font.weight: Font.Medium
                                    color: "red"
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.9
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regDisplay.activeFocus ? 2 : 1
                                border.color: regDisplay.activeFocus ? app_color : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regDisplay
                                    anchors.fill: parent
                                    placeholderText: "Ex: Dharun"
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

                        // Username
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            //anchors.horizontalCenter: parent.horizontalCenter

                            Row {
                                x: parent.width * 0.05
                                spacing: dp(1)

                                Text {
                                    text: "Username"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }

                                // QGCColoredImage {
                                //     source: "/qmlimages/NewImages/userProfile_icon.svg"
                                //     fillMode: Image.PreserveAspectFit
                                //     width: 12
                                //     height: 12
                                //     anchors.verticalCenter: parent.verticalCenter
                                //     color: textPrimary
                                // }

                                Text {
                                    text: "*"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.8
                                    font.weight: Font.Medium
                                    color: "red"
                                }

                                Text {
                                    text: "(Used for login, must be unique)"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Medium
                                    color: textSecondary
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.9
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regUser.activeFocus ? 2 : 1
                                border.color: regUser.activeFocus ? app_color : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regUser
                                    anchors.fill: parent
                                    placeholderText: "Ex: dharun_sure_5522"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    background: null
                                    selectByMouse: true

                                    // validator: RegularExpressionValidator {
                                    //     regularExpression: /^[a-zA-Z\s]*$/ // Allows only letters and spaces
                                    // }
                                }
                            }
                        }

                        // Email
                        Column {
                            width: parent.width
                            spacing: dp(2)

                            Row {
                                x: parent.width * 0.05
                                spacing: dp(1)

                                Text {
                                    text: "Email"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }

                                Text {
                                    text: "*"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                    font.weight: Font.Medium
                                    color: "red"
                                }
                            }

                            Row {
                                width: parent.width * 0.9
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    width: parent.width - sendOtpBtn.width - parent.spacing
                                    height: dp(10)
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: regEmail.activeFocus ? 2 : 1
                                    border.color: regEmail.activeFocus ? app_color : borderColor

                                    TextField {
                                        id: regEmail
                                        anchors.fill: parent
                                        placeholderText: "your.email@example.com"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black"
                                        background: null
                                        selectByMouse: true
                                        validator: RegularExpressionValidator {
                                            regularExpression: /^[a-zA-Z0-9@._-]*$/
                                        }
                                        inputMethodHints: Qt.ImhEmailCharactersOnly
                                    }
                                }

                                Button {
                                    id: sendOtpBtn
                                    width: dp(25)
                                    height: dp(10)
                                    text: "Send OTP"
                                    background: Rectangle {
                                        radius: dp(1)
                                        color: sendOtpBtn.pressed ? primaryHover : app_color
                                    }
                                    contentItem: Text {
                                        text: sendOtpBtn.text
                                        color: "white"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: {
                                        if (!MapGlobals.validateEmail(regEmail.text, regEmail)) return;

                                        // Direct XHR call instead of MapGlobals.sendOTP
                                        var xhr = new XMLHttpRequest();
                                        var url = MapGlobals.backendUrl + '/send-otp';
                                        xhr.open('POST', url, true);
                                        xhr.setRequestHeader('Content-Type', 'application/json');

                                        xhr.onreadystatechange = function() {
                                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                                if (xhr.status === 200) {
                                                    var response = JSON.parse(xhr.responseText);
                                                    if (response.success) {
                                                        otpSent = true;
                                                        rootWindow.showToastMessage("OTP sent successfully!");
                                                    } else {
                                                        rootWindow.showToastMessage(response.message || "Failed to send OTP");
                                                    }
                                                } else {
                                                    rootWindow.showToastMessage("Failed to send OTP. Please try again.");
                                                    console.error("HTTP Error:", xhr.status);
                                                }
                                            }
                                        };

                                        xhr.onerror = function() {
                                            rootWindow.showToastMessage("Network error. Check your connection.");
                                            console.error("Network error occurred");
                                        };

                                        var data = JSON.stringify({
                                            email: regEmail.text,
                                            type: "registration"
                                        });

                                        xhr.send(data);
                                    }
                                }
                            }
                        }

                        // OTP Field
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            visible: otpSent

                            Row {
                                x: parent.width * 0.05
                                spacing: dp(1)
                                Text {
                                    text: isOtpVerified ? "OTP Verified" : "OTP Verification"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: isOtpVerified ? "green" : app_color
                                }
                                Text {
                                    text: "*"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                    color: "red"
                                    visible: !isOtpVerified
                                }
                            }

                            Row {
                                width: parent.width * 0.9
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    width: isOtpVerified ? parent.width : (parent.width - 100 - parent.spacing)
                                    height: dp(10)
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: regOtp.activeFocus ? 2 : 1
                                    border.color: isOtpVerified ? "green" : (regOtp.activeFocus ? app_color : borderColor)

                                    TextField {
                                        id: regOtp
                                        anchors.fill: parent
                                        placeholderText: "Enter 6-digit OTP"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        color: "black"
                                        enabled: !isOtpVerified
                                        background: null
                                        inputMethodHints: Qt.ImhDigitsOnly
                                    }
                                }

                                Button {
                                    id: verifyOtpBtn
                                    width: 100
                                    height: dp(10)
                                    text: "Verify"
                                    visible: !isOtpVerified
                                    background: Rectangle {
                                        radius: dp(1)
                                        color: verifyOtpBtn.pressed ? primaryHover : app_color
                                    }
                                    contentItem: Text {
                                        text: verifyOtpBtn.text
                                        color: "white"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        font.bold: true
                                    }
                                    onClicked: {
                                        if (regOtp.text.length < 6) {
                                            rootWindow.showToastMessage("Please enter a valid 6-digit OTP");
                                            return;
                                        }

                                        // Direct XHR call for verification
                                        var xhr = new XMLHttpRequest();
                                        var url = MapGlobals.backendUrl + '/verify-otp';
                                        xhr.open('POST', url, true);
                                        xhr.setRequestHeader('Content-Type', 'application/json');

                                        xhr.onreadystatechange = function() {
                                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                                if (xhr.status === 200) {
                                                    var response = JSON.parse(xhr.responseText);
                                                    if (response.success) {
                                                        isOtpVerified = true;
                                                        rootWindow.showToastMessage("OTP verified! Please set your password.");
                                                    } else {
                                                        rootWindow.showToastMessage(response.message || "OTP verification failed");
                                                    }
                                                } else {
                                                    rootWindow.showToastMessage("Failed to verify OTP. Please try again.");
                                                }
                                            }
                                        };

                                        var data = JSON.stringify({
                                            email: regEmail.text,
                                            otp: regOtp.text,
                                            type: "registration"
                                        });

                                        xhr.send(data);
                                    }
                                }
                            }
                        }
                        // Password
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            visible: isOtpVerified

                            Row {
                                //anchors.horizontalCenter: parent.horizontalCenter
                                x: parent.width * 0.05
                                spacing: dp(1)

                                Text {
                                    text: "Password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }

                                Text {
                                    text: "*"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.8
                                    font.weight: Font.Medium
                                    color: "red"
                                }

                                // QGCColoredImage {
                                //     source: "/qmlimages/NewImages/password.svg"
                                //     fillMode: Image.PreserveAspectFit
                                //     width: 12
                                //     height: 12
                                //     anchors.verticalCenter: parent.verticalCenter
                                //     color: textPrimary
                                // }
                            }

                            Rectangle {
                                width: parent.width * 0.9
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regPass.activeFocus ? 2 : 1
                                border.color: regPass.activeFocus ? app_color : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regPass
                                    anchors {
                                        left: parent.left
                                        right: showPasswordBtn_crtAc.left
                                        top: parent.top
                                        bottom: parent.bottom
                                        //margins: dp(2)
                                    }
                                    placeholderText: "Enter your password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black" //textPrimary
                                    echoMode: showPasswordBtn_crtAc.checked ? TextInput.Normal : TextInput.Password
                                    background: null
                                    selectByMouse: true
                                }

                                Button {
                                    id: showPasswordBtn_crtAc
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

                                    contentItem: QGCColoredImage {
                                        anchors.fill: parent
                                        anchors.margins: dp(1)
                                        fillMode: Image.PreserveAspectFit
                                        source: parent.checked
                                                ? "/qmlimages/NewImages/password_visible.svg"
                                                : "/qmlimages/NewImages/password_hidden.svg"
                                        color: app_color
                                    }
                                }

                            }
                        }

                        // Confirm Password
                        Column {
                            width: parent.width
                            spacing: dp(2)
                            visible: isOtpVerified

                            Row {
                                //anchors.horizontalCenter: parent.horizontalCenter
                                x: parent.width * 0.05
                                spacing: dp(1)

                                Text {
                                    text: "Confirm Password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.Bold
                                    color: app_color
                                }

                                Text {
                                    text: "*"
                                    //font.pixelSize: dp(4)
                                    font.pointSize:     ScreenTools.defaultFontPointSize * 0.8
                                    font.weight: Font.Medium
                                    color: "red"
                                }

                                // QGCColoredImage {
                                //     source: "/qmlimages/NewImages/password.svg"
                                //     fillMode: Image.PreserveAspectFit
                                //     width: 12
                                //     height: 12
                                //     anchors.verticalCenter: parent.verticalCenter
                                //     color: textPrimary
                                // }
                            }

                            Rectangle {
                                width: parent.width * 0.9
                                height: dp(10)
                                radius: dp(1)
                                color: surfaceColor
                                border.width: regConfirm.activeFocus ? 2 : 1
                                border.color: regConfirm.activeFocus ? app_color : borderColor
                                anchors.horizontalCenter: parent.horizontalCenter

                                TextField {
                                    id: regConfirm
                                    anchors {
                                        left: parent.left
                                        right: confirmPswBtn.left
                                        top: parent.top
                                        bottom: parent.bottom
                                        //margins: dp(2)
                                    }
                                    placeholderText: "Confirm your password"
                                    //font.pixelSize: dp(4)
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.family: "Arial"
                                    color: "black"
                                    echoMode: confirmPswBtn.checked ? TextInput.Normal : TextInput.Password
                                    background: null
                                    selectByMouse: true
                                }


                                Button {
                                    id: confirmPswBtn
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

                                    contentItem: QGCColoredImage {
                                        anchors.fill: parent
                                        anchors.margins: dp(1)
                                        fillMode: Image.PreserveAspectFit
                                        source: parent.checked
                                                ? "/qmlimages/NewImages/password_visible.svg"
                                                : "/qmlimages/NewImages/password_hidden.svg"
                                        color: app_color
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
                                visible: isOtpVerified
                                width: parent.width * 0.9
                                height: dp(10)
                                anchors.horizontalCenter: parent.horizontalCenter

                                background: Rectangle {
                                    radius: dp(1)
                                    color: signUpActionBtn.pressed ? primaryHover : app_color
                                }

                                contentItem: Item {
                                    anchors.fill: parent
                                    // clip: true

                                    Row {
                                        anchors.centerIn: parent      // now centers correctly
                                        spacing: dp(1)

                                        QGCColoredImage {
                                            source: "/qmlimages/NewImages/createAccount.svg"
                                            fillMode: Image.PreserveAspectFit
                                            width: 22
                                            height: 22
                                            anchors.verticalCenter: parent.verticalCenter

                                        }

                                        Text {
                                            text: signUpActionBtn.text
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            font.weight: Font.Medium
                                            color: "white"
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }

                                onClicked: {
                                    // Execute validations in order
                                    if (!MapGlobals.validateUsername(regUser.text,regUser)) return;
                                    if (!MapGlobals.validateDisplayName(regDisplay.text,regDisplay)) return;
                                    if (!MapGlobals.validateEmail(regEmail.text,regEmail)) return;
                                    if (!MapGlobals.validatePassword(regPass.text,regPass)) return;
                                    if (!MapGlobals.validateConfirmPassword(regPass.text, regConfirm.text,regConfirm)) return;

                                                        MapGlobals.registerUser(regUser.text, regDisplay.text, regEmail.text, regPass.text, regConfirm.text, regOtp.text, function(result, response) {
                                                            if (result) {
                                                                rootWindow.showToastMessage("Account created successfully!");

                                                                // Use response data if available, otherwise fallback to form fields
                                                                var user = (response && response.user) ? response.user : {
                                                                    "username": regUser.text,
                                                                    "displayname": regDisplay.text,
                                                                    "email": regEmail.text
                                                                };

                                                                QGroundControl.saveGlobalSetting("username", user.username);
                                                                QGroundControl.saveGlobalSetting("name", user.displayname);
                                                                QGroundControl.saveGlobalSetting("email", user.email);
                                                                QGroundControl.saveBoolGlobalSetting("login", true);

                                                                // Clear fields
                                                                regUser.text = "";
                                                                regDisplay.text = "";
                                                                regEmail.text = "";
                                                                regOtp.text = "";
                                                                regPass.text = "";
                                                                regConfirm.text = "";
                                                                otpSent = false;
                                                                isOtpVerified = false;

                                                                // Go into the app!
                                                                MapGlobals.rootWindow.homescreen();
                                                            }
                                                        });

                                }
                            }

                            Row {
                                //width: parent.width
                                spacing: dp(1)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    text: "Already have an account ?"
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    color: textSecondary
                                }

                                Text {
                                    text: "Sign In"
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    color: app_color
                                    font.weight: Font.Medium

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            currentView = "signin"
                                        }
                                    }
                                }
                            }

                        }

                    }
                }
            }
        }

    }

    Component {
        id: resetpwdComponent

        Item {
            id: resetRoot
            width: parent.width * 0.6
            height: parent.height

            // State management - moved to root of Item
            property bool otpSent: false
            property bool isOtpVerified: false
            property string resetEmail: ""

            function sendResetOTP() {
                var userInput = resetUserInput.text.trim();
                if (userInput === "") {
                    if (typeof rootWindow !== 'undefined' && rootWindow.showToastMessage) {
                        rootWindow.showToastMessage("Please enter username or email");
                    } else {
                        console.log("Please enter username or email");
                    }
                    return;
                }

                // Use XMLHttpRequest directly instead of MapGlobals.loadUserData
                var xhr = new XMLHttpRequest();
                var url = MapGlobals.backendUrl + '/send-otp';
                xhr.open('POST', url, true);
                xhr.setRequestHeader('Content-Type', 'application/json');

                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            var response = JSON.parse(xhr.responseText);
                            if (response.success) {
                                resetRoot.otpSent = true;
                                resetRoot.resetEmail = userInput; // Store email for later
                                if (typeof rootWindow !== 'undefined' && rootWindow.showToastMessage) {
                                    rootWindow.showToastMessage("OTP sent to " + userInput);
                                }
                            } else {
                                if (typeof rootWindow !== 'undefined' && rootWindow.showToastMessage) {
                                    rootWindow.showToastMessage(response.message || "Failed to send OTP");
                                }
                            }
                        } else {
                            if (typeof rootWindow !== 'undefined' && rootWindow.showToastMessage) {
                                rootWindow.showToastMessage("Failed to send OTP. Server error.");
                            }
                        }
                    }
                };

                var data = JSON.stringify({
                    email: userInput,
                    type: "forgotPassword"
                });

                xhr.send(data);
            }
            ScrollView {
                anchors.fill: parent
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Item {
                    width: parent.width
                    height: Math.max(resetColumn.implicitHeight, parent.height)

                    Column {
                        id: resetColumn
                        width: parent.width * 0.85
                        spacing: 32 // dp(4) - using pixels directly to avoid potential issues
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                            topMargin: 16
                        }

                        // Header
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "Reset Password"
                                font.pointSize: ScreenTools.mediumFontPointSize
                                font.weight: Font.Bold
                                color: app_color
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: resetRoot.isOtpVerified ? "Set your new password" : (resetRoot.otpSent ? "Enter the OTP sent to your email" : "Enter your username or email to receive OTP")
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: textSecondary
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Form - Dynamic based on state
                        Column {
                            width: parent.width
                            spacing: 32
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Username/Email Field (Step 1)
                            Column {
                                width: parent.width
                                spacing: 16
                                visible: !resetRoot.otpSent
                                anchors.horizontalCenter: parent.horizontalCenter

                                Row {
                                    x: parent.width * 0.05
                                    spacing: 8

                                    Text {
                                        text: "Username or Email"
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                        font.weight: Font.Bold
                                        color: app_color
                                    }

                                    Text {
                                        text: "*"
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                        font.weight: Font.Medium
                                        color: "red"
                                    }
                                }

                                Rectangle {
                                    width: parent.width * 0.9
                                    height: 45 // dp(10)
                                    radius: 8
                                    color: surfaceColor
                                    border.width: resetUserInput.activeFocus ? 2 : 1
                                    border.color: resetUserInput.activeFocus ? app_color : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    TextField {
                                        id: resetUserInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        placeholderText: "Enter your username or email"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black"
                                        background: null
                                        selectByMouse: true
                                    }
                                }
                            }

                            // OTP Field (Step 2)
                            Column {
                                width: parent.width
                                spacing: 16
                                visible: resetRoot.otpSent && !resetRoot.isOtpVerified

                                Row {
                                    x: parent.width * 0.05
                                    spacing: 8

                                    Text {
                                        text: "OTP Verification"
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                        font.weight: Font.Bold
                                        color: app_color
                                    }

                                    Text {
                                        text: "*"
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.8
                                        font.weight: Font.Medium
                                        color: "red"
                                    }
                                }

                                // OTP Input Row
                                Row {
                                    width: parent.width * 0.9
                                    spacing: 16
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        width: parent.width - verifyResetOtpBtn2.width - parent.spacing
                                        height: 80
                                        radius: 8
                                        color: surfaceColor
                                        border.width: resetOtpField.activeFocus ? 2 : 1
                                        border.color: resetOtpField.activeFocus ? app_color : borderColor

                                        TextField {
                                            id: resetOtpField
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            placeholderText: "Enter 6-digit OTP"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            font.family: "Arial"
                                            color: "black"
                                            background: null
                                            selectByMouse: true
                                            inputMethodHints: Qt.ImhDigitsOnly
                                        }
                                    }
                                    Button {
                                        id: verifyResetOtpBtn2
                                        width: 160
                                        height: 80
                                        text: "Verify OTP"
                                        background: Rectangle {
                                            radius: 8
                                            color: verifyResetOtpBtn2.pressed ? primaryHover : app_color
                                        }
                                        contentItem: Text {
                                            text: "Verify OTP"
                                            color: "white"
                                            font.pointSize: ScreenTools.smallFontPointSize
                                            font.bold: true
                                        }
                                        onClicked: {
                                            if (resetOtpField.text.length < 6) {
                                                rootWindow.showToastMessage("Please enter a valid 6-digit OTP");
                                                return;
                                            }
                                            var xhr = new XMLHttpRequest();
                                            var url = MapGlobals.backendUrl + '/verify-otp';  // FIXED: Added /api/
                                            xhr.open('POST', url, true);
                                            xhr.setRequestHeader('Content-Type', 'application/json');
                                            xhr.onreadystatechange = function() {
                                                if (xhr.readyState === XMLHttpRequest.DONE) {
                                                    if (xhr.status === 200) {
                                                        var response = JSON.parse(xhr.responseText);
                                                        if (response.success) {
                                                            resetRoot.isOtpVerified = true;
                                                            rootWindow.showToastMessage("OTP verified! Please set your new password.");
                                                        } else {
                                                            rootWindow.showToastMessage(response.message || "OTP verification failed");
                                                        }
                                                    } else {
                                                        rootWindow.showToastMessage("Failed to verify OTP");
                                                    }
                                                }
                                            };
                                            var data = JSON.stringify({
                                                email: resetRoot.resetEmail,
                                                otp: resetOtpField.text,
                                                type: "forgotPassword"
                                            });
                                            xhr.send(data);
                                        }
                                    }
                                }

                                // Resend OTP option
                                Row {
                                    spacing: 8
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: "Didn't receive OTP?"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        color: textSecondary
                                    }

                                    Text {
                                        text: "Resend"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        font.weight: Font.Medium
                                        color: app_color

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                resetRoot.sendResetOTP();
                                            }
                                        }
                                    }
                                }
                            }
                            // New Password Field
                            Column {
                                width: parent.width
                                spacing: 16
                                visible: resetRoot.isOtpVerified

                                Row {
                                    x: parent.width * 0.05
                                    spacing: 8
                                    Text {
                                        text: "New Password"
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                        font.weight: Font.Bold
                                        color: app_color
                                    }
                                    Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "red" }
                                }

                                Rectangle {
                                    width: parent.width * 0.9
                                    height: 40
                                    radius: 8
                                    color: surfaceColor
                                    border.width: newPasswordField.activeFocus ? 2 : 1
                                    border.color: newPasswordField.activeFocus ? app_color : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        TextField {
                                            id: newPasswordField
                                            width: parent.width - 48 - parent.spacing
                                            anchors.verticalCenter: parent.verticalCenter
                                            placeholderText: "Enter your new password (min 8 characters)"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "black"
                                            echoMode: showNewPasswordBtn.checked ? TextInput.Normal : TextInput.Password
                                            background: null
                                        }
                                        Button {
                                            id: showNewPasswordBtn
                                            width: 40; height: 40
                                            anchors.verticalCenter: parent.verticalCenter
                                            checkable: true
                                            background: Rectangle { radius: 6; color: parent.pressed ? Qt.rgba(0,0,0,0.1) : "transparent" }
                                            contentItem: QGCColoredImage {
                                                anchors.fill: parent; anchors.margins: 8
                                                fillMode: Image.PreserveAspectFit
                                                source: parent.checked ? "/qmlimages/NewImages/password_visible.svg" : "/qmlimages/NewImages/password_hidden.svg"
                                                color: app_color
                                            }
                                        }
                                    }
                                }
                            }

                            // Confirm Password Field
                            Column {
                                width: parent.width
                                spacing: 16
                                visible: resetRoot.isOtpVerified

                                Row {
                                    x: parent.width * 0.05
                                    spacing: 8
                                    Text {
                                        text: "Confirm Password"
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                        font.weight: Font.Bold
                                        color: app_color
                                    }
                                    Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "red" }
                                }

                                Rectangle {
                                    width: parent.width * 0.9
                                    height: 40
                                    radius: 8
                                    color: surfaceColor
                                    border.width: confirmPasswordField.activeFocus ? 2 : 1
                                    border.color: confirmPasswordField.activeFocus ? app_color : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8
                                        TextField {
                                            id: confirmPasswordField
                                            width: parent.width - 48 - parent.spacing
                                            anchors.verticalCenter: parent.verticalCenter
                                            placeholderText: "Confirm your new password"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "black"
                                            echoMode: showConfirmPasswordBtn.checked ? TextInput.Normal : TextInput.Password
                                            background: null
                                        }
                                        Button {
                                            id: showConfirmPasswordBtn
                                            width: 40; height: 40
                                            anchors.verticalCenter: parent.verticalCenter
                                            checkable: true
                                            background: Rectangle { radius: 6; color: parent.pressed ? Qt.rgba(0,0,0,0.1) : "transparent" }
                                            contentItem: QGCColoredImage {
                                                anchors.fill: parent; anchors.margins: 8
                                                fillMode: Image.PreserveAspectFit
                                                source: parent.checked ? "/qmlimages/NewImages/password_visible.svg" : "/qmlimages/NewImages/password_hidden.svg"
                                                color: app_color
                                            }
                                        }
                                    }
                                }
                            }
                            Button {
                                id: resetPasswordFinalBtn
                                text: "Reset Password"
                                visible: resetRoot.isOtpVerified
                                width: parent.width * 0.9
                                height: 30
                                anchors.horizontalCenter: parent.horizontalCenter

                                background: Rectangle {
                                    radius: 8
                                    color: parent.pressed ? primaryHover : app_color
                                }

                                contentItem: Text {
                                    text: resetPasswordFinalBtn.text
                                    color: "white"
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    // Validate passwords
                                    if (!MapGlobals.validatePassword(newPasswordField.text, newPasswordField)) return;
                                    if (!MapGlobals.validateConfirmPassword(newPasswordField.text, confirmPasswordField.text, confirmPasswordField)) return;

                                    // Call reset password API
                                    var xhr = new XMLHttpRequest();
                                    var url = MapGlobals.backendUrl + '/forgot-password';  // FIXED: Added /api/
                                    xhr.open('POST', url, true);
                                    xhr.setRequestHeader('Content-Type', 'application/json');

                                    xhr.onreadystatechange = function() {
                                        if (xhr.readyState === XMLHttpRequest.DONE) {
                                            if (xhr.status === 200) {
                                                var response = JSON.parse(xhr.responseText);
                                                if (response.success) {
                                                    rootWindow.showToastMessage("Password reset successfully! Please login.");
                                                    // Reset all fields and go back to sign in
                                                    resetUserInput.text = "";
                                                    resetOtpField.text = "";
                                                    newPasswordField.text = "";
                                                    confirmPasswordField.text = "";
                                                    resetRoot.otpSent = false;
                                                    resetRoot.isOtpVerified = false;
                                                    resetRoot.resetEmail = "";
                                                    currentView = "signin";
                                                } else {
                                                    rootWindow.showToastMessage(response.message || "Failed to reset password");
                                                }
                                            } else {
                                                rootWindow.showToastMessage("Failed to reset password. Server error.");
                                            }
                                        }
                                    };

                                    xhr.send(JSON.stringify({
                                        email: resetRoot.resetEmail,
                                        otp: resetOtpField.text,
                                        newPassword: newPasswordField.text
                                    }));
                                }
                            }

                            // Action Buttons
                        Column {
                            width: parent.width
                            spacing: 24
                            anchors.horizontalCenter: parent.horizontalCenter

                            // Send OTP Button (Step 1)
                            Button {
                                id: sendResetOtpBtn
                                text: "Send OTP"
                                visible: !resetRoot.otpSent
                                width: parent.width * 0.5
                                height: 45
                                anchors.horizontalCenter: parent.horizontalCenter

                                background: Rectangle {
                                    radius: 2
                                    color: sendResetOtpBtn.pressed ? primaryHover : app_color
                                }

                                contentItem: Row {
                                    anchors.centerIn: parent
                                    spacing: 16

                                    Text {
                                        text: sendResetOtpBtn.text
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.weight: Font.Medium
                                        color: "white"
                                    }

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/send_mail.svg"
                                        fillMode: Image.PreserveAspectFit
                                        width: 20
                                        height: 20
                                        color: "white"
                                    }
                                }

                                onClicked: {
                                    resetRoot.sendResetOTP();
                                }
                            }

                            // Back to Sign In link
                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 64
                                width: backRow.width

                                Row {
                                    id: backRow
                                    spacing: 16
                                    anchors.centerIn: parent

                                    QGCColoredImage {
                                        source: "qrc:/InstrumentValueIcons/arrow-simple-left.svg"
                                        width: 20
                                        height: 20
                                        color: app_color
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Back to Sign In"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.underline: true
                                        font.weight: Font.Bold
                                        color: app_color
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // Reset all states
                                        resetUserInput.text = "";
                                        resetOtpField.text = "";
                                        newPasswordField.text = "";
                                        confirmPasswordField.text = "";
                                        resetRoot.otpSent = false;
                                        resetRoot.isOtpVerified = false;
                                        resetRoot.resetEmail = "";
                                        currentView = "signin";
                                    }
                                }
                            }
                        }

                        }
                }
            }
        }
    }
    }
}
