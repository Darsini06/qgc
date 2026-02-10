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

    property string currentView: "welcome"
    property bool isDarkMode: true

    // Color palette
    property color primaryColor: isDarkMode ? "#6366f1" : "#4f46e5"
    property color primaryHover: isDarkMode ? "#7c3aed" : "#6366f1"
    property color backgroundColor: isDarkMode ? "#0f172a" : "#f8fafc"
    property color surfaceColor: "#ffffff" //isDarkMode ? "#1e293b" : "#ffffff"
    //property color textPrimary: isDarkMode ? "#f1f5f9" : "#0f172a"
    property color textSecondary: isDarkMode ? "#94a3b8" : "#64748b"
    property color borderColor: isDarkMode ? "#334155" : "#e2e8f0"
    property color errorColor: "#ef4444"
    property color successColor: "#10b981"

    property color textPrimary: "#000000"

    property color app_color: "#5d179e"

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio


    function dp(value) {
        return value * baseUnit;
    }

    // //Background with gradient
    // Rectangle {
    //     anchors.fill: parent
    //     gradient: Gradient {
    //         GradientStop { position: 0.0; color: backgroundColor }
    //         GradientStop { position: 1.0; color: isDarkMode ? "#020617" : "#e2e8f0" }
    //     }
    // }


    StackLayout {
        anchors.fill: parent
        currentIndex: currentView === "welcome" ? 0 : (currentView === "signup" ? 1 : 2)


        // WELCOME SCREEN
        Rectangle {
            anchors.fill: parent
            color: "#ffffff"//"#ebebeb"

            // gradient: Gradient {
            //     orientation: Gradient.Horizontal
            //     GradientStop { position: 0.0; color: "#9b59b6" } // very light
            //     GradientStop { position: 1.0; color: "#6a0dad" } // base
            // }

            // ---------- Center Card ----------

            Item {
                width: parent.width * 0.85
                height: parent.height * 0.9
                anchors.centerIn: parent

                // SHADOW (REAL ELEVATION)
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

                Rectangle {
                    id: welcomecard
                    anchors.fill: parent
                    radius: dp(4)
                    color: "white"
                    clip: true

                    Item {
                        anchors.fill: parent
                        anchors.margins: dp(3)

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            // // LEFT SIDE IMAGE CONTAINER (margin provider)
                            // Item {
                            //     width: parent.width * 0.45
                            //     height: parent.height

                            //     Rectangle {
                            //         anchors.fill: parent
                            //         anchors.margins: dp(2)
                            //         radius: dp(4)
                            //         clip: true
                            //         //antialiasing: true
                            //         color: "black"

                            //         Image {
                            //             anchors.fill: parent
                            //             source: "/qmlimages/NewImages/nature_background.webp"
                            //             fillMode: Image.PreserveAspectCrop
                            //         }
                            //     }
                            // }

                            Item {
                                width: parent.width * 0.45
                                height: parent.height

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: dp(2)
                                    radius: dp(4)
                                    clip: true
                                    color: "transparent"

                                    LottieAnimation {
                                        anchors.centerIn: parent   // ✅ allowed (inside Rectangle)
                                        source: "qrc:/qmlimages/NewImages/login_lottie.json"
                                        autoPlay: true
                                        loops: Animation.Infinite
                                        scale: 0.6
                                        frameRate: 24
                                    }
                                }
                            }


                            // RIGHT SIDE SCROLLABLE CONTENT
                            ScrollView {
                                width: parent.width * 0.55
                                height: parent.height
                                clip: true

                                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                //ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                                // Container to ensure proper centering
                                Item {
                                    width: parent.width
                                    height: Math.max(loginlayout.implicitHeight, parent.height)

                                    Column {
                                        id: loginlayout
                                        width: parent.width * 0.85
                                        spacing: dp(4)
                                        //anchors.centerIn: parent

                                        anchors {
                                            top: parent.top
                                            horizontalCenter: parent.horizontalCenter
                                            topMargin: dp(2)
                                        }

                                        // Welcome Text
                                        Column {
                                            //anchors.horizontalCenter: parent.horizontalCenter
                                            width: parent.width
                                            spacing: dp(1.5)
                                            //width: parent.width * 0.85

                                            Text {
                                                text: "Welcome Back"
                                                //font.pixelSize: dp(6)
                                                font.pointSize:     ScreenTools.mediumFontPointSize
                                                font.weight: Font.Bold
                                                color: textPrimary
                                                //anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.width
                                                wrapMode: Text.Wrap
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            Text {
                                                text: "Sign in to continue your journey"
                                                //font.pixelSize: dp(3)
                                                font.pointSize:     ScreenTools.smallFontPointSize
                                                color: textSecondary
                                                //anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.width
                                                wrapMode: Text.Wrap
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        // Form
                                        Column {
                                            width: parent.width
                                            spacing: dp(3)
                                            anchors.horizontalCenter: parent.horizontalCenter

                                            // Username Field
                                            Column {
                                                width: parent.width
                                                spacing: dp(2)
                                                anchors.horizontalCenter: parent.horizontalCenter

                                                Row {
                                                    x: parent.width * 0.05
                                                    spacing: dp(1)

                                                    Text {
                                                        text: "Username or Email"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                                        font.weight: Font.Medium
                                                        color: textPrimary
                                                        //x: parent.width * 0.1
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
                                                }

                                                Rectangle {
                                                    width: parent.width * 0.9
                                                    height: dp(10) // Use dp instead of relative height
                                                    radius: dp(1) // 8/8=1
                                                    color: surfaceColor
                                                    border.width: loginUser.activeFocus ? 2 : 1
                                                    border.color: loginUser.activeFocus ? app_color : borderColor
                                                    anchors.horizontalCenter: parent.horizontalCenter

                                                    TextField {
                                                        id: loginUser
                                                        anchors.fill: parent
                                                        //anchors.margins: dp(2) // 16/8=2
                                                        placeholderText: "username or mail"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize: ScreenTools.defaultFontPointSize
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

                                                Row {
                                                    //anchors.horizontalCenter: parent.horizontalCenter
                                                    x: parent.width * 0.05
                                                    spacing: dp(1)

                                                    Text {
                                                        text: "Password"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                                        font.weight: Font.Medium
                                                        color: textPrimary
                                                        //x: parent.width * 0.25
                                                    }

                                                    // QGCColoredImage {
                                                    //     source: "/qmlimages/NewImages/password.svg"
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
                                                }

                                                Rectangle {
                                                    width: parent.width * 0.9
                                                    height: dp(10) // Use dp instead of relative height
                                                    radius: dp(1)
                                                    color: surfaceColor
                                                    border.width: loginPass.activeFocus ? 2 : 1
                                                    border.color: loginPass.activeFocus ? app_color : borderColor
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

                                                        contentItem: QGCColoredImage {
                                                            anchors.fill: parent
                                                            anchors.margins: dp(1)
                                                            fillMode: Image.PreserveAspectFit
                                                            source: parent.checked
                                                                    ? "/qmlimages/NewImages/password_visible.svg"
                                                                    : "/qmlimages/NewImages/password_hidden.svg"
                                                            color: "black"
                                                        }
                                                    }
                                                }
                                            }

                                            // Sign In Button
                                            Button {
                                                id: loginBtn
                                                text: "Sign In"
                                                width: parent.width * 0.9
                                                height: dp(10) // Adjusted size
                                                anchors.horizontalCenter: parent.horizontalCenter

                                                background: Rectangle {
                                                    radius: dp(1)
                                                    color: app_color//loginBtn.pressed ? primaryHover : app_color
                                                }

                                                contentItem: Item {
                                                    anchors.fill: parent
                                                    // clip: true

                                                    Row {
                                                        anchors.centerIn: parent      // now centers correctly
                                                        spacing: dp(2)

                                                        Text {
                                                            text: loginBtn.text
                                                            font.pointSize: ScreenTools.defaultFontPointSize
                                                            font.weight: Font.Medium
                                                            color: "white"
                                                            verticalAlignment: Text.AlignVCenter
                                                        }

                                                        QGCColoredImage {
                                                            source: "/qmlimages/NewImages/signIn.svg"
                                                            fillMode: Image.PreserveAspectFit
                                                            width: 20
                                                            height: 20
                                                        }
                                                    }
                                                }

                                                onClicked: {

                                                    if (loginUser.text.trim() === "" || loginPass.text === "") {
                                                        mainWindow.showToastMessage("Please fill all fields");
                                                        return;
                                                    }

                                                    MapGlobals.loginUserFunc(
                                                                loginUser.text.trim(),
                                                                loginPass.text,
                                                                function(result) {
                                                                    if (result) {
                                                                        // QGroundControl.saveGlobalSetting(
                                                                        //             "username",
                                                                        //             loginUser.text.trim()
                                                                        //             );

                                                                        loginUser.text = "";
                                                                        loginPass.text = "";
                                                                    }
                                                                }
                                                                );
                                                }

                                            }

                                            // Create Account text
                                            Row {
                                                //width: parent.width
                                                spacing: dp(1)
                                                anchors.horizontalCenter: parent.horizontalCenter

                                                Text {
                                                    text: "Don't have an account?"
                                                    font.pointSize: ScreenTools.smallFontPointSize
                                                    color: textSecondary
                                                }

                                                Text {
                                                    text: "Sign Up"
                                                    font.pointSize: ScreenTools.smallFontPointSize
                                                    color: app_color
                                                    font.weight: Font.Medium

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            currentView = "signup"
                                                            loginUser.text = ""
                                                            loginPass.text = ""
                                                        }
                                                    }
                                                }
                                            }

                                            // Forgot Password
                                            Text {
                                                text: "Forgot Password?"
                                                font.pointSize:     ScreenTools.smallFontPointSize
                                                color: app_color
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.width
                                                wrapMode: Text.Wrap
                                                horizontalAlignment: Text.AlignHCenter


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
                                    }
                                }
                            }

                        }

                    }


                }

            }

        }

        // SIGN UP SCREEN
        Rectangle {
            anchors.fill: parent
            color: "#ffffff"//"#ebebeb"

            // ---------- Center Card ----------

            Item {
                width: parent.width * 0.85
                height: parent.height * 0.9
                anchors.centerIn: parent

                // SHADOW (REAL ELEVATION)
                Rectangle {
                    id: shadowSource_sign
                    anchors.fill: parent
                    radius: dp(4)
                    color: "white"
                    visible: false
                }

                MultiEffect {
                    anchors.fill: shadowSource_sign
                    source: shadowSource_sign

                    shadowEnabled: true
                    shadowBlur: 0.9
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: dp(1)
                    shadowColor: "#40000000"   // soft black
                }

                Rectangle {
                    id: signUpcard
                    anchors.fill: parent
                    radius: dp(4)
                    color: "white"
                    clip: true

                    Item {
                        anchors.fill: parent
                        anchors.margins: dp(3)

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            // LEFT SIDE IMAGE
                            // Item {
                            //     width: parent.width * 0.45
                            //     height: parent.height

                            //     Rectangle {
                            //         anchors.fill: parent
                            //         anchors.margins: dp(2)   // ✅ NOW IT WORKS
                            //         radius: dp(4)
                            //         clip: true
                            //         antialiasing: true
                            //         color: "black"

                            //         Image {
                            //             anchors.fill: parent
                            //             source: "/qmlimages/NewImages/nature_background.webp"
                            //             fillMode: Image.PreserveAspectCrop
                            //         }
                            //     }
                            // }

                            Item {
                                width: parent.width * 0.45
                                height: parent.height

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: dp(2)
                                    radius: dp(4)
                                    clip: true
                                    color: "transparent"

                                    LottieAnimation {
                                        anchors.centerIn: parent   // ✅ allowed (inside Rectangle)
                                        source: "qrc:/qmlimages/NewImages/login_lottie.json"
                                        autoPlay: true
                                        loops: Animation.Infinite
                                        scale: 0.5
                                        //frameRate: 120
                                    }
                                }
                            }

                            //RIGHT SIDE FIELDS
                            Item {
                                id: scrollcontent
                                width: parent.width * 0.55
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
                                        Rectangle {
                                            id: backButton_create
                                            width: dp(10)
                                            height: dp(10)
                                            color: "transparent"
                                            z: 10

                                            anchors {
                                                top: parent.top
                                                left: parent.left
                                                topMargin: dp(2)
                                                leftMargin: dp(2)
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: currentView = "welcome"
                                            }

                                            QGCColoredImage {
                                                anchors.centerIn: parent
                                                source: "qrc:/InstrumentValueIcons/arrow-simple-left.svg"
                                                width: dp(6)
                                                height: dp(6)
                                                color: textPrimary
                                            }
                                        }

                                        // Title + Subtitle
                                        Column {
                                            width: parent.width * 0.85
                                            spacing: dp(1.5)
                                            anchors.centerIn: parent

                                            Text {
                                                text: "Create Account"
                                                font.pointSize: ScreenTools.mediumFontPointSize
                                                font.weight: Font.Bold
                                                color: textPrimary
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
                                        contentHeight: formColumn.implicitHeight + dp(6)

                                        ScrollBar.vertical: ScrollBar {
                                            policy: ScrollBar.AsNeeded
                                        }

                                        Column {
                                            id: formColumn
                                            width: flickable.width * 0.85
                                            spacing: dp(4)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.top
                                            anchors.topMargin: dp(4)


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
                                                        font.weight: Font.Medium
                                                        color: textPrimary
                                                    }

                                                    Text {
                                                        text: "*"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.8
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
                                                        font.weight: Font.Medium
                                                        color: textPrimary
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
                                                //anchors.horizontalCenter: parent.horizontalCenter

                                                Row {
                                                    //anchors.horizontalCenter: parent.horizontalCenter
                                                    x: parent.width * 0.05
                                                    spacing: dp(1)

                                                    Text {
                                                        text: "Email"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                                        font.weight: Font.Medium
                                                        color: textPrimary
                                                    }

                                                    Text {
                                                        text: "*"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.8
                                                        font.weight: Font.Medium
                                                        color: "red"
                                                    }

                                                    // QGCColoredImage {
                                                    //     source: "/qmlimages/NewImages/gmail.svg"
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
                                                    border.width: regEmail.activeFocus ? 2 : 1
                                                    border.color: regEmail.activeFocus ? app_color : borderColor
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
                                                //anchors.horizontalCenter: parent.horizontalCenter

                                                Row {
                                                    //anchors.horizontalCenter: parent.horizontalCenter
                                                    x: parent.width * 0.05
                                                    spacing: dp(1)

                                                    Text {
                                                        text: "Password"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                                        font.weight: Font.Medium
                                                        color: textPrimary
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
                                                            color: "black"
                                                        }
                                                    }

                                                }
                                            }

                                            // Confirm Password
                                            Column {
                                                width: parent.width
                                                spacing: dp(2)
                                                //anchors.horizontalCenter: parent.horizontalCenter

                                                Row {
                                                    //anchors.horizontalCenter: parent.horizontalCenter
                                                    x: parent.width * 0.05
                                                    spacing: dp(1)

                                                    Text {
                                                        text: "Confirm Password"
                                                        //font.pixelSize: dp(4)
                                                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                                                        font.weight: Font.Medium
                                                        color: textPrimary
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
                                                            color: "black"
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

                                                        MapGlobals.registerUser(regUser.text, regDisplay.text, regEmail.text, regPass.text, regConfirm.text, function(result) {
                                                            if (result) {

                                                                mainWindow.showToastMessage("Account created successfully!");

                                                                currentView = "welcome";

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
                                                                currentView = "welcome"
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
                }

            }

        }

        // RESET PASSWORD SCREEN
        Rectangle {
            anchors.fill: parent
            color: "#ffffff"//"#ebebeb"

            Item {
                width: parent.width * 0.85
                height: parent.height * 0.9
                anchors.centerIn: parent

                // SHADOW (REAL ELEVATION)
                Rectangle {
                    id: shadowSource_reset
                    anchors.fill: parent
                    radius: dp(4)
                    color: "white"
                    visible: false
                }

                MultiEffect {
                    anchors.fill: shadowSource_reset
                    source: shadowSource_reset

                    shadowEnabled: true
                    shadowBlur: 0.9
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: dp(1)
                    shadowColor: "#40000000"   // soft black
                }

                // ---------- Center Card ----------
                Rectangle {
                    id: reset_card
                    anchors.fill: parent
                    radius: dp(4)
                    color: "white"
                    clip: true

                    Item {
                        anchors.fill: parent
                        anchors.margins: dp(3)

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            // LEFT SIDE IMAGE
                            // Item {
                            //     width: parent.width * 0.45
                            //     height: parent.height

                            //     Rectangle {
                            //         anchors.fill: parent
                            //         anchors.margins: dp(2)   // ✅ NOW IT WORKS
                            //         radius: dp(4)
                            //         clip: true
                            //         antialiasing: true
                            //         color: "black"

                            //         Image {
                            //             anchors.fill: parent
                            //             source: "/qmlimages/NewImages/nature_background.webp"
                            //             fillMode: Image.PreserveAspectCrop
                            //         }
                            //     }
                            // }

                            Item {
                                width: parent.width * 0.45
                                height: parent.height

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: dp(2)
                                    radius: dp(4)
                                    clip: true
                                    color: "transparent"

                                    LottieAnimation {
                                        anchors.centerIn: parent   // ✅ allowed (inside Rectangle)
                                        source: "qrc:/qmlimages/NewImages/login_lottie.json"
                                        autoPlay: true
                                        loops: Animation.Infinite
                                        scale: 0.5
                                        //frameRate: 120
                                    }
                                }
                            }

                            Item {

                                width: parent.width * 0.55
                                height: parent.height

                                Rectangle {
                                    id: backButton_reset
                                    width: dp(10)
                                    height: dp(10)
                                    color: "transparent"
                                    z: 10

                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        topMargin: dp(2)
                                        leftMargin: dp(2)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            console.log("BACK CLICKED");
                                            currentView = "welcome"
                                        }
                                    }

                                    QGCColoredImage {
                                        anchors.centerIn: parent
                                        source: "qrc:/InstrumentValueIcons/arrow-simple-left.svg"
                                        width: dp(6)
                                        height: dp(6)
                                        color: textPrimary
                                    }
                                }


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

                                                    Row {
                                                        //anchors.horizontalCenter: parent.horizontalCenter
                                                        x: parent.width * 0.05
                                                        spacing: dp(1)

                                                        Text {
                                                            text: "Username"
                                                            //font.pixelSize: dp(4)
                                                            font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                                            font.weight: Font.Medium
                                                            color: textPrimary
                                                            //x: parent.width * 0.25
                                                        }

                                                        QGCColoredImage {
                                                            source: "/qmlimages/NewImages/userProfile_icon.svg"
                                                            fillMode: Image.PreserveAspectFit
                                                            width: 12
                                                            height: 12
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: textPrimary
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
                                                            font.weight: Font.Medium
                                                            color: textPrimary
                                                            //x: parent.width * 0.25
                                                        }

                                                        QGCColoredImage {
                                                            source: "/qmlimages/NewImages/password.svg"
                                                            fillMode: Image.PreserveAspectFit
                                                            width: 12
                                                            height: 12
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: textPrimary
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
                                                                color: "black"
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
