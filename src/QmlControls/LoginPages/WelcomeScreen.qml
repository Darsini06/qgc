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





    function dp(value) {
        return value * baseUnit;
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

    /* ========= Card ========= */
    Rectangle {
        id: authCard
        width: parent.width * 0.85
        height: parent.height * 0.9
        radius: 12
        anchors.centerIn: parent
        color: surfaceColor
        z : 1


        Rectangle {
            id: shadowSource
            anchors.fill: parent
            radius: dp(4)
            color: "white"
            visible: false
        }

        MultiEffect {
            anchors.fill: shadowSource
            source: shadowSource

            shadowEnabled: true
            shadowBlur: 0.9
            shadowHorizontalOffset: 0
            shadowVerticalOffset: dp(1)
            shadowColor: "#40000000"   // soft black
        }

        // === BASE FORM LAYER ===
        Item {
            anchors.fill: parent

            Row {
                anchors.fill: parent

                // LEFT FORM
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Loader {
                        anchors.fill: parent
                        // sourceComponent: currentView === "signin"
                        //                  ? signInComponent
                        //                  : signUpComponent

                        sourceComponent : signInComponent
                    }
                }

                // RIGHT EMPTY SPACE (under overlay)
                Item {
                    width: parent.width / 2
                    height: parent.height

                    Loader {
                        anchors.fill: parent
                        // sourceComponent: currentView === "signin"
                        //                  ? signInComponent
                        //                  : signUpComponent

                        sourceComponent : rightSide === "reset" ? resetpwdComponent : signUpComponent
                    }
                }
            }
        }

        // === SLIDING OVERLAY PANEL ===
        Rectangle  {
            id: overlayPanel
            width: parent.width / 2
            height: parent.height
            radius: 12
            clip: true          // IMPORTANT for rounded corners

            x: currentView === "signin" ? parent.width/2 : 0

            Behavior on x {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }

            // Background Image
            Image {
                anchors.fill: parent
                source: "qrc:/qmlimages/NewImages/background_login_premium.png"
                fillMode: Image.PreserveAspectCrop
                smooth: true

                // Dynamic gradient overlay to make it look futuristic
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(48/255, 25/255, 52/255, 0.4) } // Theme Purple
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
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
                                    text: "Username or Email"
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
                                    mainWindow.showToastMessage("Please fill all fields")
                                    return
                                }

                                MapGlobals.loginUserFunc(
                                            loginUser.text.trim(),
                                            loginPass.text,
                                            function(result) {
                                                if (result) {
                                                    loginUser.text = ""
                                                    loginPass.text = ""
                                                }
                                            }
                                            )
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
                                        MapGlobals.sendOTP(regEmail.text, function(success) {
                                            if (success) {
                                                otpSent = true;
                                            }
                                        });
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
                                    font.weight: Font.Medium
                                    color: "red"
                                    visible: !isOtpVerified
                                }
                            }

                            Row {
                                width: parent.width * 0.9
                                spacing: dp(2)
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    width: isOtpVerified ? parent.width : (parent.width - verifyOtpBtn.width - parent.spacing)
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
                                        font.family: "Arial"
                                        color: "black"
                                        enabled: !isOtpVerified
                                        background: null
                                        selectByMouse: true
                                        inputMethodHints: Qt.ImhDigitsOnly
                                    }
                                }

                                Button {
                                    id: verifyOtpBtn
                                    width: dp(20)
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
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: {
                                        if (regOtp.text.length < 6) {
                                            mainWindow.showToastMessage("Please enter a valid 6-digit OTP");
                                            return;
                                        }
                                        MapGlobals.verifyOTP(regEmail.text, regOtp.text, function(success) {
                                            if (success) {
                                                isOtpVerified = true;
                                                mainWindow.showToastMessage("OTP verified! Please set your password.");
                                            }
                                        });
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
                                                                mainWindow.showToastMessage("Account created successfully!");
                                                                
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
        id : resetpwdComponent

        Item {

            width: parent.width * 0.6
            height: parent.height

            // Rectangle {
            //     id: backButton_reset
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

            //         onClicked: {
            //             console.log("BACK CLICKED");
            //             currentView = "welcome"
            //         }
            //     }

            //     QGCColoredImage {
            //         anchors.centerIn: parent
            //         source: "qrc:/InstrumentValueIcons/arrow-simple-left.svg"
            //         width: dp(6)
            //         height: dp(6)
            //         color: textPrimary
            //     }
            // }


            ScrollView {
                anchors.fill: parent
                z: 1
                //clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                // Container to ensure proper centering
                Item {
                    width: parent.width
                    height: Math.max(resetColumn.implicitHeight, parent.height)

                    Column {
                        id: resetColumn
                        width: parent.width * 0.85
                        spacing: dp(4)
                        anchors.centerIn: parent

                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                            topMargin: dp(2)
                        }

                        // Header
                        Column {
                            width: parent.width
                            spacing: dp(1.5)
                            //anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                text: "Reset Password"
                                //font.pixelSize: dp(6)
                                font.pointSize: ScreenTools.mediumFontPointSize
                                font.weight: Font.Bold
                                color: app_color
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

                                Row {
                                    //anchors.horizontalCenter: parent.horizontalCenter
                                    x: parent.width * 0.05
                                    spacing: dp(1)

                                    Text {
                                        text: "Username"
                                        //font.pixelSize: dp(4)
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                        font.weight: Font.Bold
                                        color: app_color
                                        //x: parent.width * 0.25
                                    }

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/userProfile_icon.svg"
                                        fillMode: Image.PreserveAspectFit
                                        width: 12
                                        height: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: app_color
                                    }
                                }

                                Rectangle {
                                    width: parent.width * 0.9
                                    height: dp(10)
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: resetUser.activeFocus ? 2 : 1
                                    border.color: resetUser.activeFocus ? app_color : borderColor
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


                                Row {
                                    //anchors.horizontalCenter: parent.horizontalCenter
                                    x: parent.width * 0.05
                                    spacing: dp(1)

                                    Text {
                                        text: "New Password"
                                        //font.pixelSize: dp(4)
                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                        font.weight: Font.Bold
                                        color: app_color
                                        //x: parent.width * 0.25
                                    }

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/password.svg"
                                        fillMode: Image.PreserveAspectFit
                                        width: 12
                                        height: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: app_color
                                    }
                                }

                                Rectangle {
                                    width: parent.width * 0.9
                                    height: dp(10)
                                    radius: dp(1)
                                    color: surfaceColor
                                    border.width: newPassword.activeFocus ? 2 : 1
                                    border.color: newPassword.activeFocus ? app_color : borderColor
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    TextField {
                                        id: newPassword
                                        anchors {
                                            left: parent.left
                                            right: newPasswors_resetbtn.left
                                            top: parent.top
                                            bottom: parent.bottom
                                            //margins: dp(2)
                                        }
                                        placeholderText: "Enter your new password"
                                        //font.pixelSize: dp(4)
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Arial"
                                        color: "black"
                                        echoMode: newPasswors_resetbtn.checked ? TextInput.Normal : TextInput.Password
                                        background: null
                                        selectByMouse: true
                                    }


                                    Button {
                                        id: newPasswors_resetbtn
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
                        }

                        // Action Buttons

                        Button {
                            id: resetBtn
                            text: "Reset Password"
                            width: parent.width * 0.9
                            height: dp(10)
                            anchors.horizontalCenter: parent.horizontalCenter

                            background: Rectangle {
                                radius: dp(1)
                                color: resetBtn.pressed ? primaryHover : app_color
                            }

                            // contentItem: Text {
                            //     text: parent.text
                            //     //font.pixelSize: dp(4)
                            //     font.pointSize: ScreenTools.defaultFontPointSize
                            //     font.weight: Font.Medium
                            //     color: "white"
                            //     horizontalAlignment: Text.AlignHCenter
                            //     verticalAlignment: Text.AlignVCenter
                            // }

                            contentItem: Item {
                                anchors.fill: parent
                                // clip: true

                                Row {
                                    anchors.centerIn: parent      // now centers correctly
                                    spacing: dp(2)

                                    Text {
                                        text: resetBtn.text
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.weight: Font.Medium
                                        color: "white"
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/reset_password.svg"
                                        fillMode: Image.PreserveAspectFit
                                        width: 20
                                        height: 20
                                    }
                                }
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
                                MapGlobals.resetPassword(resetUser.text, newPassword.text, function(result) {
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

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: dp(8)
                            width: backRow.width

                            Row {
                                id: backRow
                                spacing: dp(2)
                                anchors.centerIn: parent

                                QGCColoredImage {
                                    source: "qrc:/InstrumentValueIcons/arrow-simple-left.svg"
                                    width: dp(4)
                                    height: dp(4)
                                    color: app_color

                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Back"
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
                                    console.log("BACK CLICKED")
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

