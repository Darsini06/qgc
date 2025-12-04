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

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import Qt.labs.platform 1.1 as Platform
import MapGlobals 1.0
// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root


    property var    pipview
    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl
    property bool   isViewer3DOpen:         false

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property alias  _gripperMenu:           gripperOptions
    property real   _layoutMargin:          ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _layoutSpacing:         ScreenTools.defaultFontPixelWidth
    property bool   _showSingleVehicleUI:   true

    property bool utmspActTrigger

    Component.onCompleted: {
        //console.log("pipView.visible :", pipview.visible);

        console.log("_pipView.visible :", _pipView.visible);

    }


    // LEFT SIDE BUTTON COLUMN
    ColumnLayout {
        id: leftColumn
        width: 100     // VERY IMPORTANT FIX ✔
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 20
        anchors.leftMargin: 20
        spacing: 10

        // ----- Saved Files Button -----
        Rectangle {
            id: listbtn
            Layout.alignment: Qt.AlignLeft
            width: leftColumn.width * 0.55
            height: width
            radius: width / 2
            color: "#1b1c3e"
            border.width: width * 0.05
            border.color: "#005BBB"

            QGCColoredImage {
                source: "/qmlimages/NewImages/savedfiles.png"
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                color: "transparent"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    QGroundControl.saveGlobalSetting("waypoint", "waypoint1")
                    if(_appSettings.screen==="Plan") {
                        planView.loaddata()
                    } else {
                        planView.loaddata1()
                    }
                }
            }
        }

        // ----- Takeoff -----
        Rectangle {
            id: takeoffbtn
            Layout.alignment: Qt.AlignLeft
            width: leftColumn.width * 0.55
            height: width
            radius: width / 2
            color: "#1b1c3e"
            border.width: width * 0.05
            border.color: "#005BBB"

            QGCColoredImage {
                source: "/qmlimages/NewImages/takeOff.png"
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/qmlimages/NewImages/takeOff.png"
                    myDialog.dialogText = "settings"
                    myDialog.open()
                }
            }
        }

        // ----- Waypoint -----
        Rectangle {
            id: waypointbtn
            Layout.alignment: Qt.AlignLeft
            width: leftColumn.width * 0.55
            height: width
            radius: width / 2
            color: "#1b1c3e"
            border.width: width * 0.05
            border.color: "#005BBB"

            QGCColoredImage {
                source: "/qmlimages/MapAddMission.svg"
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                color: "white"
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

        // ----- Camera -----
        Rectangle {
            id: camerabtn
            Layout.alignment: Qt.AlignLeft
            width: leftColumn.width * 0.55
            height: width
            radius: width / 2
            color: "#1b1c3e"
            border.width: width * 0.05
            border.color: "#005BBB"

            QGCColoredImage {
                source: "/qmlimages/NewImages/takeOff.png"
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/qmlimages/NewImages/takeOff.png"
                    myDialog.dialogText = "settings"
                    myDialog.open()
                }
            }
        }

        // ----- Land -----
        Rectangle {
            id: landbtn
            Layout.alignment: Qt.AlignLeft
            width: leftColumn.width * 0.55
            height: width
            radius: width / 2
            color: "#1b1c3e"
            border.width: width * 0.05
            border.color: "#005BBB"

            QGCColoredImage {
                source: "/qmlimages/NewImages/return.png"
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/qmlimages/NewImages/return.png"
                    myDialog.dialogText = "Land Mode"
                    myDialog.open()
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


        // ----- RTL -----
        Rectangle {
            id: rtlbtn
            Layout.alignment: Qt.AlignLeft
            width: leftColumn.width * 0.55
            height: width
            radius: width / 2
            color: "#1b1c3e"
            border.width: width * 0.05
            border.color: "#005BBB"

            QGCColoredImage {
                source: "/qmlimages/NewImages/landing.png"
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: width
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    myDialog.imageSource = "/qmlimages/NewImages/landing.png"
                    myDialog.dialogText = "RTL Mode"
                    myDialog.open()
                }
            }
        }

        // ----- Flight mode row -----
        RowLayout {
            id: modeRow
            spacing: 10
            Layout.alignment: Qt.AlignLeft
            property bool extraButtonsVisible: false

            Rectangle {
                id: modebtn
                width: leftColumn.width * 0.55
                height: width
                radius: width / 2
                color: "#1b1c3e"
                border.width: width * 0.05
                border.color: "#005BBB"

                QGCColoredImage {
                    source: "/qmlimages/FlightModesComponentIcon.png"
                    anchors.centerIn: parent
                    width: parent.width * 0.5
                    height: width
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (activeVehicle)
                            confirmDialog.open()
                        else
                            console.log("No active vehicle")
                    }
                }
            }
        }

        // ----- Flight mode text -----
        Rectangle {
            id: modebtn1
            Layout.alignment: Qt.AlignLeft
            width: flightmode1.implicitWidth + 30
            height: flightmode1.implicitHeight + 15
            radius: height / 2
            color: "#1b1c3e"
            border.width: 2
            border.color: "#005BBB"
            visible: activeVehicle

            FlightModeIndicator {
                id: flightmode1
                anchors.centerIn: parent
            }
        }
    }



    // RIGHT SIDE BOTTOM BUTTON
    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 20
        spacing: 20

        Rectangle {
            id: planbtn1
            Layout.alignment: Qt.AlignRight
            width: 100
            height: 38
            radius: width / 2
            color: "#1b1c3e"

            Text {
                text: " + New Plot "
                color: "white"
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

            }
        }

    }




    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftEdgeTopInset
        leftEdgeCenterInset:    toolStrip.leftEdgeCenterInset
        leftEdgeBottomInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.leftEdgeBottomInset : parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      topRightColumnLayout.rightEdgeTopInset
        rightEdgeCenterInset:   topRightColumnLayout.rightEdgeCenterInset
        rightEdgeBottomInset:   bottomRightRowLayout.rightEdgeBottomInset
        topEdgeLeftInset:       toolStrip.topEdgeLeftInset
        topEdgeCenterInset:     mapScale.topEdgeCenterInset
        topEdgeRightInset:      topRightColumnLayout.topEdgeRightInset
        bottomEdgeLeftInset:    virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeLeftInset : parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  bottomRightRowLayout.bottomEdgeCenterInset
        bottomEdgeRightInset:   virtualJoystickMultiTouch.visible ? virtualJoystickMultiTouch.bottomEdgeRightInset : bottomRightRowLayout.bottomEdgeRightInset
    }

    FlyViewTopRightColumnLayout {
        id:                 topRightColumnLayout
        anchors.margins:    _layoutMargin
        anchors.top:        parent.top
        anchors.bottom:     bottomRightRowLayout.top
        anchors.right:      parent.right
        spacing:            _layoutSpacing

        property real topEdgeRightInset :    childrenRect.height + _layoutMargin
        property real rightEdgeTopInset :    width + _layoutMargin
        property real rightEdgeCenterInset : rightEdgeTopInset
    }

    FlyViewBottomRightRowLayout {
        id:                 bottomRightRowLayout
        anchors.margins:    _layoutMargin
        spacing:            _layoutSpacing
        anchors.bottom: parent.bottom

        pipExpanded: _pipView.globalPipExpanded

        onPipExpandedChanged: {
            console.log("pipExpanded changed to:", pipExpanded)
            // States handle the visual changes automatically

            state = pipExpanded ? "expanded" : "shrunk"
        }


        // Use states instead of conditional anchors
            states: [
                State {
                    name: "expanded"
                    AnchorChanges {
                        target: bottomRightRowLayout
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.left: undefined
                    }
                    PropertyChanges {
                        target: bottomRightRowLayout
                        anchors.leftMargin: 0
                    }
                },
                State {
                    name: "shrunk"
                    AnchorChanges {
                        target: bottomRightRowLayout
                        anchors.left: parent.left
                        anchors.horizontalCenter: undefined
                    }
                    PropertyChanges {
                        target: bottomRightRowLayout
                        anchors.leftMargin: 45
                    }
                }
            ]

        Component.onCompleted: {
            state = pipExpanded ? "expanded" : "shrunk"
            console.log("Initial state set to:", state)
        }

        anchors.horizontalCenter: pipExpanded ? parent.horizontalCenter : undefined
        anchors.left: pipExpanded ? undefined : parent.left
        anchors.leftMargin: pipExpanded ? 0 : 20

        visible: true

        property real bottomEdgeRightInset:     height + _layoutMargin
        property real bottomEdgeCenterInset:    bottomEdgeRightInset
        property real rightEdgeBottomInset:     width + _layoutMargin

    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    GuidedActionConfirm {
        anchors.margins:            _toolsMargin
        anchors.top:                parent.top
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderTopMost
        guidedController:           _guidedController
        guidedValueSlider:          _guidedValueSlider
        utmspSliderTrigger:         utmspActTrigger
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        anchors.right:              parent.right
        anchors.rightMargin:        anchors.leftMargin
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       bottomLoaderMargin
        anchors.left:               parent.left
        anchors.leftMargin:         ( y > toolStrip.y + toolStrip.height ? toolStrip.width / 2 : toolStrip.width * 1.05 + toolStrip.x)
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property real bottomEdgeLeftInset:     parent.height-y
        property bool autoCenterThrottle:      QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue
        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
        property real bottomEdgeRightInset:    parent.height-y
        property var  _pipViewMargin:          _pipView.visible ? parentToolInsets.bottomEdgeLeftInset + ScreenTools.defaultFontPixelHeight * 2 :
                                                                  bottomRightRowLayout.height + ScreenTools.defaultFontPixelHeight * 1.5

        property var  bottomLoaderMargin:      _pipViewMargin >= parent.height / 2 ? parent.height / 2 : _pipViewMargin

        // Width is difficult to access directly hence this hack which may not work in all circumstances
        property real leftEdgeBottomInset:  visible ? bottomEdgeLeftInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rightEdgeBottomInset: visible ? bottomEdgeRightInset + width/18 - ScreenTools.defaultFontPixelHeight*2 : 0
        property real rootWidth:            _root.width
        property var  itemX:                virtualJoystickMultiTouch.x   // real X on screen

        onRootWidthChanged: virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth : undefined
        onItemXChanged:     virtualJoystickMultiTouch.status == Loader.Ready && visible ? virtualJoystickMultiTouch.item.uiRealX = itemX : undefined

        //Loader status logic
        onLoaded: {
            if (virtualJoystickMultiTouch.visible) {
                virtualJoystickMultiTouch.item.calibration = true
                virtualJoystickMultiTouch.item.uiTotalWidth = rootWidth
                virtualJoystickMultiTouch.item.uiRealX = itemX
            } else {
                virtualJoystickMultiTouch.item.calibration = false
            }
        }
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                false //!QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: preFlightChecklistPopup.createObject(mainWindow).open()


        property real topEdgeLeftInset:     visible ? y + height : 0
        property real leftEdgeTopInset:     visible ? x + width : 0
        property real leftEdgeCenterInset:  leftEdgeTopInset
    }

    GripperMenu {
        id: gripperOptions
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       toolStrip.right
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      true
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && !isViewer3DOpen && mapControl.pipState.state === mapControl.pipState.fullState

        property real topEdgeCenterInset: visible ? y + height : 0
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
}
