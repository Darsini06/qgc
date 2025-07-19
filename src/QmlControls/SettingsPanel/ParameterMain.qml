import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtPositioning


import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette

import QGroundControl.QGCPositionManager



import QGroundControl.FactSystem

import QGroundControl.Controllers
import QGroundControl.ArduPilot
import QGroundControl.QGCPositionManager
import MAVLink

Item {
    anchors.fill: parent
property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property int selectedTabIndex: 0  // Default selected tab is "Sensor"
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            z: -10
            color: "#1b1c3e"
        }
        // ---- Curved Gradient Background ----
        Canvas {
            anchors.fill: parent
            z: -1
            opacity: 0.95
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                // ðŸŽ¨ Create diagonal gradient
                var gradient = ctx.createLinearGradient(0, 0, width, height)
                gradient.addColorStop(0, "#14163C")
                gradient.addColorStop(1, "#6A85FB")
                ctx.fillStyle = gradient

                // ðŸŒ€ Create a curved path from top-left to bottom-right
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.quadraticCurveTo(width * 0.4, height * 0.1, width, height * 0.9)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
            }
        }

        Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: parent.width * 0.7
                height: parent.height * 0.9
                radius: width * 0.5
                rotation: 30
                opacity: 0.95
                anchors.rightMargin: -width * 0.25
                anchors.bottomMargin: -height * 0.2
                z: -1

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#14163C" } // Deep indigo
                    GradientStop { position: 1.0; color: "#6A85FB" } // Blue gradient
                }
            }




    }




    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0
        // Selected Component Below Tab Bar
        Loader {
            id: tabLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: activeVehicle?sensorComponent:sensorComponent1
        }
    }

    Component {
        id: sensorComponent1
        Item {
            anchors.fill: parent
            ColumnLayout {
                anchors.fill: parent
                spacing: 10



                // GridView for calibration buttons
                GridView {
                    id: gridView

                    property bool buttonsEnabled: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.ceil(count / 3) * (cellHeight + 10) // Calculate height based on items
                    //Layout.alignment: Qt.AlignHCenter
                    cellWidth: width / 3
                    cellHeight: ScreenTools.defaultFontPixelHeight * 7
                    clip: true
                    model: ListModel {
                        ListElement {
                            name: "Accelerometer"
                            type: "accel"
                            indicator: true
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }
                        ListElement {
                            name: "Compass"
                            type: "compass"
                            indicator: true
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }
                        ListElement {
                            name: "Level Horizon"
                            type: "level"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                        ListElement {
                            name: "Gyro"
                            type: "gyro"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                        ListElement {
                            name: "Pressure"
                            type: "pressure"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                        ListElement {
                            name: "RC Calibration"
                            type: "rc"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }

                        ListElement {
                            name: "Flight Modes"
                            type: "flightModes"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }

                        ListElement {
                            name: "ESC Calibration"
                            type: "esc"
                            //globals.activeVehicle ? globals.activeVehicle.supportsMotorInterference : false
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }

                        ListElement {
                            name: "Motors"
                            type: "motors"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }

                        ListElement {
                            name: "Tunning"
                            type: "tuning"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                    }

                    delegate: Item {
                        width: gridView.cellWidth
                        height: gridView.cellHeight
                        // Dynamic visibility for some buttons


                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            color: {
                                if (model.status === "success") return "#2ecc71";   // Success: Green
                                if (model.status === "failure") return "#e74c3c";   // Failure: Red

                                switch (model.type) {
                                    case "accel":        return "#2980b9";  // Blue
                                    case "compass":      return "#8e44ad";  // Purple
                                    case "level":        return "#16a085";  // Teal
                                    case "gyro":         return "#d35400";  // Orange
                                    case "pressure":     return "#f39c12";  // Yellow Orange
                                    case "rc":           return "#2c3e50";  // Navy Blue
                                    case "flightModes":  return "#c0392b";  // Dark Red
                                    case "esc":          return "#27ae60";  // Green
                                    case "motors":       return "#7f8c8d";  // Gray
                                    case "tuning":       return "#9b59b6";  // Light Purple
                                    default:             return qgcPal.button;
                                }
                            }

                            radius: 10
                            border.color: qgcPal.buttonText
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                width: parent.width

                                // Icon above the text
                                Image {
                                    source: model.icon
                                    width: 32
                                    height: 32
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fillMode: Image.PreserveAspectFit
                                }

                                // Label below the icon
                                QGCLabel {
                                    text: model.name//model.type === "pressure" ? _calibratePressureText : model.name
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    wrapMode: Text.WordWrap
                                    font.bold: true
                                }
                            }

                            // Indicator for calibration status
                            Rectangle {
                                visible: model.indicator
                                width: ScreenTools.defaultFontPixelHeight * 0.75
                                height: width
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 5
                                radius: width * 0.5
                                color: {
                                    if (model.type === "accel") return !controller.accelSetupNeeded ? "green" : "red";
                                    if (model.type === "compass") return !controller.compassSetupNeeded ? "green" : "red";
                                    return "transparent";
                                }
                            }

                            // QGCLabel {
                            //     anchors.centerIn: parent
                            //     text: {
                            //         if (model.type === "pressure") return _calibratePressureText;
                            //         return model.name;
                            //     }
                            //     color: qgcPal.buttonText
                            // }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                enabled: gridView.buttonsEnabled
                                onClicked: handleButtonClick(model.type)
                            }
                        }

                    }
                }

                Row {
                    id: buttonRow
                    spacing: 20
                    //anchors.horizontalCenter: parent.horizontalCenter
                    //anchors.topMargin: 10

                    Button {
                        id: nextButton
                        text: "Next"
                        visible: false
                        onClicked: {
                            console.log("Next button clicked")
                            controller.nextClicked()
                        }
                    }

                    Button {
                        id: cancelButton
                        text: "Cancel"
                        visible: false
                        onClicked: {
                            console.log("Cancel button clicked")
                            controller.stopCalibration()  // Ensure this method exists in APMSensorsComponentController
                        }
                    }
                }
            }
       }
    }

    Component {
        id: sensorComponent

        Item {
            anchors.fill: parent
            // Help text which is shown both in the status text area prior to pressing a cal button and in the
            // pre-calibration dialog.

            readonly property string orientationHelpSet:    qsTr("If mounted in the direction of flight, select None.")
            readonly property string orientationHelpCal:    qsTr("Before calibrating make sure rotation settings are correct. ") + orientationHelpSet
            readonly property string compassRotationText:   qsTr("If the compass or GPS module is mounted in flight direction, leave the default value (None)")

            readonly property string compassHelp:   qsTr("For Compass calibration you will need to rotate your vehicle through a number of positions.")
            readonly property string gyroHelp:      qsTr("For Gyroscope calibration you will need to place your vehicle on a surface and leave it still.")
            readonly property string accelHelp:     qsTr("For Accelerometer calibration you will need to place your vehicle on all six sides on a perfectly level surface and hold it still in each orientation for a few seconds.")
            readonly property string levelHelp:     qsTr("To level the horizon you need to place the vehicle in its level flight position and press OK.")

            readonly property string statusTextAreaDefaultText: qsTr("Start the individual calibration steps by clicking one of the buttons to the left.")

            // Used to pass help text to the preCalibrationDialog dialog
            property string preCalibrationDialogHelp

            property string _postCalibrationDialogText
            property var    _postCalibrationDialogParams

            readonly property string _badCompassCalText: qsTr("The calibration for Compass %1 appears to be poor. ") +
                                                         qsTr("Check the compass position within your vehicle and re-do the calibration.")

            readonly property int sideBarH1PointSize:  ScreenTools.mediumFontPointSize
            readonly property int mainTextH1PointSize: ScreenTools.mediumFontPointSize // Seems to be unused

            readonly property int rotationColumnWidth: 250

            property Fact noFact: Fact { }

            property bool accelCalNeeded:                   controller.accelSetupNeeded
            property bool compassCalNeeded:                 controller.compassSetupNeeded

            property Fact boardRot:                         controller.getParameterFact(-1, "AHRS_ORIENTATION")

            readonly property int _calTypeCompass:  1   ///< Calibrate compass
            readonly property int _calTypeAccel:    2   ///< Calibrate accel
            readonly property int _calTypeSet:      3   ///< Set orientations only
            readonly property int _buttonWidth:     ScreenTools.defaultFontPixelWidth * 15

            property bool   _orientationsDialogShowCompass: true
            property string _orientationDialogHelp:         orientationHelpSet
            property int    _orientationDialogCalType:      -1
            property real   _margins:                       ScreenTools.defaultFontPixelHeight / 2
            property bool   _compassAutoRotAvailable:       controller.parameterExists(-1, "COMPASS_AUTO_ROT")
            property Fact   _compassAutoRotFact:            controller.getParameterFact(-1, "COMPASS_AUTO_ROT", false /* reportMissing */)
            property bool   _compassAutoRot:                _compassAutoRotAvailable ? _compassAutoRotFact.rawValue === 2 : false
            property bool   _showSimpleAccelCalOption:      false
            property bool   _doSimpleAccelCal:              false
            property var    _gcsPosition:                    QGroundControl.qgcPositionManager.gcsPosition
            property var    _mapPosition:                    QGroundControl.flightMapPosition

            property string _levelHorizonText:              qsTr("Level Horizon")

            property string _calibratePressureText:         globals.activeVehicle.fixedWing ? qsTr("Baro/Airspeed") : qsTr("Pressure")
            property string _altText:                       globals.activeVehicle.sub ? qsTr("depth") : qsTr("altitude")
            property string _helpTextFW:                    globals.activeVehicle.fixedWing ? qsTr("To calibrate the airspeed sensor shield it from the wind. Do not touch the sensor or obstruct any holes during the calibration.") : ""


            APMSensorParams {
                id:                     sensorParams
                factPanelController:    controller
            }

            APMSensorsComponentController {
                id:                         controller
                statusLog:                  statusTextArea
                progressBar:                progressBar
                nextButton:                 nextButton
                cancelButton:               cancelButton
                orientationCalAreaHelpText: orientationCalAreaHelpText

                property var rgCompassCalFitness: [ controller.compass1CalFitness, controller.compass2CalFitness, controller.compass3CalFitness ]

                onResetStatusTextArea: statusLog.text = statusTextAreaDefaultText

                onWaitingForCancelChanged: {
                    // if (controller.waitingForCancel) {
                    //     waitForCancelDialogComponent.createObject(mainWindow).open()
                    // }
                    if (controller.waitingForCancel) {
                        if (waitForCancelDialogComponent && mainWindow) {
                            let dialog = waitForCancelDialogComponent.createObject(mainWindow);
                            if (dialog) dialog.open();
                            else console.error("Dialog creation failed");
                        } else {
                            console.error("Dialog component or mainWindow not defined");
                        }
                    }
                }

                onCalibrationComplete: {
                    switch (calType) {
                    case MAVLink.CalibrationAccel:
                    case MAVLink.CalibrationMag:
                        console.log("MAVLink.CalibrationMag")
                        _singleCompassSettingsComponentShowPriority = true
                        postOnboardCompassCalibrationComponent.createObject(mainWindow).open()
                        break
                    }
                }

                onSetAllCalButtonsEnabled: function(enabled) {
                    handleSetAllCalButtonsEnabled(enabled)
                }

            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                ProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
                    visible: false //controller.calibrationInProgress
                }

                TextArea {
                    id: statusTextArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    text: statusTextAreaDefaultText
                    color: qgcPal.text
                    background: Rectangle { color: qgcPal.windowShade }
                    visible: false //!controller.showOrientationCalArea
                }

                Rectangle {
                    id: orientationCalArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: false //controller.showOrientationCalArea
                    color: qgcPal.windowShade

                    QGCLabel {
                        id: orientationCalAreaHelpText
                        anchors.margins: ScreenTools.defaultFontPixelWidth
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pointSize: ScreenTools.mediumFontPointSize
                    }

                    Flow {
                        anchors.topMargin: ScreenTools.defaultFontPixelWidth
                        anchors.top: orientationCalAreaHelpText.bottom
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: ScreenTools.defaultFontPixelWidth

                        property real indicatorWidth: (width / 3) - (spacing * 2)
                        property real indicatorHeight: (height / 2) - spacing

                        VehicleRotationCal {
                            width:              parent.indicatorWidth
                            height:             parent.indicatorHeight
                            visible:            controller.orientationCalDownSideVisible
                            calValid:           controller.orientationCalDownSideDone
                            calInProgress:      controller.orientationCalDownSideInProgress
                            calInProgressText:  controller.orientationCalDownSideRotate ? qsTr("Rotate") : qsTr("Hold Still")
                            imageSource:        "qrc:///qmlimages/VehicleDown.png"
                        }
                        VehicleRotationCal {
                            width:              parent.indicatorWidth
                            height:             parent.indicatorHeight
                            visible:            controller.orientationCalLeftSideVisible
                            calValid:           controller.orientationCalLeftSideDone
                            calInProgress:      controller.orientationCalLeftSideInProgress
                            calInProgressText:  controller.orientationCalLeftSideRotate ? qsTr("Rotate") : qsTr("Hold Still")
                            imageSource:        "qrc:///qmlimages/VehicleLeft.png"
                        }
                        VehicleRotationCal {
                            width:              parent.indicatorWidth
                            height:             parent.indicatorHeight
                            visible:            controller.orientationCalRightSideVisible
                            calValid:           controller.orientationCalRightSideDone
                            calInProgress:      controller.orientationCalRightSideInProgress
                            calInProgressText:  controller.orientationCalRightSideRotate ? qsTr("Rotate") : qsTr("Hold Still")
                            imageSource:        "qrc:///qmlimages/VehicleRight.png"
                        }
                        VehicleRotationCal {
                            width:              parent.indicatorWidth
                            height:             parent.indicatorHeight
                            visible:            controller.orientationCalNoseDownSideVisible
                            calValid:           controller.orientationCalNoseDownSideDone
                            calInProgress:      controller.orientationCalNoseDownSideInProgress
                            calInProgressText:  controller.orientationCalNoseDownSideRotate ? qsTr("Rotate") : qsTr("Hold Still")
                            imageSource:        "qrc:///qmlimages/VehicleNoseDown.png"
                        }
                        VehicleRotationCal {
                            width:              parent.indicatorWidth
                            height:             parent.indicatorHeight
                            visible:            controller.orientationCalTailDownSideVisible
                            calValid:           controller.orientationCalTailDownSideDone
                            calInProgress:      controller.orientationCalTailDownSideInProgress
                            calInProgressText:  controller.orientationCalTailDownSideRotate ? qsTr("Rotate") : qsTr("Hold Still")
                            imageSource:        "qrc:///qmlimages/VehicleTailDown.png"
                        }
                        VehicleRotationCal {
                            width:              parent.indicatorWidth
                            height:             parent.indicatorHeight
                            visible:            controller.orientationCalUpsideDownSideVisible
                            calValid:           controller.orientationCalUpsideDownSideDone
                            calInProgress:      controller.orientationCalUpsideDownSideInProgress
                            calInProgressText:  controller.orientationCalUpsideDownSideRotate ? qsTr("Rotate") : qsTr("Hold Still")
                            imageSource:        "qrc:///qmlimages/VehicleUpsideDown.png"
                        }
                    }
                }

                // GridView for calibration buttons
                GridView {
                    id: gridView

                    property bool buttonsEnabled: true

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.ceil(count / 3) * (cellHeight + 10) // Calculate height based on items
                    //Layout.alignment: Qt.AlignHCenter
                    cellWidth: width / 3
                    cellHeight: ScreenTools.defaultFontPixelHeight * 7
                    clip: true
                    model: ListModel {
                        ListElement {
                            name: "Accelerometer"
                            type: "accel"
                            indicator: true
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }
                        ListElement {
                            name: "Compass"
                            type: "compass"
                            indicator: true
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }
                        ListElement {
                            name: "Level Horizon"
                            type: "level"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                        ListElement {
                            name: "Gyro"
                            type: "gyro"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                        ListElement {
                            name: "Pressure"
                            type: "pressure"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                        ListElement {
                            name: "RC Calibration"
                            type: "rc"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }

                        ListElement {
                            name: "Flight Modes"
                            type: "flightModes"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }

                        ListElement {
                            name: "ESC Calibration"
                            type: "esc"
                            //globals.activeVehicle ? globals.activeVehicle.supportsMotorInterference : false
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }

                        ListElement {
                            name: "Motors"
                            type: "motors"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"
                        }

                        ListElement {
                            name: "Tunning"
                            type: "tuning"
                            icon: "/qmlimages/NewImages/homeIcon.png"
                            status: "none"

                        }
                    }

                    delegate: Item {
                        width: gridView.cellWidth
                        height: gridView.cellHeight
                        // Dynamic visibility for some buttons
                        visible:  {
                            if (model.type === "gyro") {
                                return globals.activeVehicle &&
                                        (globals.activeVehicle.multiRotor ||
                                         globals.activeVehicle.rover ||
                                         globals.activeVehicle.sub);
                            }
                            if (model.type === "compassMot") {
                                return globals.activeVehicle ? globals.activeVehicle.supportsMotorInterference : false;
                            }
                            return true;
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            color: {
                                if (model.status === "success") return "lightgreen";
                                if (model.status === "failure") return "#ff9999";
                                return mouseArea.containsPress ? qgcPal.buttonHighlight : qgcPal.button;
                            }
                            radius: 5
                            border.color: qgcPal.buttonText
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 5
                                width: parent.width

                                // Icon above the text
                                Image {
                                    source: model.icon
                                    width: 32
                                    height: 32
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fillMode: Image.PreserveAspectFit
                                }

                                // Label below the icon
                                QGCLabel {
                                    text: model.type === "pressure" ? _calibratePressureText : model.name
                                    color: qgcPal.buttonText
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            // Indicator for calibration status
                            Rectangle {
                                visible: model.indicator
                                width: ScreenTools.defaultFontPixelHeight * 0.75
                                height: width
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 5
                                radius: width * 0.5
                                color: {
                                    if (model.type === "accel") return !controller.accelSetupNeeded ? "green" : "red";
                                    if (model.type === "compass") return !controller.compassSetupNeeded ? "green" : "red";
                                    return "transparent";
                                }
                            }

                            // QGCLabel {
                            //     anchors.centerIn: parent
                            //     text: {
                            //         if (model.type === "pressure") return _calibratePressureText;
                            //         return model.name;
                            //     }
                            //     color: qgcPal.buttonText
                            // }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                enabled: gridView.buttonsEnabled
                                onClicked: handleButtonClick(model.type)
                            }
                        }

                    }
                }

                Row {
                    id: buttonRow
                    spacing: 20
                    //anchors.horizontalCenter: parent.horizontalCenter
                    //anchors.topMargin: 10

                    Button {
                        id: nextButton
                        text: "Next"
                        visible: false
                        onClicked: {
                            console.log("Next button clicked")
                            controller.nextClicked()
                        }
                    }

                    Button {
                        id: cancelButton
                        text: "Cancel"
                        visible: false
                        onClicked: {
                            console.log("Cancel button clicked")
                            controller.stopCalibration()  // Ensure this method exists in APMSensorsComponentController
                        }
                    }
                }
            }

            Item {
                id: toastContainer
                anchors.bottom: parent.bottom
                //anchors.horizontalCenter: parent.horizontalCenter
                //anchors.verticalCenter: parent.verticalCenter
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



            function handleSetAllCalButtonsEnabled(enabled) {
                console.log("Enabled value received:", enabled)
                if (gridView !== null && typeof gridView !== "undefined") {
                    console.log("handleSetAllCalButtonsEnabled: " + enabled)
                    gridView.buttonsEnabled = enabled
                } else {
                    console.warn("gridView is undefined in handleSetAllCalButtonsEnabled")
                }
            }

            Component.onCompleted: {
                handleSetAllCalButtonsEnabled(true)
            }

            Connections {
                target: controller

                onUpdateCalibrationStatus: function(type, status) {
                        for (let i = 0; i < gridView.model.count; ++i) {
                            let item = gridView.model.get(i)
                            if (item.type === type) {
                                gridView.model.setProperty(i, "status", status)
                                break
                            }
                        }
                    }

                onShowToastMessage: function(message) {
                    toastContainer.showToast(message);
                }

                onSetAllCalButtonsEnabled: function(enabled) {
                    handleSetAllCalButtonsEnabled(enabled)
                }
            }

            function showOrientationsDialog(calType) {
                var dialogTitle
                var dialogButtons = Dialog.Ok
                _showSimpleAccelCalOption = false

                console.log("showOrientationsDialog calType :",calType)

                _orientationDialogCalType = calType
                switch (calType) {
                case _calTypeCompass:
                    _orientationsDialogShowCompass = true
                    _orientationDialogHelp = orientationHelpCal
                    dialogTitle = qsTr("Calibrate Compass")
                    dialogButtons |= Dialog.Cancel
                    break
                case _calTypeAccel:
                    _orientationsDialogShowCompass = false
                    _orientationDialogHelp = orientationHelpCal
                    console.log("_calTypeAccel Switch case")
                    dialogTitle = qsTr("Calibrate Accelerometer")
                    dialogButtons |= Dialog.Cancel
                    break
                case _calTypeSet:
                    _orientationsDialogShowCompass = true
                    _orientationDialogHelp = orientationHelpSet
                    dialogTitle = qsTr("Sensor Settings")
                    break
                }

                // orientationsDialogComponent.createObject(mainWindow, { title: dialogTitle, buttons: dialogButtons }).open()

                // Create and open the dialog
                var dialog = orientationsDialogComponent.createObject(mainWindow, {
                                                                          calType: calType,
                                                                          showCompass: _orientationsDialogShowCompass,
                                                                          helpText: _orientationDialogHelp
                                                                      });
                dialog.open();
            }

            // function showSimpleAccelCalOption() {
            //     _showSimpleAccelCalOption = true
            // }

            function handleButtonClick(buttonType) {

                controller.setCurrentCalibrationType(buttonType);

                console.log("Clicked type:", buttonType)
                switch(buttonType) {
                case "accel":
                    showOrientationsDialog(_calTypeAccel);
                    //showSimpleAccelCalOption();
                    break;

                case "compass":
                    if (controller.accelSetupNeeded) {
                        mainWindow.showMessageDialog(qsTr("Calibrate Compass"),
                                                     qsTr("Accelerometer must be calibrated prior to Compass."));
                    } else {
                        showOrientationsDialog(_calTypeCompass);
                    }
                    break;

                case "level":
                    if (controller.accelSetupNeeded) {
                        mainWindow.showMessageDialog(_levelHorizonText,
                                                     qsTr("Accelerometer must be calibrated prior to Level Horizon."));
                    } else {
                        console.log("Level horizon else part:", _levelHorizonText)
                        mainWindow.showMessageDialog(
                                    _levelHorizonText,
                                    qsTr("To level the horizon you need to place the vehicle in its level flight position and press Ok."),
                                    Dialog.Cancel | Dialog.Ok,
                                    function() { controller.levelHorizon() }
                                    );
                    }
                    break;

                case "gyro":
                    mainWindow.showMessageDialog(
                                qsTr("Calibrate Gyro"),
                                qsTr("For Gyroscope calibration you will need to place your vehicle on a surface and leave it still.\n\nClick Ok to start calibration."),
                                Dialog.Cancel | Dialog.Ok,
                                function() { controller.calibrateGyro() }
                                );
                    break;

                case "pressure":
                    mainWindow.showMessageDialog(
                                _calibratePressureText,
                                qsTr("Pressure calibration will set the %1 to zero at the current pressure reading. %2").arg(_altText).arg(_helpTextFW),
                                Dialog.Cancel | Dialog.Ok,
                                function() { controller.calibratePressure() }
                                );
                    break;

                    // case "compassMot":
                    //     compassMotDialogComponent.createObject(mainWindow).open();
                    //     break;

                    // case "settings":
                    //     showOrientationsDialog(_calTypeSet);
                    //     break;

                case "rc":
                    showDynamicCalibrationDialog("qrc:/qml/RadioComponent.qml","RC Calibration");
                    break;

                case "esc":
                    showDynamicCalibrationDialog("qrc:/qml/APMPowerComponent.qml","ESC Calibration");
                    break;

                case "flightModes":
                    showDynamicCalibrationDialog("qrc:/qml/APMFlightModesComponent.qml","Flight Modes");
                    break;

                case "tuning":
                    showDynamicCalibrationDialog("qrc:/qml/APMTuningComponentCopter.qml","Tunning");
                    break;

                case "motors":
                    showDynamicCalibrationDialog("qrc:/qml/APMMotorComponent.qml","Motors");
                    break;
                }
            }

            function showDynamicCalibrationDialog(qmlFile,title) {
                dynamicCalDialog.dialogTitleText = title
                dialogLoader.source = qmlFile
                dynamicCalDialog.open()
            }


            function compassLabel(index)
            {
                var label = qsTr("Compass %1 ").arg(index+1)
                var addOpenParan = true
                var addComma = false
                if (sensorParams.compassPrimaryFactAvailable) {
                    label += sensorParams.rgCompassPrimary[index] ? qsTr("(primary") : qsTr("(secondary")
                    addComma = true
                    addOpenParan = false
                }
                if (sensorParams.rgCompassExternalParamAvailable[index]) {
                    if (addOpenParan) {
                        label += "("
                    }
                    if (addComma) {
                        label += qsTr(", ")
                    }
                    label += sensorParams.rgCompassExternal[index] ? qsTr("external") : qsTr("internal")
                }
                label += ")"
                return label
            }

            QGCPalette { id: qgcPal; colorGroupEnabled: true }

            Component {
                id: waitForCancelDialogComponent

                QGCSimpleMessageDialog {
                    title:      qsTr("Calibration Cancel")
                    text:       qsTr("Waiting for Vehicle to response to Cancel. This may take a few seconds.")
                    buttons:    0

                    Connections {
                        target: controller

                        onWaitingForCancelChanged: {
                            if (!controller.waitingForCancel) {
                                close()
                            }
                        }
                    }
                }
            }

            Component {
                id: singleCompassOnboardResultsComponent

                Column {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        Math.round(ScreenTools.defaultFontPixelHeight / 2)
                    visible:        sensorParams.rgCompassAvailable[index] && sensorParams.rgCompassUseFact[index].value

                    property int _index: index

                    property real greenMaxThreshold:   8 * (sensorParams.rgCompassExternal[index] ? 1 : 2)
                    property real yellowMaxThreshold:  15 * (sensorParams.rgCompassExternal[index] ? 1 : 2)
                    property real fitnessRange:        25 * (sensorParams.rgCompassExternal[index] ? 1 : 2)

                    Item {
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         ScreenTools.defaultFontPixelHeight

                        Row {
                            id:             fitnessRow
                            anchors.fill:   parent

                            Rectangle {
                                width:  parent.width * (greenMaxThreshold / fitnessRange)
                                height: parent.height
                                color:  "green"
                            }
                            Rectangle {
                                width:  parent.width * ((yellowMaxThreshold - greenMaxThreshold) / fitnessRange)
                                height: parent.height
                                color:  "yellow"
                            }
                            Rectangle {
                                width:  parent.width * ((fitnessRange - yellowMaxThreshold) / fitnessRange)
                                height: parent.height
                                color:  "red"
                            }
                        }

                        Rectangle {
                            height:                 fitnessRow.height * 0.66
                            width:                  height
                            anchors.verticalCenter: fitnessRow.verticalCenter
                            x:                      (fitnessRow.width * (Math.min(Math.max(controller.rgCompassCalFitness[index], 0.0), fitnessRange) / fitnessRange)) - (width / 2)
                            radius:                 height / 2
                            color:                  "white"
                            border.color:           "black"
                        }
                    }

                    Loader {
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 2
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        sourceComponent:    singleCompassSettingsComponent

                        property int index: _index
                    }
                }
            }

            Component {
                id: postOnboardCompassCalibrationComponent

                QGCPopupDialog {
                    id:         postOnboardCompassCalibrationDialog
                    title:      qsTr("Calibration complete")
                    buttons:    Dialog.Ok

                    Column {
                        width:      40 * ScreenTools.defaultFontPixelWidth
                        spacing:    ScreenTools.defaultFontPixelHeight

                        Repeater {
                            model:      3
                            delegate:   singleCompassOnboardResultsComponent
                        }

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("Shown in the indicator bars is the quality of the calibration for each compass.\n\n") +
                                            qsTr("- Green indicates a well functioning compass.\n") +
                                            qsTr("- Yellow indicates a questionable compass or calibration.\n") +
                                            qsTr("- Red indicates a compass which should not be used.\n\n") +
                                            qsTr("YOU MUST REBOOT YOUR VEHICLE AFTER EACH CALIBRATION.")
                        }

                        QGCButton {
                            text:       qsTr("Reboot Vehicle")
                            onClicked: {
                                controller.vehicle.rebootVehicle()
                                postOnboardCompassCalibrationDialog.close()
                            }
                        }
                    }
                }
            }

            Component {
                id: postCalibrationComponent

                QGCPopupDialog {
                    id:     postCalibrationDialog
                    title:  qsTr("Calibration complete")

                    Column {
                        width:      40 * ScreenTools.defaultFontPixelWidth
                        spacing:    ScreenTools.defaultFontPixelHeight

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("YOU MUST REBOOT YOUR VEHICLE AFTER EACH CALIBRATION.")
                        }

                        QGCButton {
                            text:       qsTr("Reboot Vehicle")
                            onClicked: {
                                controller.vehicle.rebootVehicle()
                                postCalibrationDialog.close()
                            }
                        }
                    }
                }
            }

            property bool _singleCompassSettingsComponentShowPriority: true

            Component {
                id: singleCompassSettingsComponent

                Column {
                    spacing: Math.round(ScreenTools.defaultFontPixelHeight / 2)
                    visible: sensorParams.rgCompassAvailable[index]

                    QGCLabel {
                        text: compassLabel(index)
                    }
                    APMSensorIdDecoder {
                        fact: sensorParams.rgCompassId[index]
                    }

                    Column {
                        anchors.margins:    ScreenTools.defaultFontPixelWidth * 2
                        anchors.left:       parent.left
                        spacing:            Math.round(ScreenTools.defaultFontPixelHeight / 4)

                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth

                            FactCheckBox {
                                id:         useCompassCheckBox
                                text:       qsTr("Use Compass")
                                fact:       sensorParams.rgCompassUseFact[index]
                                visible:    sensorParams.rgCompassUseParamAvailable[index] && !sensorParams.rgCompassPrimary[index]
                            }

                            QGCComboBox {
                                model:      [ qsTr("Priority 1"), qsTr("Priority 2"), qsTr("Priority 3"), qsTr("Not Set") ]
                                visible:    _singleCompassSettingsComponentShowPriority && sensorParams.compassPrioFactsAvailable && useCompassCheckBox.visible && useCompassCheckBox.checked

                                property int _compassIndex: index

                                function selectPriorityfromParams() {
                                    currentIndex = 3
                                    var compassId = sensorParams.rgCompassId[_compassIndex].rawValue
                                    for (var prioIndex=0; prioIndex<3; prioIndex++) {
                                        console.log(`comparing ${compassId} with ${sensorParams.rgCompassPrio[prioIndex].rawValue} (index ${prioIndex})`)
                                        if (compassId === sensorParams.rgCompassPrio[prioIndex].rawValue) {
                                            currentIndex = prioIndex
                                            break
                                        }
                                    }
                                }

                                Component.onCompleted: selectPriorityfromParams()

                                onActivated: (index) => {
                                                 if (index === 3) {
                                                     // User cannot select Not Set
                                                     selectPriorityfromParams()
                                                 } else {
                                                     sensorParams.rgCompassPrio[index].rawValue = sensorParams.rgCompassId[_compassIndex].rawValue
                                                 }
                                             }
                            }
                        }

                        Column {
                            visible: !_compassAutoRot && sensorParams.rgCompassExternal[index] && sensorParams.rgCompassRotParamAvailable[index]

                            QGCLabel { text: qsTr("Orientation:") }

                            FactComboBox {
                                width:      rotationColumnWidth
                                indexModel: false
                                fact:       sensorParams.rgCompassRotFact[index]
                            }
                        }
                    }
                }
            }

            Component {
                id: orientationsDialogComponent

                QGCPopupDialog {
                    id: dialog
                    property int calType: -1
                    property bool showCompass: true
                    property string helpText: ""
                    property bool simpleAccelCal: false

                    function compassMask () {
                        var mask = 0
                        mask |=  (0 + (sensorParams.rgCompassPrio[0].rawValue !== 0)) << 0
                        mask |=  (0 + (sensorParams.rgCompassPrio[1].rawValue !== 0)) << 1
                        mask |=  (0 + (sensorParams.rgCompassPrio[2].rawValue !== 0)) << 2
                        return mask
                    }

                    title: {
                        switch(calType) {
                        case _calTypeCompass: return qsTr("Calibrate Compass");
                        case _calTypeAccel: return qsTr("Calibrate Accelerometer");
                        case _calTypeSet: return qsTr("Sensor Settings");
                        default: return "";
                        }
                    }

                    buttons: {
                        var btns = Dialog.Ok;
                        if (calType === _calTypeCompass || calType === _calTypeAccel) {
                            btns |= Dialog.Cancel;
                        }
                        return btns;
                    }

                    onAccepted: {
                        if (calType === _calTypeAccel) {
                            console.log("Calibrating Accelerometer with simpleAccelCal:", simpleAccelCal)
                            if (controller && controller.calibrateAccel) {
                                console.log("_orientationDialogCalType  == _calTypeAccel",calType)
                                controller.calibrateAccel(simpleAccelCal);
                            } else {
                                console.log("Controller or calibrateAccel method is undefined");
                            }

                        } else if (calType === _calTypeCompass) {
                            if (!northCalibrationCheckBox.checked) {
                                controller.calibrateCompass();
                            } else {
                                var lat = parseFloat(northCalLat.text);
                                var lon = parseFloat(northCalLon.text);
                                if (useMapPositionCheckbox.checked) {
                                    lat = _mapPosition.latitude;
                                    lon = _mapPosition.longitude;
                                }
                                if (useGcsPositionCheckbox.checked) {
                                    lat = _gcsPosition.latitude;
                                    lon = _gcsPosition.longitude;
                                }
                                if (isNaN(lat) || isNaN(lon)) {
                                    return;
                                }
                                controller.calibrateCompassNorth(lat, lon, compassMask());
                            }
                        }
                    }

                    Column {
                        width:      40 * ScreenTools.defaultFontPixelWidth
                        spacing:    ScreenTools.defaultFontPixelHeight

                        QGCLabel {
                            width:      parent.width
                            wrapMode:   Text.WordWrap
                            text:       _orientationDialogHelp
                        }

                        Column {
                            QGCLabel { text: qsTr("Autopilot Rotation:") }

                            FactComboBox {
                                width:      rotationColumnWidth
                                indexModel: false
                                fact:       boardRot
                            }
                        }

                        Column {
                            visible: calType === _calTypeAccel
                            spacing: ScreenTools.defaultFontPixelHeight

                            QGCLabel {
                                width:      parent.width
                                wrapMode:   Text.WordWrap
                                text: qsTr("Simple accelerometer calibration is less precise but allows calibrating without rotating the vehicle. Check this if you have a large/heavy vehicle.")
                            }

                            QGCCheckBox {
                                text: "Simple Accelerometer Calibration"
                                onClicked: simpleAccelCal = this.checked
                            }
                        }

                        Repeater {
                            model:      _orientationsDialogShowCompass ? 3 : 0
                            delegate:   singleCompassSettingsComponent
                        }

                        QGCLabel {
                            id:         magneticDeclinationLabel
                            width:      parent.width
                            visible:    globals.activeVehicle.sub && _orientationsDialogShowCompass
                            text:       qsTr("Magnetic Declination")
                        }

                        Column {
                            visible:            magneticDeclinationLabel.visible
                            anchors.margins:    ScreenTools.defaultFontPixelWidth
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            spacing:            ScreenTools.defaultFontPixelHeight

                            QGCCheckBox {
                                id:                           manualMagneticDeclinationCheckBox
                                text:                         qsTr("Manual Magnetic Declination")
                                property Fact autoDecFact:    controller.getParameterFact(-1, "COMPASS_AUTODEC")
                                property int manual:          0
                                property int automatic:       1

                                checked:    autoDecFact.rawValue === manual
                                onClicked:  autoDecFact.value = (checked ? manual : automatic)
                            }

                            FactTextField {
                                fact:       sensorParams.declinationFact
                                enabled:    manualMagneticDeclinationCheckBox.checked
                            }
                        }

                        Item { height: ScreenTools.defaultFontPixelHeight; width: 10 } // spacer

                        QGCLabel {
                            id:         northCalibrationLabel
                            width:      parent.width
                            visible:    _orientationsDialogShowCompass
                            wrapMode:   Text.WordWrap
                            text:       qsTr("Fast compass calibration given vehicle position and yaw. This ") +
                                        qsTr("results in zero diagonal and off-diagonal elements, so is only ") +
                                        qsTr("suitable for vehicles where the field is close to spherical. It is ") +
                                        qsTr("useful for large vehicles where moving the vehicle to calibrate it ") +
                                        qsTr("is difficult. Point the vehicle North before using it.")
                        }

                        Column {
                            visible:            northCalibrationLabel.visible
                            anchors.margins:    ScreenTools.defaultFontPixelWidth
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            spacing:            ScreenTools.defaultFontPixelHeight

                            QGCCheckBox {
                                id:             northCalibrationCheckBox
                                visible:        northCalibrationLabel.visible
                                text:           qsTr("Fast Calibration")
                            }

                            QGCLabel {
                                id:         northCalibrationManualPosition
                                width:      parent.width
                                visible:    northCalibrationCheckBox.checked && !globals.activeVehicle.coordinate.isValid
                                wrapMode:   Text.WordWrap
                                text:       qsTr("Vehicle has no Valid positon, please provide it")
                            }

                            QGCCheckBox {
                                visible:    northCalibrationManualPosition.visible && _gcsPosition.isValid
                                id:         useGcsPositionCheckbox
                                text:       qsTr("Use GCS position instead")
                                checked:    _gcsPosition.isValid
                            }
                            QGCCheckBox {
                                visible:    northCalibrationManualPosition.visible && !_gcsPosition.isValid
                                id:         useMapPositionCheckbox
                                text:       qsTr("Use current map position instead")
                            }

                            QGCLabel {
                                width:      parent.width
                                visible:    useMapPositionCheckbox.checked
                                wrapMode:   Text.WordWrap
                                text:       qsTr(`Lat: ${_mapPosition.latitude.toFixed(4)} Lon: ${_mapPosition.longitude.toFixed(4)}`)
                            }

                            FactTextField {
                                id:         northCalLat
                                visible:    !useGcsPositionCheckbox.checked && !useMapPositionCheckbox.checked && northCalibrationCheckBox.checked
                                text:       "0.00"
                                textColor:  isNaN(parseFloat(text)) ? qgcPal.warningText: qgcPal.textFieldText
                                enabled:    !useGcsPositionCheckbox.checked
                            }

                            FactTextField {
                                id:         northCalLon
                                visible:    !useGcsPositionCheckbox.checked && !useMapPositionCheckbox.checked && northCalibrationCheckBox.checked
                                text:       "0.00"
                                textColor:  isNaN(parseFloat(text)) ? qgcPal.warningText: qgcPal.textFieldText
                                enabled:    !useGcsPositionCheckbox.checked
                            }

                        }
                    }
                }
            }

            Component {
                id: compassMotDialogComponent

                QGCPopupDialog {
                    title:      qsTr("Compass Motor Interference Calibration")
                    buttons:    Dialog.Cancel | Dialog.Ok

                    onAccepted: controller.calibrateMotorInterference()

                    Column {
                        width:      40 * ScreenTools.defaultFontPixelWidth
                        spacing:    ScreenTools.defaultFontPixelHeight

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("This is recommended for vehicles that have only an internal compass and on vehicles where there is significant interference on the compass from the motors, power wires, etc. ") +
                                            qsTr("CompassMot only works well if you have a battery current monitor because the magnetic interference is linear with current drawn. ") +
                                            qsTr("It is technically possible to set-up CompassMot using throttle but this is not recommended.")
                        }

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("Disconnect your props, flip them over and rotate them one position around the frame. ") +
                                            qsTr("In this configuration they should push the copter down into the ground when the throttle is raised.")
                        }

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("Secure the copter (perhaps with tape) so that it does not move.")
                        }

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("Turn on your transmitter and keep throttle at zero.")
                        }

                        QGCLabel {
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            wrapMode:       Text.WordWrap
                            text:           qsTr("Click Ok to start CompassMot calibration.")
                        }
                    }
                }
            }

        }
    }

}
