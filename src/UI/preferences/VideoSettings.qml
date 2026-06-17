/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
pragma ComponentBehavior: Bound
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools

SettingsPage {
    id: cameraSettingsPage

    property var    _settingsManager:        QGroundControl.settingsManager
    property var    _videoManager:           QGroundControl.videoManager
    property var    _videoSettings:          _settingsManager.videoSettings
    property var    _appSettings:            _settingsManager.appSettings
    property var    _activeVehicle:          QGroundControl.multiVehicleManager.activeVehicle
    property string _videoSource:            _videoSettings.videoSource.rawValue
    property bool   _isGST:                  _videoManager.gstreamerEnabled
    property bool   _isStreamSource:         _videoManager.isStreamSource
    property bool   _isUDP264:               _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:               _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                 _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                  _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:               _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:  _videoManager.autoStreamConfigured
    property bool   _requiresUDPPort:        _isUDP264 || _isUDP265 || _isMPEGTS
    property bool   _narrowLayout:           width < ScreenTools.defaultFontPixelWidth * 115
    property real   _pageMargin:             ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 3
    property real   _rowHeight:              ScreenTools.defaultFontPixelHeight * 2.6
    property real   _contentWidth:           Math.min(width - (_pageMargin * 2), ScreenTools.defaultFontPixelWidth * 190)
    property real   _labelWidth:             _narrowLayout ? _contentWidth : ScreenTools.defaultFontPixelWidth * 42
    property real   _controlWidth:           _narrowLayout ? _contentWidth : ScreenTools.defaultFontPixelWidth * 44
    property string _aspectFrameGuide:       aspectRatioLabel(_videoSettings.aspectRatio.rawValue)
    property string _gridTechnique:          QGroundControl.loadGlobalSetting("Camera.GridTechnique", "Grid Off")
    property bool   _gridTechniqueEnabled:   QGroundControl.loadGlobalSetting("Camera.GridTechniqueEnabled", "false") === "true"
    property string _codingFormat:           QGroundControl.loadGlobalSetting("Camera.CodingFormat", "H.264")
    property string _videoResolution:        QGroundControl.loadGlobalSetting("Camera.VideoResolution", "1080p")
    property string _frameRate:              QGroundControl.loadGlobalSetting("Camera.FrameRate", "30")
    property string _bitrateQuality:         QGroundControl.loadGlobalSetting("Camera.BitrateQuality", "Standard")
    property bool   _videoSubtitles:         QGroundControl.loadGlobalSetting("Camera.VideoSubtitles", "false") === "true"
    property bool   _cacheVideoRecording:    QGroundControl.loadGlobalSetting("Camera.CacheVideoRecording", "false") === "true"
    property bool   _watermarkMetadata:      QGroundControl.loadGlobalSetting("Camera.MetadataWatermark", "false") === "true"
    property string _storageTarget:          QGroundControl.loadGlobalSetting("Camera.StorageTarget", "SD Card")
    property int    _storageWarningLevel:    Number(QGroundControl.loadGlobalSetting("Camera.StorageWarningLevel", "80"))
    property string _cloudSyncStatus:        QGroundControl.loadGlobalSetting("Camera.CloudSyncStatus", "Pending")
    property string _missionShotPreset:      QGroundControl.loadGlobalSetting("Camera.MissionShotPreset", "inspection")
    property string _captureMode:            QGroundControl.loadGlobalSetting("Camera.CaptureMode", "single")
    property real   _digitalZoom:            Number(QGroundControl.loadGlobalSetting("Camera.DigitalZoom", "1.0"))
    property bool   _missionProofMode:       QGroundControl.loadGlobalSetting("Camera.MissionProofMode", "false") === "true"
    property bool   _compositionGrid:        QGroundControl.loadGlobalSetting("Camera.CompositionGrid", "false") === "true"
    property bool   _centerMark:             QGroundControl.loadGlobalSetting("Camera.CenterMark", "false") === "true"
    property bool   _safeFrame:              QGroundControl.loadGlobalSetting("Camera.SafeFrame", "false") === "true"
    property bool   _zebraOverlay:           QGroundControl.loadGlobalSetting("Camera.ZebraOverlay", "false") === "true"
    property bool   _histogramOverlay:       QGroundControl.loadGlobalSetting("Camera.HistogramOverlay", "false") === "true"
    property bool   _exposureWarnings:       QGroundControl.loadGlobalSetting("Camera.ExposureWarnings", "false") === "true"
    property bool   _focusPeaking:           QGroundControl.loadGlobalSetting("Camera.FocusPeaking", "false") === "true"
    property bool   _falseColor:             QGroundControl.loadGlobalSetting("Camera.FalseColor", "false") === "true"
    property int    _zebraLevel:             Number(QGroundControl.loadGlobalSetting("Camera.ZebraLevel", "85"))
    property int    _burstCount:             Number(QGroundControl.loadGlobalSetting("Camera.BurstCount", "5"))
    property int    _intervalSeconds:        Number(QGroundControl.loadGlobalSetting("Camera.IntervalSeconds", "5"))
    property int    _timerSeconds:           Number(QGroundControl.loadGlobalSetting("Camera.TimerSeconds", "3"))
    function aspectRatioValue(label) {
        if (label === qsTr("4:3")) {
            return 4 / 3
        }
        if (label === qsTr("1:1")) {
            return 1
        }
        return 16 / 9
    }

    function aspectRatioLabel(value) {
        var ratio = Number(value)
        if (Math.abs(ratio - (4 / 3)) < 0.01) {
            return qsTr("4:3")
        }
        if (Math.abs(ratio - 1) < 0.01) {
            return qsTr("1:1")
        }
        return qsTr("16:9")
    }

    function setAspectFrameGuide(value) {
        _aspectFrameGuide = value
        QGroundControl.saveGlobalSetting("Camera.AspectFrameGuide", value)
        _videoSettings.aspectRatio.rawValue = aspectRatioValue(value)
        _videoSettings.videoFit.rawValue = 1
    }

    function setGridTechnique(value) {
        _gridTechnique = value
        QGroundControl.saveGlobalSetting("Camera.GridTechnique", value)
        _gridTechniqueEnabled = value !== qsTr("Grid Off")
        QGroundControl.saveGlobalSetting("Camera.GridTechniqueEnabled", _gridTechniqueEnabled ? "true" : "false")
        _videoSettings.gridLines.rawValue = _gridTechniqueEnabled ? 1 : 0
    }

    function setGridTechniqueEnabled(enabled) {
        _gridTechniqueEnabled = enabled
        QGroundControl.saveGlobalSetting("Camera.GridTechniqueEnabled", enabled ? "true" : "false")
        if (enabled && _gridTechnique === qsTr("Grid Off")) {
            _gridTechnique = qsTr("Grid")
            QGroundControl.saveGlobalSetting("Camera.GridTechnique", _gridTechnique)
        }
        _videoSettings.gridLines.rawValue = enabled ? 1 : 0
    }

    function batteryPercent() {
        if (!_activeVehicle || !_activeVehicle.batteries || _activeVehicle.batteries.count === 0) {
            return NaN
        }
        var battery = _activeVehicle.batteries.get ? _activeVehicle.batteries.get(0) : _activeVehicle.batteries[0]
        return battery && battery.percentRemaining && !isNaN(battery.percentRemaining.rawValue) ? battery.percentRemaining.rawValue : NaN
    }

    function altitudeMeters() {
        if (_activeVehicle && _activeVehicle.altitudeRelative && !isNaN(_activeVehicle.altitudeRelative.rawValue)) {
            return _activeVehicle.altitudeRelative.rawValue
        }
        if (_activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid && !isNaN(_activeVehicle.coordinate.altitude)) {
            return _activeVehicle.coordinate.altitude
        }
        return NaN
    }

    function safetyLevel(key) {
        var battery = batteryPercent()
        var altitude = altitudeMeters()
        switch (key) {
        case "battery":
            return isNaN(battery) ? "warn" : (battery <= 20 ? "bad" : (battery <= 35 ? "warn" : "ok"))
        case "altitude":
            return isNaN(altitude) ? "warn" : (altitude < 15 ? "bad" : (altitude < 30 ? "warn" : "ok"))
        case "storage":
            return _videoSettings.enableStorageLimit.rawValue ? "ok" : "warn"
        case "return":
            return _activeVehicle ? "ok" : "warn"
        case "geofence":
            return _activeVehicle ? "ok" : "warn"
        case "wind":
            return "warn"
        default:
            return "warn"
        }
    }

    function safetyValue(key) {
        var battery = batteryPercent()
        var altitude = altitudeMeters()
        switch (key) {
        case "battery":
            return isNaN(battery) ? qsTr("--") : Math.round(battery) + "%"
        case "altitude":
            return isNaN(altitude) ? qsTr("--") : Math.round(altitude) + qsTr(" m")
        case "storage":
            return _videoSettings.enableStorageLimit.rawValue ? qsTr("OK") : qsTr("Check")
        case "return":
            return _activeVehicle ? qsTr("Home set") : qsTr("No vehicle")
        case "geofence":
            return _activeVehicle ? qsTr("Loaded") : qsTr("Unknown")
        case "wind":
            return qsTr("Check")
        default:
            return qsTr("--")
        }
    }

    function safetySummaryLabel() {
        var bad = 0
        var warn = 0
        var keys = [ "battery", "altitude", "storage", "return", "geofence", "wind" ]
        for (var i = 0; i < keys.length; i++) {
            var level = safetyLevel(keys[i])
            if (level === "bad") {
                bad++
            } else if (level === "warn") {
                warn++
            }
        }
        if (bad > 0) {
            return qsTr("Hold")
        }
        return warn > 0 ? qsTr("Review") : qsTr("Ready")
    }

    function safetySummaryLevel() {
        var summary = safetySummaryLabel()
        return summary === qsTr("Ready") ? "ok" : (summary === qsTr("Hold") ? "bad" : "warn")
    }

    function safetyColor(level) {
        return level === "ok" ? "#16A085" : (level === "bad" ? "#D92D20" : "#D9822B")
    }

    function recordingFormatName() {
        return _videoSettings.recordingFormat.rawValue === 1 ? "MOV" : (_videoSettings.recordingFormat.rawValue === 2 ? "MP4" : "MKV")
    }

    function setRecordingFormatName(formatName) {
        _videoSettings.recordingFormat.rawValue = formatName === "MOV" ? 1 : 2
    }

    function setCodingFormat(formatName) {
        _codingFormat = formatName
        QGroundControl.saveGlobalSetting("Camera.CodingFormat", formatName)
    }

    function setVideoResolution(resolutionName) {
        _videoResolution = resolutionName
        QGroundControl.saveGlobalSetting("Camera.VideoResolution", resolutionName)
    }

    function setFrameRate(frameRateName) {
        _frameRate = frameRateName
        QGroundControl.saveGlobalSetting("Camera.FrameRate", frameRateName)
    }

    function setBitrateQuality(qualityName) {
        _bitrateQuality = qualityName
        QGroundControl.saveGlobalSetting("Camera.BitrateQuality", qualityName)
    }

    function setVideoSubtitles(enabled) {
        _videoSubtitles = enabled
        QGroundControl.saveGlobalSetting("Camera.VideoSubtitles", enabled ? "true" : "false")
    }

    function setCacheVideoRecording(enabled) {
        _cacheVideoRecording = enabled
        QGroundControl.saveGlobalSetting("Camera.CacheVideoRecording", enabled ? "true" : "false")
    }

    function setWatermarkMetadata(enabled) {
        _watermarkMetadata = enabled
        QGroundControl.saveGlobalSetting("Camera.MetadataWatermark", enabled ? "true" : "false")
    }

    function setStorageTarget(targetName) {
        if (targetName === qsTr("Cloud")) {
            return
        }
        if (targetName === qsTr("SD Card")) {
            if (!_appSettings.androidSaveToSDCard.visible) {
                return
            }
            _appSettings.androidSaveToSDCard.rawValue = true
        } else if (_appSettings.androidSaveToSDCard.visible) {
            _appSettings.androidSaveToSDCard.rawValue = false
        }
        _storageTarget = targetName
        QGroundControl.saveGlobalSetting("Camera.StorageTarget", targetName)
    }

    function setStorageWarningLevel(level) {
        _storageWarningLevel = level
        QGroundControl.saveGlobalSetting("Camera.StorageWarningLevel", level.toString())
    }

    function setCloudSyncStatus(statusName) {
        _cloudSyncStatus = statusName
        QGroundControl.saveGlobalSetting("Camera.CloudSyncStatus", statusName)
    }

    function saveRecordingProfile() {
        QGroundControl.saveGlobalSetting("Camera.CodingFormat", _codingFormat)
        QGroundControl.saveGlobalSetting("Camera.VideoResolution", _videoResolution)
        QGroundControl.saveGlobalSetting("Camera.FrameRate", _frameRate)
        QGroundControl.saveGlobalSetting("Camera.BitrateQuality", _bitrateQuality)
        QGroundControl.saveGlobalSetting("Camera.VideoSubtitles", _videoSubtitles ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.CacheVideoRecording", _cacheVideoRecording ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.MetadataWatermark", _watermarkMetadata ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.StorageTarget", _storageTarget)
        QGroundControl.saveGlobalSetting("Camera.StorageWarningLevel", _storageWarningLevel.toString())
        QGroundControl.saveGlobalSetting("Camera.CloudSyncStatus", _cloudSyncStatus)
    }

    function resetRecordingProfile() {
        setRecordingFormatName("MP4")
        setCodingFormat("H.264")
        setVideoResolution("720p")
        setFrameRate("30")
        setBitrateQuality(qsTr("Standard"))
        setVideoSubtitles(false)
        setCacheVideoRecording(false)
        setWatermarkMetadata(false)
        setStorageTarget(qsTr("SD Card"))
        setStorageWarningLevel(80)
        setCloudSyncStatus(qsTr("Pending"))
        saveRecordingProfile()
    }

    function setFactRaw(fact, value) {
        if (fact) {
            fact.rawValue = value
        }
    }

    function applyCameraPreset(profile, brightness, contrast, saturation, sharpness, gamma) {
        setFactRaw(_videoSettings.cameraColorProfile, profile)
        setFactRaw(_videoSettings.cameraBrightness, brightness)
        setFactRaw(_videoSettings.cameraContrast, contrast)
        setFactRaw(_videoSettings.cameraSaturation, saturation)
        setFactRaw(_videoSettings.cameraSharpness, sharpness)
        setFactRaw(_videoSettings.cameraGamma, gamma)
    }

    function saveMissionShotSettings() {
        QGroundControl.saveGlobalSetting("Camera.MissionShotPreset", _missionShotPreset)
        QGroundControl.saveGlobalSetting("Camera.CaptureMode", _captureMode)
        QGroundControl.saveGlobalSetting("Camera.DigitalZoom", _digitalZoom.toString())
        QGroundControl.saveGlobalSetting("Camera.MissionProofMode", _missionProofMode ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.CenterMark", _centerMark ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.SafeFrame", _safeFrame ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.ZebraOverlay", _zebraOverlay ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.HistogramOverlay", _histogramOverlay ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.ExposureWarnings", _exposureWarnings ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.FocusPeaking", _focusPeaking ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.FalseColor", _falseColor ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.ZebraLevel", _zebraLevel.toString())
        QGroundControl.saveGlobalSetting("Camera.BurstCount", _burstCount.toString())
        QGroundControl.saveGlobalSetting("Camera.IntervalSeconds", _intervalSeconds.toString())
        QGroundControl.saveGlobalSetting("Camera.TimerSeconds", _timerSeconds.toString())
    }

    function setCaptureMode(mode) {
        _captureMode = mode
        QGroundControl.saveGlobalSetting("Camera.CaptureMode", mode)
    }

    function applyMissionShotPreset(preset) {
        _missionShotPreset = preset
        _histogramOverlay = false
        _exposureWarnings = false
        _zebraOverlay = false
        _focusPeaking = false
        _falseColor = false
        _missionProofMode = false
        _centerMark = true
        _safeFrame = false

        switch (preset) {
        case "inspection":
            _digitalZoom = 2.0
            _safeFrame = true
            _focusPeaking = true
            _zebraOverlay = true
            _zebraLevel = 90
            applyCameraPreset(2, 4, 24, 0, 28, 0.9)
            setCaptureMode("single")
            break
        case "cinematic":
            _digitalZoom = 1.2
            _safeFrame = false
            applyCameraPreset(1, -2, 10, 12, 8, 1.0)
            setCaptureMode("timer")
            _timerSeconds = 3
            break
        case "mapping":
            _digitalZoom = 1.0
            _safeFrame = true
            _centerMark = false
            applyCameraPreset(0, 0, 8, -4, 12, 1.0)
            setCaptureMode("interval")
            _intervalSeconds = 5
            break
        case "lowLight":
            _digitalZoom = 1.4
            _histogramOverlay = true
            _exposureWarnings = true
            applyCameraPreset(5, 14, 8, 4, 4, 1.3)
            setCaptureMode("single")
            break
        case "evidence":
            _digitalZoom = 1.0
            _safeFrame = true
            _centerMark = true
            _histogramOverlay = true
            _exposureWarnings = true
            _missionProofMode = true
            applyCameraPreset(4, 0, 24, 2, 20, 0.9)
            setCaptureMode("burst")
            _burstCount = 3
            break
        case "payloadProof":
            _digitalZoom = 1.0
            _safeFrame = true
            _centerMark = true
            _zebraOverlay = true
            _zebraLevel = 85
            _missionProofMode = true
            applyCameraPreset(4, 0, 28, 4, 18, 0.9)
            setCaptureMode("burst")
            _burstCount = 3
            break
        }

        saveMissionShotSettings()
    }

    function missionShotPresetTitle(preset) {
        switch (preset) {
        case "inspection":  return qsTr("Inspection")
        case "cinematic":   return qsTr("Cinematic")
        case "mapping":     return qsTr("Mapping")
        case "lowLight":    return qsTr("Low Light")
        case "evidence":    return qsTr("Evidence")
        case "payloadProof": return qsTr("Payload Proof")
        default:            return qsTr("None")
        }
    }

    function missionShotPresetSummary(preset) {
        switch (preset) {
        case "inspection":   return qsTr("2x zoom  |  Single capture  |  Detail enhancement")
        case "cinematic":    return qsTr("1.2x zoom  |  3-second timer  |  Soft color profile")
        case "mapping":      return qsTr("1x zoom  |  5-second interval  |  Clean overlays")
        case "lowLight":     return qsTr("1.4x zoom  |  Single capture  |  Exposure assistance")
        case "evidence":     return qsTr("1x zoom  |  3-shot burst  |  Proof metadata")
        case "payloadProof": return qsTr("1x zoom  |  3-shot burst  |  Safe framing")
        default:             return qsTr("Choose a preset to configure the camera")
        }
    }

    ColumnLayout {
        id: pageLayout
        width: _contentWidth
        spacing: ScreenTools.defaultFontPixelHeight * 1.2
        Layout.alignment: Qt.AlignHCenter

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: heroContent.implicitHeight + _pageMargin
            radius: 8
            color: "#10201D"

            RowLayout {
                id: heroContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: _pageMargin * 0.65
                spacing: ScreenTools.defaultFontPixelWidth * 1.4

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.2
                    Layout.preferredHeight: width
                    radius: width / 2
                    color: "#75E6DA"

                    QGCLabel {
                        anchors.centerIn: parent
                        text: qsTr("CAM")
                        color: "#10201D"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    QGCLabel {
                        Layout.fillWidth: true
                        text: qsTr("Camera Settings")
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.isMobile ? ScreenTools.mediumFontPointSize : ScreenTools.largeFontPointSize
                        elide: Text.ElideRight
                    }

                    QGCLabel {
                        Layout.fillWidth: true
                        text: _videoAutoStreamConfig ? qsTr("MAVLink camera stream is configured automatically.") : qsTr("Stream, decode, recording, and mission-video preferences.")
                        color: "#BEEBE7"
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: _narrowLayout ? 1 : 4
            columnSpacing: ScreenTools.defaultFontPixelWidth
            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.75

            Repeater {
                model: [
                    { label: qsTr("Source"), value: _videoSettings.videoSource.valueString, accent: "white" },
                    { label: qsTr("Stream"), value: _isStreamSource ? qsTr("Network stream") : qsTr("Inactive"), accent: _isStreamSource ? "#16A085" : "#D9822B" },
                    { label: qsTr("ISO"), value: _videoSettings.cameraIso.valueString, accent: "#10201D" },
                    { label: qsTr("Profile"), value: _videoSettings.cameraColorProfile.valueString, accent: "#16A085" }
                ]

                Rectangle {
                    id: summaryTile
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 4.2
                    radius: 8
                    color: "#F4F8F7"
                    border.color: "#D5DEE8"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelWidth
                        spacing: 2

                        QGCLabel {
                            Layout.fillWidth: true
                            text: summaryTile.modelData.label
                            color: "#60716C"
                            font.pointSize: ScreenTools.smallFontPointSize
                            elide: Text.ElideRight
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text: summaryTile.modelData.value
                            color: summaryTile.modelData.accent
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        CameraSection {
            title: qsTr("Stream Setup")
            subtitle: qsTr("Choose where the camera feed comes from and how QGC should connect.")
            iconSource: "qrc:/InstrumentValueIcons/video-camera.svg"

            CameraFactComboRow {
                label: qsTr("Video source")
                fact: _videoSettings.videoSource
                enabled: !_videoAutoStreamConfig
                visible: fact.visible
            }

            CameraFactSwitchRow {
                label: qsTr("Enable stream")
                description: qsTr("Start or stop the configured camera stream.")
                fact: _videoSettings.streamEnabled
                visible: !_videoAutoStreamConfig && _isStreamSource && fact.visible
            }

            CameraFactTextRow {
                label: qsTr("RTSP URL")
                placeholderText: qsTr("rtsp://192.168.42.1:554/live")
                fact: _videoSettings.rtspUrl
                visible: _isRTSP && _videoSettings.rtspUrl.visible
                enabled: !_videoAutoStreamConfig
            }

            CameraFactTextRow {
                label: qsTr("TCP URL")
                placeholderText: qsTr("192.168.143.200:3001")
                fact: _videoSettings.tcpUrl
                visible: _isTCP && _videoSettings.tcpUrl.visible
                enabled: !_videoAutoStreamConfig
            }

            CameraFactTextRow {
                label: qsTr("UDP port")
                placeholderText: qsTr("5600")
                fact: _videoSettings.udpPort
                visible: _requiresUDPPort && _videoSettings.udpPort.visible
                enabled: !_videoAutoStreamConfig
            }

            CameraFactTextRow {
                label: qsTr("RTSP timeout")
                placeholderText: qsTr("8")
                fact: _videoSettings.rtspTimeout
                visible: _isRTSP && _videoSettings.rtspTimeout.visible
                enabled: !_videoAutoStreamConfig
            }
        }

        CameraSection {
            title: qsTr("View & Decode")
            subtitle: qsTr("Tune the live video display for inspection, tracking, and low-latency flight work.")
            iconSource: "qrc:/InstrumentValueIcons/adjust.svg"

            CameraSegmentedRow {
                label: qsTr("Aspect ratio")
                description: qsTr("Choose the live video display shape.")
                options: [ qsTr("16:9"), qsTr("4:3"), qsTr("1:1") ]
                value: _aspectFrameGuide
                visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
                onValueSelected: function(selectedValue) { setAspectFrameGuide(selectedValue) }
            }

            CameraGridTechniqueRow {
                label: qsTr("Grid technique")
                description: qsTr("Choose the live camera reference overlay.")
                value: _gridTechnique
                gridEnabled: _gridTechniqueEnabled
                visible: !_videoAutoStreamConfig && _isStreamSource
                onValueSelected: function(selectedValue) { setGridTechnique(selectedValue) }
                onGridEnabledRequested: function(enabled) { setGridTechniqueEnabled(enabled) }
            }

            CameraFactComboRow {
                label: qsTr("Decoder priority")
                fact: _videoSettings.forceVideoDecoder
                visible: fact.visible
            }

            CameraFactSwitchRow {
                label: qsTr("Low latency mode")
                description: qsTr("Reduces video delay for live flight control.")
                fact: _videoSettings.lowLatencyMode
                visible: !_videoAutoStreamConfig && _isStreamSource && fact.visible && _isGST
            }

        }

        CameraSection {
            title: qsTr("Mission Shot Presets")
            subtitle: qsTr("Recall complete camera setups for repeatable mission shots.")
            iconSource: "qrc:/InstrumentValueIcons/target.svg"

            ColumnLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelHeight * 0.75

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCLabel {
                        Layout.fillWidth: true
                        text: qsTr("SHOT PROFILE")
                        color: "#10201D"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    QGCLabel {
                        text: qsTr("Tap to apply")
                        color: "#64748B"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: _narrowLayout ? 2 : 6
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 0.55
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.55

                    Repeater {
                        model: [
                            { title: qsTr("Inspection"), subtitle: qsTr("Detail"), preset: "inspection", icon: "qrc:/InstrumentValueIcons/target.svg" },
                            { title: qsTr("Cinematic"), subtitle: qsTr("Motion"), preset: "cinematic", icon: "qrc:/InstrumentValueIcons/film.svg" },
                            { title: qsTr("Mapping"), subtitle: qsTr("Interval"), preset: "mapping", icon: "qrc:/InstrumentValueIcons/map.svg" },
                            { title: qsTr("Low Light"), subtitle: qsTr("Assist"), preset: "lowLight", icon: "qrc:/InstrumentValueIcons/light-bulb.svg" },
                            { title: qsTr("Evidence"), subtitle: qsTr("Metadata"), preset: "evidence", icon: "qrc:/InstrumentValueIcons/shield.svg" },
                            { title: qsTr("Payload"), subtitle: qsTr("Proof"), preset: "payloadProof", icon: "qrc:/InstrumentValueIcons/save-disk.svg" }
                        ]

                        MissionShotPresetTile {
                            required property var modelData

                            title: modelData.title
                            subtitle: modelData.subtitle
                            iconSource: modelData.icon
                            active: _missionShotPreset === modelData.preset
                            onClicked: applyMissionShotPreset(modelData.preset)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.25
                    radius: 6
                    color: "#F0F7F6"
                    border.color: "#C5E6E0"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                        spacing: ScreenTools.defaultFontPixelWidth * 0.8

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.8
                            Layout.preferredHeight: width
                            radius: width / 2
                            color: "#159A88"

                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.5
                                height: width
                                source: "qrc:/InstrumentValueIcons/checkmark.svg"
                                color: "white"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            QGCLabel {
                                Layout.fillWidth: true
                                text: missionShotPresetTitle(_missionShotPreset)
                                color: "#0F5F57"
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            QGCLabel {
                                Layout.fillWidth: true
                                text: missionShotPresetSummary(_missionShotPreset)
                                color: "#526B67"
                                font.pointSize: ScreenTools.smallFontPointSize
                                elide: Text.ElideRight
                            }
                        }

                        QGCLabel {
                            text: qsTr("APPLIED")
                            color: "#0F766E"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                            visible: _missionShotPreset.length > 0
                        }
                    }
                }
            }
        }

        CameraSection {
            title: qsTr("Recording Profile")
            subtitle: qsTr("Set the video file format, quality, capture helpers, and storage workflow.")
            iconSource: "qrc:/InstrumentValueIcons/film.svg"

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                Item { Layout.fillWidth: true }

                RecordingActionButton {
                    label: qsTr("Reset to default")
                    iconSource: "qrc:/InstrumentValueIcons/refresh.svg"
                    accent: false
                    onClicked: resetRecordingProfile()
                }

                RecordingActionButton {
                    label: qsTr("Save Profile")
                    iconSource: "qrc:/InstrumentValueIcons/checkmark.svg"
                    accent: true
                    onClicked: saveRecordingProfile()
                }
            }

            RecordingProfileCard {
                title: qsTr("File Formats")
                iconSource: "qrc:/InstrumentValueIcons/video-camera.svg"

                RecordingOptionRow {
                    label: qsTr("Recording Format")
                    options: [ "MP4", "MOV" ]
                    value: recordingFormatName()
                    optionColumns: 2
                    onValueSelected: function(selectedValue) { setRecordingFormatName(selectedValue) }
                }

                RecordingOptionRow {
                    label: qsTr("Coding Format")
                    options: [ "H.264", "H.265" ]
                    value: _codingFormat
                    optionColumns: 2
                    onValueSelected: function(selectedValue) { setCodingFormat(selectedValue) }
                }
            }

            RecordingProfileCard {
                title: qsTr("Quality Settings")
                iconSource: "qrc:/InstrumentValueIcons/chart.svg"

                RecordingOptionRow {
                    label: qsTr("Resolution")
                    options: [ "720p", "1080p", "2K", "4K", "6K" ]
                    value: _videoResolution === "2.7K" ? "2K" : (_videoResolution === "5.1K" ? "6K" : _videoResolution)
                    optionColumns: _narrowLayout ? 2 : 5
                    onValueSelected: function(selectedValue) { setVideoResolution(selectedValue === "2K" ? "2.7K" : (selectedValue === "6K" ? "5.1K" : selectedValue)) }
                }

                RecordingOptionRow {
                    label: qsTr("Frame Rate (fps)")
                    options: [ "24", "30", "48", "60", "120" ]
                    value: _frameRate
                    optionColumns: _narrowLayout ? 3 : 5
                    onValueSelected: function(selectedValue) { setFrameRate(selectedValue) }
                }

                RecordingOptionRow {
                    label: qsTr("Bitrate Quality")
                    options: [ qsTr("Low"), qsTr("Standard"), qsTr("High"), qsTr("Max") ]
                    value: _bitrateQuality
                    optionColumns: _narrowLayout ? 2 : 4
                    onValueSelected: function(selectedValue) { setBitrateQuality(selectedValue) }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: _narrowLayout ? 1 : 2
                columnSpacing: ScreenTools.defaultFontPixelWidth * 1.2
                rowSpacing: ScreenTools.defaultFontPixelHeight
                readonly property real cardColumnWidth: _narrowLayout ? width : (width - columnSpacing) / 2

                RecordingProfileCard {
                    title: qsTr("Capture Helpers")
                    iconSource: "qrc:/InstrumentValueIcons/show-sidebar.svg"
                    Layout.fillWidth: true
                    Layout.preferredWidth: parent.cardColumnWidth

                    RecordingHelperRow {
                        label: qsTr("Video subtitles")
                        description: qsTr("Embed subtitles in the video file")
                        iconSource: "qrc:/InstrumentValueIcons/show-sidebar.svg"
                        checked: _videoSubtitles
                        onToggled: function(checkedValue) { setVideoSubtitles(checkedValue) }
                    }

                    RecordingHelperRow {
                        label: qsTr("Cache video recording")
                        description: qsTr("Store temporary video cache locally")
                        iconSource: "qrc:/InstrumentValueIcons/save-disk.svg"
                        checked: _cacheVideoRecording
                        onToggled: function(checkedValue) { setCacheVideoRecording(checkedValue) }
                    }

                    RecordingHelperRow {
                        label: qsTr("Metadata watermark")
                        description: qsTr("Add metadata watermark to video")
                        iconSource: "qrc:/InstrumentValueIcons/shield.svg"
                        checked: _watermarkMetadata
                        onToggled: function(checkedValue) { setWatermarkMetadata(checkedValue) }
                    }
                }

                RecordingProfileCard {
                    title: qsTr("Storage")
                    iconSource: "qrc:/InstrumentValueIcons/save-disk.svg"
                    Layout.fillWidth: true
                    Layout.preferredWidth: parent.cardColumnWidth

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: ScreenTools.defaultFontPixelWidth * 0.8

                        RecordingStorageTile {
                            label: qsTr("SD Card")
                            detail: _appSettings.androidSaveToSDCard.visible ? qsTr("Android storage") : qsTr("Not available")
                            iconSource: "qrc:/InstrumentValueIcons/save-disk.svg"
                            active: _appSettings.androidSaveToSDCard.visible && _appSettings.androidSaveToSDCard.rawValue
                            available: _appSettings.androidSaveToSDCard.visible
                            onClicked: setStorageTarget(qsTr("SD Card"))
                        }

                        RecordingStorageTile {
                            label: qsTr("Internal")
                            detail: qsTr("Local media folder")
                            iconSource: "qrc:/InstrumentValueIcons/mobile-devices.svg"
                            active: !_appSettings.androidSaveToSDCard.visible || !_appSettings.androidSaveToSDCard.rawValue
                            available: true
                            onClicked: setStorageTarget(qsTr("Internal"))
                        }

                        RecordingStorageTile {
                            label: qsTr("Cloud")
                            detail: qsTr("Not configured")
                            iconSource: "qrc:/InstrumentValueIcons/cloud.svg"
                            active: false
                            available: false
                            onClicked: setStorageTarget(qsTr("Cloud"))
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            QGCLabel {
                                Layout.fillWidth: true
                                text: qsTr("Storage Summary")
                                color: "#10201D"
                                font.bold: true
                            }

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.8
                                radius: 8
                                color: "#E6F7F4"

                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: _storageWarningLevel + "%"
                                    color: "#0F766E"
                                    font.bold: true
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 0.8
                            radius: height / 2
                            color: "#DDECE8"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.max(0.05, Math.min(1, _storageWarningLevel / 100.0))
                                radius: parent.radius
                                color: "#16A085"
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            text: qsTr("Recordings use the configured local QGC media folder.")
                            color: "#526B67"
                            font.pointSize: ScreenTools.smallFontPointSize
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: storageWarningLayout.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.6
                radius: 10
                color: "#FFF7E8"
                border.color: "#F6D9A8"
                border.width: 1

                RowLayout {
                    id: storageWarningLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: ScreenTools.defaultFontPixelWidth * 1.5
                    spacing: ScreenTools.defaultFontPixelWidth * 1.5

                    QGCColoredImage {
                        Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2
                        Layout.preferredHeight: width
                        source: "qrc:/InstrumentValueIcons/announcement.svg"
                        color: "#F59E0B"
                    }

                    QGCLabel {
                        text: qsTr("Warning threshold")
                        color: "#10201D"
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.1
                        radius: height / 2
                        color: "#FDE6C8"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0.05, Math.min(1, _storageWarningLevel / 100.0))
                            radius: parent.radius
                            color: "#F59E0B"

                            QGCLabel {
                                anchors.centerIn: parent
                                text: _storageWarningLevel + "%"
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }
                    }

                    QGCLabel {
                        text: qsTr("Warn at ") + _storageWarningLevel + "%"
                        color: "#475569"
                        font.bold: true
                    }
                }
            }
        }

        CameraSection {
            title: qsTr("Recording Behavior & Limits")
            subtitle: qsTr("Control mission recording behavior and keep local storage predictable.")
            iconSource: "qrc:/InstrumentValueIcons/save-disk.svg"

            CameraFactSwitchRow {
                label: qsTr("Show record control")
                description: qsTr("Display the recording control in the flight UI.")
                fact: _videoSettings.showRecControl
                visible: fact.visible
            }

            CameraFactSwitchRow {
                label: qsTr("Stop when disarmed")
                description: qsTr("Automatically stop recording when the vehicle is disarmed.")
                fact: _videoSettings.disableWhenDisarmed
                visible: !_videoAutoStreamConfig && _isStreamSource && fact.visible
            }

            CameraFactComboRow {
                label: qsTr("Record format")
                fact: _videoSettings.recordingFormat
                visible: fact.visible
            }

            CameraFactSwitchRow {
                label: qsTr("Auto-delete old recordings")
                description: qsTr("Remove older recordings when the storage limit is reached.")
                fact: _videoSettings.enableStorageLimit
                visible: fact.visible
            }

            CameraFactTextRow {
                label: qsTr("Storage limit")
                placeholderText: qsTr("10240")
                fact: _videoSettings.maxVideoSize
                visible: fact.visible
                enabled: _videoSettings.enableStorageLimit.rawValue
            }
        }

        CameraSection {
            title: qsTr("Shot Safety")
            subtitle: qsTr("Check before starting a camera mission.")
            iconSource: "qrc:/InstrumentValueIcons/checkmark-outline.svg"

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: safetyPanelLayout.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.1
                radius: 8
                color: "#F7FAF9"
                border.color: "#D5DEE8"
                border.width: 1

                GridLayout {
                    id: safetyPanelLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: ScreenTools.defaultFontPixelWidth
                    columns: _narrowLayout ? 1 : 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.7

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: _narrowLayout ? _contentWidth : ScreenTools.defaultFontPixelWidth * 42
                        Layout.preferredHeight: _narrowLayout ? ScreenTools.defaultFontPixelHeight * 5.2 : ScreenTools.defaultFontPixelHeight * 8.5
                        radius: 8
                        color: "#10201D"
                        border.color: safetyColor(safetySummaryLevel())
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: ScreenTools.defaultFontPixelWidth
                            spacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.2
                                Layout.preferredHeight: width
                                radius: width / 2
                                color: safetyColor(safetySummaryLevel())

                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: safetySummaryLevel() === "ok" ? qsTr("OK") : (safetySummaryLevel() === "bad" ? qsTr("!") : qsTr("?"))
                                    color: "white"
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text: qsTr("Mission readiness")
                                    color: "white"
                                    font.bold: true
                                    font.pointSize: ScreenTools.isMobile ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                                    elide: Text.ElideRight
                                }

                                QGCLabel {
                                    Layout.fillWidth: true
                                    text: qsTr("Review camera safety before capture or autonomous work.")
                                    color: "#BEEBE7"
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.2
                                radius: 8
                                color: Qt.rgba(1, 1, 1, 0.10)
                                border.color: Qt.rgba(1, 1, 1, 0.18)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                                    anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                                    QGCLabel {
                                        Layout.fillWidth: true
                                        text: qsTr("Current state")
                                        color: "#BEEBE7"
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }

                                    QGCLabel {
                                        text: safetySummaryLabel()
                                        color: safetyColor(safetySummaryLevel())
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: _narrowLayout ? _contentWidth : ScreenTools.defaultFontPixelWidth * 116
                        columns: _narrowLayout ? 1 : 3
                        columnSpacing: ScreenTools.defaultFontPixelWidth
                        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.65

                        Repeater {
                            model: [
                                { label: qsTr("Battery"), key: "battery", icon: "battery" },
                                { label: qsTr("Min Alt"), key: "altitude", icon: "altitude" },
                                { label: qsTr("Storage"), key: "storage", icon: "storage" },
                                { label: qsTr("Return"), key: "return", icon: "return" },
                                { label: qsTr("Geofence"), key: "geofence", icon: "geofence" },
                                { label: qsTr("Wind"), key: "wind", icon: "wind" }
                            ]

                            SafetyStatusTile {
                                id: safetyDelegate
                                required property var modelData

                                label: safetyDelegate.modelData.label
                                value: safetyValue(safetyDelegate.modelData.key)
                                level: safetyLevel(safetyDelegate.modelData.key)
                                iconKey: safetyDelegate.modelData.icon
                            }
                        }
                    }
                }
            }
        }

        CameraSection {
            title: qsTr("Mission Camera Tools")
            subtitle: qsTr("Quick checks before logistics, mapping, or inspection flights.")
            iconSource: "qrc:/InstrumentValueIcons/camera.svg"

            CameraInfoRow {
                label: qsTr("Preflight check")
                value: _isStreamSource ? qsTr("Source configured") : qsTr("Select a source")
                accent: _isStreamSource ? "#16A085" : "#D9822B"
            }

            CameraInfoRow {
                label: qsTr("Network reminder")
                value: qsTr("Use RTSP/TCP/UDP only when the camera and GCS are on the same link.")
                accent: "#10201D"
            }

            CameraInfoRow {
                label: qsTr("Recording reminder")
                value: qsTr("Confirm format and storage limit before starting a mission.")
                accent: "#10201D"
            }

            CameraInfoRow {
                label: qsTr("Camera-control note")
                value: qsTr("ISO, shutter, focus, and grading values are saved here; they can be sent to the camera when a supported MAVLink camera or custom API is connected.")
                accent: "#16A085"
            }
        }
    }

    component CameraSection: Rectangle {
        id: cameraSectionRoot
        default property alias sectionChildren: sectionBody.children
        property string title
        property string subtitle
        property string iconSource: "qrc:/InstrumentValueIcons/camera.svg"

        Layout.fillWidth: true
        Layout.preferredHeight: sectionLayout.implicitHeight + _pageMargin * 0.85
        radius: 8
        color: "#FFFFFF"
        border.color: "#D5DEE8"
        border.width: 1

        ColumnLayout {
            id: sectionLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: _pageMargin * 0.75
            spacing: ScreenTools.defaultFontPixelHeight * 0.8

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.8
                    Layout.preferredHeight: width
                    radius: 8
                    color: "#E6F7F4"

                    QGCColoredImage {
                        anchors.centerIn: parent
                        width: parent.width * 0.52
                        height: width
                        source: cameraSectionRoot.iconSource
                        color: "#16A085"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    QGCLabel {
                        Layout.fillWidth: true
                        text: title
                        color: "#10201D"
                        font.bold: true
                        font.pointSize: ScreenTools.isMobile ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                        elide: Text.ElideRight
                    }

                    QGCLabel {
                        Layout.fillWidth: true
                        text: subtitle
                        color: "#60716C"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#E7ECEA"
            }

            ColumnLayout {
                id: sectionBody
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelHeight * 0.75
            }
        }
    }

    component CameraBaseRow: GridLayout {
        property string label
        property string description

        columns: _narrowLayout ? 1 : 2
        columnSpacing: ScreenTools.defaultFontPixelWidth * 2
        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35
        Layout.fillWidth: true
        Layout.minimumHeight: _rowHeight

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: _labelWidth
            spacing: 1

            QGCLabel {
                Layout.fillWidth: true
                text: label
                color: "#10201D"
                font.bold: true
                wrapMode: Text.WordWrap
            }

            QGCLabel {
                Layout.fillWidth: true
                text: description
                color: "#697A75"
                font.pointSize: ScreenTools.smallFontPointSize
                wrapMode: Text.WordWrap
                visible: description !== ""
            }
        }
    }

    component CameraFactComboRow: CameraBaseRow {
        property Fact fact

        FactComboBox {
            fact: parent.fact
            indexModel: false
            sizeToContents: false
            Layout.fillWidth: true
            Layout.maximumWidth: _controlWidth
            Layout.preferredWidth: _controlWidth
            Layout.preferredHeight: _rowHeight
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            enabled: parent.enabled
        }
    }

    component CameraFactTextRow: CameraBaseRow {
        property Fact fact
        property string placeholderText

        FactTextField {
            fact: parent.fact
            placeholderText: parent.placeholderText
            Layout.fillWidth: true
            Layout.maximumWidth: _controlWidth
            Layout.preferredWidth: _controlWidth
            Layout.preferredHeight: _rowHeight
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            enabled: parent.enabled
        }
    }

    component CameraFactSwitchRow: CameraBaseRow {
        property Fact fact

        FactCheckBoxSlider {
            text: ""
            fact: parent.fact
            Layout.fillWidth: true
            Layout.maximumWidth: _controlWidth
            Layout.preferredWidth: _controlWidth
            Layout.preferredHeight: _rowHeight
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            enabled: parent.enabled
        }
    }

    component CameraInfoRow: CameraBaseRow {
        property string value
        property string accent: "#10201D"

        QGCLabel {
            Layout.fillWidth: true
            Layout.maximumWidth: _controlWidth
            Layout.preferredWidth: _controlWidth
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            text: value
            color: accent
            font.bold: true
            wrapMode: Text.WordWrap
        }
    }

    component SafetyStatusTile: Rectangle {
        id: safetyStatusTile
        property string label
        property string value
        property string level
        property string iconKey

        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 4.0
        radius: 8
        color: "#FFFFFF"
        border.color: level === "ok" ? "#BFE7DF" : (level === "bad" ? "#F3B8B8" : "#F4D29A")
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelWidth
            spacing: ScreenTools.defaultFontPixelWidth * 0.8

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.0
                Layout.preferredHeight: width
                radius: 7
                color: level === "ok" ? "#E6F7F4" : (level === "bad" ? "#FDECEC" : "#FFF7E6")

                SafetyMiniIcon {
                    anchors.centerIn: parent
                    width: parent.width * 0.58
                    height: width
                    iconKey: safetyStatusTile.iconKey
                    color: safetyColor(level)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                QGCLabel {
                    Layout.fillWidth: true
                    text: label
                    color: "#60716C"
                    font.pointSize: ScreenTools.smallFontPointSize
                    elide: Text.ElideRight
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: value
                    color: "#10201D"
                    font.bold: true
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.6
                radius: height / 2
                color: level === "ok" ? "#E6F7F4" : (level === "bad" ? "#FDECEC" : "#FFF7E6")

                QGCLabel {
                    anchors.centerIn: parent
                    text: level === "ok" ? qsTr("OK") : (level === "bad" ? qsTr("Hold") : qsTr("Check"))
                    color: safetyColor(level)
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }
        }
    }

    component SafetyMiniIcon: Item {
        property string iconKey
        property color color: "#16A085"

        Rectangle {
            visible: iconKey === "battery"
            anchors.centerIn: parent
            width: parent.width * 0.78
            height: parent.height * 0.42
            radius: 2
            color: "transparent"
            border.color: parent.color
            border.width: 2
        }

        Rectangle {
            visible: iconKey === "battery"
            x: parent.width * 0.82
            y: parent.height * 0.42
            width: parent.width * 0.08
            height: parent.height * 0.16
            radius: 1
            color: parent.color
        }

        Item {
            visible: iconKey === "altitude"
            anchors.fill: parent

            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; width: 2; height: parent.height * 0.72; color: parent.parent.color }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.12; width: parent.width * 0.38; height: 2; rotation: 45; color: parent.parent.color }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.12; width: parent.width * 0.38; height: 2; rotation: -45; color: parent.parent.color }
        }

        Item {
            visible: iconKey === "storage"
            anchors.fill: parent

            Rectangle { anchors.centerIn: parent; width: parent.width * 0.72; height: parent.height * 0.52; radius: 3; color: "transparent"; border.color: parent.parent.color; border.width: 2 }
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height * 0.28; width: parent.width * 0.36; height: 2; color: parent.parent.color }
        }

        Item {
            visible: iconKey === "return"
            anchors.fill: parent

            Rectangle { anchors.centerIn: parent; width: parent.width * 0.76; height: width; radius: width / 2; color: "transparent"; border.color: parent.parent.color; border.width: 2 }
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.42; height: 2; rotation: -35; color: parent.parent.color }
            Rectangle { x: parent.width * 0.52; y: parent.height * 0.32; width: parent.width * 0.22; height: 2; rotation: 25; color: parent.parent.color }
        }

        Item {
            visible: iconKey === "geofence"
            anchors.fill: parent

            Rectangle { anchors.centerIn: parent; width: parent.width * 0.76; height: width; radius: 4; color: "transparent"; border.color: parent.parent.color; border.width: 2 }
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.20; height: width; radius: width / 2; color: parent.parent.color }
        }

        Item {
            visible: iconKey === "wind"
            anchors.fill: parent

            Repeater {
                model: 3
                Rectangle {
                    required property int index

                    x: parent.width * 0.12
                    y: parent.height * (0.24 + index * 0.22)
                    width: parent.width * (0.72 - index * 0.12)
                    height: 2
                    radius: 1
                    color: parent.parent.color
                }
            }
        }
    }

    component CameraPresetGrid: ColumnLayout {
        id: presetGridRoot
        property string label
        property string description: ""
        property var options: []
        property string value
        property string valueLabel: ""
        property int presetColumns: 3
        signal valueSelected(string selectedValue)

        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelHeight * 0.45

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                QGCLabel {
                    Layout.fillWidth: true
                    text: presetGridRoot.label
                    color: "#10201D"
                    font.bold: true
                    elide: Text.ElideRight
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: presetGridRoot.description
                    color: "#697A75"
                    font.pointSize: ScreenTools.smallFontPointSize
                    visible: presetGridRoot.description.length > 0
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: presetGridRoot.valueLabel.length > 0
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.55
                radius: 7
                color: "#E6F7F4"

                QGCLabel {
                    anchors.centerIn: parent
                    text: presetGridRoot.valueLabel
                    color: "#0F766E"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: presetGridRoot.presetColumns
            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.7
            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.55

            Repeater {
                model: options

                Rectangle {
                    id: presetButton
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                    radius: 8
                    property bool active: presetGridRoot.value === presetButton.modelData
                    color: presetGridRoot.value === presetButton.modelData ? "#16A085" : "#F4F8F7"
                    border.color: presetGridRoot.value === presetButton.modelData ? "#16A085" : "#D5DEE8"
                    border.width: 1

                    QGCLabel {
                        anchors.centerIn: parent
                        width: parent.width - ScreenTools.defaultFontPixelWidth
                        text: presetButton.modelData
                        color: presetButton.active ? "white" : "#10201D"
                        font.bold: presetButton.active
                        font.pointSize: ScreenTools.smallFontPointSize
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: presetGridRoot.valueSelected(presetButton.modelData)
                    }
                }
            }
        }
    }

    component CameraSwitchList: ColumnLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelHeight * 0.45
    }

    component RecordingActionButton: Rectangle {
        id: recordingActionButtonRoot
        property string label
        property string iconSource
        property bool accent: false
        signal clicked()

        Layout.preferredWidth: Math.max(ScreenTools.defaultFontPixelWidth * 19, actionLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 5)
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.7
        radius: 8
        color: accent ? "#16A085" : "#F8FAFC"
        border.color: accent ? "#16A085" : "#CCD8E2"
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: ScreenTools.defaultFontPixelWidth * 0.8

            QGCColoredImage {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight
                Layout.preferredHeight: width
                source: recordingActionButtonRoot.iconSource
                color: recordingActionButtonRoot.accent ? "white" : "#60716C"
            }

            QGCLabel {
                id: actionLabel
                text: recordingActionButtonRoot.label
                color: recordingActionButtonRoot.accent ? "white" : "#475569"
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: recordingActionButtonRoot.clicked()
        }
    }

    component RecordingProfileCard: Rectangle {
        id: recordingProfileCardRoot
        default property alias cardChildren: cardBody.data
        property string title
        property string iconSource

        Layout.fillWidth: true
        Layout.preferredHeight: cardLayout.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.4
        radius: 10
        color: "#FFFFFF"
        border.color: "#D5DEE8"
        border.width: 1

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: ScreenTools.defaultFontPixelWidth * 1.4
            spacing: ScreenTools.defaultFontPixelHeight * 0.85

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.15
                    Layout.preferredHeight: width
                    radius: 8
                    color: "#E6F7F4"

                    QGCColoredImage {
                        anchors.centerIn: parent
                        width: parent.width * 0.56
                        height: width
                        source: recordingProfileCardRoot.iconSource
                        color: "#16A085"
                    }
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: recordingProfileCardRoot.title
                    color: "#10201D"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                id: cardBody
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelHeight * 0.65
            }
        }
    }

    component RecordingOptionRow: GridLayout {
        id: recordingOptionRowRoot
        property string label
        property var options: []
        property string value
        property int optionColumns: 2
        signal valueSelected(string selectedValue)

        columns: _narrowLayout ? 1 : 2
        columnSpacing: ScreenTools.defaultFontPixelWidth * 1.6
        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.45
        Layout.fillWidth: true
        Layout.minimumHeight: ScreenTools.defaultFontPixelHeight * 3.2

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: _labelWidth
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            spacing: ScreenTools.defaultFontPixelWidth * 0.65

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.75
                Layout.preferredHeight: width
                radius: 6
                color: "#EEF8F6"

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.56
                    height: width
                    source: "qrc:/InstrumentValueIcons/information-outline.svg"
                    color: "#16A085"
                }
            }

            QGCLabel {
                Layout.fillWidth: true
                text: recordingOptionRowRoot.label
                color: "#10201D"
                font.bold: true
                elide: Text.ElideRight
            }
        }

        Flow {
            id: recordingOptionFlow

            Layout.fillWidth: true
            Layout.maximumWidth: _narrowLayout ? 10000 : ScreenTools.defaultFontPixelWidth * (recordingOptionRowRoot.optionColumns <= 2 ? 56 : (recordingOptionRowRoot.optionColumns === 4 ? 78 : 96))
            Layout.preferredWidth: _narrowLayout ? 1 : ScreenTools.defaultFontPixelWidth * (recordingOptionRowRoot.optionColumns <= 2 ? 56 : (recordingOptionRowRoot.optionColumns === 4 ? 78 : 96))
            Layout.preferredHeight: implicitHeight
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            spacing: ScreenTools.defaultFontPixelWidth * 0.75

            property real optionButtonWidth: Math.max(ScreenTools.defaultFontPixelWidth * 12,
                                                      (width - Math.max(0, recordingOptionRowRoot.optionColumns - 1) * spacing) /
                                                      Math.max(1, recordingOptionRowRoot.optionColumns))

            Repeater {
                model: recordingOptionRowRoot.options

                Rectangle {
                    id: recordingOptionButton
                    required property string modelData

                    width: recordingOptionFlow.optionButtonWidth
                    height: ScreenTools.defaultFontPixelHeight * 2.55
                    radius: 8
                    property bool active: recordingOptionRowRoot.value === recordingOptionButton.modelData
                    color: active ? "#16A085" : "#F8FAFC"
                    border.color: active ? "#16A085" : "#CCD8E2"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                        spacing: ScreenTools.defaultFontPixelWidth * 0.6

                        QGCLabel {
                            Layout.fillWidth: true
                            text: recordingOptionButton.modelData
                            color: recordingOptionButton.active ? "white" : "#10201D"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.25
                            Layout.preferredHeight: width
                            radius: width / 2
                            visible: recordingOptionButton.active
                            color: "white"

                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.58
                                height: width
                                source: "qrc:/InstrumentValueIcons/checkmark.svg"
                                color: "#16A085"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: recordingOptionRowRoot.valueSelected(recordingOptionButton.modelData)
                    }
                }
            }
        }
    }

    component RecordingHelperRow: Rectangle {
        id: recordingHelperRowRoot
        property string label
        property string description
        property string iconSource
        property bool checked
        signal toggled(bool checkedValue)

        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 4.1
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: ScreenTools.defaultFontPixelWidth * 1.1

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.4
                Layout.preferredHeight: width
                radius: 8
                color: "#E6F7F4"

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.55
                    height: width
                    source: recordingHelperRowRoot.iconSource
                    color: "#16A085"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                QGCLabel {
                    Layout.fillWidth: true
                    text: recordingHelperRowRoot.label
                    color: "#10201D"
                    font.bold: true
                    elide: Text.ElideRight
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: recordingHelperRowRoot.description
                    color: "#475569"
                    font.pointSize: ScreenTools.smallFontPointSize
                    elide: Text.ElideRight
                }
            }

            Switch {
                checked: recordingHelperRowRoot.checked
                text: ""
                onToggled: recordingHelperRowRoot.toggled(checked)
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: "#E7ECEA"
        }
    }

    component RecordingStorageTile: Rectangle {
        id: recordingStorageTileRoot
        property string label
        property string detail: ""
        property string iconSource
        property bool active: false
        property bool available: true
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 5.0
        radius: 8
        color: active ? "#E6F7F4" : "#F8FAFC"
        border.color: active ? "#16A085" : "#CCD8E2"
        border.width: 1
        opacity: available ? 1 : 0.55

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - ScreenTools.defaultFontPixelWidth
            spacing: ScreenTools.defaultFontPixelHeight * 0.35

            QGCColoredImage {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.7
                Layout.preferredHeight: width
                source: recordingStorageTileRoot.iconSource
                color: recordingStorageTileRoot.active ? "#16A085" : "#64748B"
            }

            QGCLabel {
                Layout.fillWidth: true
                text: recordingStorageTileRoot.label
                color: recordingStorageTileRoot.active ? "#0F766E" : "#334155"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            QGCLabel {
                Layout.fillWidth: true
                text: recordingStorageTileRoot.detail
                color: recordingStorageTileRoot.active ? "#0F766E" : "#64748B"
                font.pointSize: ScreenTools.smallFontPointSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: ScreenTools.defaultFontPixelWidth * 0.7
            width: ScreenTools.defaultFontPixelHeight * 1.35
            height: width
            radius: width / 2
            color: "#16A085"
            visible: active

            QGCColoredImage {
                anchors.centerIn: parent
                width: parent.width * 0.55
                height: width
                source: "qrc:/InstrumentValueIcons/checkmark.svg"
                color: "white"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: recordingStorageTileRoot.available
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: recordingStorageTileRoot.clicked()
        }
    }

    component MissionShotPresetTile: Rectangle {
        id: missionShotPresetTileRoot
        property string title
        property string subtitle
        property string iconSource
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 5.4
        radius: 6
        color: active ? "#11786D" : (missionPresetMouse.containsMouse ? "#F0F8F6" : "#F8FAFC")
        border.color: active ? "#11786D" : (missionPresetMouse.containsMouse ? "#79C9BC" : "#D5DEE8")
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 3
            color: active ? "#75E6DA" : "transparent"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.65
            spacing: ScreenTools.defaultFontPixelHeight * 0.25

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.1
                Layout.preferredHeight: width
                radius: 6
                color: active ? Qt.rgba(1, 1, 1, 0.15) : "#E3F5F1"

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.52
                    height: width
                    source: missionShotPresetTileRoot.iconSource
                    color: active ? "white" : "#149A88"
                }
            }

            QGCLabel {
                Layout.fillWidth: true
                text: missionShotPresetTileRoot.title
                color: active ? "white" : "#10201D"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            QGCLabel {
                Layout.fillWidth: true
                text: missionShotPresetTileRoot.subtitle
                color: active ? Qt.rgba(1, 1, 1, 0.72) : "#64748B"
                font.pointSize: ScreenTools.smallFontPointSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            width: ScreenTools.defaultFontPixelHeight * 1.15
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.18)
            visible: active

            QGCColoredImage {
                anchors.centerIn: parent
                width: parent.width * 0.52
                height: width
                source: "qrc:/InstrumentValueIcons/checkmark.svg"
                color: "white"
            }
        }

        MouseArea {
            id: missionPresetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: missionShotPresetTileRoot.clicked()
        }
    }

    component CameraToggleRow: Rectangle {
        id: cameraToggleRowRoot
        property string label
        property string description: ""
        property bool checked
        signal toggled(bool checkedValue)

        Layout.fillWidth: true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.0
        radius: 8
        color: "#F7FAF9"
        border.color: "#D5DEE8"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 1.1
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 1.1
            spacing: ScreenTools.defaultFontPixelWidth

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                QGCLabel {
                    Layout.fillWidth: true
                    text: cameraToggleRowRoot.label
                    color: "#10201D"
                    font.bold: true
                    elide: Text.ElideRight
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: cameraToggleRowRoot.checked ? qsTr("Enabled") : qsTr("Disabled")
                    color: cameraToggleRowRoot.checked ? "#0F766E" : "#697A75"
                    font.pointSize: ScreenTools.smallFontPointSize
                    elide: Text.ElideRight
                }
            }

            Switch {
                checked: cameraToggleRowRoot.checked
                text: ""
                onToggled: cameraToggleRowRoot.toggled(checked)
            }
        }
    }

    component CameraSegmentedRow: GridLayout {
        id: segmentedRowRoot
        property string label
        property string description: ""
        property var options: []
        property string value
        signal valueSelected(string selectedValue)

        columns: _narrowLayout ? 1 : 2
        columnSpacing: ScreenTools.defaultFontPixelWidth * 2
        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35
        Layout.fillWidth: true
        Layout.minimumHeight: _rowHeight * 1.35

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: _labelWidth
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            spacing: 1

            QGCLabel {
                Layout.fillWidth: true
                text: segmentedRowRoot.label
                color: "#10201D"
                font.bold: true
                elide: Text.ElideRight
            }

            QGCLabel {
                Layout.fillWidth: true
                text: segmentedRowRoot.description
                color: "#697A75"
                font.pointSize: ScreenTools.smallFontPointSize
                visible: segmentedRowRoot.description.length > 0
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: segmentedControl
            Layout.fillWidth: true
            Layout.maximumWidth: _narrowLayout ? 10000 : ScreenTools.defaultFontPixelWidth * 64
            Layout.preferredWidth: _narrowLayout ? 1 : ScreenTools.defaultFontPixelWidth * 64
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            spacing: ScreenTools.defaultFontPixelWidth * 0.5

            Repeater {
                model: options

                Rectangle {
                    id: segmentedButton
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                    radius: 8
                    color: segmentedRowRoot.value === segmentedButton.modelData ? "#16A085" : "#F4F8F7"
                    border.color: segmentedRowRoot.value === segmentedButton.modelData ? "#16A085" : "#D5DEE8"
                    border.width: 1

                    QGCLabel {
                        anchors.centerIn: parent
                        width: parent.width - ScreenTools.defaultFontPixelWidth
                        text: segmentedButton.modelData
                        color: segmentedRowRoot.value === segmentedButton.modelData ? "white" : "#10201D"
                        font.bold: segmentedRowRoot.value === segmentedButton.modelData
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: segmentedRowRoot.valueSelected(segmentedButton.modelData)
                    }
                }
            }
        }
    }

    component CameraGridTechniqueRow: GridLayout {
        id: gridTechniqueRowRoot
        property string label
        property string description: ""
        property string value
        property bool gridEnabled: false
        signal valueSelected(string selectedValue)
        signal gridEnabledRequested(bool enabled)

        columns: _narrowLayout ? 1 : 2
        columnSpacing: ScreenTools.defaultFontPixelWidth * 2
        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35
        Layout.fillWidth: true
        Layout.minimumHeight: gridEnabled ? ScreenTools.defaultFontPixelHeight * 8.0 : _rowHeight * 1.35

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: _labelWidth
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            spacing: 1

            QGCLabel {
                Layout.fillWidth: true
                text: gridTechniqueRowRoot.label
                color: "#10201D"
                font.bold: true
                elide: Text.ElideRight
            }

            QGCLabel {
                Layout.fillWidth: true
                text: gridTechniqueRowRoot.description
                color: "#697A75"
                font.pointSize: ScreenTools.smallFontPointSize
                visible: gridTechniqueRowRoot.description.length > 0
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: _narrowLayout ? 10000 : ScreenTools.defaultFontPixelWidth * 64
            Layout.preferredWidth: _narrowLayout ? 1 : ScreenTools.defaultFontPixelWidth * 64
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            radius: 8
            visible: !gridEnabled
            color: "#16A085"
            border.color: "#16A085"
            border.width: 1

            QGCLabel {
                anchors.centerIn: parent
                text: qsTr("Enable")
                color: "white"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: gridEnabledRequested(true)
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: _narrowLayout ? 10000 : ScreenTools.defaultFontPixelWidth * 64
            Layout.preferredWidth: _narrowLayout ? 1 : ScreenTools.defaultFontPixelWidth * 64
            Layout.alignment: _narrowLayout ? Qt.AlignLeft : Qt.AlignRight
            visible: gridEnabled
            columns: 3
            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.5
            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.45

            Repeater {
                model: [
                    qsTr("Grid"),
                    qsTr("X"),
                    qsTr("Point"),
                    qsTr("Square"),
                    qsTr("Grid Off"),
                    qsTr("Reticle"),
                    qsTr("Frame"),
                    qsTr("Zebra"),
                    qsTr("False")
                ]

                Rectangle {
                    id: gridTechniqueButton
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                    radius: 8
                    color: gridTechniqueRowRoot.value === gridTechniqueButton.modelData ? "#16A085" : "#F4F8F7"
                    border.color: gridTechniqueRowRoot.value === gridTechniqueButton.modelData ? "#16A085" : "#D5DEE8"
                    border.width: 1
                    property bool active: gridTechniqueRowRoot.value === gridTechniqueButton.modelData
                    property color iconColor: active ? "white" : "#10201D"

                    Item {
                        id: techniqueIcon
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) * 0.58
                        height: width

                        Item {
                            anchors.fill: parent
                            visible: gridTechniqueButton.modelData === qsTr("Grid") || gridTechniqueButton.modelData === qsTr("Grid Off")

                            Rectangle { x: parent.width / 3; width: 1; height: parent.height; color: gridTechniqueButton.iconColor; opacity: 0.95 }
                            Rectangle { x: parent.width * 2 / 3; width: 1; height: parent.height; color: gridTechniqueButton.iconColor; opacity: 0.95 }
                            Rectangle { y: parent.height / 3; width: parent.width; height: 1; color: gridTechniqueButton.iconColor; opacity: 0.95 }
                            Rectangle { y: parent.height * 2 / 3; width: parent.width; height: 1; color: gridTechniqueButton.iconColor; opacity: 0.95 }
                        }

                        Item {
                            anchors.fill: parent
                            visible: gridTechniqueButton.modelData === qsTr("X")

                            Rectangle { anchors.centerIn: parent; width: parent.width * 1.35; height: 2; radius: 1; rotation: 45; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.centerIn: parent; width: parent.width * 1.35; height: 2; radius: 1; rotation: -45; color: gridTechniqueButton.iconColor }
                        }

                        Grid {
                            anchors.centerIn: parent
                            columns: 3
                            rows: 3
                            spacing: parent.width * 0.18
                            visible: gridTechniqueButton.modelData === qsTr("Point")

                            Repeater {
                                model: 9
                                Rectangle {
                                    width: techniqueIcon.width * 0.12
                                    height: width
                                    radius: width / 2
                                    color: gridTechniqueButton.iconColor
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: gridTechniqueButton.modelData === qsTr("Square")

                            Rectangle { anchors.centerIn: parent; width: parent.width * 0.86; height: width; color: "transparent"; border.color: gridTechniqueButton.iconColor; border.width: 2; radius: 2 }
                            Rectangle { anchors.centerIn: parent; width: parent.width * 0.46; height: width; color: "transparent"; border.color: gridTechniqueButton.iconColor; border.width: 2; radius: 2 }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 1.34
                            height: 2
                            radius: 1
                            rotation: -45
                            color: gridTechniqueButton.iconColor
                            visible: gridTechniqueButton.modelData === qsTr("Grid Off")
                        }

                        Item {
                            anchors.fill: parent
                            visible: gridTechniqueButton.modelData === qsTr("Reticle")

                            Rectangle { anchors.centerIn: parent; width: parent.width; height: 2; radius: 1; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.centerIn: parent; width: 2; height: parent.height; radius: 1; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.centerIn: parent; width: parent.width * 0.55; height: width; radius: width / 2; color: "transparent"; border.color: gridTechniqueButton.iconColor; border.width: 2 }
                        }

                        Item {
                            anchors.fill: parent
                            visible: gridTechniqueButton.modelData === qsTr("Frame")

                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; width: parent.width * 0.36; height: 2; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; width: 2; height: parent.height * 0.36; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.right: parent.right; anchors.top: parent.top; width: parent.width * 0.36; height: 2; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.right: parent.right; anchors.top: parent.top; width: 2; height: parent.height * 0.36; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: parent.width * 0.36; height: 2; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: 2; height: parent.height * 0.36; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; width: parent.width * 0.36; height: 2; color: gridTechniqueButton.iconColor }
                            Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; width: 2; height: parent.height * 0.36; color: gridTechniqueButton.iconColor }
                        }

                        Item {
                            anchors.fill: parent
                            clip: true
                            visible: gridTechniqueButton.modelData === qsTr("Zebra")

                            Repeater {
                                model: 5
                                Rectangle {
                                    required property int index

                                    x: index * techniqueIcon.width * 0.23 - techniqueIcon.width * 0.15
                                    y: -techniqueIcon.height * 0.1
                                    width: 2
                                    height: techniqueIcon.height * 1.2
                                    rotation: 28
                                    color: gridTechniqueButton.iconColor
                                }
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: parent.width * 0.07
                            visible: gridTechniqueButton.modelData === qsTr("False")

                            Repeater {
                                model: [ "#2DD4BF", "#F59E0B", "#EF4444" ]
                                Rectangle {
                                    required property string modelData
                                    required property int index

                                    property string falseColorSwatch: modelData
                                    width: techniqueIcon.width * 0.2
                                    height: techniqueIcon.height * 0.76
                                    radius: 2
                                    color: gridTechniqueButton.active ? "white" : falseColorSwatch
                                    opacity: gridTechniqueButton.active ? (0.55 + index * 0.18) : 1
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: gridTechniqueMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (gridTechniqueButton.modelData === qsTr("Grid Off")) {
                                gridTechniqueRowRoot.gridEnabledRequested(false)
                            } else {
                                gridTechniqueRowRoot.valueSelected(gridTechniqueButton.modelData)
                            }
                        }
                    }

                    ToolTip.visible: gridTechniqueMouse.containsMouse
                    ToolTip.text: gridTechniqueButton.modelData
                }
            }
        }
    }
}
