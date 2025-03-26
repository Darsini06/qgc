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

/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    minimumWidth:   ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true
    property var    guidedController
    property var    guidedValueSlider


    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionChecked:      optionCheckBox.checked

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
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property var    _unitsConversion:           QGroundControl.unitsConversion
    property var _guidedController: globals.guidedControllerFlyView
    property int    actionTakeoff
    signal loadPlanFile()
    // Reference the existing FlightMap instance (defined in another QML file)
    //property alias mainFlightMap: mainFlightMap

    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens
        if (!ScreenTools.isFakeMobile && (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120)) {
            mainWindow.showFullScreen()
        } else {
            width   = ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(150 * Screen.pixelDensity, Screen.height)
        }


        if(planType==="Plan"){
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

    /// @return true: View switches are not currently allowed
    function preventViewSwitch() {
        return globals.validationError
    }

    function newscreen() {
        pageLoader.source = "newscreen.qml";
    }

    function showPlanView() {
        planbtn.visible =false
        listbtn.visible = false
        takeoffbtn.visible = false
        rtlbtn.visible = false
        modebtn.visible = false
        flyView.visible = false
        planView.visible = true


    }



    function showFlyView() {
        planbtn.visible = true
        listbtn.visible = true
        takeoffbtn.visible = true
        rtlbtn.visible = true
        modebtn.visible = activeVehicle ? false : true
        flyView.visible = true
        planView.visible = false


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
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction }).open()
    }

    // This variant is only meant to be called by QGCApplication
    function _showMessageDialog(dialogTitle, dialogText) {
        showMessageDialog(dialogTitle, dialogText)
    }

    Component {
        id: simpleMessageDialogComponent

        QGCSimpleMessageDialog {
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
        color:          QGroundControl.globalPalette.window
    }

    FlyView {
        id:                     flyView
        anchors.fill:           parent
        utmspSendActTrigger:    _utmspSendActTrigger
    }
    // FileList {
    //     id:                     filelist
    //     anchors.fill:           parent
    //     visible:        false
    // }


    PlanView {
        id:             planView
        anchors.fill:   parent
        visible:        false
        planType: plan
    }


    FlyViewToolBar {
        id: toolbar
        visible: false
        // Reserve space even when hidden
        //height: visible ? implicitHeight : 0
    }

    FlyViewMap  {
        id: _map
    }

    FlightMap {
        id: _flightMap
        //anchors.fill : parent
        //visible : false
    }

    MainRootIcons {
        id:             mainrootIcons
        map: _map
        flightMap: _flightMap
        anchors.top:        toolbar.bottom
        anchors.bottom:     parent.bottom
        //anchors.left:       parent.left
        anchors.right:      parent.right
        visible:        true

        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: 15

        mapRotation: MapGlobals.mapRotation
    }


    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }

    function showToolSelectDialog() {
        if (!mainWindow.preventViewSwitch()) {
            mainWindow.showIndicatorDrawer1(toolSelectComponent, null)
        }
    }



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
    //         border.color: "#005BBB"  // Border color
    //         border.width: 2
    //     }
    //         onClicked: {
    //             if (!mainWindow.preventViewSwitch()) {
    //                 mainWindow.showIndicatorDrawer(toolSelectComponents, null)
    //             }
    //         }
    //     }

    ColumnLayout {
        id:columnbtn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 80
        anchors.leftMargin: 20
        visible: true
        spacing: 20  // Adjust this value to control space between icons

        Rectangle {
            id: listbtn
            Layout.alignment: Qt.AlignLeft
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible: true



            QGCColoredImage {
                id: flightModeIndicator2
                source: "qrc:/InstrumentValueIcons/list.svg"
                width: 24
                height: 24
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    planView.loaddata()
                }
            }
        }

        Rectangle {
            id: takeoffbtn
            Layout.alignment: Qt.AlignLeft
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible:  true



            QGCColoredImage {
                id: takeofficon
                source: "/res/takeoff.svg"
                width: 24
                height: 24
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/res/takeoff.svg";  // Set the image dynamically
                    myDialog.dialogText = "settings"; // Set the text dynamically
                    myDialog.open()
                }
            }
        }

        Rectangle {
            id: landbtn
            Layout.alignment: Qt.AlignLeft
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible:false



            QGCColoredImage {
                id: landbtnicon
                source: "/res/land.svg"
                width: 24
                height: 24
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {

                    myDialog.imageSource = "/res/land.svg";  // Set the image dynamically
                    myDialog.dialogText = "Land Mode"; // Set the text dynamically
                    myDialog.open()
                }
            }
        }

        Rectangle {
            id: rtlbtn
            Layout.alignment: Qt.AlignLeft
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible:  true



            QGCColoredImage {
                id: rtlbtnicon
                source: "/res/rtl.svg"
                width: 24
                height: 24
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {

                }
            }
        }



        Rectangle {
            id: modebtn
            Layout.alignment: Qt.AlignLeft
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible: activeVehicle ? false : true


            Image {
                id: flightModeIndicator12
                source: "/qmlimages/FlightModesComponentIcon.png"
                width: 24
                height: 24
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!mainWindow.preventViewSwitch()) {
                        mainWindow.showIndicatorDrawer(toolSelectComponents, null)
                    }
                }
            }
        }


        Rectangle {
            id: modebtn1
            Layout.alignment: Qt.AlignLeft
            width: 200
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible: activeVehicle ? true : false




            FlightModeIndicator {
                id: flightmode1
                visible: activeVehicle ? true : false
                anchors.centerIn: parent

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
            color: "#4CAF50" // Green theme for agriculture
            radius: 50
            border.color: "#2E7D32"
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


                text: myDialog.dialogText==="settings"?"Takeoff Altitude: " + takeoffSettings.sliderOutputValue + " m":myDialog.dialogText
                font.pixelSize: 16
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                id: circularButton
                width: 80
                height: 80
                radius: 40
                color: "#A5D6A7"
                border.color: "#2E7D32"
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
                    onEntered: circularButton.color = "#1B5E20"
                    onExited: circularButton.color = "#388E3C"
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
                        ctx.strokeStyle = "#009900"
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
                    color: "#1B5E20"
                    radius: 10
                    border.color: "#2E7D32"
                    border.width: 2

                    Text {
                        text: "-"
                        font.pixelSize: 24
                        color: "white"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (takeoffSettings.sliderOutputValue > 1.2) {
                                takeoffSettings.sliderOutputValue -= 0.1
                            }
                        }
                    }
                }

                Rectangle {
                    width: 40
                    height: 40
                    color: "#1B5E20"
                    radius: 10
                    border.color: "#2E7D32"
                    border.width: 2

                    Text {
                        text: "+"
                        font.pixelSize: 24
                        color: "white"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (takeoffSettings.sliderOutputValue < 120) {
                                takeoffSettings.sliderOutputValue += 0.1
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
        _activeVehicle.guidedModeTakeoff(valueInMeters)
        landbtn.visible=true
        takeoffbtn.visible=false


        myDialog.close()
    }

    function executeAction2() {
        console.log("Button long-pressed! Action executed.1")
        _activeVehicle.guidedModeRTL(false)
        landbtn.visible=false
        takeoffbtn.visible=true


        myDialog.close()
    }




    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 20
        anchors.rightMargin: 20
        spacing: 20  // Adjust this value to control space between icons

        Rectangle {
            id: planbtn
            Layout.alignment: Qt.AlignRight
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible: true



            QGCColoredImage {
                source: "/qmlimages/Plan.svg"
                width: 24
                height: 24
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    mainWindow.showPlanView()
                    //viewer3DWindow.close()
                }
            }
        }

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

    function showCriticalVehicleMessage(message) {
        indicatorPopup.close()
        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
            // We received additional wanring message while an older warning message was still displayed.
            // When the user close the older one drop the message indicator tool so they can see the rest of them.
            criticalVehicleMessagePopup.dropMessageIndicatorOnClose = true
        } else {
            criticalVehicleMessagePopup.criticalVehicleMessage      = message
            criticalVehicleMessagePopup.dropMessageIndicatorOnClose = false
            criticalVehicleMessagePopup.open()
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
        x:              isRightAligned ? mainWindow.contentItem.width - contentItem.implicitWidth - _margins
                                       : calcXPosition()
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
                color:          QGroundControl.globalPalette.window
                radius:         indicatorDrawer._margins
                opacity:        0.85
            }

            Rectangle {
                anchors.horizontalCenter:   backgroundRect.right
                anchors.verticalCenter:     backgroundRect.top
                width:                      ScreenTools.defaultFontPixelHeight
                height:                     width
                radius:                     width / 2
                color:                      QGroundControl.globalPalette.button
                border.color:               QGroundControl.globalPalette.buttonText
                visible:                    indicatorDrawerLoader.item && indicatorDrawerLoader.item.showExpand && !indicatorDrawer._expanded

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               ">"
                    color:              QGroundControl.globalPalette.buttonText
                }

                QGCMouseArea {
                    fillItem: parent
                    onClicked: indicatorDrawer._expanded = true
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

    Connections{
        target: activationbar
        function onActivationTriggered(value){
            _utmspSendActTrigger= value
        }
    }

    UTMSPActivationStatusBar{
        id:                         activationbar
        activationStartTimestamp:   UTMSPStateStorage.startTimeStamp
        activationApproval:         UTMSPStateStorage.showActivationTab && QGroundControl.utmspManager.utmspVehicle.vehicleActivation
        flightID:                   UTMSPStateStorage.flightID
        anchors.fill:               parent
    }
}
