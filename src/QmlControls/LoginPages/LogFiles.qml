import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.LocalStorage
import QtQuick.Effects
import QtWebView

import Qt.labs.lottieqt 1.0
import Qt.labs.settings 1.0

import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.Controllers 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.FactSystem 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0
import QGroundControl.FlightMap 1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.ShapeFileHelper 1.0
import QGroundControl.UTMSP 1.0

import MapGlobals
import QtLocation
import QtPositioning
import QtQuick.Window

//================================

Item {
    id: logFilesRoot
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
    property color app_color:       MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#262626"
    property color sidebar_color:   app_color
    property color bg_color:        "#F9FAFB"
    property color border_color:    "#E5E7EB"
    property color text_primary:    "#111827"
    property color text_secondary:  "#6B7280"
    property bool isCloudView:      true
    signal backClicked()

    property bool privacyLoading: true
    property bool pageLoading:    true

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 90
    readonly property real outerPadding: isSmallScreen ? 20 : 60
    readonly property real tableMaxWidth: 1100

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
        if (QGroundControl.loadGlobalSetting("loadpage","loadpage") === "Agri"){
            nameFilters = _planMasterController.loadNameFilters1
        }else{
            nameFilters = _planMasterController.loadNameFilters
        }


        _planMasterController._updateMobileShortPath()
        _planMasterController._setupFileExtensions()
    }

    onVisibleChanged: {
        if (visible) {
            console.log("onVisibleChanged");
            triggerLoad();

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
            triggerLoad()
        } else if (currentView === "privacy_policy") {
            privacyLoader.active = true
        }
    }

    function triggerLoad() {
        pageLoading = true
        loadSessions()
        // We'll also trigger cloud fetch if needed
    }

    function loadSessions() {
        console.log("Loading drone sessions...");
        sessionModel.clear();

        MapGlobals.getAllSessions(function(sessions) {
            if (sessions.length === 0) {
                console.log("No drone sessions found");
                pageLoading = false
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
            updateSessionStats();
            pageLoading = false
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

        // function loadFromSelectedFile() {
        //     _updateMobileShortPath()
        //     _setupFileExtensions()
        //     if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
        //         nameFilters = _planMasterController.loadNameFilters1
        //     }else{
        //         nameFilters = _planMasterController.loadNameFilters
        //     }


        //     openForLoad()
        // }

        // function loadFromSelectedFile1() {
        //     fileDialog.title       = qsTr("Select Plan File")
        //     fileDialog.planFiles   = true
        //     if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
        //         nameFilters = _planMasterController.loadNameFilters1
        //     }else{
        //         nameFilters = _planMasterController.loadNameFilters
        //     }
        //     fileDialog.openForLoad()
        // }

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

                        console.log("extensions",_rgExtensions)
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

    //=======================================================================================
    // MAIN CONTENT
    //=======================================================================================
    Rectangle {
        anchors.fill: parent
        color: bg_color

        RowLayout {
            anchors.fill: parent
            spacing: 0

            /* ================= PREMIUM SIDEBAR (45%) ================= */
            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: isSmallScreen ? 0 : parent.width * 0.45
                visible: !isSmallScreen
                color: sidebar_color
                clip: true

                // Background Gradient
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: sidebar_color }
                        GradientStop { position: 1.0; color: "#1A1A1A" }
                    }
                }

                // Decorative Accents
                Rectangle {
                    width: 400; height: 400; radius: 200; color: Qt.rgba(255,255,255,0.03)
                    anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: -80
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    spacing: 0

                    // Back Arrow
                    Rectangle {
                        width: 44; height: 44; radius: 12
                        color: Qt.rgba(255, 255, 255, 0.08)
                        border.color: Qt.rgba(255, 255, 255, 0.15)
                        QGCColoredImage { source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"; width: 20; height: 20; color: "white"; anchors.centerIn: parent }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: logFilesRoot.backClicked()
                        }
                    }

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 16
                        Text {
                            text: "Log Files"
                            font.family: "Outfit"
                            font.pointSize: 32
                            font.bold: true
                            color: "white"
                        }
                        Text {
                            text: "Comprehensive collection of your mission plans and synchronized cloud records."
                            font.family: "Outfit"
                            font.pointSize: 12
                            color: Qt.rgba(255, 255, 255, 0.6)
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            lineHeight: 1.5
                        }
                    }

                    Item { Layout.fillHeight: true }

                    LottieAnimation {
                        Layout.preferredHeight: 140; Layout.preferredWidth: 140
                        source: "qrc:/qmlimages/NewImages/report_1.json"; autoPlay: true; loops: Animation.Infinite
                    }

                    Item { Layout.preferredHeight: 40 }
                }
            }

            /* ================= DATA CONTENT AREA (55%) ================= */
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"

                // Mobile Navigation Bar
                Rectangle {
                    visible: isSmallScreen; width: parent.width; height: 70; color: "white"
                    anchors.top: parent.top; z: 10
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: border_color }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 20
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"; width: 24; height: 24; color: text_primary
                            MouseArea {
                                anchors.fill: parent
                                onClicked: logFilesRoot.backClicked()
                            }
                        }
                        Text { text: "Log Files"; font.family: "Outfit"; font.bold: true; font.pointSize: ScreenTools.mediumFontPointSize; color: text_primary }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: isSmallScreen ? 70 : 0
                    spacing: 0

                    // --- Centered Content Container ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: outerPadding
                        Layout.rightMargin: outerPadding
                        Layout.topMargin: isSmallScreen ? 10 : 20
                        spacing: 30

                        // Inline content (Always show Plan Files)
                        Loader {
                            id: inlineLoader
                            Layout.fillWidth:  true
                            Layout.fillHeight: true
                            sourceComponent:   fileListComponent
                        }
                    }
                }
            }
        }
    }

    // --- Premium Loading Screen ---
    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        color: "white"
        visible: pageLoading
        z: 1000

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: pageLoading
            }

            Text {
                text: qsTr("Synchronizing Your Flight Data...")
                font.family: "Outfit"
                font.pointSize: 14
                font.bold: true
                color: text_primary
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: qsTr("Please wait while we fetch your latest mission logs.")
                font.family: "Outfit"
                font.pointSize: 10
                color: text_secondary
                Layout.alignment: Qt.AlignHCenter
            }
        }
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ── Inline File List Component ───────────────────────────────────
    Component {
        id: fileListComponent
        Item {
            id: fileListRoot
            anchors.fill: parent
            property bool isCloudView: false
            property var fileList: controller.getFiles(folder, _rgExtensions)

            function refreshFiles() {
                if (isCloudView) { fetchCloudFiles() }
                else { fileList = controller.getFiles(folder, _rgExtensions) }
            }

            function fetchCloudFiles() {
                cloudPlansLoading = true
                MapGlobals.fetchCloudPlans(userName, function(plans) {
                    cloudPlansModel.clear()
                    for (var i = 0; i < plans.length; i++) { cloudPlansModel.append(plans[i]) }
                    cloudPlansLoading = false
                })
            }

            property bool cloudPlansLoading: false
            ListModel { id: cloudPlansModel }

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: contentCol.height + 100
                clip: true

                ColumnLayout {
                    id: contentCol
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: isSmallScreen ? 10 : 20
                    spacing: 24

                    // Page Title (Desktop Only)
                    ColumnLayout {
                        visible: !isSmallScreen; Layout.fillWidth: true; spacing: 4
                        Text { text: "Plan Files"; font.family: "Outfit"; font.pointSize: 24; font.bold: true; color: text_primary }
                        Text { text: qsTr("Synced plans associated with %1").arg(userEmail); font.family: "Outfit"; font.pointSize: 11; color: text_secondary }
                    }

                    // THE DATA GRID CARD
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(500, filesListView.contentHeight + 40)
                        color: "white"; radius: 16
                        border.color: border_color; border.width: 1
                        clip: true
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0,0,0,0.03); shadowBlur: 1.0; shadowVerticalOffset: 4 }

                        ColumnLayout {
                            anchors.fill: parent; spacing: 0
                            BusyIndicator { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 40; visible: cloudPlansLoading }
                            ListView {
                                id: filesListView
                                Layout.fillWidth: true; Layout.fillHeight: true
                                model: cloudPlansModel; interactive: false
                                visible: !cloudPlansLoading
                                delegate: Rectangle {
                                    width: filesListView.width; height: 72
                                    color: index % 2 === 1 ? "#FAFAFC" : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 30; anchors.rightMargin: 30; spacing: 20
                                        Rectangle {
                                            width: 40; height: 40; radius: 10; color: Qt.rgba(0, 0, 0, 0.05)
                                            QGCColoredImage { source: "qrc:/qmlimages/NewImages/report.svg"; width: 18; height: 18; color: app_color; anchors.centerIn: parent }
                                        }
                                        Text { text: model.plan_name; font.family: "Outfit"; font.bold: true; color: text_primary; font.pointSize: 13; Layout.fillWidth: true }
                                        Rectangle {
                                            width: 80; height: 32; radius: 8; color: app_color
                                            Text { text: "LOAD"; color: "white"; font.family: "Outfit"; font.bold: true; font.pointSize: 9; anchors.centerIn: parent }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    mainWindow.showMessageDialog(qsTr("Download Plan"),
                                                        qsTr("Do you want to download and load '%1' from the cloud?").arg(model.plan_name),
                                                        Dialog.Yes | Dialog.Cancel,
                                                        function() {
                                                            mainWindow.openHomeScreen()
                                                            mainWindow.showFlyView()
                                                            mainWindow.showPlanView()
                                                            _planMasterController.loadFromJson(model.plan_data)
                                                            mainWindow.showToastMessage("Cloud plan loaded")
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 30; anchors.rightMargin: 30; height: 1; color: border_color; visible: index < filesListView.count - 1 }
                                }
                                ColumnLayout {
                                    anchors.centerIn: parent; visible: filesListView.count === 0 && !cloudPlansLoading; spacing: 16
                                    QGCColoredImage { source: "qrc:/InstrumentValueIcons/info.svg"; width: 60; height: 60; color: "#D1D5DB"; Layout.alignment: Qt.AlignHCenter }
                                    Text { text: "No Plan Files Discovered"; font.family: "Outfit"; font.bold: true; font.pointSize: 14; color: text_secondary; Layout.alignment: Qt.AlignHCenter }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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
    Component {
        id: logoutdialog
        QGCPopupDialog {
            id: popup
            title: qsTr("Sign Out")
            buttons: Dialog.Yes | Dialog.No
            onAccepted: {
                QGroundControl.saveBoolGlobalSetting("login", false)
                popup.visible = false
                MapGlobals.profile()
            }
            onRejected: { popup.visible = false }
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel { text: qsTr("Are you sure you want to sign out?"); Layout.fillWidth: true }
            }
        }
    }
}

