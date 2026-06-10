import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QGroundControl.Controllers
import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette
import QGroundControl.SettingsManager

SettingsPage {
    id: root

    component UnitSelector: RowLayout {
        spacing:            6
        Layout.fillWidth:   true

        property string labelText
        property Fact fact
        property var options: []
        property var customValue: null
        property var customSelectCallback: null

        function isSelected(val) {
            if (customSelectCallback !== null) {
                return customValue === val
            }
            return fact ? fact.value === val : false
        }

        QGCLabel {
            text:                   labelText
            color:                  "black"
            font.bold:              true
            Layout.alignment:       Qt.AlignVCenter
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
        }

        RowLayout {
            spacing:            4
            Layout.fillWidth:   true
            Layout.alignment:   Qt.AlignVCenter

            Repeater {
                model: options

                delegate: Rectangle {
                    width:          ScreenTools.defaultFontPixelWidth * 6.5
                    height:         30
                    radius:         4
                    border.width:   1
                    border.color:   isSelected(modelData.value) ? "#79AE6F" : "#CCCCCC"
                    color:          isSelected(modelData.value) ? "#79AE6F" : (mouseArea.containsMouse ? "#E8F4E5" : "white")

                    QGCLabel {
                        id:                 textLabel
                        anchors.centerIn:   parent
                        text:               modelData.text
                        color:              isSelected(modelData.value) ? "white" : "black"
                        font.bold:          isSelected(modelData.value)
                        font.pointSize:     ScreenTools.defaultFontPointSize * 0.9
                    }

                    MouseArea {
                        id:                 mouseArea
                        anchors.fill:       parent
                        hoverEnabled:       true
                        cursorShape:        Qt.PointingHandCursor
                        onClicked: {
                            if (customSelectCallback !== null) {
                                customSelectCallback(modelData.value)
                            } else if (fact) {
                                fact.value = modelData.value
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }
    }

    component OnOffToggle: Rectangle {
        id: toggleRoot
        width:              48
        height:             26
        radius:             height / 2
        color:              checked ? "#79AE6F" : "#E0E0E0"
        border.color:       checked ? "#79AE6F" : "#CCCCCC"
        border.width:       1
        
        property bool checked: false
        signal toggled(bool newValue)

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            id: thumb
            width:              20
            height:             20
            radius:             height / 2
            color:              "white"
            anchors.verticalCenter: parent.verticalCenter
            x:                  checked ? (parent.width - width - 3) : 3

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }

        MouseArea {
            anchors.fill:       parent
            cursorShape:        Qt.PointingHandCursor
            onClicked: {
                toggleRoot.toggled(!toggleRoot.checked)
            }
        }
    }

    //General Settings ------------------------------------------------------------------------------------
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath

    //Video Settings ------------------------------------------------------------------------------------
    property var    _videoManager:              QGroundControl.videoManager
    property var    _videoSettings:             _settingsManager.videoSettings
    property string _videoSource:               _videoSettings.videoSource.rawValue
    property bool   _isGST:                     _videoManager.gstreamerEnabled
    property bool   _isStreamSource:            _videoManager.isStreamSource
    property bool   _isUDP264:                  _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:                  _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                    _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                     _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:                  _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:     _videoManager.autoStreamConfigured
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 30
    property bool   _requiresUDPPort:           _isUDP264 || _isUDP265 || _isMPEGTS
    //Telemetry Settings ------------------------------------------------------------------------------------
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("Not Connected")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:   _appSettings.apmStartMavlinkStreams
    //Drone Settings ------------------------------------------------------------------------------------
    property var    _linkManager:               QGroundControl.linkManager
    property var    _autoConnectSettings:       QGroundControl.settingsManager.autoConnectSettings
    property bool   _isNarrow:                  width < ScreenTools.defaultFontPixelWidth * 110
    property real   _innerMargin:               ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 8
    property real   _labelWidth:                _isNarrow ? contentLayout.width : ScreenTools.defaultFontPixelWidth * 45
    property real   _controlWidth:              _isNarrow ? contentLayout.width : ScreenTools.defaultFontPixelWidth * 35
    property real   _maxContentWidth:           ScreenTools.defaultFontPixelWidth * 90
    property real   _contentWidth:              Math.min(width - (_innerMargin * 2), _maxContentWidth)



    ColumnLayout {
        id:                 contentLayout
        width:              _contentWidth
        spacing:            _isNarrow ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 1.5
        //anchors.horizontalCenter: parent.horizontalCenter
        Layout.alignment:   Qt.AlignHCenter


        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.3
            visible:          _videoSettings.videoSource.visible
        }

        RowLayout {
            Layout.fillWidth: true
            visible: _appSettings.followTarget.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Stream GCS Position")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactComboBox {
                id: followTargetCombo
                fact: _appSettings.followTarget

                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 4
                }

                onPressedChanged: {
                    if (pressed) {
                        popup.width = Math.max(width, ScreenTools.defaultFontPixelWidth * 40)
                        popup.x = width - popup.width
                    }
                }
            }
        }
        // --- SD Card Save (Tick Style) ---
        RowLayout {
            spacing:            10
            Layout.fillWidth:   true
            visible:            _appSettings.androidSaveToSDCard.visible

            QGCLabel {
                text:                   qsTr("Save application data to SD Card")
                color:                  "black"
                font.bold:              true
                Layout.fillWidth:       true
                wrapMode:               Text.WordWrap
            }

            OnOffToggle {
                checked:                _appSettings.androidSaveToSDCard.value != 0
                onToggled: (val) =>     _appSettings.androidSaveToSDCard.value = val ? 1 : 0
            }
        }


        //Not for Mobile
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _appSavePath.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
                spacing:            0

                QGCLabel {
                    text: qsTr("Application Load/Save Path")
                    font.bold: true
                    color: "black"
                    Layout.fillWidth: true
                }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:              Text.ElideMiddle
                    color:              "black"
                }
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow
            }

            QGCButton {
                text:               qsTr("Browse")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:          savePathBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:                 savePathBrowseDialog
                    title:              qsTr("Choose the location to save/load files")
                    folder:             _appSavePath.rawValue
                    selectFolder:       true
                    onAcceptedForLoad:  (file) => _appSavePath.rawValue = file
                }
            }
        }

        // Distance Selector (Combines Horizontal and Vertical Distance)
        UnitSelector {
            labelText:              qsTr("Distance")
            visible:                _settingsManager.unitsSettings.visible
            customValue:            _settingsManager.unitsSettings.horizontalDistanceUnits.value
            options: [
                { text: qsTr("m"),  value: UnitsSettings.HorizontalDistanceUnitsMeters },
                { text: qsTr("ft"), value: UnitsSettings.HorizontalDistanceUnitsFeet }
            ]
            customSelectCallback:   function(val) {
                _settingsManager.unitsSettings.horizontalDistanceUnits.value = val
                _settingsManager.unitsSettings.verticalDistanceUnits.value = val
            }
        }

        // Area Selector
        UnitSelector {
            labelText:              qsTr("Area")
            visible:                _settingsManager.unitsSettings.visible
            fact:                   _settingsManager.unitsSettings.areaUnits
            options: [
                { text: qsTr("m²"),  value: UnitsSettings.AreaUnitsSquareMeters },
                { text: qsTr("ft²"), value: UnitsSettings.AreaUnitsSquareFeet },
                { text: qsTr("km²"), value: UnitsSettings.AreaUnitsSquareKilometers },
                { text: qsTr("ha"),  value: UnitsSettings.AreaUnitsHectares },
                { text: qsTr("ac"),  value: UnitsSettings.AreaUnitsAcres },
                { text: qsTr("mi²"), value: UnitsSettings.AreaUnitsSquareMiles }
            ]
        }

        // Speed Selector
        UnitSelector {
            labelText:              qsTr("Speed")
            visible:                _settingsManager.unitsSettings.visible
            fact:                   _settingsManager.unitsSettings.speedUnits
            options: [
                { text: qsTr("m/s"),  value: UnitsSettings.SpeedUnitsMetersPerSecond },
                { text: qsTr("ft/s"), value: UnitsSettings.SpeedUnitsFeetPerSecond },
                { text: qsTr("km/h"), value: UnitsSettings.SpeedUnitsKilometersPerHour },
                { text: qsTr("mph"),  value: UnitsSettings.SpeedUnitsMilesPerHour },
                { text: qsTr("kt"),   value: UnitsSettings.SpeedUnitsKnots }
            ]
        }

        // Temperature Selector
        UnitSelector {
            labelText:              qsTr("Temperature")
            visible:                _settingsManager.unitsSettings.visible
            fact:                   _settingsManager.unitsSettings.temperatureUnits
            options: [
                { text: qsTr("°C"), value: UnitsSettings.TemperatureUnitsCelsius },
                { text: qsTr("°F"), value: UnitsSettings.TemperatureUnitsFarenheit }
            ]
        }

        //Not for Mobile
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _userBrandImageIndoor.visible && _brandImageSettings.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
                spacing:            0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Indoor Image")
                    font.bold:          true
                    color:              "black"
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageIndoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    color:              "black"
                    visible:            _userBrandImageIndoor.valueString.length > 0
                }
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow
            }

            QGCButton {
                text:               qsTr("Browse")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:          userBrandImageIndoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 userBrandImageIndoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageIndoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageIndoor.rawValue = "file:///" + file
                }
            }
        }

        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _userBrandImageOutdoor.visible && _brandImageSettings.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
                spacing:            0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Outdoor Image")
                    font.bold:          true
                    color:              "black"
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageOutdoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    color:              "black"
                    visible:            _userBrandImageOutdoor.valueString.length > 0
                }
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow
            }

            QGCButton {
                text:               qsTr("Browse")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:          userBrandImageOutdoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id :                 userBrandImageOutdoorBrowseDialog
                    title :              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageOutdoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageOutdoor.rawValue = "file:///" + file
                }
            }
        }

        //Not for Mobile
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _brandImageSettings.visible && !ScreenTools.isMobile

            QGCLabel {
                text:               qsTr("Reset Images")
                font.bold:          true
                color:              "black"
                Layout.preferredWidth: _labelWidth
                Layout.fillWidth:   _isNarrow
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow
            }

            QGCButton {
                text:               qsTr("Reset")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:  {
                    _userBrandImageIndoor.rawValue = ""
                    _userBrandImageOutdoor.rawValue = ""
                }
            }
        }

        // --- Logging Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            //Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.5
        }

        Text {
            Layout.fillWidth: true
            text:             qsTr("Logging")
            font.pixelSize:   ScreenTools.isMobile ? 18 : 22
            color:            "black"
            font.bold:        true
            horizontalAlignment: Text.AlignLeft
            visible:          !_disableAllDataPersistence
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            visible: !_disableAllDataPersistence

            Repeater {
                model: [
                    { t: qsTr("Save log after each flight"), f: _appSettings.telemetrySave, v: _appSettings.telemetrySave.visible, e: true },
                    { t: qsTr("Save logs even if vehicle was not armed"), f: _appSettings.telemetrySaveNotArmed, v: _appSettings.telemetrySaveNotArmed.visible, e: _appSettings.telemetrySave.rawValue },
                ]
                delegate: RowLayout {
                    spacing:            10
                    visible:            modelData.v
                    opacity:            modelData.e ? 1 : 0.5
                    Layout.fillWidth:   true

                    QGCLabel {
                        text:                   modelData.t
                        color:                  "black"
                        font.bold:              true
                        Layout.fillWidth:       true
                        wrapMode:               Text.WordWrap
                    }

                    OnOffToggle {
                        checked:                modelData.f.value != 0
                        enabled:                modelData.e
                        onToggled: (val) =>     modelData.f.value = val ? 1 : 0
                    }
                }
            }
        }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Save log after each flight")
        //     fact:               _telemetrySave
        //     visible:            fact.visible  &&  !_disableAllDataPersistence
        //     property Fact _telemetrySave: _appSettings.telemetrySave
        // }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Save logs even if vehicle was not armed")
        //     fact:               _telemetrySaveNotArmed
        //     visible:            fact.visible   &&  !_disableAllDataPersistence
        //     enabled:            _appSettings.telemetrySave.rawValue
        //     property Fact _telemetrySaveNotArmed: _appSettings.telemetrySaveNotArmed
        // }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Save CSV log of telemetry data")
        //     fact:               _saveCsvTelemetry
        //     visible:            fact.visible   &&  !_disableAllDataPersistence
        //     property Fact _saveCsvTelemetry: _appSettings.saveCsvTelemetry
        // }

        //Link Settings
        LinkSettings {
            Layout.fillWidth: true
        }

        // Bottom Spacer
        Item {
            Layout.preferredHeight: 20
        }
    }
}
