/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

RowLayout {
    id:         control
    spacing:    0

    property bool   showIndicator:          true
    property var    expandedPageComponent
    property bool   waitForParameters:      false

    property real fontPointSize:    ScreenTools.defaultFontPointSize
    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property bool allowEditMode:    true
    property bool editMode:         false
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle

    RowLayout {
        Layout.fillWidth: true

        QGCColoredImage {
            id:         flightModeIcon
            width:      0
            height:     ScreenTools.defaultFontPixelHeight
            fillMode:   Image.PreserveAspectFit
            mipmap:     true
            color:      "white"
            source:     "/qmlimages/FlightModesComponentIcon.png"
            visible:    false
        }

        QGCLabel {
            text:               activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
            font.pointSize:     fontPointSize
            Layout.alignment:   Qt.AlignCenter
            color:      "white"
            MouseArea {
                anchors.fill:   parent
                onClicked:      if(_activeVehicle){
                                    mainWindow.showIndicatorDrawer(drawerComponent, control)
                                }
            }
        }
    }

    Component {
        id: drawerComponent

        ToolIndicatorPage {
            showExpand:         false // Hide default edit button to maintain custom header look
            waitForParameters:  control.waitForParameters

            contentComponent:    flightModeContentComponent
            expandedComponent:   flightModeExpandedComponent

            onExpandedChanged: {
                if (!expanded) {
                    editMode = false
                }
            }
        }
    }

    Component {
        id: flightModeContentComponent

        Rectangle {
            id: container
            implicitWidth:  ScreenTools.defaultFontPixelWidth * 35
            implicitHeight: Math.min(ScreenTools.screenHeight * 0.8, contentColumn.implicitHeight + headerArea.height + ScreenTools.defaultFontPixelHeight * 2)
            radius:         15
            clip:           true
            color:          "transparent"
            border.color:   "transparent"
            border.width:   0

            ColumnLayout {
                anchors.fill: parent
                spacing:      0

                // Header
                Rectangle {
                    id: headerArea
                    Layout.fillWidth: true
                    height:           ScreenTools.defaultFontPixelHeight * 3.5
                    color:            "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelWidth * 2
                        spacing: ScreenTools.defaultFontPixelWidth * 1.5

                        QGCLabel {
                            Layout.fillWidth: true
                            text:             activeVehicle ? activeVehicle.flightMode : qsTr("Stabilize")
                            color:            "white"
                            font.pointSize:   ScreenTools.mediumFontPointSize
                            font.bold:        true
                        }

                        Rectangle {
                            width:            height
                            height:           parent.height * 0.6
                            radius:           height / 2
                            color:            Qt.rgba(1, 1, 1, 0.2) // Background opacity only
                            id:               closeButton

                            QGCLabel {
                                text:             "X" // Use standard character to ensure display
                                color:            "white"
                                anchors.centerIn: parent
                                font.pixelSize:   parent.height * 0.5
                                font.bold:        true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked:    mainWindow.closeIndicatorDrawer()
                            }
                        }
                    }
                }

                // Divider below header
                Rectangle {
                    Layout.fillWidth: true
                    height:           1
                    color:            "white"
                    opacity:          0.2
                }

                // Scrollable content
                Flickable {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    contentHeight:     contentColumn.implicitHeight + (ScreenTools.defaultFontPixelHeight * 2)
                    clip:              true
                    interactive:       true
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: contentColumn
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        spacing:        0 // No spacing for "table" look

                        property var    activeVehicle:            QGroundControl.multiVehicleManager.activeVehicle
                        property var    flightModeSettings:       QGroundControl.settingsManager.flightModeSettings
                        property var    hiddenFlightModesFact:    null
                        property var    hiddenFlightModesList:    []

                        Component.onCompleted: {
                            var hiddenFlightModesPropPrefix
                            if (activeVehicle.px4Firmware) {
                                hiddenFlightModesPropPrefix = "px4HiddenFlightModes"
                            } else if (activeVehicle.apmFirmware) {
                                hiddenFlightModesPropPrefix = "apmHiddenFlightModes"
                            } else {
                                control.allowEditMode = false
                            }
                            if (control.allowEditMode) {
                                var hiddenFlightModesProp = hiddenFlightModesPropPrefix + activeVehicle.vehicleClassInternalName()
                                if (flightModeSettings.hasOwnProperty(hiddenFlightModesProp)) {
                                    hiddenFlightModesFact = flightModeSettings[hiddenFlightModesProp]
                                    if (hiddenFlightModesFact && hiddenFlightModesFact.value !== "") {
                                        hiddenFlightModesList = hiddenFlightModesFact.value.split(",")
                                    }
                                } else {
                                    control.allowEditMode = false
                                }
                            }
                        }

                        Repeater {
                            id:     modeRepeater
                            model:  activeVehicle ? activeVehicle.flightModes : []

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                visible: editMode || !hiddenFlightModesList.find(item => { return item === modelData } )

                                Rectangle {
                                    id:                 modeButton
                                    Layout.fillWidth:   true
                                    height:             ScreenTools.defaultFontPixelHeight * 3
                                    color:              modeMouseArea.pressed ? "#40FFFFFF" : (_activeVehicle.flightMode === modelData ? "#40FFFFFF" : "transparent")
                                    radius:             8
                                    
                                    RowLayout {
                                        anchors.fill:    parent
                                        anchors.margins: ScreenTools.defaultFontPixelWidth * 3
                                        spacing:         ScreenTools.defaultFontPixelWidth

                                        QGCLabel {
                                            Layout.fillWidth: true
                                            text:             modelData
                                            color:            "white"
                                            font.pointSize:   ScreenTools.defaultFontPointSize
                                            font.bold:        _activeVehicle.flightMode === modelData
                                        }

                                        QGCCheckBoxSlider {
                                            id: checkBox
                                            visible: editMode
                                            onClicked: {
                                                hiddenFlightModesList = []
                                                for (var i=0; i<modeRepeater.count; i++) {
                                                    var cb = modeRepeater.itemAt(i).children[0].children[0].children[1] // RowLayout check
                                                    if (cb && !cb.checked) {
                                                        hiddenFlightModesList.push(modeRepeater.model[i])
                                                    }
                                                }
                                                hiddenFlightModesFact.value = hiddenFlightModesList.join(",")
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: modeMouseArea
                                        anchors.fill: parent
                                        onClicked: {
                                            if (editMode) {
                                                checkBox.toggle()
                                                checkBox.clicked()
                                            } else {
                                                _activeVehicle.flightMode = modelData
                                                mainWindow.closeIndicatorDrawer()
                                            }
                                        }
                                    }
                                }

                                // Divider between rows
                                Rectangle {
                                    Layout.fillWidth: true
                                    height:           1
                                    color:            "white"
                                    opacity:          0.2
                                    visible:          index < modeRepeater.count - 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: flightModeExpandedComponent

        ColumnLayout {
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 60
            spacing:                ScreenTools.defaultFontPixelHeight / 2

            property var  qgcPal:   QGroundControl.globalPalette

            Loader {
                sourceComponent: expandedPageComponent
            }

            SettingsGroupLayout {
                Layout.fillWidth:  true

                RowLayout {
                    Layout.fillWidth:   true
                    enabled:            control.allowEditMode

                    QGCLabel {
                        Layout.fillWidth:   true
                        text:               qsTr("Edit Displayed Flight Modes")
                    }

                    QGCCheckBoxSlider {
                        onClicked: control.editMode = checked
                    }
                }

                LabelledButton {
                    Layout.fillWidth:   true
                    label:              qsTr("RC Transmitter Flight Modes")
                    buttonText:         qsTr("Configure")

                    onClicked: {
                        mainWindow.showVehicleSetupTool(qsTr("Radio"))
                        mainWindow.closeIndicatorDrawer()
                    }
                }
            }
        }
    }
}
