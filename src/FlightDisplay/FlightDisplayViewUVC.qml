/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtMultimedia

import QGroundControl

Rectangle {
    id:                 _root
    width:              getWidth()
    height:             getHeight()
    color:              Qt.rgba(0,0,0,0.75)
    clip:               true
    anchors.centerIn:   parent
    visible:            _localCameraAvailable

    property var _videoManager: QGroundControl.videoManager
    property bool _localCameraAvailable: mediaDevices.videoInputs.length > 0
    property bool recording: mediaRecorder.recorderState === MediaRecorder.RecordingState || mediaRecorder.recorderState === MediaRecorder.PausedState
    property bool paused: mediaRecorder.recorderState === MediaRecorder.PausedState
    property string lastPhotoFile: ""
    property string lastVideoFile: ""
    property bool _stopRecordingRequested: false
    property double _cameraAspectRatio: 0
    property double _ar: QGroundControl.videoManager.aspectRatio !== 0.0 ? QGroundControl.videoManager.aspectRatio : _cameraAspectRatio
    property int _fitMode: QGroundControl.settingsManager.videoSettings.videoFit.rawValue
    property string _desiredResolution: QGroundControl.loadGlobalSetting("Camera.VideoResolution", "1080p")
    property int _desiredFrameRate: Number(QGroundControl.loadGlobalSetting("Camera.FrameRate", "30"))

    signal recordingSaved(string filePath)
    signal recordingFailed(string filePath)

    function getWidth() {
        if (_fitMode === 0 || _fitMode === 2) {
            return parent.width
        }
        return _ar !== 0.0 ? parent.height * _ar : parent.width
    }

    function getHeight() {
        if (_fitMode === 1 || _fitMode === 2) {
            return parent.height
        }
        return _ar !== 0.0 ? parent.width * (1 / _ar) : parent.height
    }

    function adjustAspectRatio() {
        var resolution = camera.cameraFormat.resolution
        if (resolution.height > 0 && resolution.width > 0) {
            _root._cameraAspectRatio = resolution.width / resolution.height
        }
    }

    function capturePhoto(filePath) {
        if (!filePath || filePath.length === 0) {
            return false
        }
        lastPhotoFile = filePath
        _root.grabToImage(function(result) {
            result.saveToFile(filePath)
        })
        return true
    }

    function _resolutionHeight(resolutionName) {
        switch (resolutionName) {
        case "720p":
            return 720
        case "2.7K":
            return 1520
        case "4K":
            return 2160
        case "5.1K":
            return 2700
        default:
            return 1080
        }
    }

    function applyRecordingProfile() {
        _desiredResolution = QGroundControl.loadGlobalSetting("Camera.VideoResolution", "1080p")
        _desiredFrameRate = Number(QGroundControl.loadGlobalSetting("Camera.FrameRate", "30"))
        if (!camera.cameraDevice || !camera.cameraDevice.videoFormats) {
            return false
        }

        var formats = camera.cameraDevice.videoFormats
        if (!formats || formats.length === undefined) {
            return false
        }

        var targetHeight = _resolutionHeight(_desiredResolution)
        var bestFormat = null
        var bestScore = 999999
        for (var i = 0; i < formats.length; i++) {
            var format = formats[i]
            if (!format || !format.resolution || format.resolution.height <= 0) {
                continue
            }
            var fpsMin = format.minFrameRate ? format.minFrameRate : 0
            var fpsMax = format.maxFrameRate ? format.maxFrameRate : 999
            var fpsPenalty = (_desiredFrameRate >= fpsMin && _desiredFrameRate <= fpsMax) ? 0 : Math.min(Math.abs(_desiredFrameRate - fpsMin), Math.abs(_desiredFrameRate - fpsMax)) * 20
            var score = Math.abs(format.resolution.height - targetHeight) + fpsPenalty
            if (score < bestScore) {
                bestScore = score
                bestFormat = format
            }
        }

        if (bestFormat) {
            camera.cameraFormat = bestFormat
            adjustAspectRatio()
            return true
        }
        return false
    }

    function startRecording(filePath) {
        if (!filePath || filePath.length === 0 || recording) {
            return false
        }
        applyRecordingProfile()
        lastVideoFile = filePath
        _stopRecordingRequested = false
        mediaRecorder.outputLocation = "file:///" + filePath.replace(/\\/g, "/")
        mediaRecorder.record()
        return true
    }

    function stopRecording() {
        if (!recording && !paused) {
            return false
        }
        _stopRecordingRequested = true
        mediaRecorder.stop()
        return true
    }

    function pauseRecording() {
        if (!recording || paused) {
            return false
        }
        mediaRecorder.pause()
        return true
    }

    function resumeRecording() {
        if (!paused) {
            return false
        }
        mediaRecorder.record()
        return true
    }

    MediaDevices {
        id: mediaDevices

        function findCameraDevice(cameraId) {
            var videoInputs = mediaDevices.videoInputs
            for (var i = 0; i < videoInputs.length; i++) {
                if (videoInputs[i].description === cameraId) {
                    return videoInputs[i]
                }
            }
            return mediaDevices.defaultVideoInput
        }
    }

    CaptureSession {
        camera: Camera {
            id:             camera
            cameraDevice:   mediaDevices.findCameraDevice(_videoManager.uvcVideoSourceID)
            active:         _localCameraAvailable

            onCameraDeviceChanged: {
                if (active) {
                    adjustAspectRatio()
                }
            }

            onActiveChanged: {
                if (active) {
                    adjustAspectRatio()
                }
            }
        }
        videoOutput: videoOutput
        imageCapture: ImageCapture {
            id: imageCapture
        }
        recorder: MediaRecorder {
            id: mediaRecorder
            onRecorderStateChanged: {
                if (recorderState === MediaRecorder.StoppedState && _root._stopRecordingRequested) {
                    _root._stopRecordingRequested = false
                    _root.recordingSaved(_root.lastVideoFile)
                }
            }
            onErrorOccurred: {
                _root._stopRecordingRequested = false
                _root.recordingFailed(_root.lastVideoFile)
            }
        }
    }

    VideoOutput {
        id:             videoOutput
        anchors.fill:   parent
        fillMode:       _fitMode === 2 ? VideoOutput.Stretch : VideoOutput.PreserveAspectFit
    }
}
