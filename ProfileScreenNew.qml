import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.LocalStorage 2.0

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
    property string currentView: "profile" // options: main, accountUpdate, userGuide, record, reports, feedback, settings

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


    StackLayout {
        anchors.fill: parent

        currentIndex: {
            if (currentView === "profile") return 0
            else if (currentView === "accountUpdate") return 1
            else if (currentView === "privacy_policy") return 2
            else if (currentView === "terms&conditions") return 3
            else if (currentView === "feedback") return 4
            else if (currentView === "reports") return 5
            else if (currentView === "drone") return 6
            else return 0
        }

        //Profile Screen
        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Profile screen header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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
                            source: "/qmlimages/NewImages/profile.png"
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

                                // Distance Covered
                                // RowLayout {
                                //     spacing: 10
                                //     QGCColoredImage {
                                //         source: "qrc:/InstrumentValueIcons/travel-walk.svg"
                                //         width: 20
                                //         height: 20
                                //         color: "#2c3e50"
                                //     }
                                //     Text {
                                //         text: "Distance Covered"
                                //         font.pointSize: ScreenTools.smallFontPointSize
                                //         color: "#666666"
                                //         Layout.fillWidth: true
                                //     }
                                //     Text {
                                //         text: "256 km"
                                //         font.pointSize: ScreenTools.smallFontPointSize
                                //         font.bold: true
                                //         color: "#2c3e50"
                                //     }
                                // }
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

        // Account Update Screen
        Rectangle {
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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

                                    currentView = "profile"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

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
                            color: "white"
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Account Update content area
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.bottomMargin: 10
                    Layout.topMargin: 10
                    spacing: 10

                    // First Card - Profile Info & Stats
                    Rectangle {
                        Layout.preferredWidth: parent.width * 0.4
                        Layout.fillHeight: true
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
                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/droneManFly.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.3
                                    onStatusChanged: console.log("Lottie Status:", status)
                                }
                            }

                            Text {
                                text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                                wrapMode: Text.WordWrap
                                font.pointSize: ScreenTools.defaultFontPointSize
                                color: "black" // Changed from white to black for visibility
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width - 40 // Add some margin
                            }
                        }
                    }

                    // Second Card - Form
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            Item {
                                width: parent.width
                                implicitHeight: formColumn.implicitHeight + 15 // Add padding

                                Column {
                                    id: formColumn
                                    width: parent.width
                                    spacing: 10
                                    anchors.centerIn: parent

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
                                            border.color: namefield.activeFocus ? "#3498db" : "#dcdde1"

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
                                            border.color: _username.activeFocus ? "#3498db" : "#dcdde1"

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
                                            border.color: emailField.activeFocus ? "#3498db" : "#dcdde1"

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
                                            border.color: mobileField.activeFocus ? "#3498db" : "#dcdde1"

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
                                                    border.color: "#1b1c3e"
                                                    color: rpcCompletedStatus === 1 ? "#1b1c3e" : "transparent"

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: rpcCompletedStatus = 1
                                                    }
                                                }

                                                Text {
                                                    text: "Yes"
                                                    font.pointSize: ScreenTools.defaultFontPointSize
                                                    color: "#333333"
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
                                                    border.color: "#1b1c3e"
                                                    color: rpcCompletedStatus === 0 ? "#1b1c3e" : "transparent"

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        onClicked: rpcCompletedStatus = 0
                                                    }
                                                }

                                                Text {
                                                    text: "No"
                                                    font.pointSize: ScreenTools.defaultFontPointSize
                                                    color: "#333333"
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
                                            color: parent.pressed ? "#218838" : "#28a745"
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
                        }
                    } //SecondCaed

                }
            }
        }

        // Privacy Policy
        Rectangle {
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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

                                    currentView = "profile"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QGCColoredImage {
                            id: privacypolicy
                            source: "/qmlimages/NewImages/privacy_policy_black.svg"
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }

                        Text {
                            text: "Privacy Policy"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: "white"
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }
            }

        }

        // Terms & Conditions
        Rectangle {
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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
            }

        }

        // Feedback Screen
        Rectangle {
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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

                                    currentView = "profile"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QGCColoredImage {
                            id: feedback
                            source: "/qmlimages/NewImages/feedback.svg"
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }

                        Text {
                            text: "Feedback"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: "white"
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.bottomMargin: 10
                    Layout.topMargin: 10
                    spacing: 10

                    // First Card - Profile Info & Stats
                    Rectangle {
                        Layout.preferredWidth: parent.width * 0.4
                        Layout.fillHeight: true
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

                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/droneManFly.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.3
                                    onStatusChanged: console.log("Lottie Status:", status)
                                }
                            }

                            Text {
                                text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                                wrapMode: Text.WordWrap
                                font.pointSize: ScreenTools.defaultFontPointSize
                                color: "black" // Changed from white to black for visibility
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width - 40 // Add some margin
                            }
                        }
                    }

                    // Second Card - Form
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            contentWidth: availableWidth
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            Item {
                                width: parent.width
                                implicitHeight: _formColumn.implicitHeight + 15 // Add padding

                                Column {
                                    id: _formColumn
                                    width: parent.width
                                    spacing: 10
                                    anchors.centerIn: parent

                                    //Mobile Number
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
                                            border.width: feed_mobile.activeFocus ? 2 : 1
                                            border.color: feed_mobile.activeFocus ? "#3498db" : "#dcdde1"

                                            TextField {
                                                id: feed_mobile
                                                anchors.fill: parent
                                                anchors.margins: 5
                                                placeholderText: "Enter mobile number"
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#2c3e50"
                                                background: null
                                                selectByMouse: true
                                                verticalAlignment: TextInput.AlignVCenter
                                                inputMethodHints: Qt.ImhDigitsOnly

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
                                            border.width: feed_email.activeFocus ? 2 : 1
                                            border.color: feed_email.activeFocus ? "#3498db" : "#dcdde1"

                                            TextField {
                                                id: feed_email
                                                anchors.fill: parent
                                                anchors.margins: 5
                                                placeholderText: "Enter your email"
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#2c3e50"
                                                background: null
                                                selectByMouse: true
                                                verticalAlignment: TextInput.AlignVCenter
                                                inputMethodHints: Qt.ImhEmailCharactersOnly

                                            }
                                        }
                                    }

                                    // Feedback Field
                                    Column {
                                        width: parent.width
                                        spacing: 5

                                        Text {
                                            text: "Feedback"
                                            font.pointSize: ScreenTools.defaultFontPointSize
                                            font.bold: true
                                            color: "#2c3e50"
                                            leftPadding: 5
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 100
                                            radius: 8
                                            color: "white"
                                            border.width: feedbackArea.activeFocus ? 2 : 1
                                            border.color: feedbackArea.activeFocus ? "#3498db" : "#dcdde1"

                                            TextArea {
                                                id: feedbackArea
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                    margins: 5
                                                }
                                                placeholderText: "Enter your feedback here..."
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#2c3e50"
                                                background: null
                                                selectByMouse: true
                                                wrapMode: TextArea.Wrap
                                                verticalAlignment: TextEdit.AlignTop
                                            }
                                        }

                                    }


                                    // Update Button
                                    Button {
                                        text: "Send"
                                        width: parent.width * 0.3
                                        height: 40
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        onClicked: {

                                            if (feedbackArea.text === "") {
                                                mainWindow.showToastMessage("Enter your valuable feedback");
                                                return;
                                            }

                                            var mobile = feed_mobile.text.trim();
                                            var email = feed_email.text.trim();
                                            var comments = feedbackArea.text.trim();


                                            MapGlobals.insertFeedback(
                                                        userName, // assuming userName is available in ProfileScreen
                                                        mobile,
                                                        email,
                                                        comments,
                                                        function(result) {
                                                            if (result) {

                                                                mainWindow.showToastMessage("Feedback sent successfully!");

                                                                currentView = "profile";

                                                                feed_mobile.text = "";
                                                                feed_email.text = "";
                                                                feedbackArea.text = "";

                                                            } else {
                                                                console.log(" Failed to send feedback");
                                                                mainWindow.showToastMessage("Failed to send feedback. Please try again.");
                                                            }
                                                        }
                                                        );
                                        }

                                        background: Rectangle {
                                            radius: 5
                                            color: parent.pressed ? "#218838" : "#28a745"
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

                        }
                    } //SecondCaed

                }
            }

        }

        // Reports Screen
        Rectangle {
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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

                                    currentView = "profile"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QGCColoredImage {
                            id: sessions
                            source: "/qmlimages/NewImages/report.svg"
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }

                        Text {
                            text: "Report"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: "white"
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.bottomMargin: 10
                    Layout.topMargin: 10
                    spacing: 10

                    // First Card - Profile Info & Stats
                    Rectangle {
                        Layout.preferredWidth: parent.width * 0.4
                        Layout.fillHeight: true
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

                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/droneManFly.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.3
                                    onStatusChanged: console.log("Lottie Status:", status)
                                }
                            }

                            Text {
                                text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                                wrapMode: Text.WordWrap
                                font.pointSize: ScreenTools.defaultFontPointSize
                                color: "black" // Changed from white to black for visibility
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width - 40 // Add some margin
                            }
                        }
                    }

                    // Second Card - Form
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 8
                        border.color: "#e0e0e0"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 0

                            // Inner Header
                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                color: "#f8f9fa"
                                radius: 8

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 15

                                    Text {
                                        text: "Date"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        width: parent.width * 0.3
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Start Time"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        width: parent.width * 0.3
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "End Time"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: true
                                        color: "#2c3e50"
                                        width: parent.width * 0.3
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // List Content
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentWidth: availableWidth
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                ListView {
                                    id: listView
                                    width: parent.width
                                    model: sessionModel
                                    spacing: 8
                                    boundsBehavior: Flickable.StopAtBounds

                                    delegate: Rectangle {
                                        width: listView.width
                                        height: 40
                                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                                        radius: 6

                                        Row {
                                            anchors.fill: parent
                                            anchors.leftMargin: 20
                                            anchors.rightMargin: 20
                                            spacing: 15

                                            // Date Column
                                            Text {
                                                text: model.date || "NA"
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#2c3e50"
                                                width: parent.width * 0.3
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                            }

                                            // Start Time Column

                                            // Text {
                                            //     text: model.start_time || "NA"
                                            //     font.pointSize: ScreenTools.defaultFontPointSize
                                            //     color: "#2c3e50"
                                            //     width: parent.width * 0.3
                                            //     anchors.verticalCenter: parent.verticalCenter
                                            //     elide: Text.ElideRight
                                            // }

                                            Text {
                                                text: {
                                                    var parts = model.start_time.split(":")
                                                    if (parts.length < 2) return model.start_time
                                                    var hour = parseInt(parts[0])
                                                    var minute = parts[1]
                                                    var second = parts[2]
                                                    var ampm = hour >= 12 ? "PM" : "AM"
                                                    hour = hour % 12
                                                    if (hour === 0) hour = 12
                                                    return hour + ":" + minute + ":" + second + " " + ampm
                                                }
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#2c3e50"
                                                width: parent.width * 0.3
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                            }


                                            // End Time Column

                                            // Text {
                                            //     text: model.end_time || "NA"
                                            //     font.pointSize: ScreenTools.defaultFontPointSize
                                            //     color: "#2c3e50"
                                            //     width: parent.width * 0.3
                                            //     anchors.verticalCenter: parent.verticalCenter
                                            //     elide: Text.ElideRight
                                            // }

                                            Text {
                                                text: {
                                                    var parts = model.end_time.split(":")
                                                    if (parts.length < 2) return model.start_time
                                                    var hour = parseInt(parts[0])
                                                    var minute = parts[1]
                                                    var second = parts[2]
                                                    var ampm = hour >= 12 ? "PM" : "AM"
                                                    hour = hour % 12
                                                    if (hour === 0) hour = 12
                                                    return hour + ":" + minute + ":" + second + " " + ampm
                                                }
                                                font.pointSize: ScreenTools.defaultFontPointSize
                                                color: "#2c3e50"
                                                width: parent.width * 0.3
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                            }

                                        }

                                        // Separator line
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 1
                                            color: "#e0e0e0"
                                            opacity: 0.5
                                        }
                                    }

                                    // Empty state
                                    Label {
                                        anchors.centerIn: parent
                                        text: "No sessions recorded yet"
                                        font.pixelSize: 16
                                        color: "#7f8c8d"
                                        visible: listView.count === 0
                                    }
                                }
                            }
                        }
                    }

                }
            }

        }

        // Select Drone Screen
        Rectangle {
            color: "white"

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: "#1b1c3e"

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

                                    currentView = "profile"
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        QGCColoredImage {
                            id: drone
                            source: "/qmlimages/NewImages/select_drone_type_black.svg"
                            width: 25
                            height: 25
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                        }

                        Text {
                            text: "Select Application"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: "white"
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                // Select Drone Screen content area
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.bottomMargin: 10
                    Layout.topMargin: 10
                    spacing: 10

                    // First Card - Lottie file
                    Rectangle {
                        Layout.preferredWidth: parent.width * 0.4
                        Layout.fillHeight: true
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            anchors.margins: 20
                            spacing: 10
                            width: parent.width - 40

                            Item {
                                width: 150
                                height: 150
                                anchors.horizontalCenter: parent.horizontalCenter

                                LottieAnimation {
                                    id: droneAnim1
                                    anchors.centerIn: parent
                                    source: "qrc:/qmlimages/NewImages/droneManFly.json"
                                    autoPlay: true
                                    loops: Animation.Infinite
                                    scale: 0.3
                                    onStatusChanged: console.log("Lottie Status:", status)
                                }
                            }

                            Text {
                                text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                                wrapMode: Text.WordWrap
                                font.pointSize: ScreenTools.defaultFontPointSize
                                color: "black" // Changed from white to black for visibility
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width - 40 // Add some margin
                            }
                        }
                    }

                    // Second Card - Drone Categories
                    Rectangle {
                        id: root // <-- IMPORTANT
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"
                        radius: 5
                        border.color: "#e0e0e0"
                        border.width: 1

                        property int selectedIndex: -1

                        property var buttonModel: [
                            { label: "Camera", color: "#1b2a49", border: "#3b6ea5", image: "/qmlimages/NewImages/cameradrone.svg" },
                            { label: "Agri", color: "#1c3f2b", border: "#4CAF50", image: "/qmlimages/NewImages/agri.png" },
                            { label: "Mapping", color: "#1b2a49", border: "#3b6ea5", image: "/qmlimages/NewImages/survey.png" },
                            { label: "VTOL", color: "#2e1437", border: "#9b59b6", image: "/qmlimages/NewImages/vtol.png" }
                        ]

                        onVisibleChanged: if (visible) {
                            var saved = QGroundControl.loadGlobalSetting("loadpage", "loadpage").trim()

                            if (saved === "loadpage") {
                                selectedIndex = -1
                            } else {
                                for (var i = 0; i < buttonModel.length; i++) {
                                    if (buttonModel[i].label === saved) {
                                        selectedIndex = i
                                        break
                                    }
                                }
                            }
                        }


                        Column {
                            anchors.centerIn: parent
                            spacing: 20
                            width: parent.width * 0.95
                            height: parent.height * 0.95

                            GridLayout {
                                id: buttonGrid
                                anchors.horizontalCenter: parent.horizontalCenter
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 20
                                width: parent.width
                                height: parent.height

                                Repeater {
                                    model: root.buttonModel
                                    property int key: root.selectedIndex
                                    delegate: Button {
                                        Layout.preferredWidth: buttonGrid.width * 0.45
                                        Layout.preferredHeight: buttonGrid.height * 0.4

                                        background: Rectangle {
                                            id: bg
                                            color: modelData.color
                                            radius: 12
                                            border.width: width * 0.02
                                            border.color: root.selectedIndex === index ? "yellow" : modelData.border

                                            anchors.fill: parent
                                        }

                                        contentItem: Item {
                                            anchors.fill: parent

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: iconBaseSize * 0.2

                                                Image {
                                                    source: modelData.image
                                                    width: iconBaseSize * 1.5
                                                    height: iconBaseSize * 1.5
                                                    fillMode: Image.PreserveAspectFit
                                                    anchors.horizontalCenter: parent.horizontalCenter

                                                }

                                                Text {
                                                    text: modelData.label
                                                    color: "white"
                                                    font.pointSize: ScreenTools.defaultFontPointSize
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                            }
                                        }


                                        Item {
                                            anchors.fill: parent

                                            QGCColoredImage {
                                                visible: root.selectedIndex !== -1 && root.selectedIndex === index
                                                source: "qrc:/qmlimages/check.svg"
                                                width: iconBaseSize * 0.5
                                                height: iconBaseSize * 0.5
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.topMargin: 8
                                                anchors.rightMargin: 8
                                                color: "green"

                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    width: iconBaseSize * 0.6
                                                    height: iconBaseSize * 0.6
                                                    radius: 14
                                                    color: "white"
                                                    border.color: "green"
                                                    border.width: 2
                                                    z: -1
                                                }
                                            }
                                        }

                                        onClicked: {
                                            root.selectedIndex = index  // <-- FIXED
                                            console.log("Selected:", modelData.label)
                                            QGroundControl.saveGlobalSetting("loadpage", modelData.label)
                                            mainWindow.showToastMessage(modelData.label + " Selected")
                                            currentView = "profile"
                                        }
                                    }
                                }
                            }
                        }
                    }

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





