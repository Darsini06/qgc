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
    id: root
    backgroundColor: "white"


    // -- Properties --
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property var    _flyViewSettings:           _settingsManager.flyViewSettings
    property var    _guidedSettings:            _settingsManager.guidedSettings
    property var    _viewer3DSettings:          _settingsManager.viewer3DSettings
    property var    _videoManager:              QGroundControl.videoManager
    property var    _videoSettings:             _settingsManager.videoSettings
    property var    _linkManager:               QGroundControl.linkManager
    property var    _autoConnectSettings:       _settingsManager.autoConnectSettings
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle

    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath
    property Fact   _guidedMinimumAltitude:     _guidedSettings.guidedMinimumAltitude
    property Fact   _guidedMaximumAltitude:     _guidedSettings.guidedMaximumAltitude
    property Fact   _maxGoToLocationDistance:   _guidedSettings.maxGoToLocationDistance
    property Fact   _viewer3DEnabled:           _viewer3DSettings.enabled
    property Fact   _viewer3DOsmFilePath:       _viewer3DSettings.osmFilePath
    property Fact   _viewer3DBuildingLevelHeight: _viewer3DSettings.buildingLevelHeight
    property Fact   _viewer3DAltitudeBias:      _viewer3DSettings.altitudeBias

    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property string _notConnectedStr:           qsTr("Not Connected")
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

    property bool   _isNarrow:                  root.width < ScreenTools.defaultFontPixelWidth * 80
    property real   _innerMargin:               _isNarrow ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 4
    property real   _contentWidth:              Math.min(root.width - (_innerMargin * 2), ScreenTools.defaultFontPixelWidth * 120)

    // -- Content Layout --
    ColumnLayout {
        id:                 contentLayout
        Layout.fillWidth:   true
        Layout.preferredWidth: _contentWidth
        Layout.maximumWidth: ScreenTools.defaultFontPixelWidth * 120
        Layout.alignment:   Qt.AlignHCenter
        Layout.leftMargin:  _innerMargin
        Layout.rightMargin: _innerMargin
        spacing:            _isNarrow ? ScreenTools.defaultFontPixelHeight / 2 : ScreenTools.defaultFontPixelHeight

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text:             qsTr("General Settings")
            font.pixelSize:   ScreenTools.isMobile ? 22 : 28
            color:            "black"
            font.bold:        true
            horizontalAlignment: Text.AlignHCenter
            bottomPadding:    ScreenTools.defaultFontPixelHeight
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        }

        // --- Application Section ---
        LabelledFactComboBox {
            label:      qsTr("Language")
            fact:       _appSettings.qLocaleLanguage
            indexModel: false
            visible:    _appSettings.qLocaleLanguage.visible
        }

        // --- Stream GCS Position (Tick Style) ---
        ColumnLayout {
            spacing: 12
            visible: _appSettings.followTarget.visible
            Layout.fillWidth: true
            QGCLabel { text: qsTr("Stream GCS Position"); color: "black"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 20
                Repeater {
                    model: _appSettings.followTarget.enumStrings
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 26; height: 26; border.color: _appSettings.followTarget.rawValue === _appSettings.followTarget.enumValues[index] ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                            QGCColoredImage {
                                anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                                visible: _appSettings.followTarget.rawValue === _appSettings.followTarget.enumValues[index]
                            }
                        }
                        QGCLabel { text: modelData; color: "black"; font.pointSize: ScreenTools.defaultFontPointSize }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: _appSettings.followTarget.rawValue = _appSettings.followTarget.enumValues[index]
                        }
                    }
                }
            }
        }

        // --- SD Card Save (Tick Style) ---
        RowLayout {
            spacing: 15
            visible: _appSettings.androidSaveToSDCard.visible
            Rectangle {
                width: 28; height: 28; border.color: _appSettings.androidSaveToSDCard.value != 0 ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                QGCColoredImage {
                    anchors.centerIn: parent; width: 20; height: 20; source: "/qmlimages/checkbox-check.svg"; color: "black"
                    visible: _appSettings.androidSaveToSDCard.value != 0
                }
            }
            QGCLabel { text: qsTr("Save application data to SD Card"); color: "black"; font.bold: true; Layout.fillWidth: true }
            MouseArea {
                anchors.fill: parent
                onClicked: _appSettings.androidSaveToSDCard.value = (_appSettings.androidSaveToSDCard.value == 0 ? 1 : 0)
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _appSavePath.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth: true
                spacing:          0
                QGCLabel { text: qsTr("Application Load/Save Path"); color: "black"; font.bold: true }
                QGCLabel {
                    Layout.fillWidth: true
                    font.pointSize:   ScreenTools.smallFontPointSize
                    text:             _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:            Text.ElideMiddle
                }
            }

            QGCButton {
                text:      qsTr("Browse")
                onClicked: savePathBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:                 savePathBrowseDialog
                    title:              qsTr("Choose the location to save/load files")
                    folder:             _appSavePath.rawValue
                    selectFolder:       true
                    onAcceptedForLoad:  (file) => _appSavePath.rawValue = file
                }
            }
        }

        // --- Units Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        }


        Repeater {
            visible: QGroundControl.settingsManager.unitsSettings.visible
            model:   [ _settingsManager.unitsSettings.horizontalDistanceUnits, _settingsManager.unitsSettings.verticalDistanceUnits, _settingsManager.unitsSettings.areaUnits, _settingsManager.unitsSettings.speedUnits, _settingsManager.unitsSettings.temperatureUnits ]
            ColumnLayout {
                id: unitRow
                property var unitFact: modelData
                spacing: 12
                Layout.fillWidth: true
                QGCLabel { text: unitFact.shortDescription; color: "black"; font.bold: true }
                Flow {
                    Layout.fillWidth: true
                    spacing: 20
                    Repeater {
                        model: unitFact.enumStrings
                        RowLayout {
                            spacing: 12
                            Rectangle {
                                width: 26; height: 26; border.color: unitFact.value === unitFact.enumValues[index] ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                                QGCColoredImage {
                                    anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                                    visible: unitFact.value === unitFact.enumValues[index]
                                }
                            }
                            QGCLabel { text: modelData; color: "black"; font.pointSize: ScreenTools.smallFontPointSize }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: unitFact.value = unitFact.enumValues[index]
                            }
                        }
                    }
                }
                Item { Layout.preferredHeight: 8 } // Spacer
            }
        }

        // --- Brand Image Section ---
        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _userBrandImageIndoor.visible && _brandImageSettings.visible && !ScreenTools.isMobile
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          0
                QGCLabel { text: qsTr("Indoor Image"); color: "black"; font.bold: true }
                QGCLabel {
                    Layout.fillWidth: true
                    font.pointSize:   ScreenTools.smallFontPointSize
                    text:             _userBrandImageIndoor.valueString.replace("file:///", "")
                    elide:            Text.ElideMiddle
                    visible:          _userBrandImageIndoor.valueString.length > 0
                }
            }

            QGCButton {
                Layout.alignment: _isNarrow ? Qt.AlignRight : Qt.AlignRight
                text:      qsTr("Browse")
                onClicked: userBrandImageIndoorBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:                 userBrandImageIndoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageIndoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageIndoor.rawValue = "file:///" + file
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _userBrandImageOutdoor.visible && _brandImageSettings.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth: true
                spacing:          0
                QGCLabel { text: qsTr("Outdoor Image"); color: "black"; font.bold: true }
                QGCLabel {
                    Layout.fillWidth: true
                    font.pointSize:   ScreenTools.smallFontPointSize
                    text:             _userBrandImageOutdoor.valueString.replace("file:///", "")
                    elide:            Text.ElideMiddle
                    visible:          _userBrandImageOutdoor.valueString.length > 0
                }
            }

            QGCButton {
                Layout.alignment: _isNarrow ? Qt.AlignRight : Qt.AlignRight
                text:      qsTr("Browse")
                onClicked: userBrandImageOutdoorBrowseDialog.openForLoad()
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
            visible:    _brandImageSettings.visible && !ScreenTools.isMobile
            label:      qsTr("Reset Images")
            buttonText: qsTr("Reset")
            onClicked:  {
                _userBrandImageIndoor.rawValue = ""
                _userBrandImageOutdoor.rawValue = ""
            }
        }

        // --- Fly View Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        }

        Text {
            text:             qsTr("Flight View Config")
            font.pixelSize:   18
            color:            "black"
            font.bold:        true
        }
        // --- Fly View Section (Tick Style) ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            
            // Checkbox Template for Fly View
            Repeater {
                model: [
                    { t: qsTr("Use Preflight Checklist"), f: _appSettings.useChecklist, v: _appSettings.useChecklist.visible && QGroundControl.corePlugin.options.preFlightChecklistUrl.toString().length, e: true },
                    { t: qsTr("Enforce Preflight Checklist"), f: _appSettings.enforceChecklist, v: _appSettings.enforceChecklist.visible && _appSettings.useChecklist.visible, e: _appSettings.useChecklist.value },
                    { t: qsTr("Keep Map Centered On Vehicle"), f: _flyViewSettings.keepMapCenteredOnVehicle, v: _flyViewSettings.keepMapCenteredOnVehicle.visible, e: true },
                    { t: qsTr("Show Telemetry Log Replay Status Bar"), f: _flyViewSettings.showLogReplayStatusBar, v: _flyViewSettings.showLogReplayStatusBar.visible, e: true },
                    { t: qsTr("Show simple camera controls"), f: _flyViewSettings.showSimpleCameraControl, v: _flyViewSettings.showSimpleCameraControl.visible, e: true },
                    { t: qsTr("Update device-location-based RTH"), f: _flyViewSettings.updateHomePosition, v: _flyViewSettings.updateHomePosition.visible, e: true },
                    { t: qsTr("Show additional heading indicators"), f: _flyViewSettings.showAdditionalIndicatorsCompass, v: _flyViewSettings.showAdditionalIndicatorsCompass.visible, e: true },
                    { t: qsTr("Lock Compass Nose-Up"), f: _flyViewSettings.lockNoseUpCompass, v: _flyViewSettings.lockNoseUpCompass.visible, e: true }
                ]
                delegate: RowLayout {
                    spacing: 15
                    visible: modelData.v
                    opacity: modelData.e ? 1 : 0.5
                    Rectangle {
                        width: 26; height: 26; border.color: modelData.f.value != 0 ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                        QGCColoredImage {
                            anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                            visible: modelData.f.value != 0
                        }
                    }
                    QGCLabel { text: modelData.t; color: "black"; Layout.fillWidth: true }
                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData.e
                        onClicked: modelData.f.value = (modelData.f.value == 0 ? 1 : 0)
                    }
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Minimum Altitude")
            fact:             _guidedMinimumAltitude
            visible:          fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Maximum Altitude")
            fact:             _guidedMaximumAltitude
            visible:          fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Go To Location Max Distance")
            fact:             _maxGoToLocationDistance
            visible:          fact.visible
        }


        // --- 3D Viewer Section (Tick Style) ---
        RowLayout {
            spacing: 15
            visible: _viewer3DEnabled.visible && _viewer3DSettings.visible
            Rectangle {
                width: 26; height: 26; border.color: _viewer3DEnabled.value != 0 ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                QGCColoredImage {
                    anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                    visible: _viewer3DEnabled.value != 0
                }
            }
            QGCLabel { text: qsTr("3D Viewer Enabled"); color: "black"; font.bold: true; Layout.fillWidth: true }
            MouseArea {
                anchors.fill: parent
                onClicked: _viewer3DEnabled.value = (_viewer3DEnabled.value == 0 ? 1 : 0)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing:          ScreenTools.defaultFontPixelWidth
            enabled:          _viewer3DEnabled.rawValue
            visible:          _viewer3DOsmFilePath.rawValue && _viewer3DSettings.visible

            ColumnLayout {
                Layout.fillWidth: true
                spacing:          ScreenTools.defaultFontPixelHeight / 4
                QGCLabel { text: qsTr("3D Map File:"); color: "black"; font.bold: true }
                QGCTextField {
                    id:               osmFileTextField
                    Layout.fillWidth: true
                    readOnly:         true
                    text:             _viewer3DOsmFilePath.rawValue
                }
            }

            Flow {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing:          ScreenTools.defaultFontPixelWidth
                
                Item { Layout.fillWidth: _isNarrow; visible: _isNarrow } // Spacer for layout

                QGCButton {
                    text:      qsTr("Clear")
                    onClicked: {
                        osmFileTextField.text = "Please select an OSM file"
                        _viewer3DOsmFilePath.value = osmFileTextField.text
                    }
                }
                QGCButton {
                    text:      qsTr("Select File")
                    onClicked: fileDialog.openForLoad()
                    QGCFileDialog {
                        id:          fileDialog
                        nameFilters: [qsTr("OpenStreetMap files (*.osm)")]
                        title:       qsTr("Select map file")
                        onAcceptedForLoad: (file) => {
                            osmFileTextField.text = file
                            _viewer3DOsmFilePath.value = file
                        }
                    }
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Average Building Level Height")
            fact:             _viewer3DBuildingLevelHeight
            enabled:          _viewer3DEnabled.rawValue
            visible:          fact.visible && _viewer3DSettings.visible
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Vehicles Altitude Bias")
            fact:             _viewer3DAltitudeBias
            enabled:          _viewer3DEnabled.rawValue
            visible:          fact.visible && _viewer3DSettings.visible
        }

        // --- Video Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        }

        Text {
            Layout.alignment: Qt.AlignLeft
            text:             qsTr("Video Settings")
            font.pixelSize:   ScreenTools.isMobile ? 18 : 22
            color:            "black"
            font.bold:        true
            topPadding:       ScreenTools.defaultFontPixelHeight
            bottomPadding:    ScreenTools.defaultFontPixelHeight / 2
        }

        ColumnLayout {
            spacing: 10
            visible: _videoSettings.videoSource.visible
            QGCLabel { text: qsTr("Video Source"); color: "black"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 15
                Repeater {
                    model: _videoSettings.videoSource.enumStrings
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 26; height: 26; border.color: _videoSettings.videoSource.rawValue === _videoSettings.videoSource.enumValues[index] ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                            QGCColoredImage {
                                anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                                visible: _videoSettings.videoSource.rawValue === _videoSettings.videoSource.enumValues[index]
                            }
                        }
                        QGCLabel { text: modelData; color: "black" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: _videoSettings.videoSource.rawValue = _videoSettings.videoSource.enumValues[index]
                        }
                    }
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:        true
            textFieldPreferredWidth: _urlFieldWidth
            label:                   qsTr("RTSP URL")
            fact:                    _videoSettings.rtspUrl
            visible:                 _isRTSP && fact.visible
            enabled:                 !_videoAutoStreamConfig
        }

        LabelledFactTextField {
            Layout.fillWidth:        true
            textFieldPreferredWidth: _urlFieldWidth
            label:                   qsTr("TCP URL")
            fact:                    _videoSettings.tcpUrl
            visible:                 _isTCP && fact.visible
            enabled:                 !_videoAutoStreamConfig
        }

        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("UDP Port")
            fact:             _videoSettings.udpPort
            visible:          _requiresUDPPort && fact.visible
            enabled:          !_videoAutoStreamConfig
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
            QGCLabel { text: qsTr("Aspect Ratio"); color: "black"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 20
                Repeater {
                    model: _videoSettings.aspectRatio.enumStrings
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 26; height: 26; border.color: _videoSettings.aspectRatio.rawValue === _videoSettings.aspectRatio.enumValues[index] ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                            QGCColoredImage {
                                anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                                visible: _videoSettings.aspectRatio.rawValue === _videoSettings.aspectRatio.enumValues[index]
                            }
                        }
                        QGCLabel { text: modelData; color: "black" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: _videoSettings.aspectRatio.rawValue = _videoSettings.aspectRatio.enumValues[index]
                        }
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            
            Repeater {
                model: [
                    { t: qsTr("Stop recording when disarmed"), f: _videoSettings.disableWhenDisarmed, v: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.disableWhenDisarmed.visible, e: true },
                    { t: qsTr("Low Latency Mode"), f: _videoSettings.lowLatencyMode, v: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.lowLatencyMode.visible && _isGST, e: true },
                    { t: qsTr("Auto-Delete Saved Recordings"), f: _videoSettings.enableStorageLimit, v: _videoSettings.enableStorageLimit.visible, e: true }
                ]
                delegate: RowLayout {
                    spacing: 15
                    visible: modelData.v
                    Rectangle {
                        width: 26; height: 26; border.color: modelData.f.value != 0 ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                        QGCColoredImage {
                            anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                            visible: modelData.f.value != 0
                        }
                    }
                    QGCLabel { text: modelData.t; color: "black"; Layout.fillWidth: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.f.value = (modelData.f.value == 0 ? 1 : 0)
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            visible: _videoSettings.forceVideoDecoder.visible
            QGCLabel { text: qsTr("Video Decode Priority"); color: "black"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 20
                Repeater {
                    model: _videoSettings.forceVideoDecoder.enumStrings
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 26; height: 26; border.color: _videoSettings.forceVideoDecoder.rawValue === _videoSettings.forceVideoDecoder.enumValues[index] ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                            QGCColoredImage {
                                anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                                visible: _videoSettings.forceVideoDecoder.rawValue === _videoSettings.forceVideoDecoder.enumValues[index]
                            }
                        }
                        QGCLabel { text: modelData; color: "black" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: _videoSettings.forceVideoDecoder.rawValue = _videoSettings.forceVideoDecoder.enumValues[index]
                        }
                    }
                }
            }
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            visible: _videoSettings.recordingFormat.visible
            QGCLabel { text: qsTr("Record File Format"); color: "black"; font.bold: true }
            Flow {
                Layout.fillWidth: true
                spacing: 20
                Repeater {
                    model: _videoSettings.recordingFormat.enumStrings
                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 26; height: 26; border.color: _videoSettings.recordingFormat.rawValue === _videoSettings.recordingFormat.enumValues[index] ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                            QGCColoredImage {
                                anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                                visible: _videoSettings.recordingFormat.rawValue === _videoSettings.recordingFormat.enumValues[index]
                            }
                        }
                        QGCLabel { text: modelData; color: "black" }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: _videoSettings.recordingFormat.rawValue = _videoSettings.recordingFormat.enumValues[index]
                        }
                    }
                }
            }
        }


        LabelledFactTextField {
            Layout.fillWidth: true
            label:            qsTr("Max Storage Usage")
            fact:             _videoSettings.maxVideoSize
            visible:          fact.visible
            enabled:          _videoSettings.enableStorageLimit.rawValue
        }

        // --- Logging Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        }

        Text {
            Layout.alignment: Qt.AlignLeft
            text:             qsTr("Logging")
            font.pixelSize:   ScreenTools.isMobile ? 18 : 22
            color:            "black"
            font.bold:        true
            topPadding:       ScreenTools.defaultFontPixelHeight
            bottomPadding:    ScreenTools.defaultFontPixelHeight / 2
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
                    { t: qsTr("Save CSV log of telemetry data"), f: _appSettings.saveCsvTelemetry, v: _appSettings.saveCsvTelemetry.visible, e: true }
                ]
                delegate: RowLayout {
                    spacing: 15
                    visible: modelData.v
                    opacity: modelData.e ? 1 : 0.5
                    Rectangle {
                        width: 26; height: 26; border.color: modelData.f.value != 0 ? "black" : "#CCC"; border.width: 2; radius: 4; color: "white"
                        QGCColoredImage {
                            anchors.centerIn: parent; width: 18; height: 18; source: "/qmlimages/checkbox-check.svg"; color: "black"
                            visible: modelData.f.value != 0
                        }
                    }
                    QGCLabel { text: modelData.t; color: "black"; Layout.fillWidth: true }
                    MouseArea {
                        anchors.fill: parent
                        enabled: modelData.e
                        onClicked: modelData.f.value = (modelData.f.value == 0 ? 1 : 0)
                    }
                }
            }
        }

        // --- Links Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight / 2
        }

        Text {
            Layout.alignment: Qt.AlignLeft
            text:             qsTr("Communication Links")
            font.pixelSize:   ScreenTools.isMobile ? 18 : 22
            color:            "black"
            font.bold:        true
            topPadding:       ScreenTools.defaultFontPixelHeight
            bottomPadding:    ScreenTools.defaultFontPixelHeight / 2
        }

        Repeater {
            model: _linkManager.linkConfigurations
            ColumnLayout {
                id:               linkRow
                Layout.fillWidth: true
                visible:          !object.dynamic
                spacing:          ScreenTools.defaultFontPixelHeight / 4

                // Background highlight on hover/mobile
                Rectangle {
                    Layout.fillWidth: true
                    height:           Math.max(linkMainRow.height + 10, ScreenTools.minTouchPixels)
                    color:            "#F5F5F5"
                    radius:           8
                    visible:          !_isNarrow

                    RowLayout {
                        id:               linkMainRow
                        anchors.fill:     parent
                        anchors.margins:  10
                        spacing:          15

                        QGCLabel {
                            Layout.fillWidth: true
                            text:             object.name
                            color:            "black"
                            font.bold:        true
                        }

                        RowLayout {
                            spacing: 15
                            QGCColoredImage {
                                height:            24
                                width:             height
                                sourceSize.height: height
                                fillMode:          Image.PreserveAspectFit
                                color:             qgcPalEdit.text
                                source:            "/res/pencil.svg"
                                enabled:           !object.link
                                QGCPalette { id: qgcPalEdit; colorGroupEnabled: parent.enabled }
                                QGCMouseArea {
                                    fillItem: parent
                                    onClicked: {
                                        var editingConfig = _linkManager.startConfigurationEditing(object)
                                        linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                                    }
                                }
                            }

                            QGCColoredImage {
                                height:            24
                                width:             height
                                sourceSize.height: height
                                fillMode:          Image.PreserveAspectFit
                                color:             qgcPalDelete.text
                                source:            "/res/TrashDelete.svg"
                                QGCPalette { id: qgcPalDelete; colorGroupEnabled: parent.enabled }
                                QGCMouseArea {
                                    fillItem: parent
                                    onClicked: mainWindow.showMessageDialog(
                                                   qsTr("Delete Link"),
                                                   qsTr("Are you sure you want to delete '%1'?").arg(object.name),
                                                   Dialog.Ok | Dialog.Cancel,
                                                   function () { _linkManager.removeConfiguration(object) })
                                }
                            }

                            QGCButton {
                                text:      object.link ? qsTr("Disconnect") : qsTr("Connect")
                                onClicked: {
                                    if (object.link) {
                                        object.link.disconnect()
                                    } else {
                                        _linkManager.createConnectedLink(object)
                                    }
                                }
                            }
                        }
                    }
                }

                // Narrow screen layout
                Rectangle {
                    Layout.fillWidth: true
                    height:           narrowCol.implicitHeight + 20
                    color:            "#F8F9FB"
                    radius:           10
                    border.color:     "#E0E0E0"
                    border.width:     1
                    visible:          _isNarrow

                    ColumnLayout {
                        id:               narrowCol
                        anchors.fill:     parent
                        anchors.margins:  12
                        spacing:          10

                        QGCLabel {
                            Layout.fillWidth: true
                            text:             object.name
                            color:            "black"
                            font.bold:        true
                            font.pointSize:   ScreenTools.mediumFontPointSize
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing:          15

                            QGCButton {
                                Layout.preferredWidth: ScreenTools.minTouchPixels * 2
                                text:      qsTr("Edit")
                                enabled:   !object.link
                                onClicked: {
                                    var editingConfig = _linkManager.startConfigurationEditing(object)
                                    linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                                }
                            }

                            QGCButton {
                                Layout.preferredWidth: ScreenTools.minTouchPixels * 2
                                text:      qsTr("Delete")
                                onClicked: mainWindow.showMessageDialog(
                                               qsTr("Delete Link"),
                                               qsTr("Are you sure you want to delete '%1'?").arg(object.name),
                                               Dialog.Ok | Dialog.Cancel,
                                               function () { _linkManager.removeConfiguration(object) })
                            }

                            Item { Layout.fillWidth: true }

                            QGCButton {
                                primary:   true
                                text:      object.link ? qsTr("Disconnect") : qsTr("Connect")
                                onClicked: {
                                    if (object.link) {
                                        object.link.disconnect()
                                    } else {
                                        _linkManager.createConnectedLink(object)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        LabelledButton {
            label:      qsTr("Add New Link")
            buttonText: qsTr("Add")
            onClicked:  typeSelectionDialogComponent.createObject(mainWindow).open()
        }

        // Bottom Spacer
        Item {
            Layout.preferredHeight: 20
        }
    }

    // --- Dialog Components ---
    Component {
        id: typeSelectionDialogComponent
        QGCPopupDialog {
            id:                  typeDialog
            title:               qsTr("Select Link Type")
            buttons:             false
            closeOnClickOutside: true
            property int selectedType: -1

            ColumnLayout {
                spacing:          15
                Layout.fillWidth: true
                Repeater {
                    model: _linkManager.linkTypeStrings
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing:          20
                        Rectangle {
                            width:  25
                            height: 25
                            radius: width/2
                            color:  "#4a2c6d"
                            Text {
                                anchors.centerIn: parent
                                font.pixelSize:   14
                                color:            "white"
                                text:             index + 1
                            }
                        }
                        Text {
                            text:           modelData
                            font.pixelSize: 16
                            color:          "black"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    typeDialog.selectedType = index
                                    typeDialog.close()
                                    var editingConfig = _linkManager.createConfiguration(index, "")
                                    linkConfigDialogComponent.createObject(mainWindow, {
                                        editingConfig:  editingConfig,
                                        originalConfig: null,
                                        selectedType:   index
                                    }).open()
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    Component {
        id: linkConfigDialogComponent
        QGCPopupDialog {
            title:         selectedType === 3 ? qsTr("Bluetooth Devices") : (originalConfig ? qsTr("Edit Link") : qsTr("Add New Link"))
            buttons:       Dialog.Save | Dialog.Cancel
            acceptAllowed: nameField.text !== ""

            property var originalConfig
            property var editingConfig
            property int selectedType

            onAccepted: {
                linkSettingsLoader.item.saveSettings()
                editingConfig.devName = nameField.text
                editingConfig.name    = editingConfig.devName
                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                    _linkManager.createConnectedLink(editingConfig)
                }
            }
            onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

            ColumnLayout {
                spacing:          ScreenTools.defaultFontPixelHeight / 2
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    spacing:          ScreenTools.defaultFontPixelWidth
                    visible:          _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"
                    QGCLabel { text: qsTr("Name") }
                    QGCTextField {
                        id:               nameField
                        Layout.fillWidth: true
                        text:             editingConfig.devName
                        placeholderText:  qsTr("Enter name")
                    }
                }

                Loader {
                    id:               linkSettingsLoader
                    Layout.fillWidth: true
                    source:           subEditConfig.settingsURL
                    property var subEditConfig:       editingConfig
                    property int _firstColumnWidth:   ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:  ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:         ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:         ScreenTools.defaultFontPixelWidth / 2
                }
            }
        }
    }
}
