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
import QGroundControl.Controllers
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

//=============================
import QGroundControl.FlightMap

import QtLocation
import QtPositioning
import QtQuick.Window
import Qt.labs.settings 1.0

import QGroundControl.FactSystem

import QGroundControl.ShapeFileHelper
import QGroundControl.FlightDisplay
import QGroundControl.UTMSP
//================================

Item {
    id: logfiles
    anchors.fill: parent
    property string currentView: MapGlobals.currentView_profile

    property string userName: QGroundControl.loadGlobalSetting("username", "")
    property string displayName: QGroundControl.loadGlobalSetting("name", "")
    property string userEmail: QGroundControl.loadGlobalSetting("email", "")

    property string name_from_db: ""
    property string mobileNo_from_db: ""
    property string email_from_db: ""
    property int rpcCompletedStatus: -1

    //==================================
    property var  _planMasterController:  planMasterController
    property var  nameFilters:            []
    property var  _missionController:     _planMasterController.missionController
    //================================

    property string selectedImage: ""

    property real iconBaseSize: Math.min(Screen.width, Screen.height) * 0.1

    property int totalMinutes: 0
    property int missionsCompleted: 0
    property string totalDurationFormatted: "0h 0m"
    property color app_color: MapGlobals.comefrom === "Profile" ? "#262626" : mainWindow.app_color
    signal backClicked()

    property bool privacyLoading: true

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio

    //========================================================================
    property var    _appSettings:  QGroundControl.settingsManager.appSettings
    property string folder:        _appSettings ? _appSettings.missionSavePath : ""
    property bool   _openForLoad:  true
    property real   _margins:      ScreenTools.defaultFontPixelHeight / 2
    property bool   _mobileDlg:    QGroundControl.corePlugin.options.useMobileFileDialog
    property var    _rgExtensions
    property string _mobileShortPath
    //===========================================================================================

    function dp(value) {
        return value * baseUnit;
    }

    ListModel {
        id: sessionModel
    }

    Connections {
        target: MapGlobals

        onNewSessionAdded: {
            console.log("New session added, refreshing...");
            loadSessions();
        }
    }

    Component.onCompleted: {
        if (userName !== "") {
            userName = QGroundControl.loadGlobalSetting("username", "")
            loadUserDataFromMain();
        }

        _planMasterController._updateMobileShortPath()
        _planMasterController._setupFileExtensions()
    }

    onVisibleChanged: {
        if (visible) {
            console.log("onVisibleChanged");
            loadSessions();

            displayName = QGroundControl.loadGlobalSetting("name", "")
            userName    = QGroundControl.loadGlobalSetting("username", "")
            userEmail   = QGroundControl.loadGlobalSetting("email", "")

            if (userName !== "") {
                console.log("onVisibleUserName : ", userName);
                loadUserDataFromMain();
            }
        }
    }

    onCurrentViewChanged: {
        console.log("onCurrentViewChanged")

        displayName = QGroundControl.loadGlobalSetting("name", "")
        userName    = QGroundControl.loadGlobalSetting("username", "")
        userEmail   = QGroundControl.loadGlobalSetting("email", "")

        if (currentView === "reports") {
            console.log("Switched to Reports view")
            loadSessions()
        } else if (currentView === "privacy_policy") {
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
                    id:         session.id,
                    date:       session.date,
                    start_time: session.start_time,
                    end_time:   session.end_time,
                    duration:   session.duration || 0,
                    created_at: session.created_at
                });
            }

            console.log("Loaded", sessions.length, "sessions into model");

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

        totalMinutes      = total;
        missionsCompleted = sessionModel.count;

        var hours   = Math.floor(total / 60);
        var minutes = total % 60;
        totalDurationFormatted = hours + "h " + minutes + "m";

        console.log("== Session Stats ==");
        console.log("Total Duration:", totalDurationFormatted);
        console.log("Missions Completed:", missionsCompleted);
    }

    function loadUserDataFromMain() {
        MapGlobals.loadUserData(userName, function(userData) {
            if (userData) {
                name_from_db      = userData.displayname    || "";
                mobileNo_from_db  = userData.mobile_number  || "";
                email_from_db     = userData.email          || "";
                rpcCompletedStatus = (userData.rpc_completed !== undefined && userData.rpc_completed !== null)
                        ? Number(userData.rpc_completed)
                        : -1;

                console.log("Data retrieved - Name:", name_from_db,
                            "Email:", email_from_db,
                            "Mobile:", mobileNo_from_db,
                            "RPC Status:", rpcCompletedStatus);
                console.log("Type of rpc_completed:", typeof userData.rpc_completed)
            } else {
                console.log("No user data received");
                name_from_db      = "";
                mobileNo_from_db  = "";
                email_from_db     = "";
                rpcCompletedStatus = -1;
            }
        });
    }

    function to12Hour(time24) {
        if (!time24) return "";
        var parts = time24.split(":");
        if (parts.length < 2) return time24;

        var hour   = parseInt(parts[0]);
        var minute = parts[1];
        var second = parts[2] || "00";
        var ampm   = hour >= 12 ? "PM" : "AM";
        hour = hour % 12;
        if (hour === 0) hour = 12;

        var formatted = hour.toString().padStart(2, '0') + ":" + minute + ":" + second + " " + ampm;
        return formatted;
    }

    function switchPage(newView) {
        fadeOverlay.opacity = 1
        fadeTimer.newView   = newView
        fadeTimer.start()
    }

    //========================================================
    PlanMasterController {
        id:      planMasterController
        flyView: false

        function loadFromSelectedFile() {
            _updateMobileShortPath()
            _setupFileExtensions()
            nameFilters = _planMasterController.loadNameFilters1
            openForLoad()
        }

        function loadFromSelectedFile1() {
            fileDialog.title       = qsTr("Select Plan File")
            fileDialog.planFiles   = true
            fileDialog.nameFilters = _planMasterController.loadNameFilters
            fileDialog.openForLoad()
        }

        function saveToSelectedFile() {
            if (!checkReadyForSaveUpload(true)) { return }
            fileDialog.title       = qsTr("Save Plan")
            fileDialog.planFiles   = true
            fileDialog.nameFilters = _planMasterController.saveNameFilters
            fileDialog.openForSave()
        }

        function data() {
            var surveyCreator = null
            for (var i = 0; i < _planMasterController.planCreators.count; i++) {
                var creator = _planMasterController.planCreators.get(i)
                if (creator.name === "Survey") {
                    surveyCreator = creator
                    break
                }
            }

            if (surveyCreator) {
                console.log("surveyCreator", surveyCreator)
                QGroundControl.saveGlobalSetting("surveyCreator", surveyCreator)
                var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2),
                                           editorMap.centerViewport.top  + (editorMap.centerViewport.height / 2))
                var centerCoord = editorMap.toCoordinate(centerPoint, false)
                surveyCreator.createPlan(centerCoord)
            } else {
                console.log("Survey plan creator not found")
            }

            if (QGroundControl.loadGlobalSetting("mapping", "mapping") === "basic") {
                filename._resetPolygon()
            } else if (QGroundControl.loadGlobalSetting("mapping", "mapping") === "circle") {
                filename._resetCircle()
            }
        }

        function saveToSelectedFile1() {
            if (!checkReadyForSaveUpload(true)) { return }
            fileDialog.title       = qsTr("Save Plan")
            fileDialog.planFiles   = true
            fileDialog.nameFilters = _planMasterController.saveNameFilters1
            fileDialog.openForSave()
        }

        function fitViewportToItems() {
            mapFitFunctions.fitMapViewportToMissionItems()
        }

        function saveKmlToSelectedFile() {
            if (!checkReadyForSaveUpload(true)) { return }
            fileDialog.title       = qsTr("Save KML")
            fileDialog.planFiles   = false
            fileDialog.nameFilters = ShapeFileHelper.fileDialogKMLFilters
            fileDialog.openForSave()
        }

        function openForLoad() {
            _openForLoad = true
            if (_mobileDlg && folder.length !== 0) {
                // handled inline now — no popup needed
            } else if (selectFolder) {
                fullFolderDialog.open()
            } else {
                fullFileDialog.fileMode = FileDialog.OpenFile
                fullFileDialog.open()
            }
        }

        function _updateMobileShortPath() {
            if (ScreenTools.isMobile) {
                _mobileShortPath = controller.fullFolderPathToShortMobilePath(folder);
            }
        }

        function _setupFileExtensions() {
            _rgExtensions = []
            for (var i = 0; i < nameFilters.length; i++) {
                var filter  = nameFilters[i]
                var regExp  = /^.*\((.*)\)$/
                var result  = regExp.exec(filter)
                if (result.length === 2) { filter = result[1] }
                var rgFilters = filter.split(" ")
                for (var j = 0; j < rgFilters.length; j++) {
                    if (!_mobileDlg || (rgFilters[j] !== "*" && rgFilters[j] !== "*.*")) {
                        _rgExtensions.push(rgFilters[j])
                    }
                }
            }
        }
    }
    //========================================================

    Timer {
        id:       fadeTimer
        interval: 220
        repeat:   false

        property string newView: ""

        onTriggered: {
            currentView          = newView
            fadeOverlay.opacity  = 0
        }
    }

    Item {
        id: transitionRoot
        anchors.fill: parent

        Loader {
            id: pageLoader
            anchors.fill: parent
            asynchronous: true

            property var pageCache: ({})

            sourceComponent: {
                pageCache[currentView] = profilePage
                //inlineLoader.sourceComponent = fileListComponent
            }
        }

        Rectangle {
            id: fadeOverlay
            anchors.fill: parent
            color:   Qt.rgba(0, 0, 0, 0.18)
            opacity: 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration:     220
                    easing.type:  Easing.OutCubic
                }
            }
        }
    }

    // ─── Profile Page ────────────────────────────────────────────────────────
    Component {
        id: profilePage

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.15
                    color: app_color

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin:  20
                        anchors.rightMargin: 20
                        spacing: 10

                        QGCColoredImage {
                            source:   "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            fillMode: Image.PreserveAspectFit
                            width:  25
                            height: 25
                            color:  "white"

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (MapGlobals.comefrom === "Profile") {
                                        backClicked()
                                        // Fallback if standalone
                                        if (typeof pageLoader !== 'undefined' && pageLoader.source.toString().indexOf("LogFiles.qml") !== -1) {
                                            mainWindow.openProfileScreen()
                                        }
                                    } else if (MapGlobals.comefrom === "Camera") {
                                        mainWindow.cameraView()
                                    } else if (MapGlobals.comefrom === "Plan") {
                                        mainWindow.showFlyView()
                                    } else if (MapGlobals.comefrom === "Start") {
                                        mainWindow.showMapping()
                                    } else {
                                        mainWindow.openHomeScreen()
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text:           "Log files"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color:          "white"
                            font.bold:      true
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // Content area
                RowLayout {
                    Layout.fillWidth:    true
                    Layout.fillHeight:   true
                    Layout.leftMargin:   20
                    Layout.rightMargin:  20
                    Layout.bottomMargin: 20
                    spacing: 20

                    // ── Right Card: Menu + Inline File List ──────────────────
                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true
                        color:        "white"
                        radius:       5
                        border.color: "#e0e0e0"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill:    parent
                            anchors.margins: 10
                            spacing: 0
                            clip:    true

                            // Menu list — hidden when inline content is active
                            ListView {
                                id: menuList
                                Layout.fillWidth:  true
                                Layout.fillHeight: true
                                visible: inlineLoader.sourceComponent === null

                                model: ListModel {
                                    ListElement {
                                        icon:   "/qmlimages/NewImages/report.svg"
                                        name:   "Files"
                                        screen: "fileList"
                                    }
                                }

                                delegate: Rectangle {
                                    width:  ListView.view.width
                                    height: 50
                                    color:  "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 15

                                        QGCColoredImage {
                                            source:   model.icon
                                            width:    20
                                            height:   20
                                            color:    "transparent"
                                        }

                                        Text {
                                            text:             model.name
                                            font.pointSize:   ScreenTools.defaultFontPointSize
                                            color:            "#333333"
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width:  parent.width
                                        height: 1
                                        color:  "#eeeeee"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked: {
                                            if (model.screen === "logout") {
                                                logoutdialog.createObject(mainWindow).open()
                                            } else if (model.screen === "fileList") {
                                                // Setup paths/extensions, then show inline
                                                _planMasterController._updateMobileShortPath()
                                                _planMasterController._setupFileExtensions()
                                                inlineLoader.sourceComponent = fileListComponent
                                                console.log("gridlines True")
                                                MapGlobals.setGridLines(true)

                                            } else {
                                                if (model.screen === "privacy_policy") {
                                                    privacyLoading = true
                                                }
                                                switchPage(model.screen)
                                            }
                                        }
                                    }
                                }
                            }

                            // Inline content (replaces menu when a sub-view is loaded)
                            Loader {
                                id: inlineLoader
                                Layout.fillWidth:  true
                                Layout.fillHeight: true
                                visible:           sourceComponent !== null
                                sourceComponent:   fileListComponent
                            }
                        }
                    }
                    // ────────────────────────────────────────────────────────
                }
            }

            // ── Inline File List Component ───────────────────────────────────
            Component {
                id: fileListComponent

                Item {
                    anchors.fill: parent

                    // Track file list so delete can trigger a refresh
                    property var fileList: controller.getFiles(folder, _rgExtensions)

                    function refreshFiles() {
                        fileList = controller.getFiles(folder, _rgExtensions)
                    }




                    // Scrollable file list
                    ScrollView {
                        anchors.top:         parent.top
                        anchors.topMargin:   6
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.bottom:      parent.bottom
                        clip:                true
                        contentWidth:        width

                        Column {
                            width:   parent.width
                            spacing: ScreenTools.defaultFontPixelHeight / 2
                            padding: 4

                            QGCLabel {
                                text: qsTr("Path: %1").arg(_mobileShortPath)
                            }

                            Repeater {
                                id:    fileRepeater
                                model: fileList

                                FileButton {
                                    width:  parent ? parent.width : 0
                                    text:   modelData

                                    onClicked: {
                                        console.log("Loading file:", modelData)
                                        console.log("Folder:", folder)
                                        console.log("Filename stripped:", modelData.split(".")[0])

                                        mainWindow.openHomeScreen()
                                        mainWindow.showFlyView()
                                        mainWindow.showPlanView()

                                        var strippedFileName = modelData.split(".")[0]
                                        _appSettings.username = strippedFileName

                                        MapGlobals.comefrom = "Plan"
                                        console.log("MapGlobals.comefrom", MapGlobals.comefrom)
                                        _appSettings.screen = "Plan"

                                        swapCamera()
                                        mainWindow.fileload(folder + "/" + modelData)
                                    }

                                    onHamburgerClicked: {
                                        highlight = true
                                        fileHamburgerMenu.fileToDelete =
                                            controller.fullyQualifiedFilename(folder, modelData)
                                        fileHamburgerMenu.popup()
                                    }

                                    QGCMenu {
                                        id: fileHamburgerMenu
                                        property string fileToDelete

                                        onAboutToHide: parent.highlight = false

                                        QGCMenuItem {
                                            text: qsTr("Delete")
                                            onTriggered: {
                                                controller.deleteFile(fileHamburgerMenu.fileToDelete)
                                                // Refresh file list after deletion
                                                var root = fileRepeater.parent
                                                while (root && !root.refreshFiles) { root = root.parent }
                                                if (root) root.refreshFiles()
                                            }
                                        }
                                    }
                                }
                            }

                            QGCLabel {
                                text:    qsTr("No files")
                                visible: fileList.length === 0
                            }
                        }


                    }
                }
            }
            // ────────────────────────────────────────────────────────────────
        }
    }
    // ─────────────────────────────────────────────────────────────────────────

    function swapCamera() {
        var videoSettings = QGroundControl.settingsManager.videoSettings
        if (videoSettings) {
            var videoSourceFact = videoSettings.videoSource
            if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                videoSourceFact.value = videoSourceFact.enumValues[1]
            }
        }
    }

    QGCFileDialogController { id: controller }

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

    //=======================================================================================
    Component {
        id: logoutdialog

        QGCPopupDialog {
            id: popup
            title: qsTr("Logout")
            buttons: Dialog.Yes | Dialog.No

            onAccepted: {
                QGroundControl.saveBoolGlobalSetting("login", false)
                popup.visible = false
                MapGlobals.profile()
            }

            onRejected: {
                popup.visible = false
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel {
                    text:             qsTr("Are you sure you want to logout?")
                    Layout.fillWidth: true
                }
            }
        }
    }
}
