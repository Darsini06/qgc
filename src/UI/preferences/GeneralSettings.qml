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
import QGroundControl.Controllers
import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette

SettingsPage {
    //General Settings ------------------------------------------------------------------------------------
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath




    Text {
                Layout.alignment: Qt.AlignHCenter
                text: "General Settings"
                font.pixelSize: 20
                color: "white"
                font.bold: true
            }


    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("General")

        LabelledFactComboBox {
            label:      qsTr("Language")
            fact:       _appSettings.qLocaleLanguage
            indexModel: false
            visible:    _appSettings.qLocaleLanguage.visible
        }

        // LabelledFactComboBox {
        //     label:      qsTr("Color Scheme")
        //     fact:       _appSettings.indoorPalette
        //     indexModel: false
        //     visible:    _appSettings.indoorPalette.visible
        // }

        LabelledFactComboBox {
            label:       qsTr("Stream GCS Position")
            fact:       _appSettings.followTarget
            indexModel: false
            visible:    _appSettings.followTarget.visible
        }

        // FactCheckBoxSlider {
        //     Layout.fillWidth: true
        //     text:           qsTr("Mute all audio output")
        //     fact:       _audioMuted
        //     visible:    _audioMuted.visible
        //     property Fact _audioMuted: _appSettings.audioMuted
        // }

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:       qsTr("Save application data to SD Card")
            fact:       _androidSaveToSDCard
            visible:    _androidSaveToSDCard.visible
            property Fact _androidSaveToSDCard: _appSettings.androidSaveToSDCard
        }

        // QGCCheckBoxSlider {
        //     Layout.fillWidth: true
        //     text:       qsTr("Clear all settings on next start")
        //     checked:    false
        //     onClicked: {
        //         if (checked) {
        //             QGroundControl.deleteAllSettingsNextBoot()
        //         }
        //     }
        // }

        // RowLayout {
        //     Layout.fillWidth:   true
        //     spacing:            ScreenTools.defaultFontPixelWidth * 2
        //     visible:            _appFontPointSize.visible

        //     QGCLabel {
        //         Layout.fillWidth:   true
        //         text:               qsTr("UI Scaling")
        //         color: "white"
        //     }

        //     RowLayout {
        //         spacing: ScreenTools.defaultFontPixelWidth * 2

        //         QGCButton {
        //             Layout.preferredWidth:  height
        //             height:                 baseFontEdit.height * 1.5
        //             text:                   "-"
        //             onClicked: {
        //                 if (_appFontPointSize.value > _appFontPointSize.min) {
        //                     _appFontPointSize.value = _appFontPointSize.value - 1
        //                 }
        //             }
        //         }

        //         QGCLabel {
        //             id:                     baseFontEdit
        //             width:                  ScreenTools.defaultFontPixelWidth * 6
        //             text:                   (QGroundControl.settingsManager.appSettings.appFontPointSize.value / ScreenTools.platformFontPointSize * 100).toFixed(0) + "%"
        //             color: "white"
        //         }

        //         QGCButton {
        //             Layout.preferredWidth:  height
        //             height:                 baseFontEdit.height * 1.5
        //             text:                   "+"
        //             onClicked: {
        //                 if (_appFontPointSize.value < _appFontPointSize.max) {
        //                     _appFontPointSize.value = _appFontPointSize.value + 1
        //                 }
        //             }
        //         }
        //     }
        // }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _appSavePath.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel { text: qsTr("Application Load/Save Path") }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:              Text.ElideMiddle
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  savePathBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:                 savePathBrowseDialog
                    title:              qsTr("Choose the location to save/load files")
                    folder:             _appSavePath.rawValue
                    selectFolder:       true
                    onAcceptedForLoad:  (file) => _appSavePath.rawValue = file
                }
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Units")
        visible:            QGroundControl.settingsManager.unitsSettings.visible

        Repeater {
            model: [ QGroundControl.settingsManager.unitsSettings.horizontalDistanceUnits, QGroundControl.settingsManager.unitsSettings.verticalDistanceUnits, QGroundControl.settingsManager.unitsSettings.areaUnits, QGroundControl.settingsManager.unitsSettings.speedUnits, QGroundControl.settingsManager.unitsSettings.temperatureUnits ]

            LabelledFactComboBox {
                label:                  modelData.shortDescription
                fact:                   modelData
                indexModel:             false
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Brand Image")
        visible:            _brandImageSettings.visible && !ScreenTools.isMobile

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _userBrandImageIndoor.visible

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Indoor Image")
                }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageIndoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    visible:            _userBrandImageIndoor.valueString.length > 0
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  userBrandImageIndoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 userBrandImageIndoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageIndoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageIndoor.rawValue = "file:///" + file
                }
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _userBrandImageOutdoor.visible

            ColumnLayout {

                Layout.fillWidth:   true
                spacing:            0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Outdoor Image")
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageOutdoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    visible:            _userBrandImageOutdoor.valueString.length > 0
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  userBrandImageOutdoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 userBrandImageOutdoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageOutdoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageOutdoor.rawValue = "file:///" + file
                }
            }
        }

        LabelledButton {
            label:      qsTr("Reset Images")
            buttonText: qsTr("Reset")
            onClicked:  {
                _userBrandImageIndoor.rawValue = ""
                _userBrandImageOutdoor.rawValue = ""
            }
        }
    }


    //Flyview Settings ------------------------------------------------------------------------------------
    //property var    _settingsManager:                   QGroundControl.settingsManager
    property var    _flyViewSettings:                   _settingsManager.flyViewSettings
    property var    _customMavlinkActionsSettings:      _settingsManager.customMavlinkActionsSettings
    property Fact   _virtualJoystick:                   _settingsManager.appSettings.virtualJoystick
    property Fact   _virtualJoystickAutoCenterThrottle: _settingsManager.appSettings.virtualJoystickAutoCenterThrottle
    property Fact   _showAdditionalIndicatorsCompass:   _flyViewSettings.showAdditionalIndicatorsCompass
    property Fact   _lockNoseUpCompass:                 _flyViewSettings.lockNoseUpCompass
    property Fact   _guidedMinimumAltitude:             _flyViewSettings.guidedMinimumAltitude
    property Fact   _guidedMaximumAltitude:             _flyViewSettings.guidedMaximumAltitude
    property Fact   _maxGoToLocationDistance:           _flyViewSettings.maxGoToLocationDistance
    property var    _viewer3DSettings:                  _settingsManager.viewer3DSettings
    property Fact   _viewer3DEnabled:                   _viewer3DSettings.enabled
    property Fact   _viewer3DOsmFilePath:               _viewer3DSettings.osmFilePath
    property Fact   _viewer3DBuildingLevelHeight:       _viewer3DSettings.buildingLevelHeight
    property Fact   _viewer3DAltitudeBias:              _viewer3DSettings.altitudeBias
    QGCFileDialogController { id: fileController }

    function customActionList() {
        var fileModel = fileController.getFiles(_settingsManager.appSettings.customActionsSavePath, "*.json")
        fileModel.unshift(qsTr("<None>"))
        return fileModel
    }


    Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Flyview Settings"
                font.pixelSize: 20
                color: "white"
                font.bold: true
            }


    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("General")

        FactCheckBoxSlider {
            id:                 useCheckList
            Layout.fillWidth:   true
            text:               qsTr("Use Preflight Checklist")
            fact:               _useChecklist
            visible:            _useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length
            property Fact _useChecklist:      _settingsManager.appSettings.useChecklist
        }





        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enforce Preflight Checklist")
            fact:               _enforceChecklist
            enabled:            _settingsManager.appSettings.useChecklist.value
            visible:            useCheckList.visible && _enforceChecklist.visible
            property Fact _enforceChecklist: _settingsManager.appSettings.enforceChecklist
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Keep Map Centered On Vehicle")
            fact:               _keepMapCenteredOnVehicle
            visible:            _keepMapCenteredOnVehicle.visible
            property Fact _keepMapCenteredOnVehicle: _flyViewSettings.keepMapCenteredOnVehicle
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show Telemetry Log Replay Status Bar")
            fact:               _showLogReplayStatusBar
            visible:            _showLogReplayStatusBar.visible
            property Fact _showLogReplayStatusBar: _flyViewSettings.showLogReplayStatusBar
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show simple camera controls (DIGICAM_CONTROL)")
            visible:            _showDumbCameraControl.visible
            fact:               _showDumbCameraControl

            property Fact _showDumbCameraControl: _flyViewSettings.showSimpleCameraControl
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Update return to home position based on device location.")
            fact:               _updateHomePosition
            visible:            _updateHomePosition.visible
            property Fact _updateHomePosition: _flyViewSettings.updateHomePosition
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Guided Commands")
        visible:            _guidedMinimumAltitude.visible || _guidedMaximumAltitude.visible || _maxGoToLocationDistance.visible

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Minimum Altitude")
            fact:               _guidedMinimumAltitude
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Maximum Altitude")
            fact:               _guidedMaximumAltitude
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Go To Location Max Distance")
            fact:               _maxGoToLocationDistance
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:       true
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 35
        heading:                qsTr("Custom MAVLink Actions")
        headingDescription:     qsTr("Custom action JSON files should be created in the '%1' folder.").arg(QGroundControl.settingsManager.appSettings.customActionsSavePath)

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Fly View Custom Actions")
            model:              customActionList()
            onActivated:        (index) => index == 0 ? _customMavlinkActionsSettings.flyViewActionsFile.rawValue = "" : _customMavlinkActionsSettings.flyViewActionsFile.rawValue = comboBox.currentText

            Component.onCompleted: {
                var index = comboBox.find(_customMavlinkActionsSettings.flyViewActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }

        LabelledComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Joystick Custom Actions")
            model:              customActionList()
            onActivated:        (index) => index == 0 ? _customMavlinkActionsSettings.joystickActionsFile.rawValue = "" : _customMavlinkActionsSettings.joystickActionsFile.rawValue = comboBox.currentText

            Component.onCompleted: {
                var index = comboBox.find(_customMavlinkActionsSettings.joystickActionsFile.valueString)
                comboBox.currentIndex = index == -1 ? 0 : index
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Virtual Joystick")
        visible:            _virtualJoystick.visible || _virtualJoystickAutoCenterThrottle.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enabled")
            visible:            _virtualJoystick.visible
            fact:               _virtualJoystick
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto-Center Throttle")
            visible:            _virtualJoystickAutoCenterThrottle.visible
            enabled:            _virtualJoystick.rawValue
            fact:               _virtualJoystickAutoCenterThrottle
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Instrument Panel")
        visible:            _showAdditionalIndicatorsCompass.visible || _lockNoseUpCompass.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Show additional heading indicators on Compass")
            visible:            _showAdditionalIndicatorsCompass.visible
            fact:               _showAdditionalIndicatorsCompass
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Lock Compass Nose-Up")
            visible:            _lockNoseUpCompass.visible
            fact:               _lockNoseUpCompass
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("3D View")
        visible:            _viewer3DSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enabled")
            fact:               _viewer3DEnabled
            visible:            _viewer3DEnabled.visible
        }

        ColumnLayout{
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DOsmFilePath.rawValue

            RowLayout{
                Layout.fillWidth:   true
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    wrapMode:   Text.WordWrap
                    visible:    true
                    text:       qsTr("3D Map File:")
                }

                QGCTextField {
                    id:                 osmFileTextField
                    height:             ScreenTools.defaultFontPixelWidth * 4.5
                    unitsLabel:         ""
                    showUnits:          false
                    visible:            true
                    Layout.fillWidth:   true
                    readOnly:           true
                    text:               _viewer3DOsmFilePath.rawValue
                }
            }

            RowLayout{
                Layout.alignment:   Qt.AlignRight
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCButton {
                    text: qsTr("Clear")

                    onClicked: {
                        osmFileTextField.text = "Please select an OSM file"
                        _viewer3DOsmFilePath.value = osmFileTextField.text
                    }
                }

                QGCButton {
                    text: qsTr("Select File")

                    onClicked: {
                        var filename = _viewer3DOsmFilePath.rawValue;
                        const found = filename.match(/(.*)[\/\\]/);
                        if(found){
                            filename = found[1]||''; // extracting the directory from the file path
                            fileDialog.folder = (filename[0] === "/")?(filename.slice(1)):(filename);
                        }
                        fileDialog.openForLoad()
                    }

                    QGCFileDialog {
                        id:             fileDialog
                        nameFilters:    [qsTr("OpenStreetMap files (*.osm)")]
                        title:          qsTr("Select map file")

                        onAcceptedForLoad: (file) => {
                                               osmFileTextField.text = file
                                               _viewer3DOsmFilePath.value = osmFileTextField.text
                        }
                    }
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Average Building Level Height")
            fact:               _viewer3DBuildingLevelHeight
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DBuildingLevelHeight.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Vehicles Altitude Bias")
            fact:               _viewer3DAltitudeBias
            enabled:            _viewer3DEnabled.rawValue
            visible:            _viewer3DAltitudeBias.visible
        }
    }

    //Planview Settings ------------------------------------------------------------------------------------
    //property var _settingsManager:  QGroundControl.settingsManager
    property var _planViewSettings: QGroundControl.settingsManager.planViewSettings

    Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Planview Settings"
                font.pixelSize: 20
                color: "white"
                font.bold: true
            }
    SettingsGroupLayout {
        Layout.fillWidth: true

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Default Mission Altitude")
            fact:               _settingsManager.appSettings.defaultMissionItemAltitude
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("VTOL TransitionDistance")
            fact:               _planViewSettings.vtolTransitionDistance
            visible:            fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Use MAV_CMD_CONDITION_GATE for pattern generation")
            fact:               _planViewSettings.useConditionGate
            visible:            fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Missions Do Not Require Takeoff Item")
            fact:               _planViewSettings.takeoffItemNotRequired
            visible:            fact.visible
        }
    }

    //Video Settings ------------------------------------------------------------------------------------
    //property var    _settingsManager:            QGroundControl.settingsManager
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
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 25
    property bool   _requiresUDPPort:           _isUDP264 || _isUDP265 || _isMPEGTS

    Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Video Settings"
                font.pixelSize: 20
                color: "white"
                font.bold: true
            }
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Video Source")
        headingDescription: _videoAutoStreamConfig ? qsTr("Mavlink camera stream is automatically configured") : ""
        enabled:            !_videoAutoStreamConfig

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Source")
            indexModel:         false
            fact:               _videoSettings.videoSource
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Connection")
        visible:            !_videoAutoStreamConfig && (_isTCP || _isRTSP | _requiresUDPPort)

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    _urlFieldWidth
            label:                      qsTr("RTSP URL")
            fact:                       _videoSettings.rtspUrl
            visible:                    _isRTSP && _videoSettings.rtspUrl.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            label:                      qsTr("TCP URL")
            textFieldPreferredWidth:    _urlFieldWidth
            fact:                       _videoSettings.tcpUrl
            visible:                    _isTCP && _videoSettings.tcpUrl.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("UDP Port")
            fact:               _videoSettings.udpPort
            visible:            _requiresUDPPort && _videoSettings.udpPort.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Aspect Ratio")
            fact:               _videoSettings.aspectRatio
            visible:            !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Stop recording when disarmed")
            fact:               _videoSettings.disableWhenDisarmed
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Low Latency Mode")
            fact:               _videoSettings.lowLatencyMode
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible && _isGST
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Video decode priority")
            fact:               _videoSettings.forceVideoDecoder
            visible:            fact.visible
            indexModel:         false
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading:            qsTr("Local Video Storage")

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Record File Format")
            fact:               _videoSettings.recordingFormat
            visible:            _videoSettings.recordingFormat.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto-Delete Saved Recordings")
            fact:               _videoSettings.enableStorageLimit
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Max Storage Usage")
            fact:               _videoSettings.maxVideoSize
            visible:            fact.visible
            enabled:            _videoSettings.enableStorageLimit.rawValue
        }
    }

    //Telemetry Settings ------------------------------------------------------------------------------------
    //property var    _settingsManager:           QGroundControl.settingsManager
    //property var    _appSettings:               _settingsManager.appSettings
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("Not Connected")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var     _apmStartMavlinkStreams:   _appSettings.apmStartMavlinkStreams


    Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Telemetry Settings"
                font.pixelSize: 20
                color: "white"
                font.bold: true
            }
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Ground Station")

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("MAVLink System ID:")
                color: "white"
            }

            QGCTextField {
                text:               QGroundControl.mavlinkSystemID.toString()
                numericValuesOnly:  true
                onEditingFinished: {
                    console.log("text", text)
                    QGroundControl.mavlinkSystemID = parseInt(text)
                }
            }
        }

        QGCCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Emit heartbeat")
            checked:            QGroundControl.multiVehicleManager.gcsHeartBeatEnabled
            onClicked:          QGroundControl.multiVehicleManager.gcsHeartBeatEnabled = checked
        }

        QGCCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Only connect to vehicle with same MAVLink protocol version")
            checked:            QGroundControl.isVersionCheckEnabled
            onClicked:          QGroundControl.isVersionCheckEnabled = checked
        }
    }

    SettingsGroupLayout {
        id:                 mavlink2SigningGroup
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink 2 Signing")
        headingDescription: qsTr("Signing keys should only be sent to the vehicle over secure links.")
        visible:            _mavlink2SigningKey.visible

        property Fact _mavlink2SigningKey: _appSettings.mavlink2SigningKey

        Connections {
            target:             mavlink2SigningGroup._mavlink2SigningKey
            onRawValueChanged:  sendToVehiclePrompt.visible = true
        }

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            LabelledFactTextField {
                Layout.fillWidth:           true
                textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 32
                label:                      qsTr("Key")
                fact:                       mavlink2SigningGroup._mavlink2SigningKey
            }

            QGCButton {
                text:       qsTr("Send to Vehicle")
                enabled:    _activeVehicle

                onClicked: {
                    sendToVehiclePrompt.visible = false
                    _activeVehicle.sendSetupSigning()
                }
            }
        }

        QGCLabel {
            id:                 sendToVehiclePrompt
            Layout.fillWidth:   true
            text:               qsTr("Signing key has changed. Don't forget to send to Vehicle(s) if needed.")
            visible:            false
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink Forwarding")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable")
            fact:               _appSettings.forwardMavlink
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 20
            label:                      qsTr("Host name")
            fact:                       _appSettings.forwardMavlinkHostName
            visible:                    fact.visible
            enabled:                    _appSettings.forwardMavlink.rawValue
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Logging")
        visible:            !_disableAllDataPersistence

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save log after each flight")
            fact:               _telemetrySave
            visible:            fact.visible
            property Fact _telemetrySave: _appSettings.telemetrySave
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save logs even if vehicle was not armed")
            fact:               _telemetrySaveNotArmed
            visible:            fact.visible
            enabled:            _appSettings.telemetrySave.rawValue
            property Fact _telemetrySaveNotArmed: _appSettings.telemetrySaveNotArmed
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Save CSV log of telemetry data")
            fact:               _saveCsvTelemetry
            visible:            fact.visible
            property Fact _saveCsvTelemetry: _appSettings.saveCsvTelemetry
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Stream Rates (ArduPilot Only)")
        visible:            _showAPMStreamRates

        QGCCheckBoxSlider {
            id:                 controllerByVehicleCheckBox
            Layout.fillWidth:   true
            text:               qsTr("Controlled By vehicle")
            checked:            !_apmStartMavlinkStreams.rawValue
            onClicked:          _apmStartMavlinkStreams.rawValue = !checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Raw Sensors")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extended Status")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("RC Channels")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Position")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 1")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 2")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 3")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Link Status (Current Vehicle))")

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages sent (computed)")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages received")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total message loss")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Loss rate:")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(0) + '%' : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Signing:")
            labelText:          _activeVehicle ? (_activeVehicle.mavlinkSigning ? "On" : "Off") : _notConnectedStr
        }
    }

    Text {
                Layout.alignment: Qt.AlignHCenter
                text: " "
                font.pixelSize: 20
                color: "white"
                font.bold: true
            }
}
