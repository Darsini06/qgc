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

Item {
    id: profilescreen
    anchors.fill: parent
    property string currentView: MapGlobals.currentView_profile//"profile" // options: main, accountUpdate, userGuide, record, reports, feedback, settings

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

    property color app_color: "#5d179e"

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio


    function dp(value) {
        return value * baseUnit;
    }



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
            console.log("ProfileScreenNew droneType",droneType);

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


    Loader {
        id: pageLoader
        anchors.fill: parent
        asynchronous: true
        active: true
        visible: true

        property var pageCache: ({ })

        sourceComponent: {
            if (!pageCache[currentView]) {
                switch (currentView) {
                case "profile": pageCache[currentView] = profilePage; break
                case "accountUpdate": pageCache[currentView] = accountUpdatePage; break
                case "privacy_policy": pageCache[currentView] = privacyPage; break
                case "terms&conditions": pageCache[currentView] = termsPage; break
                case "feedback": pageCache[currentView] = feedbackPage; break
                case "reports": pageCache[currentView] = reportsPage; break
                case "drone": pageCache[currentView] = dronePage; break
                default: pageCache[currentView] = profilePage
                }
            }
            return pageCache[currentView]
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        visible: pageLoader.status === Loader.Loading
        z: 99

        Item {
            id: lottieWrapper
            anchors.centerIn: parent
            width: dp(3)
            height: dp(3)
            scale: 0.5

            LottieAnimation {
                id: droneAnim
                source: "qrc:/qmlimages/NewImages/loading_lottie.json"
                anchors.centerIn: parent
                autoPlay: true
                loops: Animation.Infinite
                frameRate: 300   // increase speed
            }
        }
    }

    //Profile Screen
    Component {
        id: profilePage

        Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Profile screen header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: app_color//"#1b1c3e"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 10

                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            fillMode: Image.PreserveAspectFit
                            width: 25
                            height: 25
                            color: "white"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // mainWindow.profileScreen1(false)
                                    mainWindow.openNewScreen();
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QGCColoredImage {
                            id: homeIcon
                            source: "/qmlimages/NewImages/user_profile.svg"
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }

                        Text {
                            text: "Profile"
                            //font.pointSize: 18
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: "white"
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Profile content area
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.bottomMargin: 20
                    spacing: 20

                    // First Card - Profile Info & Stats
                    Rectangle {
                        Layout.preferredWidth: parent.width * 0.45
                        Layout.fillHeight: true
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10
                            clip: true

                            // Profile Image
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 80
                                height: 80
                                radius: 40
                                color: "transparent"

                                QGCColoredImage {
                                    anchors.centerIn: parent
                                    source: "/qmlimages/NewImages/profileImage.png"
                                    width: 80
                                    height: 80
                                    fillMode: Image.PreserveAspectFit
                                    //color: "#666666"
                                    color: "transparent"

                                }
                            }

                            // Name
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: displayName || "Anonymous"
                                font.pointSize: ScreenTools.mediumFontPointSize
                                font.bold: true
                                color: "#333333"
                            }

                            // Email
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: userEmail || "user@example.com"
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: "#666666"
                            }

                            // Stats Section
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                // Hours Flown
                                RowLayout {
                                    spacing: 10
                                    QGCColoredImage {
                                        source: "qrc:/InstrumentValueIcons/time.svg"
                                        width: 20
                                        height: 20
                                        color: "#2c3e50"
                                    }
                                    Text {
                                        text: "Total Hours Flown"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        color: "#666666"
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: totalDurationFormatted
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                    }
                                }

                                // Missions Completed
                                RowLayout {
                                    spacing: 10
                                    QGCColoredImage {
                                        source: "qrc:/InstrumentValueIcons/checkmark.svg"
                                        width: 20
                                        height: 20
                                        color: "#2c3e50"
                                    }
                                    Text {
                                        text: "Missions Completed"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        color: "#666666"
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: missionsCompleted
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                    }
                                }
                            }
                        }
                    }

                    // Second Card - Menu List
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        ColumnLayout
                        {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 0
                            clip: true

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                model: ListModel {
                                    ListElement { icon: "/qmlimages/NewImages/accountUpdate_black.svg"; name: " Account Update "; screen: "accountUpdate" }
                                    ListElement { icon: "/qmlimages/NewImages/privacy_policy_black.svg"; name: " Privacy Policy "; screen: "privacy_policy" }
                                    ListElement { icon: "/qmlimages/NewImages/terms_condition_black.svg"; name: "Terms & Conditions"; screen: "terms&conditions" }
                                    ListElement { icon: "/qmlimages/NewImages/feedback.svg"; name: "Feedback"; screen: "feedback" }
                                    ListElement { icon: "/qmlimages/NewImages/report.svg"; name: "Reports"; screen: "reports" }
                                    ListElement { icon: "/qmlimages/NewImages/select_drone_type_black.svg"; name: "Select Application"; screen: "drone" }
                                    ListElement { icon: "/qmlimages/NewImages/logout.svg"; name: "Logout"; screen: "logout" }
                                }


                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 50
                                    color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 15

                                        QGCColoredImage {
                                            source: model.icon
                                            width: 20
                                            height: 20
                                            color: "transparent"
                                        }

                                        Text {
                                            text: model.name
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            color: "#333333"
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 1
                                        color: "#eeeeee"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.screen === "logout") {
                                                logoutdialog.createObject(mainWindow).open()
                                            } else {

                                                if(model.screen === "privacy_policy"){
                                                    privacyLoading = true
                                                }

                                                currentView = model.screen // This updates StackLayout.currentIndex
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

                // Header
                Rectangle {
                    id: header
                    width: parent.width
                    height: parent.height * 0.15
                    color: app_color//"#1b1c3e"

                    QGCColoredImage {
                        id: backArrow
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        width: 25
                        height: 25
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentView = "profile"
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        QGCColoredImage {
                            id: accountUpdate
                            source: "/qmlimages/NewImages/accountUpdate_black.svg"
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }

                        Text {
                            text: "Account Update"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.bold: true
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Account Update content area
                Item {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10

                    // First Card - Profile Info & Stats
                    Rectangle {
                        id: leftCard
                        width: parent.width * 0.4
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10

                            Item {
                                width: 150
                                height: 150
                                anchors.horizontalCenter: parent.horizontalCenter

                                LottieAnimation {
                                    id: droneAnim
                                    anchors.fill: parent
                                    source: "qrc:/qmlimages/NewImages/accountupdate_lottie.json"
                                    autoPlay: true
                                    loops: Animation.Infinite

                                    onStatusChanged: console.log("Lottie Status:", status)
                                }
                            }


                            // Text {
                            //     text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                            //     wrapMode: Text.WordWrap
                            //     font.pointSize: ScreenTools.defaultFontPointSize
                            //     color: "black" // Changed from white to black for visibility
                            //     horizontalAlignment: Text.AlignHCenter
                            //     width: parent.width - 40 // Add some margin
                            // }
                        }
                    }

                    // Second Card - Form
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: leftCard.right
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            //contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            Column {
                                id: formColumn
                                width: parent.width
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

                        }
                    } //SecondCaed

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
                    height: parent.height * 0.15
                    color: app_color//"#1b1c3e"

                    // Back arrow (left center)
                    QGCColoredImage {
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        width: 25
                        height: 25
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                currentView = "profile"
                                privacyLoader.active = false
                                privacyLoading = true
                            }
                        }
                    }

                    // Center title + icon
                    Row {
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/privacy_policy_black.svg"
                            width: 25
                            height: 25
                            color: "white"
                        }

                        Text {
                            text: "Privacy Policy"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.bold: true
                            color: "white"
                            verticalAlignment: Text.AlignVCenter
                        }
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
                        Layout.preferredHeight: Screen.height * 0.15
                        color: app_color//"#1b1c3e"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 10

                            QGCColoredImage {
                                source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                                fillMode: Image.PreserveAspectFit
                                width: 25
                                height: 25
                                color: "white"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        //termsconditionsLoader.active = false
                                        currentView = "profile"
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            QGCColoredImage {
                                id: termsconditions
                                source: "/qmlimages/NewImages/terms_condition_black.svg"
                                width: 25
                                height: 25
                                fillMode: Image.PreserveAspectFit
                                color: "white"
                            }

                            Text {
                                text: "Terms & Conditions"
                                font.pointSize: ScreenTools.mediumFontPointSize
                                color: "white"
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }
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
                    height: parent.height * 0.15
                    color: app_color//"#1b1c3e"

                    // Back Arrow (Left Center)
                    QGCColoredImage {
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        width: 25
                        height: 25
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentView = "profile"
                        }
                    }

                    // Center Title
                    Row {
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/feedback.svg"
                            width: 25
                            height: 25
                            color: "white"
                        }

                        Text {
                            text: "Feedback"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.bold: true
                            color: "white"
                        }
                    }
                }

                /* ================= CONTENT ================= */
                Item {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10

                    /* ===== LEFT CARD ===== */
                    Rectangle {
                        id: leftCard
                        width: parent.width * 0.4
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        radius: 5
                        color: "white"
                        border.color: "#e0e0e0"
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10

                            Item {
                                width: 150
                                height: 150
                                anchors.horizontalCenter: parent.horizontalCenter

                                LottieAnimation {
                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/feedback_1.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.4
                                }
                            }

                            // Text {
                            //     text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                            //     wrapMode: Text.WordWrap
                            //     horizontalAlignment: Text.AlignHCenter
                            //     font.pointSize: ScreenTools.defaultFontPointSize
                            //     color: "black"
                            //     width: parent.width - 40
                            // }
                        }
                    }

                    /* ===== RIGHT CARD ===== */
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: leftCard.right
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        radius: 5
                        color: "white"
                        border.color: "#e0e0e0"
                        border.width: 1

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            Column {
                                width: parent.width
                                spacing: 10

                                /* ===== Mobile ===== */
                                Column {
                                    spacing: 5
                                    width: parent.width

                                    Text { text: "Mobile Number"; font.bold: true }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        radius: 8
                                        border.width: feed_mobile.activeFocus ? 2 : 1
                                        border.color: feed_mobile.activeFocus ? app_color : "#dcdde1"

                                        TextField {
                                            id: feed_mobile
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter mobile number"
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            background: null
                                        }
                                    }
                                }

                                /* ===== Email ===== */
                                Column {
                                    spacing: 5
                                    width: parent.width

                                    Text { text: "Email"; font.bold: true }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        radius: 8
                                        border.width: feed_email.activeFocus ? 2 : 1
                                        border.color: feed_email.activeFocus ? app_color : "#dcdde1"

                                        TextField {
                                            id: feed_email
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter your email"
                                            inputMethodHints: Qt.ImhEmailCharactersOnly
                                            background: null
                                        }
                                    }
                                }

                                /* ===== Feedback ===== */
                                Column {
                                    spacing: 5
                                    width: parent.width

                                    Text { text: "Feedback"; font.bold: true }

                                    Rectangle {
                                        width: parent.width
                                        height: 100
                                        radius: 8
                                        border.width: feedbackArea.activeFocus ? 2 : 1
                                        border.color: feedbackArea.activeFocus ? app_color : "#dcdde1"

                                        TextArea {
                                            id: feedbackArea
                                            anchors.fill: parent
                                            anchors.margins: 5
                                            placeholderText: "Enter your feedback here..."
                                            wrapMode: TextArea.Wrap
                                            background: null
                                        }
                                    }
                                }

                                /* ===== Button ===== */
                                Button {
                                    text: "Send"
                                    width: parent.width * 0.3
                                    height: 40
                                    anchors.horizontalCenter: parent.horizontalCenter

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

                                    onClicked: {

                                        if (feedbackArea.text === "") {
                                            mainWindow.showToastMessage("Enter your valuable feedback");
                                            return;
                                        }

                                        MapGlobals.insertFeedback(
                                                    userName,
                                                    feed_mobile.text,
                                                    feed_email.text,
                                                    feedbackArea.text,
                                                    function(ok) {
                                                        if (ok) {
                                                            mainWindow.showToastMessage("Feedback sent successfully!");
                                                            currentView = "profile";
                                                        } else {
                                                            mainWindow.showToastMessage("Failed to send feedback");
                                                        }
                                                    }
                                                    );
                                    }
                                }

                                Item { height: 10 }
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
                    height: parent.height * 0.15
                    color: app_color//"#1b1c3e"

                    QGCColoredImage {
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        width: 25; height: 25
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: currentView = "profile"
                        }
                    }

                    Row {
                        spacing: 8
                        anchors.centerIn: parent

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/report.svg"
                            width: 25; height: 25
                            color: "white"
                        }

                        Text {
                            text: "Report"
                            font.bold: true
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: "white"
                        }
                    }
                }

                /* ================= CONTENT ================= */
                Item {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10

                    /* ===== LEFT CARD ===== */
                    Rectangle {
                        id: reportLeft
                        width: parent.width * 0.4
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        radius: 5
                        border.color: "#e0e0e0"
                        color: "white"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 10

                            Item {
                                width: 150; height: 150
                                anchors.horizontalCenter: parent.horizontalCenter

                                LottieAnimation {
                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/report_1.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.5
                                }
                            }

                            // Text {
                            //     text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                            //     wrapMode: Text.WordWrap
                            //     horizontalAlignment: Text.AlignHCenter
                            //     color: "black"
                            //     width: parent.width - 40
                            // }
                        }
                    }

                    /* ===== RIGHT CARD ===== */
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: reportLeft.right
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        radius: 5
                        border.color: "#e0e0e0"
                        color: "white"

                        /* Wrapper instead of Column */
                        Item {
                            anchors.fill: parent
                            anchors.margins: 8

                            /* ===== TABLE HEADER ===== */
                            Rectangle {
                                id: tableHeader
                                width: parent.width
                                height: 40
                                radius: 6
                                color: "#f8f9fa"

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 20
                                    spacing: 15

                                    Text {
                                        text: "Date"
                                        width: parent.width * 0.3
                                        font.bold: true
                                    }
                                    Text {
                                        text: "Start Time"
                                        width: parent.width * 0.3
                                        font.bold: true
                                    }
                                    Text {
                                        text: "End Time"
                                        width: parent.width * 0.3
                                        font.bold: true
                                    }
                                }
                            }

                            /* ===== LIST AREA ===== */
                            ScrollView {
                                anchors.top: tableHeader.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 6
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                ListView {
                                    id: listView
                                    width: parent.width
                                    model: sessionModel
                                    spacing: 6

                                    delegate: Rectangle {
                                        width: listView.width
                                        height: 40
                                        radius: 6
                                        color: index % 2 ? "#f8f9fa" : "#ffffff"

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: 20
                                            spacing: 15

                                            Text { text: model.date || "NA"; width: parent.width * 0.3 }
                                            Text { text: model.start_time || "NA"; width: parent.width * 0.3 }
                                            Text { text: model.end_time || "NA"; width: parent.width * 0.3 }
                                        }
                                    }

                                    /* Empty State */
                                    Label {
                                        anchors.centerIn: parent
                                        text: "No sessions recorded yet"
                                        visible: listView.count === 0
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
                    height: parent.height * 0.15
                    color: app_color//"#1b1c3e"

                    QGCColoredImage {
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        width: 25
                        height: 25
                        color: "white"
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentView = "profile"
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/select_drone_type_black.svg"
                            width: 25
                            height: 25
                            color: "white"
                        }

                        Text {
                            text: "Select Application"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.bold: true
                            color: "white"
                        }
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
                        { label: "Camera", image: "/qmlimages/NewImages/cameradrone.svg" },
                        { label: "Agri", image: "/qmlimages/NewImages/agri.png" },
                        { label: "Mapping",image: "/qmlimages/NewImages/survey.png" }
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
                            id : grid
                            columns: 3
                            spacing: 20
                            width: parent.width
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: contentArea.buttonModel

                                Item {
                                    width: (grid.width - (grid.spacing * (grid.columns - 1))) / grid.columns

                                    height: contentColumn.implicitHeight + 40

                                    // ----- SHADOW SOURCE -----
                                    Rectangle {
                                        id: shadowSource
                                        anchors.fill: card
                                        radius: 8
                                        color: "white"
                                        visible: false
                                    }

                                    // ----- REAL ELEVATION -----
                                    MultiEffect {
                                        anchors.fill: shadowSource
                                        source: shadowSource
                                        shadowEnabled: true

                                        shadowHorizontalOffset: 0
                                        shadowVerticalOffset: dp(0.5) //contentArea.selectedIndex === index ? dp(2) : dp(1)
                                        shadowBlur: 1.5 //contentArea.selectedIndex === index ? 0.8 : 0.5
                                        shadowColor: "#40000000"
                                    }

                                    // ----- CARD -----
                                    Button {
                                        id: card
                                        anchors.fill: parent
                                        padding: 0

                                        background: Rectangle {
                                            radius: 8
                                            color: "white"
                                            border.width: contentArea.selectedIndex === index
                                                          ? 2
                                                          : 1
                                            border.color: contentArea.selectedIndex === index
                                                          ? app_color
                                                          : "#D3D3D3"
                                        }

                                        contentItem: Item   {
                                            anchors.fill: parent

                                            Column {
                                                id : contentColumn
                                                anchors.centerIn: parent
                                                spacing: 12

                                                Image {
                                                    source: modelData.image
                                                    width: 56
                                                    height: 56
                                                    fillMode: Image.PreserveAspectFit
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }

                                                Text {
                                                    text: modelData.label
                                                    color: "black"
                                                    font.bold: true
                                                    font.pointSize: ScreenTools.defaultFontPointSize
                                                    horizontalAlignment: Text.AlignHCenter
                                                    width: parent.width
                                                    wrapMode: Text.WordWrap
                                                }
                                            }
                                        }

                                        QGCColoredImage {
                                            visible: contentArea.selectedIndex === index
                                            source: "qrc:/qmlimages/check.svg"
                                            width: 20
                                            height: 20
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 10
                                            color: app_color
                                        }

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

                                mainWindow.openNewScreen();
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





