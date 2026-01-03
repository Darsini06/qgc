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


    property string edit:""
    property string sessionDate: ""
    property string sessionStart: ""
    property string sessionEnd: ""
    property bool sessionSaved: false



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
                    MapGlobals.saveDroneSession(sessionDate, sessionStart, sessionEnd);
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

        // Reference Variable for MainRootWindow
        MapGlobals.rootWindow = mainWindow
        //MapGlobals.loginLoader = login
        //MapGlobals.newscreen   = newscreen
        MapGlobals.modeBtn1    = modebtn1

        //Initialize the Database and Create Tables
        MapGlobals.initDB()

        //profilelogin()
        MapGlobals.profile()

        //Print all Session Table Datas.Just For Reference
        MapGlobals.printSessionTable()

        if(_appSettings.screen==="Plan"){
            plan="Plan"
            console.log("NextScreen loaded with planType:", planType)
        }else{
            plan="Start"
            console.log("NextScreen loaded with planType: Start")
        }

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
        modebtn1.visible = false
        mainrootIcons.visible = false
        waypointbtn.visible = false

        //newscreen.visible = true
        mainWindow.openNewScreen()

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
        rtlbtn.visible = false
        planView.visible = false
        modebtn1.visible = false
        mainrootIcons.visible = false

        //newscreen.visible = false
        mainWindow.closeScreens();

        waypointbtn.visible = true
        flyView.visible = true
        takeoffbtn.visible = true
    }

    function showFlyView() {
        waypointbtn.visible = false
        camerabtn.visible = false
        MapGlobals.save = "save1"
        planbtn.visible = true
        listbtn.visible = true
        takeoffbtn.visible = true
        flyView.visible = true
        planView.visible = false

        //newscreen.visible = false
         mainWindow.closeScreens();

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

        //newscreen.visible = false
        mainWindow.closeScreens();

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

    function closefile() {
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

        //newscreen.visible = false
        mainWindow.closeScreens();

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

    // function profileScreen1(comesFrom) {
    //     console.log("profileScreen1==========")
    //     profileScreen.visible = comesFrom
    //     newscreen.visible = !comesFrom
    // }

    Component {
        id: simpleMessageDialogComponent

        QGCSimpleMessageDialog {
        }
    }

    // ListModel {
    //     id: userModel
    // }

    // Dialog {
    //     id: userDialog
    //     modal: true
    //     width: parent.width * 0.9
    //     height: parent.height * 0.6
    //     standardButtons: Dialog.Ok

    //     contentItem: ColumnLayout {
    //         anchors.fill: parent
    //         spacing: 10

    //         Label {
    //             text: "User List"
    //             font.bold: true
    //             font.pointSize: 16
    //             horizontalAlignment: Text.AlignHCenter
    //             Layout.alignment: Qt.AlignHCenter
    //         }

    //         ListView {
    //             id: userList
    //             Layout.fillWidth: true
    //             Layout.fillHeight: true
    //             model: userModel
    //             clip: true

    //             delegate: Rectangle {
    //                 width: userList.width
    //                 height: 50
    //                 color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"

    //                 Row {
    //                     anchors.verticalCenter: parent.verticalCenter
    //                     spacing: 10
    //                     padding: 10

    //                     Text {
    //                         text: id + " " + displayname
    //                         font.bold: true
    //                         color: "black"
    //                     }

    //                     Text {
    //                         text: "(" + username + " - " + email + ")"
    //                         color: "black"
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

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

    // // JavaScript function to read from DB
    // function loadUsersFromDB() {

    //     var db = MapGlobals.getDatabase();
    //     userModel.clear();
    //     db.transaction(function(tx) {
    //         var rs = tx.executeSql("SELECT * FROM users");
    //         console.log("inserted=========",rs)

    //         for (let i = 0; i < rs.rows.length; i++) {
    //             let row = rs.rows.item(i);
    //             console.log("inserted=========",row.username)
    //             userModel.append({
    //                                  id: row.id,
    //                                  username: row.username,
    //                                  displayname: row.displayname,
    //                                  email: row.email
    //                              });
    //         }

    //     });

    //     userDialog.open()
    // }

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
        visible:        false

    }


    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        false
        planType: plan
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    false
    }

    Loader {
        id: pageLoader
        anchors.fill: parent
    }



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


    function openWelcomeScreen() {
        pageLoader.source = "qrc:/qml/LoginPages/WelcomeScreen.qml"
    }

    function openNewScreen() {
        pageLoader.source = "qrc:/qml/Newscreen.qml"
    }

    function openProfileScreen() {
        pageLoader.source = "qrc:/qml/ProfileScreenNew.qml"
    }

    function closeScreens() {
        pageLoader.source = ""
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
        //         source: "/qmlimages/NewImages/takeOff.svg"
        //         width: parent.width * 0.5   // 60% of button size
        //         height: width
        //         anchors.centerIn: parent
        //         color: "white"
        //     }

        //     MouseArea {
        //         anchors.fill: parent
        //         onClicked: {
        //             myDialog.imageSource = "/qmlimages/NewImages/takeOff.svg"
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
                source: "/qmlimages/NewImages/takeOff.svg"
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
                    myDialog.imageSource = "/qmlimages/NewImages/takeOff.svg"
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
        property string imageSource: "/qmlimages/NewImages/takeOff.svg" // Default image
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
                                source: "/qmlimages/NewImages/kmlFile.svg"
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
                // source: "/qmlimages/NewImages/takeOff.svg"
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
                // source: "/qmlimages/NewImages/takeOff.svg"
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
                // source: "/qmlimages/NewImages/takeOff.svg"
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
