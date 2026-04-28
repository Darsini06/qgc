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
import QtQuick.Effects


import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap


import QGroundControl.UTMSP
import QGroundControl.Palette
import MapGlobals
import QtQuick.LocalStorage

import Qt.labs.folderlistmodel
import Qt.labs.platform as Platform

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

    property var    mapPolygon :                null


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
    property bool   showUTMIndicator: false
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

    property real screenWidth: width
    property real screenHeight: height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio

    property string droneType: QGroundControl.loadGlobalSetting("loadpage", "loadpage")

    // --- Dynamic Theming ---
    property color app_color: {
        if (droneType === "Agri")    return "#79AE6F" // Forest Green
        if (droneType === "Mapping") return "#4F9DDF" // Clear Blue
        if (droneType === "Camera")  return "#F39C12" // Sunset Orange
        return "#4A2C6D" // Professional Purple (Default)
    }

    property color accent_color: {
        if (droneType === "Agri")    return "#5D8A54" // Darker Green
        if (droneType === "Mapping") return "#347DBD" // Darker Blue
        if (droneType === "Camera")  return "#D35400" // Darker Orange
        return "#673AB7" // Vibrant Purple
    }

    function updateAppTheme(newMode) {
        droneType = newMode
        QGroundControl.saveGlobalSetting("loadpage", newMode)
        console.log("App Theme Updated to:", newMode)
    }

    property bool connecting_drone : false


    function dp(value) {
        return value * baseUnit;
    }



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

        MapGlobals.modeBtn1    = modebtn1

        // Initialize the Database and Create Tables
        MapGlobals.initDB()

        // Handle initial navigation
        MapGlobals.profile()

        // Print all Session Table Datas. Just For Reference
        // MapGlobals.printSessionTable()

        if(_appSettings.screen==="Plan"){
            plan="Plan"
            console.log("NextScreen loaded with planType:", planType)
        }else{
            plan="Start"
            console.log("NextScreen loaded with planType: Start")
        }
    }

    // Listen for permission granted signal to proceed on mobile devices
    Connections {
        target: QGroundControl.qgcPositionManager
        function onPermissionGranted() {
            if (MapGlobals.rootWindow) {
                console.log("Permission granted signal received, re-checking profile flow")
                MapGlobals.profile()
            } else {
                console.log("Permission granted signal received, but MapGlobals.rootWindow not set yet. Skipping.")
            }
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

    function fileload(file) {
        planView.newmapfile(file)
    }

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
        takeoffbtn.visible=_guidedController.showTakeoff || !_guidedController.showLand
    }

    function land(){
        rtlbtn.visible=false
        takeoffbtn.visible=_guidedController.showLand && !_guidedController.showTakeoff
    }

    function homescreen() {

        planbtn.visible =false
        listbtn.visible = false
        takeoffbtn.visible = false
        rtlbtn.visible = false
        flyView.visible = false
        planView.visible = false
        modebtn1.visible = false
        mainrootIcons.visible = false
        waypointbtn.visible = false

        //homescreen.visible = true
        mainWindow.openHomeScreen()

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

        //homescreen.visible = false
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

        //homescreen.visible = false
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

        //homescreen.visible = false
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

        //homescreen.visible = false
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
        showTool(qsTr("Application Settings"), "AppSettings.qml", "qrc:/qmlimages/NewImages/dronecommanderlogo.svg")
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

    function close_dialog_showToast(text) {
        sideDrawer.close()
        toastContainer.showToast(text)
    }

    function showToastMessage(text) {
        toastContainer.showToast(text)
    }

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
                color: app_color
                radius: 14
                antialiasing: true
                clip: true

                // mask lower corners → flat against content
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 14
                    color: app_color
                    radius: 0
                }

                Item {
                    anchors.fill: parent

                    QGCLabel {
                        id: titleLabel
                        text: dynamicCalDialog.dialogTitleText
                        anchors.centerIn: parent
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: "white"
                    }

                    MouseArea {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: parent.height
                        onClicked: dynamicCalDialog.close()

                        QGCColoredImage {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: "qrc:/res/XDelete.svg"
                            color: "white"
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
        parent: Overlay.overlay   // THIS IS THE KEY TO SHOW THE TOST UPPER IN ANY COMPONENTS
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20

        width: parent.width
        height: 40
        visible: false
        z: 10000

        Rectangle {
            id: toastBackground
            width: toastText.width + 40
            height: 40
            radius: 10
            color: "#323232"
            opacity: 0.9
            anchors.centerIn: parent

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
        if (flyView) flyView.visible = false
        if (planView) planView.visible = false
        pageLoader.source = "qrc:/qml/LoginPages/WelcomeScreen.qml"
    }

    function openHomeScreen() {
        pageLoader.source = "qrc:/qml/LoginPages/HomeScreen.qml"
    }

    function openProfileScreen() {
        pageLoader.source = "qrc:/qml/LoginPages/ProfileScreen.qml"
    }

    function logfiles() {
        pageLoader.source = "qrc:/qml/LoginPages/LogFiles.qml"
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
            ListElement { image: "/qmlimages/NewImages/settings.svg"; file: "GeneralSettings.qml"; title: "General Settings" }
            ListElement { image: "qrc:/InstrumentValueIcons/globe.svg"; file: "AirspaceSettings.qml"; title: "Airspace" }
            ListElement { image: "/qmlimages/NewImages/failsafe.svg"; file: "APMSafetyComponent.qml"; title: "Fail Safe" }
            ListElement { image: "/qmlimages/NewImages/callibration.png"; file: "APMSensorsComponent.qml"; title: "Calibration" }
            //ListElement { image: "/qmlimages/NewImages/parameterSettings.svg"; file: "BasicParameters.qml"; title: "Parameters" }
            ListElement { image: "/qmlimages/FirmwareUpgradeIcon.png"; file: "FirmwareUpgrade.qml"; title: "Firmware" }
            //ListElement { image: "/qmlimages/NewImages/commlinks.svg"; file: "LinkSettings.qml"; title: "Info" }

            // Update when activeVehicle changes
            // onActiveVehicleChanged: {
            //     updateSettingsTab();
            // }

            Component.onCompleted: {
                updateSettingsTab();
            }

            function updateSettingsTab() {
                if (activeVehicle) {

                    tabModel.setProperty(3, "file", "qrc:/qml/SettingsPanel/CalibrationSettings.qml");

                } else {
                    tabModel.setProperty(3, "file", "APMSensorsComponent.qml");
                }
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            spacing: 0

            /* ================= HEADER ================= */
            Rectangle {
                Layout.preferredHeight: 44
                Layout.fillWidth: true
                color: app_color

                // Back Button (LEFT)
                QGCColoredImage {
                    id: backArrow
                    width: 25
                    height: 25
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    color: "white"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sideDrawer.close()
                    }
                }

                // CENTER TITLE (TRUE CENTER)
                Text {
                    text: "Settings"
                    anchors.centerIn: parent
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true
                    color: "white"
                }
            }

            // --- MAIN NAVIGATION AREA ---
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                /* ================= SIDEBAR NAVIGATION ================= */
                Rectangle {
                    Layout.preferredWidth: ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 20 : ScreenTools.defaultFontPixelWidth * 28
                    Layout.fillHeight: true
                    color: "#f8f9fa" // Light aesthetic sidebar
                    
                    // Sidebar Right Border
                    Rectangle {
                        anchors.right: parent.right
                        width: 1
                        height: parent.height
                        color: "#E0E0E0"
                    }

                    ListView {
                        id: sidebarList
                        anchors.fill: parent
                        model: tabModel
                        currentIndex: tabBarDummy.currentIndex // Sync with dummy for compatibility if needed
                        clip: true
                        topMargin: 20
                        spacing: 2
                        
                        // Fake TabBar for index tracking and logic preservation
                        TabBar { id: tabBarDummy; visible: false; currentIndex: 0 }

                        delegate: Item {
                            width: parent.width
                            height: 60
                            
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 8
                                color: sidebarList.currentIndex === index ? Qt.rgba(38, 38, 38, 0.1) : "transparent"
                                
                                Behavior on color { ColorAnimation { duration: 200 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 15
                                    spacing: 12

                                    QGCColoredImage {
                                        width: 20
                                        height: 20
                                        source: model.image
                                        color: sidebarList.currentIndex === index ? app_color : "#666666"
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.title
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.bold: sidebarList.currentIndex === index
                                        color: sidebarList.currentIndex === index ? app_color : "#444444"
                                    }
                                    
                                    // Selection Indicator (vertical line)
                                    Rectangle {
                                        width: 4
                                        height: 24
                                        radius: 2
                                        color: app_color
                                        visible: sidebarList.currentIndex === index
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        sidebarList.currentIndex = index
                                        tabBarDummy.currentIndex = index
                                        loaders.source = model.file
                                    }
                                }
                            }
                        }
                    }
                }

                /* ================= SETTINGS CONTENT AREA ================= */
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "white"

                    Loader {
                        id: loaders
                        anchors.fill: parent
                        anchors.margins: 15
                        source: tabModel.get(sidebarList.currentIndex).file
                    }

                    Item {
                        id: drone_loading
                        anchors.fill: parent
                        visible: connecting_drone
                        z: 100

                        // Blocks ALL touch/mouse input when the loading screen is enabled
                        MouseArea {
                            anchors.fill: parent
                            enabled: drone_loading.visible

                            // propagateComposedEvents: false is actually the default, but stating it explicitly
                            // makes the intent clear and protects against any parent-level event forwarding that
                            // might be configured elsewhere in QGC's codebase.
                            propagateComposedEvents: false

                            onClicked: {}
                            onPressed: {}
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "#80000000"
                        }

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: drone_loading.visible
                        }
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
        id: columnbtn
        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.8
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.5
        spacing: ScreenTools.defaultFontPixelHeight * 1.2
        visible: true

        readonly property real _btnSize: ScreenTools.defaultFontPixelHeight * 2.2
        readonly property real _iconSize: _btnSize * 0.55
        Rectangle {
            id:         utmIndicatorBtn
            Layout.alignment: Qt.AlignLeft
            width:      columnbtn._btnSize
            height:     width
            radius:     width / 2
            color:      "white"
            visible:    false
            border.width: width * 0.05
            border.color: "white"

            QGCColoredImage {
                source:             "/qmlimages/PaperPlane.svg"
                width:              columnbtn._iconSize
                height:             width
                anchors.centerIn:   parent
                color:              showUTMIndicator ? "green" : "black"
            }

            MouseArea {
                anchors.fill:       parent
                onClicked:          showUTMIndicator = !showUTMIndicator
            }
        }

        Rectangle {
            id: listbtn
            Layout.alignment: Qt.AlignLeft
            width:  columnbtn._btnSize
            height: width                 // Keep it square
            radius: width / 2            // Circle
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible: false
            border.width: 0
            border.color:  "transparent"

            QGCColoredImage {
                id: flightModeIndicator2
                source: "/qmlimages/NewImages/savefile.svg" //"/qmlimages/NewImages/log.png"
                width:  columnbtn._iconSize
                height: width
                anchors.centerIn: parent
                //color: "transparent"
                color : "white"
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
        //     color:  "white"//"#301934"
        //     visible: true
        //     border.width: width * 0.05    // 10% of button width
        //     border.color:  "white"//"#005BBB"

        //     QGCColoredImage {
        //         id: takeofficon
        //         source: "/qmlimages/PaperPlane.svg"
        //         width: parent.width * 0.5   // 60% of button size
        //         height: width
        //         anchors.centerIn: parent
        //         color: "white"
        //     }

        //     MouseArea {
        //         anchors.fill: parent
        //         onClicked: {
        //             myDialog.imageSource = "/qmlimages/PaperPlane.svg"
        //             myDialog.dialogText = "settings"
        //             myDialog.open()
        //         }
        //     }
        // }

        Rectangle {
            id: takeoffbtn
            Layout.alignment: Qt.AlignLeft
            width: columnbtn._btnSize
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible:  false
            border.width: 0
            border.color:  "transparent"

            QGCColoredImage {
                id: takeofficon
                source: "/qmlimages/PaperPlane.svg"
                width: columnbtn._iconSize
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    //guidedValueSlider.visible = true
                    myDialog.imageSource = "/qmlimages/PaperPlane.svg"
                    myDialog.dialogText = "settings"
                    myDialog.open()
                }
            }
        }

        Rectangle {
            id: waypointbtn
            Layout.alignment: Qt.AlignLeft
            width: columnbtn._btnSize
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible:  false
            border.width: 0
            border.color:  "transparent"

            QGCColoredImage {
                id: waypointbtnicon1
                source: "/qmlimages/MapAddMission.svg"
                width: columnbtn._iconSize
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "white"
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
        //     color:  "white"//"#301934"      // white background
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
            width: columnbtn._btnSize
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible:  false
            border.width: 0
            border.color:  "transparent"

            QGCColoredImage {
                id: camerabtnicon
                source: "/qmlimages/PaperPlane.svg"
                width: columnbtn._iconSize
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "white"
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    // //whatsappImageSlider.visible=true
                    // mainWindow.showToastMessage("Camera clicked");
                    myDialog.imageSource = "/qmlimages/PaperPlane.svg"
                    myDialog.dialogText = "settings"
                    myDialog.open()
                }
            }
        }

        Rectangle {
            id: landbtn
            Layout.alignment: Qt.AlignLeft
            width: columnbtn._btnSize
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible:  false
            border.width: 0
            border.color:  "transparent"

            QGCColoredImage {
                id: landbtnicon
                source: "/qmlimages/NewImages/return.svg"
                width: columnbtn._iconSize
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "white"
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
            width: columnbtn._btnSize
            height: width                 // Keep it square
            radius: width / 2   // Makes it a circle
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible:  false
            border.width: 0
            border.color:  "transparent"

            QGCColoredImage {
                id: rtlbtnicon
                source: "/qmlimages/NewImages/landing.png"
                width: columnbtn._iconSize
                height: width
                anchors.centerIn: parent
                //color: "white"
                color : "white"
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
            color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black
            visible: false // Only visible in toolbar per user request

            border.width: 0
            border.color:  "transparent"

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
                    color: "black"
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Dialog {
        id: myDialog
        width: myDialog.dialogText === "settings" ? 340 : 260
        height: myDialog.dialogText === "settings" ? 220 : 190
        property string imageSource: "/qmlimages/PaperPlane.svg"
        property string dialogText: "Default Text"

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: false
        dim: false
        closePolicy: Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 20
            color: Qt.rgba(0, 0, 0, 0.65)
            border.width: 1
            border.color: "white"
        }

        QtObject {
            id: progressState
            property real value: 0.0
        }

        QtObject {
            id: takeoffSettings
            property real sliderOutputValue: 2.0
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 8

            // --- Top Area (Altitude Settings Header / Normal Header) ---
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: myDialog.dialogText === "settings" ? qsTr("Take off altitude") : myDialog.dialogText
                color: "white"
                font.pointSize: 12
                font.bold: true
            }

            // --- Altitude Controls ---
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 25
                visible: myDialog.dialogText === "settings"

                // Minus Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                    border.color: "white"
                    
                    Text {
                        text: "-"
                        color: "white"
                        font.pointSize: 16
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -2
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

                // Altitude Value
                Text {
                    text: takeoffSettings.sliderOutputValue.toFixed(1) + " m"
                    color: "white"
                    font.pointSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                // Plus Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                    border.color: "white"

                    Text {
                        text: "+"
                        color: "white"
                        font.pointSize: 16
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
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

            Item { Layout.fillHeight: true }

            // --- Bottom Area (Action Button) ---
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 90
                height: 90

                Rectangle {
                    id: circularButton
                    anchors.fill: parent
                    radius: 45
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.width: 1
                    border.color: "white"
                    
                    Canvas {
                        id: progressCircle
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.beginPath()
                            ctx.arc(width/2, height/2, 45, -Math.PI/2, (2 * Math.PI * progressState.value) - Math.PI/2, false)
                            ctx.lineWidth = 4
                            ctx.strokeStyle = "#79AE6F"
                            ctx.stroke()
                        }
                    }

                    QGCColoredImage {
                        source: myDialog.imageSource
                        width: 40
                        height: 40
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                        color: "white"
                    }

                    MouseArea {
                        id: holdArea
                        anchors.fill: parent
                        onPressed: progressTimer.start()
                        onReleased: {
                            progressTimer.stop()
                            progressState.value = 0
                            progressCircle.requestPaint()
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("press & hold to confirm")
                color: "#dddddd"
                font.pointSize: 10
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
            rtlbtn.visible=false
            takeoffbtn.visible=true

        }

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
            width: 48
            height: 48
            radius: width / 2
            color:  Qt.rgba(0, 0, 0, 0.40)      // More transparent black toolbars button
            visible: plan === "Plan"

            Text {
                text: "+"
                color: "white"
                anchors.centerIn: parent
                font.bold: true
                font.pointSize: 24
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

    // ── Full-screen Mission Type Selector ────────────────────────────────────
    // Single Rectangle covers 100% of the window — no popup, no scroll, no crop.
    Rectangle {
        id: dialog
        anchors.fill: parent
        visible: false
        z: 999                 // Ensure it covers toolbar/FlyView completely
        color: "#0d0d0f"

        // Block background clicks
        MouseArea {
            anchors.fill: parent
            onClicked: {}
            onDoubleClicked: {}
            onWheel: { wheel.accepted = true }
        }

        // Smooth fade-in
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        opacity: visible ? 1 : 0

        Rectangle {
            anchors.fill: parent
            opacity: 0.18
            gradient: Gradient {
                GradientStop { position: 0.0; color: app_color }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: app_color }
            }
        }

        // Properties exposed for external visibility control (legacy callers)
        property alias mappingbtn:      mappingbtn
        property alias mappingcirclebtn: mappingcirclebtn
        property alias agribtn:         agribtn
        property alias agrigpsbtn:      agrigpsbtn

        Platform.FileDialog {
            id: kmlFileDialog
            title: "Select KML File"
            nameFilters: ["KML files (*.kml)"]
            fileMode: Platform.FileDialog.OpenFile

            onAccepted: {
                if (kmlFileDialog.file && kmlFileDialog.file !== "") {
                    var fileStr   = kmlFileDialog.file.toString()
                    var localPath = ""
                    if (fileStr.startsWith("file://"))
                        localPath = fileStr.replace("file://", "")
                    else if (fileStr.startsWith("content://"))
                        localPath = fileStr

                    MapGlobals.kmlPath             = localPath
                    MapGlobals.mark_with           = "KML_File"
                    MapGlobals.edit                = "edit"
                    MapGlobals.share_edit_visibility = true
                    mainWindow.showPlanView()
                    dialog.visible = false
                    planView.data1()
                }
            }
        }

        // ── Close button ─────────────────────────────────────────────────────
        Rectangle {
            id: closeBtn
            width:  ScreenTools.minTouchPixels
            height: width
            radius: width / 2
            color:  "transparent"
            border.color: "white"
            border.width: 1
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1.5
            z: 10

            Text {
                text: "\u00d7"
                color: "white"
                font.pixelSize: ScreenTools.mediumFontPointSize * 2
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked: {
                    dialog.visible = false
                    if (QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Agri")
                        mainWindow.showFlyView()
                    else if (QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Mapping")
                        mainWindow.showMapping()
                }
                onEntered: closeBtn.color = "#cc4444"
                onExited:  closeBtn.color = "transparent"
            }
        }

        // ── Centered content ─────────────────────────────────────────────────
        ColumnLayout {
            id: contentCol
            anchors.centerIn: parent
            // Small centered group
            width:   Math.min(parent.width * 0.85, ScreenTools.defaultFontPixelWidth * 85)
            spacing: ScreenTools.defaultFontPixelHeight * 1.8

            // Header
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight * 0.4
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: "SELECT MISSION TYPE"
                    color: "white"
                    font.pointSize:   ScreenTools.largeFontPointSize * 1.2
                    font.bold:        true
                    font.letterSpacing: 2
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: contentCol.width
                }

                Rectangle {
                    width: 60; height: 3
                    color: app_color; radius: 2
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // ── Card row ─────────────────────────────────────────────────────
            // All visible cards share the width equally — single horizontal row.
            RowLayout {
                id: cardsRow
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 2

                // Card 1: Basic Mapping
                Rectangle {
                    id: mappingbtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: width
                    radius: 18
                    color:         ma1.containsMouse ? "#1e1e1e" : "#161616"
                    border.color:  ma1.containsMouse ? app_color : "#2e2e2e"
                    border.width:  ma1.containsMouse ? 2 : 1
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Mapping"

                    Column {
                        anchors.centerIn: parent
                        spacing: parent.height * 0.08
                        width: parent.width * 0.85

                        Rectangle {
                            width: parent.width * 0.55; height: width; radius: width / 2
                            color: ma1.containsMouse ? app_color : "#252525"
                            anchors.horizontalCenter: parent.horizontalCenter

                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/basic_marking.svg";
                                width: parent.width * 0.55; height: width
                                color: "white"; anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Text {
                            text: "Basic"; color: "white"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold: true; wrapMode: Text.WordWrap
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: ma1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            planView.mapclear()
                            QGroundControl.saveGlobalSetting("mapping", "basic")
                            MapGlobals.mark_with = "Mark_With_Manual"
                            MapGlobals.edit = "edit"
                            MapGlobals.editdialog = "editdialog"
                            MapGlobals.share_edit_visibility = true

                            //Grid Lines set to false
                            MapGlobals.setGridLines(false)

                            mainWindow.showPlanView()
                            dialog.visible = false
                            planView.data1()
                        }
                    }
                }

                // Card 2: Circular Mapping
                Rectangle {
                    id: mappingcirclebtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: width
                    radius: 18
                    color:         ma2.containsMouse ? "#1e1e1e" : "#161616"
                    border.color:  ma2.containsMouse ? app_color : "#2e2e2e"
                    border.width:  ma2.containsMouse ? 2 : 1
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Mapping"

                    Column {
                        anchors.centerIn: parent
                        spacing: parent.height * 0.08
                        width: parent.width * 0.75
                        Rectangle {
                            width: parent.width * 0.55; height: width; radius: width / 2
                            color: ma2.containsMouse ? app_color : "#252525"
                            anchors.horizontalCenter: parent.horizontalCenter
                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/circle_marking.svg"
                                width: parent.width * 0.6; height: width
                                color: "white"; anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                        Text {
                            text: "Circular"; color: "white"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold: true; wrapMode: Text.WordWrap
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        id: ma2; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            planView.mapclear()
                            QGroundControl.saveGlobalSetting("mapping", "circle")
                            MapGlobals.mark_with = "Mark_With_Manual"
                            MapGlobals.edit = "edit"; MapGlobals.editdialog = "editdialog"
                            MapGlobals.share_edit_visibility = true

                            //Grid Lines set to false
                            MapGlobals.setGridLines(false)

                            mainWindow.showPlanView(); dialog.visible = false; planView.data1()
                        }
                    }
                }

                // Card 3: Map Selection  (always visible)
                Rectangle {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: width
                    radius: 18
                    color:         ma3.containsMouse ? "#1e1e1e" : "#161616"
                    border.color:  ma3.containsMouse ? app_color : "#2e2e2e"
                    border.width:  ma3.containsMouse ? 2 : 1

                    Column {
                        anchors.centerIn: parent
                        spacing: parent.height * 0.08
                        width: parent.width * 0.75
                        Rectangle {
                            width: parent.width * 0.55; height: width; radius: width / 2
                            color: ma3.containsMouse ? app_color : "#252525"
                            anchors.horizontalCenter: parent.horizontalCenter
                            QGCColoredImage {
                                source: "/qmlimages/NewImages/map_selection.svg"
                                width: parent.width * 0.6; height: width
                                color: "white"; anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                        Text {
                            text: "Map Selection"; color: "white"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold: true; wrapMode: Text.WordWrap
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        id: ma3; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            QGroundControl.saveGlobalSetting("mapping", "agri")
                            planView.mapclear()
                            MapGlobals.mark_with = "Mark_With_Manual"
                            MapGlobals.edit = "edit"; MapGlobals.editdialog = "editdialog"
                            MapGlobals.share_edit_visibility = true

                            //Grid Lines set to false
                            MapGlobals.setGridLines(false)

                            mainWindow.showPlanView(); dialog.visible = false; planView.data1()
                        }
                    }
                }

                // Card 4: Mark with Drone
                Rectangle {
                    id: agribtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: width
                    radius: 18
                    color:         ma4.containsMouse ? "#1e1e1e" : "#161616"
                    border.color:  ma4.containsMouse ? app_color : "#2e2e2e"
                    border.width:  ma4.containsMouse ? 2 : 1
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Agri"

                    Column {
                        anchors.centerIn: parent
                        spacing: parent.height * 0.08
                        width: parent.width * 0.75
                        Rectangle {
                            width: parent.width * 0.55; height: width; radius: width / 2
                            color: ma4.containsMouse ? app_color : "#252525"
                            anchors.horizontalCenter: parent.horizontalCenter
                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/mark_with_drone.svg"
                                width: parent.width * 0.6; height: width
                                color: "white"; anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                        Text {
                            text: "Mark with Drone"; color: "white"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold: true; wrapMode: Text.WordWrap
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        id: ma4; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (activeVehicle) {
                                QGroundControl.saveGlobalSetting("mapping", "agri")
                                planView.mapclear()
                                MapGlobals.mark_with = "Mark_With_Drone"
                                MapGlobals.edit = "edit"

                                //Grid Lines set to false
                                MapGlobals.setGridLines(false)

                                mainWindow.showPlanView(); dialog.visible = false; planView.data1()
                            } else {
                                dialog.visible = false
                                mainWindow.showToastMessage("Drone Not Connected")
                            }
                            MapGlobals.share_edit_visibility = true
                        }
                    }
                }

                // Card 5: Mark with GPS
                Rectangle {
                    id: agrigpsbtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: width
                    radius: 18
                    color:         ma5.containsMouse ? "#1e1e1e" : "#161616"
                    border.color:  ma5.containsMouse ? app_color : "#2e2e2e"
                    border.width:  ma5.containsMouse ? 2 : 1
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Agri"

                    Column {
                        anchors.centerIn: parent
                        spacing: parent.height * 0.08
                        width: parent.width * 0.75
                        Rectangle {
                            width: parent.width * 0.55; height: width; radius: width / 2
                            color: ma5.containsMouse ? app_color : "#252525"
                            anchors.horizontalCenter: parent.horizontalCenter
                            QGCColoredImage {
                                source: "/qmlimages/NewImages/mark_with_gps.svg"
                                width: parent.width * 0.6; height: width
                                color: "white"; anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                        Text {
                            text: "Mark with GPS"; color: "white"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold: true; wrapMode: Text.WordWrap
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        id: ma5; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            QGroundControl.saveGlobalSetting("mapping", "agri")
                            planView.mapclear()
                            MapGlobals.mark_with = "Mark_With_GPS"
                            MapGlobals.edit = "edit"
                            MapGlobals.share_edit_visibility = true

                            //Grid Lines set to false
                            MapGlobals.setGridLines(false)

                            mainWindow.showPlanView(); dialog.visible = false; planView.data1()
                        }
                    }
                }

                // Card 6: Load KML/SHP  (always visible)
                Rectangle {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: width
                    radius: 18
                    color:         ma6.containsMouse ? "#1e1e1e" : "#161616"
                    border.color:  ma6.containsMouse ? app_color : "#2e2e2e"
                    border.width:  ma6.containsMouse ? 2 : 1

                    Column {
                        anchors.centerIn: parent
                        spacing: parent.height * 0.08
                        width: parent.width * 0.75
                        Rectangle {
                            width: parent.width * 0.55; height: width; radius: width / 2
                            color: ma6.containsMouse ? app_color : "#252525"
                            anchors.horizontalCenter: parent.horizontalCenter
                            QGCColoredImage {
                                source: "/qmlimages/NewImages/kmlFile.svg"
                                width: parent.width * 0.6; height: width
                                color: "white"; anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                        Text {
                            text: "Load KML/SHP..."; color: "white"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold: true; wrapMode: Text.WordWrap
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    MouseArea {
                        id: ma6; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: kmlFileDialog.open()
                    }
                }

            } // end RowLayout (cardsRow)
        } // end ColumnLayout (contentCol)

    } // end Rectangle (dialog)


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
                            imageResource:      "qrc:/qmlimages/NewImages/dronecommanderlogo.svg"
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
        padding:        0
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

        background: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.4) // Modern Semi-Transparent Background
            radius: 12
            border.color: "#3d3d3d"
            border.width: 1
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
        visible:                    showUTMIndicator
        anchors.fill:               parent
    }
}
