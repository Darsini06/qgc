import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.LocalStorage 2.0
import QtQuick.Effects

import QtWebView 1.1

import Qt.labs.lottieqt 1.0

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Rectangle {
    id: profilescreen
    anchors.fill: parent
    color: "#F8F9FB" // Light professional background
    property string currentView: MapGlobals.currentView_profile

    property string userName: QGroundControl.loadGlobalSetting("username", "")
    property string displayName: QGroundControl.loadGlobalSetting("name", "")
    property string userEmail: QGroundControl.loadGlobalSetting("email", "")
    property string name_from_db: ""
    property string mobileNo_from_db: ""
    property string email_from_db: ""
    property int rpcCompletedStatus: -1

    property string selectedImage: ""

    property real iconBaseSize: Math.min(Screen.width, Screen.height) * 0.1

    property int totalMinutes: 0
    property int missionsCompleted: 0
    property string totalDurationFormatted: "0h 0m"

    property string droneType: "loadpage"

    property bool privacyLoading: true

    property color app_color: "#4a2c6d"

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio


    function dp(value) {
        return value * baseUnit;
    }

    property bool isMobile: ScreenTools.isMobile
    property bool isTablet: ScreenTools.isMobile && !ScreenTools.isTinyScreen
    property bool isDesktop: !ScreenTools.isMobile
    property bool isSmallScreen: ScreenTools.isTinyScreen

    ListModel {
        id: sessionModel
    }

    // Connect to new session signal
    Connections {
        target: MapGlobals

        onNewSessionAdded: {
            console.log("New session added, refreshing...");
            loadSessions();
        }
    }

    Component.onCompleted: {
        console.log("ProfileScreen outer onCompleted",droneType);
        if (userName !== "") {
            userName = QGroundControl.loadGlobalSetting("username", "")
            loadUserDataFromMain();
        }
    }

    onVisibleChanged: {

        if (visible) {

            console.log("onVisibleChanged");

            loadSessions();

            droneType = QGroundControl.loadGlobalSetting("loadpage","loadpage");
            console.log("ProfileScreen droneType",droneType);

            displayName = QGroundControl.loadGlobalSetting("name", "")
            userName = QGroundControl.loadGlobalSetting("username", "")
            userEmail = QGroundControl.loadGlobalSetting("email", "")

            if (userName !== "") {
                console.log("onVisibleUserName : ",userName);
                loadUserDataFromMain();
            }
        }
    }

    onCurrentViewChanged: {
        console.log("onCurrentViewChanged")

        displayName = QGroundControl.loadGlobalSetting("name", "")
        userName = QGroundControl.loadGlobalSetting("username", "")
        userEmail = QGroundControl.loadGlobalSetting("email", "")

        if (currentView === "reports") {
            console.log("Switched to Reports view")
            loadSessions()
        }else if (currentView === "privacy_policy") {
            privacyLoader.active = true
        }
    }

    function loadSessions() {
        console.log("Loading drone sessions...");
        sessionModel.clear();

        MapGlobals.getAllSessions(function(sessions) {
            if (sessions.length === 0) {
                console.log("No drone sessions found");
                return;
            }

            for (var i = 0; i < sessions.length; i++) {
                var session = sessions[i];
                sessionModel.append({
                                        id: session.id,
                                        date: session.date,
                                        start_time: session.start_time,
                                        end_time: session.end_time,
                                        duration: session.duration || 0,
                                        created_at: session.created_at
                                    });
            }

            console.log("Loaded", sessions.length, "sessions into model");

            //Just for get Print Statement
            for (var j = 0; j < sessionModel.count; j++) {
                var item = sessionModel.get(j);
                console.log(
                            "Session", j + 1, ":",
                            "ID:", item.id,
                            "Date:", item.date,
                            "Start:", item.start_time,
                            "End:", item.end_time,
                            "Duration:", item.duration,
                            "CreatedAt:", item.created_at
                            );
            }

            updateSessionStats();

        });

    }

    function updateSessionStats() {
        var total = 0;

        for (var i = 0; i < sessionModel.count; i++) {
            var item = sessionModel.get(i);
            total += Number(item.duration || 0);
        }

        totalMinutes = total;
        missionsCompleted = sessionModel.count;

        // Convert minutes → hours + minutes
        var hours = Math.floor(total / 60);
        var minutes = total % 60;
        totalDurationFormatted = hours + "h " + minutes + "m";

        console.log("== Session Stats ==");
        console.log("Total Duration:", totalDurationFormatted);
        console.log("Missions Completed:", missionsCompleted);
    }


    function loadUserDataFromMain() {

        MapGlobals.loadUserData(userName, function(userData) {
            if (userData) {
                // Set your profile screen properties
                name_from_db = userData.displayname || "";
                mobileNo_from_db = userData.mobile_number || "";
                email_from_db = userData.email || "";
                rpcCompletedStatus = (userData.rpc_completed !== undefined && userData.rpc_completed !== null)
                        ? Number(userData.rpc_completed)
                        : -1;

                console.log("Data retrieved - Name:", name_from_db,
                            "Email:", email_from_db,
                            "Mobile:", mobileNo_from_db,
                            "RPC Status:",  rpcCompletedStatus
                            );

                console.log("Type of rpc_completed:", typeof userData.rpc_completed)
            } else {
                console.log("No user data received");
                // Clear the fields if no data
                name_from_db = "";
                mobileNo_from_db = "";
                email_from_db = "";
                rpcCompletedStatus = -1 ;
            }
        });
    }

    function to12Hour(time24) {
        if (!time24) return "";
        var parts = time24.split(":");
        if (parts.length < 2) return time24;

        var hour = parseInt(parts[0]);
        var minute = parts[1];
        var second = parts[2] || "00";
        var ampm = hour >= 12 ? "PM" : "AM";
        hour = hour % 12;
        if (hour === 0) hour = 12; // midnight/noon edge cases

        // Format with leading zeros if needed
        var formatted = hour.toString().padStart(2, '0') + ":" + minute + ":" + second + " " + ampm;
        return formatted;
    }

    function switchPage(newView) {
        // start fade OUT
        fadeOverlay.opacity = 1

        // store next page
        fadeTimer.newView = newView

        // start timer (wait until fade-out finishes)
        fadeTimer.start()
    }


    Timer {
        id: fadeTimer
        interval: 220        // must match animation duration
        repeat: false

        property string newView: ""

        onTriggered: {
            // swap page AFTER fade-out
            currentView = newView

            // fade IN
            fadeOverlay.opacity = 0
        }
    }


    Item {
        id: transitionRoot
        anchors.fill: parent

        Loader {
            id: pageLoader
            anchors.fill: parent
            asynchronous: true

            property var pageCache: ({ })

            sourceComponent: {

                if (!pageCache[currentView]) {

                    switch (currentView) {

                    case "profile":
                        pageCache[currentView] = profilePage
                        break

                    case "accountUpdate":
                        pageCache[currentView] = accountUpdatePage
                        break

                    case "privacy_policy":
                        pageCache[currentView] = privacyPage
                        break

                    case "terms&conditions":
                        pageCache[currentView] = termsPage
                        break

                    case "feedback":
                        pageCache[currentView] = feedbackPage
                        break

                    case "reports":
                        pageCache[currentView] = reportsPage
                        break

                    case "drone":
                        pageCache[currentView] = dronePage
                        break

                    default:
                        pageCache[currentView] = profilePage
                    }
                }

                return pageCache[currentView]
            }
        }

        Rectangle {
            id: fadeOverlay
            anchors.fill: parent

            // softer than pure black (looks professional)
            color: Qt.rgba(0,0,0,0.18)

            opacity: 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }


    // Rectangle {
    //     anchors.fill: parent
    //     color: "transparent"
    //     visible: pageLoader.status === Loader.Loading
    //     z: 99

    //     Item {
    //         id: lottieWrapper
    //         anchors.centerIn: parent
    //         width: dp(3)
    //         height: dp(3)
    //         scale: 0.5

    //         LottieAnimation {
    //             id: droneAnim
    //             source: "qrc:/qmlimages/NewImages/loading_color_dots.json"
    //             anchors.centerIn: parent
    //             autoPlay: true
    //             loops: Animation.Infinite
    //             //frameRate: 300   // increase speed
    //         }
    //     }
    // }

    //Profile Screen
    Component {
        id: profilePage

        Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Profile screen header - Professional Modern Design
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(parent.height * 0.12, 70)
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 15

                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            fillMode: Image.PreserveAspectFit
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            color: "white"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mainWindow.openHomeScreen();
                            }
                        }

                        Text {
                            text: qsTr("User Profile")
                            font.pointSize: ScreenTools.largeFontPointSize
                            color: "white"
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }
                    }
                    
                    // Header bottom shadow
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: "#20000000"
                    }
                }

                // Profile content area
                // Profile content area
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    padding: (isSmallScreen || isMobile) ? 15 : 25

                    GridLayout {
                        width: parent.width
                        columns: (isSmallScreen || isMobile) ? 1 : 2
                        rowSpacing: (isSmallScreen || isMobile) ? 15 : 25
                        columnSpacing: 25

                        // First Card - Profile Avatar & Stats
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredWidth: (isSmallScreen || isMobile) ? -1 : parent.width * 0.38
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: profileColumn.implicitHeight + ((isSmallScreen || isMobile) ? 30 : 50)
                            
                            Rectangle {
                                id: profileCardBg
                                anchors.fill: parent
                                color: "white"
                                radius: 12
                                border.color: "#E6E9EF"
                                border.width: 1
                                visible: false
                            }
                            
                            MultiEffect {
                                anchors.fill: profileCardBg
                                source: profileCardBg
                                shadowEnabled: true
                                shadowBlur: 1.0
                                shadowVerticalOffset: 2
                                shadowColor: "#15000000"
                            }

                            ColumnLayout {
                                id: profileColumn
                                anchors.fill: parent
                                anchors.margins: (isSmallScreen || isMobile) ? 15 : 25
                                spacing: (isSmallScreen || isMobile) ? 10 : 15
                                
                                // Unified Horizontal Profile & Stats Header
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 90
                                    spacing: 20

                                    // 1. Profile Avatar & Info (Left Corner)
                                    RowLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 12
                                        
                                        // Avatar
                                        Rectangle {
                                            width: (isSmallScreen || isMobile) ? 60 : 70
                                            height: width
                                            radius: width / 2
                                            color: "white"
                                            border.color: app_color
                                            border.width: 2
                                            
                                            AnimatedImage {
                                                anchors.centerIn: parent
                                                source: "qrc:/qmlimages/NewImages/report_gif.gif"
                                                width: parent.width * 0.85
                                                height: width
                                                fillMode: Image.PreserveAspectFit
                                            }
                                        }

                                        // Name column
                                        ColumnLayout {
                                            spacing: 2
                                            Text { text: qsTr("Welcome,"); font.pointSize: ScreenTools.smallFontPointSize * 0.85; color: "#6D7278" }
                                            Text { text: displayName || "User"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true; color: "#1A1C1E" }
                                            Text { text: userEmail || ""; font.pointSize: ScreenTools.smallFontPointSize * 0.75; color: app_color; visible: userEmail !== "" }
                                        }
                                    }

                                    // Spacing
                                    Item { Layout.fillWidth: true }

                                    // 2. Stats Section (Right Corner)
                                    RowLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 12

                                        // Flight Time Card
                                        Rectangle {
                                            width: (isSmallScreen || isMobile) ? 140 : 160
                                            height: 70
                                            radius: 12
                                            color: "#F8FAFC"
                                            border.color: "#E2E8F0"
                                            
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 10; spacing: 10
                                                Rectangle {
                                                    width: 32; height: 32; radius: 8; color: "#F3E8FF"
                                                    QGCColoredImage { anchors.centerIn: parent; source: "qrc:/InstrumentValueIcons/time.svg"; width: 18; height: 18; color: app_color }
                                                }
                                                ColumnLayout {
                                                    spacing: 0
                                                    Text { text: qsTr("Flight Time"); font.pointSize: ScreenTools.smallFontPointSize * 0.8; color: "#64748B" }
                                                    Text { text: totalDurationFormatted; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: "#0F172A" }
                                                }
                                            }
                                        }

                                        // Missions Card
                                        Rectangle {
                                            width: (isSmallScreen || isMobile) ? 140 : 160
                                            height: 70
                                            radius: 12
                                            color: "#F8FAFC"
                                            border.color: "#E2E8F0"
                                            
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 10; spacing: 10
                                                Rectangle {
                                                    width: 32; height: 32; radius: 8; color: "#DCFCE7"
                                                    QGCColoredImage { anchors.centerIn: parent; source: "qrc:/InstrumentValueIcons/checkmark.svg"; width: 18; height: 18; color: "#16A34A" }
                                                }
                                                ColumnLayout {
                                                    spacing: 0
                                                    Text { text: qsTr("Completed"); font.pointSize: ScreenTools.smallFontPointSize * 0.8; color: "#64748B" }
                                                    Text { text: missionsCompleted; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: "#0F172A" }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Second Card - Navigation Menu
                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: menuColumn.implicitHeight + 30
                            
                            Rectangle {
                                id: menuCardBg
                                anchors.fill: parent
                                color: "white"
                                radius: 12
                                border.color: "#E6E9EF"
                                border.width: 1
                                visible: false
                            }
                            
                            MultiEffect {
                                anchors.fill: menuCardBg
                                source: menuCardBg
                                shadowEnabled: true
                                shadowBlur: 1.0
                                shadowVerticalOffset: 2
                                shadowColor: "#15000000"
                            }

                            ColumnLayout {
                                id: menuColumn
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 0

                                Repeater {
                                    model: ListModel {
                                        ListElement { icon: "/qmlimages/NewImages/accountUpdate_black.svg"; name: "Account Details"; screen: "accountUpdate" }
                                        ListElement { icon: "/qmlimages/NewImages/privacy_policy_black.svg"; name: "Privacy Policy"; screen: "privacy_policy" }
                                        ListElement { icon: "/qmlimages/NewImages/terms_condition_black.svg"; name: "Terms & Conditions"; screen: "terms&conditions" }
                                        ListElement { icon: "/qmlimages/NewImages/feedback.svg"; name: "Contact & Feedback"; screen: "feedback" }
                                        ListElement { icon: "/qmlimages/NewImages/report.svg"; name: "Mission History"; screen: "reports" }
                                        ListElement { icon: "/qmlimages/NewImages/select_drone_type_black.svg"; name: "Change Profile Mode"; screen: "drone" }
                                        ListElement { icon: "/qmlimages/NewImages/logout.svg"; name: "Sign Out"; screen: "logout" }
                                    }

                                    delegate: Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 60
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 2
                                            radius: 8
                                            color: itemMouseArea.containsMouse ? "#F5F7FA" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 15
                                                spacing: 15

                                                QGCColoredImage {
                                                    source: model.icon
                                                    width: 22; height: 22
                                                    color: model.screen === "logout" ? "#E74C3C" : "#1A1C1E"
                                                }

                                                Text {
                                                    text: model.name
                                                    font.pointSize: ScreenTools.defaultFontPointSize
                                                    color: model.screen === "logout" ? "#E74C3C" : "#1A1C1E"
                                                    font.bold: itemMouseArea.containsMouse
                                                    Layout.fillWidth: true
                                                }
                                                
                                                QGCColoredImage {
                                                    source: "qrc:/InstrumentValueIcons/arrow-thin-right.svg"
                                                    width: 14; height: 14
                                                    color: "#D1D5DB"
                                                    visible: model.screen !== "logout"
                                                }
                                            }

                                            MouseArea {
                                                id: itemMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (model.screen === "logout") {
                                                        logoutdialog.createObject(mainWindow).open()
                                                    } else {
                                                        if(model.screen === "privacy_policy") privacyLoading = true
                                                        currentView = model.screen
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

    // Account Update Screen
    Component {
        id: accountUpdatePage

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "white"

                // Professional Header with Gradient-like shadow
                Rectangle {
                    id: header
                    width: parent.width
                    height: Math.max(parent.height * 0.12, 70)
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 26; height: 26
                            color: "white"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentView = "profile"
                            }
                        }

                        Text {
                            text: qsTr("Account Settings")
                            font.pointSize: ScreenTools.largeFontPointSize
                            font.bold: true; color: "white"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                // Account Update content area
                ScrollView {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    padding: (isSmallScreen || isMobile) ? 15 : 25

                    GridLayout {
                        width: parent.width
                        columns: (isSmallScreen || isMobile) ? 1 : 2
                        rowSpacing: (isSmallScreen || isMobile) ? 15 : 25
                        columnSpacing: 25

                        // First Card - Profile Banner
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: (isSmallScreen || isMobile) ? -1 : parent.width * 0.4
                            Layout.preferredHeight: (isSmallScreen || isMobile) ? 140 : 300
                            radius: 12
                            clip: true
                            
                            Image {
                                anchors.fill: parent
                                source: "qrc:/qmlimages/NewImages/nature_background.webp"
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                            
                            // Accent Overlay
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#40000000" }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                        }

                        // Second Card - Form
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: formColumn.implicitHeight + 30
                            color: "white"
                            radius: 5
                            border.color: "#e0e0e0"
                            border.width: 1

                            Column {
                                id: formColumn
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10

                                // Name Field
                                Column {
                                    width: parent.width
                                    spacing: 5

                                    Text {
                                        text: "Profile Name"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        leftPadding: 5
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        radius: 8
                                        color: "white"
                                        border.width: namefield.activeFocus ? 2 : 1
                                        border.color: namefield.activeFocus ? app_color : "#dcdde1"

                                        TextField {
                                            id: namefield
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter your name"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "#2c3e50"
                                            background: null
                                            selectByMouse: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: name_from_db

                                            validator: RegularExpressionValidator {
                                                regularExpression: /^[a-zA-Z\s]*$/
                                            }
                                        }
                                    }

                                }

                                // username Field
                                Column {
                                    width: parent.width
                                    spacing: 5

                                    Text {
                                        text: "Username"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        leftPadding: 5
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        radius: 8
                                        color: "white"
                                        border.width: _username.activeFocus ? 2 : 1
                                        border.color: _username.activeFocus ? app_color : "#dcdde1"

                                        TextField {
                                            id: _username
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter your username"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "#2c3e50"
                                            background: null
                                            selectByMouse: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: userName

                                            validator: RegularExpressionValidator {
                                                regularExpression: /^[a-zA-Z\s]*$/
                                            }
                                        }
                                    }
                                }

                                // Email Field
                                Column {
                                    width: parent.width
                                    spacing: 5

                                    Text {
                                        text: "Email"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        leftPadding: 5
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        radius: 8
                                        color: "white"
                                        border.width: emailField.activeFocus ? 2 : 1
                                        border.color: emailField.activeFocus ? app_color : "#dcdde1"

                                        TextField {
                                            id: emailField
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter your email"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "#2c3e50"
                                            background: null
                                            selectByMouse: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            inputMethodHints: Qt.ImhEmailCharactersOnly
                                            text: email_from_db
                                        }
                                    }
                                }

                                // Mobile Number Field
                                Column {
                                    width: parent.width
                                    spacing: 5

                                    Text {
                                        text: "Mobile Number"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        leftPadding: 5
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        radius: 8
                                        color: "white"
                                        border.width: mobileField.activeFocus ? 2 : 1
                                        border.color: mobileField.activeFocus ? app_color : "#dcdde1"

                                        TextField {
                                            id: mobileField
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter mobile number"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "#2c3e50"
                                            background: null
                                            selectByMouse: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            text: mobileNo_from_db
                                        }
                                    }
                                }

                                // RPC Completion Question
                                Column {
                                    width: parent.width * 0.95
                                    spacing: 8
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        text: "Have you completed the RPC?"
                                        font.pointSize: ScreenTools.defaultFontPointSize

                                        color: "#333333"
                                    }

                                    Row {
                                        spacing: 30
                                        //anchors.horizontalCenter: parent.horizontalCenter

                                        // Yes Radio Button
                                        Row {
                                            spacing: 8
                                            anchors.verticalCenter: parent.verticalCenter

                                            Rectangle {
                                                width: 15
                                                height: 15
                                                radius: 10
                                                border.width: 2
                                                border.color: app_color//"#1b1c3e"
                                                color: rpcCompletedStatus === 1 ? app_color : "transparent"

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: rpcCompletedStatus = 1
                                                }
                                            }

                                            Text {
                                                text: "Yes"
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#000000"
                                                anchors.verticalCenter: parent.verticalCenter

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: rpcCompletedStatus = 1
                                                }
                                            }
                                        }

                                        // No Radio Button
                                        Row {
                                            spacing: 8
                                            anchors.verticalCenter: parent.verticalCenter

                                            Rectangle {
                                                width: 15
                                                height: 15
                                                radius: 10
                                                border.width: 2
                                                border.color: app_color//"#1b1c3e"
                                                color: rpcCompletedStatus === 0 ? app_color : "transparent"

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: rpcCompletedStatus = 0
                                                }
                                            }

                                            Text {
                                                text: "No"
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#000000"
                                                anchors.verticalCenter: parent.verticalCenter

                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: rpcCompleted.checked = "No"
                                                }
                                            }
                                        }
                                    }


                                }

                                // Update Button
                                Button {
                                    text: "Update"
                                    width: parent.width * 0.3
                                    height: 40
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    onClicked: {
                                        if (!MapGlobals.validateUsername(_username.text,_username)) return;
                                        if (!MapGlobals.validateDisplayName(namefield.text,namefield)) return;
                                        if (!MapGlobals.validateEmail(emailField.text,emailField)) return;

                                        var _rpcCompleted =  rpcCompletedStatus //=== "Yes" ? 1 : 0;
                                        console.log("_rpcCompleted : ",_rpcCompleted)

                                        MapGlobals.updateUser(userName,_username.text, namefield.text, emailField.text,mobileField.text,_rpcCompleted, function(result) {
                                            if (result) {

                                                QGroundControl.saveGlobalSetting("username", _username.text);
                                                QGroundControl.saveGlobalSetting("name", namefield.text);
                                                QGroundControl.saveGlobalSetting("email", emailField.text);

                                                mainWindow.showToastMessage("Updated successfully!");

                                                currentView = "profile";
                                            }
                                        });
                                    }

                                    background: Rectangle {
                                        radius: 5
                                        color: app_color//parent.pressed ? "#218838" : "#28a745"
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                Item { height: 10 } // Spacer
                            }
                        } //SecondCard
                    } // GridLayout
                }

        }

        }
    }

    // Privacy Policy
    Component {
        id: privacyPage

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "white"

                /* ================= HEADER ================= */
                Rectangle {
                    id: header
                    width: parent.width
                    height: Math.max(parent.height * 0.12, 70)
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 26; height: 26
                            color: "white"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    currentView = "profile"
                                    privacyLoader.active = false
                                    privacyLoading = true
                                }
                            }
                        }

                        Text {
                            text: qsTr("Privacy Policy")
                            font.pointSize: ScreenTools.largeFontPointSize
                            font.bold: true; color: "white"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                /* ================= CONTENT AREA ================= */
                Item {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    // White background (prevents flash)
                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                    }

                    /* ===== WEBVIEW LOADER ===== */
                    Loader {
                        id: privacyLoader
                        anchors.fill: parent
                        active: currentView === "privacy_policy"
                        visible: !privacyLoading
                        asynchronous: true

                        onActiveChanged: {
                            if (active)
                                privacyLoading = true
                        }

                        sourceComponent: WebView {
                            anchors.fill: parent
                            url: "https://www.nithra.mobi/privacy.php"

                            onLoadingChanged: function(loadRequest) {
                                if (loadRequest.status === WebView.LoadStartedStatus) {
                                    privacyLoading = true
                                } else if (loadRequest.status === WebView.LoadSucceededStatus ||
                                           loadRequest.status === WebView.LoadFailedStatus) {
                                    privacyLoading = false
                                }
                            }
                        }
                    }

                    /* ===== LOADING INDICATOR ===== */
                    Rectangle {
                        anchors.fill: parent
                        color: "#00000020"
                        visible: privacyLoading
                        z: 10

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: true
                            width: 40
                            height: 40
                        }
                    }
                }
            }
        }

    }

    // Terms & Conditions
    Component {
        id: termsPage

        Item {
            anchors.fill: parent
            Rectangle {
                color: "white"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(parent.height * 0.12, 70)
                        color: app_color

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 20

                            QGCColoredImage {
                                source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                                width: 26; height: 26
                                color: "white"
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: currentView = "profile"
                                }
                            }

                            Text {
                                text: qsTr("Terms & Conditions")
                                font.pointSize: ScreenTools.largeFontPointSize
                                color: "white"
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // // Content Area
                    // Item {
                    //     Layout.fillWidth: true
                    //     Layout.fillHeight: true

                    //     // WebView Loader (LAZY LOAD)
                    //     Loader {
                    //         id: termsconditionsLoader
                    //         anchors.fill: parent
                    //         active: currentView === "privacy_policy"

                    //         sourceComponent: WebView {
                    //             anchors.fill: parent
                    //             url: "https://www.nithra.mobi/privacy.php"

                    //             onLoadingChanged: function(loadRequest) {
                    //                 if (loadRequest.status === WebView.LoadStartedStatus) {
                    //                     privacyLoading = true
                    //                 } else if (loadRequest.status === WebView.LoadSucceededStatus ||
                    //                            loadRequest.status === WebView.LoadFailedStatus) {
                    //                     privacyLoading = false
                    //                 }
                    //             }
                    //         }
                    //     }

                    //     // Center Loader
                    //     BusyIndicator {
                    //         running: privacyLoading
                    //         visible: privacyLoading
                    //         anchors.centerIn: parent
                    //         width: 40
                    //         height: 40
                    //     }
                    // }

                }

            }

        }


    }

    // Feedback Screen
    Component {
        id: feedbackPage

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "white"

                /* ================= HEADER ================= */
                Rectangle {
                    id: header
                    width: parent.width
                    height: Math.max(parent.height * 0.12, 70)
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 26; height: 26
                            color: "white"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentView = "profile"
                            }
                        }

                        Text {
                            text: qsTr("User Feedback")
                            font.pointSize: ScreenTools.largeFontPointSize
                            font.bold: true; color: "white"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                /* ================= CONTENT ================= */
                ScrollView {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    GridLayout {
                        width: parent.width
                        columns: (isSmallScreen || isMobile) ? 1 : 2
                        rowSpacing: 20
                        columnSpacing: 20
                        anchors.margins: 15

                        // Illustrative Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (isSmallScreen || isMobile) ? 120 : 300
                            radius: 12
                            color: "#F8FAFC"
                            border.color: "#E2E8F0"
                            border.width: 1

                            Item {
                                width: (isSmallScreen || isMobile) ? 60 : 100
                                height: (isSmallScreen || isMobile) ? 60 : 100
                                anchors.centerIn: parent

                                LottieAnimation {
                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/feedback_1.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.2
                                }
                            }
                        }

                        // Form Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            implicitHeight: feedbackColumn.implicitHeight + 40
                            color: "white"
                            radius: 12
                            border.color: "#E2E8F0"
                            border.width: 1

                            ColumnLayout {
                                id: feedbackColumn
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Text { text: "Contact Information"; font.bold: true; color: "#1E293B" }
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 45
                                        radius: 8
                                        border.color: feed_mobile.activeFocus ? app_color : "#CBD5E1"
                                        border.width: 1
                                        TextField {
                                            id: feed_mobile
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            placeholderText: "Mobile Number"
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            background: null
                                        }
                                    }
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 45
                                        radius: 8
                                        border.color: feed_email.activeFocus ? app_color : "#CBD5E1"
                                        border.width: 1
                                        TextField {
                                            id: feed_email
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            placeholderText: "Email Address"
                                            inputMethodHints: Qt.ImhEmailCharactersOnly
                                            background: null
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Text { text: "Details"; font.bold: true; color: "#1E293B" }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 120
                                        radius: 8
                                        border.color: feedbackArea.activeFocus ? app_color : "#CBD5E1"
                                        border.width: 1
                                        TextArea {
                                            id: feedbackArea
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            placeholderText: "Tell us how we can improve..."
                                            wrapMode: TextArea.Wrap
                                            background: null
                                        }
                                    }
                                }

                                Button {
                                    text: "Submit Feedback"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 45
                                    onClicked: {
                                        if (feedbackArea.text === "") {
                                            mainWindow.showToastMessage("Please enter your feedback");
                                            return;
                                        }
                                        MapGlobals.insertFeedback(userName, feed_mobile.text, feed_email.text, feedbackArea.text, function(ok) {
                                            if (ok) {
                                                mainWindow.showToastMessage("Thank you for your feedback!");
                                                currentView = "profile";
                                            }
                                        });
                                    }
                                    background: Rectangle { radius: 8; color: app_color }
                                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Reports Screen
    Component {
        id: reportsPage

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "white"

                /* ================= HEADER ================= */
                Rectangle {
                    id: header
                    width: parent.width
                    height: Math.max(parent.height * 0.12, 70)
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 26; height: 26
                            color: "white"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: currentView = "profile"
                            }
                        }

                        Text {
                            text: qsTr("Mission Reports")
                            font.pointSize: ScreenTools.largeFontPointSize
                            font.bold: true; color: "white"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                /* ================= CONTENT ================= */
                ScrollView {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    padding: (isSmallScreen || isMobile) ? 10 : 20

                    ColumnLayout {
                        width: parent.width
                        spacing: 20

                        // Illustration Header
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: (isSmallScreen || isMobile) ? 120 : 200
                            radius: 12
                            color: "#F1F5F9"
                            LottieAnimation {
                                anchors.centerIn: parent
                                source: "qrc:/qmlimages/NewImages/report_1.json"
                                autoPlay: true
                                loops: Animation.Infinite
                                scale: 0.15
                            }
                        }

                        // Data Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: reportsContent.implicitHeight + 40
                            radius: 12
                            border.color: "#E2E8F0"
                            color: "white"

                            ColumnLayout {
                                id: reportsContent
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 15

                                // Table Headers (Simplified for mobile)
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Text { text: "Date"; font.bold: true; Layout.fillWidth: true; color: "#64748B" }
                                    Text { text: "Start"; font.bold: true; Layout.preferredWidth: 80; color: "#64748B" }
                                    Text { text: "End"; font.bold: true; Layout.preferredWidth: 80; color: "#64748B" }
                                }

                                // Separator
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#F1F5F9" }

                                // List
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Repeater {
                                        model: sessionModel
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            height: 50
                                            color: index % 2 === 0 ? "transparent" : "#F8FAFC"
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 5
                                                spacing: 10
                                                Text { text: model.date || "NA"; Layout.fillWidth: true; font.pointSize: ScreenTools.defaultFontPointSize }
                                                Text { text: model.start_time || "NA"; Layout.preferredWidth: 80 }
                                                Text { text: model.end_time || "NA"; Layout.preferredWidth: 80 }
                                            }
                                        }
                                    }
                                    
                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "No session history found"
                                        visible: sessionModel.count === 0
                                        color: "#94A3B8"
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
        id: dronePage

        Item {
            id: root
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "white"

                /* ================= HEADER ================= */
                Rectangle {
                    id: header
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Math.max(parent.height * 0.12, 70)
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 26; height: 26
                            color: "white"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: currentView = "profile"
                            }
                        }

                        Text {
                            text: qsTr("Select Mission Profile")
                            font.pointSize: ScreenTools.largeFontPointSize
                            font.bold: true; color: "white"
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                /* ================= CONTENT ================= */
                Item {
                    id : contentArea
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 20

                    /* ---- STATE ---- */
                    property int selectedIndex: -1

                    property var buttonModel: [
                        { label: "Camera", image: "qrc:/qmlimages/NewImages/camerabg.png" },
                        { label: "Agri", image: "qrc:/qmlimages/NewImages/agribg.png" },
                        { label: "Mapping",image: "qrc:/qmlimages/NewImages/mapbg.png" }
                    ]

                    Component.onCompleted: {
                        var saved = QGroundControl.loadGlobalSetting("loadpage", "loadpage").trim()
                        for (var i = 0; i < buttonModel.length; i++) {
                            if (buttonModel[i].label === saved) {
                                selectedIndex = i
                                break
                            }
                        }
                    }

                    Column {
                        id: mainColumn
                        spacing: 40
                        width: parent.width * 0.9
                        anchors.centerIn: parent

                        Grid {
                            id: grid
                            columns: 3
                            spacing: (isSmallScreen || isMobile) ? 10 : 20
                            width: parent.width
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: contentArea.buttonModel

                                Item {
                                    id: wrapper

                                    // ---- CARD SIZE (CARD CONTROLS SIZE — NOT CONTENT) ----
                                    width: (grid.width - (grid.spacing * (grid.columns - 1))) / grid.columns
                                    height: width * 0.7        // responsive aspect ratio (IMPORTANT)

                                    // ---------- SHADOW SOURCE ----------
                                    Rectangle {
                                        id: shadowSource
                                        anchors.fill: card
                                        radius: 8
                                        color: "white"
                                        visible: false
                                    }

                                    // ---------- REAL SHADOW ----------
                                    MultiEffect {
                                        anchors.fill: shadowSource
                                        source: shadowSource
                                        shadowEnabled: true
                                        shadowHorizontalOffset: 0
                                        shadowVerticalOffset: dp(1)
                                        shadowBlur: 1.5
                                        shadowColor: "#40000000"
                                    }

                                    // ---------- CARD ----------
                                    Button {
                                        id: card
                                        anchors.fill: parent
                                        padding: 0

                                        background: Rectangle {
                                            radius: 8
                                            color: "white"
                                            border.width: contentArea.selectedIndex === index ? 2.5 : 1
                                            border.color: contentArea.selectedIndex === index
                                                          ? app_color
                                                          : "#D3D3D3"

                                            // Rectangle {
                                            //     anchors.fill: parent
                                            //     radius: parent.radius
                                            //     color: contentArea.selectedIndex === index
                                            //            ? Qt.rgba(0,0,0,0.15)
                                            //            : "transparent"
                                            // }
                                        }

                                        // ===== CONTENT =====
                                        contentItem: Item {
                                            anchors.fill: parent
                                            clip: true

                                            // IMAGE CONTAINER (controls margin once)
                                            Item {
                                                id: imageContainer
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                clip: true

                                                // ---- IMAGE ----
                                                Image {
                                                    anchors.fill: parent
                                                    source: modelData.image
                                                    fillMode: Image.PreserveAspectCrop
                                                }

                                                // ---- GRADIENT ----
                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    height: parent.height * 0.35

                                                    gradient: Gradient {
                                                        GradientStop { position: 0.0; color: "#00000000" }
                                                        GradientStop { position: 1.0; color: "#AA000000" }
                                                    }
                                                }

                                                // ---- TEXT ----
                                                Text {
                                                    text: modelData.label
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    anchors.margins: 12

                                                    color: "white"
                                                    font.bold: true
                                                    font.pointSize: ScreenTools.defaultFontPointSize
                                                    horizontalAlignment: Text.AlignHCenter
                                                    wrapMode: Text.WordWrap
                                                }
                                            }
                                        }

                                        // ---- SELECTION CHECK ICON ----
                                        // Rectangle {
                                        //     visible: contentArea.selectedIndex === index

                                        //     width: 20
                                        //     height: 20
                                        //     //radius: 14
                                        //     color: "transparent"
                                        //     //border.color: app_color
                                        //     //border.width: 2

                                        //     anchors.top: parent.top
                                        //     anchors.right: parent.right
                                        //     anchors.margins: 15

                                        //     z: 10   // force above everything

                                        //     QGCColoredImage {
                                        //         anchors.centerIn: parent
                                        //         source: "qrc:/qmlimages/check.svg"
                                        //         width: 20
                                        //         height: 20
                                        //         color: app_color
                                        //     }
                                        // }

                                        onClicked: {
                                            contentArea.selectedIndex = index
                                        }
                                    }

                                }
                            }
                        }

                        Button {
                            text: "Continue"
                            width: parent.width * 0.5
                            height: 40
                            enabled: contentArea.selectedIndex !== -1
                            anchors.horizontalCenter: parent.horizontalCenter

                            background: Rectangle {
                                radius: 5
                                color: enabled ? app_color : "#D3D3D3"
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                console.log("Selected:", contentArea.buttonModel[contentArea.selectedIndex].label)
                                QGroundControl.saveGlobalSetting("loadpage", contentArea.buttonModel[contentArea.selectedIndex].label)
                                mainWindow.showToastMessage(contentArea.buttonModel[contentArea.selectedIndex].label + " Selected")

                                mainWindow.openHomeScreen();
                                //currentView = "profile"
                            }
                        }
                    }


                }


                //     Item {
                //         anchors.top: header.bottom
                //         anchors.left: parent.left
                //         anchors.right: parent.right
                //         anchors.bottom: parent.bottom
                //         anchors.margins: 10

                //         /* -------- RIGHT CARD -------- */
                //         Rectangle {
                //             id: rightCard
                //             anchors.left: reportLeft.right
                //             anchors.right: parent.right
                //             anchors.top: parent.top
                //             anchors.bottom: parent.bottom
                //             anchors.leftMargin: 10
                //             radius: 5
                //             color: "white"
                //             border.color: "#e0e0e0"

                //             /* ---- STATE ---- */
                //             property int selectedIndex: -1

                //             property var buttonModel: [
                //                 { label: "Camera",  color: "#1b2a49", border: "#3b6ea5", image: "/qmlimages/NewImages/cameradrone.svg" },
                //                 { label: "Agri",    color: "#1c3f2b", border: "#4CAF50", image: "/qmlimages/NewImages/agri.png" },
                //                 { label: "Mapping", color: "#1b2a49", border: "#3b6ea5", image: "/qmlimages/NewImages/survey.png" }
                //                 //{ label: "VTOL",    color: "#2e1437", border: "#9b59b6", image: "/qmlimages/NewImages/vtol.png" }
                //             ]

                //             Component.onCompleted: {
                //                 var saved = QGroundControl.loadGlobalSetting("loadpage", "loadpage").trim()
                //                 for (var i = 0; i < buttonModel.length; i++) {
                //                     if (buttonModel[i].label === saved) {
                //                         selectedIndex = i
                //                         break
                //                     }
                //                 }
                //             }

                //             Grid {
                //                 anchors.centerIn: parent
                //                 columns: 2
                //                 spacing: 20
                //                 width: parent.width * 0.9
                //                 height: parent.height * 0.9

                //                 Repeater {
                //                     model: rightCard.buttonModel

                //                     Button {
                //                         width: parent.width * 0.45
                //                         height: parent.height * 0.45

                //                         padding: 0
                //                         leftPadding: 0
                //                         rightPadding: 0
                //                         topPadding: 0
                //                         bottomPadding: 0

                //                         background: Rectangle {
                //                             anchors.fill: parent
                //                             radius: 12
                //                             color: modelData.color
                //                             border.width: 2
                //                             border.color: rightCard.selectedIndex === index
                //                                           ? "yellow"
                //                                           : modelData.border
                //                         }

                //                         contentItem: Item {
                //                             anchors.fill: parent
                //                             Column {
                //                                 anchors.centerIn: parent
                //                                 spacing: 10

                //                                 Image {
                //                                     source: modelData.image
                //                                     width: 48
                //                                     height: 48
                //                                     fillMode: Image.PreserveAspectFit
                //                                 }

                //                                 Text {
                //                                     text: modelData.label
                //                                     color: "white"
                //                                     font.bold: true
                //                                 }
                //                             }

                //                         }


                //                         QGCColoredImage {
                //                             visible: rightCard.selectedIndex === index
                //                             source: "qrc:/qmlimages/check.svg"
                //                             width: 18
                //                             height: 18
                //                             anchors.top: parent.top
                //                             anchors.right: parent.right
                //                             anchors.margins: 8
                //                             color: "green"
                //                         }

                //                         onClicked: {
                //                             rightCard.selectedIndex = index
                //                             QGroundControl.saveGlobalSetting("loadpage", modelData.label)
                //                             mainWindow.showToastMessage(modelData.label + " Selected")
                //                             currentView = "profile"
                //                         }
                //                     }
                //                 }
                //             }

                //         }
                //     }


            }
        }

    }

    FileDialog {
        id: imageDialog
        title: "Choose Image"
        nameFilters: ["*.png", "*.jpg", "*.jpeg"]
        onAccepted: {
            if (imageDialog.currentFile !== "") {
                selectedImage = imageDialog.currentFile
                console.log("Selected image path:", selectedImage)
            } else {
                console.warn("No image selected.")
            }
        }
    }

    Component {
        id: logoutdialog

        QGCPopupDialog {
            id: popup
            title: qsTr("Logout")

            buttons: Dialog.Yes | Dialog.No

            onAccepted: {
                QGroundControl.saveBoolGlobalSetting("login", false)
                QGroundControl.saveGlobalSetting("loadpage", "loadpage")
                popup.visible = false
                MapGlobals.profile()
            }

            onRejected: {
                popup.visible = false
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel {
                    text: qsTr("Are you sure you want to logout?")
                    Layout.fillWidth: true
                }
            }
        }
    }

}





