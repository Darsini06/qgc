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
        console.log("pipView.visible :", pipview.visible);
        console.log("_pipView.visible :", _pipView.visible);
    }


    ColumnLayout {
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
                color: "#1b1c3e"
                visible: true
                border.width: width * 0.05    // 10% of button width
                border.color: "#005BBB"

                QGCColoredImage {
                    id: flightModeIndicator2
                    source: "/qmlimages/NewImages/savedfiles.png" //"/qmlimages/NewImages/log.png"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
                    color: "transparent"
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
            //     color: "#1b1c3e"
            //     visible: true
            //     border.width: width * 0.05    // 10% of button width
            //     border.color: "#005BBB"

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
                color: "#1b1c3e"      // white background
                visible:  true
                border.width: width * 0.05
                border.color: "#005BBB"

                QGCColoredImage {
                    id: takeofficon
                    source: "/qmlimages/NewImages/takeOff.png"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
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

            Rectangle {
                id: waypointbtn
                Layout.alignment: Qt.AlignLeft
                width: parent.width * 0.05    // 8% of parent width
                height: width                 // Keep it square
                radius: width / 2   // Makes it a circle
                color: "#1b1c3e"      // white background
                visible:  true
                border.width: width * 0.05
                border.color: "#005BBB"

                QGCColoredImage {
                    id: waypointbtnicon1
                    source: "/qmlimages/MapAddMission.svg"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
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

            // Rectangle {
            //     id: eraserbtn
            //     Layout.alignment: Qt.AlignLeft
            //     width: parent.width * 0.05    // 8% of parent width
            //     height: width                 // Keep it square
            //     radius: width / 2   // Makes it a circle
            //     color: "#1b1c3e"      // white background
            //     visible:  false
            //     border.width: width * 0.05
            //     border.color: "#005BBB"



            //     QGCColoredImage {
            //         id: eraserbtnicon
            //         source: "/qmlimages/NewImages/map_eraser.png"
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
                color: "#1b1c3e"      // white background
                visible:  true
                border.width: width * 0.05
                border.color: "#005BBB"

                QGCColoredImage {
                    id: camerabtnicon
                    source: "/qmlimages/NewImages/takeOff.png"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
                    color: "white"
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
                color: "#1b1c3e"      // white background
                visible:  true
                border.width: width * 0.05
                border.color: "#005BBB"

                QGCColoredImage {
                    id: landbtnicon
                    source: "/qmlimages/NewImages/return.png"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {

                        myDialog.imageSource = "/qmlimages/NewImages/return.png";  // Set the image dynamically
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
                color: "#1b1c3e"      // white background
                visible:  true
                border.width: width * 0.05
                border.color: "#005BBB"

                QGCColoredImage {
                    id: rtlbtnicon
                    source: "/qmlimages/NewImages/landing.png"
                    width: parent.width * 0.5   // 60% of button size
                    height: width
                    anchors.centerIn: parent
                    color: "white"
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
                    color: "#1b1c3e"      // white background
                    visible:  true
                    border.width: width * 0.05
                    border.color: "#005BBB"

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
                color: "#1b1c3e"
                visible: activeVehicle

                border.width: 2
                border.color: "#005BBB"

                FlightModeIndicator {
                    id: flightmode1
                    //visible: true
                    anchors.centerIn: parent
                }
            }

        }



    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 10
        anchors.rightMargin: 20
        spacing: 20  // Adjust this value to control space between icons

        Rectangle {
            id: planbtn1
            Layout.alignment: Qt.AlignRight
            width: 100
            height: 38
            radius: width / 2  // Makes it a circle
            color: "#1b1c3e"     // white background
            visible: true

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
                // color: "#1b1c3e"
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
                // color: "#1b1c3e"
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
                // color: "#1b1c3e"
                // radius: 8
                // }
                // onClicked: console.log("Option 2 clicked")
                // }

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
