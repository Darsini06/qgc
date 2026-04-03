/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem

RowLayout {
    id:         control
    spacing:    0

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property var    _vehicleInAir:      _activeVehicle ? _activeVehicle.flying || _activeVehicle.landing : false
    property bool   _vtolInFWDFlight:   _activeVehicle ? _activeVehicle.vtolInFwdFlight : false
    property bool   _armed:             _activeVehicle ? _activeVehicle.armed : false
    property real   _margins:           ScreenTools.defaultFontPixelWidth
    property real   _spacing:           ScreenTools.defaultFontPixelWidth / 2
    property bool   _healthAndArmingChecksSupported: _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.supported : false

    QGCMarqueeLabel {
        id:             mainStatusLabel
        text:           mainStatusText()
        font.pointSize: ScreenTools.mediumFontPointSize
        implicitWidth:  maxWidth
        maxWidth:       ScreenTools.defaultFontPixelWidth * ScreenTools.mediumFontPointRatio * 10
        color: "white"

        property string _commLostText:      qsTr("Communication Lost")
        property string _readyToFlyText:    qsTr("Ready To Fly")
        property string _notReadyToFlyText: qsTr("Not Ready")
        property string _disconnectedText:  qsTr("Connect")//qsTr("Disconnected - Click to manually connect")
        property string _armedText:         qsTr("Armed")
        property string _flyingText:        qsTr("Flying")
        property string _landingText:       qsTr("Landing")

        function mainStatusText() {
            var statusText
            if (_activeVehicle) {
                if (_communicationLost) {
                    _mainStatusBGColor = "transparent"
                    return mainStatusLabel._commLostText
                }
                if (_activeVehicle.armed) {
                    _mainStatusBGColor ="transparent"

                    if (_healthAndArmingChecksSupported) {
                        if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                            if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                                _mainStatusBGColor = "transparent"
                            }
                        } else {
                            _mainStatusBGColor = "transparent"
                        }
                    }

                    if (_activeVehicle.flying) {
                        console.log("flying check")
                        mainWindow.takeoff()
                        console.log("flying check1")
                        return mainStatusLabel._flyingText
                    } else if (_activeVehicle.landing) {
                    //mainWindow.land()
                        return mainStatusLabel._landingText
                    } else {
                        //mainWindow.takeoff()
                        return mainStatusLabel._armedText
                    }
                } else {
                    if (_healthAndArmingChecksSupported) {
                        if (_activeVehicle.healthAndArmingCheckReport.canArm) {
                            if (_activeVehicle.healthAndArmingCheckReport.hasWarningsOrErrors) {
                                _mainStatusBGColor ="transparent"
                            } else {
                                _mainStatusBGColor = "transparent"
                            }
                            console.log("healthAndArmingCheckReport")
                            return mainStatusLabel._readyToFlyText
                        } else {
                            console.log("healthAndArmingCheckReport1")
                            _mainStatusBGColor = "transparent"
                            return mainStatusLabel._notReadyToFlyText
                        }
                    } else if (_activeVehicle.readyToFlyAvailable) {
                        if (_activeVehicle.readyToFly) {
                            console.log("readyToFlyAvailable readyToFly")
                            _mainStatusBGColor = "transparent"
                            return mainStatusLabel._readyToFlyText
                        } else {
                            console.log("readyToFlyAvailable  readyToFly1")
                            _mainStatusBGColor ="transparent"
                            return mainStatusLabel._notReadyToFlyText
                        }
                    } else {
                        // Best we can do is determine readiness based on AutoPilot component setup and health indicators from SYS_STATUS
                        if (_activeVehicle.allSensorsHealthy && _activeVehicle.autopilot.setupComplete) {
                            _mainStatusBGColor = "transparent"
                            return mainStatusLabel._readyToFlyText
                        } else {
                            _mainStatusBGColor = "transparent"
                            return mainStatusLabel._notReadyToFlyText
                        }
                    }
                }
            } else {
                _mainStatusBGColor = "transparent"//"#A6ADFF"//qgcPal.toolBarColor
                return mainStatusLabel._disconnectedText
            }
        }

        QGCMouseArea {
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 control.height
            onClicked:              mainWindow.showIndicatorDrawer(overallStatusComponent, control)

            property Component overallStatusComponent: _activeVehicle ? overallStatusIndicatorPage : overallStatusOfflineIndicatorPage
        }
    }

    Item {
        implicitWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        implicitHeight: 1
        visible:        vtolModeLabel.visible
    }

    QGCLabel {
        id:                     vtolModeLabel
        Layout.alignment:       Qt.AlignVCenter
        text:                   _vtolInFWDFlight ? qsTr("FW(vtol)") : qsTr("MR(vtol)")
        font.pointSize:         enabled ? ScreenTools.largeFontPointSize : ScreenTools.defaultFontPointSize
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * text.length
        visible:                _activeVehicle && _activeVehicle.vtol
        enabled:                _activeVehicle && _activeVehicle.vtol && _vehicleInAir

        QGCMouseArea {
            anchors.fill:   parent
            onClicked:      mainWindow.showIndicatorDrawer(vtolTransitionIndicatorPage)
        }
    }

    Component {
        id: overallStatusOfflineIndicatorPage

        MainStatusIndicatorOfflinePage {

        }
    }

    Component {
        id: overallStatusIndicatorPage

        ToolIndicatorPage {
            showExpand:         _activeVehicle.mainStatusIndicatorContentItem ? true : false
            waitForParameters:  _activeVehicle.mainStatusIndicatorContentItem ? true : false
            contentComponent:   mainStatusContentComponent
            expandedComponent:  mainStatusExpandedComponent
        }
    }

    Component {
        id: mainStatusContentComponent

        Item {
            implicitWidth:  mainLayout.width + 40
            implicitHeight: mainLayout.height + 40

            Column {
                id:         mainLayout
                anchors.centerIn: parent
                width:      230
                spacing:    16

                // Dynamic Arm/Disarm Button
                Rectangle {
                    width:  parent.width
                    height: 48    // Slightly taller for a great feel
                    color: armActionMouse.pressed ? "#33ffffff" : (armActionMouse.hovered ? "#11ffffff" : "transparent")
                    border.color: "white"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    property bool forceArm: false
                    property bool enabledBtn: _armed || !_healthAndArmingChecksSupported || (_activeVehicle && _activeVehicle.healthAndArmingCheckReport.canArm)
                    property bool isArmed: _armed

                    Text {
                        anchors.centerIn: parent
                        text: parent.isArmed ? qsTr("Disarm") : (parent.forceArm ? qsTr("Force Arm") : qsTr("Arm"))
                        color: "white"
                        font.bold: true
                        font.pixelSize: 15
                        font.family: "Outfit"
                        font.letterSpacing: 1.0
                    }

                    MouseArea {
                        id: armActionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: parent.enabledBtn ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: parent.enabledBtn

                        onPressAndHold: parent.forceArm = true

                        onClicked: {
                            if (_armed) {
                                mainWindow.disarmVehicleRequest()
                            } else {
                                if (parent.forceArm) {
                                    mainWindow.forceArmVehicleRequest()
                                } else {
                                    mainWindow.armVehicleRequest()
                                }
                            }
                            parent.forceArm = false
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "white"
                    opacity: 0.1
                    visible: !_healthAndArmingChecksSupported
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("SENSOR STATUS")
                    visible: !_healthAndArmingChecksSupported
                    color: "white"
                    font.pointSize: 10
                    font.family: "Outfit"
                    font.bold: true
                    font.letterSpacing: 1.5
                    opacity: 1.0
                }

                GridLayout {
                    width:          parent.width
                    rowSpacing:     14
                    columnSpacing:  ScreenTools.defaultFontPixelWidth * 2
                    columns:        2
                    visible:        !_healthAndArmingChecksSupported

                    Repeater {
                        model: _activeVehicle ? _activeVehicle.sysStatusSensorInfo.sensorNames.length * 2 : 0
                        delegate: QGCLabel {
                            property int  sensorIndex: Math.floor(index / 2)
                            property bool isName:      (index % 2) === 0
                            
                            text: isName ? 
                                _activeVehicle.sysStatusSensorInfo.sensorNames[sensorIndex] : 
                                _activeVehicle.sysStatusSensorInfo.sensorStatus[sensorIndex]
                            
                            color: isName ? "white" : (String(text).toLowerCase().indexOf("normal") !== -1 || String(text).toLowerCase().indexOf("ok") !== -1 ? "#2ECC71" : (String(text).toLowerCase().indexOf("disabled") !== -1 ? "#95A5A6" : "#E74C3C"))
                            
                            opacity:            isName ? 0.7 : 1.0
                            font.pointSize:     10
                            font.family:        "Outfit"
                            font.bold:          !isName
                            Layout.fillWidth:   isName
                            Layout.alignment:   isName ? Qt.AlignLeft : Qt.AlignRight
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "white"
                    opacity: 0.1
                    visible: _healthAndArmingChecksSupported && _activeVehicle && _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("OVERALL STATUS")
                    visible: _healthAndArmingChecksSupported && _activeVehicle && _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode.count > 0
                    color: "white"
                    font.pointSize: 10
                    font.family: "Outfit"
                    font.bold: true
                    font.letterSpacing: 1.5
                    opacity: 1.0
                }
            // List health and arming checks
            Repeater {
                visible:    _healthAndArmingChecksSupported
                model:      _activeVehicle ? _activeVehicle.healthAndArmingCheckReport.problemsForCurrentMode : null
                delegate:   listdelegate
            }

            FactPanelController {
                id: controller
            }

            Component {
                id: listdelegate

                Column {
                    Row {
                        spacing: ScreenTools.defaultFontPixelHeight

                        QGCLabel {
                            id:           message
                            text:         object.message
                            textFormat:   TextEdit.RichText
                            color:        object.severity == 'error' ? qgcPal.colorRed : object.severity == 'warning' ? qgcPal.colorOrange : qgcPal.text
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (object.description != "")
                                        object.expanded = !object.expanded
                                }
                            }
                        }

                        QGCColoredImage {
                            id:                     arrowDownIndicator
                            anchors.verticalCenter: parent.verticalCenter
                            height:                 1.5 * ScreenTools.defaultFontPixelWidth
                            width:                  height
                            source:                 "/qmlimages/arrow-down.png"
                            color:                  qgcPal.text
                            visible:                object.description != ""
                            MouseArea {
                                anchors.fill:       parent
                                onClicked:          object.expanded = !object.expanded
                            }
                        }
                    }

                    QGCLabel {
                        id:                 description
                        text:               object.description
                        textFormat:         TextEdit.RichText
                        clip:               true
                        visible:            object.expanded
                        color: "white"

                        property var fact:  null

                        onLinkActivated: (link) => {
                            if (link.startsWith('param://')) {
                                var paramName = link.substr(8);
                                fact = controller.getParameterFact(-1, paramName, true)
                                if (fact != null) {
                                    paramEditorDialogComponent.createObject(mainWindow).open()
                                }
                            } else {
                                Qt.openUrlExternally(link);
                            }
                        }

                        Component {
                            id: paramEditorDialogComponent

                            ParameterEditorDialog {
                                title:          qsTr("Edit Parameter")
                                fact:           description.fact
                                destroyOnClose: true
                            }
                        }
                    }
                }
            }
        }
    }
    }

    Component {
        id: mainStatusExpandedComponent

        ColumnLayout {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 60
            spacing:                margins / 2

            property real margins: ScreenTools.defaultFontPixelHeight

            Loader {
                source: _activeVehicle.mainStatusIndicatorContentItem
            }

            SettingsGroupLayout {
                Layout.fillWidth: true


                GridLayout {
                    columns:            2
                    rowSpacing:         ScreenTools.defaultFontPixelHeight / 2
                    columnSpacing:      ScreenTools.defaultFontPixelWidth *2
                    Layout.fillWidth:   true

                    QGCLabel { Layout.fillWidth: true;
                        text: qsTr("Vehicle Parameters")
                        color: "white"
                    }
                    QGCButton {
                        text: qsTr("Configure")
                        onClicked: {
                            mainWindow.showToolSelectDialog1(0)
                            //mainWindow.showVehicleSetupTool(qsTr("Parameters"))
                            mainWindow.closeIndicatorDrawer()
                        }
                    }

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Initial Vehicle Setup") }
                    QGCButton {
                        text: qsTr("Configure")
                        onClicked: {
                            //mainWindow.showVehicleSetupTool()
                             mainWindow.showToolSelectDialog1(1)
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: vtolTransitionIndicatorPage

        ToolIndicatorPage {
            contentComponent: Component {
                QGCButton {
                    text: _vtolInFWDFlight ? qsTr("Transition to Multi-Rotor") : qsTr("Transition to Fixed Wing")

                    onClicked: {
                        if (_vtolInFWDFlight) {
                            mainWindow.vtolTransitionToMRFlightRequest()
                        } else {
                            mainWindow.vtolTransitionToFwdFlightRequest()
                        }
                        mainWindow.closeIndicatorDrawer()
                    }
                }
            }
        }
    }
}
