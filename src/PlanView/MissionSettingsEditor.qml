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
    color:              "#1e1e24"
    visible:            missionItem.isCurrentItem
    radius:             _radius

    property real   _panelRadius:   8
    property real   _fieldRadius:   15
    property color  _panelColor:    "#282830"
    property color  _panelBorder:   "#3e3e4a"
    property color  _fieldColor:    "#32323b"
    property color  _fieldBorder:   "#3e3e4a"
    property color  _headingColor:  "#ffffff"
    property color  _labelColor:    "#ffffff"
    property color  _valueColor:    "#ffffff"
    property color  _unitColor:     "#8e8e93"
    property color  _colorAccent:   "#4a2c6d"

    property var    _masterControler:               masterController
    property var    _missionController:             _masterControler.missionController
    property var    _controllerVehicle:             _masterControler.controllerVehicle
    property bool   _vehicleHasHomePosition:        _controllerVehicle.homePosition.isValid
    property bool   _showCruiseSpeed:               !_controllerVehicle.multiRotor
    property bool   _showHoverSpeed:                _controllerVehicle.multiRotor || _controllerVehicle.vtol
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
    property bool   _allowFWVehicleTypeSelection:   _noMissionItemsAdded && !globals.activeVehicle

    readonly property string _firmwareLabel:    qsTr("Firmware")
    readonly property string _vehicleLabel:     qsTr("Vehicle")
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2

    QGCPalette { id: qgcPal }
    QGCFileDialogController { id: fileController }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Component {
        id: volumeSliderComponent

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth * 0.7
            property var fact: null
            property color trackFillColor: _colorAccent
            property bool showMinusButton: true
            property bool showPlusButton: true

            Rectangle {
                visible: parent.showMinusButton
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth: Layout.preferredHeight
                radius: 15
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
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1;
                            parent.parent.fact.value -= step;
                        }
                    }
                }
            }

            Slider {
                id: factSlider
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                
                from: {
                    if (!parent.fact) return 0;
                    if (isNaN(parent.fact.min) || parent.fact.min < -1000) return 0;
                    return parent.fact.min;
                }
                to: {
                    if (!parent.fact) return 100;
                    if (isNaN(parent.fact.max) || parent.fact.max > 1000) return (from + 200);
                    return parent.fact.max;
                }
                value: parent.fact ? parent.fact.value : 0
                stepSize: parent.fact ? (parent.fact.increment ? parent.fact.increment : 1) : 1
                
                background: Rectangle {
                    x: factSlider.leftPadding
                    y: factSlider.topPadding + factSlider.availableHeight / 2 - height / 2
                    implicitWidth: 100
                    implicitHeight: 6
                    width: factSlider.availableWidth
                    height: implicitHeight
                    radius: 3
                    color: _fieldColor
                    
                    Rectangle {
                        width: factSlider.visualPosition * parent.width
                        height: parent.height
                        color: parent.parent.parent.trackFillColor
                        radius: 3
                    }
                }
                
                handle: Rectangle {
                    x: factSlider.leftPadding + factSlider.visualPosition * (factSlider.availableWidth - width)
                    y: factSlider.topPadding + factSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: _valueColor
                    border.color: _colorAccent
                    border.width: factSlider.pressed ? 4 : 2
                    
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }
                
                onMoved: {
                    if (parent.fact) parent.fact.value = value;
                }
            }

            Rectangle {
                visible: parent.showPlusButton
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth: Layout.preferredHeight
                radius: 15
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
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1;
                            parent.parent.fact.value += step;
                        }
                    }
                }
            }

            FactTextField {
                id: factField
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment: Qt.AlignVCenter
                fact: parent.fact
                showUnits: true
                color: _valueColor
                horizontalAlignment: Qt.AlignHCenter
                background: Rectangle {
                    color: factField.activeFocus ? _fieldColor : _panelColor
                    border.color: factField.activeFocus ? _colorAccent : _panelBorder
                    border.width: factField.activeFocus ? 2 : 1
                    radius: 15
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
                    text:   qsTr("Altitude")
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

                        MouseArea {
                            anchors.fill:   parent
                            onClicked: {
                                var removeModes = []
                                var updateFunction = function(altMode){ _missionController.globalAltitudeMode = altMode }
                                if (!_controllerVehicle.supportsTerrainFrame) {
                                    removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                                }
                                altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
                            }

                            RowLayout {
                                anchors.fill:           parent
                                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 0.8
                                anchors.rightMargin:    ScreenTools.defaultFontPixelWidth * 0.5

                                QGCLabel {
                                    Layout.fillWidth:   true
                                    text:               QGroundControl.altitudeModeShortDescription(_missionController.globalAltitudeMode)
                                    color:              _valueColor
                                    font.pixelSize:     Math.round(ScreenTools.defaultFontPixelHeight * 0.75)
                                }
                                QGCColoredImage {
                                    height:     ScreenTools.defaultFontPixelHeight * 0.45
                                    width:      height
                                    source:     "/res/DropArrow.svg"
                                    color:      _unitColor
                                }
                            }
                        }
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
                                item.showMinusButton = true
                                item.showPlusButton = true
                            }
                        }
                    }
                }
            }
        }

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
                    text:   qsTr("Speed")
                    color:  _labelColor
                    font.bold: true
                }

                Loader {
                    Layout.fillWidth:   true
                    sourceComponent:    volumeSliderComponent
                    property var targetFact: missionItem.speedSection.flightSpeed
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
            visible:            !_simpleMissionStart && _showCameraSection

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
                    checked:    !_waypointsOnlyMode && missionItem.cameraSection.settingsSpecified
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

                SectionHeader {
                    id:             vehicleInfoSectionHeader
                    width:          parent.width
                    text:           qsTr("Vehicle Info")
                    checked:        false
                    color:          _labelColor
                }

                Column {
                    width:          parent.width
                    spacing:        ScreenTools.defaultFontPixelHeight * 0.5
                    visible:        vehicleInfoSectionHeader.checked

                    GridLayout {
                        width:          parent.width
                        columnSpacing:  ScreenTools.defaultFontPixelWidth
                        rowSpacing:     columnSpacing
                        columns:        2

                        QGCLabel { text: _firmwareLabel; color: _labelColor; visible: _multipleFirmware }
                        FactComboBox {
                            fact:                   QGroundControl.settingsManager.appSettings.offlineEditingFirmwareClass
                            indexModel:             false
                            width:                  parent.width / 2
                            visible:                _multipleFirmware && _allowFWVehicleTypeSelection
                            background: Rectangle {
                                radius: _fieldRadius
                                color: _fieldColor
                                border.color: _fieldBorder
                                border.width: 1
                            }
                        }
                        QGCLabel { text: _controllerVehicle.firmwareTypeString; color: _valueColor; visible: _multipleFirmware && !_allowFWVehicleTypeSelection }

                        QGCLabel { text: _vehicleLabel; color: _labelColor; visible: _multipleVehicleTypes }
                        FactComboBox {
                            fact:                   QGroundControl.settingsManager.appSettings.offlineEditingVehicleClass
                            indexModel:             false
                            width:                  parent.width / 2
                            visible:                _multipleVehicleTypes && _allowFWVehicleTypeSelection
                            background: Rectangle {
                                radius: _fieldRadius
                                color: _fieldColor
                                border.color: _fieldBorder
                                border.width: 1
                            }
                        }
                        QGCLabel { text: _controllerVehicle.vehicleTypeString; color: _valueColor; visible: _multipleVehicleTypes && !_allowFWVehicleTypeSelection }
                    }

                    QGCLabel {
                        width:                  parent.width
                        wrapMode:               Text.WordWrap
                        font.pointSize:         ScreenTools.smallFontPointSize
                        text:                   qsTr("Speed values used to calculate total mission time.")
                        color:                  _unitColor
                    }

                    Column {
                        width:      parent.width
                        spacing:    ScreenTools.defaultFontPixelHeight * 0.3
                        visible:    _showCruiseSpeed

                        QGCLabel { 
                            text: qsTr("Cruise speed")
                            color: _labelColor
                        }
                        Loader {
                            width:              parent.width
                            sourceComponent:    volumeSliderComponent
                            property var targetFact: QGroundControl.settingsManager.appSettings.offlineEditingCruiseSpeed
                            onTargetFactChanged: if (item) item.fact = targetFact
                            onLoaded: {
                                if (item) {
                                    item.fact = targetFact
                                    item.trackFillColor = _colorAccent
                                }
                            }
                        }
                    }

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
            visible:            !_vehicleHasHomePosition

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
                    text:           qsTr("Launch Position")
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
                        property var targetFact: missionItem.plannedHomePositionAltitude
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
                        onClicked:                  missionItem.coordinate = map.center
                        Layout.alignment:           Qt.AlignHCenter
                    }
                } // inner ColumnLayout
            } // launchCol
        } // launch position panel
    } // valuesColumn
} // valuesRect
