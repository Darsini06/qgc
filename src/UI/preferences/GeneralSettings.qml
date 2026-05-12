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
    id: root

    // --- Settings Managers ---
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath

    // --- Video Settings ---
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
    property bool   _requiresUDPPort:           _isUDP264 || _isUDP265 || _isMPEGTS

    // --- State ---
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property bool   _isNarrow:                  root.width < ScreenTools.defaultFontPixelWidth * 60
    property color  _themeColor:                typeof app_color !== "undefined" ? app_color : "#4A2C6D"
    property color  _accentColor:               typeof accent_color !== "undefined" ? accent_color : "#673AB7"

    // --- Responsive Helper Components ---
    component SectionHeader : ColumnLayout {
        property string title
        spacing: 4
        Layout.fillWidth: true
        Layout.topMargin: ScreenTools.defaultFontPixelHeight
        
        QGCLabel {
            text:           title
            font.bold:      true
            font.pointSize: ScreenTools.mediumFontPointSize
            color:          _themeColor
        }
        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: _themeColor
            opacity: 0.2
        }
    }

    component ResponsiveRow : GridLayout {
        property string label
        property alias  content:        container.data
        property bool   showLabel:      true
        
        columns:            _isNarrow ? 1 : 2
        columnSpacing:      ScreenTools.defaultFontPixelWidth * 2
        rowSpacing:         _isNarrow ? 4 : 8
        Layout.fillWidth:   true

        QGCLabel {
            text:               label
            color:              "#444"
            font.bold:          true
            visible:            showLabel
            Layout.fillWidth:   _isNarrow
            Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 30
        }

        Item {
            id:                 container
            Layout.fillWidth:   true
            Layout.preferredHeight: childrenRect.height
        }
    }

    ColumnLayout {
        id:                 contentLayout
        Layout.fillWidth:   true
        spacing:            ScreenTools.defaultFontPixelHeight

        // --- General Section ---
        SectionHeader { title: qsTr("Application Settings") }

        ResponsiveRow {
            label:              qsTr("Stream GCS Position")
            visible:            _appSettings.followTarget.visible
            FactComboBox {
                fact:           _appSettings.followTarget
                indexModel:     false
                width:          parent.width
            }
        }

        ResponsiveRow {
            label:              qsTr("Save data to SD Card")
            visible:            _appSettings.androidSaveToSDCard.visible
            
            QGCCheckBox {
                checked:        _appSettings.androidSaveToSDCard.value != 0
                onClicked:      _appSettings.androidSaveToSDCard.value = (checked ? 1 : 0)
                // Styling handled by QGCCheckBox
            }
        }

        // --- Desktop Only Path ---
        ResponsiveRow {
            label:              qsTr("Application Load/Save Path")
            visible:            _appSavePath.visible && !ScreenTools.isMobile
            
            RowLayout {
                width: parent.width
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:              Text.ElideMiddle
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

        // --- Units Section ---
        SectionHeader { title: qsTr("Measurement Units") }

        Repeater {
            model: [
                _settingsManager.unitsSettings.horizontalDistanceUnits,
                _settingsManager.unitsSettings.verticalDistanceUnits,
                _settingsManager.unitsSettings.areaUnits,
                _settingsManager.unitsSettings.speedUnits,
                _settingsManager.unitsSettings.temperatureUnits
            ]

            ResponsiveRow {
                label:          modelData.shortDescription
                FactComboBox {
                    fact:       modelData
                    indexModel: false
                    width:      parent.width
                }
            }
        }

        // --- Video Section ---
        SectionHeader { 
            title:      qsTr("Video Settings") 
            visible:    _videoSettings.videoSource.visible
        }

        ResponsiveRow {
            label:              qsTr("Video Source")
            visible:            _videoSettings.videoSource.visible
            FactComboBox {
                fact:           _videoSettings.videoSource
                indexModel:     false
                width:          parent.width
            }
        }

        GridLayout {
            columns:            _isNarrow ? 1 : 2
            columnSpacing:      ScreenTools.defaultFontPixelWidth * 2
            rowSpacing:         ScreenTools.defaultFontPixelHeight
            Layout.fillWidth:   true
            visible:            _isStreamSource && _videoSettings.videoSource.visible

            // RTSP URL
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                visible: _isRTSP && _videoSettings.rtspUrl.visible
                QGCLabel { text: qsTr("RTSP URL"); font.bold: true; color: "#444" }
                FactTextField {
                    fact:               _videoSettings.rtspUrl
                    Layout.fillWidth:   true
                }
            }

            // TCP URL
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                visible: _isTCP && _videoSettings.tcpUrl.visible
                QGCLabel { text: qsTr("TCP URL"); font.bold: true; color: "#444" }
                FactTextField {
                    fact:               _videoSettings.tcpUrl
                    Layout.fillWidth:   true
                }
            }

            // UDP Port
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                visible: _requiresUDPPort && _videoSettings.udpPort.visible
                QGCLabel { text: qsTr("UDP Port"); font.bold: true; color: "#444" }
                FactTextField {
                    fact:               _videoSettings.udpPort
                    Layout.fillWidth:   true
                }
            }

            // Aspect Ratio
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
                QGCLabel { text: qsTr("Aspect Ratio"); font.bold: true; color: "#444" }
                FactTextField {
                    fact:               _videoSettings.aspectRatio
                    Layout.fillWidth:   true
                }
            }
        }

        ResponsiveRow {
            label:              qsTr("Low Latency Mode")
            visible:            !_videoAutoStreamConfig && _isStreamSource && _videoSettings.lowLatencyMode.visible && _isGST
            QGCCheckBox {
                checked:        _videoSettings.lowLatencyMode.value != 0
                onClicked:      _videoSettings.lowLatencyMode.value = (checked ? 1 : 0)
            }
        }

        // --- Logging Section ---
        SectionHeader { 
            title:      qsTr("Logging & Data") 
            visible:    !_disableAllDataPersistence
        }

        ResponsiveRow {
            label:              qsTr("Save log after each flight")
            visible:            !_disableAllDataPersistence && _appSettings.telemetrySave.visible
            QGCCheckBox {
                checked:        _appSettings.telemetrySave.value != 0
                onClicked:      _appSettings.telemetrySave.value = (checked ? 1 : 0)
            }
        }

        ResponsiveRow {
            label:              qsTr("Save logs even if not armed")
            visible:            !_disableAllDataPersistence && _appSettings.telemetrySaveNotArmed.visible
            enabled:            _appSettings.telemetrySave.rawValue
            opacity:            enabled ? 1 : 0.5
            QGCCheckBox {
                checked:        _appSettings.telemetrySaveNotArmed.value != 0
                onClicked:      _appSettings.telemetrySaveNotArmed.value = (checked ? 1 : 0)
            }
        }

        // --- Brand Images (Desktop Only) ---
        SectionHeader { 
            title:      qsTr("Brand Branding") 
            visible:    _brandImageSettings.visible && !ScreenTools.isMobile
        }

        ResponsiveRow {
            label:              qsTr("Indoor Image")
            visible:            _brandImageSettings.visible && !ScreenTools.isMobile
            RowLayout {
                width: parent.width
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageIndoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    visible:            _userBrandImageIndoor.valueString.length > 0
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
        }

        // --- Connection Links ---
        SectionHeader { title: qsTr("Connection Links") }
        
        LinkSettings {
            Layout.fillWidth: true
        }

        // Spacer for bottom
        Item { Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2 }
    }
}