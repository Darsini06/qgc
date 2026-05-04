import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.SettingsManager
import QGroundControl.Controllers

// Editor for Mission Settings
Rectangle {
    id:                 valuesRect
    width:              availableWidth
    height:             valuesColumn.implicitHeight + (_margin * 2)
    implicitHeight:     height
    color:              "transparent"
    visible:            missionItem !== null && missionItem !== undefined
    radius:             _radius

    property var    missionItem:                    null
    property real   availableWidth:                 0
    property real   _radius:                        0

    property real   _panelRadius:   8
    property real   _fieldRadius:   4
    property color  _panelColor:    "#333333"
    property color  _panelBorder:   "#444444"
    property color  _fieldColor:    "#444444"
    property color  _fieldBorder:   "#555555"
    property color  _headingColor:  "#ffffff"
    property color  _labelColor:    "#ffffff"
    property color  _valueColor:    "#ffffff"
    property color  _unitColor:     "#ffffff"
    property color  _colorAccent:   "#666666"

    property var    masterController:               null
    property var    _masterController:              masterController
    property var    _missionController:             _masterController ? _masterController.missionController : null
    property var    _controllerVehicle:             _masterController ? _masterController.controllerVehicle : null
    property bool   _vehicleHasHomePosition:        _controllerVehicle ? _controllerVehicle.homePosition.isValid : false
    property bool   _showCruiseSpeed:               _controllerVehicle ? !_controllerVehicle.multiRotor : false
    property bool   _showHoverSpeed:                _controllerVehicle ? (_controllerVehicle.multiRotor || _controllerVehicle.vtol) : false
    property bool   _multipleFirmware:              !QGroundControl.singleFirmwareSupport
    property bool   _multipleVehicleTypes:          !QGroundControl.singleVehicleSupport
    property real   _fieldWidth:                    ScreenTools.defaultFontPixelWidth * 16
    property bool   _mobile:                        ScreenTools.isMobile
    property var    _savePath:                      QGroundControl.settingsManager.appSettings.missionSavePath
    property var    _fileExtension:                 QGroundControl.settingsManager.appSettings.missionFileExtension
    property var    _appSettings:                   QGroundControl.settingsManager.appSettings
    property bool   _waypointsOnlyMode:             QGroundControl.corePlugin.options.missionWaypointsOnly
    property bool   _showCameraSection:             true // Always show per user request: "should not miss any content"
    property bool   _simpleMissionStart:            QGroundControl.corePlugin.options.showSimpleMissionStart
    property bool   _showFlightSpeed:               true // Always show
    property bool   _noMissionItemsAdded:           _missionController ? _missionController.visualItems.count <= 1 : true
    property bool   _allowFWVehicleTypeSelection:   _noMissionItemsAdded && !globals.activeVehicle

    readonly property string _firmwareLabel:    qsTr("Firmware")
    readonly property string _vehicleLabel:     qsTr("Vehicle")
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2

    property string _application : QGroundControl.loadGlobalSetting("loadpage","loadpage");

    QGCPalette { id: qgcPal }
    QGCFileDialogController { id: fileController }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Component {
        id: volumeSliderComponent

        ColumnLayout {
                    id: rootCol
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5
                    property var fact: null
                    property color trackFillColor: _colorAccent
                    property bool showMinusButton: true
                    property bool showPlusButton: true


                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth * 0.7

                        Rectangle {
                            visible: rootCol.showMinusButton
                            Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                            Layout.preferredWidth: Layout.preferredHeight
                            radius: 4
                            color: minusArea.pressed ? _colorAccent : (minusArea.containsMouse ? _fieldColor : _panelColor)
                            border.color: minusArea.containsMouse ? _colorAccent : _panelBorder
                            border.width: 1

                            QGCLabel {
                                anchors.centerIn: parent
                                text: "−"
                                font.pointSize: ScreenTools.mediumFontPointSize
                                font.bold: true
                                color: _headingColor
                            }

                            MouseArea {
                                id: minusArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (rootCol.fact) {
                                        var step = rootCol.fact.increment ? rootCol.fact.increment : 1;
                                        rootCol.fact.value -= step;
                                    }
                                }
                            }
                        }

                        FactTextField {
                            id: factField
                            Layout.fillWidth:       true
                            Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                            fact:                   rootCol.fact
                            showUnits:              true
                            color:                  _valueColor
                            horizontalAlignment:    Qt.AlignHCenter
                            background: Rectangle {
                                color:        factField.activeFocus ? _fieldColor : _panelColor
                                border.color: factField.activeFocus ? _colorAccent : _panelBorder
                                border.width: factField.activeFocus ? 2 : 1
                                radius:       4
                            }
                        }

                        Rectangle {
                            visible: rootCol.showPlusButton
                            Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                            Layout.preferredWidth: Layout.preferredHeight
                            radius: 4
                            color: plusArea.pressed ? _colorAccent : (plusArea.containsMouse ? _fieldColor : _panelColor)
                            border.color: plusArea.containsMouse ? _colorAccent : _panelBorder
                            border.width: 1

                            QGCLabel {
                                anchors.centerIn: parent
                                text: "+"
                                font.pointSize: ScreenTools.mediumFontPointSize
                                font.bold: true
                                color: _headingColor
                            }

                            MouseArea {
                                id: plusArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (rootCol.fact) {
                                        var step = rootCol.fact.increment ? rootCol.fact.increment : 1;
                                        rootCol.fact.value += step;
                                    }
                                }
                            }
                        }
                    }
                }

    }

    Connections {
        target: _controllerVehicle
        function onSupportsTerrainFrameChanged() {
            if (!_controllerVehicle.supportsTerrainFrame && _missionController.globalAltitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
                _missionController.globalAltitudeMode = QGroundControl.AltitudeModeCalcAboveTerrain
            }
        }
    }

    Column {
        id:                 valuesColumn
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        topPadding:         ScreenTools.defaultFontPixelHeight * 0.5
        spacing:            ScreenTools.defaultFontPixelHeight * 1.0

        // --- Altitude Panel ---
        Rectangle {
            width:              parent.width
            height:             altCol.implicitHeight + (ScreenTools.defaultFontPixelHeight * 2)
            color:              _panelColor
            radius:             _panelRadius
            border.color:       _panelBorder

            ColumnLayout {
                id: altCol
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.topMargin: ScreenTools.defaultFontPixelHeight
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                QGCLabel {
                    text:   qsTr("All Altitudes")
                    color:  _labelColor
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns:          ScreenTools.isMobile ? 1 : 2
                    columnSpacing:    ScreenTools.defaultFontPixelWidth
                    rowSpacing:       ScreenTools.defaultFontPixelHeight * 0.5

                    Rectangle {
                        Layout.preferredWidth:  ScreenTools.isMobile ? parent.width : ScreenTools.defaultFontPixelWidth * 16
                        Layout.fillWidth:       ScreenTools.isMobile
                        Layout.preferredHeight: 32
                        radius:                 _fieldRadius
                        color:                  _fieldColor
                        border.color:           _fieldBorder
                        border.width:           1
                        enabled:                _noMissionItemsAdded

                        // Sibling, not parent-child
                        RowLayout {
                            anchors.fill:           parent
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 0.8
                            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth * 0.5
                            enabled: false  // prevents this layout from consuming touch

                            QGCLabel {
                                Layout.fillWidth:   true
                                text:               QGroundControl.altitudeModeShortDescription(_missionController.globalAltitudeMode)
                                color:              _noMissionItemsAdded ? _valueColor : _unitColor
                                font.pixelSize:     Math.round(ScreenTools.defaultFontPixelHeight * 0.75)
                            }

                            QGCColoredImage {
                                height:     ScreenTools.defaultFontPixelHeight * 0.45
                                width:      height
                                source:     "/res/DropArrow.svg"
                                color:      _unitColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("--- Altitude Panel ---")
                                var removeModes = []
                                var updateFunction = function(altMode) {
                                    _missionController.globalAltitudeMode = altMode
                                }
                                if (!_controllerVehicle.supportsTerrainFrame) {
                                    removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                                }
                                altModeDialogComponent.createObject(
                                            mainWindow,
                                            { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }
                                            ).open()
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelHeight * 0.2

                        QGCLabel {
                            text:   qsTr("Initial Point")
                            color:  _labelColor
                            font.bold: true
                        }

                        Loader {
                            Layout.fillWidth:   true
                            sourceComponent:    volumeSliderComponent
                            property var targetFact: QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
                            onTargetFactChanged: if (item) item.fact = targetFact
                            onLoaded: {

                                if (item) {
                                    item.fact = targetFact
                                    item.trackFillColor = _colorAccent
                                    item.showMinusButton = false
                                    item.showPlusButton = true
                                }
                            }
                        }
                    } // ColumnLayout
                } // GridLayout
            } // ColumnLayout altCol
        } // Rectangle

        // --- Speed Panel ---
        Rectangle {
            width:              parent.width
            height:             speedCol.implicitHeight + (ScreenTools.defaultFontPixelHeight * 2)
            color:              _panelColor
            radius:             _panelRadius
            border.color:       _panelBorder
            visible:            _showFlightSpeed

            ColumnLayout {
                id: speedCol
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.topMargin: ScreenTools.defaultFontPixelHeight
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                QGCLabel {
                    text:   qsTr("Flight speed")
                    color:  _labelColor
                    font.bold: true
                }

                Loader {
                    Layout.fillWidth:   true
                    sourceComponent:    volumeSliderComponent
                    property var targetFact: missionItem ? missionItem.speedSection.flightSpeed : null
                    onTargetFactChanged: if (item) item.fact = targetFact
                    onLoaded: {
                        if (item) {
                            item.fact = targetFact
                            item.trackFillColor = "#ffffff"
                            item.showMinusButton = true
                            item.showPlusButton = true
                        }
                    }
                }
            }
        }

        // --- Camera Panel ---
        Rectangle {
            width:              parent.width
            height:             camCol.implicitHeight + (ScreenTools.defaultFontPixelHeight * 2)
            color:              _panelColor
            radius:             _panelRadius
            border.color:       _panelBorder
            visible:            !_simpleMissionStart && _showCameraSection && _application !== "Agri"

            ColumnLayout {
                id: camCol
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.topMargin: ScreenTools.defaultFontPixelHeight
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                CameraSection {
                    id:         cameraSection
                    checked:    !_waypointsOnlyMode && missionItem && missionItem.cameraSection && missionItem.cameraSection.settingsSpecified
                    Layout.fillWidth: true
                }

                QGCLabel {
                    Layout.fillWidth:       true
                    text:                   qsTr("Above camera commands will take affect immediately upon mission start.")
                    wrapMode:               Text.WordWrap
                    horizontalAlignment:    Text.AlignHCenter
                    font.pointSize:         ScreenTools.smallFontPointSize
                    color:                  _unitColor
                    visible:                cameraSection.checked
                }
            }
        }

        // --- Vehicle Info Panel ---
        Rectangle {
            width:              parent.width
            height:             vehCol.implicitHeight + (ScreenTools.defaultFontPixelHeight * 2)
            color:              _panelColor
            radius:             _panelRadius
            border.color:       _panelBorder
            visible:            !_simpleMissionStart && !_waypointsOnlyMode

            Column {
                id: vehCol
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.topMargin: ScreenTools.defaultFontPixelHeight
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                // SectionHeader {
                //     id:             vehicleInfoSectionHeader
                //     width:          parent.width
                //     text:           qsTr("Vehicle Info")
                //     checked:        false
                //     color:          _labelColor
                // }

                Column {
                    width:          parent.width
                    spacing:        ScreenTools.defaultFontPixelHeight * 0.5
                    //visible:      vehicleInfoSectionHeader.checked

                    // GridLayout {
                    //     width:          parent.width
                    //     columnSpacing:  ScreenTools.defaultFontPixelWidth
                    //     rowSpacing:     columnSpacing
                    //     columns:        2

                    //     QGCLabel { text: _firmwareLabel; color: _labelColor; visible: _multipleFirmware }
                    //     FactComboBox {
                    //         fact:                   QGroundControl.settingsManager.appSettings.offlineEditingFirmwareClass
                    //         indexModel:             false
                    //         width:                  parent.width / 2
                    //         visible:                _multipleFirmware && _allowFWVehicleTypeSelection
                    //         background: Rectangle {
                    //             radius: _fieldRadius
                    //             color: _fieldColor
                    //             border.color: _fieldBorder
                    //             border.width: 1
                    //         }
                    //     }
                    //     QGCLabel { text: _controllerVehicle.firmwareTypeString; color: _valueColor; visible: _multipleFirmware && !_allowFWVehicleTypeSelection }

                    //     QGCLabel { text: _vehicleLabel; color: _labelColor; visible: _multipleVehicleTypes }
                    //     FactComboBox {
                    //         fact:                   QGroundControl.settingsManager.appSettings.offlineEditingVehicleClass
                    //         indexModel:             false
                    //         width:                  parent.width / 2
                    //         visible:                _multipleVehicleTypes && _allowFWVehicleTypeSelection
                    //         background: Rectangle {
                    //             radius: _fieldRadius
                    //             color: _fieldColor
                    //             border.color: _fieldBorder
                    //             border.width: 1
                    //         }
                    //     }
                    //     QGCLabel { text: _controllerVehicle.vehicleTypeString; color: _valueColor; visible: _multipleVehicleTypes && !_allowFWVehicleTypeSelection }
                    // }

                    // QGCLabel {
                    //     width:                  parent.width
                    //     wrapMode:               Text.WordWrap
                    //     font.pointSize:         ScreenTools.smallFontPointSize
                    //     text:                   qsTr("Speed values used to calculate total mission time.")
                    //     color:                  _unitColor
                    // }

                    // Column {
                    //     width:      parent.width
                    //     spacing:    ScreenTools.defaultFontPixelHeight * 0.3
                    //     visible:    _showCruiseSpeed

                    //     QGCLabel {
                    //         text: qsTr("Cruise speed")
                    //         color: _labelColor
                    //     }
                    //     Loader {
                    //         width:              parent.width
                    //         sourceComponent:    volumeSliderComponent
                    //         property var targetFact: QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed
                    //         onTargetFactChanged: if (item) item.fact = targetFact
                    //         onLoaded: {
                    //             if (item) {
                    //                 item.fact = targetFact
                    //                 item.trackFillColor = _colorAccent
                    //             }
                    //         }
                    //     }
                    // }

                    Column {
                        width:      parent.width
                        spacing:    ScreenTools.defaultFontPixelHeight * 0.3
                        visible:    _showHoverSpeed

                        QGCLabel {
                            text: qsTr("Hover speed")
                            color: _labelColor
                        }
                        Loader {
                            width:              parent.width
                            sourceComponent:    volumeSliderComponent
                            property var targetFact: QGroundControl.settingsManager.appSettings.offlineEditingHoverSpeed
                            onTargetFactChanged: if (item) item.fact = targetFact
                            onLoaded: {
                                if (item) {
                                    item.fact = targetFact
                                    item.trackFillColor = _colorAccent
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Launch Position Panel ---
        Rectangle {
            width:              parent.width
            height:             launchCol.implicitHeight + (ScreenTools.defaultFontPixelHeight * 2)
            color:              _panelColor
            radius:             _panelRadius
            border.color:       _panelBorder
            visible:            false

            ColumnLayout {
                id: launchCol
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    parent.top
                anchors.margins: ScreenTools.defaultFontPixelWidth
                anchors.topMargin: ScreenTools.defaultFontPixelHeight
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                SectionHeader {
                    id:             plannedHomePositionSection
                    Layout.fillWidth: true
                    text:           qsTr("Home Position")
                    checked:        false
                    color:          _labelColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5
                    visible:        plannedHomePositionSection.checked

                    QGCLabel {
                        text:   qsTr("Altitude")
                        color:  _labelColor
                        font.bold: true
                    }

                    Loader {
                        Layout.fillWidth:   true
                        sourceComponent:    volumeSliderComponent
                        property var targetFact: missionItem ? missionItem.plannedHomePositionAltitude : null
                        onTargetFactChanged: if (item) item.fact = targetFact
                        onLoaded: {
                            if (item) {
                                item.fact = targetFact
                                item.trackFillColor = _colorAccent
                                item.showMinusButton = true
                                item.showPlusButton = true
                            }
                        }
                    }

                    QGCLabel {
                        Layout.fillWidth:       true
                        wrapMode:               Text.WordWrap
                        font.pointSize:         ScreenTools.smallFontPointSize
                        text:                   qsTr("Actual position set by vehicle at flight time.")
                        color:                  _unitColor
                        horizontalAlignment:    Text.AlignHCenter
                    }

                    QGCButton {
                        text:                       qsTr("Set To Map Center")
                        onClicked:                  if (missionItem) missionItem.coordinate = map.center
                        Layout.alignment:           Qt.AlignHCenter
                    }
                } // inner ColumnLayout
            } // launchCol
        } // launch position panel
    } // valuesColumn
} // valuesRect
