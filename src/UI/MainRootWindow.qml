/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

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


import QGroundControl.UTMSP
import QGroundControl.Palette 1.0

import MapGlobals 1.0

import QtQuick.LocalStorage 2.0

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.folderlistmodel 2.1
import Qt.labs.platform 1.1 as Platform

import "qrc:/qml/SettingsPanel"


/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    minimumWidth:   ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true
    property var    guidedController
    property var    guidedValueSlider

    property var    mapPolygon :                object.surveyAreaPolygon


    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionChecked:      optionCheckBox.checked

    property var _appSettings: QGroundControl.settingsManager.appSettings

    QGCCheckBox {
        id:                 optionCheckBox
        Layout.alignment:   Qt.AlignHCenter
        text:               ""
        visible:            text !== ""
    }

    property bool   _utmspSendActTrigger
    property bool   _utmspStartTelemetry
    property var someParameter
    property string planType: "Default"
    property string plan: "Default"
    property string takeoff: "takeoff"
    property bool longPressTriggered: false
    property real progressValue: 0.0
    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property var    _unitsConversion:           QGroundControl.unitsConversion
    property var _guidedController: globals.guidedControllerFlyView
    property int    actionTakeoff
    signal loadPlanFile()
    // Reference the existing FlightMap instance (defined in another QML file)
    //property alias mainFlightMap: mainFlightMap


    property string edit:""
    property string sessionDate: ""
    property string sessionStart: ""
    property string sessionEnd: ""
    property bool sessionSaved: false
    signal newSessionAdded()


    Connections {
        target: QGroundControl.multiVehicleManager

        onActiveVehicleChanged: {
            handleVehicleConnectionChange();
            updateTabModel();
        }

        function handleVehicleConnectionChange() {
            let now = new Date();
            let timeString = now.toLocaleTimeString(Qt.locale(), "HH:mm:ss");
            let dateString = now.toLocaleDateString(Qt.locale(), "dd-MM-yyyy");

            if (activeVehicle) {
                sessionDate = dateString;
                sessionStart = timeString;
                console.log("Drone Connected at:", sessionStart, "on", sessionDate);
            } else {
                if (sessionStart !== "") { // Only save if we have a start time
                    sessionEnd = timeString;
                    console.log("Drone Disconnected at:", sessionEnd,"on", sessionDate);
                    saveDroneSession(sessionDate, sessionStart, sessionEnd);
                    // Reset for next session
                    sessionStart = "";
                    sessionEnd = "";
                }
            }
        }

        function updateTabModel() {
            tabModel.updateSettingsTab();
        }
    }

    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens
        if (!ScreenTools.isFakeMobile && (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120)) {
            mainWindow.showFullScreen()
        } else {
            width   = ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(150 * Screen.pixelDensity, Screen.height)
        }

        //Initialize the Database and Create Tables
        initDB()

        profilelogin()
        profile()

        //Print all Session Table Datas.Just For Reference
        printSessionTable()

        if(_appSettings.screen==="Plan"){
            plan="Plan"
            console.log("NextScreen loaded with planType:", planType)
        }else{
            plan="Start"
            console.log("NextScreen loaded with planType: Start")

        }

        // Start the sequence of first run prompt(s)
        //firstRunPromptManager.nextPrompt()
    }

    /* QtObject {
        // First time showing dialogs codes
        id: firstRunPromptManager

        property var currentDialog:     null
       // property var rgPromptIds:       QGroundControl.corePlugin.firstRunPromptsToShow()
        property var rgPromptIds:       null
        property int nextPromptIdIndex: 0

        function clearNextPromptSignal() {
            if (currentDialog) {
                currentDialog.closed.disconnect(nextPrompt)
            }
        }

        function nextPrompt() {
            if(rgPromptIds != null){
                if (nextPromptIdIndex < rgPromptIds.length) {
                    var component = Qt.createComponent(QGroundControl.corePlugin.firstRunPromptResource(rgPromptIds[nextPromptIdIndex]));
                    currentDialog = component.createObject(mainWindow)
                    currentDialog.closed.connect(nextPrompt)
                    currentDialog.open()
                    nextPromptIdIndex++
                } else {
                    currentDialog = null
                    showPreFlightChecklistIfNeeded()
                }
            }


        }
    }*/

    readonly property real      _topBottomMargins:          ScreenTools.defaultFontPixelHeight * 0.5

    //-------------------------------------------------------------------------
    //-- Global Scope Variables

    QtObject {
        id: globals

        readonly property var       activeVehicle:                  QGroundControl.multiVehicleManager.activeVehicle
        readonly property real      defaultTextHeight:              ScreenTools.defaultFontPixelHeight
        readonly property real      defaultTextWidth:               ScreenTools.defaultFontPixelWidth
        readonly property var       planMasterControllerFlyView:    flyView.planController
        readonly property var       guidedControllerFlyView:        flyView.guidedController

        property bool               validationError:                false   // There is a FactTextField somewhere with a validation error

        // Property to manage RemoteID quick acces to settings page
        property bool               commingFromRIDIndicator:        false

    }

    /// Default color palette used throughout the UI
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    //-------------------------------------------------------------------------
    //-- Actions

    signal armVehicleRequest
    signal forceArmVehicleRequest
    signal disarmVehicleRequest
    signal vtolTransitionToFwdFlightRequest
    signal vtolTransitionToMRFlightRequest
    signal showPreFlightChecklistIfNeeded

    //-------------------------------------------------------------------------
    //-- Global Scope Functions

    function planmap() {
        planView.newmap()
    }

    function newscreendata() {
        if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Camera"){
            newscreen.camera()
        }else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
            newscreen.agri()
        }else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
            newscreen.mapping()
        }else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="VTOL"){
            newscreen.vtol()
        }
    }

    function filename() {
        filename.tracemode()
    }

    /// @return true: View switches are not currently allowed
    function preventViewSwitch() {
        return globals.validationError
    }

    function takeoff(){
        rtlbtn.visible=true
        takeoffbtn.visible=false
    }

    function land(){
        rtlbtn.visible=false
        takeoffbtn.visible=true
    }

    function newscreen() {
        planbtn.visible =false
        listbtn.visible = false
        takeoffbtn.visible = false
        rtlbtn.visible = false
        flyView.visible = false
        planView.visible = false

        newscreen.visible = true
        //modebtn.visible = false
        modebtn1.visible = false
        mainrootIcons.visible = false

        waypointbtn.visible = false
        //eraserbtn.visible = false
    }

    function showPlanView() {
        planbtn.visible =false
        listbtn.visible = false
        takeoffbtn.visible = false
        rtlbtn.visible = false
        //modebtn.visible = false
        flyView.visible = false
        planView.visible = true
        modebtn1.visible = false
        mainrootIcons.visible = false

        waypointbtn.visible = false
        //eraserbtn.visible = false
    }

    function cameraView() {
        planbtn.visible = false
        listbtn.visible = false
        takeoffbtn.visible = true
        rtlbtn.visible = false
        //modebtn.visible = false
        flyView.visible = true
        planView.visible = false
        modebtn1.visible = false
        mainrootIcons.visible = false
        newscreen.visible = false

        waypointbtn.visible = true
        //eraserbtn.visible = true

    }

    function showFlyView() {
        waypointbtn.visible = false
        camerabtn.visible = false
        //photoVideoControl.visible = false
        MapGlobals.save = "save1"
        planbtn.visible = true
        listbtn.visible = true
        takeoffbtn.visible = true
        //modebtn.visible = activeVehicle?false:true
        flyView.visible = true
        planView.visible = false
        newscreen.visible = false
        mainrootIcons.visible=true
        modebtn1.visible = activeVehicle ? true : false
        plan="Plan"
        MapGlobals.edit = "edit1"
        _appSettings.username="";
        //eraserbtn.visible = true
        dialog.mappingbtn.visible= false
        dialog.mappingcirclebtn.visible= false
        dialog.agribtn.visible= true
        dialog.agrigpsbtn.visible= true
    }

    function showMapping() {
        waypointbtn.visible = true
        camerabtn.visible = false
        //photoVideoControl.visible = false
        MapGlobals.save = "save1"
        planbtn.visible = true
        listbtn.visible = true
        takeoffbtn.visible = true
        //modebtn.visible = activeVehicle?false:true
        flyView.visible = true
        planView.visible = false
        newscreen.visible = false
        mainrootIcons.visible=true
        modebtn1.visible = activeVehicle ? true : false
        plan="Plan"
        MapGlobals.edit = "edit1"
        _appSettings.username="";
        //eraserbtn.visible = true
        dialog.mappingbtn.visible= true
        dialog.mappingcirclebtn.visible= true
        dialog.agribtn.visible= false
        dialog.agrigpsbtn.visible= false
    }

    function closefile(){
        filename.dailogclose()
    }

    function showFlyView1() {
        MapGlobals.save = "save1"
        planbtn.visible = true
        listbtn.visible = true
        takeoffbtn.visible = true
        //modebtn.visible = activeVehicle?false:true
        flyView.visible = true
        planView.visible = false
        newscreen.visible = false
        modebtn1.visible = activeVehicle ? true : false
        plan="Start"
        MapGlobals.edit = "edit1"

        waypointbtn.visible = false
        //eraserbtn.visible = true
    }

    function showTool(toolTitle, toolSource, toolIcon) {
        toolDrawer.backIcon     = flyView.visible ? "/qmlimages/PaperPlane.svg" : "/qmlimages/Plan.svg"
        toolDrawer.toolTitle    = toolTitle
        toolDrawer.toolSource   = toolSource
        toolDrawer.toolIcon     = toolIcon
        toolDrawer.visible      = true
    }

    function showAnalyzeTool() {
        showTool(qsTr("Analyze Tools"), "AnalyzeView.qml", "/qmlimages/Analyze.svg")
    }

    function showVehicleSetupTool(setupPage = "") {
        showTool(qsTr("Vehicle Setup"), "SetupView.qml", "/qmlimages/Gears.svg")
        if (setupPage !== "") {
            toolDrawerLoader.item.showNamedComponentPanel(setupPage)
        }
    }

    function showSettingsTool(settingsPage = "") {
        showTool(qsTr("Application Settings"), "AppSettings.qml", "/res/QGCLogoWhite")
        if (settingsPage !== "") {
            toolDrawerLoader.item.showSettingsPage(settingsPage)
        }
    }

    //-------------------------------------------------------------------------
    //-- Global simple message dialog

    function showMessageDialog(dialogTitle, dialogText, buttons = Dialog.Ok, acceptFunction = null) {
        console.log("dialogTitle : ",dialogTitle)
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction }).open()
    }

    // This variant is only meant to be called by QGCApplication
    function _showMessageDialog(dialogTitle, dialogText) {

        showMessageDialog(dialogTitle, dialogText)
    }

    function showToast(text) {
        sideDrawer.close()
        toastContainer.showToast(text)
    }

    function showToastMessage(text) {
        toastContainer.showToast(text)
    }

    function profileScreen1(comesFrom) {
        console.log("profileScreen1==========")
        profileScreen.visible = comesFrom
        newscreen.visible = !comesFrom
    }

    Component {
        id: simpleMessageDialogComponent

        QGCSimpleMessageDialog {
        }
    }

    ListModel {
        id: userModel
    }

    Dialog {
        id: userDialog
        modal: true
        width: parent.width * 0.9
        height: parent.height * 0.6
        standardButtons: Dialog.Ok

        contentItem: ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "User List"
                font.bold: true
                font.pointSize: 16
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            ListView {
                id: userList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: userModel
                clip: true

                delegate: Rectangle {
                    width: userList.width
                    height: 50
                    color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        padding: 10

                        Text {
                            text: id + " " + displayname
                            font.bold: true
                            color: "black"
                        }

                        Text {
                            text: "(" + username + " - " + email + ")"
                            color: "black"
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: dynamicCalDialog
        modal: true
        anchors.centerIn: parent
        width: parent.width * 0.85
        height: parent.height * 0.9
        clip: true

        property string dialogTitleText: ""

        closePolicy: Popup.NoAutoClose
        padding: 0   // no global padding

        background: Rectangle {
            radius: 14
            color: "white"
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // Title bar (full width, rounded top only)
            Rectangle {
                width: parent.width
                height: titleLabel.implicitHeight + 14
                color: "#7F56D9"
                radius: 14
                antialiasing: true
                clip: true

                // mask lower corners → flat against content
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 14
                    color: "#7F56D9"
                    radius: 0
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 0

                    QGCLabel {
                        id: titleLabel
                        text: dynamicCalDialog.dialogTitleText
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: "white"
                    }

                    MouseArea {
                        Layout.alignment: Qt.AlignRight
                        width: 30
                        height: 30
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: dynamicCalDialog.close()

                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            color: "white"
                            font.pixelSize: 18
                        }
                    }
                }
            }

            // Content area with padding
            Item {
                width: parent.width
                height: parent.height - (titleLabel.implicitHeight + 14)
                anchors.margins: 0

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 14
                    color: "transparent"

                    Loader {
                        id: dialogLoader
                        anchors.fill: parent
                    }
                }
            }
        }

        onClosed: dialogLoader.source = ""
    }


    // Starting of DB code
    function getDatabase() {
        return LocalStorage.openDatabaseSync("QGCUserDB", "1.0", "User DB", 1000000);
    }

    function initDB() {
        var db = getDatabase();
        db.transaction(function(tx) {
            try {

                // Users table - simplified
                tx.executeSql("CREATE TABLE IF NOT EXISTS users(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    displayname TEXT NOT NULL,
                    email TEXT UNIQUE NOT NULL,
                    password TEXT NOT NULL,
                    mobile_number TEXT,
                    rpc_completed INTEGER DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )");


                // Drone sessions table - simplified
                tx.executeSql("CREATE TABLE IF NOT EXISTS drone_sessions(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    date TEXT NOT NULL,
                    start_time TEXT NOT NULL,
                    end_time TEXT NOT NULL,
                    duration INTEGER
                )");


                //feedback table
                tx.executeSql("CREATE TABLE IF NOT EXISTS feedback (
                               id INTEGER PRIMARY KEY AUTOINCREMENT,
                               username TEXT,
                               mobile_number TEXT,
                               email TEXT,
                               comments TEXT
                           )");

                console.log("Database and tables created successfully");

            } catch (error) {
                console.error("Error creating database:", error);
            }
        });
    }

    // MainRootWindow.qml
    function insertFeedback(username, mobile_number, email, comments, callback) {
        var db = getDatabase();
        db.transaction(function(tx) {
            try {

                console.log("=== ALL FEEDBACK BEFORE INSERT ===");
                var beforeInsert = tx.executeSql("SELECT * FROM feedback ORDER BY id");
                printFeedbackTable(beforeInsert, "BEFORE INSERT");

                // Insert new feedback
                var rs = tx.executeSql(
                            "INSERT INTO feedback (username, mobile_number, email, comments) VALUES (?, ?, ?, ?)",
                            [username, mobile_number, email, comments]
                            );

                if (rs.rowsAffected > 0) {
                    console.log("Feedback inserted successfully");

                    // Print all data AFTER insert
                    console.log("=== ALL FEEDBACK AFTER INSERT ===");
                    var afterInsert = tx.executeSql("SELECT * FROM feedback ORDER BY id");
                    printFeedbackTable(afterInsert, "AFTER INSERT");

                    if (callback) {
                        callback(true);
                    }
                } else {
                    console.log("Feedback insertion failed");
                    if (callback) {
                        callback(false);
                    }
                }

            } catch (error) {
                console.error("Error inserting feedback:", error);
                if (callback) {
                    callback(false);
                }
            }
        });
    }

    // Just print the feedback table
    function printFeedbackTable(resultSet, label) {

        console.log("ID | Username | Mobile | Email | Comments");
        console.log("------------------------------------------");

        if (resultSet.rows.length === 0) {
            console.log("No feedback records found");
        } else {
            for (var i = 0; i < resultSet.rows.length; i++) {
                var feedback = resultSet.rows.item(i);
                // Truncate long comments for better readability
                var truncatedComments = feedback.comments.length > 30 ?
                            feedback.comments.substring(0, 30) + "..." :
                            feedback.comments;

                console.log(feedback.id + " | " +
                            (feedback.username || "NULL") + " | " +
                            (feedback.mobile_number || "NULL") + " | " +
                            (feedback.email || "NULL") + " | " +
                            truncatedComments);
            }
        }
        console.log("------------------------------------------");
    }

    //saveDroneSession
    function saveDroneSession(date, startTime, endTime) {
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                // Calculate duration in minutes
                var duration = calculateDuration(startTime, endTime);

                // Insert session with duration
                var rs = tx.executeSql(
                            "INSERT INTO drone_sessions(date, start_time, end_time, duration) VALUES(?, ?, ?, ?)",
                            [date, startTime, endTime, duration]
                            );

                if (rs.rowsAffected > 0) {
                    console.log("Session saved - ID:", rs.insertId,
                                "Date:", date,
                                "Start:", startTime,
                                "End:", endTime,
                                "Duration:", duration, "minutes");
                    sessionSaved = true;
                    newSessionAdded(); // Emit signal to notify other components
                }

            } catch (error) {
                console.error("Error saving drone session:", error);
            }
        });
    }

    // Just print the Session table
    function printSessionTable() {
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                var resultSet = tx.executeSql("SELECT * FROM drone_sessions ORDER BY id");

                console.log("ID | date | start_time | end_time | duration");
                console.log("------------------------------------------");

                if (resultSet.rows.length === 0) {
                    console.log("No Session records found");
                } else {
                    for (var i = 0; i < resultSet.rows.length; i++) {
                        var session = resultSet.rows.item(i);
                        console.log(
                                    session.id + " | " +
                                    (session.date || "NULL") + " | " +
                                    (session.start_time || "NULL") + " | " +
                                    (session.end_time || "NULL") + " | " +
                                    (session.duration || "NULL")
                                    );
                    }
                }

                console.log("------------------------------------------");

            } catch (error) {
                console.error("Error reading drone session:", error);
            }
        });
    }

    //calculate the duration from startsession to end session
    function calculateDuration(startTime, endTime) {
        try {
            // Parse times (format: "HH:mm:ss")
            var startParts = startTime.split(':');
            var endParts = endTime.split(':');

            var startTotalSeconds = parseInt(startParts[0]) * 3600 +
                    parseInt(startParts[1]) * 60 +
                    parseInt(startParts[2] || 0);

            var endTotalSeconds = parseInt(endParts[0]) * 3600 +
                    parseInt(endParts[1]) * 60 +
                    parseInt(endParts[2] || 0);

            var durationSeconds = endTotalSeconds - startTotalSeconds;

            if (durationSeconds < 0) {
                // Handle(session spans midnight)
                durationSeconds += 24 * 3600;
            }

            return Math.round(durationSeconds / 60); // Convert to minutes

        } catch (e) {
            console.error("Error calculating duration:", e);
            return 0;
        }
    }

    // JavaScript function to read from DB
    function loadUsersFromDB() {

        var db = getDatabase();
        userModel.clear();
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM users");
            console.log("inserted=========",rs)

            for (let i = 0; i < rs.rows.length; i++) {
                let row = rs.rows.item(i);
                console.log("inserted=========",row.username)
                userModel.append({
                                     id: row.id,
                                     username: row.username,
                                     displayname: row.displayname,
                                     email: row.email
                                 });
            }
            // if (rs.rows.length > 0) {
            //     console.log("Login Success");
            //     login.visible = false;
            //     mainWindow.newscreen();
            //     mainWindow.showToastMessage("Login Success");
            // } else {
            //     console.log("Invalid Credentials");
            //     mainWindow.showToastMessage("Invalid Credentials");
            // }
        });


        // var db = getDatabase();

        // // Clear model before loading new data
        // userModel.clear();

        // db.transaction(function(tx) {

        //     tx.executeSql("SELECT * FROM users", [], function(tx, results) {

        //     console.log("results==========",results.rows.length)
        //         for (let i = 0; i < results.rows.length; i++) {
        //             let row = results.rows.item(i);
        //             userModel.append({
        //                 id: row.id,
        //                 username: row.username,
        //                 displayname: row.displayname,
        //                 email: row.email
        //             });
        //         }
        //     });
        // });

        userDialog.open()
    }

    function getAllSessions(callback) {
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                var rs = tx.executeSql("SELECT * FROM drone_sessions ORDER BY date DESC, start_time DESC");
                var sessions = [];

                console.log("Found", rs.rows.length, "drone sessions in database");

                for (var i = 0; i < rs.rows.length; i++) {
                    sessions.push(rs.rows.item(i));
                }

                if (callback) {
                    callback(sessions);
                }

            } catch (error) {
                console.error("Error retrieving sessions:", error);
                if (callback) {
                    callback([]);
                }
            }
        });
    }

    function registerUser(username, displayname, email, password, confirmpassword, callback) {
        var db = getDatabase();
        var result = false;

        db.transaction(function(tx) {
            // Print input values
            console.log("=== USER REGISTRATION ATTEMPT ===");
            console.log("Username:", username);
            console.log("Display Name:", displayname);
            console.log("Email:", email);
            // Consider not logging passwords in production for security
            console.log("Password length:", password.length);
            console.log("Confirm Password length:", confirmpassword.length);

            // First check if username already exists
            var usernameCheck = tx.executeSql(
                        "SELECT id FROM users WHERE username = ?",
                        [username]
                        );

            if (usernameCheck.rows.length > 0) {
                console.log("Registration failed - username already exists");
                showToastMessage("Username already exists", true);
                if (callback) callback(false);
                return;
            }

            // Check if email already exists
            var emailCheck = tx.executeSql(
                        "SELECT id FROM users WHERE email = ?",
                        [email]
                        );

            if (emailCheck.rows.length > 0) {
                console.log("Registration failed - email already exists");
                showToastMessage("Email already registered", true);
                if (callback) callback(false);
                return;
            }

            var rs = tx.executeSql(
                        "INSERT INTO users(username, displayname, email, password) VALUES(?, ?, ?, ?)",
                        [username, displayname, email, password]
                        );

            if (rs.rowsAffected > 0) {
                console.log("Registration successful!");
                console.log("Rows affected:", rs.rowsAffected);
                console.log("Inserted ID:", rs.insertId);

                // Fetch and print the inserted record
                var selectRs = tx.executeSql(
                            "SELECT * FROM users WHERE id = ?",
                            [rs.insertId]
                            );

                if (selectRs.rows.length > 0) {
                    var insertedUser = selectRs.rows.item(0);
                    console.log("Inserted user details:");
                    console.log("ID:", insertedUser.id);
                    console.log("Username:", insertedUser.username);
                    console.log("Display Name:", insertedUser.displayname);
                    console.log("Email:", insertedUser.email);
                    console.log("RPC Completed:", insertedUser.rpc_completed);
                    console.log("Created At:", insertedUser.created_at);
                }

                result = true;
            } else {
                console.log("Registration failed - no rows affected");
                result = false;
            }

            console.log("=== REGISTRATION COMPLETED ===");

            if (callback) {
                callback(result);
            }
        });
    }

    function loginUserFunc(username, password,callback) {
        var db = getDatabase();
        var result = false;

        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM users WHERE username=? AND password=?", [username, password]);
            console.log("inserted=========",rs)
            if (rs.rows.length > 0) {
                console.log("Login Success");
                result = true;
                login.visible = false;
                mainWindow.newscreen();
                mainWindow.showToastMessage("Login Successfully");
                MapGlobals.login="login"
                QGroundControl.saveBoolGlobalSetting("login", true)
            } else {
                result = false;
                console.log("Invalid Credentials");
                mainWindow.showToastMessage("Incorrect username or password");
            }

            if (callback) {
                callback(result);
            }

        });
    }

    function resetPassword(username, newPass, callback) {
        var db = getDatabase();
        db.transaction(function(tx) {  // 'tx' is the transaction object, not 'db'
            // Check if username exists
            var checkRs = tx.executeSql("SELECT * FROM users WHERE username = ?", [username]);

            var result = {success: false, message: ""};

            if (checkRs.rows.length > 0) {
                // Update password
                var updateRs = tx.executeSql("UPDATE users SET password = ? WHERE username = ?", [newPass, username]);

                if (updateRs.rowsAffected > 0) {
                    result.success = true;
                    result.message = "Password reset successfully!";
                } else {
                    result.message = "Failed to reset password. Please try again.";
                }
            } else {
                result.message = "Incorrect Username";
            }

            // Call the callback with the result
            if (callback) {
                callback(result);
            }
        });
    }

    function updateUser(old_userName, new_username, newDisplayname, newEmail, mobile_no, _rpcCompleted, callback) {
        var db = getDatabase();
        db.transaction(function(tx) {
            // Print all data BEFORE update
            console.log("=== ALL USERS BEFORE UPDATE ===");
            var beforeUpdate = tx.executeSql("SELECT * FROM users");
            for (var i = 0; i < beforeUpdate.rows.length; i++) {
                var user = beforeUpdate.rows.item(i);
                console.log("User", i + 1, "- ID:", user.id,
                            "Username:", user.username,
                            "Name:", user.displayname,
                            "Email:", user.email,
                            "Mobile:", user.mobile_number || "NULL",
                            "RPC:", user.rpc_completed);
            }

            // Perform the update
            var rs = tx.executeSql(
                        "UPDATE users SET username = ?, displayname = ?, email = ?, mobile_number = ?, rpc_completed = ? WHERE username = ?",
                        [new_username, newDisplayname, newEmail, mobile_no, _rpcCompleted, old_userName]
                        );

            if (rs.rowsAffected > 0) {
                console.log("User updated successfully");
                console.log("Rows affected:", rs.rowsAffected);

                // Print all data AFTER update
                console.log("=== ALL USERS AFTER UPDATE ===");
                var afterUpdate = tx.executeSql("SELECT * FROM users");

                for (var j = 0; j < afterUpdate.rows.length; j++) {
                    var updatedUser = afterUpdate.rows.item(j);
                    console.log("User", j + 1, "- ID:", updatedUser.id,
                                "Username:", updatedUser.username,
                                "Name:", updatedUser.displayname,
                                "Email:", updatedUser.email,
                                "Mobile:", updatedUser.mobile_number || "NULL",
                                "RPC:", updatedUser.rpc_completed);
                }

                if (callback) {
                    callback(true);
                }

            } else {

                console.log("User not found or update failed");

                if (callback) {
                    callback(false);
                }
            }
        });
    }

    function deleteUser(username) {
        var db = getDatabase();
        db.transaction(function(tx) {
            var rs = tx.executeSql(
                        "DELETE FROM users WHERE username = ?",
                        [username]
                        );
            if (rs.rowsAffected > 0) {
                console.log("User deleted");
                mainWindow.showToastMessage("User deleted");
            } else {
                console.log("User not found");
                mainWindow.showToastMessage("User not found");
            }
        });
    }

    function profilelogin() {
        var db = getDatabase();
        db.transaction(function(tx) {// Only 'id' is the primary key now
            tx.executeSql("CREATE TABLE IF NOT EXISTS userslogin(id INTEGER , login TEXT  )");
            tx.executeSql("INSERT INTO userslogin(id, login) VALUES(1, '0')");
        });
        console.log("DB Created:", db);
    }

    function loadUserData(username, callback) {
        console.log("Loading user data for:", username);

        if (username !== "") {
            var db = getDatabase();
            db.transaction(function(tx) {
                var selectRs = tx.executeSql(
                            "SELECT * FROM users WHERE username = ?",
                            [username]
                            );

                var result = null;
                if (selectRs.rows.length > 0) {
                    result = selectRs.rows.item(0);
                    console.log("User data found:", result);
                    console.log("In MainrootWindow rpc_completed:", result.rpc_completed)
                } else {
                    console.log("No user found with username:", username);
                }

                // Call the callback with the result
                if (callback) {
                    callback(result);
                }
            });
        } else {
            if (callback) {
                callback(null);
            }
        }
    }

    function profile() {
        var loginpage= QGroundControl.loadBoolGlobalSetting("login",false)
        if(loginpage===true){
            login.visible = false;
            mainWindow.newscreen();
            QGroundControl.saveBoolGlobalSetting("login", true)
            modebtn1.visible = false

        }else{
            login.visible = true;
            newscreen.visible = false
            console.log("Invalid Credentials");
            QGroundControl.saveBoolGlobalSetting("login", false)
        }

        // var db = getDatabase();
        // db.transaction(function(tx) {
        //     var rs = tx.executeSql("SELECT * FROM userslogin WHERE login = 1");

        //     if (rs.rows.length > 0) {
        //         login.visible = false;
        //         mainWindow.newscreen();


        //     } else {
        //         login.visible = true;
        //         newscreen.visible = false
        //         console.log("Invalid Credentials");
        //     }
        // });
    }

    function setLogin(userId) {
        console.log("setLogin========");

        var db = getDatabase();

        db.transaction(function(tx) {

            var rs = tx.executeSql("UPDATE userslogin SET login = 1 WHERE id = ?", [userId]);
            if (rs.rowsAffected > 0) {
                console.log("Password Reset");
            } else {
                console.log("User not found");
            }

        });
    }

    function setLogout(userId) {
        var db = getDatabase();

        db.transaction(function(tx) {

            var rs = tx.executeSql("UPDATE userslogin SET login = 0 WHERE id = ?", [userId]);
            if (rs.rowsAffected > 0) {
                console.log("Password Reset");
            } else {
                console.log("User not found");
            }

        });
    }

    function validateNotEmpty(field, fieldName, focusField) {
        if (field.trim() === "") {
            showToastMessage(`Please enter your ${fieldName}`);
            if (focusField) focusField.focus = true;
            return false;
        }
        return true;
    }

    function validateUsername(username, focusField, isUpdate = false)   {
        if (!validateNotEmpty(username, "username", focusField)) return false;

        if (username.length < 3) {
            showToastMessage("Username must be at least 3 characters long");
            if (focusField) focusField.focus = true;
            return false;
        }

        if (!/^[a-zA-Z0-9_]+$/.test(username)) {
            showToastMessage("Username can only contain letters, numbers, and underscores");
            if (focusField) focusField.focus = true;
            return false;
        }

        // For account creation, you might want to check if username already exists
        if (!isUpdate) {
            // Simulate checking if username exists
            if (username === "existinguser") {
                showToastMessage("Username already taken");
                if (focusField) focusField.focus = true;
                return false;
            }
        }

        return true;
    }

    function validateDisplayName(displayName, focusField) {
        if (!validateNotEmpty(displayName, "display name", focusField)) return false;

        if (displayName.length < 2) {
            showToastMessage("Display name must be at least 2 characters long");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    function validateEmail(email, focusField, isUpdate = false) {
        if (!validateNotEmpty(email, "email address", focusField)) return false;

        // Comprehensive email validation regex
        var emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

        if (!emailRegex.test(email)) {
            showToastMessage("Please enter a valid email address");
            if (focusField) focusField.focus = true;
            return false;
        }

        // For account creation, you might want to check if email already exists
        if (!isUpdate) {
            // Simulate checking if email exists
            if (email === "existing@example.com") {
                showToastMessage("Email already registered");
                if (focusField) focusField.focus = true;
                return false;
            }
        }

        return true;
    }

    function validatePassword(password, focusField, isUpdate = false) {
        // For update, password is optional (only validate if provided)
        if (isUpdate && password === "") return true;

        if (!validateNotEmpty(password, "password", focusField)) return false;

        if (password.length < 8) {
            showToastMessage("Password must be at least 8 characters long");
            if (focusField) focusField.focus = true;
            return false;
        }

        // Check for password strength
        var hasUpperCase = /[A-Z]/.test(password);
        var hasLowerCase = /[a-z]/.test(password);
        var hasNumbers = /[0-9]/.test(password);
        var hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

        var strengthScore = (hasUpperCase ? 1 : 0) + (hasLowerCase ? 1 : 0) +
                (hasNumbers ? 1 : 0) + (hasSpecialChar ? 1 : 0);

        if (strengthScore < 3) {
            showToastMessage("Password should include uppercase, lowercase, numbers, and special characters");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    function validateConfirmPassword(password, confirmPassword, focusField, isUpdate = false) {
        // For update, confirm password is only required if password is provided
        if (isUpdate && password === "" && confirmPassword === "") return true;

        if (!validateNotEmpty(confirmPassword, "password confirmation", focusField)) return false;

        if (password !== confirmPassword) {
            showToastMessage("Passwords don't match");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    function validateMobileNumber(mobile, focusField) {
        if (!validateNotEmpty(mobile, "mobile number", focusField)) return false;

        // Basic mobile number validation
        var mobileRegex = /^[\+]?[1-9][\d]{0,15}$/;
        var cleanedMobile = mobile.replace(/[-\s\(\)]/g, '');

        if (!mobileRegex.test(cleanedMobile)) {
            showToastMessage("Please enter a valid mobile number");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }


    Item {
        id: toastContainer
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 40
        visible: false
        z: 1000 // Make sure it's above other components

        Rectangle {
            id: toastBackground
            width: toastText.width + 40
            height: 40
            radius: 10
            color: "#323232"
            opacity: 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: toastText
                anchors.centerIn: parent
                text: ""
                color: "white"
                font.bold: true
            }
        }

        Timer {
            id: toastTimer
            interval: 3000
            running: false
            onTriggered: toastContainer.visible = false
        }

        function showToast(msg) {
            toastText.text = msg
            toastContainer.visible = true
            toastTimer.restart()
        }
    }

    /// Saves main window position and size
    MainWindowSavedState {
        window: mainWindow
    }

    property bool _forceClose: false

    function finishCloseProcess() {
        _forceClose = true
        // For some reason on the Qml side Qt doesn't automatically disconnect a signal when an object is destroyed.
        // So we have to do it ourselves otherwise the signal flows through on app shutdown to an object which no longer exists.
        firstRunPromptManager.clearNextPromptSignal()
        QGroundControl.linkManager.shutdown()
        QGroundControl.videoManager.stopVideo();
        mainWindow.close()
    }

    // On attempting an application close we check for:
    //  Unsaved missions - then
    //  Pending parameter writes - then
    //  Active connections

    property string closeDialogTitle: qsTr("Close %1").arg(QGroundControl.appName)

    function checkForUnsavedMission() {
        if (planView._planMasterController.dirty) {
            showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              Dialog.Yes | Dialog.No,
                              function() { checkForPendingParameterWrites() })
            return false
        } else {
            return checkForPendingParameterWrites()
        }
    }

    function checkForPendingParameterWrites() {
        for (var index=0; index<QGroundControl.multiVehicleManager.vehicles.count; index++) {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites) {
                mainWindow.showMessageDialog(closeDialogTitle,
                                             qsTr("You have pending parameter updates to a vehicle. If you close you will lose changes. Are you sure you want to close?"),
                                             Dialog.Yes | Dialog.No,
                                             function() { checkForActiveConnections() })
                return false
            }
        }
        return checkForActiveConnections()
    }

    function checkForActiveConnections() {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                                         qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                                         Dialog.Yes | Dialog.No,
                                         function() { finishCloseProcess() })
            return false
        } else {
            finishCloseProcess()
            return true
        }
    }

    onClosing: (close) => {
                   if (!_forceClose) {
                       close.accepted = checkForUnsavedMission()
                   }
               }

    background: Rectangle {
        anchors.fill:   parent
        color: QGroundControl.globalPalette.window
    }

    QGCMapPolygonVisuals{
        id:filename
    }

    FlyView {
        id:                     flyView
        anchors.fill:           parent
        utmspSendActTrigger:    _utmspSendActTrigger
        planType: plan
        visible: false
    }


    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        false
        planType: plan
    }

    ProfileScreenNew {
        id: profileScreen
        anchors.fill: parent
        visible:false
    }

    FlyViewToolBar {
        id: toolbar
        visible: false
    }

    Newscreen {
        id:                     newscreen
        anchors.fill:           parent
        visible : false
    }

    // CalibrationSettings{
    //     id : calibrationPage
    //     visible : false
    // }

    // Loader {
    //     id: calibrationLoader
    //     active: false
    //     sourceComponent: CalibrationSettings { id: calibrationPage }

    // }


    Loader {
        id: login
        anchors.fill: parent
        source: "qrc:/qml/LoginPages/WelcomeScreen.qml"
        visible: false
    }

    // Class1 {
    //     id:                     login
    //     anchors.fill:           parent
    //     visible : false
    // }

    MainRootIcons {
        id:             mainrootIcons
        anchors.top:        toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.right:      parent.right
        visible:        false
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 15
        flightMap : planView.editorMap
        mapRotation: MapGlobals.mapRotation
        planViewRef: planView
    }

    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }

    function showToolSelectDialog() {

        if (!mainWindow.preventViewSwitch()) {
            console.log('showToolSelectDialog')
            //mainWindow.showIndicatorDrawer1(toolSelectComponent, null)
            sideDrawer.open()
        }
    }

    function showToolSelectDialog1(index) {

        if (!mainWindow.preventViewSwitch()) {
            sideDrawer.open()
            tabBar.currentIndex = index; // 3rd index (0-based index)
            loaders.source = tabModel.get(index).file; // Load that page
        }
    }

    function sideDrawer1(qmlFile) {
        console.log("qmlFile",)
        sideDrawer.pushView(qmlFile)
    }


    Drawer {
        id: sideDrawer
        edge: Qt.RightEdge
        modal: true
        focus: true
        width: parent.width
        height: parent.height
        visible: false
        interactive: false // Prevent opening with swipe

        background: Rectangle {
            color: "white"
            radius: 0
        }

        property var navigationStack: []
        property var rootDrawer: sideDrawer

        function pushView(qmlFile) {
            navigationStack.push(qmlFile);
            loaders.source = qmlFile;
        }

        function popView() {
            if (navigationStack.length > 1) {
                navigationStack.pop();
                loaders.source = navigationStack[navigationStack.length - 1];
            }
        }

        ListModel {
            id: tabModel
            ListElement { image: "/qmlimages/NewImages/parameterSettings.svg"; file: "BasicParameters.qml"; title: "Flight Modes" }
            ListElement { image: "/qmlimages/NewImages/callibration.png"; file: "APMSensorsComponent.qml"; title: "Settings" }
            ListElement { image: "/qmlimages/NewImages/failsafe.svg"; file: "APMSafetyComponent.qml"; title: "Diamond" }
            ListElement { image: "/qmlimages/NewImages/settings.svg"; file: "GeneralSettings.qml"; title: "Info" }
            ListElement { image: "/qmlimages/NewImages/commlinks.svg"; file: "LinkSettings.qml"; title: "Info" }

            // Update when activeVehicle changes
            // onActiveVehicleChanged: {
            //     updateSettingsTab();
            // }

            Component.onCompleted: {
                updateSettingsTab();
            }

            function updateSettingsTab() {
                if (activeVehicle) {
                    tabModel.setProperty(1, "file", "CalibrationSettings.qml");
                } else {
                    tabModel.setProperty(1, "file", "APMSensorsComponent.qml");
                }
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Top App Bar
            Rectangle  {
                Layout.preferredHeight: ScreenTools.toolbarHeight
                Layout.fillWidth: true
                color:  "#1b1c3e"

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left     // Required!
                    anchors.leftMargin: 20        // Now it will work
                    spacing: 20

                    QGCColoredImage {
                        id: backArrow
                        width: 30
                        height: 25
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        color: "white"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sideDrawer.close()
                            }
                        }
                    }

                    Text {
                        text: "Settings"
                        font.bold: true
                        font.pixelSize: 20
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                    }
                }

            }

            // Rectangle {
            //     Layout.preferredHeight: parent.height * 0.10
            //     Layout.fillWidth: true
            //     color: "transparent"
            // }

            TabBar {
                id: tabBar
                Layout.preferredHeight: 20//ScreenTools.toolbarHeight
                Layout.fillWidth: true
                currentIndex: 0

                background: Rectangle {
                    color:  "#1b1c3e"
                }

                Repeater {
                    model: tabModel
                    TabButton {
                        Layout.fillWidth: true
                        height: ScreenTools.toolbarHeight

                        background: Rectangle {
                            color: tabBar.currentIndex === index ? "white" : "grey"
                            radius: 10
                        }

                        contentItem: Column {
                            spacing: 7
                            anchors.centerIn: parent

                            QGCColoredImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: tabBar.currentIndex === index ? 18 : 18
                                height: tabBar.currentIndex === index ? 18 : 18
                                source: model.image
                                //color: tabBar.currentIndex === index ?  "white"//"#1b1c3e" : "white"
                                color: tabBar.currentIndex === index ? "transparent" : "white"
                            }

                            // Rectangle {
                            //     width: 45
                            //     height: 3
                            //     color: tabBar.currentIndex === index ? "white" : "black"
                            //     anchors.horizontalCenter: parent.horizontalCenter
                            //     visible: tabBar.currentIndex === index
                            //     radius: 5
                            // }
                        }

                        onClicked: {
                            loaders.source = model.file;
                            // if (activeVehicle) {
                            //     loaders.source = model.file;
                            // } else {
                            //     showToast("Device not connected");
                            // }
                        }
                    }
                }
            }

            Rectangle {
                color: "white"
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10

                Loader {
                    id: loaders
                    anchors.fill: parent
                    source: tabModel.get(tabBar.currentIndex).file/*if (activeVehicle) {
                                            tabModel.get(tabBar.currentIndex).file
                                        }*/
                }

                Connections {
                    target: tabBar
                    onCurrentIndexChanged: {
                        loaders.source = tabModel.get(tabBar.currentIndex).file
                        // if (activeVehicle) {
                        //     loaders.source = tabModel.get(tabBar.currentIndex).file
                        // }
                    }
                }
            }
        }
    }

    // Drawer {
    //     id: sideDrawer
    //     width: parent.width * 0.6
    //     height: parent.height
    //     interactive: true
    //     edge: Qt.RightEdge


    //     background: Rectangle{
    //         color: "black"
    //         opacity: 0.8
    //     }

    //     // Navigation stack for the drawer content
    //     property var navigationStack: []
    //     property var rootDrawer: sideDrawer

    //     // Function to push a new QML file onto the stack
    //     function pushView(qmlFile) {
    //         navigationStack.push(qmlFile);
    //         loaders.source = qmlFile;
    //     }

    //     // Function to pop the current view
    //     function popView() {
    //         if (navigationStack.length > 1) {
    //             navigationStack.pop();
    //             loaders.source = navigationStack[navigationStack.length - 1];
    //         }
    //     }

    //     ListModel {
    //         id: tabModel
    //         ListElement { image: "/qmlimages/NewImages/RCCallibration.png"; file: "qrc:/qml/SettingsPanel/RCCallibarationTab.qml" ;title: "Radio" }
    //         ListElement { image: "/qmlimages/NewImages/parameterSettings.svg"; file: "qrc:/qml/SettingsPanel/CalibrationSettings.qml" ;title: "Flight Modes"}
    //         ListElement { image: "/qmlimages/NewImages/menu.png";  file: "" ;title: "Settings" }
    //         ListElement { image: "/qmlimages/NewImages/diamond.png";  file: "" ;title: "Diamond" }
    //         ListElement { image: "/qmlimages/NewImages/CompassArrow.png";  file: "" ; title: "Info"}
    //     }


    //     RowLayout {
    //         anchors.fill: parent
    //         spacing: 0

    //         // Vertical Tab Bar
    //         TabBar {
    //             id: tabBar
    //             Layout.preferredWidth: 50
    //             Layout.fillHeight: true
    //             currentIndex: 0

    //             background: Rectangle {
    //                 color: "black"
    //                 opacity: 0.9
    //             }

    //             contentItem: ListView {
    //                 orientation: ListView.Vertical
    //                 boundsBehavior: Flickable.StopAtBounds
    //                 model: tabBar.contentModel
    //                 currentIndex: tabBar.currentIndex
    //                 interactive: false

    //                 highlightMoveDuration: 0
    //                 //highlightRangeMode: ListView.ApplyRange
    //                 //preferredHighlightBegin: 40
    //                 //preferredHighlightEnd: height - 40

    //                 // Key Change: Calculate spacing to distribute tabs evenly
    //                 spacing: (height - (tabModel.count * 35)) / (tabModel.count + 1)
    //                 topMargin: spacing
    //                 bottomMargin: spacing
    //             }

    //             Repeater {
    //                 model: tabModel
    //                 delegate: TabButton {
    //                     width: tabBar.width
    //                     text: title
    //                     // Ensure proper vertical sizing
    //                     implicitHeight: 35

    //                     background: Rectangle {
    //                         color: "transparent"
    //                     }

    //                     contentItem: QGCColoredImage {
    //                         anchors.centerIn: parent
    //                         source: model.image //tabBar.currentIndex === index ? model.image : model.unselected
    //                         color : tabBar.currentIndex === index ? "#33ffd4" : "white"
    //                     }
    //                     onClicked: loaders.source = model.file
    //                 }
    //             }
    //         }

    //         Rectangle {
    //             Layout.preferredWidth: 1  // Line thickness
    //             Layout.fillHeight: true
    //             color: "grey"
    //             // anchors.left: tabBar.right
    //             //     anchors.right: parent.right
    //             //     anchors.leftMargin: 15
    //             //     anchors.rightMargin: 15
    //         }

    //         Rectangle {
    //             color: "transparent"
    //             Layout.fillWidth: true
    //             Layout.fillHeight: true

    //             Loader {
    //                 id: loaders
    //                 anchors.fill: parent
    //                 source: tabModel.get(tabBar.currentIndex).file
    //             }

    //             // Update loader on tab change
    //             Connections {
    //                 target: tabBar
    //                 onCurrentIndexChanged: loaders.source = tabModel.get(tabBar.currentIndex).file
    //             }
    //         }

    //     }
    // }


    // Button {
    //     text: activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
    //     Layout.rightMargin: 40
    //     font.bold: true
    //     font.pixelSize: 16
    //     visible:activeVehicle ? false : true
    //     anchors.left: parent.left
    //     anchors.bottom: parent.bottom
    //     anchors.leftMargin: 20   // Left padding
    //                 anchors.rightMargin: 40  // Right padding
    //                 anchors.topMargin: 10    // Top padding
    //                 anchors.bottomMargin: 10
    //     contentItem: Text {
    //         text: parent.text
    //         font: parent.font
    //         color: "white"  // Set text color
    //         horizontalAlignment: Text.AlignHCenter
    //         verticalAlignment: Text.AlignVCenter
    //         anchors.leftMargin: 40   // Left padding
    //                     anchors.rightMargin: 40  // Right padding
    //                     anchors.topMargin: 10    // Top padding
    //                     anchors.bottomMargin: 10 // Bottom padding
    //     }
    //     background: Rectangle {
    //         color: "#007AFF"  // Blue color (iOS-style button)
    //         radius: 20  // Curved button
    //         border.color:  "white"//"#005BBB"  // Border color
    //         border.width: 2
    //     }
    //         onClicked: {
    //             if (!mainWindow.preventViewSwitch()) {
    //                 mainWindow.showIndicatorDrawer(toolSelectComponents, null)
    //             }
    //         }
    //     }

    property var parameterMap: [
        { name: "MNT1_TYPE", value: "BrushlessPWM" },
        { name: "RC7_OPTION", value: "Mount Yaw" }
    ]

    Dialog {
        id: confirmDialog
        title: "Confirm Parameter Changes"
        standardButtons: Dialog.Yes | Dialog.No

        Label {
            text: "Are you sure you want to change all 10 parameters?"
        }

        onAccepted: {
            // Change all parameters
            for (var i = 0; i < parameterMap.length; i++) {
                var paramInfo = parameterMap[i]
                var fact = activeVehicle.getParameterFact(-1, paramInfo.name)
                if (fact) {
                    fact.value = paramInfo.value
                    console.log("Set parameter", paramInfo.name, "to", paramInfo.value)
                } else {
                    console.log("Parameter not found:", paramInfo.name)
                }
            }
            completeDialog.open()
        }
    }

    Dialog {
        id: completeDialog
        title: "Operation Complete"
        standardButtons: Dialog.Ok

        Label {
            text: "Parameters changed successfully!"
        }
    }

    ColumnLayout {
        id:columnbtn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: parent.height* 0.15
        anchors.leftMargin: 20
        visible: true
        spacing: 10  // Adjust this value to control space between icons


        Rectangle {
            id: listbtn
            Layout.alignment: Qt.AlignLeft
            width: parent.width * 0.05    // 8% of parent width
            height: width                 // Keep it square
            radius: width / 2            // Circle
            color:  "white"//"#1b1c3e"
            visible: false
            border.width: width * 0.05    // 10% of button width
            border.color:  "white"//"#005BBB"

            QGCColoredImage {
                id: flightModeIndicator2
                source: "/qmlimages/NewImages/savefile.svg" //"/qmlimages/NewImages/log.png"
                width: parent.width * 0.5   // 60% of button size
                height: width
                anchors.centerIn: parent
                //color: "transparent"
                color : "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    QGroundControl.saveGlobalSetting("waypoint", "waypoint1")
                    if(_appSettings.screen==="Plan"){
                        planView.loaddata()

                    }else{
                        planView.loaddata1()
                    }
                }
            }
        }


        // Rectangle {
        //     id: takeoffbtn
        //     Layout.alignment: Qt.AlignLeft
        //     width: parent.width * 0.05    // 8% of parent width
        //     height: width                 // Keep it square
        //     radius: width / 2            // Circle
        //     color:  "white"//"#1b1c3e"
        //     visible: true
        //     border.width: width * 0.05    // 10% of button width
        //     border.color:  "white"//"#005BBB"

        //     QGCColoredImage {
        //         id: takeofficon
        //         source: "/qmlimages/NewImages/takeOff.png"
        //         width: parent.width * 0.5   // 60% of button size
        //         height: width
        //         anchors.centerIn: parent
        //         color: "white"
        //     }

        //     MouseArea {
        //         anchors.fill: parent
        //         onClicked: {
        //             myDialog.imageSource = "/qmlimages/NewImages/takeOff.png"
        //             myDialog.dialogText = "settings"
        //             myDialog.open()
        //         }
        //     }
        // }

        Rectangle {
            id: takeoffbtn
            Layout.alignment: Qt.AlignLeft
            width: parent.width * 0.05    // 8% of parent width
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  "white"//"#1b1c3e"      // white background
            visible:  false
            border.width: width * 0.05
            border.color:  "white"//"#005BBB"

            QGCColoredImage {
                id: takeofficon
                source: "/qmlimages/NewImages/takeOff.svg"
                width: parent.width * 0.6   // 60% of button size
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/qmlimages/NewImages/takeOff.svg"
                    myDialog.dialogText = "settings"
                    myDialog.open()
                }
            }
        }

        Rectangle {
            id: waypointbtn
            Layout.alignment: Qt.AlignLeft
            width: parent.width * 0.05    // 8% of parent width
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  "white"//"#1b1c3e"      // white background
            visible:  false
            border.width: width * 0.05
            border.color:  "white"//"#005BBB"

            QGCColoredImage {
                id: waypointbtnicon1
                source: "/qmlimages/MapAddMission.svg"
                width: parent.width * 0.6   // 60% of button size
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    QGroundControl.saveGlobalSetting("waypoint", "waypoint")
                    QGroundControl.saveGlobalSetting("waypointvisible", "waypointvisible")
                    QGroundControl.saveGlobalSetting("waypointMark", "true")
                    planView.mapclear()
                    mainWindow.showPlanView()

                    waypointDescriptionDialog.createObject(mainWindow).open()

                }
            }
        }

        // Rectangle {
        //     id: eraserbtn
        //     Layout.alignment: Qt.AlignLeft
        //     width: parent.width * 0.05    // 8% of parent width
        //     height: width                 // Keep it square
        //     radius: width / 2   // Makes it a circle
        //     color:  "white"//"#1b1c3e"      // white background
        //     visible:  false
        //     border.width: width * 0.05
        //     border.color:  "white"//"#005BBB"



        //     QGCColoredImage {
        //         id: eraserbtnicon
        //         source: "/qmlimages/NewImages/map_eraser.svg"
        //         width: parent.width * 0.5   // 60% of button size
        //         height: width
        //         anchors.centerIn: parent
        //         color: "transparent"
        //     }



        //     MouseArea {
        //         anchors.fill: parent
        //         onClicked: {
        //             planView.mapclear()
        //         }
        //     }
        // }

        Rectangle {
            id: camerabtn
            Layout.alignment: Qt.AlignLeft
            width: parent.width * 0.05    // 8% of parent width
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  "white"//"#1b1c3e"      // white background
            visible:  false
            border.width: width * 0.05
            border.color:  "white"//"#005BBB"

            QGCColoredImage {
                id: camerabtnicon
                source: "/qmlimages/NewImages/takeOff.png"
                width: parent.width * 0.5   // 60% of button size
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "black"
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    // //whatsappImageSlider.visible=true
                    // mainWindow.showToastMessage("Camera clicked");
                    myDialog.imageSource = "/qmlimages/NewImages/takeOff.png"
                    myDialog.dialogText = "settings"
                    myDialog.open()
                }
            }
        }


        Rectangle {
            id: landbtn
            Layout.alignment: Qt.AlignLeft
            width: parent.width * 0.05    // 8% of parent width
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  "white"//"#1b1c3e"      // white background
            visible:  false
            border.width: width * 0.05
            border.color:  "white"//"#005BBB"

            QGCColoredImage {
                id: landbtnicon
                source: "/qmlimages/NewImages/return.svg"
                width: parent.width * 0.5   // 60% of button size
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "black"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {

                    myDialog.imageSource = "/qmlimages/NewImages/return.svg";  // Set the image dynamically
                    myDialog.dialogText = "Land Mode"; // Set the text dynamically
                    myDialog.open()
                }
            }
        }

        Rectangle {
            id: rtlbtn
            Layout.alignment: Qt.AlignLeft
            width: parent.width * 0.05    // 8% of parent width
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  "white"//"#1b1c3e"      // white background
            visible:  false
            border.width: width * 0.05
            border.color:  "white"//"#005BBB"

            QGCColoredImage {
                id: rtlbtnicon
                source: "/qmlimages/NewImages/landing.png"
                width: parent.width * 0.5   // 60% of button size
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "black"
            }


            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/qmlimages/NewImages/landing.png";  // Set the image dynamically
                    myDialog.dialogText = "RTL Mode"; // Set the text dynamically
                    myDialog.open()

                }
            }
        }

        RowLayout {
            id: modeRow
            spacing: 10  // Adjust the spacing between buttons
            Layout.alignment: Qt.AlignLeft

            property bool extraButtonsVisible: false  // Toggle visibility of extra buttons


            Rectangle {
                id: modebtn
                Layout.alignment: Qt.AlignLeft
                width: parent.width * 0.05    // 8% of parent width
                height: width                 // Keep it square
                radius: width / 2   // Makes it a circle
                color:  "white"//"#1b1c3e"      // white background
                visible:  false
                border.width: width * 0.05
                border.color:  "white"//"#005BBB"

                QGCColoredImage {
                    id: flightModeIndicator12
                    source: "/qmlimages/FlightModesComponentIcon.png"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (activeVehicle) {
                            // Show confirmation dialog
                            confirmDialog.open()
                        } else {
                            console.log("No active vehicle")
                        }

                    }
                }
            }


            // Extra buttons
            Rectangle {
                id: extraBtn1
                width: 50
                height: 50
                radius: width / 2
                color: "white"
                visible: modeRow.extraButtonsVisible  // Controlled by modebtn

                Text {
                    text: "A"
                    color: "white"
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Extra button 1 clicked");
                    }
                }
            }

            Rectangle {
                id: extraBtn2
                width: 50
                height: 50
                radius: width / 2
                color: "white"
                visible: modeRow.extraButtonsVisible

                Text {
                    text: "M"
                    color: "white"
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Extra button 2 clicked");
                    }
                }
            }

            Rectangle {
                id: extraBtn3
                width: 50
                height: 50
                radius: width / 2
                color: "white"
                visible: modeRow.extraButtonsVisible

                Text {
                    text: "AB"
                    color: "white"
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Extra button 3 clicked");
                    }
                }
            }

            Rectangle {
                id: extraBtn4
                width: 50
                height: 50
                radius: width / 2
                color: "white"
                visible: modeRow.extraButtonsVisible

                Text {
                    text: "M"
                    color: "white"
                    font.bold: true
                    anchors.centerIn: parent
                }

                QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/edit-pencil.svg"
                    width: 16
                    height: 16
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 5
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Extra button 3 clicked");
                    }
                }
            }
        }

        Rectangle {
            id: modebtn1
            Layout.alignment: Qt.AlignLeft

            // Base it on flight mode text's size
            width: flightmode1.implicitWidth + 30   // 10px padding left/right
            height: flightmode1.implicitHeight + 15 // 5px padding top/bottom
            radius: height / 2   // pill/capsule shaped
            color:  "white"//"#1b1c3e"
            visible: activeVehicle

            border.width: 2
            border.color:  "white"//"#005BBB"

            FlightModeIndicator {
                id: flightmode1
                //visible: true
                anchors.centerIn: parent
            }
        }

    }

    Component {
        id: waypointDescriptionDialog

        QGCPopupDialog {
            id: popup
            title: qsTr(" Do You know ? ")

            buttons: Dialog.Ok | Dialog.Cancel

            onAccepted: {
                popup.visible = false
                QGroundControl.saveGlobalSetting("waypointMark", "true")
                MapGlobals.waypoint="waypoint"
            }

            onRejected: {
                MapGlobals.waypoint="waypoint1"
                popup.visible = false

                //waypoint enable disable logic
                QGroundControl.saveGlobalSetting("returnWaypointEnabled", "true")

                if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Camera"){
                    mainWindow.cameraView()
                    mainWindow.closefile()
                }else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
                    mainWindow.showMapping()
                    mainWindow.closefile()
                }
                else{
                    if (planType === "Plan") {
                        mainWindow.showFlyView()
                        mainWindow.closefile()
                    } else {
                        mainWindow.showFlyView1()
                        mainWindow.closefile()
                    }
                }

            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel {
                    text: qsTr("Your first point is selected as the takeoff point, and it is also your first waypoint.\nNow select your waypoints. Click OK to continue.")
                    Layout.fillWidth: true
                }
            }
        }
    }

    Dialog {
        id: myDialog
        width: 320
        height: 300
        property string imageSource: "/res/default.svg" // Default image
        property string dialogText: "Default Text" // Default text

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        background: Rectangle {
            color: "#ccccff"
            radius: 50
            border.color: "#6a6af8"
            border.width: 5
            clip: true
        }

        QtObject {
            id: progressState
            property real value: 0.0
        }

        QtObject {
            id: takeoffSettings
            property real sliderOutputValue: 1.0
        }

        contentItem: ColumnLayout {
            width: parent.width
            height: parent.height
            spacing: 10
            anchors.centerIn: parent

            Text {

                text: myDialog.dialogText==="settings"?"Takeoff Altitude: " + takeoffSettings.sliderOutputValue + " m":myDialog.dialogText+"/n add data"
                font.pixelSize: 16
                color: "black"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                id: circularButton
                width: 80
                height: 80
                radius: 40
                color: "white"
                border.color: "#6a6af8"
                border.width: 2
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    source: myDialog.imageSource
                    width: 24
                    height: 24
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: holdArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: progressTimer.start()
                    onReleased: {
                        progressTimer.stop()
                        progressState.value = 0
                        progressCircle.requestPaint()
                    }
                    onEntered: circularButton.color = "#ccccff"
                    onExited: circularButton.color = "white"
                }

                Canvas {
                    id: progressCircle
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.beginPath()
                        ctx.arc(
                                    width / 2, height / 2,
                                    35, -Math.PI / 2,
                                    (2 * Math.PI * progressState.value) - Math.PI / 2,
                                    false
                                    )
                        ctx.lineWidth = 6
                        ctx.strokeStyle = "#2323f2"
                        ctx.stroke()
                    }
                }
            }

            RowLayout {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter
                visible: myDialog.dialogText==="settings"?true:false
                Rectangle {
                    width: 40
                    height: 40
                    color: "#ccccff"
                    radius: 10
                    border.color: "#6a6af8"
                    border.width: 2

                    Text {
                        text: "-"
                        font.pixelSize: 24
                        color: "black"
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (takeoffSettings.sliderOutputValue > 1.0) {
                                takeoffSettings.sliderOutputValue = Math.round((takeoffSettings.sliderOutputValue - 0.1) * 10) / 10
                            }
                        }
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    color: "#ccccff"
                    radius: 10
                    border.color: "#6a6af8"
                    border.width: 2

                    Text {
                        text: "+"
                        font.pixelSize: 24
                        color: "black"
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (takeoffSettings.sliderOutputValue < 120) {
                                takeoffSettings.sliderOutputValue = Math.round((takeoffSettings.sliderOutputValue + 0.1) * 10) / 10
                            }
                        }
                    }
                }
            }
        }


        Timer {
            id: progressTimer
            interval: 100
            repeat: true
            onTriggered: {
                if (progressState.value < 1.0) {
                    progressState.value += 0.1
                    progressCircle.requestPaint()
                } else {
                    progressTimer.stop()
                    progressState.value = 0
                    progressCircle.requestPaint()
                    myDialog.dialogText==="settings"?executeAction1():executeAction2()
                }
            }
        }
    }


    function executeAction1() {


        console.log("Button long-pressed! Action executed.")
        // _guidedController.closeAll()
        // _guidedController.confirmAction(3)

        var sliderOutputValue = 0
        sliderOutputValue = takeoffSettings.sliderOutputValue
        console.log("takeoffSettings.sliderOutputValue",sliderOutputValue)

        //guidedController.executeAction(flightModeIndicatorBg1.action, flightModeIndicatorBg1.actionData, sliderOutputValue, flightModeIndicatorBg1.optionChecked)
        if (mapIndicator) {
            mapIndicator.actionConfirmed()
            mapIndicator = undefined
        }

        UTMSPStateStorage.indicatorOnMissionStatus = true
        UTMSPStateStorage.currentNotificationIndex = 7
        UTMSPStateStorage.currentStateIndex = 3

        var valueInMeters = _unitsConversion.appSettingsVerticalDistanceUnitsToMeters(sliderOutputValue)
        activeVehicle.guidedModeTakeoff(valueInMeters)

        if( activeVehicle.armed){

            rtlbtn.visible=true
            takeoffbtn.visible=false
        }





        myDialog.close()
    }

    function executeAction2() {
        console.log("Button long-pressed! Action executed.1")
        if(activeVehicle){
            var homeDistance = QGroundControl.loadGlobalSetting("home", "home")

            if (homeDistance > 10.0) {
                activeVehicle.guidedModeRTL(false)
            } else {
                activeVehicle.guidedModeLand()
            }

        }
        // rtlbtn.visible=false
        // takeoffbtn.visible=true


        myDialog.close()
    }




    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 20
        spacing: 20  // Adjust this value to control space between icons

        Rectangle {
            id: planbtn
            Layout.alignment: Qt.AlignRight
            width: 100
            height: 38
            radius: width / 2  // Makes it a circle
            color:  "white"//"#1b1c3e"     // white background
            visible: false

            Text {
                text: " + New Plot "
                color: "black"
                anchors.centerIn: parent
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    QGroundControl.saveGlobalSetting("load", "load")
                    QGroundControl.saveGlobalSetting("waypoint", "waypoint1")
                    dialog.visible = true
                    MapGlobals.save = "save"
                }


                // onClicked: {
                //     // mainWindow.showPlanView()
                //     // //viewer3DWindow.close()

                // }
            }
        }

    }


    // Dialog {
    //     id: dialog
    //     modal: true
    //     dim: true
    //     anchors.centerIn: parent
    //     width: parent.width //* 0.8   // 80% of screen width
    //     height: parent.height // * 0.5 // 50% of screen height
    //     background: Rectangle {
    //         color: "transparent"
    //         radius: 10
    //         border.color: "white"
    //         border.width: 1
    //     }

    //     // Close button in top-right corner
    //     Rectangle {
    //         id: closeBtn
    //         width: 30
    //         height: 30
    //         radius: width / 2
    //         color: "red"
    //         anchors.right: parent.right
    //         anchors.top: parent.top
    //         anchors.margins: 10

    //         Text {
    //             text: "X"
    //             color: "white"
    //             anchors.centerIn: parent
    //             font.bold: true
    //         }

    //         MouseArea {
    //             anchors.fill: parent
    //             onClicked:{
    //                 dialog.visible = false
    //                 mainWindow.showFlyView()

    //             }
    //         }
    //     }

    //     Column {
    //         anchors.centerIn: parent
    //         spacing: 20
    //         width: parent.width * 0.9
    //         height: parent.height

    //         RowLayout {
    //             width: parent.width
    //             height: parent.height  // Set explicit height for the row layout
    //             spacing: 20

    //             Button {
    //                 Layout.alignment: Qt.AlignHCenter
    //                 Layout.preferredWidth: parent.width* 0.2
    //                 Layout.preferredHeight: parent.height* 0.4

    //                 background: Rectangle {
    //                     color:  "white"//"#1b1c3e"
    //                     radius: 12
    //                 }

    //                 contentItem: Item {
    //                     anchors.fill: parent

    //                     Column {
    //                         spacing: 8
    //                         anchors.centerIn: parent   // ✅ Center both icon and text vertically and horizontally

    //                         Image {
    //                             source: "/qmlimages/NewImages/mapSelection.png"  // Replace with actual icon
    //                             width: 50
    //                             height: 50
    //                             fillMode: Image.PreserveAspectFit
    //                             anchors.horizontalCenter: parent.horizontalCenter}

    //                         Text {
    //                             text: "Map Selection"
    //                             color: "white"
    //                             font.pixelSize: 16
    //                             font.bold: true
    //                             horizontalAlignment: Text.AlignHCenter
    //                             verticalAlignment: Text.AlignVCenter
    //                             anchors.horizontalCenter: parent.horizontalCenter}
    //                     }
    //                 }
    //                 onClicked: {
    //                     console.log("Option 1 clicked")
    //                     MapGlobals.mark_with = "Mark_With_Manual"
    //                     MapGlobals.edit = "edit"
    //                     MapGlobals.editdialog = "editdialog"
    //                     mainWindow.showPlanView()
    //                     dialog.visible = false
    //                     planView.data1()
    //                 }
    //             }
    //             Button {
    //                 Layout.alignment: Qt.AlignHCenter
    //                 Layout.preferredWidth: parent.width* 0.2
    //                 Layout.preferredHeight: parent.height* 0.4

    //                 background: Rectangle {
    //                     color:  "white"//"#1b1c3e"
    //                     radius: 12
    //                 }

    //                 contentItem: Item {
    //                     anchors.fill: parent

    //                     Column {
    //                         spacing: 8
    //                         anchors.centerIn: parent   // ✅ Center both icon and text vertically and horizontally

    //                         Image {
    //                             source: "/qmlimages/NewImages/droneGpsMarking.png"  // Replace with actual icon
    //                             width: 50
    //                             height: 50
    //                             fillMode: Image.PreserveAspectFit
    //                             anchors.horizontalCenter: parent.horizontalCenter
    //                         }

    //                         Text {
    //                             text: "Drone GPS"
    //                             color: "white"
    //                             font.pixelSize: 16
    //                             font.bold: true
    //                             horizontalAlignment: Text.AlignHCenter
    //                             verticalAlignment: Text.AlignVCenter
    //                             anchors.horizontalCenter: parent.horizontalCenter
    //                         }
    //                     }
    //                 }

    //                 onClicked: {
    //                     MapGlobals.mark_with = "Mark_With_Drone"
    //                     MapGlobals.edit = "edit"
    //                     mainWindow.showPlanView()
    //                     dialog.visible = false
    //                     planView.data1()
    //                 }
    //             }
    //             Button {
    //                 Layout.alignment: Qt.AlignHCenter
    //                 Layout.preferredWidth: parent.width* 0.2
    //                 Layout.preferredHeight: parent.height* 0.4

    //                 background: Rectangle {
    //                     color:  "white"//"#1b1c3e"
    //                     radius: 12
    //                 }

    //                 contentItem: Item {
    //                     anchors.fill: parent

    //                     Column {
    //                         spacing: 8
    //                         anchors.centerIn: parent

    //                         Image {
    //                             source: "/qmlimages/NewImages/kmlFile.png"
    //                             width: 50
    //                             height: 50
    //                             fillMode: Image.PreserveAspectFit
    //                             anchors.horizontalCenter: parent.horizontalCenter
    //                         }

    //                         Text {
    //                             text: "Load KML/SHP..."
    //                             color: "white"
    //                             font.pixelSize: 16
    //                             font.bold: true
    //                             horizontalAlignment: Text.AlignHCenter
    //                             verticalAlignment: Text.AlignVCenter
    //                             anchors.horizontalCenter: parent.horizontalCenter
    //                         }
    //                     }
    //                 }

    //                 onClicked: {
    //                     MapGlobals.mark_with = "Mark_With_GPS"
    //                     MapGlobals.edit = "edit"
    //                     mainWindow.showPlanView()
    //                     dialog.visible = false
    //                     planView.data1()
    //                 }
    //             }


    //             //     Button {
    //             //         //Layout.fillWidth: true
    //             //         Layout.alignment: Qt.AlignHCenter
    //             //         Layout.preferredWidth: parent.width* 0.2
    //             //         Layout.preferredHeight: parent.height* 0.4 // Ensure height is taken from parent
    //             //         //text: "Map Selection"
    //             //         contentItem: Column {
    //             //             width: parent.width
    //             //                     height: parent.height
    //             //                     spacing: 10
    //             //                     anchors.centerIn: parent
    //             //                             Image {
    //             //                                 source: "/qmlimages/NewImages/takeoff.png"
    //             //                                 width: 50
    //             //                                 height: 50
    //             //                                 anchors.horizontalCenter: parent.horizontalCenter
    //             //                             }
    //             //                             Text {
    //             //                                 text: "Map Selection"
    //             //                                 color: "white"
    //             //                                 horizontalAlignment: Text.AlignHCenter
    //             //                                 font.bold: true
    //             //                                 anchors.horizontalCenter: parent.horizontalCenter
    //             //                             }
    //             //                         }
    //             //         background: Rectangle {
    //             //             color:  "white"//"#1b1c3e"
    //             //             radius: 8
    //             //         }
    //             //         onClicked: {
    //             //             console.log("Option 1 clicked")
    //             //             MapGlobals.edit = "edit"
    //             //             mainWindow.showPlanView()
    //             //             dialog.visible = false
    //             //             planView.data1()
    //             //         }
    //             //     }

    //             //     Button {
    //             //         //Layout.fillWidth: true
    //             //         Layout.alignment: Qt.AlignHCenter
    //             //         Layout.preferredWidth: parent.width* 0.2
    //             //         Layout.preferredHeight: parent.height * 0.4// Ensure height is taken from parent
    //             //         //text: "Drone GPS"
    //             //         contentItem: Column {
    //             //             width: parent.width
    //             //                     height: parent.height
    //             //                     spacing: 10
    //             //                     anchors.centerIn: parent
    //             //                             Image {
    //             //                                 source: "/qmlimages/NewImages/takeoff.png"
    //             //                                 width: 50
    //             //                                 height: 50
    //             //                                 anchors.horizontalCenter: parent.horizontalCenter
    //             //                             }
    //             //                             Text {
    //             //                                 text: "Drone GPS"
    //             //                                 color: "white"
    //             //                                 horizontalAlignment: Text.AlignHCenter
    //             //                                 font.bold: true
    //             //                                 anchors.horizontalCenter: parent.horizontalCenter
    //             //                             }
    //             //                         }
    //             //         background: Rectangle {
    //             //             color:  "white"//"#1b1c3e"
    //             //             radius: 8
    //             //         }
    //             //         onClicked: console.log("Option 2 clicked")
    //             //     }

    //             //     Button {
    //             //         //Layout.fillWidth: true
    //             //         Layout.alignment: Qt.AlignHCenter
    //             //         Layout.preferredWidth: parent.width* 0.2
    //             //         Layout.preferredHeight: parent.height * 0.4// Ensure height is taken from parent
    //             //         //text: "Load KML/SHP..."
    //             //         contentItem: Column {
    //             //             width: parent.width
    //             //                     height: parent.height
    //             //                     spacing: 10
    //             //                     anchors.centerIn: parent
    //             //                             Image {
    //             //                                 source: "/qmlimages/NewImages/takeoff.png"
    //             //                                 width: 50
    //             //                                 height: 50
    //             //                                 anchors.horizontalCenter: parent.horizontalCenter
    //             //                             }
    //             //                             Text {
    //             //                                 text: "Load KML/SHP..."
    //             //                                 color: "white"
    //             //                                 horizontalAlignment: Text.AlignHCenter
    //             //                                 font.bold: true
    //             //                                 anchors.horizontalCenter: parent.horizontalCenter
    //             //                             }
    //             //                         }
    //             //         background: Rectangle {
    //             //             color:  "white"//"#1b1c3e"
    //             //             radius: 8
    //             //         }
    //             //         onClicked: console.log("Option 2 clicked")
    //             //     }

    //         }
    //     }
    // }


    // onClicked: {
    // dialog.visible = true
    // MapGlobals.save = "save"
    // }

    Dialog {
        id: dialog
        modal: true
        dim: true
        anchors.centerIn: parent
        width: parent.width //* 0.8 // 80% of screen width
        height: parent.height // * 0.5 // 50% of screen height

        property alias mappingbtn: mappingbtn
        property alias mappingcirclebtn: mappingcirclebtn
        property alias agribtn: agribtn
        property alias agrigpsbtn: agrigpsbtn


        background: Rectangle {
            color: "transparent"
            radius: 10
            border.color: "white"
            border.width: 1
        }

        Platform.FileDialog {
            id: kmlFileDialog
            title: "Select KML File"
            nameFilters: ["KML files (*.kml)"]
            fileMode: Platform.FileDialog.OpenFile

            onAccepted: {
                console.log("Picked file (QUrl):", kmlFileDialog.file)

                if (kmlFileDialog.file && kmlFileDialog.file !== "") {
                    var fileStr = kmlFileDialog.file.toString()
                    console.log("Picked file string:", fileStr)

                    // Handle both file:// and content://
                    var localPath = ""
                    if (fileStr.startsWith("file://")) {
                        localPath = fileStr.replace("file://", "")
                    } else if (fileStr.startsWith("content://")) {
                        // On Android you get content:// URIs
                        localPath = fileStr   // keep as-is for now
                    }

                    console.log("Final Local Path:", localPath)

                    MapGlobals.kmlPath = localPath
                    MapGlobals.mark_with = "KML_File"
                    MapGlobals.edit = "edit"
                    MapGlobals.share_edit_visibility = false
                    mainWindow.showPlanView()
                    dialog.visible = false
                    planView.data1()
                } else {
                    console.log("No file selected")
                }
            }
        }


        // Close button in top-right corner
        Rectangle {
            id: closeBtn
            width: 30
            height: 30
            radius: width / 2
            color: "red"
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10

            Text {
                text: "X"
                color: "white"
                anchors.centerIn: parent
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked:{
                    dialog.visible = false
                    if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                        mainWindow.showFlyView()
                    }else if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
                        mainWindow.showMapping()
                    }



                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.9
            height: parent.height

            RowLayout {
                width: parent.width
                height: parent.height // Set explicit height for the row layout
                spacing: 20

                // Map Selection - Dark Blue
                Button {
                    id:mappingbtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.2
                    Layout.preferredHeight: parent.height * 0.4
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"?true:false

                    background: Rectangle {
                        id: mapping
                        color: "#1b2a49" // Dark Blue
                        radius: 12
                        border.width: width * 0.02
                        border.color: "#3b6ea5"
                        anchors.fill: parent
                    }

                    contentItem: Rectangle {
                        radius: mapping.radius
                        color: "transparent"
                        anchors.fill: parent

                        Column {
                            spacing: 8
                            anchors.centerIn: parent

                            Image {
                                source: "/qmlimages/NewImages/mapSelection.png"
                                width: 50
                                height: 50
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Basic"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    onClicked: {
                        planView.mapclear()
                        QGroundControl.saveGlobalSetting("mapping", "basic")
                        MapGlobals.mark_with = "Mark_With_Manual"
                        MapGlobals.edit = "edit"
                        MapGlobals.editdialog = "editdialog"
                        MapGlobals.share_edit_visibility = false
                        mainWindow.showPlanView()
                        dialog.visible = false
                        planView.data1()

                    }
                }

                // Drone - Dark Green
                Button {
                    id:mappingcirclebtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.2
                    Layout.preferredHeight: parent.height * 0.4
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"?true:false

                    background: Rectangle {
                        id: mappingcircle
                        color: "#1c3f2b" // Dark Green
                        radius: 12
                        border.width: width * 0.02
                        border.color: "#4CAF50"
                    }

                    contentItem: Rectangle {
                        radius: mappingcircle.radius
                        color: "transparent"
                        anchors.fill: parent

                        Column {
                            spacing: 8
                            anchors.centerIn: parent

                            Image {
                                source: "/qmlimages/NewImages/droneGpsMarking.png"
                                width: 50
                                height: 50
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Circular"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    onClicked: {
                        planView.mapclear()
                        QGroundControl.saveGlobalSetting("mapping", "circle")
                        MapGlobals.mark_with = "Mark_With_Manual"
                        MapGlobals.edit = "edit"
                        MapGlobals.editdialog = "editdialog"
                        MapGlobals.share_edit_visibility = false
                        mainWindow.showPlanView()
                        dialog.visible = false
                        planView.data1()
                    }
                }



                // Map Selection - Dark Blue
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.2
                    Layout.preferredHeight: parent.height * 0.4


                    background: Rectangle {
                        id: bgMap
                        color: "#1b2a49" // Dark Blue
                        radius: 12
                        border.width: width * 0.02
                        border.color: "#3b6ea5"
                        anchors.fill: parent
                    }

                    contentItem: Rectangle {
                        radius: bgMap.radius
                        color: "transparent"
                        anchors.fill: parent

                        Column {
                            spacing: 8
                            anchors.centerIn: parent

                            Image {
                                source: "/qmlimages/NewImages/mapSelection.png"
                                width: 50
                                height: 50
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Map Selection"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    onClicked: {
                        QGroundControl.saveGlobalSetting("mapping", "agri")
                        planView.mapclear()
                        MapGlobals.mark_with = "Mark_With_Manual"
                        MapGlobals.edit = "edit"
                        MapGlobals.editdialog = "editdialog"
                        MapGlobals.share_edit_visibility = false
                        mainWindow.showPlanView()
                        dialog.visible = false
                        planView.data1()

                    }
                }

                // Drone - Dark Green
                Button {
                    id:agribtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.2
                    Layout.preferredHeight: parent.height * 0.4
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"?true:false

                    background: Rectangle {
                        id: bgDrone
                        color: "#1c3f2b" // Dark Green
                        radius: 12
                        border.width: width * 0.02
                        border.color: "#4CAF50"
                    }

                    contentItem: Rectangle {
                        radius: bgDrone.radius
                        color: "transparent"
                        anchors.fill: parent

                        Column {
                            spacing: 8
                            anchors.centerIn: parent

                            Image {
                                source: "/qmlimages/NewImages/droneGpsMarking.png"
                                width: 50
                                height: 50
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Mark with Drone"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    onClicked: {

                        if(activeVehicle){
                            QGroundControl.saveGlobalSetting("mapping", "agri")
                            planView.mapclear()
                            MapGlobals.mark_with = "Mark_With_Drone"
                            MapGlobals.edit = "edit"
                            mainWindow.showPlanView()
                            dialog.visible = false
                            planView.data1()
                        }else {
                            dialog.visible = false
                            mainWindow.showToastMessage("Drone Not Connected");
                        }

                        MapGlobals.share_edit_visibility = false

                    }
                }

                // GPS - Dark Green
                Button {
                    id:agrigpsbtn
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.2
                    Layout.preferredHeight: parent.height * 0.4
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"?true:false

                    background: Rectangle {
                        id: bgGPS
                        color: "#1b2a49" // Dark Green
                        radius: 12
                        border.width: width * 0.02
                        border.color: "#3b6ea5"
                    }

                    contentItem: Rectangle {
                        radius: bgGPS.radius
                        color: "transparent"
                        anchors.fill: parent

                        Column {
                            spacing: 8
                            anchors.centerIn: parent

                            Image {
                                source: "/qmlimages/NewImages/droneGpsMarking.png"
                                width: 50
                                height: 50
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Mark with GPS"
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    onClicked: {
                        QGroundControl.saveGlobalSetting("mapping", "agri")
                        planView.mapclear()
                        MapGlobals.mark_with = "Mark_With_GPS"
                        MapGlobals.edit = "edit"
                        MapGlobals.share_edit_visibility = false
                        mainWindow.showPlanView()
                        dialog.visible = false
                        planView.data1()
                    }
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: parent.width * 0.2
                    Layout.preferredHeight: parent.height * 0.4

                    background: Rectangle {
                        id: bgKml
                        color: "#2e1437" // Dark Purple
                        radius: 12
                        border.width: width * 0.02
                        border.color: "#9b59b6"
                    }

                    contentItem: Rectangle {
                        radius: bgKml.radius
                        color: "transparent"
                        anchors.fill: parent

                        Column {
                            spacing: 8
                            anchors.centerIn: parent

                            Image {
                                source: "/qmlimages/NewImages/kmlFile.png"
                                width: 50
                                height: 50
                                fillMode: Image.PreserveAspectFit
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Load KML/SHP..."
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    onClicked: {
                        QGroundControl.saveGlobalSetting("mapping", "agri")
                        // MapGlobals.mark_with = "KML_File"
                        // MapGlobals.edit = "edit"
                        // mainWindow.showPlanView()
                        // dialog.visible = false
                        // planView.data1()
                        //kmlOrSHPLoadDialog.openForLoad()

                        // open native file dialog directly
                        kmlFileDialog.open()

                    }
                }

                // Button {
                // //Layout.fillWidth: true
                // Layout.alignment: Qt.AlignHCenter
                // Layout.preferredWidth: parent.width* 0.2
                // Layout.preferredHeight: parent.height* 0.4 // Ensure height is taken from parent
                // //text: "Map Selection"
                // contentItem: Column {
                // width: parent.width
                // height: parent.height
                // spacing: 10
                // anchors.centerIn: parent
                // Image {
                // source: "/qmlimages/NewImages/takeoff.png"
                // width: 50
                // height: 50
                // anchors.horizontalCenter: parent.horizontalCenter
                // }
                // Text {
                // text: "Map Selection"
                // color: "white"
                // horizontalAlignment: Text.AlignHCenter
                // font.bold: true
                // anchors.horizontalCenter: parent.horizontalCenter
                // }
                // }
                // background: Rectangle {
                // color:  "white"//"#1b1c3e"
                // radius: 8
                // }
                // onClicked: {
                // console.log("Option 1 clicked")
                // MapGlobals.edit = "edit"
                // mainWindow.showPlanView()
                // dialog.visible = false
                // planView.data1()
                // }
                // }

                // Button {
                // //Layout.fillWidth: true
                // Layout.alignment: Qt.AlignHCenter
                // Layout.preferredWidth: parent.width* 0.2
                // Layout.preferredHeight: parent.height * 0.4// Ensure height is taken from parent
                // //text: "Drone GPS"
                // contentItem: Column {
                // width: parent.width
                // height: parent.height
                // spacing: 10
                // anchors.centerIn: parent
                // Image {
                // source: "/qmlimages/NewImages/takeoff.png"
                // width: 50
                // height: 50
                // anchors.horizontalCenter: parent.horizontalCenter
                // }
                // Text {
                // text: "Drone GPS"
                // color: "white"
                // horizontalAlignment: Text.AlignHCenter
                // font.bold: true
                // anchors.horizontalCenter: parent.horizontalCenter
                // }
                // }
                // background: Rectangle {
                // color:  "white"//"#1b1c3e"
                // radius: 8
                // }
                // onClicked: console.log("Option 2 clicked")
                // }

                // Button {
                // //Layout.fillWidth: true
                // Layout.alignment: Qt.AlignHCenter
                // Layout.preferredWidth: parent.width* 0.2
                // Layout.preferredHeight: parent.height * 0.4// Ensure height is taken from parent
                // //text: "Load KML/SHP..."
                // contentItem: Column {
                // width: parent.width
                // height: parent.height
                // spacing: 10
                // anchors.centerIn: parent
                // Image {
                // source: "/qmlimages/NewImages/takeoff.png"
                // width: 50
                // height: 50
                // anchors.horizontalCenter: parent.horizontalCenter
                // }
                // Text {
                // text: "Load KML/SHP..."
                // color: "white"
                // horizontalAlignment: Text.AlignHCenter
                // font.bold: true
                // anchors.horizontalCenter: parent.horizontalCenter
                // }
                // }
                // background: Rectangle {
                // color:  "white"//"#1b1c3e"
                // radius: 8
                // }
                // onClicked: console.log("Option 2 clicked")
                // }

            }
        }

    }

    function _restorePreviousVertices() {
        mapPolygon.beginReset()
        mapPolygon.clear()
        for (var i=0; i<_savedVertices.length; i++) {
            mapPolygon.appendVertex(_savedVertices[i])
        }
        mapPolygon.endReset()
        _circleMode = _savedCircleMode
    }

    Component {

        id: toolSelectComponent

        ToolIndicatorPage {
            id:         toolSelectDialog
            //title:      qsTr("Select Tool")

            property real _toolButtonHeight:    ScreenTools.defaultFontPixelHeight * 3
            property real _margins:             ScreenTools.defaultFontPixelWidth

            contentComponent: Component {
                ColumnLayout {
                    width:  innerLayout.width + (toolSelectDialog._margins * 2)
                    height: innerLayout.height + (toolSelectDialog._margins * 2)

                    ColumnLayout {
                        id:             innerLayout
                        Layout.margins: toolSelectDialog._margins
                        spacing:        ScreenTools.defaultFontPixelWidth

                        SubMenuButton {
                            id:                 setupButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Vehicle Setup")
                            imageResource:      "/qmlimages/Gears.svg"
                            onClicked: {
                                if (!mainWindow.preventViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showVehicleSetupTool()
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 analyzeButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Analyze Tools")
                            imageResource:      "/qmlimages/Analyze.svg"
                            visible:            QGroundControl.corePlugin.showAdvancedUI
                            onClicked: {
                                if (!mainWindow.preventViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showAnalyzeTool()
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 settingsButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Application Settings")
                            imageResource:      "/res/QGCLogoFull"
                            imageColor:         "transparent"
                            visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
                            onClicked: {
                                if (!mainWindow.preventViewSwitch()) {
                                    drawer.close()
                                    mainWindow.showSettingsTool()
                                }
                            }
                        }

                        ColumnLayout {
                            width:                  innerLayout.width
                            spacing:                0
                            Layout.alignment:       Qt.AlignHCenter

                            QGCLabel {
                                id:                     versionLabel
                                text:                   qsTr("%1 Version").arg(QGroundControl.appName)
                                font.pointSize:         ScreenTools.smallFontPointSize
                                wrapMode:               QGCLabel.WordWrap
                                Layout.maximumWidth:    parent.width
                                Layout.alignment:       Qt.AlignHCenter
                            }

                            QGCLabel {
                                text:                   QGroundControl.qgcVersion
                                font.pointSize:         ScreenTools.smallFontPointSize
                                wrapMode:               QGCLabel.WrapAnywhere
                                Layout.maximumWidth:    parent.width
                                Layout.alignment:       Qt.AlignHCenter

                                QGCMouseArea {
                                    id:                 easterEggMouseArea
                                    anchors.topMargin:  -versionLabel.height
                                    anchors.fill:       parent

                                    onClicked: (mouse) => {
                                                   console.log("clicked")
                                                   if (mouse.modifiers & Qt.ControlModifier) {
                                                       QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                                       showTouchAreasNotification.open()
                                                   } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) {
                                                       if(!QGroundControl.corePlugin.showAdvancedUI) {
                                                           advancedModeOnConfirmation.open()
                                                       } else {
                                                           advancedModeOffConfirmation.open()
                                                       }
                                                   }
                                               }

                                    // This allows you to change this on mobile
                                    onPressAndHold: {
                                        QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                        showTouchAreasNotification.open()
                                    }

                                    MessageDialog {
                                        id:                 showTouchAreasNotification
                                        title:              qsTr("Debug Touch Areas")
                                        text:               qsTr("Touch Area display toggled")
                                        buttons:            MessageDialog.Ok
                                    }

                                    MessageDialog {
                                        id:                 advancedModeOnConfirmation
                                        title:              qsTr("Advanced Mode")
                                        text:               QGroundControl.corePlugin.showAdvancedUIMessage
                                        buttons:            MessageDialog.Yes | MessageDialog.No
                                        onButtonClicked: function (button, role) {
                                            switch (button) {
                                            case MessageDialog.Yes:
                                                QGroundControl.corePlugin.showAdvancedUI = true
                                                advancedModeOnConfirmation.close()
                                                break;
                                            }
                                        }
                                    }

                                    MessageDialog {
                                        id:                 advancedModeOffConfirmation
                                        title:              qsTr("Advanced Mode")
                                        text:               qsTr("Turn off Advanced Mode?")
                                        buttons:            MessageDialog.Yes | MessageDialog.No
                                        onButtonClicked: function (button, role) {
                                            switch (button) {
                                            case MessageDialog.Yes:
                                                QGroundControl.corePlugin.showAdvancedUI = false
                                                advancedModeOffConfirmation.close()
                                                break;
                                            case MessageDialog.No:
                                                resetPrompt.close()
                                                break;
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

    Component {
        id: toolSelectComponents

        ToolIndicatorPage {
            id:         toolSelectDialog
            //title:      qsTr("Select Tool")

            property real _toolButtonHeight:    ScreenTools.defaultFontPixelHeight * 3
            property real _margins:             ScreenTools.defaultFontPixelWidth

            contentComponent: Component {
                ColumnLayout {
                    width:  innerLayout.width + (toolSelectDialog._margins * 2)
                    height: innerLayout.height + (toolSelectDialog._margins * 2)

                    ColumnLayout {
                        id:             innerLayout
                        Layout.margins: toolSelectDialog._margins
                        spacing:        ScreenTools.defaultFontPixelWidth



                        SubMenuButton {
                            id:                 analyzeButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Altitude Hold")
                            imageResource:      "/res/ArrowRight.svg"
                            visible:            true
                            onClicked: {

                            }
                        }

                        SubMenuButton {
                            id:                 analyzeButton1
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Auto")
                            imageResource:      "/res/ArrowRight.svg"
                            visible:            true
                            onClicked: {

                            }
                        }

                        SubMenuButton {
                            id:                 analyzeButton2
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Loiter")
                            imageResource:      "/res/ArrowRight.svg"
                            visible:            true
                            onClicked: {

                            }
                        }

                        SubMenuButton {
                            id:                 analyzeButton7
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("ZigZag")
                            imageResource:      "/res/ArrowRight.svg"
                            visible:            true
                            onClicked: {

                            }
                        }
                    }
                }
            }
        }
    }


    Drawer {
        id:             toolDrawer
        width:          mainWindow.width
        height:         mainWindow.height
        edge:           Qt.LeftEdge
        dragMargin:     0
        closePolicy:    Drawer.NoAutoClose
        interactive:    false
        visible:        false

        property alias backIcon:    backIcon.source
        property alias toolTitle:   toolbarDrawerText.text
        property alias toolSource:  toolDrawerLoader.source
        property alias toolIcon:    toolIcon.source

        // Unload the loader only after closed, otherwise we will see a "blank" loader in the meantime
        onClosed: {
            toolDrawer.toolSource = ""
        }

        Rectangle {
            id:             toolDrawerToolbar
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         ScreenTools.toolbarHeight
            color:          qgcPal.toolbarBackground

            RowLayout {
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left:       parent.left
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCColoredImage {
                    id:                     backIcon
                    width:                  ScreenTools.defaultFontPixelHeight * 2
                    height:                 ScreenTools.defaultFontPixelHeight * 2
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    color:                  qgcPal.text
                }

                QGCLabel {
                    id:     backTextLabel
                    text:   qsTr("Back")
                }

                QGCLabel {
                    font.pointSize: ScreenTools.largeFontPointSize
                    text:           "<"
                }

                QGCColoredImage {
                    id:                     toolIcon
                    width:                  ScreenTools.defaultFontPixelHeight * 2
                    height:                 ScreenTools.defaultFontPixelHeight * 2
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    color:                  qgcPal.text
                }

                QGCLabel {
                    id:             toolbarDrawerText
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }

            QGCMouseArea {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                x:                  parent.mapFromItem(backIcon, backIcon.x, backIcon.y).x
                width:              (backTextLabel.x + backTextLabel.width) - backIcon.x
                onClicked: {
                    toolDrawer.visible      = false
                }
            }
        }

        Loader {
            id:             toolDrawerLoader
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    toolDrawerToolbar.bottom
            anchors.bottom: parent.bottom

            Connections {
                target:                 toolDrawerLoader.item
                ignoreUnknownSignals:   true
                onPopout:               toolDrawer.visible = false
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup

    // function showCriticalVehicleMessage(message) {
    //     indicatorPopup.close()
    //     if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
    //         // We received additional wanring message while an older warning message was still displayed.
    //         // When the user close the older one drop the message indicator tool so they can see the rest of them.
    //         criticalVehicleMessagePopup.dropMessageIndicatorOnClose = true
    //     } else {
    //         criticalVehicleMessagePopup.criticalVehicleMessage      = message
    //         criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false
    //         criticalVehicleMessagePopup.open()
    //     }
    // }

    Popup {
        id:                 criticalVehicleMessagePopup
        y:                  ScreenTools.defaultFontPixelHeight
        x:                  Math.round((mainWindow.width - width) * 0.5)
        width:              mainWindow.width  * 0.55
        height:             criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal:              false
        focus:              true
        closePolicy:        Popup.CloseOnEscape

        property alias  criticalVehicleMessage:        criticalVehicleMessageText.text
        property bool   dropMessageIndicatorOnClose:   false

        background: Rectangle {
            anchors.fill:   parent
            color:          qgcPal.alertBackground
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            border.color:   qgcPal.alertBorder
            border.width:   2

            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.top:                parent.top
                anchors.topMargin:          -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      vehicleWarningLabel.contentWidth + _margins
                height:                     vehicleWarningLabel.contentHeight + _margins

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 vehicleWarningLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Vehicle Error")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }

            Rectangle {
                id:                         additionalErrorsIndicator
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.bottom:             parent.bottom
                anchors.bottomMargin:       -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      additionalErrorsLabel.contentWidth + _margins
                height:                     additionalErrorsLabel.contentHeight + _margins
                visible:                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 additionalErrorsLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Additional errors received")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }
        }

        QGCLabel {
            id:                 criticalVehicleMessageText
            width:              criticalVehicleMessagePopup.width - ScreenTools.defaultFontPixelHeight
            anchors.centerIn:   parent
            wrapMode:           Text.WordWrap
            color:              qgcPal.alertText
            textFormat:         TextEdit.RichText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.dropMessageIndicatorOnClose) {
                    criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false;
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                    flyView.dropMessageIndicatorTool();
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Popups - deprecated, use Indicator Drawer instead

    function showIndicatorPopup(item, dropItem, dim = true) {
        indicatorPopup.currentIndicator = dropItem
        indicatorPopup.currentItem = item
        indicatorPopup.dim = dim
        indicatorPopup.open()
    }

    function hideIndicatorPopup() {
        indicatorPopup.close()
        indicatorPopup.currentItem = null
        indicatorPopup.currentIndicator = null
    }

    Popup {
        id:             indicatorPopup
        padding:        ScreenTools.defaultFontPixelWidth * 0.75
        modal:          true
        focus:          true
        dim:            false
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property var    currentItem:        null
        property var    currentIndicator:   null
        y:              ScreenTools.toolbarHeight

        background: Rectangle {
            width:  loader.width
            height: loader.height
            color:  Qt.rgba(0,0,0,0)
        }

        Loader {
            id:             loader
            onLoaded: {
                var centerX = mainWindow.contentItem.mapFromItem(indicatorPopup.currentItem, 0, 0).x - (loader.width * 0.5)
                if((centerX + indicatorPopup.width) > (mainWindow.width - ScreenTools.defaultFontPixelWidth)) {
                    centerX = mainWindow.width - indicatorPopup.width - ScreenTools.defaultFontPixelWidth
                }
                indicatorPopup.x = centerX
            }
        }

        onOpened: {
            loader.sourceComponent = indicatorPopup.currentIndicator
        }

        onClosed: {
            loader.sourceComponent = null
            indicatorPopup.currentIndicator = null
        }

    }

    //-------------------------------------------------------------------------
    //-- Indicator Drawer

    function showIndicatorDrawer(drawerComponent, indicatorItem) {
        indicatorDrawer.isRightAligned = false;
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.indicatorItem = indicatorItem
        indicatorDrawer.open()
    }
    function showIndicatorDrawer1(drawerComponent, indicatorItem) {
        indicatorDrawer.isRightAligned = true;
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.indicatorItem = indicatorItem
        indicatorDrawer.open()
    }

    function closeIndicatorDrawer() {
        indicatorDrawer.close()
    }

    Popup {
        id:             indicatorDrawer
        x:              isRightAligned ? mainWindow.contentItem.width - contentItem.implicitWidth - _margins : calcXPosition()
        y:              ScreenTools.toolbarHeight + _margins
        leftInset:      0
        rightInset:     0
        topInset:       0
        bottomInset:    0
        padding:        _margins * 2
        visible:        false
        modal:          true
        focus:          true
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var sourceComponent
        property var indicatorItem
        property bool isRightAligned: false
        property bool _expanded:    false
        property real _margins:     ScreenTools.defaultFontPixelHeight / 4

        function calcXPosition() {
            if (indicatorItem) {
                var xCenter = indicatorItem.mapToItem(mainWindow.contentItem, indicatorItem.width / 2, 0).x
                return Math.max(_margins, Math.min(xCenter - (contentItem.implicitWidth / 2), mainWindow.contentItem.width - contentItem.implicitWidth - _margins - (indicatorDrawer.padding * 2) - (ScreenTools.defaultFontPixelHeight / 2)))
            } else {
                return _margins
            }
        }

        onOpened: {
            _expanded                               = false;
            indicatorDrawerLoader.sourceComponent   = indicatorDrawer.sourceComponent
        }

        onClosed: {
            _expanded                               = false
            indicatorItem                           = undefined
            indicatorDrawerLoader.sourceComponent   = undefined
        }

        background: Item {

            Rectangle {
                id:             backgroundRect
                anchors.fill:   parent
                color:          "black"//QGroundControl.globalPalette.window
                radius:         indicatorDrawer._margins
                opacity:        0.85
            }

            Rectangle {
                anchors.horizontalCenter:   backgroundRect.right
                anchors.verticalCenter:     backgroundRect.top
                width:                      50//ScreenTools.defaultFontPixelHeight
                height:                     20//width
                radius:                     width / 2
                color:                      QGroundControl.globalPalette.button
                border.color:               QGroundControl.globalPalette.buttonText
                visible:                    activeVehicle ? false :indicatorDrawerLoader.item && indicatorDrawerLoader.item.showExpand && !indicatorDrawer._expanded

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               "More"
                    color:              QGroundControl.globalPalette.buttonText
                }

                QGCMouseArea {
                    fillItem: parent
                    onClicked: {
                        if(!activeVehicle){
                            //indicatorDrawer._expanded = true
                            mainWindow.showToolSelectDialog1(4)
                            mainWindow.closeIndicatorDrawer()
                        }else{
                            indicatorDrawer._expanded = true
                            //mainWindow.showToolSelectDialog1(4)
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }
        }

        contentItem: QGCFlickable {
            id:             indicatorDrawerLoaderFlickable
            implicitWidth:  Math.min(mainWindow.contentItem.width - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.width)
            implicitHeight: Math.min(mainWindow.contentItem.height - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.height)
            contentWidth:   indicatorDrawerLoader.width
            contentHeight:  indicatorDrawerLoader.height

            Loader {
                id: indicatorDrawerLoader

                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "expanded"
                    value:      indicatorDrawer._expanded
                }

                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "drawer"
                    value:      indicatorDrawer
                }
            }
        }
    }

    // We have to create the popup windows for the Analyze pages here so that the creation context is rooted
    // to mainWindow. Otherwise if they are rooted to the AnalyzeView itself they will die when the analyze viewSwitch
    // closes.

    function createrWindowedAnalyzePage(title, source) {
        var windowedPage = windowedAnalyzePage.createObject(mainWindow)
        windowedPage.title = title
        windowedPage.source = source
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width:      ScreenTools.defaultFontPixelWidth  * 100
            height:     ScreenTools.defaultFontPixelHeight * 40
            visible:    true

            property alias source: loader.source

            Rectangle {
                color:          QGroundControl.globalPalette.window
                anchors.fill:   parent

                Loader {
                    id:             loader
                    anchors.fill:   parent
                    onLoaded:       item.popped = true
                }
            }

            onClosing: {
                visible = false
                source = ""
            }
        }
    }

    Connections {
        target: activationbar
        function onActivationTriggered(value){
            _utmspSendActTrigger= value
        }
    }

    UTMSPActivationStatusBar {
        id:                         activationbar
        activationStartTimestamp:   UTMSPStateStorage.startTimeStamp
        activationApproval:         UTMSPStateStorage.showActivationTab && QGroundControl.utmspManager.utmspVehicle.vehicleActivation
        flightID:                   UTMSPStateStorage.flightID
        anchors.fill:               parent
    }
}
