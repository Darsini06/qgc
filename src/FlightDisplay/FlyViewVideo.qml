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
import QtQuick.Effects
import QtQuick.Layouts
import QtMultimedia

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

Item {
    id: _root

    property Item pipView
    property Item pipState: videoPipState
    property bool aiDetectionEnabled: QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "AI"
    property bool aiAutoCaptureEnabled: false
    property bool aiPersonVehicleOnly: true
    property int  aiAutoCaptureCooldownSeconds: 10
    property double _aiLastCaptureMs: 0
    property string _aiLastDetectionLabel: qsTr("None")
    property var  _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var  _cameraManager: _activeVehicle ? _activeVehicle.cameraManager : null
    property var  _camera: _cameraManager ? _cameraManager.currentCameraInstance : null
    property var  _gimbalController: _activeVehicle ? _activeVehicle.gimbalController : null
    property var  _activeGimbal: _gimbalController ? _gimbalController.activeGimbal : null
    property var  _videoSettings: QGroundControl.settingsManager.videoSettings
    property var  _appSettings: QGroundControl.settingsManager.appSettings
    property bool _hasCameraControl: _camera && (_camera.capturesVideo || _camera.capturesPhotos)
    property bool _cameraInPhotoMode: _hasCameraControl && _camera.cameraMode === MavlinkCameraControl.CAM_MODE_PHOTO
    property bool _cameraInVideoMode: _hasCameraControl && !_cameraInPhotoMode
    property bool _videoCaptureIdle: !_hasCameraControl || _camera.videoCaptureStatus === MavlinkCameraControl.VIDEO_CAPTURE_STATUS_STOPPED
    property bool _photoCaptureBusy: _hasCameraControl && _camera.photoCaptureStatus === MavlinkCameraControl.PHOTO_CAPTURE_IN_PROGRESS
    property bool _cameraAppMode: QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Camera" ||
                                  QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "AI"
    property bool _videoIsFull: pipState.state === pipState.fullState
    property bool _showCameraStudio: _cameraAppMode && _root.visible && _videoIsFull
    property bool _uvcRecording: cameraLoader.item && cameraLoader.item.recording
    property bool _uvcPaused: cameraLoader.item && cameraLoader.item.paused
    property bool _localRecording: QGroundControl.videoManager.recording || _uvcRecording
    property bool _recordingPaused: _uvcPaused
    property bool _studioPanelOpen: false
    property string _subjectLockMode: "none"
    property bool _sectionCaptureOpen: true
    property bool _sectionLookOpen: true
    property bool _sectionExposureOpen: true
    property bool _sectionFocusOpen: false
    property bool _sectionStorageOpen: false
    property bool _sectionGimbalOpen: true
    property bool _sectionDebugOpen: false
    property string _savedProfileName: ""
    property bool _isoManual: false
    property bool _shutterManual: false
    property bool _whiteManual: false
    property bool _focusManual: false
    property bool _libraryOpen: false
    property bool _missionProofMode: QGroundControl.loadGlobalSetting("Camera.MissionProofMode", "false") === "true"
    property string _missionShotPreset: QGroundControl.loadGlobalSetting("Camera.MissionShotPreset", "")
    property string _missionShotSignature: ""
    property string _gridTechniqueSetting: ""
    property string _missionName: QGroundControl.loadGlobalSetting("loadpage", "loadpage")
    property bool _compositionGrid: QGroundControl.loadGlobalSetting("Camera.CompositionGrid", "false") === "true"
    property bool _centerMark: QGroundControl.loadGlobalSetting("Camera.CenterMark", "false") === "true"
    property bool _safeFrame: QGroundControl.loadGlobalSetting("Camera.SafeFrame", "false") === "true"
    property bool _zebraOverlay: QGroundControl.loadGlobalSetting("Camera.ZebraOverlay", "false") === "true"
    property bool _histogramOverlay: QGroundControl.loadGlobalSetting("Camera.HistogramOverlay", "false") === "true"
    property bool _exposureWarnings: QGroundControl.loadGlobalSetting("Camera.ExposureWarnings", "false") === "true"
    property string _codingFormat: QGroundControl.loadGlobalSetting("Camera.CodingFormat", "H.264")
    property string _videoResolution: QGroundControl.loadGlobalSetting("Camera.VideoResolution", "1080p")
    property string _frameRate: QGroundControl.loadGlobalSetting("Camera.FrameRate", "30")
    property string _bitrateQuality: QGroundControl.loadGlobalSetting("Camera.BitrateQuality", "Standard")
    property string _shutterMode: _shutterModeLabel(_videoSettings.cameraShutter.rawValue)
    property real _evCompensation: Number(_videoSettings.cameraExposure.rawValue)
    property string _isoLimit: _isoLimitLabel(_videoSettings.cameraIso.rawValue)
    property string _focusModeSetting: "Auto"
    property bool _gimbalHorizonLock: false
    property bool _autoProofCapture: false
    property int _storageWarningLevel: Number(QGroundControl.loadGlobalSetting("Camera.StorageWarningLevel", "80"))
    property string _cloudSyncStatus: QGroundControl.loadGlobalSetting("Camera.CloudSyncStatus", "Pending")
    property string _lastMediaTag: ""
    property bool _watermarkMetadata: QGroundControl.loadGlobalSetting("Camera.MetadataWatermark", "false") === "true"
    property bool _videoSubtitles: QGroundControl.loadGlobalSetting("Camera.VideoSubtitles", "false") === "true"
    property string _peakingLevel: "OFF"
    property string _gridStyle: "X"
    property bool _frameGuide: false
    property string _storageTarget: QGroundControl.loadGlobalSetting("Camera.StorageTarget", "SD Card")
    property bool _cacheVideoRecording: QGroundControl.loadGlobalSetting("Camera.CacheVideoRecording", "false") === "true"
    property int  _zebraLevel: Number(QGroundControl.loadGlobalSetting("Camera.ZebraLevel", "85"))
    property bool _focusPeaking: QGroundControl.loadGlobalSetting("Camera.FocusPeaking", "false") === "true"
    property bool _falseColor: QGroundControl.loadGlobalSetting("Camera.FalseColor", "false") === "true"
    property bool _tapFocusEnabled: true
    property bool _tapTrackEnabled: true
    property bool _tapFocusVisible: false
    property real _tapFocusX: 0
    property real _tapFocusY: 0
    property string _captureMode: QGroundControl.loadGlobalSetting("Camera.CaptureMode", "single")
    property int  _burstCount: Number(QGroundControl.loadGlobalSetting("Camera.BurstCount", "5"))
    property int  _burstRemaining: 0
    property bool _intervalActive: false
    property int  _intervalSeconds: Number(QGroundControl.loadGlobalSetting("Camera.IntervalSeconds", "5"))
    property int  _timerSeconds: Number(QGroundControl.loadGlobalSetting("Camera.TimerSeconds", "3"))
    property int  _timerRemaining: 0
    property int  _panoramaRemaining: 0
    property bool _orbitShotArmed: false
    property real _gimbalSpeed: 5.0
    property int  _mediaReviewIndex: -1
    property int  _pendingExportIndex: -1
    property real _mediaStorageBytes: 0
    property real _saveStorageBytesAvailable: -1
    property real _saveStorageBytesTotal: -1
    property bool _saveStorageWritable: false
    property string _lastCameraCommand: qsTr("No command yet")
    property string _lastCameraBackend: qsTr("Idle")
    property string _lastProofPackagePath: ""
    property int  _recordingHealthTick: 0
    property bool _photoCaptureGuard: false
    property bool _recordingActive: !_videoCaptureIdle || _localRecording
    property real _cameraDockUnit: Math.max(14, Math.min(ScreenTools.defaultFontPixelHeight, 18))
    property real _cameraDockSmallPointSize: Math.min(ScreenTools.smallFontPointSize, 9)
    property real _cameraDockDefaultPointSize: Math.min(ScreenTools.defaultFontPointSize, 10)
    property real _cameraDockButtonSize: _cameraDockUnit * 3.4
    property real _cameraDockIconSize: _cameraDockButtonSize * 0.48
    property color _cameraDockIconColor: "white"
    property color _cameraDockButtonColor: Qt.rgba(1, 1, 1, 0.12)
    property color _cameraDockButtonHoverColor: Qt.rgba(1, 1, 1, 0.20)
    property color _cameraDockButtonActiveBorderColor: "#75E6DA"
    property string _obstacleAvoidanceAction: QGroundControl.loadGlobalSetting("Safety.ObstacleAvoidanceAction", "Bypass")
    property bool _obstacleAvoidanceEnabled: _obstacleAvoidanceAction !== "OFF"
    property real _obstacleDangerDistance: 2.0
    property real _obstacleCautionDistance: 5.0
    property real _nearestObstacleDistance: _calculateNearestObstacleDistance()
    property real _frontObstacleDistance: _minimumObstacleDistance([7, 0, 1])
    property real _rightObstacleDistance: _minimumObstacleDistance([1, 2, 3])
    property real _rearObstacleDistance: _minimumObstacleDistance([3, 4, 5])
    property real _leftObstacleDistance: _minimumObstacleDistance([5, 6, 7])
    property string _nearestObstacleDirection: _calculateNearestObstacleDirection()
    property bool _obstacleWarningActive: _obstacleLevelForDistance(_frontObstacleDistance) === "danger" ||
                                          _obstacleLevelForDistance(_frontObstacleDistance) === "caution" ||
                                          _obstacleLevelForDistance(_rightObstacleDistance) === "danger" ||
                                          _obstacleLevelForDistance(_rightObstacleDistance) === "caution" ||
                                          _obstacleLevelForDistance(_rearObstacleDistance) === "danger" ||
                                          _obstacleLevelForDistance(_rearObstacleDistance) === "caution" ||
                                          _obstacleLevelForDistance(_leftObstacleDistance) === "danger" ||
                                          _obstacleLevelForDistance(_leftObstacleDistance) === "caution"
    property string _obstacleIndicatorLevel: {
        return _obstacleLevelForDistance(_nearestObstacleDistance)
    }

    function _minimumObstacleDistance(indices) {
        var values = obstacleProximity.rgRotationValues
        var nearest = NaN
        for (var i = 0; i < indices.length; i++) {
            var distance = Number(values[indices[i]])
            if (!isNaN(distance) && distance > 0 && (isNaN(nearest) || distance < nearest)) {
                nearest = distance
            }
        }
        return nearest
    }

    function _calculateNearestObstacleDistance() {
        return _minimumObstacleDistance([0, 1, 2, 3, 4, 5, 6, 7])
    }

    function _calculateNearestObstacleDirection() {
        var directions = [
            { label: qsTr("FRONT"), distance: _frontObstacleDistance },
            { label: qsTr("RIGHT"), distance: _rightObstacleDistance },
            { label: qsTr("REAR"), distance: _rearObstacleDistance },
            { label: qsTr("LEFT"), distance: _leftObstacleDistance }
        ]
        var nearestDirection = qsTr("NO DATA")
        var nearest = NaN
        for (var i = 0; i < directions.length; i++) {
            if (!isNaN(directions[i].distance) &&
                    (isNaN(nearest) || directions[i].distance < nearest)) {
                nearest = directions[i].distance
                nearestDirection = directions[i].label
            }
        }
        return nearestDirection
    }

    function _obstacleLevelForDistance(distance) {
        if (isNaN(distance)) {
            return "waiting"
        }
        if (distance <= _obstacleDangerDistance) {
            return "danger"
        }
        if (distance <= _obstacleCautionDistance) {
            return "caution"
        }
        return "clear"
    }

    function _obstacleColorForDistance(distance) {
        switch (_obstacleLevelForDistance(distance)) {
        case "danger":
            return "#FF3B30"
        case "caution":
            return "#FFC928"
        case "clear":
            return "#32D17D"
        default:
            return "#84909C"
        }
    }

    function _obstacleIndicatorColor() {
        return _obstacleColorForDistance(_nearestObstacleDistance)
    }

    function _obstacleIndicatorText() {
        switch (_obstacleIndicatorLevel) {
        case "danger":
            return qsTr("STOP")
        case "caution":
            return qsTr("CAUTION")
        case "clear":
            return qsTr("CLEAR")
        default:
            return qsTr("WAITING")
        }
    }

    function _applyGridTechnique(technique) {
        _compositionGrid = false
        _centerMark = false
        _frameGuide = false
        _zebraOverlay = false
        _falseColor = false

        switch (technique) {
        case "Grid":
            _compositionGrid = true
            _gridStyle = "Thirds"
            break
        case "X":
            _compositionGrid = true
            _gridStyle = "X"
            break
        case "Point":
            _compositionGrid = true
            _gridStyle = "Point"
            break
        case "Square":
            _compositionGrid = true
            _gridStyle = "Square"
            break
        case "Reticle":
            _centerMark = true
            break
        case "Frame":
            _frameGuide = true
            break
        case "Zebra":
            _zebraOverlay = true
            break
        case "False":
            _falseColor = true
            break
        default:
            break
        }
    }

    function _syncGridTechniqueSetting() {
        var enabled = QGroundControl.loadGlobalSetting("Camera.GridTechniqueEnabled", "false") === "true"
        var technique = enabled ? QGroundControl.loadGlobalSetting("Camera.GridTechnique", "Grid Off") : "Grid Off"
        if (technique === _gridTechniqueSetting) {
            return
        }
        _gridTechniqueSetting = technique
        _applyGridTechnique(technique)
    }

    function _resetCameraOverlays() {
        _compositionGrid = false
        _centerMark = false
        _safeFrame = false
        _zebraOverlay = false
        _histogramOverlay = false
        _exposureWarnings = false
        _focusPeaking = false
        _falseColor = false
        _frameGuide = false
        _gridTechniqueSetting = "Grid Off"

        QGroundControl.saveGlobalSetting("Camera.CompositionGrid", "false")
        QGroundControl.saveGlobalSetting("Camera.GridTechniqueEnabled", "false")
        QGroundControl.saveGlobalSetting("Camera.CenterMark", "false")
        QGroundControl.saveGlobalSetting("Camera.SafeFrame", "false")
        QGroundControl.saveGlobalSetting("Camera.ZebraOverlay", "false")
        QGroundControl.saveGlobalSetting("Camera.HistogramOverlay", "false")
        QGroundControl.saveGlobalSetting("Camera.ExposureWarnings", "false")
        QGroundControl.saveGlobalSetting("Camera.FocusPeaking", "false")
        QGroundControl.saveGlobalSetting("Camera.FalseColor", "false")
    }

    on_ShowCameraStudioChanged: {
        if (_showCameraStudio) {
            _resetCameraOverlays()
        }
    }

    Timer {
        interval: 200
        repeat: true
        running: _root._showCameraStudio
        triggeredOnStart: true
        onTriggered: {
            _root._syncGridTechniqueSetting()
            _root._refreshMissionShotSettings()
            _root._obstacleAvoidanceAction = QGroundControl.loadGlobalSetting("Safety.ObstacleAvoidanceAction", "Bypass")
        }
    }
    property int  _recordSeconds: 0
    property string _pendingRecordingFile: ""
    property int _libraryRefreshTick: 0
    property real _digitalZoom: Number(QGroundControl.loadGlobalSetting("Camera.DigitalZoom", "1.0"))
    property int  _profileValue: _videoSettings.cameraColorProfile.rawValue
    property real _effectiveBrightness: Math.max(-1.0, Math.min(1.0, _videoSettings.cameraBrightness.rawValue / 100.0)) + (_profileValue === 3 ? -0.10 : (_profileValue === 5 ? 0.10 : 0))
    property real _effectiveContrast: Math.max(-1.0, Math.min(1.0, _videoSettings.cameraContrast.rawValue / 100.0)) + (_profileValue === 1 ? 0.12 : (_profileValue === 2 ? 0.18 : (_profileValue === 4 ? 0.28 : 0)))
    property real _effectiveSaturation: Math.max(-1.0, Math.min(1.0, _videoSettings.cameraSaturation.rawValue / 100.0)) + (_profileValue === 1 ? 0.10 : (_profileValue === 3 ? -0.28 : 0))
    property color _profileTint: _profileValue === 3 ? Qt.rgba(0.10, 0.20, 0.42, 0.18)
                                : (_profileValue === 5 ? Qt.rgba(0.95, 0.78, 0.45, 0.12)
                                                       : (_profileValue === 1 ? Qt.rgba(0.95, 0.62, 0.35, 0.08)
                                                                              : "transparent"))
    property bool _effectsActive: _profileValue !== 0 ||
                                  _videoSettings.cameraBrightness.rawValue !== 0 ||
                                  _videoSettings.cameraContrast.rawValue !== 0 ||
                                  _videoSettings.cameraSaturation.rawValue !== 0
    property bool _previewEffectsActive: _videoIsFull && _effectsActive
    property bool _overExposureLikely: _videoSettings.cameraBrightness.rawValue >= 45 || (_zebraOverlay && _zebraLevel <= 75)
    property bool _underExposureLikely: _videoSettings.cameraBrightness.rawValue <= -45 || _profileValue === 3
    property bool _localCameraAvailable: localCameraDevices.videoInputs.length > 0

    property int    _track_rec_x:       0
    property int    _track_rec_y:       0

    MediaDevices {
        id: localCameraDevices
    }

    ProximityRadarValues {
        id: obstacleProximity
        vehicle: _root._activeVehicle
    }

    QGCFileDialogController {
        id: mediaFileController
    }

    QGCFileDialog {
        id: mediaExportFolderDialog
        title: qsTr("Choose export folder")
        folder: _root._settingsFolderPath(_root._appSettings.photoSavePath)
        selectFolder: true
        onAcceptedForLoad: function(folderPath) {
            _root._exportReviewMediaToFolder(folderPath)
        }
    }

    ListModel {
        id: mediaLibraryModel
    }

    ListModel {
        id: savedCameraProfiles
    }

    Component.onCompleted: {
        _resetCameraOverlays()
        _syncGridTechniqueSetting()
        _refreshMissionShotSettings(true)
        _refreshMediaStorage()
        _loadSavedCameraProfiles()
    }

    Timer {
        id: libraryRefreshTimer
        interval: 450
        repeat: true
        property int remainingTicks: 0
        onTriggered: {
            _root._libraryRefreshTick++
            remainingTicks--
            if (remainingTicks <= 0) {
                stop()
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: _root._showCameraStudio
        triggeredOnStart: true
        onTriggered: _root._refreshMediaStorage()
    }

    Timer {
        interval: 1000
        repeat: true
        running: _root._showCameraStudio && _root._libraryOpen
        triggeredOnStart: true
        onTriggered: _root._pruneMissingLocalMedia()
    }

    function _toast(message) {
        if (typeof mainWindow !== "undefined" && mainWindow.showToastMessage) {
            mainWindow.showToastMessage(message)
        }
    }

    function _setFactRaw(fact, value) {
        if (fact) {
            fact.rawValue = value
        }
    }

    function _applyCameraPreset(profile, brightness, contrast, saturation, sharpness, gamma) {
        _setFactRaw(_videoSettings.cameraColorProfile, profile)
        _setFactRaw(_videoSettings.cameraBrightness, brightness)
        _setFactRaw(_videoSettings.cameraContrast, contrast)
        _setFactRaw(_videoSettings.cameraSaturation, saturation)
        _setFactRaw(_videoSettings.cameraSharpness, sharpness)
        _setFactRaw(_videoSettings.cameraGamma, gamma)
    }

    function _recordingFormatName() {
        return _videoSettings.recordingFormat.rawValue === 1 ? "MOV" : (_videoSettings.recordingFormat.rawValue === 2 ? "MP4" : "MKV")
    }

    function _setRecordingFormatName(formatName) {
        _videoSettings.recordingFormat.rawValue = formatName === "MOV" ? 1 : 2
    }

    function _settingBackendNote() {
        if (cameraLoader.item && cameraLoader.item.startRecording) {
            return qsTr("Saved for local recording profile")
        }
        if (_hasCameraControl) {
            return qsTr("Saved locally; camera support depends on MAVLink camera capabilities")
        }
        if (QGroundControl.videoManager.hasVideo) {
            return qsTr("Saved for stream recording profile")
        }
        return qsTr("Saved")
    }

    function _setCodingFormat(formatName) {
        _codingFormat = formatName
        QGroundControl.saveGlobalSetting("Camera.CodingFormat", formatName)
        _toast(_settingBackendNote() + qsTr(": ") + formatName)
    }

    function _setVideoResolution(resolutionName) {
        _videoResolution = resolutionName
        QGroundControl.saveGlobalSetting("Camera.VideoResolution", resolutionName)
        _toast(_settingBackendNote() + qsTr(": ") + resolutionName)
    }

    function _setFrameRate(frameRateName) {
        _frameRate = frameRateName
        QGroundControl.saveGlobalSetting("Camera.FrameRate", frameRateName)
        _toast(_settingBackendNote() + qsTr(": ") + frameRateName + qsTr(" FPS"))
    }

    function _setBitrateQuality(qualityName) {
        _bitrateQuality = qualityName
        QGroundControl.saveGlobalSetting("Camera.BitrateQuality", qualityName)
        _toast(_settingBackendNote() + qsTr(": ") + qualityName)
    }

    function _resetRecordingProfile() {
        _codingFormat = "H.264"
        _videoResolution = "1080p"
        _frameRate = "30"
        _bitrateQuality = "Standard"
        _saveRecordingProfileSettings()
    }

    function _saveRecordingProfileSettings() {
        QGroundControl.saveGlobalSetting("Camera.CodingFormat", _codingFormat)
        QGroundControl.saveGlobalSetting("Camera.VideoResolution", _videoResolution)
        QGroundControl.saveGlobalSetting("Camera.FrameRate", _frameRate)
        QGroundControl.saveGlobalSetting("Camera.BitrateQuality", _bitrateQuality)
        QGroundControl.saveGlobalSetting("Camera.StorageWarningLevel", _storageWarningLevel.toString())
        QGroundControl.saveGlobalSetting("Camera.CloudSyncStatus", _cloudSyncStatus)
        QGroundControl.saveGlobalSetting("Camera.MetadataWatermark", _watermarkMetadata ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.VideoSubtitles", _videoSubtitles ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.StorageTarget", _storageTarget)
        QGroundControl.saveGlobalSetting("Camera.CacheVideoRecording", _cacheVideoRecording ? "true" : "false")
    }

    function _refreshRecordingProfileSettings() {
        _codingFormat = QGroundControl.loadGlobalSetting("Camera.CodingFormat", "H.264")
        _videoResolution = QGroundControl.loadGlobalSetting("Camera.VideoResolution", "1080p")
        _frameRate = QGroundControl.loadGlobalSetting("Camera.FrameRate", "30")
        _bitrateQuality = QGroundControl.loadGlobalSetting("Camera.BitrateQuality", "Standard")
        _storageWarningLevel = Number(QGroundControl.loadGlobalSetting("Camera.StorageWarningLevel", "80"))
        _cloudSyncStatus = QGroundControl.loadGlobalSetting("Camera.CloudSyncStatus", "Pending")
        _watermarkMetadata = QGroundControl.loadGlobalSetting("Camera.MetadataWatermark", "false") === "true"
        _videoSubtitles = QGroundControl.loadGlobalSetting("Camera.VideoSubtitles", "false") === "true"
        _storageTarget = QGroundControl.loadGlobalSetting("Camera.StorageTarget", "SD Card")
        _cacheVideoRecording = QGroundControl.loadGlobalSetting("Camera.CacheVideoRecording", "false") === "true"
    }

    function _saveMissionShotSettings() {
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

    function _shutterModeLabel(value) {
        var denominator = Math.round(Number(value))
        return denominator > 0 ? "1/" + denominator : "Auto"
    }

    function _isoLimitLabel(value) {
        var iso = Math.round(Number(value))
        return iso > 0 ? iso.toString() : "Auto"
    }

    function _setCameraFact(fact, value) {
        if (!fact) {
            return
        }
        fact.rawValue = value
    }

    function _shutterSupported() {
        return !!(_hasCameraControl && _camera && _camera.shutterSpeed)
    }

    function _isoSupported() {
        return !!(_hasCameraControl && _camera && _camera.iso)
    }

    function _evSupported() {
        return !!(_hasCameraControl && _camera && _camera.ev)
    }

    function _exposureControlsAvailable() {
        return _shutterSupported() || _isoSupported() || _evSupported()
    }

    function _focusControlsAvailable() {
        return !!(_hasCameraControl && _camera && (_camera.hasFocus || _camera.hasTracking)) ||
               !!(_activeVehicle && _activeVehicle.roiModeSupported)
    }

    function _profileSnapshot() {
        return {
            colorProfile: _videoSettings.cameraColorProfile.rawValue,
            brightness: _videoSettings.cameraBrightness.rawValue,
            contrast: _videoSettings.cameraContrast.rawValue,
            saturation: _videoSettings.cameraSaturation.rawValue,
            sharpness: _videoSettings.cameraSharpness.rawValue,
            gamma: _videoSettings.cameraGamma.rawValue,
            digitalZoom: _digitalZoom,
            captureMode: _captureMode,
            burstCount: _burstCount,
            intervalSeconds: _intervalSeconds,
            timerSeconds: _timerSeconds,
            shutterMode: _shutterMode,
            isoLimit: _isoLimit,
            evCompensation: _evCompensation,
            centerMark: _centerMark,
            safeFrame: _safeFrame,
            zebraOverlay: _zebraOverlay,
            histogramOverlay: _histogramOverlay,
            exposureWarnings: _exposureWarnings,
            focusPeaking: _focusPeaking,
            falseColor: _falseColor
        }
    }

    function _applyProfileSnapshot(profile) {
        if (!profile) {
            return
        }
        _applyCameraPreset(Number(profile.colorProfile), Number(profile.brightness), Number(profile.contrast),
                           Number(profile.saturation), Number(profile.sharpness), Number(profile.gamma))
        _digitalZoom = Math.max(1.0, Math.min(4.0, Number(profile.digitalZoom)))
        _setCaptureMode(profile.captureMode || "single")
        _burstCount = Number(profile.burstCount || 5)
        _intervalSeconds = Number(profile.intervalSeconds || 5)
        _timerSeconds = Number(profile.timerSeconds || 3)
        _centerMark = !!profile.centerMark
        _safeFrame = !!profile.safeFrame
        _zebraOverlay = !!profile.zebraOverlay
        _histogramOverlay = !!profile.histogramOverlay
        _exposureWarnings = !!profile.exposureWarnings
        _focusPeaking = !!profile.focusPeaking
        _falseColor = !!profile.falseColor
        if (_shutterSupported()) {
            _setShutterMode(profile.shutterMode || "Auto")
        }
        if (_isoSupported()) {
            _setIsoLimit(profile.isoLimit || "Auto")
        }
        if (_evSupported()) {
            _setEvCompensation(Number(profile.evCompensation || 0))
        }
        _saveMissionShotSettings()
    }

    function _saveProfilesToSettings() {
        var profiles = []
        for (var i = 0; i < savedCameraProfiles.count; i++) {
            var item = savedCameraProfiles.get(i)
            profiles.push({ name: item.name, settings: item.settings })
        }
        QGroundControl.saveGlobalSetting("Camera.SavedProfiles", JSON.stringify(profiles))
    }

    function _loadSavedCameraProfiles() {
        savedCameraProfiles.clear()
        var stored = QGroundControl.loadGlobalSetting("Camera.SavedProfiles", "[]")
        try {
            var profiles = JSON.parse(stored)
            if (!profiles || profiles.length === undefined) {
                return
            }
            for (var i = 0; i < profiles.length; i++) {
                if (profiles[i].name && profiles[i].settings) {
                    savedCameraProfiles.append({ name: profiles[i].name, settings: profiles[i].settings })
                }
            }
        } catch (error) {
            console.warn("Unable to load saved camera profiles:", error)
        }
    }

    function _saveCurrentCameraProfile() {
        var name = _savedProfileName.trim()
        if (name.length === 0) {
            _toast(qsTr("Enter a profile name"))
            return
        }
        for (var i = 0; i < savedCameraProfiles.count; i++) {
            if (savedCameraProfiles.get(i).name.toLowerCase() === name.toLowerCase()) {
                savedCameraProfiles.setProperty(i, "name", name)
                savedCameraProfiles.setProperty(i, "settings", _profileSnapshot())
                _saveProfilesToSettings()
                _toast(qsTr("Camera profile updated"))
                return
            }
        }
        savedCameraProfiles.append({ name: name, settings: _profileSnapshot() })
        _saveProfilesToSettings()
        _savedProfileName = ""
        _toast(qsTr("Camera profile saved"))
    }

    function _deleteCameraProfile(index) {
        if (index < 0 || index >= savedCameraProfiles.count) {
            return
        }
        savedCameraProfiles.remove(index)
        _saveProfilesToSettings()
        _toast(qsTr("Camera profile deleted"))
    }

    function _syncCameraExposureMode() {
        if (!_camera || !_camera.exposureMode) {
            return
        }
        _setCameraFact(_camera.exposureMode, (_shutterMode === "Auto" && _isoLimit === "Auto") ? 0 : 1)
    }

    function _setShutterMode(mode) {
        _shutterMode = mode
        var denominator = mode === "Auto" ? 0 : Number(mode.substring(2))
        _videoSettings.cameraShutter.rawValue = denominator
        _syncCameraExposureMode()
        if (denominator > 0 && _camera && _camera.shutterSpeed) {
            _setCameraFact(_camera.shutterSpeed, 1.0 / denominator)
        }
    }

    function _setEvCompensation(value) {
        _evCompensation = Math.round(value * 10) / 10
        _videoSettings.cameraExposure.rawValue = _evCompensation
        if (_camera && _camera.ev && _shutterMode === "Auto" && _isoLimit === "Auto") {
            _setCameraFact(_camera.ev, _evCompensation)
        }
    }

    function _setIsoLimit(isoLabel) {
        _isoLimit = isoLabel
        var iso = isoLabel === "Auto" ? 0 : Number(isoLabel)
        _videoSettings.cameraIso.rawValue = iso
        _syncCameraExposureMode()
        if (iso > 0 && _camera && _camera.iso) {
            _setCameraFact(_camera.iso, iso)
        }
    }

    function _saveExposureAssistSettings() {
        QGroundControl.saveGlobalSetting("Camera.ZebraOverlay", _zebraOverlay ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.HistogramOverlay", _histogramOverlay ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.ExposureWarnings", _exposureWarnings ? "true" : "false")
        QGroundControl.saveGlobalSetting("Camera.ZebraLevel", _zebraLevel.toString())
        _missionShotSignature = _missionShotSettingsSignature()
    }

    function _missionShotSettingsSignature() {
        return [
            QGroundControl.loadGlobalSetting("Camera.MissionShotPreset", ""),
            QGroundControl.loadGlobalSetting("Camera.CaptureMode", "single"),
            QGroundControl.loadGlobalSetting("Camera.DigitalZoom", "1.0"),
            QGroundControl.loadGlobalSetting("Camera.MissionProofMode", "false"),
            QGroundControl.loadGlobalSetting("Camera.CenterMark", "false"),
            QGroundControl.loadGlobalSetting("Camera.SafeFrame", "false"),
            QGroundControl.loadGlobalSetting("Camera.ZebraOverlay", "false"),
            QGroundControl.loadGlobalSetting("Camera.HistogramOverlay", "false"),
            QGroundControl.loadGlobalSetting("Camera.ExposureWarnings", "false"),
            QGroundControl.loadGlobalSetting("Camera.FocusPeaking", "false"),
            QGroundControl.loadGlobalSetting("Camera.FalseColor", "false"),
            QGroundControl.loadGlobalSetting("Camera.ZebraLevel", "85"),
            QGroundControl.loadGlobalSetting("Camera.BurstCount", "5"),
            QGroundControl.loadGlobalSetting("Camera.IntervalSeconds", "5"),
            QGroundControl.loadGlobalSetting("Camera.TimerSeconds", "3")
        ].join("|")
    }

    function _refreshMissionShotSettings(forceRefresh) {
        var storedSignature = _missionShotSettingsSignature()
        if (!forceRefresh && storedSignature === _missionShotSignature) {
            return
        }
        _missionShotSignature = storedSignature
        _missionShotPreset = QGroundControl.loadGlobalSetting("Camera.MissionShotPreset", "")
        _captureMode = QGroundControl.loadGlobalSetting("Camera.CaptureMode", "single")
        _digitalZoom = Number(QGroundControl.loadGlobalSetting("Camera.DigitalZoom", "1.0"))
        _missionProofMode = QGroundControl.loadGlobalSetting("Camera.MissionProofMode", "false") === "true"
        _centerMark = QGroundControl.loadGlobalSetting("Camera.CenterMark", "false") === "true"
        _safeFrame = QGroundControl.loadGlobalSetting("Camera.SafeFrame", "false") === "true"
        _zebraOverlay = QGroundControl.loadGlobalSetting("Camera.ZebraOverlay", "false") === "true"
        _histogramOverlay = QGroundControl.loadGlobalSetting("Camera.HistogramOverlay", "false") === "true"
        _exposureWarnings = QGroundControl.loadGlobalSetting("Camera.ExposureWarnings", "false") === "true"
        _focusPeaking = QGroundControl.loadGlobalSetting("Camera.FocusPeaking", "false") === "true"
        _falseColor = QGroundControl.loadGlobalSetting("Camera.FalseColor", "false") === "true"
        _zebraLevel = Number(QGroundControl.loadGlobalSetting("Camera.ZebraLevel", "85"))
        _burstCount = Number(QGroundControl.loadGlobalSetting("Camera.BurstCount", "5"))
        _intervalSeconds = Number(QGroundControl.loadGlobalSetting("Camera.IntervalSeconds", "5"))
        _timerSeconds = Number(QGroundControl.loadGlobalSetting("Camera.TimerSeconds", "3"))
    }

    function _cameraColorName() {
        switch (_profileValue) {
        case 1:
            return "Cinematic"
        case 2:
            return "Inspection"
        case 3:
            return "D-Log M"
        case 4:
            return "Vivid"
        case 5:
            return "HLG"
        case 6:
            return "Low Light"
        case 7:
            return "B&W"
        default:
            return "Normal"
        }
    }

    function _applyCameraColorName(colorName) {
        if (colorName === "D-Log M") {
            _applyCameraPreset(3, -6, 10, -18, 12, 1.2)
        } else if (colorName === "HLG") {
            _applyCameraPreset(5, 8, 8, 6, 8, 1.15)
        } else if (colorName === "Vivid") {
            _applyCameraPreset(4, 2, 24, 18, 14, 0.95)
        } else if (colorName === "Cinematic") {
            _applyCameraPreset(1, -2, 10, 12, 8, 1.0)
        } else if (colorName === "Low Light") {
            _applyCameraPreset(6, 14, 8, 4, 4, 1.3)
        } else if (colorName === "Inspection") {
            _applyCameraPreset(2, 4, 24, 0, 28, 0.9)
        } else if (colorName === "B&W") {
            _applyCameraPreset(7, 0, 18, -100, 18, 1.0)
        } else {
            _applyCameraPreset(0, 0, 0, 0, 0, 1.0)
        }
    }

    function _resetAllCameraParameters() {
        _resetCameraTools()
        _setRecordingFormatName("MP4")
        _resetRecordingProfile()
        _shutterMode = "Auto"
        _evCompensation = 0
        _isoLimit = "Auto"
        _focusModeSetting = "Auto"
        _gimbalHorizonLock = false
        _autoProofCapture = false
        _storageWarningLevel = 80
        _cloudSyncStatus = "Pending"
        _watermarkMetadata = false
        _videoSubtitles = false
        _peakingLevel = "OFF"
        _gridStyle = "X"
        _frameGuide = false
        _storageTarget = "SD Card"
        _cacheVideoRecording = false
        _whiteManual = false
        _missionProofMode = false
        _saveRecordingProfileSettings()
        _toast(qsTr("Camera parameters reset"))
    }

    function _applyMissionShotPreset(preset) {
        _missionShotPreset = preset
        _histogramOverlay = false
        _exposureWarnings = false
        _zebraOverlay = false
        _focusPeaking = false
        _falseColor = false
        _centerMark = true
        _safeFrame = false

        switch (preset) {
        case "inspection":
            _digitalZoom = 2.0
            _safeFrame = true
            _focusPeaking = true
            _zebraOverlay = true
            _zebraLevel = 90
            _applyCameraPreset(2, 4, 24, 0, 28, 0.9)
            _setCaptureMode("single")
            break
        case "cinematic":
            _digitalZoom = 1.2
            _safeFrame = false
            _applyCameraPreset(1, -2, 10, 12, 8, 1.0)
            _setCaptureMode("timer")
            _timerSeconds = 3
            break
        case "mapping":
            _digitalZoom = 1.0
            _safeFrame = true
            _centerMark = false
            _applyCameraPreset(0, 0, 8, -4, 12, 1.0)
            _setCaptureMode("interval")
            _intervalSeconds = 5
            break
        case "lowLight":
            _digitalZoom = 1.4
            _histogramOverlay = true
            _exposureWarnings = true
            _applyCameraPreset(5, 14, 8, 4, 4, 1.3)
            _setCaptureMode("single")
            break
        case "thermal":
            _digitalZoom = 1.6
            _falseColor = true
            _histogramOverlay = true
            _safeFrame = true
            _applyCameraPreset(3, -8, 18, -30, 18, 1.2)
            _setCaptureMode("single")
            break
        case "payloadProof":
            _digitalZoom = 1.0
            _safeFrame = true
            _centerMark = true
            _zebraOverlay = true
            _zebraLevel = 85
            _missionProofMode = true
            _applyCameraPreset(4, 0, 28, 4, 18, 0.9)
            _setCaptureMode("burst")
            _burstCount = 3
            break
        case "evidence":
            _digitalZoom = 1.0
            _safeFrame = true
            _centerMark = true
            _histogramOverlay = true
            _exposureWarnings = true
            _missionProofMode = true
            _applyCameraPreset(4, 0, 24, 2, 20, 0.9)
            _setCaptureMode("burst")
            _burstCount = 3
            break
        }

        _saveMissionShotSettings()
        _toast(qsTr("Mission shot preset applied"))
    }

    function _resetCameraTools() {
        _applyCameraPreset(0, 0, 0, 0, 0, 1.0)
        _digitalZoom = 1.0
        _compositionGrid = false
        _centerMark = false
        _safeFrame = false
        _zebraOverlay = false
        _histogramOverlay = false
        _exposureWarnings = false
        _videoSubtitles = false
        _peakingLevel = "OFF"
        _gridStyle = "X"
        _frameGuide = false
        _storageTarget = "SD Card"
        _cacheVideoRecording = false
        _resetRecordingProfile()
        _shutterMode = "Auto"
        _evCompensation = 0
        _isoLimit = "Auto"
        _focusModeSetting = "Auto"
        _gimbalHorizonLock = false
        _autoProofCapture = false
        _storageWarningLevel = 80
        _cloudSyncStatus = "Pending"
        _watermarkMetadata = false
        _zebraLevel = 85
        _focusPeaking = false
        _falseColor = false
        _tapFocusEnabled = true
        _tapTrackEnabled = true
        _tapFocusVisible = false
        _missionProofMode = false
        aiAutoCaptureEnabled = false
        _captureMode = "single"
        _burstCount = 5
        _burstRemaining = 0
        _intervalActive = false
        _intervalSeconds = 5
        _timerSeconds = 3
        _timerRemaining = 0
        _panoramaRemaining = 0
        _orbitShotArmed = false
        _gimbalSpeed = 5.0
        _saveRecordingProfileSettings()
        _mediaReviewIndex = -1
        burstCaptureTimer.stop()
        intervalCaptureTimer.stop()
        timerCaptureTimer.stop()
        panoramaCaptureTimer.stop()
        if (_videoSettings.gridLines) {
            _videoSettings.gridLines.rawValue = 0
        }
    }

    Timer {
        id: storageRefreshTimer
        interval: 5000
        repeat: true
        running: _root._libraryOpen
        onTriggered: _root._refreshMediaStorage()
    }

    function _recordingStorageLabel() {
        if (_hasCameraControl && _camera.storageFreeStr && _camera.storageFreeStr.length > 0) {
            return _camera.storageFreeStr
        }
        return QGroundControl.videoManager.hasVideo || QGroundControl.videoManager.isUvc ? qsTr("Local") : qsTr("--")
    }

    function _recordingTimeLeftLabel() {
        if (_localRecording) {
            return _formatRecordSeconds(_recordSeconds) + (_recordingPaused ? qsTr(" paused") : qsTr(" elapsed"))
        }
        if (_hasCameraControl && _camera.recordTimeStr && _camera.recordTimeStr.length > 0) {
            return _camera.recordTimeStr
        }
        if (_recordingActive) {
            return _formatRecordSeconds(_recordSeconds) + qsTr(" elapsed")
        }
        return qsTr("--")
    }

    function _recordingResolutionLabel() {
        if (_hasCameraControl && _camera.resolution && _camera.resolution.width > 0 && _camera.resolution.height > 0) {
            return _camera.resolution.width + "x" + _camera.resolution.height
        }
        return _videoResolution
    }

    function _recordingFpsLabel() {
        return _frameRate
    }

    function _recordingBitrateLabel() {
        if (_hasCameraControl && _camera.currentStreamInstance && _camera.currentStreamInstance.name && _camera.currentStreamInstance.name.length > 0) {
            return qsTr("Auto")
        }
        return _bitrateQuality
    }

    function _recordingDroppedFramesLabel() {
        return QGroundControl.videoManager.decoding ? qsTr("Monitor") : qsTr("--")
    }

    function _recordingCodecLabel() {
        if (_hasCameraControl && _camera.currentStreamInstance && _camera.currentStreamInstance.name && _camera.currentStreamInstance.name.length > 0) {
            return _camera.currentStreamInstance.name
        }
        return _codingFormat
    }

    function _recordingHealthValue(key) {
        switch (key) {
        case "storage":
            return _recordingStorageLabel()
        case "time":
            return _recordingTimeLeftLabel()
        case "dropped":
            return _recordingDroppedFramesLabel()
        case "bitrate":
            return _recordingBitrateLabel()
        case "resolution":
            return _recordingResolutionLabel()
        case "fps":
            return _recordingFpsLabel()
        case "codec":
            return _recordingCodecLabel()
        default:
            return qsTr("--")
        }
    }

    function _cameraConnectionLabel() {
        if (_hasCameraControl) {
            return qsTr("Drone camera connected")
        }
        if (cameraLoader.item || QGroundControl.videoManager.hasVideo || QGroundControl.videoManager.isUvc) {
            return qsTr("Video feed connected")
        }
        return qsTr("Camera disconnected")
    }

    function _cameraConnectionActive() {
        return _hasCameraControl || cameraLoader.item || QGroundControl.videoManager.hasVideo || QGroundControl.videoManager.isUvc
    }

    function _batteryPercent() {
        if (!_activeVehicle || !_activeVehicle.batteries || _activeVehicle.batteries.count === 0) {
            return NaN
        }
        var battery = _activeVehicle.batteries.get ? _activeVehicle.batteries.get(0) : _activeVehicle.batteries[0]
        return battery && battery.percentRemaining && !isNaN(battery.percentRemaining.rawValue) ? battery.percentRemaining.rawValue : NaN
    }

    function _lowBatteryWarningActive() {
        var pct = _batteryPercent()
        return !isNaN(pct) && pct <= 20
    }

    function _altitudeMeters() {
        if (_activeVehicle && _activeVehicle.altitudeRelative && !isNaN(_activeVehicle.altitudeRelative.rawValue)) {
            return _activeVehicle.altitudeRelative.rawValue
        }
        if (_activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid && !isNaN(_activeVehicle.coordinate.altitude)) {
            return _activeVehicle.coordinate.altitude
        }
        return NaN
    }

    function _safetyLevel(key) {
        var battery = _batteryPercent()
        var altitude = _altitudeMeters()
        switch (key) {
        case "battery":
            return isNaN(battery) ? "warn" : (battery <= 20 ? "bad" : (battery <= 35 ? "warn" : "ok"))
        case "altitude":
            return isNaN(altitude) ? "warn" : (altitude < 15 ? "bad" : (altitude < 30 ? "warn" : "ok"))
        case "storage":
            return _storageWarningActive() ? "warn" : "ok"
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

    function _safetyValue(key) {
        var battery = _batteryPercent()
        var altitude = _altitudeMeters()
        switch (key) {
        case "battery":
            return isNaN(battery) ? qsTr("--") : Math.round(battery) + "%"
        case "altitude":
            return isNaN(altitude) ? qsTr("--") : Math.round(altitude) + qsTr(" m")
        case "storage":
            return _storageWarningActive() ? qsTr("Low") : qsTr("OK")
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

    function _safetySummaryLabel() {
        var bad = 0
        var warn = 0
        var keys = [ "battery", "altitude", "storage", "return", "geofence", "wind" ]
        for (var i = 0; i < keys.length; i++) {
            var level = _safetyLevel(keys[i])
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

    function _safetySummaryColor() {
        var status = _safetySummaryLabel()
        return status === qsTr("Ready") ? "#6EE7B7" : (status === qsTr("Hold") ? "#D92D20" : "#FFB020")
    }

    function _pilotWarningLabel() {
        if (_storageWarningActive()) {
            return qsTr("LOW STORAGE")
        }
        if (_lowBatteryWarningActive()) {
            return qsTr("LOW BATTERY")
        }
        if (!_cameraConnectionActive()) {
            return qsTr("NO CAMERA")
        }
        return ""
    }

    function _droneIdLabel() {
        return _activeVehicle ? (qsTr("Drone ") + _activeVehicle.id) : qsTr("No drone")
    }

    function _vehicleLocationLabel() {
        if (_activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid) {
            return _activeVehicle.coordinate.latitude.toFixed(6) + ", " + _activeVehicle.coordinate.longitude.toFixed(6)
        }
        return qsTr("--")
    }

    function _vehicleAltitudeLabel() {
        if (_activeVehicle && _activeVehicle.altitudeRelative && !isNaN(_activeVehicle.altitudeRelative.rawValue)) {
            return _activeVehicle.altitudeRelative.valueString + _activeVehicle.altitudeRelative.units
        }
        if (_activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid && !isNaN(_activeVehicle.coordinate.altitude)) {
            return Math.round(_activeVehicle.coordinate.altitude) + qsTr(" m")
        }
        return qsTr("--")
    }

    function _vehicleHeadingDegrees() {
        if (_activeVehicle && _activeVehicle.heading && !isNaN(_activeVehicle.heading.rawValue)) {
            return Number(_activeVehicle.heading.rawValue)
        }
        return NaN
    }

    function _factLabel(fact) {
        if (!fact) {
            return qsTr("--")
        }
        var units = fact.units && fact.units.length > 0 ? (" " + fact.units) : ""
        if (fact.valueString && fact.valueString.length > 0) {
            return fact.valueString + units
        }
        if (!isNaN(fact.rawValue)) {
            return Number(fact.rawValue).toFixed(0) + units
        }
        return qsTr("--")
    }

    function _distanceFromPilotLabel() {
        return _activeVehicle ? _factLabel(_activeVehicle.distanceToHome) : qsTr("--")
    }

    function _groundSpeedLabel() {
        return _activeVehicle ? _factLabel(_activeVehicle.groundSpeed) : qsTr("--")
    }

    function _headingLabel() {
        var heading = _vehicleHeadingDegrees()
        return isNaN(heading) ? qsTr("--") : Math.round(heading) + "\u00b0"
    }

    function _batteryLabel() {
        var battery = _batteryPercent()
        return isNaN(battery) ? qsTr("--") : Math.round(battery) + "%"
    }

    function _captureMetadata(capturedAt) {
        var coordinateValid = _activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid
        var heading = _vehicleHeadingDegrees()
        return {
            capturedAt: capturedAt,
            latitude: coordinateValid ? _activeVehicle.coordinate.latitude : null,
            longitude: coordinateValid ? _activeVehicle.coordinate.longitude : null,
            absoluteAltitudeMeters: coordinateValid && !isNaN(_activeVehicle.coordinate.altitude) ? _activeVehicle.coordinate.altitude : null,
            relativeAltitudeMeters: _activeVehicle && _activeVehicle.altitudeRelative && !isNaN(_activeVehicle.altitudeRelative.rawValue)
                                    ? Number(_activeVehicle.altitudeRelative.rawValue) : null,
            headingDegrees: isNaN(heading) ? null : heading,
            vehicleId: _activeVehicle ? _activeVehicle.id : null,
            vehicleLabel: _droneIdLabel(),
            missionName: _missionName && _missionName.length > 0 ? _missionName : QGroundControl.loadGlobalSetting("loadpage", "loadpage"),
            cameraSource: _cameraSourceLabel(),
            cameraModel: _hasCameraControl && _camera.modelName ? _camera.modelName : "",
            captureMode: _captureMode,
            colorProfile: _cameraColorName(),
            digitalZoom: _digitalZoom
        }
    }

    function _writePhotoMetadata(filePath, metadata) {
        if (!filePath || filePath.length === 0 || !metadata) {
            return ""
        }
        var metadataPath = filePath + ".metadata.json"
        return mediaFileController.writeTextFile(metadataPath, JSON.stringify(metadata, null, 2)) ? metadataPath : ""
    }

    function _proofMetadataText(item) {
        if (!item) {
            return ""
        }
        var tagText = item.tag && item.tag.length > 0 ? (qsTr(" | Tag ") + item.tag) : ""
        var headingText = item.heading && item.heading.length > 0 ? (qsTr(" | Heading ") + item.heading) : ""
        return qsTr("GPS ") + item.gpsLocation + qsTr(" | Alt ") + item.altitude + headingText + qsTr(" | ") + item.droneId + qsTr(" | ") + item.missionName + tagText
    }

    function _mediaTypeLabel(kind) {
        if (kind === "video") {
            return qsTr("Video")
        }
        if (kind === "tag") {
            return qsTr("Tag")
        }
        return qsTr("Photo")
    }

    function _mediaIcon(kind) {
        if (kind === "video") {
            return "/qmlimages/camera_video.svg"
        }
        if (kind === "tag") {
            return "qrc:/InstrumentValueIcons/target.svg"
        }
        return "/qmlimages/camera_photo.svg"
    }

    function _liveStatusText() {
        return _cameraConnectionLabel()
               + qsTr(" | ") + _recordingResolutionLabel()
               + qsTr(" | FPS ") + _recordingFpsLabel()
               + qsTr(" | Bitrate ") + _recordingBitrateLabel()
               + qsTr(" | Storage ") + _recordingStorageLabel()
               + qsTr(" | Zoom ") + _digitalZoom.toFixed(1) + "x"
               + qsTr(" | Gimbal ") + (_gimbalAvailable() ? (Math.round(_gimbalPitch()) + qsTr(" deg")) : qsTr("--"))
    }

    function _aiLabelAllowed(label) {
        if (!aiPersonVehicleOnly) {
            return true
        }
        var lower = (label ? label : "").toString().toLowerCase()
        return lower.indexOf("person") >= 0 || lower.indexOf("vehicle") >= 0 || lower.indexOf("car") >= 0 || lower.indexOf("truck") >= 0 || lower.indexOf("bus") >= 0 || lower.indexOf("motor") >= 0
    }

    function _handleAiDetections(detections) {
        if (typeof mainWindow !== "undefined" && mainWindow.flightTimeline) {
            mainWindow.flightTimeline.recordDetection(detections)
        }
        if (!aiDetectionEnabled || !aiAutoCaptureEnabled || !detections || detections.length === 0) {
            return
        }
        var label = ""
        for (var i = 0; i < detections.length; i++) {
            label = detections[i].label || qsTr("Object")
            if (_aiLabelAllowed(label)) {
                var now = Date.now()
                if (now - _aiLastCaptureMs >= Math.max(1, aiAutoCaptureCooldownSeconds) * 1000) {
                    _aiLastCaptureMs = now
                    _aiLastDetectionLabel = label
                    _missionProofMode = true
                    _takeSinglePhoto()
                    _toast(qsTr("AI detection captured: ") + label)
                }
                return
            }
        }
    }

    function _videoPointFromScreen(x, y) {
        var videoWidth = videoStreaming.getWidth ? videoStreaming.getWidth() : _root.width
        var videoHeight = videoStreaming.getHeight ? videoStreaming.getHeight() : _root.height
        var offsetX = (width - videoWidth) / 2
        var offsetY = (height - videoHeight) / 2
        var px = Math.max(Math.min((x - offsetX) / videoWidth, 1.0), 0.0)
        var py = Math.max(Math.min((y - offsetY) / videoHeight, 1.0), 0.0)
        return Qt.point(px, py)
    }

    function _handleVideoTap(x, y) {
        if (!_tapFocusEnabled && !_tapTrackEnabled) {
            return
        }

        _tapFocusX = x
        _tapFocusY = y
        _tapFocusVisible = true
        tapFocusHideTimer.restart()

        if (_tapTrackEnabled && videoStreaming._camera && videoStreaming._camera.hasTracking) {
            if (!videoStreaming._camera.trackingEnabled) {
                videoStreaming._camera.trackingEnabled = true
            }
            videoStreaming._camera.startTracking(_videoPointFromScreen(x, y), flyViewVideoMouseArea.radius / Math.max(videoStreaming.getWidth(), 1))
            _toast(qsTr("Tracking point set"))
        } else if (_tapFocusEnabled) {
            _toast(qsTr("Focus point set"))
        }
    }

    function _trackingAvailable() {
        return _hasCameraControl && _camera && _camera.hasTracking
    }

    function _subjectLockLabel() {
        switch (_subjectLockMode) {
        case "person":
            return qsTr("Person")
        case "vehicle":
            return qsTr("Vehicle")
        case "building":
            return qsTr("Building")
        case "gps":
            return qsTr("GPS POI")
        default:
            return _trackingAvailable() && _camera.trackingEnabled ? qsTr("Tracking") : qsTr("Off")
        }
    }

    function _armSubjectTracking(mode) {
        _subjectLockMode = mode
        _tapTrackEnabled = true
        _tapFocusEnabled = true
        if (_trackingAvailable()) {
            _camera.trackingEnabled = true
            _toast(qsTr("Tap the video subject to lock ") + _subjectLockLabel())
        } else {
            _toast(qsTr("Subject tracking is not available on this camera"))
        }
    }

    function _lockCurrentGpsPoi() {
        if (!_activeVehicle || !_activeVehicle.coordinate || !_activeVehicle.coordinate.isValid) {
            _toast(qsTr("No GPS point available"))
            return
        }
        if (_activeVehicle.roiModeSupported) {
            _activeVehicle.guidedModeROI(_activeVehicle.coordinate)
            _subjectLockMode = "gps"
            _toast(qsTr("GPS point of interest locked"))
        } else {
            _toast(qsTr("ROI is not supported by this vehicle"))
        }
    }

    function _lockInspectionPoi() {
        _lookGimbalDown()
        _lockCurrentGpsPoi()
        if (_subjectLockMode === "gps") {
            _subjectLockMode = "building"
        }
    }

    function _clearSubjectLock() {
        if (_trackingAvailable() && _camera.trackingEnabled) {
            _camera.stopTracking()
            _camera.trackingEnabled = false
        }
        if (_activeVehicle && _activeVehicle.isROIEnabled && _activeVehicle.stopGuidedModeROI) {
            _activeVehicle.stopGuidedModeROI()
        }
        _subjectLockMode = "none"
        _toast(qsTr("Subject lock cleared"))
    }

    function _gimbalAvailable() {
        return _gimbalController && _activeGimbal
    }

    function _gimbalPitch() {
        return _gimbalAvailable() ? _activeGimbal.absolutePitch.rawValue : 0
    }

    function _gimbalYaw() {
        return _gimbalAvailable() ? (_activeGimbal.yawLock ? _activeGimbal.absoluteYaw.rawValue : _activeGimbal.bodyYaw.rawValue) : 0
    }

    function _sendGimbalAngles(pitch, yaw) {
        if (!_gimbalAvailable()) {
            _toast(qsTr("No gimbal connected"))
            return
        }
        _gimbalController.acquireGimbalControl()
        if (_activeGimbal.yawLock) {
            _gimbalController.sendPitchAbsoluteYaw(pitch, yaw)
        } else {
            _gimbalController.sendPitchBodyYaw(pitch, yaw)
        }
    }

    function _nudgeGimbal(pitchDelta, yawDelta) {
        _sendGimbalAngles(_gimbalPitch() + pitchDelta, _gimbalYaw() + yawDelta)
    }

    function _centerGimbal() {
        if (_gimbalAvailable()) {
            _gimbalController.centerGimbal()
        } else {
            _toast(qsTr("No gimbal connected"))
        }
    }

    function _lookGimbalDown() {
        _sendGimbalAngles(-90, _gimbalYaw())
    }

    function _lookGimbalForward() {
        _sendGimbalAngles(0, 0)
    }

    function _timestamp(includeMilliseconds) {
        return Qt.formatDateTime(new Date(), includeMilliseconds ? "yyyy-MM-dd_hh.mm.ss.zzz" : "yyyy-MM-dd_hh.mm.ss")
    }

    function _settingsFolderPath(setting) {
        if (!setting) {
            return ""
        }
        if (setting.rawValueString !== undefined) {
            return setting.rawValueString
        }
        if (setting.rawValue !== undefined) {
            return setting.rawValue
        }
        return setting.toString()
    }

    function _photoFilePath() {
        return _settingsFolderPath(_appSettings.photoSavePath) + "/" + _timestamp(true) + ".jpg"
    }

    function _recordingExtension() {
        switch (_videoSettings.recordingFormat.rawValue) {
        case 0:
            return "mkv"
        case 1:
            return "mov"
        default:
            return "mp4"
        }
    }

    function _videoBaseName() {
        return _timestamp(false)
    }

    function _videoFilePath(baseName) {
        return _settingsFolderPath(_appSettings.videoSavePath) + "/" + baseName + "." + _recordingExtension()
    }

    function _localVideoFilePath(baseName) {
        return _settingsFolderPath(_appSettings.videoSavePath) + "/" + baseName + ".mp4"
    }

    function _fileName(path) {
        if (!path || path.length === 0) {
            return qsTr("Unknown file")
        }
        var normalized = path.replace(/\\/g, "/")
        return normalized.substring(normalized.lastIndexOf("/") + 1)
    }

    function _fileUrl(path) {
        if (!path || path.length === 0) {
            return ""
        }
        var normalized = path.replace(/\\/g, "/")
        return normalized.indexOf("/") === 0 ? "file://" + normalized : "file:///" + normalized
    }

    function _formatBytes(bytes) {
        if (bytes < 0) {
            return qsTr("--")
        }
        if (bytes >= 1024 * 1024 * 1024) {
            return (bytes / (1024 * 1024 * 1024)).toFixed(1) + qsTr(" GB")
        }
        if (bytes >= 1024 * 1024) {
            return (bytes / (1024 * 1024)).toFixed(1) + qsTr(" MB")
        }
        return (bytes / 1024).toFixed(0) + qsTr(" KB")
    }

    function _refreshMediaStorage() {
        var photoPath = _settingsFolderPath(_appSettings.photoSavePath)
        var videoPath = _settingsFolderPath(_appSettings.videoSavePath)
        var photoBytes = mediaFileController.folderSizeBytes(photoPath, ["*.jpg", "*.jpeg", "*.png"])
        var videoBytes = mediaFileController.folderSizeBytes(videoPath, ["*.mp4", "*.mov", "*.mkv"])
        _mediaStorageBytes = photoBytes + videoBytes
        _saveStorageBytesAvailable = mediaFileController.storageBytesAvailable(videoPath)
        _saveStorageBytesTotal = mediaFileController.storageBytesTotal(videoPath)
        _saveStorageWritable = mediaFileController.storagePathWritable(videoPath) && mediaFileController.storagePathWritable(photoPath)
    }

    function _storagePercentUsed() {
        if (_saveStorageBytesAvailable < 0 || _saveStorageBytesTotal <= 0) {
            return -1
        }
        return Math.max(0, Math.min(100, Math.round((1 - (_saveStorageBytesAvailable / _saveStorageBytesTotal)) * 100)))
    }

    function _storageStatusLabel() {
        if (!_saveStorageWritable) {
            return qsTr("Not writable")
        }
        var percent = _storagePercentUsed()
        if (percent < 0) {
            return qsTr("Unknown")
        }
        return percent + qsTr("% used")
    }

    function _capabilityLevel(controlName) {
        switch (controlName) {
        case "photo":
            if (cameraLoader.item || QGroundControl.videoManager.hasVideo) {
                return "local"
            }
            return _hasCameraControl && _camera.capturesPhotos ? "drone" : "unavailable"
        case "record":
            if (cameraLoader.item || QGroundControl.videoManager.hasVideo) {
                return "local"
            }
            return _hasCameraControl && _camera.capturesVideo ? "drone" : "unavailable"
        case "gimbal":
            return _gimbalAvailable() ? "drone" : "unavailable"
        case "tracking":
            return _trackingAvailable() ? "drone" : "unavailable"
        case "roi":
            return _activeVehicle && _activeVehicle.roiModeSupported ? "drone" : "unavailable"
        case "zoom":
            return _hasCameraControl && _camera.hasZoom ? "drone" : "local"
        case "storage":
            return _saveStorageWritable ? "local" : "unavailable"
        default:
            return "local"
        }
    }

    function _capabilityBadgeText(controlName) {
        var level = _capabilityLevel(controlName)
        if (level === "drone") {
            return qsTr("Drone supported")
        }
        if (level === "local") {
            return qsTr("Local only")
        }
        return qsTr("Unavailable")
    }

    function _capabilityBadgeColor(controlName) {
        var level = _capabilityLevel(controlName)
        if (level === "drone") {
            return "#16A085"
        }
        if (level === "local") {
            return "#F39C12"
        }
        return Qt.rgba(1, 1, 1, 0.20)
    }

    function _logCameraCommand(commandName, backendName) {
        _lastCameraCommand = commandName
        _lastCameraBackend = backendName
        _toast(commandName + qsTr(" - ") + backendName)
    }

    function _checkStatus(key) {
        switch (key) {
        case "feed":
            return QGroundControl.videoManager.decoding || _localCameraAvailable ? qsTr("OK") : qsTr("No feed")
        case "recordPath":
            return _settingsFolderPath(_appSettings.videoSavePath).length > 0 ? qsTr("OK") : qsTr("Missing")
        case "storage":
            return _saveStorageWritable ? _storageStatusLabel() : qsTr("Not writable")
        case "gimbal":
            return _gimbalAvailable() ? qsTr("OK") : qsTr("Unavailable")
        case "tracking":
            return _trackingAvailable() ? qsTr("OK") : qsTr("Unavailable")
        case "gps":
            return _activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid ? qsTr("OK") : qsTr("No GPS")
        default:
            return qsTr("--")
        }
    }

    function _checkGood(key) {
        var status = _checkStatus(key)
        return status === qsTr("OK") || status.indexOf(qsTr("% used")) > -1
    }

    function _normalizeLocalPath(path) {
        if (!path || path.length === 0) {
            return ""
        }
        var normalized = path.toString().replace(/\\/g, "/")
        if (normalized.indexOf("file:///") === 0) {
            normalized = normalized.substring(8)
        } else if (normalized.indexOf("file://") === 0) {
            normalized = normalized.substring(7)
        }
        return normalized.toLowerCase()
    }

    function _folderFileSet(folderPath, filters) {
        var set = ({})
        if (!folderPath || folderPath.length === 0) {
            return set
        }
        var files = mediaFileController.getFiles(folderPath, filters)
        for (var i = 0; i < files.length; i++) {
            set[_normalizeLocalPath(folderPath + "/" + files[i])] = true
        }
        return set
    }

    function _pruneMissingLocalMedia() {
        var photoFiles = _folderFileSet(_settingsFolderPath(_appSettings.photoSavePath), ["*.jpg", "*.jpeg", "*.png"])
        var videoFiles = _folderFileSet(_settingsFolderPath(_appSettings.videoSavePath), ["*.mp4", "*.mov", "*.mkv"])
        var removed = false
        for (var i = mediaLibraryModel.count - 1; i >= 0; i--) {
            var item = mediaLibraryModel.get(i)
            var normalizedPath = _normalizeLocalPath(item.filePath)
            var foundInFolder = item.kind === "photo" ? photoFiles[normalizedPath] : (item.kind === "video" ? videoFiles[normalizedPath] : true)
            if (item.localCopy && item.filePath && item.filePath.length > 0 && (!mediaFileController.fileExists(item.filePath) || !foundInFolder)) {
                mediaLibraryModel.remove(i)
                removed = true
                if (_mediaReviewIndex === i) {
                    _mediaReviewIndex = -1
                } else if (_mediaReviewIndex > i) {
                    _mediaReviewIndex--
                }
            }
        }

        if (removed) {
            _libraryRefreshTick++
        }
        _refreshMediaStorage()
    }

    function _storageWarningActive() {
        var limitBytes = _videoSettings.maxVideoSize.rawValue * 1024 * 1024
        return limitBytes > 0 && _mediaStorageBytes >= limitBytes * (_storageWarningLevel / 100.0)
    }

    function _addMedia(kind, filePath, droneCopy, note) {
        var capturedAt = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")
        var metadata = _captureMetadata(capturedAt)
        var metadataPath = kind === "photo" ? _writePhotoMetadata(filePath, metadata) : ""
        mediaLibraryModel.insert(0, {
            kind: kind,
            filePath: filePath,
            name: _fileName(filePath),
            time: Qt.formatDateTime(new Date(), "hh:mm:ss"),
            capturedAt: capturedAt,
            gpsLocation: _vehicleLocationLabel(),
            altitude: _vehicleAltitudeLabel(),
            heading: metadata.headingDegrees === null ? qsTr("--") : Math.round(metadata.headingDegrees) + "\u00b0",
            droneId: _droneIdLabel(),
            missionName: _missionName && _missionName.length > 0 ? _missionName : QGroundControl.loadGlobalSetting("loadpage", "loadpage"),
            localCopy: filePath && filePath.length > 0,
            droneCopy: droneCopy,
            note: note,
            metadataPath: metadataPath,
            tag: _lastMediaTag,
            missionProof: _missionProofMode,
            exported: false
        })
        _lastMediaTag = ""
        libraryRefreshTimer.remainingTicks = 6
        libraryRefreshTimer.restart()
        _refreshMediaStorage()
    }

    function _addMediaTag(tag) {
        var now = new Date()
        _lastMediaTag = tag
        mediaLibraryModel.insert(0, {
            kind: "tag",
            filePath: "",
            name: tag + qsTr(" marker"),
            time: Qt.formatDateTime(now, "hh:mm:ss"),
            capturedAt: Qt.formatDateTime(now, "yyyy-MM-dd hh:mm:ss"),
            gpsLocation: _vehicleLocationLabel(),
            altitude: _vehicleAltitudeLabel(),
            heading: isNaN(_vehicleHeadingDegrees()) ? qsTr("--") : Math.round(_vehicleHeadingDegrees()) + "\u00b0",
            droneId: _droneIdLabel(),
            missionName: _missionName && _missionName.length > 0 ? _missionName : QGroundControl.loadGlobalSetting("loadpage", "loadpage"),
            localCopy: false,
            droneCopy: false,
            note: qsTr("Flight marker added during live view"),
            metadataPath: "",
            tag: tag,
            missionProof: tag === qsTr("Issue") || tag === qsTr("Crack") || tag === qsTr("Hotspot"),
            exported: false
        })
        _libraryOpen = true
        _toast(qsTr("Tagged: ") + tag)
    }

    function _setReviewTag(tag) {
        if (_mediaReviewIndex < 0 || _mediaReviewIndex >= mediaLibraryModel.count) {
            _addMediaTag(tag)
            return
        }
        mediaLibraryModel.setProperty(_mediaReviewIndex, "tag", tag)
        mediaLibraryModel.setProperty(_mediaReviewIndex, "note", qsTr("Tagged during review: ") + tag)
        _lastMediaTag = tag
        _toast(qsTr("Media tagged: ") + tag)
    }

    function _reviewMedia(index) {
        if (index < 0 || index >= mediaLibraryModel.count) {
            _mediaReviewIndex = -1
            return
        }
        _mediaReviewIndex = index
        _libraryOpen = true
        mediaRenameField.text = mediaLibraryModel.get(index).name
    }

    function _reviewItem() {
        return _mediaReviewIndex >= 0 && _mediaReviewIndex < mediaLibraryModel.count ? mediaLibraryModel.get(_mediaReviewIndex) : null
    }

    function _renameReviewMedia(newName) {
        if (_mediaReviewIndex < 0 || _mediaReviewIndex >= mediaLibraryModel.count || newName.length === 0) {
            return
        }
        mediaLibraryModel.setProperty(_mediaReviewIndex, "name", newName)
        _toast(qsTr("Media renamed"))
    }

    function _toggleMissionProof() {
        if (_mediaReviewIndex < 0 || _mediaReviewIndex >= mediaLibraryModel.count) {
            return
        }
        var item = mediaLibraryModel.get(_mediaReviewIndex)
        mediaLibraryModel.setProperty(_mediaReviewIndex, "missionProof", !item.missionProof)
        _toast(!item.missionProof ? qsTr("Marked as mission proof") : qsTr("Mission proof removed"))
    }

    function _exportReviewMedia() {
        if (_mediaReviewIndex < 0 || _mediaReviewIndex >= mediaLibraryModel.count) {
            return
        }
        var item = mediaLibraryModel.get(_mediaReviewIndex)
        if (!item.filePath || item.filePath.length === 0) {
            _toast(qsTr("No local media file to export"))
            return
        }
        _pendingExportIndex = _mediaReviewIndex
        mediaExportFolderDialog.openForLoad()
    }

    function _exportReviewMediaToFolder(folderPath) {
        if (_pendingExportIndex < 0 || _pendingExportIndex >= mediaLibraryModel.count) {
            return
        }
        var item = mediaLibraryModel.get(_pendingExportIndex)
        if (item.missionProof) {
            var proofPath = mediaFileController.createProofPackage(item.filePath, _proofManifestForItem(item), folderPath, _proofPackageBaseName(item))
            if (proofPath.length > 0) {
                mediaLibraryModel.setProperty(_pendingExportIndex, "exported", true)
                _lastProofPackagePath = proofPath
                mediaFileController.openFolder(folderPath)
                _logCameraCommand(qsTr("Proof package export"), qsTr("ZIP created"))
            } else {
                _toast(qsTr("Unable to export proof package"))
            }
            _pendingExportIndex = -1
            return
        }
        if (mediaFileController.copyFileToFolder(item.filePath, folderPath)) {
            if (item.metadataPath && item.metadataPath.length > 0 && mediaFileController.fileExists(item.metadataPath)) {
                mediaFileController.copyFileToFolder(item.metadataPath, folderPath)
            }
            mediaLibraryModel.setProperty(_pendingExportIndex, "exported", true)
            mediaFileController.openFolder(folderPath)
            _toast(qsTr("Media exported"))
        } else {
            _toast(qsTr("Unable to export media"))
        }
        _pendingExportIndex = -1
    }

    function _proofPackageBaseName(item) {
        var baseName = item.name && item.name.length > 0 ? item.name : _fileName(item.filePath)
        return "proof_" + baseName.replace(/\.[^/.]+$/, "").replace(/[^A-Za-z0-9_.-]/g, "_")
    }

    function _proofManifestForItem(item) {
        var manifest = {
            media: item.name,
            fileName: _fileName(item.filePath),
            kind: item.kind,
            capturedAt: item.capturedAt,
            gpsLocation: item.gpsLocation,
            altitude: item.altitude,
            heading: item.heading,
            droneId: item.droneId,
            missionName: item.missionName,
            metadataFile: item.metadataPath,
            tag: item.tag,
            note: item.note,
            missionProof: item.missionProof,
            exportedAt: Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss"),
            source: _cameraSourceLabel(),
            backend: _lastCameraBackend
        }
        return JSON.stringify(manifest, null, 2)
    }

    function _deleteReviewMedia() {
        if (_mediaReviewIndex < 0 || _mediaReviewIndex >= mediaLibraryModel.count) {
            return
        }
        var item = mediaLibraryModel.get(_mediaReviewIndex)
        if (item.localCopy && item.filePath && item.filePath.length > 0 && mediaFileController.fileExists(item.filePath)) {
            mediaFileController.deleteFile(item.filePath)
        }
        if (item.metadataPath && item.metadataPath.length > 0 && mediaFileController.fileExists(item.metadataPath)) {
            mediaFileController.deleteFile(item.metadataPath)
        }
        mediaLibraryModel.remove(_mediaReviewIndex)
        _mediaReviewIndex = -1
        _refreshMediaStorage()
        _toast(qsTr("Media removed from library"))
    }

    function _captureModeLabel() {
        switch (_captureMode) {
        case "burst":
            return qsTr("Burst")
        case "interval":
            return _intervalActive ? qsTr("Interval On") : qsTr("Interval")
        case "timer":
            return qsTr("Timer")
        case "panorama":
            return qsTr("Panorama")
        case "orbit":
            return _orbitShotArmed ? qsTr("Orbit Armed") : qsTr("Orbit")
        default:
            return qsTr("Single")
        }
    }

    function _setCaptureMode(mode) {
        _captureMode = mode
        QGroundControl.saveGlobalSetting("Camera.CaptureMode", mode)
        if (mode !== "interval") {
            _intervalActive = false
            intervalCaptureTimer.stop()
        }
        if (mode !== "orbit") {
            _orbitShotArmed = false
        }
        _timerRemaining = 0
        _burstRemaining = 0
        _panoramaRemaining = 0
        burstCaptureTimer.stop()
        timerCaptureTimer.stop()
        panoramaCaptureTimer.stop()
    }

    function _takeSinglePhoto() {
        if (_photoCaptureGuard) {
            return
        }
        _photoCaptureGuard = true
        photoCaptureGuardTimer.restart()

        if (cameraLoader.item) {
            var uvcPhotoPath = _photoFilePath()
            if (!cameraLoader.visible || cameraLoader.width <= 0 || cameraLoader.height <= 0) {
                _toast(qsTr("Unable to save photo"))
                _logCameraCommand(qsTr("Photo capture"), qsTr("Unavailable"))
                return
            }
            _logCameraCommand(qsTr("Photo capture"), qsTr("Local camera"))
            var captureItem = _root._previewEffectsActive ? localCameraEffect : cameraLoader
            captureItem.grabToImage(function(result) {
                if (result.saveToFile(uvcPhotoPath)) {
                    _addMedia("photo", uvcPhotoPath, false, qsTr("Saved from local camera"))
                    _toast(qsTr("Photo saved locally"))
                } else {
                    _toast(qsTr("Unable to save photo"))
                }
            })
        } else if (_hasCameraControl && _camera.capturesPhotos) {
            if (!_cameraInPhotoMode) {
                _camera.setCameraModePhoto()
            }
            _camera.takePhoto()
            if (QGroundControl.videoManager.hasVideo) {
                var mavPhotoPath = _photoFilePath()
                QGroundControl.videoManager.grabImage(mavPhotoPath)
                _addMedia("photo", mavPhotoPath, true, qsTr("Drone capture requested, local stream snapshot saved"))
            } else {
                _addMedia("photo", "", true, qsTr("Drone capture requested"))
            }
            _logCameraCommand(qsTr("Photo capture"), qsTr("MAVLink camera"))
        } else if (QGroundControl.videoManager.hasVideo) {
            var streamPhotoPath = _photoFilePath()
            QGroundControl.videoManager.grabImage(streamPhotoPath)
            _addMedia("photo", streamPhotoPath, false, qsTr("Saved from video stream"))
            _logCameraCommand(qsTr("Photo capture"), qsTr("Video stream snapshot"))
        } else {
            _logCameraCommand(qsTr("Photo capture"), qsTr("Unavailable"))
        }
    }

    function _capturePhoto() {
        switch (_captureMode) {
        case "burst":
            _burstRemaining = Math.max(1, _burstCount)
            _toast(qsTr("Burst capture started"))
            burstCaptureTimer.restart()
            return
        case "interval":
            _intervalActive = !_intervalActive
            if (_intervalActive) {
                intervalCaptureTimer.restart()
                _toast(qsTr("Interval capture started"))
                _takeSinglePhoto()
            } else {
                intervalCaptureTimer.stop()
                _toast(qsTr("Interval capture stopped"))
            }
            return
        case "timer":
            _timerRemaining = Math.max(1, _timerSeconds)
            timerCaptureTimer.restart()
            _toast(qsTr("Timed photo started"))
            return
        case "panorama":
            _panoramaRemaining = 5
            _safeFrame = true
            _centerMark = true
            _toast(qsTr("Panorama capture started"))
            panoramaCaptureTimer.restart()
            return
        case "orbit":
            _orbitShotArmed = !_orbitShotArmed
            _intervalActive = _orbitShotArmed
            if (_orbitShotArmed) {
                _intervalSeconds = Math.max(3, _intervalSeconds)
                _safeFrame = true
                _centerMark = true
                intervalCaptureTimer.restart()
                _toast(qsTr("Orbit shot preset armed"))
                _takeSinglePhoto()
            } else {
                intervalCaptureTimer.stop()
                _toast(qsTr("Orbit shot preset stopped"))
            }
            return
        default:
            _takeSinglePhoto()
        }
    }

    function _toggleRecording() {
        _refreshRecordingProfileSettings()
        if (cameraLoader.item && cameraLoader.item.startRecording) {
            if (cameraLoader.item.recording) {
                cameraLoader.item.stopRecording()
                _logCameraCommand(qsTr("Stop recording"), qsTr("Local camera"))
            } else {
                _pendingRecordingFile = _localVideoFilePath(_videoBaseName())
                _recordSeconds = 0
                if (cameraLoader.item.startRecording(_pendingRecordingFile)) {
                    _logCameraCommand(qsTr("Start recording"), qsTr("Local camera"))
                } else {
                    _pendingRecordingFile = ""
                    _logCameraCommand(qsTr("Start recording"), qsTr("Unavailable"))
                }
            }
        } else if (_hasCameraControl && _camera.capturesVideo) {
            if (!_cameraInVideoMode) {
                _camera.setCameraModeVideo()
            }
            if (_videoCaptureIdle) {
                _recordSeconds = 0
                var mavBaseName = _videoBaseName()
                _pendingRecordingFile = QGroundControl.videoManager.hasVideo ? _videoFilePath(mavBaseName) : ""
                if (_pendingRecordingFile.length > 0) {
                    QGroundControl.videoManager.startRecording(mavBaseName)
                }
            } else {
                if (QGroundControl.videoManager.recording) {
                    QGroundControl.videoManager.stopRecording()
                    _addMedia("video", _pendingRecordingFile, true, qsTr("Drone recording stopped, local stream recording saved"))
                    _pendingRecordingFile = ""
                }
            }
            _camera.toggleVideoRecording()
            _logCameraCommand(_videoCaptureIdle ? qsTr("Start recording") : qsTr("Stop recording"), qsTr("MAVLink camera"))
        } else if (QGroundControl.videoManager.hasVideo) {
            if (QGroundControl.videoManager.recording) {
                QGroundControl.videoManager.stopRecording()
                if (_pendingRecordingFile.length > 0) {
                    _addMedia("video", _pendingRecordingFile, false, qsTr("Saved from video stream"))
                }
                _pendingRecordingFile = ""
                _logCameraCommand(qsTr("Stop recording"), qsTr("Video stream recorder"))
            } else {
                _recordSeconds = 0
                var streamBaseName = _videoBaseName()
                _pendingRecordingFile = _videoFilePath(streamBaseName)
                QGroundControl.videoManager.startRecording(streamBaseName)
                _logCameraCommand(qsTr("Start recording"), qsTr("Video stream recorder"))
            }
        } else {
            _logCameraCommand(qsTr("Start recording"), qsTr("Unavailable"))
        }
    }

    function _recordingText() {
        if (_recordingActive) {
            return _recordingPaused ? qsTr("Paused ") + _formatRecordSeconds(_recordSeconds) : _formatRecordSeconds(_recordSeconds)
        }
        return qsTr("Ready")
    }

    function _recordingStateLabel() {
        if (_recordingPaused) {
            return qsTr("Paused")
        }
        if (_recordingActive) {
            return qsTr("REC")
        }
        return qsTr("Ready")
    }

    function _cameraSourceLabel() {
        return (_localCameraAvailable || QGroundControl.videoManager.isUvc) ? qsTr("Local Camera") : qsTr("Drone Stream")
    }

    function _liveStateLabel() {
        if (_recordingPaused) {
            return qsTr("Paused")
        }
        if (_recordingActive) {
            return qsTr("Recording")
        }
        return QGroundControl.videoManager.decoding || _localCameraAvailable ? qsTr("Live") : qsTr("Idle")
    }

    function _canPauseRecording() {
        return cameraLoader.item && cameraLoader.item.pauseRecording && cameraLoader.item.resumeRecording
    }

    function _toggleRecordingPause() {
        if (!_recordingActive || !_canPauseRecording()) {
            return
        }
        if (_recordingPaused) {
            if (cameraLoader.item.resumeRecording()) {
                _toast(qsTr("Recording resumed"))
            }
        } else if (cameraLoader.item.pauseRecording()) {
            _toast(qsTr("Recording paused"))
        }
    }

    function _endRecording() {
        if (_recordingActive) {
            _toggleRecording()
        }
    }

    function _formatRecordSeconds(totalSeconds) {
        var hours = Math.floor(totalSeconds / 3600)
        var minutes = Math.floor((totalSeconds % 3600) / 60)
        var seconds = totalSeconds % 60
        return ("0" + hours).slice(-2) + ":" + ("0" + minutes).slice(-2) + ":" + ("0" + seconds).slice(-2)
    }

    Timer {
        id: photoCaptureGuardTimer
        interval: 900
        repeat: false
        onTriggered: {
            _root._photoCaptureGuard = false
            _root._libraryRefreshTick++
        }
    }

    Timer {
        id: burstCaptureTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (_root._burstRemaining <= 0) {
                stop()
                return
            }
            _root._takeSinglePhoto()
            _root._burstRemaining--
            if (_root._burstRemaining <= 0) {
                stop()
                _root._toast(qsTr("Burst capture finished"))
            }
        }
    }

    Timer {
        id: intervalCaptureTimer
        interval: Math.max(2, _root._intervalSeconds) * 1000
        repeat: true
        onTriggered: {
            if (_root._intervalActive) {
                _root._takeSinglePhoto()
            } else {
                stop()
            }
        }
    }

    Timer {
        id: timerCaptureTimer
        interval: 1000
        repeat: true
        onTriggered: {
            _root._timerRemaining--
            if (_root._timerRemaining <= 0) {
                stop()
                _root._takeSinglePhoto()
            }
        }
    }

    Timer {
        id: panoramaCaptureTimer
        interval: 1300
        repeat: true
        onTriggered: {
            if (_root._panoramaRemaining <= 0) {
                stop()
                return
            }
            _root._takeSinglePhoto()
            _root._panoramaRemaining--
            if (_root._panoramaRemaining <= 0) {
                stop()
                _root._toast(qsTr("Panorama capture finished"))
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: _root._recordingActive && !_root._recordingPaused
        onTriggered: _root._recordSeconds++
    }

    Timer {
        id: tapFocusHideTimer
        interval: 1200
        repeat: false
        onTriggered: _root._tapFocusVisible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: _root._showCameraStudio
        onTriggered: _root._recordingHealthTick++
    }

    on_RecordingActiveChanged: {
        if (_recordingActive) {
            _recordSeconds = 0
        }
    }

    PipState {
        id:         videoPipState
        pipView:    _root.pipView
        isDark:     true

        onWindowAboutToOpen: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onWindowAboutToClose: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onStateChanged: {
            if (pipState.state !== pipState.fullState) {
                QGroundControl.videoManager.fullScreen = false
            }
        }
    }

    Timer {
        id:           videoStartDelay
        interval:     2000;
        running:      false
        repeat:       false
        onTriggered:  QGroundControl.videoManager.startVideo()
    }

    //-- Video Streaming
    FlightDisplayViewVideo {
        id:             videoStreaming
        anchors.fill:   parent
        useSmallFont:   _root.pipState.state !== _root.pipState.fullState
        visible:        !_root._localCameraAvailable && (QGroundControl.videoManager.isStreamSource || (_root.aiDetectionEnabled && !QGroundControl.videoManager.isUvc))
        scale:          _root._digitalZoom
        transformOrigin: Item.Center
        layer.enabled:  _root._previewEffectsActive
        layer.effect: MultiEffect {
            brightness: _root._effectiveBrightness
            contrast:   _root._effectiveContrast
            saturation: Math.max(-1.0, Math.min(1.0, _root._effectiveSaturation))
        }
    }
    //-- UVC Video (USB Camera or Video Device)
    Loader {
        id:             cameraLoader
        anchors.fill:   parent
        visible:        _root._localCameraAvailable || QGroundControl.videoManager.isUvc
        source:         (_root._localCameraAvailable || QGroundControl.videoManager.uvcEnabled) ? "qrc:/qml/FlightDisplayViewUVC.qml" : "qrc:/qml/FlightDisplayViewDummy.qml"
        scale:          _root._digitalZoom
        transformOrigin: Item.Center
        onLoaded: {
            if (item && item.recordingSaved) {
                item.recordingSaved.connect(function(filePath) {
                    if (filePath && filePath.length > 0) {
                        _addMedia("video", filePath, false, qsTr("Saved from local camera"))
                    }
                    _pendingRecordingFile = ""
                    _toast(qsTr("Local recording saved"))
                })
            }
            if (item && item.recordingFailed) {
                item.recordingFailed.connect(function(filePath) {
                    _pendingRecordingFile = ""
                    _toast(qsTr("Unable to save recording"))
                })
            }
        }
        opacity:        _root._previewEffectsActive ? 0.001 : 1.0
    }

    MultiEffect {
        id:             localCameraEffect
        anchors.fill:   cameraLoader
        source:         cameraLoader
        visible:        cameraLoader.visible && _root._previewEffectsActive
        scale:          cameraLoader.scale
        transformOrigin: Item.Center
        brightness:     _root._effectiveBrightness
        contrast:       _root._effectiveContrast
        saturation:     Math.max(-1.0, Math.min(1.0, _root._effectiveSaturation))
    }

    Rectangle {
        anchors.fill: parent
        color: _root._profileTint
        visible: _root._previewEffectsActive && color.a > 0
        z: 2
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.0, 0.20, 0.55, 0.12)
        visible: _root._videoIsFull && _root._falseColor
        z: 3
    }

    AIDetectionOverlay {
        id: aiDetectionOverlay
        anchors.fill: parent
        detectionEnabled: _root._videoIsFull && _root.aiDetectionEnabled
        videoActive: QGroundControl.videoManager.decoding
        videoItem: videoStreaming
        z: 50
    }

    Connections {
        target: aiDetectionOverlay
        function onDetectionsChanged() {
            _root._handleAiDetections(aiDetectionOverlay.detections)
        }
    }

    QGCLabel {
        text: qsTr("Double-click to exit full screen")
        font.pointSize: ScreenTools.largeFontPointSize
        visible: QGroundControl.videoManager.fullScreen && flyViewVideoMouseArea.containsMouse
        anchors.centerIn: parent

        onVisibleChanged: {
            if (visible) {
                labelAnimation.start()
            }
        }

        PropertyAnimation on opacity {
            id: labelAnimation
            duration: 10000
            from: 1.0
            to: 0.0
            easing.type: Easing.InExpo
        }
    }

    OnScreenGimbalController {
        id:                      onScreenGimbalController
        anchors.fill:            parent
        screenX:                 flyViewVideoMouseArea.mouseX
        screenY:                 flyViewVideoMouseArea.mouseY
        cameraTrackingEnabled:   videoStreaming._camera && videoStreaming._camera.trackingEnabled
    }

    MouseArea {
        id:                         flyViewVideoMouseArea
        anchors.fill:               parent
        enabled:                    pipState.state === pipState.fullState
        hoverEnabled:               true

        property double x0:         0
        property double x1:         0
        property double y0:         0
        property double y1:         0
        property double offset_x:   0
        property double offset_y:   0
        property double radius:     20
        property var trackingROI:   null
        property var trackingStatus: trackingStatusComponent.createObject(flyViewVideoMouseArea, {})

        onClicked: (mouse) => {
            _root._handleVideoTap(mouse.x, mouse.y)
            onScreenGimbalController.clickControl()
        }
        onDoubleClicked: QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen

        onPressed:(mouse) => {
            onScreenGimbalController.pressControl()

            _track_rec_x = mouse.x
            _track_rec_y = mouse.y

            //create a new rectangle at the wanted position
            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    trackingROI = trackingROIComponent.createObject(flyViewVideoMouseArea, {
                        "x": mouse.x,
                        "y": mouse.y
                    });
                }
            }
        }
        onPositionChanged: (mouse) => {
            //on move, update the width of rectangle
            if (trackingROI !== null) {
                if (mouse.x < trackingROI.x) {
                    trackingROI.x = mouse.x
                    trackingROI.width = Math.abs(mouse.x - _track_rec_x)
                } else {
                    trackingROI.width = Math.abs(mouse.x - trackingROI.x)
                }
                if (mouse.y < trackingROI.y) {
                    trackingROI.y = mouse.y
                    trackingROI.height = Math.abs(mouse.y - _track_rec_y)
                } else {
                    trackingROI.height = Math.abs(mouse.y - trackingROI.y)
                }
            }
        }
        onReleased: (mouse) => {
            onScreenGimbalController.releaseControl()

            //if there is already a selection, delete it
            if (trackingROI !== null) {
                trackingROI.destroy();
            }

            if(videoStreaming._camera) {
                if (videoStreaming._camera.trackingEnabled) {
                    // order coordinates --> top/left and bottom/right
                    x0 = Math.min(_track_rec_x, mouse.x)
                    x1 = Math.max(_track_rec_x, mouse.x)
                    y0 = Math.min(_track_rec_y, mouse.y)
                    y1 = Math.max(_track_rec_y, mouse.y)

                    //calculate offset between video stream rect and background (black stripes)
                    offset_x = (parent.width - videoStreaming.getWidth()) / 2
                    offset_y = (parent.height - videoStreaming.getHeight()) / 2

                    //convert absolute coords in background to absolute video stream coords
                    x0 = x0 - offset_x
                    x1 = x1 - offset_x
                    y0 = y0 - offset_y
                    y1 = y1 - offset_y

                    //convert absolute to relative coordinates and limit range to 0...1
                    x0 = Math.max(Math.min(x0 / videoStreaming.getWidth(), 1.0), 0.0)
                    x1 = Math.max(Math.min(x1 / videoStreaming.getWidth(), 1.0), 0.0)
                    y0 = Math.max(Math.min(y0 / videoStreaming.getHeight(), 1.0), 0.0)
                    y1 = Math.max(Math.min(y1 / videoStreaming.getHeight(), 1.0), 0.0)

                    //use point message if rectangle is very small
                    if (Math.abs(_track_rec_x - mouse.x) < 10 && Math.abs(_track_rec_y - mouse.y) < 10) {
                        var pt  = Qt.point(x0, y0)
                        videoStreaming._camera.startTracking(pt, radius / videoStreaming.getWidth())
                    } else {
                        var rec = Qt.rect(x0, y0, x1 - x0, y1 - y0)
                        videoStreaming._camera.startTracking(rec)
                    }
                    _track_rec_x = 0
                    _track_rec_y = 0
                }
            }
        }

        Component {
            id: trackingROIComponent

            Rectangle {
                color:              Qt.rgba(0.1,0.85,0.1,0.25)
                border.color:       "green"
                border.width:       1
            }
        }

        Component {
            id: trackingStatusComponent

            Rectangle {
                color:              "transparent"
                border.color:       "red"
                border.width:       5
                radius:             5
            }
        }

        Timer {
            id: trackingStatusTimer
            interval:               50
            repeat:                 true
            running:                true
            onTriggered: {
                if (videoStreaming._camera) {
                    if (videoStreaming._camera.trackingEnabled && videoStreaming._camera.trackingImageStatus) {
                        var margin_hor = (parent.parent.width - videoStreaming.getWidth()) / 2
                        var margin_ver = (parent.parent.height - videoStreaming.getHeight()) / 2
                        var left = margin_hor + videoStreaming.getWidth() * videoStreaming._camera.trackingImageRect.left
                        var top = margin_ver + videoStreaming.getHeight() * videoStreaming._camera.trackingImageRect.top
                        var right = margin_hor + videoStreaming.getWidth() * videoStreaming._camera.trackingImageRect.right
                        var bottom = margin_ver + !isNaN(videoStreaming._camera.trackingImageRect.bottom) ? videoStreaming.getHeight() * videoStreaming._camera.trackingImageRect.bottom : top + (right - left)
                        var width = right - left
                        var height = bottom - top

                        flyViewVideoMouseArea.trackingStatus.x = left
                        flyViewVideoMouseArea.trackingStatus.y = top
                        flyViewVideoMouseArea.trackingStatus.width = width
                        flyViewVideoMouseArea.trackingStatus.height = height
                    } else {
                        flyViewVideoMouseArea.trackingStatus.x = 0
                        flyViewVideoMouseArea.trackingStatus.y = 0
                        flyViewVideoMouseArea.trackingStatus.width = 0
                        flyViewVideoMouseArea.trackingStatus.height = 0
                    }
                }
            }
        }
    }

    Item {
        id: cameraCompositionOverlay
        anchors.fill: parent
        visible: _root._showCameraStudio
        z: 60

        Item {
            anchors.fill: parent
            visible: _root._compositionGrid && _root._gridStyle === "Thirds"

            Rectangle { x: parent.width / 3; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.30) }
            Rectangle { x: parent.width * 2 / 3; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.30) }
            Rectangle { y: parent.height / 3; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.30) }
            Rectangle { y: parent.height * 2 / 3; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.30) }
        }

        Item {
            anchors.fill: parent
            visible: _root._compositionGrid && _root._gridStyle === "X"

            Rectangle { anchors.centerIn: parent; width: Math.sqrt(parent.width * parent.width + parent.height * parent.height); height: 1; rotation: Math.atan(parent.height / parent.width) * 180 / Math.PI; color: Qt.rgba(1, 1, 1, 0.30) }
            Rectangle { anchors.centerIn: parent; width: Math.sqrt(parent.width * parent.width + parent.height * parent.height); height: 1; rotation: -Math.atan(parent.height / parent.width) * 180 / Math.PI; color: Qt.rgba(1, 1, 1, 0.30) }
        }

        Grid {
            anchors.centerIn: parent
            columns: 3
            rows: 3
            spacing: Math.min(parent.width, parent.height) * 0.18
            visible: _root._compositionGrid && _root._gridStyle === "Point"

            Repeater {
                model: 9
                Rectangle {
                    width: ScreenTools.defaultFontPixelHeight * 0.35
                    height: width
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.58)
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: _root._compositionGrid && _root._gridStyle === "Square"

            Rectangle { anchors.centerIn: parent; width: parent.width * 0.62; height: parent.height * 0.62; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.34); border.width: 1 }
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.32; height: parent.height * 0.32; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.34); border.width: 1 }
        }

        Item {
            anchors.centerIn: parent
            width: ScreenTools.defaultFontPixelHeight * 5
            height: width
            visible: _root._centerMark

            Rectangle { anchors.centerIn: parent; width: parent.width; height: 1; color: Qt.rgba(0.46, 0.90, 0.86, 0.9) }
            Rectangle { anchors.centerIn: parent; width: 1; height: parent.height; color: Qt.rgba(0.46, 0.90, 0.86, 0.9) }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.36
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Qt.rgba(0.46, 0.90, 0.86, 0.9)
                border.width: 1
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.82
            height: parent.height * 0.78
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.42)
            border.width: 1
            visible: _root._safeFrame || _root._frameGuide
        }

        Rectangle {
            id: flightMonitorStrip
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 4.8
            width: Math.min(parent.width * 0.74 * 4 / 6, ScreenTools.defaultFontPixelWidth * 98 * 4 / 6)
            height: monitorGrid.implicitHeight + ScreenTools.defaultFontPixelHeight * 0.9
            radius: ScreenTools.defaultFontPixelHeight * 0.55
            color: Qt.rgba(0, 0, 0, 0.58)
            border.color: Qt.rgba(1, 1, 1, 0.24)
            border.width: 1
            visible: _root._showCameraStudio
            z: 10

            GridLayout {
                id: monitorGrid
                anchors.centerIn: parent
                width: parent.width - ScreenTools.defaultFontPixelWidth * 1.4
                columns: 4
                columnSpacing: ScreenTools.defaultFontPixelWidth * 0.65
                rowSpacing: ScreenTools.defaultFontPixelHeight * 0.25

                Repeater {
                    model: [
                        { label: qsTr("ALT"),   value: _root._vehicleAltitudeLabel() },
                        { label: qsTr("DIST"),  value: _root._distanceFromPilotLabel() },
                        { label: qsTr("NOSE"),  value: _root._headingLabel() },
                        { label: qsTr("SPEED"), value: _root._groundSpeedLabel() }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.1
                        radius: ScreenTools.defaultFontPixelHeight * 0.35
                        color: Qt.rgba(1, 1, 1, 0.10)
                        border.color: Qt.rgba(1, 1, 1, 0.14)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.35
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: "#75E6DA"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize * 0.82
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 7.2
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 1.4
            width: Math.min(parent.width * 0.42, watermarkLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2)
            height: watermarkLabel.implicitHeight + ScreenTools.defaultFontPixelHeight
            radius: ScreenTools.defaultFontPixelHeight * 0.45
            color: Qt.rgba(0, 0, 0, 0.58)
            border.color: Qt.rgba(1, 1, 1, 0.26)
            border.width: 1
            visible: _root._watermarkMetadata

            Label {
                id: watermarkLabel
                anchors.centerIn: parent
                width: parent.width - ScreenTools.defaultFontPixelWidth
                text: _root._droneIdLabel() + qsTr(" | ") + _root._vehicleLocationLabel() + qsTr(" | Alt ") + _root._vehicleAltitudeLabel() + qsTr(" | ") + Qt.formatDateTime(new Date(), "hh:mm:ss")
                color: "white"
                font.bold: true
                font.pointSize: ScreenTools.smallFontPointSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: _root._zebraOverlay ? 42 : 0
            Rectangle {
                x: index * ScreenTools.defaultFontPixelWidth * 4 - parent.width * 0.12
                y: parent.height * 0.08
                width: 2
                height: parent.height * 0.84
                rotation: 28
                color: Qt.rgba(1, 1, 1, Math.max(0.18, Math.min(0.48, (105 - _root._zebraLevel) / 70)))
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 5
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 4.8
            width: ScreenTools.defaultFontPixelWidth * 18
            height: ScreenTools.defaultFontPixelHeight * 7.2
            radius: ScreenTools.defaultFontPixelHeight * 0.45
            color: Qt.rgba(0, 0, 0, 0.58)
            border.color: Qt.rgba(1, 1, 1, 0.28)
            border.width: 1
            visible: _root._histogramOverlay

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                spacing: ScreenTools.defaultFontPixelHeight * 0.25

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Histogram")
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    Label {
                        text: _root._overExposureLikely ? qsTr("High") : (_root._underExposureLikely ? qsTr("Low") : qsTr("OK"))
                        color: _root._overExposureLikely ? "#FFB020" : (_root._underExposureLikely ? "#75E6DA" : "#6EE7B7")
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    Repeater {
                        model: [0.24, 0.36, 0.52, 0.76, 0.58, 0.42, 0.30, 0.22, 0.18, 0.15, 0.20, 0.34, 0.48, 0.62, 0.50, 0.38]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.preferredHeight: Math.max(ScreenTools.defaultFontPixelHeight * 0.45,
                                                             parent.height * Math.max(0.12, Math.min(0.96, modelData + (_root._effectiveBrightness * 0.28) + (_root._effectiveContrast * 0.10))))
                            radius: 1
                            color: index > 12 && _root._overExposureLikely ? "#FFB020" : (index < 3 && _root._underExposureLikely ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.82))
                        }
                    }
                }
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 5.2
            spacing: ScreenTools.defaultFontPixelWidth * 0.5
            visible: _root._exposureWarnings && (_root._overExposureLikely || _root._underExposureLikely || _root._zebraOverlay)

            Rectangle {
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.1
                Layout.preferredWidth: warningLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2
                radius: ScreenTools.defaultFontPixelHeight
                color: _root._overExposureLikely ? Qt.rgba(0.90, 0.18, 0.12, 0.82) : Qt.rgba(0.08, 0.50, 0.70, 0.82)
                border.color: Qt.rgba(1, 1, 1, 0.35)
                border.width: 1

                Label {
                    id: warningLabel
                    anchors.centerIn: parent
                    text: _root._overExposureLikely ? qsTr("OVER EXPOSURE") : qsTr("UNDER EXPOSURE")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }

            Rectangle {
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.1
                Layout.preferredWidth: zebraWarningLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 2
                radius: ScreenTools.defaultFontPixelHeight
                color: Qt.rgba(0, 0, 0, 0.62)
                border.color: Qt.rgba(1, 1, 1, 0.28)
                border.width: 1
                visible: _root._zebraOverlay

                Label {
                    id: zebraWarningLabel
                    anchors.centerIn: parent
                    text: qsTr("Zebra ") + _root._zebraLevel + "%"
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 4.2
            width: smartCaptureLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 3
            height: ScreenTools.defaultFontPixelHeight * 3
            radius: ScreenTools.defaultFontPixelHeight * 1.5
            color: Qt.rgba(0, 0, 0, 0.66)
            border.color: "#75E6DA"
            border.width: 1
            visible: _root._timerRemaining > 0 || _root._burstRemaining > 0 || _root._panoramaRemaining > 0 || _root._intervalActive || _root._orbitShotArmed

            Label {
                id: smartCaptureLabel
                anchors.centerIn: parent
                text: _root._timerRemaining > 0 ? qsTr("Timer ") + _root._timerRemaining
                      : (_root._burstRemaining > 0 ? qsTr("Burst ") + _root._burstRemaining
                         : (_root._panoramaRemaining > 0 ? qsTr("Panorama ") + _root._panoramaRemaining
                            : (_root._orbitShotArmed ? qsTr("Orbit interval running") : qsTr("Interval running"))))
                color: "white"
                font.bold: true
                font.pointSize: ScreenTools.defaultFontPointSize
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 4.8
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 1.2
            width: ScreenTools.defaultFontPixelWidth * 35
            height: ScreenTools.defaultFontPixelHeight * 3.4
            radius: ScreenTools.defaultFontPixelHeight * 0.45
            color: Qt.rgba(0, 0, 0, 0.62)
            border.color: _root._recordingActive ? "#D92D20" : Qt.rgba(1, 1, 1, 0.22)
            border.width: 1
            visible: _root._showCameraStudio

            RowLayout {
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPixelHeight * 0.45
                spacing: ScreenTools.defaultFontPixelWidth * 0.8

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 0.65
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: _root._recordingActive ? "#D92D20" : (_root._cameraConnectionActive() ? "#16A085" : Qt.rgba(1, 1, 1, 0.42))
                }

                Label {
                    Layout.fillWidth: true
                    text: _root._liveStatusText()
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: pilotWarningText.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.2
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.7
                    radius: ScreenTools.defaultFontPixelHeight * 0.85
                    color: Qt.rgba(0.85, 0.18, 0.12, 0.86)
                    visible: _root._pilotWarningLabel().length > 0

                    Label {
                        id: pilotWarningText
                        anchors.centerIn: parent
                        text: _root._pilotWarningLabel()
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                    }
                }
            }
        }

        Repeater {
            model: _root._focusPeaking ? 10 : 0
            Rectangle {
                x: parent.width * (0.18 + (index % 5) * 0.16)
                y: parent.height * (0.24 + Math.floor(index / 5) * 0.36)
                width: ScreenTools.defaultFontPixelWidth * 4.2
                height: 2
                color: "#75E6DA"
                opacity: 0.72
            }
        }

        Item {
            id: tapFocusIndicator
            x: _root._tapFocusX - width / 2
            y: _root._tapFocusY - height / 2
            width: ScreenTools.defaultFontPixelHeight * 4.2
            height: width
            visible: _root._tapFocusVisible
            opacity: visible ? 1.0 : 0.0

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: width / 2
                color: "transparent"
                border.color: "#75E6DA"
                border.width: 2
            }

            Rectangle { anchors.centerIn: parent; width: parent.width * 0.72; height: 1; color: "#75E6DA" }
            Rectangle { anchors.centerIn: parent; width: 1; height: parent.height * 0.72; color: "#75E6DA" }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.25
                text: (_root._tapTrackEnabled && videoStreaming._camera && videoStreaming._camera.hasTracking) ? qsTr("TRACK") : qsTr("FOCUS")
                color: "#75E6DA"
                font.bold: true
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }
    }

    Rectangle {
        id: cameraShutterDock
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: _root._cameraDockUnit * 0.65
        width: _root._cameraDockUnit * 4.6
        height: Math.min(parent.height - _root._cameraDockUnit * 5.2,
                         dockColumn.implicitHeight + _root._cameraDockUnit * 1.1)
        radius: _root._cameraDockUnit * 0.75
        color: Qt.rgba(0, 0, 0, 0.48)
        border.color: Qt.rgba(1, 1, 1, 0.22)
        border.width: 1
        clip: true
        visible: _root._showCameraStudio
        z: 120

        ColumnLayout {
            id: dockColumn
            anchors.fill: parent
            anchors.margins: _root._cameraDockUnit * 0.55
            spacing: _root._cameraDockUnit * 0.45

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: dockPhotoMouse.containsMouse ? _root._cameraDockButtonHoverColor : _root._cameraDockButtonColor
                border.color: _root._photoCaptureBusy ? _root._cameraDockButtonActiveBorderColor : _root._cameraDockIconColor
                border.width: 2
                opacity: _root._photoCaptureGuard ? 0.55 : 1.0

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: _root._cameraDockIconSize
                    height: width
                    source: "/qmlimages/camera_photo.svg"
                    color: _root._cameraDockIconColor
                }

                MouseArea {
                    id: dockPhotoMouse
                    anchors.fill: parent
                    enabled: !_root._photoCaptureGuard
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._capturePhoto()
                }

                ToolTip.visible: dockPhotoMouse.containsMouse
                ToolTip.text: qsTr("Capture: ") + _root._captureModeLabel()
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: Layout.preferredWidth
                radius: _root._recordingActive ? _root._cameraDockUnit * 0.45 : width / 2
                color: dockVideoMouse.containsMouse ? _root._cameraDockButtonHoverColor : _root._cameraDockButtonColor
                border.color: _root._recordingActive ? _root._cameraDockButtonActiveBorderColor : _root._cameraDockIconColor
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * (_root._recordingActive ? 0.44 : 0.50)
                    height: width
                    radius: _root._recordingActive ? width * 0.12 : width / 2
                    color: _root._cameraDockIconColor
                    Behavior on width { NumberAnimation { duration: 180 } }
                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                MouseArea {
                    id: dockVideoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._toggleRecording()
                }

                ToolTip.visible: dockVideoMouse.containsMouse
                ToolTip.text: _root._recordingActive ? qsTr("End recording") : qsTr("Record video")
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: _root._cameraDockUnit * 3.2
                radius: _root._cameraDockUnit * 0.45
                color: _root._recordingActive ? Qt.rgba(0.85, 0.18, 0.12, 0.34) : Qt.rgba(1, 1, 1, 0.10)
                border.color: _root._recordingActive ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.20)
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - _root._cameraDockUnit * 0.55
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: _root._recordingStateLabel()
                        color: _root._recordingActive ? "#FFB020" : "white"
                        font.bold: true
                        font.pointSize: _root._cameraDockSmallPointSize
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        text: _root._recordingActive ? _root._formatRecordSeconds(_root._recordSeconds) : qsTr("--")
                        color: "white"
                        font.bold: true
                        font.pointSize: _root._cameraDockDefaultPointSize
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: _root._cameraDockUnit * 2
                radius: _root._cameraDockUnit * 0.35
                visible: _root._recordingActive && _root._canPauseRecording()
                color: dockPauseMouse.containsMouse ? "#FFB020" : Qt.rgba(1, 1, 1, 0.14)
                border.color: Qt.rgba(1, 1, 1, 0.45)
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: _root._recordingPaused ? qsTr("Resume") : qsTr("Pause")
                    color: "white"
                    font.bold: true
                    font.pointSize: _root._cameraDockSmallPointSize
                }

                MouseArea {
                    id: dockPauseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._toggleRecordingPause()
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: _root._cameraDockUnit * 2
                radius: _root._cameraDockUnit * 0.35
                visible: _root._recordingActive
                color: dockEndMouse.containsMouse ? "#B42318" : "#D92D20"
                border.color: "white"
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: qsTr("End")
                    color: "white"
                    font.bold: true
                    font.pointSize: _root._cameraDockSmallPointSize
                }

                MouseArea {
                    id: dockEndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._endRecording()
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: dockSettingsMouse.containsMouse ? _root._cameraDockButtonHoverColor : _root._cameraDockButtonColor
                border.color: _root._studioPanelOpen ? _root._cameraDockButtonActiveBorderColor : _root._cameraDockIconColor
                border.width: _root._studioPanelOpen ? 2 : 1

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: _root._cameraDockIconSize
                    height: width
                    source: "/res/gear-black.svg"
                    color: _root._cameraDockIconColor
                }

                MouseArea {
                    id: dockSettingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._studioPanelOpen = !_root._studioPanelOpen
                }

                ToolTip.visible: dockSettingsMouse.containsMouse
                ToolTip.text: qsTr("Camera settings")
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: _root._cameraDockButtonSize
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: libraryMouse.containsMouse ? _root._cameraDockButtonHoverColor : _root._cameraDockButtonColor
                border.color: _root._libraryOpen ? _root._cameraDockButtonActiveBorderColor : _root._cameraDockIconColor
                border.width: _root._libraryOpen ? 2 : 1

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: _root._cameraDockIconSize
                    height: width
                    source: "qrc:/InstrumentValueIcons/photo.svg"
                    color: _root._cameraDockIconColor
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: _root._cameraDockUnit * 1.1
                    height: width
                    radius: width / 2
                    color: "#F39C12"
                    visible: mediaLibraryModel.count > 0

                    Label {
                        anchors.centerIn: parent
                        text: mediaLibraryModel.count
                        color: "white"
                        font.bold: true
                        font.pointSize: _root._cameraDockSmallPointSize * 0.8
                    }
                }

                MouseArea {
                    id: libraryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._libraryOpen = !_root._libraryOpen
                }

                ToolTip.visible: libraryMouse.containsMouse
                ToolTip.text: qsTr("Media library")
            }

        }
    }

    Rectangle {
        id: mediaLibraryPopup
        anchors.right: cameraShutterDock.left
        anchors.bottom: cameraShutterDock.bottom
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.8
        width: Math.min(parent.width * 0.46, ScreenTools.defaultFontPixelWidth * 54)
        height: Math.min(parent.height * 0.48, ScreenTools.defaultFontPixelHeight * 34)
        radius: ScreenTools.defaultFontPixelHeight * 0.8
        color: Qt.rgba(0, 0, 0, 0.88)
        border.color: Qt.rgba(1, 1, 1, 0.35)
        border.width: 1
        visible: _root._showCameraStudio && _root._libraryOpen
        z: 121
        onVisibleChanged: {
            if (visible) {
                _root._pruneMissingLocalMedia()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.8
            spacing: ScreenTools.defaultFontPixelHeight * 0.6

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Media Library")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize
                }

                Label {
                    text: mediaLibraryModel.count + qsTr(" items")
                    color: "#75E6DA"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                radius: ScreenTools.defaultFontPixelHeight * 0.35
                color: _root._storageWarningActive() ? Qt.rgba(0.95, 0.62, 0.05, 0.20) : Qt.rgba(1, 1, 1, 0.08)
                border.color: _root._storageWarningActive() ? "#F39C12" : Qt.rgba(1, 1, 1, 0.14)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.8
                    anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.8

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Storage")
                        color: Qt.rgba(1, 1, 1, 0.72)
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    Label {
                        text: _root._formatBytes(_root._mediaStorageBytes)
                        color: _root._storageWarningActive() ? "#F39C12" : "#75E6DA"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: qsTr("No media captured in this session.")
                color: Qt.rgba(1, 1, 1, 0.72)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: mediaLibraryModel.count === 0
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: mediaLibraryModel
                spacing: ScreenTools.defaultFontPixelHeight * 0.45
                visible: mediaLibraryModel.count > 0

                delegate: Rectangle {
                    id: mediaDelegate
                    width: ListView.view.width
                    height: ScreenTools.defaultFontPixelHeight * 8.4
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: mediaTileMouse.containsMouse || _root._mediaReviewIndex === index ? Qt.rgba(0.09, 0.63, 0.52, 0.22) : Qt.rgba(1, 1, 1, 0.10)
                    border.color: _root._mediaReviewIndex === index ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelWidth * 0.8

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 7
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: Qt.rgba(0, 0, 0, 0.38)
                            clip: true

                            Image {
                                id: mediaThumbImage
                                anchors.fill: parent
                                source: kind === "photo" && filePath && filePath.length > 0 ? (_root._fileUrl(filePath) + "?v=" + _root._libraryRefreshTick) : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: kind === "photo" && filePath && filePath.length > 0
                                cache: false
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: kind !== "photo" || mediaThumbImage.status === Image.Error || (kind === "photo" && mediaThumbImage.status === Image.Null)
                                color: kind === "tag" ? "#16A085" : (kind === "photo" ? Qt.rgba(0.95, 0.62, 0.05, 0.92) : "#D92D20")

                                QGCColoredImage {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.46
                                    height: width
                                    source: _root._mediaIcon(kind)
                                    color: "white"
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: ScreenTools.defaultFontPixelHeight * 1.5
                                color: Qt.rgba(0, 0, 0, 0.52)

                                Label {
                                    anchors.centerIn: parent
                                    text: _root._mediaTypeLabel(kind)
                                    color: "white"
                                    font.bold: true
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Label {
                                Layout.fillWidth: true
                                text: name
                                color: "white"
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: droneCopy ? qsTr("Saved locally and requested on drone") : qsTr("Saved locally")
                                color: "#75E6DA"
                                elide: Text.ElideRight
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelWidth * 0.35

                                Rectangle {
                                    Layout.preferredWidth: proofLabel.implicitWidth + ScreenTools.defaultFontPixelWidth
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.45
                                    radius: ScreenTools.defaultFontPixelHeight * 0.7
                                    color: "#16A085"
                                    visible: missionProof

                                    Label {
                                        id: proofLabel
                                        anchors.centerIn: parent
                                        text: qsTr("Proof")
                                        color: "white"
                                        font.bold: true
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: exportedLabel.implicitWidth + ScreenTools.defaultFontPixelWidth
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.45
                                    radius: ScreenTools.defaultFontPixelHeight * 0.7
                                    color: Qt.rgba(1, 1, 1, 0.16)
                                    visible: exported

                                    Label {
                                        id: exportedLabel
                                        anchors.centerIn: parent
                                        text: qsTr("Shared")
                                        color: "white"
                                        font.bold: true
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: tagLabel.implicitWidth + ScreenTools.defaultFontPixelWidth
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.45
                                    radius: ScreenTools.defaultFontPixelHeight * 0.7
                                    color: Qt.rgba(0.95, 0.62, 0.05, 0.25)
                                    border.color: "#F39C12"
                                    border.width: 1
                                    visible: tag && tag.length > 0

                                    Label {
                                        id: tagLabel
                                        anchors.centerIn: parent
                                        text: tag
                                        color: "white"
                                        font.bold: true
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 2

                            Label {
                                text: time
                                color: Qt.rgba(1, 1, 1, 0.72)
                                font.pointSize: ScreenTools.smallFontPointSize
                                horizontalAlignment: Text.AlignRight
                            }

                            Label {
                                text: localCopy ? qsTr("Local") : qsTr("Drone")
                                color: localCopy ? "white" : "#75E6DA"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: droneCopy ? qsTr("Drone") : ""
                                color: "#75E6DA"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }
                    }

                    MouseArea {
                        id: mediaTileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._reviewMedia(index)
                    }
                }
            }
        }
    }

    Rectangle {
        id: mediaReviewPanel
        property var reviewItem: _root._reviewItem()

        anchors.right: cameraShutterDock.left
        anchors.top: parent.top
        anchors.bottom: mediaLibraryPopup.top
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.8
        anchors.topMargin: ScreenTools.toolbarHeight + ScreenTools.defaultFontPixelHeight * 0.8
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.8
        width: Math.min(parent.width * 0.56, ScreenTools.defaultFontPixelWidth * 64)
        radius: ScreenTools.defaultFontPixelHeight * 0.8
        color: Qt.rgba(0, 0, 0, 0.92)
        border.color: Qt.rgba(1, 1, 1, 0.38)
        border.width: 1
        visible: _root._showCameraStudio && _root._libraryOpen && reviewItem !== null
        z: 123

        MediaPlayer {
            id: reviewVideoPlayer
            source: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.kind === "video" && mediaReviewPanel.reviewItem.filePath.length > 0 ? _root._fileUrl(mediaReviewPanel.reviewItem.filePath) : ""
            videoOutput: reviewVideoOutput
            onSourceChanged: {
                if (source && mediaReviewPanel.visible) {
                    play()
                }
            }
        }

        onVisibleChanged: {
            if (visible && reviewItem && reviewItem.kind === "video" && reviewVideoPlayer.source) {
                reviewVideoPlayer.play()
            } else if (!visible) {
                reviewVideoPlayer.stop()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.8
            spacing: ScreenTools.defaultFontPixelHeight * 0.6

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: mediaReviewPanel.reviewItem ? mediaReviewPanel.reviewItem.name : ""
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.3
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: closeReviewMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.10)
                    border.color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: "X"
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }

                    MouseArea {
                        id: closeReviewMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._mediaReviewIndex = -1
                    }

                    ToolTip.visible: closeReviewMouse.containsMouse
                    ToolTip.text: qsTr("Close preview")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: ScreenTools.defaultFontPixelHeight * 15
                radius: ScreenTools.defaultFontPixelHeight * 0.5
                color: Qt.rgba(0, 0, 0, 0.45)
                border.color: Qt.rgba(1, 1, 1, 0.16)
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    source: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.kind === "photo" && mediaReviewPanel.reviewItem.filePath.length > 0 ? (_root._fileUrl(mediaReviewPanel.reviewItem.filePath) + "?v=" + _root._libraryRefreshTick) : ""
                    fillMode: Image.PreserveAspectFit
                    visible: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.kind === "photo"
                    cache: false
                }

                VideoOutput {
                    id: reviewVideoOutput
                    anchors.fill: parent
                    visible: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.kind === "video"
                    fillMode: VideoOutput.PreserveAspectFit
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: !mediaReviewPanel.reviewItem || mediaReviewPanel.reviewItem.filePath.length === 0

                    QGCColoredImage {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 4
                        Layout.preferredHeight: Layout.preferredWidth
                        source: mediaReviewPanel.reviewItem ? _root._mediaIcon(mediaReviewPanel.reviewItem.kind) : "/qmlimages/camera_photo.svg"
                        color: "white"
                        opacity: 0.82
                    }

                    Label {
                        text: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.kind === "tag" ? qsTr("Flight marker") : qsTr("Drone media requested")
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                    width: reviewTypeLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.2
                    height: ScreenTools.defaultFontPixelHeight * 2
                    radius: ScreenTools.defaultFontPixelHeight
                    color: Qt.rgba(0, 0, 0, 0.58)

                    Label {
                        id: reviewTypeLabel
                        anchors.centerIn: parent
                        text: mediaReviewPanel.reviewItem ? _root._mediaTypeLabel(mediaReviewPanel.reviewItem.kind) : ""
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.5

                TextField {
                    id: mediaRenameField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Media name")
                    selectByMouse: true
                    text: mediaReviewPanel.reviewItem ? mediaReviewPanel.reviewItem.name : ""
                    onAccepted: _root._renameReviewMedia(text)
                }

                Button {
                    text: qsTr("Rename")
                    onClicked: _root._renameReviewMedia(mediaRenameField.text)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: proofMetadataColumn.height + ScreenTools.defaultFontPixelHeight * 1.0
                radius: ScreenTools.defaultFontPixelHeight * 0.45
                color: Qt.rgba(1, 1, 1, 0.08)
                border.color: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.missionProof ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.16)
                border.width: 1

                ColumnLayout {
                    id: proofMetadataColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: ScreenTools.defaultFontPixelHeight * 0.5
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: mediaReviewPanel.reviewItem ? _root._proofMetadataText(mediaReviewPanel.reviewItem) : ""
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        Layout.fillWidth: true
                        text: mediaReviewPanel.reviewItem ? (qsTr("Captured ") + mediaReviewPanel.reviewItem.capturedAt + qsTr(" | ") + mediaReviewPanel.reviewItem.note) : ""
                        color: Qt.rgba(1, 1, 1, 0.68)
                        font.pointSize: ScreenTools.smallFontPointSize
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.45
                visible: mediaReviewPanel.reviewItem !== null

                Repeater {
                    model: [qsTr("Issue"), qsTr("Good Shot"), qsTr("Retake"), qsTr("Crack"), qsTr("Hotspot"), qsTr("POI")]

                    Rectangle {
                        width: tagReviewLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.4
                        height: ScreenTools.defaultFontPixelHeight * 2.1
                        radius: ScreenTools.defaultFontPixelHeight
                        color: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.tag === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                        border.color: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.tag === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                        border.width: 1

                        Label {
                            id: tagReviewLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _root._setReviewTag(modelData)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelWidth * 0.5

                Button {
                    Layout.fillWidth: true
                    text: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.missionProof ? qsTr("Proof Marked") : qsTr("Mission Proof")
                    onClicked: _root._toggleMissionProof()
                }

                Button {
                    Layout.fillWidth: true
                    text: mediaReviewPanel.reviewItem && mediaReviewPanel.reviewItem.exported ? qsTr("Shared") : qsTr("Export / Share")
                    onClicked: _root._exportReviewMedia()
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Delete")
                    onClicked: _root._deleteReviewMedia()
                }
            }
        }
    }

    Rectangle {
        id: cameraCaptureBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 1.1
        width: Math.min(parent.width - ScreenTools.defaultFontPixelWidth * 4, ScreenTools.defaultFontPixelWidth * 52)
        height: ScreenTools.defaultFontPixelHeight * 5.2
        radius: ScreenTools.defaultFontPixelHeight * 0.8
        color: Qt.rgba(0, 0, 0, 0.58)
        border.color: Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        visible: false
        z: 80

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 1.2
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 1.2
            spacing: ScreenTools.defaultFontPixelWidth * 1.2

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.2
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: photoMouse.containsMouse ? "#F39C12" : Qt.rgba(1, 1, 1, 0.12)
                border.color: "white"
                border.width: _root._photoCaptureBusy ? 2 : 1
                opacity: _root._photoCaptureGuard ? 0.55 : 1.0

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.46
                    height: width
                    source: "/qmlimages/camera_photo.svg"
                    color: "white"
                }

                MouseArea {
                    id: photoMouse
                    anchors.fill: parent
                    enabled: !_root._photoCaptureGuard
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._capturePhoto()
                }

                ToolTip.visible: photoMouse.containsMouse
                ToolTip.text: qsTr("Capture photo")
            }

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.2
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: _root._recordingActive ? "#D92D20" : (recordMouse.containsMouse ? "#D92D20" : Qt.rgba(1, 1, 1, 0.12))
                border.color: "white"
                border.width: 1

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * (_root._recordingActive ? 0.34 : 0.54)
                    height: width
                    radius: _root._recordingActive ? width * 0.2 : width / 2
                    color: "white"
                    Behavior on width { NumberAnimation { duration: 180 } }
                    Behavior on radius { NumberAnimation { duration: 180 } }
                }

                MouseArea {
                    id: recordMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._toggleRecording()
                }

                ToolTip.visible: recordMouse.containsMouse
                ToolTip.text: _root._recordingActive ? qsTr("Stop recording") : qsTr("Record video")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth * 0.5

                    Rectangle {
                        Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 0.7
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: "#D92D20"
                        visible: _root._recordingActive

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: _root._recordingActive && !_root._recordingPaused
                            NumberAnimation { to: 0.22; duration: 700 }
                            NumberAnimation { to: 1.0; duration: 700 }
                        }
                    }

                    Label {
                        text: _root._recordingText()
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: _root._hasCameraControl ? (_root._camera.modelName + " | " + (_root._cameraInPhotoMode ? qsTr("Photo") : qsTr("Video")))
                                                   : (QGroundControl.videoManager.hasVideo ? qsTr("Local video capture") : qsTr("Camera feed unavailable"))
                    color: Qt.rgba(1, 1, 1, 0.72)
                    elide: Text.ElideRight
                    font.pointSize: ScreenTools.smallFontPointSize
                }
            }

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 4.2
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.1
                radius: ScreenTools.defaultFontPixelHeight * 0.35
                visible: _root._recordingActive && _root._canPauseRecording()
                color: pauseMouse.containsMouse ? "#FFB020" : Qt.rgba(1, 1, 1, 0.14)
                border.color: Qt.rgba(1, 1, 1, 0.45)
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: _root._recordingPaused ? qsTr("Resume") : qsTr("Pause")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }

                MouseArea {
                    id: pauseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._toggleRecordingPause()
                }
            }

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.8
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.1
                radius: ScreenTools.defaultFontPixelHeight * 0.35
                visible: _root._recordingActive
                color: endMouse.containsMouse ? "#B42318" : "#D92D20"
                border.color: "white"
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: qsTr("End")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                }

                MouseArea {
                    id: endMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._endRecording()
                }
            }

            Rectangle {
                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: settingsMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                border.color: cameraStudioPanel.visible ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.35)
                border.width: cameraStudioPanel.visible ? 2 : 1

                QGCColoredImage {
                    anchors.centerIn: parent
                    width: parent.width * 0.46
                    height: width
                    source: "/res/gear-black.svg"
                    color: "white"
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: _root._studioPanelOpen = !_root._studioPanelOpen
                }

                ToolTip.visible: settingsMouse.containsMouse
                ToolTip.text: qsTr("Camera controls")
            }
        }
    }

    Rectangle {
        id: cameraStudioPanel
        anchors.right: cameraShutterDock.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 1.2
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 5.4
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 1.2
        width: Math.min(parent.width - cameraShutterDock.width - ScreenTools.defaultFontPixelWidth * 4,
                        Math.max(ScreenTools.defaultFontPixelWidth * 34, Math.min(parent.width * 0.34, ScreenTools.defaultFontPixelWidth * 46)))
        radius: ScreenTools.defaultFontPixelHeight * 0.55
        color: Qt.rgba(0, 0, 0, 0.82)
        border.color: Qt.rgba(1, 1, 1, 0.30)
        border.width: 1
        visible: _root._showCameraStudio && _root._studioPanelOpen
        z: 118

        Flickable {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelHeight
            contentHeight: cameraStudioColumn.height
            clip: true

            ColumnLayout {
                id: cameraStudioColumn
                width: parent.width
                spacing: ScreenTools.defaultFontPixelHeight * 0.65

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelHeight * 0.22

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth * 0.7

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.2
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: width / 2
                                color: "#16A085"

                                QGCColoredImage {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.52
                                    height: width
                                    source: "/res/gear-black.svg"
                                    color: "white"
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Camera Tools")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: sourceStatusLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 1.5
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.6
                            radius: ScreenTools.defaultFontPixelHeight * 0.8
                            color: Qt.rgba(0.09, 0.63, 0.52, 0.24)
                            border.color: Qt.rgba(0.46, 0.90, 0.86, 0.36)
                            border.width: 1

                            Label {
                                id: sourceStatusLabel
                                anchors.centerIn: parent
                                text: _root._cameraSourceLabel() + qsTr(" | ") + _root._liveStateLabel()
                                color: "#75E6DA"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }
                    }

                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.45

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.1
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: resetToolsMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                            border.color: Qt.rgba(1, 1, 1, 0.24)
                            border.width: 1

                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.52
                                height: width
                                source: "/qmlimages/ArrowCCW.svg"
                                color: "white"
                            }

                            MouseArea {
                                id: resetToolsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _root._resetCameraTools()
                            }
                            ToolTip.visible: resetToolsMouse.containsMouse
                            ToolTip.text: qsTr("Reset all")
                        }

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.1
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: _root._libraryOpen ? "#16A085" : (libraryToolsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.12))
                            border.color: Qt.rgba(1, 1, 1, 0.24)
                            border.width: 1

                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.52
                                height: width
                                source: "qrc:/InstrumentValueIcons/photo.svg"
                                color: "white"
                            }

                            MouseArea {
                                id: libraryToolsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _root._libraryOpen = !_root._libraryOpen
                            }
                            ToolTip.visible: libraryToolsMouse.containsMouse
                            ToolTip.text: _root._libraryOpen ? qsTr("Hide library") : qsTr("Library")
                        }

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.1
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: _root._effectsActive ? "#F39C12" : Qt.rgba(1, 1, 1, 0.12)
                            border.color: Qt.rgba(1, 1, 1, 0.24)
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("FX")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                            ToolTip.visible: fxToolsMouse.containsMouse
                            ToolTip.text: _root._effectsActive ? qsTr("Effects active") : qsTr("Clean image")
                            MouseArea {
                                id: fxToolsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(1, 1, 1, 0.18)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: capabilityColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(0.46, 0.90, 0.86, 0.26)
                    border.width: 1

                    ColumnLayout {
                        id: capabilityColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.4

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Camera Capability")
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.55
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Repeater {
                                model: [
                                    { label: qsTr("Capture"), key: "photo" },
                                    { label: qsTr("Record"), key: "record" },
                                    { label: qsTr("Zoom"), key: "zoom" },
                                    { label: qsTr("Gimbal"), key: "gimbal" },
                                    { label: qsTr("Tracking"), key: "tracking" },
                                    { label: qsTr("Storage"), key: "storage" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.45
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: Qt.rgba(0, 0, 0, 0.24)
                                    border.color: Qt.rgba(1, 1, 1, 0.14)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.38
                                        spacing: ScreenTools.defaultFontPixelWidth * 0.45

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.label
                                            color: "white"
                                            font.bold: true
                                            font.pointSize: ScreenTools.smallFontPointSize * 0.9
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: capabilityBadgeText.implicitWidth + ScreenTools.defaultFontPixelWidth
                                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.35
                                            radius: ScreenTools.defaultFontPixelHeight * 0.65
                                            color: _root._capabilityBadgeColor(modelData.key)

                                            Label {
                                                id: capabilityBadgeText
                                                anchors.centerIn: parent
                                                text: _root._capabilityBadgeText(modelData.key)
                                                color: "white"
                                                font.bold: true
                                                font.pointSize: ScreenTools.smallFontPointSize * 0.72
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.25
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: _root._recordingActive ? Qt.rgba(0.85, 0.18, 0.12, 0.26) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: _root._recordingActive ? Qt.rgba(1, 1, 1, 0.44) : Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelWidth * 0.7

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 0.85
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: _root._recordingActive ? "#D92D20" : Qt.rgba(1, 1, 1, 0.34)

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: _root._recordingActive && !_root._recordingPaused
                                NumberAnimation { to: 0.28; duration: 700 }
                                NumberAnimation { to: 1.0; duration: 700 }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: _root._recordingStateLabel()
                                color: _root._recordingActive ? "#FFB020" : "white"
                                font.bold: true
                                font.pointSize: ScreenTools.defaultFontPointSize
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: _root._recordingActive ? _root._formatRecordSeconds(_root._recordSeconds) : qsTr("Ready to record")
                                color: Qt.rgba(1, 1, 1, 0.76)
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.8
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.0
                            radius: ScreenTools.defaultFontPixelHeight * 0.32
                            visible: _root._recordingActive && _root._canPauseRecording()
                            color: panelPauseMouse.containsMouse ? "#FFB020" : Qt.rgba(1, 1, 1, 0.12)
                            border.color: Qt.rgba(1, 1, 1, 0.28)
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: _root._recordingPaused ? qsTr("Resume") : qsTr("Pause")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            MouseArea {
                                id: panelPauseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _root._toggleRecordingPause()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.3
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.0
                            radius: ScreenTools.defaultFontPixelHeight * 0.32
                            visible: _root._recordingActive
                            color: panelEndMouse.containsMouse ? "#B42318" : "#D92D20"
                            border.color: "white"
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: qsTr("End")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            MouseArea {
                                id: panelEndMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _root._endRecording()
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: false
                    spacing: ScreenTools.defaultFontPixelHeight * 0.45

                    Repeater {
                        model: [
                            { label: qsTr("Brightness"), fact: _root._videoSettings.cameraBrightness, min: -100, max: 100 },
                            { label: qsTr("Contrast"), fact: _root._videoSettings.cameraContrast, min: -100, max: 100 },
                            { label: qsTr("Saturation"), fact: _root._videoSettings.cameraSaturation, min: -100, max: 100 },
                            { label: qsTr("Sharpness"), fact: _root._videoSettings.cameraSharpness, min: -100, max: 100 }
                        ]

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.label + qsTr(" ") + modelData.fact.rawValue
                                    color: Qt.rgba(1, 1, 1, 0.72)
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                                Rectangle {
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.45
                                    Layout.preferredHeight: Layout.preferredWidth
                                    radius: ScreenTools.defaultFontPixelHeight * 0.25
                                    color: lookTopResetMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1

                                    QGCColoredImage {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.56
                                        height: width
                                        source: "/qmlimages/ArrowCCW.svg"
                                        color: "white"
                                    }

                                    MouseArea {
                                        id: lookTopResetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.fact.rawValue = 0
                                    }
                                    ToolTip.visible: lookTopResetMouse.containsMouse
                                    ToolTip.text: qsTr("Reset ") + modelData.label
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: modelData.min
                                to: modelData.max
                                stepSize: 1
                                value: modelData.fact.rawValue
                                onMoved: modelData.fact.rawValue = Math.round(value)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                        Label { text: _root._sectionCaptureOpen ? qsTr("v") : qsTr(">"); color: "#75E6DA"; font.bold: true }
                        Label { Layout.fillWidth: true; text: qsTr("Capture"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._captureModeLabel(); color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._sectionCaptureOpen = !_root._sectionCaptureOpen
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: _root._sectionCaptureOpen
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Zoom")
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        Label {
                            text: _root._digitalZoom.toFixed(1) + "x"
                            color: "#75E6DA"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 1.0
                        to: 4.0
                        stepSize: 0.1
                        value: _root._digitalZoom
                        onMoved: {
                            _root._digitalZoom = Math.round(value * 10) / 10
                            if (_root._hasCameraControl && _root._camera.hasZoom) {
                                _root._camera.zoomLevel = Math.min(100, Math.max(0, ((_root._digitalZoom - 1.0) / 3.0) * 100))
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.2
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    visible: false
                    color: Qt.rgba(0.09, 0.63, 0.52, 0.16)
                    border.color: Qt.rgba(0.46, 0.90, 0.86, 0.35)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.45
                        spacing: ScreenTools.defaultFontPixelWidth

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Mode")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        Label {
                            text: (_root._localCameraAvailable || QGroundControl.videoManager.isUvc) ? qsTr("Local Camera") : qsTr("Drone Stream")
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                    visible: _root._focusControlsAvailable()
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                        Label { text: _root._sectionFocusOpen ? qsTr("v") : qsTr(">"); color: "#75E6DA"; font.bold: true }
                        QGCColoredImage { Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.1; Layout.preferredHeight: Layout.preferredWidth; source: "/qmlimages/crossHair.svg"; color: "#75E6DA" }
                        Label { Layout.fillWidth: true; text: qsTr("Focus / Tracking"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._tapFocusEnabled ? qsTr("Tap") : qsTr("Off"); color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._sectionFocusOpen = !_root._sectionFocusOpen
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth * 0.6
                    visible: _root._sectionFocusOpen && _root._hasCameraControl && _root._camera.hasTracking

                    Button {
                        Layout.fillWidth: true
                        text: _root._camera.trackingEnabled ? qsTr("Tracking On") : qsTr("Tracking Off")
                        onClicked: _root._camera.trackingEnabled = !_root._camera.trackingEnabled
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Stop Track")
                        enabled: _root._camera.trackingEnabled
                        onClicked: _root._camera.stopTracking()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth * 0.6
                    visible: _root._sectionFocusOpen && _root._focusControlsAvailable()

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.5
                        radius: ScreenTools.defaultFontPixelHeight * 0.35
                        color: _root._subjectLockMode !== "none" ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                        border.color: _root._subjectLockMode !== "none" ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.24)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.45
                            spacing: ScreenTools.defaultFontPixelWidth * 0.55

                            QGCColoredImage {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.2
                                Layout.preferredHeight: Layout.preferredWidth
                                source: "/qmlimages/TrackingIcon.svg"
                                color: _root._subjectLockMode !== "none" ? "#10201E" : "white"
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Subject ") + _root._subjectLockLabel()
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.5
                        radius: ScreenTools.defaultFontPixelHeight * 0.35
                        color: _root._tapFocusEnabled ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                        border.color: _root._tapFocusEnabled ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.24)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.45
                            spacing: ScreenTools.defaultFontPixelWidth * 0.55

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.2
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: width / 2
                                color: _root._tapFocusEnabled ? "#75E6DA" : Qt.rgba(0, 0, 0, 0.30)
                                border.color: Qt.rgba(1, 1, 1, 0.45)
                                border.width: 1

                                QGCColoredImage {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.68
                                    height: width
                                    source: "/qmlimages/crossHair.svg"
                                    color: "#10201E"
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Tap Focus")
                                color: "white"
                                font.bold: _root._tapFocusEnabled
                                font.pointSize: ScreenTools.smallFontPointSize
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _root._tapFocusEnabled = !_root._tapFocusEnabled
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.5
                        radius: ScreenTools.defaultFontPixelHeight * 0.35
                        enabled: _root._hasCameraControl && _root._camera.hasTracking
                        opacity: enabled ? 1.0 : 0.52
                        color: _root._tapTrackEnabled && enabled ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                        border.color: _root._tapTrackEnabled && enabled ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.24)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: ScreenTools.defaultFontPixelHeight * 0.45
                            spacing: ScreenTools.defaultFontPixelWidth * 0.55

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.2
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: width / 2
                                color: _root._tapTrackEnabled && parent.parent.enabled ? "#75E6DA" : Qt.rgba(0, 0, 0, 0.30)
                                border.color: Qt.rgba(1, 1, 1, 0.45)
                                border.width: 1

                                QGCColoredImage {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.68
                                    height: width
                                    source: "/qmlimages/TrackingIcon.svg"
                                    color: "#10201E"
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Tap Track")
                                color: "white"
                                font.bold: _root._tapTrackEnabled && parent.parent.enabled
                                font.pointSize: ScreenTools.smallFontPointSize
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: _root._tapTrackEnabled = !_root._tapTrackEnabled
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                        Label { text: _root._sectionLookOpen ? qsTr("v") : qsTr(">"); color: "#75E6DA"; font.bold: true }
                        Label { Layout.fillWidth: true; text: qsTr("Color"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._cameraColorName(); color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.maximumWidth: ScreenTools.defaultFontPixelWidth * 14 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._sectionLookOpen = !_root._sectionLookOpen
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 0.5
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.4
                    visible: _root._sectionLookOpen

                    Repeater {
                        model: [
                            { label: qsTr("Normal") },
                            { label: qsTr("D-Log M") },
                            { label: qsTr("HLG") },
                            { label: qsTr("Vivid") },
                            { label: qsTr("Cinematic") },
                            { label: qsTr("Low Light") },
                            { label: qsTr("Inspection") },
                            { label: qsTr("B&W") }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: _root._cameraColorName() === modelData.label ? "#F39C12" : Qt.rgba(1, 1, 1, 0.10)
                            border.color: Qt.rgba(1, 1, 1, 0.22)
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "white"
                                font.bold: _root._cameraColorName() === modelData.label
                                font.pointSize: ScreenTools.smallFontPointSize
                                elide: Text.ElideRight
                                width: parent.width - ScreenTools.defaultFontPixelWidth
                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _root._applyCameraColorName(modelData.label)
                            }
                        }
                    }
                }

                GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: ScreenTools.defaultFontPixelWidth * 0.45

                        Repeater {
                            model: [ 1, 2, 4 ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                radius: ScreenTools.defaultFontPixelHeight * 0.32
                                color: Math.abs(_root._digitalZoom - modelData) < 0.05 ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                border.color: Math.abs(_root._digitalZoom - modelData) < 0.05 ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData + "x"
                                    color: "white"
                                    font.bold: Math.abs(_root._digitalZoom - modelData) < 0.05
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _root._digitalZoom = modelData
                                        if (_root._hasCameraControl && _root._camera.hasZoom) {
                                            _root._camera.zoomLevel = Math.min(100, Math.max(0, ((_root._digitalZoom - 1.0) / 3.0) * 100))
                                        }
                                    }
                                }
                            }
                        }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: recordSettingsColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    visible: false
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    ColumnLayout {
                        id: recordSettingsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Recording Format")
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.5
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Repeater {
                                model: [ "MP4", "MOV" ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._recordingFormatName() === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._recordingFormatName() === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._recordingFormatName() === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._setRecordingFormatName(modelData)
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Coding Format")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.5

                            Repeater {
                                model: [ "H.264", "H.265" ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._codingFormat === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._codingFormat === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._codingFormat === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._setCodingFormat(modelData)
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Resolution")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.35
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Repeater {
                                model: [ "720p", "1080p", "2.7K", "4K", "5.1K" ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._videoResolution === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._videoResolution === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._videoResolution === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._setVideoResolution(modelData)
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Frame Rate")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 5
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.28

                            Repeater {
                                model: [ "24", "30", "48", "60", "120" ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._frameRate === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._frameRate === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._frameRate === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._setFrameRate(modelData)
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Bitrate Quality")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.35

                            Repeater {
                                model: [ qsTr("Low"), qsTr("Standard"), qsTr("High"), qsTr("Max") ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._bitrateQuality === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._bitrateQuality === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - ScreenTools.defaultFontPixelWidth * 0.4
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._bitrateQuality === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._setBitrateQuality(modelData)
                                    }
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Label { text: qsTr("Video subtitles"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize }
                            Switch { checked: _root._videoSubtitles; onToggled: _root._videoSubtitles = checked }
                            Label { text: qsTr("Cache video recording"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize }
                            Switch { checked: _root._cacheVideoRecording; onToggled: _root._cacheVideoRecording = checked }
                            Label { text: qsTr("Metadata watermark"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize }
                            Switch { checked: _root._watermarkMetadata; onToggled: _root._watermarkMetadata = checked }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Storage")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.45

                            Repeater {
                                model: [ qsTr("SD Card"), qsTr("Internal"), qsTr("Cloud") ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._storageTarget === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._storageTarget === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - ScreenTools.defaultFontPixelWidth
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._storageTarget === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._storageTarget = modelData
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { Layout.fillWidth: true; text: qsTr("Storage warning"); color: Qt.rgba(1, 1, 1, 0.72); font.pointSize: ScreenTools.smallFontPointSize }
                            Label { text: _root._storageWarningLevel + "%"; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.45

                            Repeater {
                                model: [ 80, 90, 95 ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._storageWarningLevel === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._storageWarningLevel === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData + "%"
                                        color: "white"
                                        font.bold: _root._storageWarningLevel === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._storageWarningLevel = modelData
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Cloud Sync Status")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.35

                            Repeater {
                                model: [ qsTr("Pending"), qsTr("Uploading"), qsTr("Synced"), qsTr("Failed") ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._cloudSyncStatus === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._cloudSyncStatus === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - ScreenTools.defaultFontPixelWidth * 0.4
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._cloudSyncStatus === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.8
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._cloudSyncStatus = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 0.35
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35
                    visible: _root._sectionFocusOpen && _root._hasCameraControl && _root._camera.hasFocus

                    Repeater {
                        model: [ qsTr("Auto"), qsTr("Manual"), qsTr("Infinity"), qsTr("Tap Focus") ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                            radius: ScreenTools.defaultFontPixelHeight * 0.32
                            color: _root._focusModeSetting === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                            border.color: _root._focusModeSetting === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                width: parent.width - ScreenTools.defaultFontPixelWidth * 0.35
                                text: modelData
                                color: "white"
                                font.bold: _root._focusModeSetting === modelData
                                font.pointSize: ScreenTools.smallFontPointSize * 0.82
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    _root._focusModeSetting = modelData
                                    _root._tapFocusEnabled = modelData === qsTr("Tap Focus")
                                    _root._focusManual = modelData === qsTr("Manual")
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 0.5
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35
                    visible: _root._sectionFocusOpen && (_root._trackingAvailable() || (_root._activeVehicle && _root._activeVehicle.roiModeSupported))

                    Repeater {
                        model: [
                            { label: qsTr("Person"), mode: "person", action: function() { _root._armSubjectTracking("person") } },
                            { label: qsTr("Vehicle"), mode: "vehicle", action: function() { _root._armSubjectTracking("vehicle") } },
                            { label: qsTr("Building"), mode: "building", action: function() { _root._lockInspectionPoi() } },
                            { label: qsTr("GPS POI"), mode: "gps", action: function() { _root._lockCurrentGpsPoi() } }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: _root._subjectLockMode === modelData.mode ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                            border.color: _root._subjectLockMode === modelData.mode ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                width: parent.width - ScreenTools.defaultFontPixelWidth
                                text: modelData.label
                                color: "white"
                                font.bold: _root._subjectLockMode === modelData.mode
                                font.pointSize: ScreenTools.smallFontPointSize
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.action()
                            }
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    visible: _root._sectionFocusOpen && (_root._trackingAvailable() || (_root._activeVehicle && _root._activeVehicle.roiModeSupported))
                    text: qsTr("Clear Subject / POI Lock")
                    enabled: _root._subjectLockMode !== "none" || (_root._trackingAvailable() && _root._camera.trackingEnabled) || (_root._activeVehicle && _root._activeVehicle.isROIEnabled)
                    onClicked: _root._clearSubjectLock()
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                    visible: _root._exposureControlsAvailable()
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                        Label { text: _root._sectionExposureOpen ? qsTr("v") : qsTr(">"); color: "#75E6DA"; font.bold: true }
                        Label { Layout.fillWidth: true; text: qsTr("Exposure"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._overExposureLikely ? qsTr("High") : (_root._underExposureLikely ? qsTr("Low") : qsTr("OK")); color: _root._overExposureLikely ? "#FFB020" : (_root._underExposureLikely ? "#75E6DA" : "#6EE7B7"); font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._sectionExposureOpen = !_root._sectionExposureOpen
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: _root._sectionExposureOpen && _root._exposureControlsAvailable()
                    spacing: ScreenTools.defaultFontPixelHeight * 0.45

                    Label {
                        Layout.fillWidth: true
                        visible: _root._shutterSupported()
                        text: qsTr("Shutter Mode")
                        color: "white"
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        visible: _root._shutterSupported()
                        columns: 5
                        columnSpacing: ScreenTools.defaultFontPixelWidth * 0.28

                        Repeater {
                            model: [ "Auto", "1/50", "1/60", "1/120", "1/240" ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                radius: ScreenTools.defaultFontPixelHeight * 0.32
                                color: _root._shutterMode === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                border.color: _root._shutterMode === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    width: parent.width - ScreenTools.defaultFontPixelWidth * 0.25
                                    text: modelData
                                    color: "white"
                                    font.bold: _root._shutterMode === modelData
                                    font.pointSize: ScreenTools.smallFontPointSize * 0.82
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._setShutterMode(modelData)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: _root._evSupported()
                        Label { Layout.fillWidth: true; text: qsTr("EV compensation"); color: Qt.rgba(1, 1, 1, 0.72); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: (_root._evCompensation > 0 ? "+" : "") + _root._evCompensation.toFixed(1); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                    }

                    Slider {
                        Layout.fillWidth: true
                        visible: _root._evSupported()
                        from: -3
                        to: 3
                        stepSize: 0.3
                        value: _root._evCompensation
                        onMoved: _root._setEvCompensation(value)
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: _root._isoSupported()
                        text: qsTr("ISO Limit")
                        color: Qt.rgba(1, 1, 1, 0.72)
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        visible: _root._isoSupported()
                        columns: 4
                        columnSpacing: ScreenTools.defaultFontPixelWidth * 0.35
                        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                        Repeater {
                            model: [ "Auto", "100", "200", "400", "800", "1600", "3200" ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                radius: ScreenTools.defaultFontPixelHeight * 0.32
                                color: _root._isoLimit === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                border.color: _root._isoLimit === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "white"
                                    font.bold: _root._isoLimit === modelData
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._setIsoLimit(modelData)
                                }
                            }
                        }
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: false
                    spacing: ScreenTools.defaultFontPixelHeight * 0.45

                    Repeater {
                        model: [
                            { label: qsTr("Brightness"), fact: _root._videoSettings.cameraBrightness, min: -100, max: 100 },
                            { label: qsTr("Contrast"), fact: _root._videoSettings.cameraContrast, min: -100, max: 100 },
                            { label: qsTr("Saturation"), fact: _root._videoSettings.cameraSaturation, min: -100, max: 100 },
                            { label: qsTr("Sharpness"), fact: _root._videoSettings.cameraSharpness, min: -100, max: 100 }
                        ]

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.label + qsTr(" ") + modelData.fact.rawValue
                                    color: Qt.rgba(1, 1, 1, 0.72)
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                                Label {
                                    text: modelData.fact.rawValue
                                    color: "#75E6DA"
                                    font.bold: true
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                                Rectangle {
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.45
                                    Layout.preferredHeight: Layout.preferredWidth
                                    radius: ScreenTools.defaultFontPixelHeight * 0.25
                                    color: sliderResetMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1

                                    QGCColoredImage {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.56
                                        height: width
                                        source: "/qmlimages/ArrowCCW.svg"
                                        color: "white"
                                    }

                                    MouseArea {
                                        id: sliderResetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.fact.rawValue = 0
                                    }
                                    ToolTip.visible: sliderResetMouse.containsMouse
                                    ToolTip.text: qsTr("Reset ") + modelData.label
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: modelData.min
                                to: modelData.max
                                stepSize: 1
                                value: modelData.fact.rawValue
                                onMoved: modelData.fact.rawValue = Math.round(value)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: exposureAssistColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    visible: _root._sectionExposureOpen
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(0.46, 0.90, 0.86, 0.26)
                    border.width: 1

                    ColumnLayout {
                        id: exposureAssistColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Exposure Assist")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: _root._overExposureLikely ? qsTr("High") : (_root._underExposureLikely ? qsTr("Low") : qsTr("OK"))
                                color: _root._overExposureLikely ? "#FFB020" : (_root._underExposureLikely ? "#75E6DA" : "#6EE7B7")
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.6
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.2

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                                radius: ScreenTools.defaultFontPixelHeight * 0.32
                                color: _root._zebraOverlay ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                                border.color: _root._zebraOverlay ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: (_root._zebraOverlay ? "\u2713 " : "") + qsTr("Zebra")
                                    color: "white"
                                    font.bold: _root._zebraOverlay
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _root._zebraOverlay = !_root._zebraOverlay
                                        _root._saveExposureAssistSettings()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                                radius: ScreenTools.defaultFontPixelHeight * 0.32
                                color: _root._histogramOverlay ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                                border.color: _root._histogramOverlay ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: (_root._histogramOverlay ? "\u2713 " : "") + qsTr("Histogram")
                                    color: "white"
                                    font.bold: _root._histogramOverlay
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _root._histogramOverlay = !_root._histogramOverlay
                                        _root._saveExposureAssistSettings()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                                radius: ScreenTools.defaultFontPixelHeight * 0.32
                                color: _root._exposureWarnings ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                                border.color: _root._exposureWarnings ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: (_root._exposureWarnings ? "\u2713 " : "") + qsTr("Warnings")
                                    color: "white"
                                    font.bold: _root._exposureWarnings
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        _root._exposureWarnings = !_root._exposureWarnings
                                        _root._saveExposureAssistSettings()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Zebra level")
                                color: Qt.rgba(1, 1, 1, 0.72)
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: _root._zebraLevel + "%"
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 65
                            to: 100
                            stepSize: 1
                            value: _root._zebraLevel
                            onMoved: {
                                _root._zebraLevel = Math.round(value)
                                _root._saveExposureAssistSettings()
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: _root._sectionLookOpen
                    spacing: ScreenTools.defaultFontPixelHeight * 0.45

                    Repeater {
                        model: [
                            { label: qsTr("Brightness"), fact: _root._videoSettings.cameraBrightness, min: -100, max: 100 },
                            { label: qsTr("Contrast"), fact: _root._videoSettings.cameraContrast, min: -100, max: 100 },
                            { label: qsTr("Saturation"), fact: _root._videoSettings.cameraSaturation, min: -100, max: 100 },
                            { label: qsTr("Sharpness"), fact: _root._videoSettings.cameraSharpness, min: -100, max: 100 }
                        ]

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.label + qsTr(" ") + modelData.fact.rawValue
                                    color: Qt.rgba(1, 1, 1, 0.72)
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                                Rectangle {
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.45
                                    Layout.preferredHeight: Layout.preferredWidth
                                    radius: ScreenTools.defaultFontPixelHeight * 0.25
                                    color: lookSliderResetMouseHidden.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1

                                    QGCColoredImage {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.56
                                        height: width
                                        source: "/qmlimages/ArrowCCW.svg"
                                        color: "white"
                                    }

                                    MouseArea {
                                        id: lookSliderResetMouseHidden
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.fact.rawValue = 0
                                    }
                                    ToolTip.visible: lookSliderResetMouseHidden.containsMouse
                                    ToolTip.text: qsTr("Reset ") + modelData.label
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: modelData.min
                                to: modelData.max
                                stepSize: 1
                                value: modelData.fact.rawValue
                                onMoved: modelData.fact.rawValue = Math.round(value)
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: false
                    spacing: ScreenTools.defaultFontPixelHeight * 0.45

                    Repeater {
                        model: [
                            { label: qsTr("Brightness"), fact: _root._videoSettings.cameraBrightness, min: -100, max: 100 },
                            { label: qsTr("Contrast"), fact: _root._videoSettings.cameraContrast, min: -100, max: 100 },
                            { label: qsTr("Saturation"), fact: _root._videoSettings.cameraSaturation, min: -100, max: 100 },
                            { label: qsTr("Sharpness"), fact: _root._videoSettings.cameraSharpness, min: -100, max: 100 }
                        ]

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.label + qsTr(" ") + modelData.fact.rawValue
                                    color: Qt.rgba(1, 1, 1, 0.72)
                                    font.pointSize: ScreenTools.smallFontPointSize
                                }
                                Rectangle {
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.45
                                    Layout.preferredHeight: Layout.preferredWidth
                                    radius: ScreenTools.defaultFontPixelHeight * 0.25
                                    color: lookSliderResetMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1

                                    QGCColoredImage {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.56
                                        height: width
                                        source: "/qmlimages/ArrowCCW.svg"
                                        color: "white"
                                    }

                                    MouseArea {
                                        id: lookSliderResetMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.fact.rawValue = 0
                                    }
                                    ToolTip.visible: lookSliderResetMouse.containsMouse
                                    ToolTip.text: qsTr("Reset ") + modelData.label
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: modelData.min
                                to: modelData.max
                                stepSize: 1
                                value: modelData.fact.rawValue
                                onMoved: modelData.fact.rawValue = Math.round(value)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                        Label { text: _root._sectionStorageOpen ? qsTr("v") : qsTr(">"); color: "#75E6DA"; font.bold: true }
                        Label { Layout.fillWidth: true; text: qsTr("Storage"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._recordingStorageLabel(); color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._sectionStorageOpen = !_root._sectionStorageOpen
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: recordingHealthColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    visible: _root._sectionStorageOpen
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: _root._recordingActive ? Qt.rgba(0.85, 0.18, 0.12, 0.55) : Qt.rgba(0.46, 0.90, 0.86, 0.26)
                    border.width: 1

                    ColumnLayout {
                        id: recordingHealthColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Recording Health")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: _root._recordingActive ? qsTr("REC") : (QGroundControl.videoManager.decoding ? qsTr("Live") : qsTr("Idle"))
                                color: _root._recordingActive ? "#FFB020" : (QGroundControl.videoManager.decoding ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.62))
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.65
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Repeater {
                                model: [
                                    { label: qsTr("Storage"), key: "storage" },
                                    { label: qsTr("Time left"), key: "time" },
                                    { label: qsTr("Dropped"), key: "dropped" },
                                    { label: qsTr("Bitrate"), key: "bitrate" },
                                    { label: qsTr("Resolution"), key: "resolution" },
                                    { label: qsTr("FPS"), key: "fps" },
                                    { label: qsTr("Format"), key: "codec" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.0
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: Qt.rgba(0, 0, 0, 0.28)
                                    border.color: Qt.rgba(1, 1, 1, 0.14)
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.35
                                        spacing: 0

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.label
                                            color: Qt.rgba(1, 1, 1, 0.62)
                                            font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: _root._recordingHealthTick >= 0 ? _root._recordingHealthValue(modelData.key) : qsTr("--")
                                            color: "white"
                                            font.bold: true
                                            font.pointSize: ScreenTools.smallFontPointSize
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.25
                    visible: _root._gimbalAvailable()
                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth

                        Label { text: _root._sectionGimbalOpen ? qsTr("v") : qsTr(">"); color: "#75E6DA"; font.bold: true }
                        Label { Layout.fillWidth: true; text: qsTr("Gimbal"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        Label {
                            text: _root._gimbalAvailable()
                                  ? (qsTr("P ") + Math.round(_root._gimbalPitch()) + qsTr(" / Y ") + Math.round(_root._gimbalYaw()))
                                  : qsTr("Unavailable")
                            color: _root._gimbalAvailable() ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.56)
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: _root._sectionGimbalOpen = !_root._sectionGimbalOpen
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: gimbalControlColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    visible: _root._sectionGimbalOpen && _root._gimbalAvailable()
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: _root._gimbalAvailable() ? Qt.rgba(0.46, 0.90, 0.86, 0.30) : Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                    opacity: _root._gimbalAvailable() ? 1.0 : 0.72

                    ColumnLayout {
                        id: gimbalControlColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.5

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Gimbal Controls")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: _root._gimbalAvailable() ? (qsTr("P ") + Math.round(_root._gimbalPitch()) + qsTr(" / Y ") + Math.round(_root._gimbalYaw())) : qsTr("Unavailable")
                                color: _root._gimbalAvailable() ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.56)
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Horizon lock")
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Switch {
                                checked: _root._gimbalHorizonLock
                                enabled: _root._gimbalAvailable()
                                onToggled: _root._gimbalHorizonLock = checked
                            }
                        }

                        GridLayout {
                            Layout.alignment: Qt.AlignHCenter
                            columns: 3
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.45
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Item { Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1; Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4 }

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                                radius: ScreenTools.defaultFontPixelHeight * 0.35
                                color: gimbalPitchUpMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                border.width: 1
                                enabled: _root._gimbalAvailable()

                                Label { anchors.centerIn: parent; text: qsTr("Pitch +"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                                MouseArea {
                                    id: gimbalPitchUpMouse
                                    anchors.fill: parent
                                    enabled: parent.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._nudgeGimbal(_root._gimbalSpeed, 0)
                                }
                            }

                            Item { Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1; Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4 }

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                                radius: ScreenTools.defaultFontPixelHeight * 0.35
                                color: gimbalYawLeftMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                border.width: 1
                                enabled: _root._gimbalAvailable()

                                Label { anchors.centerIn: parent; text: qsTr("Yaw -"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                                MouseArea {
                                    id: gimbalYawLeftMouse
                                    anchors.fill: parent
                                    enabled: parent.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._nudgeGimbal(0, -_root._gimbalSpeed)
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                                radius: ScreenTools.defaultFontPixelHeight * 0.35
                                color: gimbalCenterMouse.containsMouse ? "#F39C12" : Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                border.width: 1
                                enabled: _root._gimbalAvailable()

                                Label { anchors.centerIn: parent; text: qsTr("Center"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                                MouseArea {
                                    id: gimbalCenterMouse
                                    anchors.fill: parent
                                    enabled: parent.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._centerGimbal()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                                radius: ScreenTools.defaultFontPixelHeight * 0.35
                                color: gimbalYawRightMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                border.width: 1
                                enabled: _root._gimbalAvailable()

                                Label { anchors.centerIn: parent; text: qsTr("Yaw +"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                                MouseArea {
                                    id: gimbalYawRightMouse
                                    anchors.fill: parent
                                    enabled: parent.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._nudgeGimbal(0, _root._gimbalSpeed)
                                }
                            }

                            Item { Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1; Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4 }

                            Rectangle {
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4
                                radius: ScreenTools.defaultFontPixelHeight * 0.35
                                color: gimbalPitchDownMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                border.width: 1
                                enabled: _root._gimbalAvailable()

                                Label { anchors.centerIn: parent; text: qsTr("Pitch -"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                                MouseArea {
                                    id: gimbalPitchDownMouse
                                    anchors.fill: parent
                                    enabled: parent.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: _root._nudgeGimbal(-_root._gimbalSpeed, 0)
                                }
                            }

                            Item { Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 3.1; Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.4 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth * 0.5

                            Repeater {
                                model: [
                                    { label: qsTr("Recenter"), action: function() { _root._centerGimbal() } },
                                    { label: qsTr("Look Down"), action: function() { _root._lookGimbalDown() } },
                                    { label: qsTr("Forward"), action: function() { _root._lookGimbalForward() } }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: gimbalPresetMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1
                                    enabled: _root._gimbalAvailable()

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - ScreenTools.defaultFontPixelWidth
                                        text: modelData.label
                                        color: "white"
                                        font.bold: true
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: gimbalPresetMouse
                                        anchors.fill: parent
                                        enabled: parent.enabled
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.action()
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Smooth speed")
                                color: Qt.rgba(1, 1, 1, 0.72)
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: _root._gimbalSpeed.toFixed(0) + "\u00b0"
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 1
                            to: 20
                            stepSize: 1
                            value: _root._gimbalSpeed
                            onMoved: _root._gimbalSpeed = Math.round(value)
                        }
                    }
                }

                Rectangle {
                    visible: true
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? missionShotColumn.height + ScreenTools.defaultFontPixelHeight * 1.1 : 0
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(0.46, 0.90, 0.86, 0.26)
                    border.width: 1

                    ColumnLayout {
                        id: missionShotColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Camera Profiles")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: qsTr("1 tap")
                                color: "#75E6DA"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.5
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.4

                            Repeater {
                                model: [
                                    { title: qsTr("Inspection"), subtitle: qsTr("Zoom + detail"), preset: "inspection" },
                                    { title: qsTr("Cinematic"), subtitle: qsTr("Soft motion"), preset: "cinematic" },
                                    { title: qsTr("Mapping"), subtitle: qsTr("Grid interval"), preset: "mapping" },
                                    { title: qsTr("Low Light"), subtitle: qsTr("Bright assist"), preset: "lowLight" },
                                    { title: qsTr("Evidence"), subtitle: qsTr("Proof metadata"), preset: "evidence" },
                                    { title: qsTr("Payload Proof"), subtitle: qsTr("Burst evidence"), preset: "payloadProof" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 3.2
                                    radius: ScreenTools.defaultFontPixelHeight * 0.35
                                    color: missionShotMouse.containsMouse ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: missionShotMouse.containsMouse ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.42
                                        spacing: 0

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.title
                                            color: "white"
                                            font.bold: true
                                            font.pointSize: ScreenTools.smallFontPointSize
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.subtitle
                                            color: Qt.rgba(1, 1, 1, 0.66)
                                            font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: missionShotMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._applyMissionShotPreset(modelData.preset)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(1, 1, 1, 0.16)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth * 0.45

                            TextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("New profile name")
                                text: _root._savedProfileName
                                selectByMouse: true
                                onTextChanged: _root._savedProfileName = text
                                onAccepted: _root._saveCurrentCameraProfile()
                            }

                            Button {
                                text: qsTr("Save")
                                enabled: _root._savedProfileName.trim().length > 0
                                onClicked: _root._saveCurrentCameraProfile()
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: savedCameraProfiles.count === 0
                            text: qsTr("No saved profiles")
                            color: Qt.rgba(1, 1, 1, 0.58)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        Repeater {
                            model: savedCameraProfiles

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelWidth * 0.45

                                Button {
                                    Layout.fillWidth: true
                                    text: name
                                    onClicked: {
                                        _root._applyProfileSnapshot(settings)
                                        _root._toast(qsTr("Camera profile applied: ") + name)
                                    }
                                }

                                Button {
                                    text: qsTr("Delete")
                                    onClicked: _root._deleteCameraProfile(index)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: proofModeColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: _root._missionProofMode ? Qt.rgba(0.09, 0.63, 0.52, 0.18) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: _root._missionProofMode ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1

                    ColumnLayout {
                        id: proofModeColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Mission Proof Mode")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Switch {
                                checked: _root._missionProofMode
                                onToggled: _root._missionProofMode = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Auto proof at waypoint")
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Switch {
                                checked: _root._autoProofCapture
                                onToggled: {
                                    _root._autoProofCapture = checked
                                    if (checked) {
                                        _root._missionProofMode = true
                                    }
                                }
                            }
                        }

                        TextField {
                            Layout.fillWidth: true
                            placeholderText: qsTr("Mission name")
                            text: _root._missionName
                            selectByMouse: true
                            onEditingFinished: _root._missionName = text
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Proof saves GPS, altitude, time, drone ID, and mission name with captured media.")
                            color: Qt.rgba(1, 1, 1, 0.68)
                            font.pointSize: ScreenTools.smallFontPointSize
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: smartCaptureColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    visible: _root._sectionCaptureOpen
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(0.46, 0.90, 0.86, 0.26)
                    border.width: 1

                    ColumnLayout {
                        id: smartCaptureColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Smart Capture")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: _root._captureModeLabel()
                                color: "#75E6DA"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.45
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Repeater {
                                model: [
                                    { label: qsTr("Single"), mode: "single" },
                                    { label: qsTr("Burst"), mode: "burst" },
                                    { label: qsTr("Interval"), mode: "interval" },
                                    { label: qsTr("Timer"), mode: "timer" },
                                    { label: qsTr("Pano"), mode: "panorama" },
                                    { label: qsTr("Orbit"), mode: "orbit" }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.35
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._captureMode === modelData.mode ? Qt.rgba(0.09, 0.63, 0.52, 0.72) : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._captureMode === modelData.mode ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - ScreenTools.defaultFontPixelWidth
                                        text: modelData.label
                                        color: "white"
                                        font.bold: _root._captureMode === modelData.mode
                                        font.pointSize: ScreenTools.smallFontPointSize
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: _root._setCaptureMode(modelData.mode)
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: _root._captureMode === "burst"
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label { Layout.fillWidth: true; text: qsTr("Burst count"); color: Qt.rgba(1, 1, 1, 0.72); font.pointSize: ScreenTools.smallFontPointSize }
                                Label { text: _root._burstCount; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 3
                                to: 10
                                stepSize: 1
                                value: _root._burstCount
                                onMoved: _root._burstCount = Math.round(value)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: _root._captureMode === "interval" || _root._captureMode === "orbit"
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label { Layout.fillWidth: true; text: qsTr("Interval"); color: Qt.rgba(1, 1, 1, 0.72); font.pointSize: ScreenTools.smallFontPointSize }
                                Label { text: _root._intervalSeconds + "s"; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 2
                                to: 30
                                stepSize: 1
                                value: _root._intervalSeconds
                                onMoved: {
                                    _root._intervalSeconds = Math.round(value)
                                    if (_root._intervalActive) {
                                        intervalCaptureTimer.restart()
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: _root._captureMode === "timer"
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Label { Layout.fillWidth: true; text: qsTr("Timer delay"); color: Qt.rgba(1, 1, 1, 0.72); font.pointSize: ScreenTools.smallFontPointSize }
                                Label { text: _root._timerSeconds + "s"; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                            }

                            Slider {
                                Layout.fillWidth: true
                                from: 2
                                to: 15
                                stepSize: 1
                                value: _root._timerSeconds
                                onMoved: _root._timerSeconds = Math.round(value)
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: _root._captureMode === "panorama" || _root._captureMode === "orbit"
                            text: _root._captureMode === "orbit" ? qsTr("Orbit preset uses interval capture while the pilot flies or starts an orbit.")
                                                                 : qsTr("Panorama captures five frames with center and safe-frame guides.")
                            color: Qt.rgba(1, 1, 1, 0.68)
                            wrapMode: Text.WordWrap
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: ScreenTools.defaultFontPixelWidth * 0.6
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.25
                    visible: false

                    CheckBox {
                        text: qsTr("Thirds")
                        palette.text: "white"
                        palette.windowText: "white"
                        checked: _root._compositionGrid
                        onToggled: _root._compositionGrid = checked
                    }

                    CheckBox {
                        text: qsTr("Reticle")
                        palette.text: "white"
                        palette.windowText: "white"
                        checked: _root._centerMark
                        onToggled: _root._centerMark = checked
                    }

                    CheckBox {
                        text: qsTr("Safe frame")
                        palette.text: "white"
                        palette.windowText: "white"
                        checked: _root._safeFrame
                        onToggled: _root._safeFrame = checked
                    }

                    CheckBox {
                        text: qsTr("Zebra")
                        palette.text: "white"
                        palette.windowText: "white"
                        checked: _root._zebraOverlay
                        onToggled: _root._zebraOverlay = checked
                    }

                    CheckBox {
                        text: qsTr("Peaking")
                        palette.text: "white"
                        palette.windowText: "white"
                        checked: _root._focusPeaking
                        onToggled: _root._focusPeaking = checked
                    }

                    CheckBox {
                        text: qsTr("False color")
                        palette.text: "white"
                        palette.windowText: "white"
                        checked: _root._falseColor
                        onToggled: _root._falseColor = checked
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 4.6
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: Qt.rgba(1, 1, 1, 0.10)
                    border.color: Qt.rgba(1, 1, 1, 0.14)
                    border.width: 1

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        columns: 2
                        columnSpacing: ScreenTools.defaultFontPixelWidth
                        rowSpacing: 2

                        Label { text: qsTr("ISO"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._videoSettings.cameraIso.valueString; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: qsTr("Color"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._cameraColorName(); color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: qsTr("Format"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._recordingFormatName() + qsTr(" / ") + _root._codingFormat; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: qsTr("Quality"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._videoResolution + qsTr(" / ") + _root._frameRate + qsTr(" FPS"); color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: qsTr("Focus"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._focusModeSetting; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: qsTr("Storage"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._storageTarget; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: qsTr("Cloud"); color: Qt.rgba(1, 1, 1, 0.62); font.pointSize: ScreenTools.smallFontPointSize }
                        Label { text: _root._cloudSyncStatus; color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: aiCameraColumn.height + ScreenTools.defaultFontPixelHeight * 1.1
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    visible: _root.aiDetectionEnabled
                    color: Qt.rgba(1, 1, 1, 0.08)
                    border.color: _root.aiAutoCaptureEnabled ? "#75E6DA" : Qt.rgba(0.46, 0.90, 0.86, 0.24)
                    border.width: 1

                    ColumnLayout {
                        id: aiCameraColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.55
                        spacing: ScreenTools.defaultFontPixelHeight * 0.45

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("AI Camera Mode")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Label {
                                text: aiDetectionOverlay.modelReady ? qsTr("Ready") : qsTr("Loading")
                                color: aiDetectionOverlay.modelReady ? "#75E6DA" : "#FFB020"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.7
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.35

                            Label { text: qsTr("Detected"); color: Qt.rgba(1, 1, 1, 0.64); font.pointSize: ScreenTools.smallFontPointSize }
                            Label { Layout.fillWidth: true; text: aiDetectionOverlay.detections ? aiDetectionOverlay.detections.length : 0; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                            Label { text: qsTr("Last capture"); color: Qt.rgba(1, 1, 1, 0.64); font.pointSize: ScreenTools.smallFontPointSize }
                            Label { Layout.fillWidth: true; text: _root._aiLastDetectionLabel; color: "#75E6DA"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize; elide: Text.ElideRight }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Person / vehicle only")
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Switch {
                                checked: _root.aiPersonVehicleOnly
                                onToggled: _root.aiPersonVehicleOnly = checked
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Capture on detection")
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            Switch {
                                checked: _root.aiAutoCaptureEnabled
                                onToggled: {
                                    _root.aiAutoCaptureEnabled = checked
                                    if (checked) {
                                        _root._missionProofMode = true
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Peaking level")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            columnSpacing: ScreenTools.defaultFontPixelWidth * 0.35

                            Repeater {
                                model: [ "OFF", "Low", "Normal", "High" ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.15
                                    radius: ScreenTools.defaultFontPixelHeight * 0.32
                                    color: _root._peakingLevel === modelData ? "#16A085" : Qt.rgba(1, 1, 1, 0.10)
                                    border.color: _root._peakingLevel === modelData ? "#75E6DA" : Qt.rgba(1, 1, 1, 0.20)
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - ScreenTools.defaultFontPixelWidth * 0.4
                                        text: modelData
                                        color: "white"
                                        font.bold: _root._peakingLevel === modelData
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            _root._peakingLevel = modelData
                                            _root._focusPeaking = modelData !== "OFF"
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label { Layout.fillWidth: true; text: qsTr("Cooldown"); color: Qt.rgba(1, 1, 1, 0.72); font.pointSize: ScreenTools.smallFontPointSize }
                            Label { text: _root.aiAutoCaptureCooldownSeconds + "s"; color: "white"; font.bold: true; font.pointSize: ScreenTools.smallFontPointSize }
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 3
                            to: 60
                            stepSize: 1
                            value: _root.aiAutoCaptureCooldownSeconds
                            onMoved: _root.aiAutoCaptureCooldownSeconds = Math.round(value)
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Reset camera parameters")
                    onClicked: _root._resetAllCameraParameters()
                }
            }
        }
    }

    Item {
        id: obstacleAvoidanceIndicator
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 2
        anchors.topMargin: ScreenTools.defaultFontPixelHeight * 5.2
        width: Math.max(ScreenTools.defaultFontPixelWidth * 23, 220)
        height: width
        visible: _root._showCameraStudio &&
                 _root._obstacleAvoidanceEnabled &&
                 _root._obstacleWarningActive
        z: 130

        property color obstacleStatusColor: _root._obstacleIndicatorColor()

        Label {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("OBSTACLE ") + _root._nearestObstacleDirection
            color: obstacleAvoidanceIndicator.obstacleStatusColor
            font.bold: true
            font.pointSize: ScreenTools.smallFontPointSize
            font.letterSpacing: 0.8
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#D9000000"
                shadowBlur: 0.55
                shadowVerticalOffset: 1
            }
        }

        Item {
            id: obstacleArc
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 1.35
            width: Math.min(parent.width, parent.height) - ScreenTools.defaultFontPixelWidth
            height: width

            property real arcRadius: width * 0.35
            property real dotSize: Math.max(4, ScreenTools.defaultFontPixelHeight * 0.32)
            property real centerX: width / 2
            property real centerY: height / 2

            Repeater {
                id: obstacleDirectionArcs
                model: [
                    { label: qsTr("F"), distance: _root._frontObstacleDistance, centerAngle: -Math.PI / 2 },
                    { label: qsTr("R"), distance: _root._rightObstacleDistance, centerAngle: 0 },
                    { label: qsTr("B"), distance: _root._rearObstacleDistance, centerAngle: Math.PI / 2 },
                    { label: qsTr("L"), distance: _root._leftObstacleDistance, centerAngle: Math.PI }
                ]

                Item {
                    id: directionArc
                    required property var modelData
                    anchors.fill: parent
                    property real directionDistance: Number(modelData.distance)
                    property string directionLevel: _root._obstacleLevelForDistance(directionDistance)
                    property color directionColor: _root._obstacleColorForDistance(directionDistance)
                    visible: directionLevel === "danger" || directionLevel === "caution"

                    Repeater {
                        id: directionDots
                        model: 9

                        Rectangle {
                            required property int index
                            property real arcAngle: directionArc.modelData.centerAngle -
                                                    Math.PI * 0.18 +
                                                    (index / (directionDots.count - 1)) * Math.PI * 0.36

                            x: obstacleArc.centerX + Math.cos(arcAngle) * obstacleArc.arcRadius - width / 2
                            y: obstacleArc.centerY + Math.sin(arcAngle) * obstacleArc.arcRadius - height / 2
                            width: obstacleArc.dotSize
                            height: width
                            radius: width / 2
                            color: directionArc.directionColor
                            opacity: 1

                            Behavior on color {
                                ColorAnimation { duration: 220 }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 180 }
                            }

                            SequentialAnimation on scale {
                                running: directionArc.directionLevel === "danger"
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.45; duration: 420; easing.type: Easing.OutQuad }
                                NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InQuad }
                            }
                        }
                    }

                    Label {
                        x: obstacleArc.centerX +
                           Math.cos(directionArc.modelData.centerAngle) * obstacleArc.arcRadius * 1.27 -
                           width / 2
                        y: obstacleArc.centerY +
                           Math.sin(directionArc.modelData.centerAngle) * obstacleArc.arcRadius * 1.27 -
                           height / 2
                        text: directionArc.modelData.label + " " +
                              directionArc.directionDistance.toFixed(1) + qsTr(" m")
                        color: directionArc.directionColor
                        font.bold: true
                        font.pointSize: ScreenTools.smallFontPointSize * 0.82
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#E6000000"
                            shadowBlur: 0.5
                            shadowVerticalOffset: 1
                        }
                    }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: obstacleArc.arcRadius * 0.78
                height: width

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.25
                    height: parent.height * 0.68
                    radius: width * 0.35
                    color: Qt.rgba(0.46, 0.90, 0.86, 0.82)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.76
                    height: parent.height * 0.13
                    radius: height / 2
                    color: Qt.rgba(0.46, 0.90, 0.86, 0.82)
                }

                Repeater {
                    model: [
                        { xPos: 0.10, yPos: 0.18 },
                        { xPos: 0.68, yPos: 0.18 },
                        { xPos: 0.10, yPos: 0.66 },
                        { xPos: 0.68, yPos: 0.66 }
                    ]

                    Rectangle {
                        required property var modelData
                        x: parent.width * modelData.xPos
                        y: parent.height * modelData.yPos
                        width: parent.width * 0.22
                        height: width
                        radius: width / 2
                        color: Qt.rgba(0.46, 0.90, 0.86, 0.68)
                        border.color: Qt.rgba(1, 1, 1, 0.42)
                        border.width: 1
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: parent.width * 0.14
                    height: parent.height * 0.22
                    radius: width / 2
                    color: "white"
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: obstacleArc.arcRadius * 0.72
                spacing: -1

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: isNaN(_root._nearestObstacleDistance)
                          ? qsTr("--")
                          : _root._nearestObstacleDistance.toFixed(1) + qsTr(" m")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.15
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#E6000000"
                        shadowBlur: 0.5
                        shadowVerticalOffset: 1
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: _root._nearestObstacleDirection
                    color: obstacleAvoidanceIndicator.obstacleStatusColor
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize * 0.85
                    font.letterSpacing: 0.8

                    Behavior on color {
                        ColorAnimation { duration: 220 }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#E6000000"
                        shadowBlur: 0.5
                        shadowVerticalOffset: 1
                    }
                }
            }
        }
    }

    ProximityRadarVideoView{
        anchors.fill:   parent
        vehicle:        QGroundControl.multiVehicleManager.activeVehicle
        visible:        _root._videoIsFull
    }

    ObstacleDistanceOverlayVideo {
        id: obstacleDistance
        visible: _root._videoIsFull
        showText: pipState.state === pipState.fullState
    }
}
