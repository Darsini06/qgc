

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
    id: settingsPage
    // General Settings ------------------------------------------------------------------------------------
    property var _settingsManager: QGroundControl.settingsManager
    property var _appSettings: _settingsManager.appSettings
    property var _brandImageSettings: _settingsManager.brandImageSettings
    property Fact _appFontPointSize: _appSettings.appFontPointSize
    property Fact _userBrandImageIndoor: _brandImageSettings.userBrandImageIndoor
    property Fact _userBrandImageOutdoor: _brandImageSettings.userBrandImageOutdoor
    property Fact _appSavePath: _appSettings.savePath

    // Flyview Settings
    property var _flyViewSettings: _settingsManager.flyViewSettings
    property var _customMavlinkActionsSettings: _settingsManager.customMavlinkActionsSettings
    property Fact _virtualJoystick: _appSettings.virtualJoystick
    property Fact _virtualJoystickAutoCenterThrottle: _appSettings.virtualJoystickAutoCenterThrottle
    property Fact _showAdditionalIndicatorsCompass: _flyViewSettings.showAdditionalIndicatorsCompass
    property Fact _lockNoseUpCompass: _flyViewSettings.lockNoseUpCompass
    property Fact _guidedMinimumAltitude: _flyViewSettings.guidedMinimumAltitude
    property Fact _guidedMaximumAltitude: _flyViewSettings.guidedMaximumAltitude
    property Fact _maxGoToLocationDistance: _flyViewSettings.maxGoToLocationDistance
    property var _viewer3DSettings: _settingsManager.viewer3DSettings
    property Fact _viewer3DEnabled: _viewer3DSettings.enabled
    property Fact _viewer3DOsmFilePath: _viewer3DSettings.osmFilePath
    property Fact _viewer3DBuildingLevelHeight: _viewer3DSettings.buildingLevelHeight
    property Fact _viewer3DAltitudeBias: _viewer3DSettings.altitudeBias

    // Video Settings
    property var _videoManager: QGroundControl.videoManager
    property var _videoSettings: _settingsManager.videoSettings
    property string _videoSource: _videoSettings.videoSource.rawValue
    property bool _isGST: _videoManager.gstreamerEnabled
    property bool _isStreamSource: _videoManager.isStreamSource
    property bool _isUDP264: _isStreamSource
                             && (_videoSource === _videoSettings.udp264VideoSource)
    property bool _isUDP265: _isStreamSource
                             && (_videoSource === _videoSettings.udp265VideoSource)
    property bool _isRTSP: _isStreamSource
                           && (_videoSource === _videoSettings.rtspVideoSource)
    property bool _isTCP: _isStreamSource && (_videoSettings.tcpVideoSource)
    property bool _isMPEGTS: _isStreamSource
                             && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool _videoAutoStreamConfig: _videoManager.autoStreamConfigured
    property real _urlFieldWidth: ScreenTools.defaultFontPixelWidth * 25
    property bool _requiresUDPPort: _isUDP264 || _isUDP265 || _isMPEGTS

    // Telemetry Settings
    property bool _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr: qsTr("Not Connected")
    property bool _isAPM: _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool _showAPMStreamRates: QGroundControl.apmFirmwareSupported
                                       && _settingsManager.apmMavlinkStreamRateSettings.visible
                                       && _isAPM
    property var _apmStartMavlinkStreams: _appSettings.apmStartMavlinkStreams

    // Planview Settings
    property var _planViewSettings: QGroundControl.settingsManager.planViewSettings

    QGCFileDialogController {
        id: fileController
    }

    function customActionList() {
        var fileModel = fileController.getFiles(
                    _settingsManager.appSettings.customActionsSavePath,
                    "*.json")
        fileModel.unshift(qsTr("<None>"))
        return fileModel
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: ScreenTools.defaultFontPixelHeight

            // Custom Component for Section Headers
            component SectionHeader: QGCLabel {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: ScreenTools.largeFontPointSize
                font.bold: true
                color: qgcPal.text
                text: "Section Header"
                Rectangle {
                    anchors.fill: parent
                    color: qgcPal.windowShade
                    opacity: 0.8
                    z: -1
                }
            }

            // Custom Component for Settings Group
            component CustomSettingsGroup: Rectangle {
                Layout.fillWidth: true
                implicitHeight: settingsColumn.implicitHeight + ScreenTools.defaultFontPixelHeight
                color: qgcPal.window
                border.color: qgcPal.text
                border.width: 1
                radius: 4

                ColumnLayout {
                    id: settingsColumn
                    anchors.margins: ScreenTools.defaultFontPixelWidth
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    QGCLabel {
                        text: qsTr("Group Heading")
                        font.bold: true
                        color: qgcPal.text
                    }
                }
            }

            // General Settings
            SectionHeader {
                text: qsTr("General Settings")
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    LabelledFactComboBox {
                        label: qsTr("Language")
                        fact: _appSettings.qLocaleLanguage
                        indexModel: false
                        visible: _appSettings.qLocaleLanguage.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Color Scheme")
                        fact: _appSettings.indoorPalette
                        indexModel: false
                        visible: _appSettings.indoorPalette.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Stream GCS Position")
                        fact: _appSettings.followTarget
                        indexModel: false
                        visible: _appSettings.followTarget.visible
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Mute all audio output")
                        fact: _audioMuted
                        visible: _audioMuted.visible
                        Layout.fillWidth: true
                        property Fact _audioMuted: _appSettings.audioMuted
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Save application data to SD Card")
                        fact: _androidSaveToSDCard
                        visible: _androidSaveToSDCard.visible
                        Layout.fillWidth: true
                        property Fact _androidSaveToSDCard: _appSettings.androidSaveToSDCard
                    }

                    QGCCheckBoxSlider {
                        text: qsTr("Clear all settings on next start")
                        checked: false
                        onClicked: QGroundControl.deleteAllSettingsNextBoot()
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        visible: _appFontPointSize.visible
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        QGCLabel {
                            text: qsTr("UI Scaling")
                            color: qgcPal.text
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth

                            QGCButton {
                                text: "-"
                                onClicked: {
                                    if (_appFontPointSize.value > _appFontPointSize.min) {
                                        _appFontPointSize.value -= 1
                                    }
                                }
                                implicitHeight: baseFontEdit.height * 1.5
                                implicitWidth: implicitHeight
                            }

                            QGCLabel {
                                id: baseFontEdit
                                text: (QGroundControl.settingsManager.appSettings.appFontPointSize.value
                                       / ScreenTools.platformFontPointSize * 100).toFixed(
                                          0) + "%"
                                color: qgcPal.text
                                width: ScreenTools.defaultFontPixelWidth * 6
                            }

                            QGCButton {
                                text: "+"
                                onClicked: {
                                    if (_appFontPointSize.value < _appFontPointSize.max) {
                                        _appFontPointSize.value += 1
                                    }
                                }
                                implicitHeight: baseFontEdit.height * 1.5
                                implicitWidth: implicitHeight
                            }
                        }
                    }

                    RowLayout {
                        visible: _appSavePath.visible && !ScreenTools.isMobile
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            QGCLabel {
                                text: qsTr("Application Load/Save Path")
                            }
                            QGCLabel {
                                font.pointSize: ScreenTools.smallFontPointSize
                                text: _appSavePath.rawValue
                                      === "" ? qsTr("<default location>") : _appSavePath.value
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        QGCButton {
                            text: qsTr("Browse")
                            onClicked: savePathBrowseDialog.openForLoad()
                            QGCFileDialog {
                                id: savePathBrowseDialog
                                title: qsTr("Choose the location to save/load files")
                                folder: _appSavePath.rawValue
                                selectFolder: true
                                onAcceptedForLoad: file => _appSavePath.rawValue = file
                            }
                        }
                    }
                }
            }

            CustomSettingsGroup {
                visible: QGroundControl.settingsManager.unitsSettings.visible
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Units")
                    }

                    Repeater {
                        model: [QGroundControl.settingsManager.unitsSettings.horizontalDistanceUnits, QGroundControl.settingsManager.unitsSettings.verticalDistanceUnits, QGroundControl.settingsManager.unitsSettings.areaUnits, QGroundControl.settingsManager.unitsSettings.speedUnits, QGroundControl.settingsManager.unitsSettings.temperatureUnits]

                        LabelledFactComboBox {
                            label: modelData.shortDescription
                            fact: modelData
                            indexModel: false
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            CustomSettingsGroup {
                visible: _brandImageSettings.visible && !ScreenTools.isMobile
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Brand Image")
                    }

                    RowLayout {
                        visible: _userBrandImageIndoor.visible
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            QGCLabel {
                                text: qsTr("Indoor Image")
                            }
                            QGCLabel {
                                font.pointSize: ScreenTools.smallFontPointSize
                                text: _userBrandImageIndoor.valueString.replace(
                                          "file:///", "")
                                elide: Text.ElideMiddle
                                visible: _userBrandImageIndoor.valueString.length > 0
                                Layout.fillWidth: true
                            }
                        }

                        QGCButton {
                            text: qsTr("Browse")
                            onClicked: userBrandImageIndoorBrowseDialog.openForLoad()
                            QGCFileDialog {
                                id: userBrandImageIndoorBrowseDialog
                                title: qsTr("Choose custom brand image file")
                                folder: _userBrandImageIndoor.rawValue.replace(
                                            "file:///", "")
                                selectFolder: false
                                onAcceptedForLoad: file => _userBrandImageIndoor.rawValue
                                                   = "file:///" + file
                            }
                        }
                    }

                    RowLayout {
                        visible: _userBrandImageOutdoor.visible
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true

                            QGCLabel {
                                text: qsTr("Outdoor Image")
                            }
                            QGCLabel {
                                font.pointSize: ScreenTools.smallFontPointSize
                                text: _userBrandImageOutdoor.valueString.replace(
                                          "file:///", "")
                                elide: Text.ElideMiddle
                                visible: _userBrandImageOutdoor.valueString.length > 0
                                Layout.fillWidth: true
                            }
                        }

                        QGCButton {
                            text: qsTr("Browse")
                            onClicked: userBrandImageOutdoorBrowseDialog.openForLoad()
                            QGCFileDialog {
                                id: userBrandImageOutdoorBrowseDialog
                                title: qsTr("Choose custom brand image file")
                                folder: _userBrandImageOutdoor.rawValue.replace(
                                            "file:///", "")
                                selectFolder: false
                                onAcceptedForLoad: file => _userBrandImageOutdoor.rawValue
                                                   = "file:///" + file
                            }
                        }
                    }

                    LabelledButton {
                        label: qsTr("Reset Images")
                        buttonText: qsTr("Reset")
                        onClicked: {
                            _userBrandImageIndoor.rawValue = ""
                            _userBrandImageOutdoor.rawValue = ""
                        }
                        Layout.fillWidth: true
                    }
                }
            }

            // Flyview Settings
            SectionHeader {
                text: qsTr("Flyview Settings")
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("General")
                    }

                    FactCheckBoxSlider {
                        id: useCheckList
                        text: qsTr("Use Preflight Checklist")
                        fact: _useChecklist
                        visible: _useChecklist.visible
                                 && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString(
                                     ).length
                        Layout.fillWidth: true
                        property Fact _useChecklist: _settingsManager.appSettings.useChecklist
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Enforce Preflight Checklist")
                        fact: _enforceChecklist
                        enabled: _settingsManager.appSettings.useChecklist.value
                        visible: useCheckList.visible
                                 && _enforceChecklist.visible
                        Layout.fillWidth: true
                        property Fact _enforceChecklist: _settingsManager.appSettings.enforceChecklist
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Keep Map Centered On Vehicle")
                        fact: _keepMapCenteredOnVehicle
                        visible: _keepMapCenteredOnVehicle.visible
                        Layout.fillWidth: true
                        property Fact _keepMapCenteredOnVehicle: _flyViewSettings.keepMapCenteredOnVehicle
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Show Telemetry Log Replay Status Bar")
                        fact: _showLogReplayStatusBar
                        visible: _showLogReplayStatusBar.visible
                        Layout.fillWidth: true
                        property Fact _showLogReplayStatusBar: _flyViewSettings.showLogReplayStatusBar
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Show simple camera controls (DIGICAM_CONTROL)")
                        visible: _showDumbCameraControl.visible
                        fact: _showDumbCameraControl
                        Layout.fillWidth: true
                        property Fact _showDumbCameraControl: _flyViewSettings.showSimpleCameraControl
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Update return to home position based on device location.")
                        fact: _updateHomePosition
                        visible: _updateHomePosition.visible
                        Layout.fillWidth: true
                        property Fact _updateHomePosition: _flyViewSettings.updateHomePosition
                    }
                }
            }

            CustomSettingsGroup {
                visible: _guidedMinimumAltitude.visible
                         || _guidedMaximumAltitude.visible
                         || _maxGoToLocationDistance.visible
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Guided Commands")
                    }

                    LabelledFactTextField {
                        label: qsTr("Minimum Altitude")
                        fact: _guidedMinimumAltitude
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("Maximum Altitude")
                        fact: _guidedMaximumAltitude
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("Go To Location Max Distance")
                        fact: _maxGoToLocationDistance
                        visible: fact.visible
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Custom MAVLink Actions")
                        Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
                    }
                    QGCLabel {
                        text: qsTr("Custom action JSON files should be created in the '%1' folder.").arg(
                                  QGroundControl.settingsManager.appSettings.customActionsSavePath)
                        font.pointSize: ScreenTools.smallFontPointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    LabelledComboBox {
                        label: qsTr("Fly View Custom Actions")
                        model: customActionList()
                        onActivated: index => index == 0 ? _customMavlinkActionsSettings.flyViewActionsFile.rawValue = "" : _customMavlinkActionsSettings.flyViewActionsFile.rawValue = comboBox.currentText
                        Layout.fillWidth: true
                        Component.onCompleted: {
                            var index = comboBox.find(
                                        _customMavlinkActionsSettings.flyViewActionsFile.valueString)
                            comboBox.currentIndex = index == -1 ? 0 : index
                        }
                    }

                    LabelledComboBox {
                        label: qsTr("Joystick Custom Actions")
                        model: customActionList()
                        onActivated: index => index == 0 ? _customMavlinkActionsSettings.joystickActionsFile.rawValue = "" : _customMavlinkActionsSettings.joystickActionsFile.rawValue = comboBox.currentText
                        Layout.fillWidth: true
                        Component.onCompleted: {
                            var index = comboBox.find(
                                        _customMavlinkActionsSettings.joystickActionsFile.valueString)
                            comboBox.currentIndex = index == -1 ? 0 : index
                        }
                    }
                }
            }

            CustomSettingsGroup {
                visible: _virtualJoystick.visible
                         || _virtualJoystickAutoCenterThrottle.visible
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Virtual Joystick")
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Enabled")
                        visible: _virtualJoystick.visible
                        fact: _virtualJoystick
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Auto-Center Throttle")
                        visible: _virtualJoystickAutoCenterThrottle.visible
                        enabled: _virtualJoystick.rawValue
                        fact: _virtualJoystickAutoCenterThrottle
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                visible: _showAdditionalIndicatorsCompass.visible
                         || _lockNoseUpCompass.visible
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Instrument Panel")
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Show additional heading indicators on Compass")
                        visible: _showAdditionalIndicatorsCompass.visible
                        fact: _showAdditionalIndicatorsCompass
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Lock Compass Nose-Up")
                        visible: _lockNoseUpCompass.visible
                        fact: _lockNoseUpCompass
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                visible: _viewer3DSettings.visible
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("3D View")
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Enabled")
                        fact: _viewer3DEnabled
                        visible: _viewer3DEnabled.visible
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        enabled: _viewer3DEnabled.rawValue
                        visible: _viewer3DOsmFilePath.rawValue
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth
                            Layout.fillWidth: true

                            QGCLabel {
                                wrapMode: Text.WordWrap
                                text: qsTr("3D Map File:")
                            }

                            QGCTextField {
                                id: osmFileTextField
                                height: ScreenTools.defaultFontPixelWidth * 4.5
                                unitsLabel: ""
                                showUnits: false
                                readOnly: true
                                text: _viewer3DOsmFilePath.rawValue
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: ScreenTools.defaultFontPixelWidth

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
                                    var filename = _viewer3DOsmFilePath.rawValue
                                    const found = filename.match(/(.*)[\/\\]/)
                                    if (found) {
                                        filename = found[1] || ''
                                        fileDialog.folder = (filename[0]
                                                             === "/") ? (filename.slice(
                                                                             1)) : (filename)
                                    }
                                    fileDialog.openForLoad()
                                }

                                QGCFileDialog {
                                    id: fileDialog
                                    nameFilters: [qsTr(
                                            "OpenStreetMap files (*.osm)")]
                                    title: qsTr("Select map file")
                                    onAcceptedForLoad: file => {
                                                           osmFileTextField.text = file
                                                           _viewer3DOsmFilePath.value
                                                           = osmFileTextField.text
                                                       }
                                }
                            }
                        }
                    }

                    LabelledFactTextField {
                        label: qsTr("Average Building Level Height")
                        fact: _viewer3DBuildingLevelHeight
                        enabled: _viewer3DEnabled.rawValue
                        visible: _viewer3DBuildingLevelHeight.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("Vehicles Altitude Bias")
                        fact: _viewer3DAltitudeBias
                        enabled: _viewer3DEnabled.rawValue
                        visible: _viewer3DAltitudeBias.visible
                        Layout.fillWidth: true
                    }
                }
            }

            // Planview Settings
            SectionHeader {
                text: qsTr("Planview Settings")
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Planview")
                    }

                    LabelledFactTextField {
                        label: qsTr("Default Mission Altitude")
                        fact: _settingsManager.appSettings.defaultMissionItemAltitude
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("VTOL Transition Distance")
                        fact: _planViewSettings.vtolTransitionDistance
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Use MAV_CMD_CONDITION_GATE for pattern generation")
                        fact: _planViewSettings.useConditionGate
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Missions Do Not Require Takeoff Item")
                        fact: _planViewSettings.takeoffItemNotRequired
                        visible: fact.visible
                        Layout.fillWidth: true
                    }
                }
            }

            // Video Settings
            SectionHeader {
                text: qsTr("Video Settings")
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Video Source")
                        Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
                    }
                    QGCLabel {
                        text: _videoAutoStreamConfig ? qsTr("Mavlink camera stream is automatically configured") : ""
                        font.pointSize: ScreenTools.smallFontPointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Source")
                        indexModel: false
                        fact: _videoSettings.videoSource
                        visible: fact.visible
                        enabled: !_videoAutoStreamConfig
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                visible: !_videoAutoStreamConfig && (_isTCP || _isRTSP
                                                     || _requiresUDPPort)
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Connection")
                    }

                    LabelledFactTextField {
                        textFieldPreferredWidth: _urlFieldWidth
                        label: qsTr("RTSP URL")
                        fact: _videoSettings.rtspUrl
                        visible: _isRTSP && _videoSettings.rtspUrl.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("TCP URL")
                        textFieldPreferredWidth: _urlFieldWidth
                        fact: _videoSettings.tcpUrl
                        visible: _isTCP && _videoSettings.tcpUrl.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("UDP Port")
                        fact: _videoSettings.udpPort
                        visible: _requiresUDPPort
                                 && _videoSettings.udpPort.visible
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Settings")
                    }

                    LabelledFactTextField {
                        label: qsTr("Aspect Ratio")
                        fact: _videoSettings.aspectRatio
                        visible: !_videoAutoStreamConfig && _isStreamSource
                                 && _videoSettings.aspectRatio.visible
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Stop recording when disarmed")
                        fact: _videoSettings.disableWhenDisarmed
                        visible: !_videoAutoStreamConfig && _isStreamSource
                                 && fact.visible
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Low Latency Mode")
                        fact: _videoSettings.lowLatencyMode
                        visible: !_videoAutoStreamConfig && _isStreamSource
                                 && fact.visible && _isGST
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Video decode priority")
                        fact: _videoSettings.forceVideoDecoder
                        visible: fact.visible
                        indexModel: false
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Local Video Storage")
                    }

                    LabelledFactComboBox {
                        label: qsTr("Record File Format")
                        fact: _videoSettings.recordingFormat
                        visible: _videoSettings.recordingFormat.visible
                        Layout.fillWidth: true
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Auto-Delete Saved Recordings")
                        fact: _videoSettings.enableStorageLimit
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        label: qsTr("Max Storage Usage")
                        fact: _videoSettings.maxVideoSize
                        visible: fact.visible
                        enabled: _videoSettings.enableStorageLimit.rawValue
                        Layout.fillWidth: true
                    }
                }
            }

            // Telemetry Settings
            SectionHeader {
                text: qsTr("Telemetry Settings")
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Ground Station")
                    }

                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        QGCLabel {
                            text: qsTr("MAVLink System ID:")
                            Layout.fillWidth: true
                        }

                        QGCTextField {
                            text: QGroundControl.mavlinkSystemID.toString()
                            numericValuesOnly: true
                            onEditingFinished: QGroundControl.mavlinkSystemID = parseInt(
                                                   text)
                        }
                    }

                    QGCCheckBoxSlider {
                        text: qsTr("Emit heartbeat")
                        checked: QGroundControl.multiVehicleManager.gcsHeartBeatEnabled
                        onClicked: QGroundControl.multiVehicleManager.gcsHeartBeatEnabled = checked
                        Layout.fillWidth: true
                    }

                    QGCCheckBoxSlider {
                        text: qsTr("Only connect to vehicle with same MAVLink protocol version")
                        checked: QGroundControl.isVersionCheckEnabled
                        onClicked: QGroundControl.isVersionCheckEnabled = checked
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                visible: _mavlink2SigningKey.visible
                property Fact _mavlink2SigningKey: _appSettings.mavlink2SigningKey
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("MAVLink 2 Signing")
                        Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
                    }
                    QGCLabel {
                        text: qsTr("Signing keys should only be sent to the vehicle over secure links.")
                        font.pointSize: ScreenTools.smallFontPointSize
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // RowLayout {
                    //     spacing: ScreenTools.defaultFontPixelWidth
                    //     Layout.fillWidth: true

                    //     LabelledFactTextField {
                    //         textFieldPreferredWidths: ScreenTools.defaultFontPixelWidth * 32
                    //         label: qsTr("Key")
                    //         fact: mavlink2SigningGroup._mavlink2SigningKey
                    //         Layout.fillWidth: true
                    //     }

                    //     QGCButton {
                    //         text: qsTr("Send to Vehicle")
                    //         enabled: _activeVehicle
                    //         onClicked: {
                    //             sendToVehiclePrompt.visible = false
                    //             _activeVehicle.sendSetupSigning()
                    //         }
                    //     }
                    // }

                    QGCLabel {
                        id: sendToVehiclePrompt
                        text: qsTr("Signing key has changed. Don't forget to send to Vehicle(s) if needed.")
                        visible: false
                        Layout.fillWidth: true
                    }

                    Connections {
                        target: mavlink2SigningGroup._mavlink2SigningKey
                        onRawValueChanged: sendToVehiclePrompt.visible = true
                    }
                }
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("MAVLink Forwarding")
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Enable")
                        fact: _appSettings.forwardMavlink
                        visible: fact.visible
                        Layout.fillWidth: true
                    }

                    LabelledFactTextField {
                        textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 20
                        label: qsTr("Host name")
                        fact: _appSettings.forwardMavlinkHostName
                        visible: fact.visible
                        enabled: _appSettings.forwardMavlink.rawValue
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                visible: !_disableAllDataPersistence
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Logging")
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Save log after each flight")
                        fact: _telemetrySave
                        visible: fact.visible
                        Layout.fillWidth: true
                        property Fact _telemetrySave: _appSettings.telemetrySave
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Save logs even if vehicle was not armed")
                        fact: _telemetrySaveNotArmed
                        visible: fact.visible
                        enabled: _appSettings.telemetrySave.rawValue
                        Layout.fillWidth: true
                        property Fact _telemetrySaveNotArmed: _appSettings.telemetrySaveNotArmed
                    }

                    FactCheckBoxSlider {
                        text: qsTr("Save CSV log of telemetry data")
                        fact: _saveCsvTelemetry
                        visible: fact.visible
                        Layout.fillWidth: true
                        property Fact _saveCsvTelemetry: _appSettings.saveCsvTelemetry
                    }
                }
            }

            CustomSettingsGroup {
                visible: _showAPMStreamRates
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Stream Rates (ArduPilot Only)")
                    }

                    QGCCheckBoxSlider {
                        id: controllerByVehicleCheckBox
                        text: qsTr("Controlled By vehicle")
                        checked: !_apmStartMavlinkStreams.rawValue
                        onClicked: _apmStartMavlinkStreams.rawValue = !checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Raw Sensors")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Extended Status")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("RC Channels")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Position")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Extra 1")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Extra 2")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }

                    LabelledFactComboBox {
                        label: qsTr("Extra 3")
                        fact: _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
                        indexModel: false
                        enabled: !controllerByVehicleCheckBox.checked
                        Layout.fillWidth: true
                    }
                }
            }

            CustomSettingsGroup {
                ColumnLayout {
                    parent: settingsColumn
                    QGCLabel {
                        text: qsTr("Link Status (Current Vehicle)")
                    }

                    LabelledLabel {
                        label: qsTr("Total messages sent (computed)")
                        labelText: _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
                        Layout.fillWidth: true
                    }

                    LabelledLabel {
                        label: qsTr("Total messages received")
                        labelText: _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
                        Layout.fillWidth: true
                    }

                    LabelledLabel {
                        label: qsTr("Total message loss")
                        labelText: _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
                        Layout.fillWidth: true
                    }

                    LabelledLabel {
                        label: qsTr("Loss rate:")
                        labelText: _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(
                                                        0) + '%' : _notConnectedStr
                        Layout.fillWidth: true
                    }

                    LabelledLabel {
                        label: qsTr("Signing:")
                        labelText: _activeVehicle ? (_activeVehicle.mavlinkSigning ? "On" : "Off") : _notConnectedStr
                        Layout.fillWidth: true
                    }
                }
            }

            Item {
                height: ScreenTools.defaultFontPixelHeight
                Layout.fillWidth: true
            }
        }
    }

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: true
    }
}
