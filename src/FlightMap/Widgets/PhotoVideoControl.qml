/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtPositioning
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.FactControls

Rectangle {
    id: bgRect
    width:      mainLayout.width + (_margins * 2.5)
    height:     mainLayout.height + (_margins * 2.5)
    color:      "transparent"
    radius:     16
    border.width: 0
    visible:    _camera.capturesVideo || _camera.capturesPhotos

    anchors.top: parent.top
    anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.8
property bool isTablet: Screen.width >= 800
    readonly property real baseSize: isTablet
                                     ? ScreenTools.defaultFontPixelHeight * 1.8
                                     : ScreenTools.defaultFontPixelHeight * 1.8
    property real iconSize: baseSize * 1
    property real   _margins:                   ScreenTools.defaultFontPixelHeight / 2
    property real   _smallMargins:              ScreenTools.defaultFontPixelWidth / 2
    property var    _activeVehicle:             globals.activeVehicle
    property var    _cameraManager:             _activeVehicle.cameraManager
    property var    _camera:                    _cameraManager.currentCameraInstance
    property bool   _cameraInPhotoMode:         _camera.cameraMode === MavlinkCameraControl.CAM_MODE_PHOTO
    property bool   _cameraInVideoMode:         !_cameraInPhotoMode
    property bool   _videoCaptureIdle:          _camera.videoCaptureStatus === MavlinkCameraControl.VIDEO_CAPTURE_STATUS_STOPPED
    property bool   _photoCaptureSingleIdle:    _camera.photoCaptureStatus === MavlinkCameraControl.PHOTO_CAPTURE_IDLE
    property bool   _photoCaptureIntervalIdle:  _camera.photoCaptureStatus === MavlinkCameraControl.PHOTO_CAPTURE_INTERVAL_IDLE
    property bool   _photoCaptureIdle:          _photoCaptureSingleIdle || _photoCaptureIntervalIdle
    property bool   _isSelectingMode:           false
    
    // Properties for last captured photo/video
    property string lastCapturedPath: ""
    property bool   isLastCaptureVideo: false

    function toUrl(filePath) {
        if (!filePath) return "";
        if (filePath.indexOf("file://") === 0) {
            return filePath;
        }
        var cleanPath = filePath.replace(/\\/g, "/");
        if (cleanPath.indexOf(":") === 1) {
            return "file:///" + cleanPath;
        }
        if (cleanPath.indexOf("/") !== 0) {
            return "file:///" + cleanPath;
        }
        return "file://" + cleanPath;
    }

    Connections {
        target: QGroundControl.videoManager
        function onImageFileChanged() {
            var path = QGroundControl.videoManager.imageFile;
            if (path && path !== "") {
                lastCapturedPath = toUrl(path);
                isLastCaptureVideo = !_cameraInPhotoMode;
                // Trigger toast preview
                toastTimer.stop();
                hideToastAnimation.stop();
                showToastAnimation.start();
            }
        }
        function onRecordingChanged() {
            if (!QGroundControl.videoManager.recording) {
                // Grab screenshot of the video when recording stops
                QGroundControl.videoManager.grabImage();
            }
        }
    }

    // Camera Shutter animation overlay
    Item {
        id: shutterOverlay
        anchors.fill: mainWindow.contentItem
        z: 99999
        visible: false

        Rectangle {
            id: topShutter
            anchors.top: parent.top
            width: parent.width
            height: 0
            color: "black"
        }

        Rectangle {
            id: bottomShutter
            anchors.bottom: parent.bottom
            width: parent.width
            height: 0
            color: "black"
        }

        SequentialAnimation {
            id: shutterAnimation
            
            ScriptAction {
                script: {
                    shutterOverlay.visible = true;
                }
            }
            
            // Close shutter
            ParallelAnimation {
                NumberAnimation {
                    target: topShutter
                    property: "height"
                    to: shutterOverlay.height / 2
                    duration: 120
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: bottomShutter
                    property: "height"
                    to: shutterOverlay.height / 2
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }
            
            // Open shutter
            ParallelAnimation {
                NumberAnimation {
                    target: topShutter
                    property: "height"
                    to: 0
                    duration: 120
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: bottomShutter
                    property: "height"
                    to: 0
                    duration: 120
                    easing.type: Easing.InQuad
                }
            }
            
            ScriptAction {
                script: {
                    shutterOverlay.visible = false;
                }
            }
        }
    }

    // Captured Media Toast Preview
    Rectangle {
        id: mediaToastPreview
        anchors.centerIn: mainWindow.contentItem
        width: Math.min(mainWindow.contentItem.width * 0.5, ScreenTools.defaultFontPixelHeight * 20)
        height: width * (9/16)
        radius: 12
        color: "#1e1e1e"
        border.color: "white"
        border.width: 2
        clip: true
        z: 99998
        opacity: 0
        scale: 0.8
        visible: false

        Image {
            anchors.fill: parent
            source: lastCapturedPath
            fillMode: Image.PreserveAspectCrop
            cache: false
        }

        // Dark gradient overlay at the bottom for text readability
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * 0.3
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
            }
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 8

            QGCColoredImage {
                width: 16
                height: 16
                source: isLastCaptureVideo ? "/qmlimages/camera_video.svg" : "/qmlimages/camera_photo.svg"
                color: "white"
                fillMode: Image.PreserveAspectFit
            }

            QGCLabel {
                text: isLastCaptureVideo ? qsTr("Video Saved Successfully") : qsTr("Photo Saved Successfully")
                color: "white"
                font.bold: true
                font.pointSize: ScreenTools.smallFontPointSize
            }
        }

        // Show/hide animations
        ParallelAnimation {
            id: showToastAnimation
            ScriptAction {
                script: {
                    mediaToastPreview.visible = true;
                }
            }
            NumberAnimation {
                target: mediaToastPreview
                property: "opacity"
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: mediaToastPreview
                property: "scale"
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
            }
            onFinished: toastTimer.start()
        }

        ParallelAnimation {
            id: hideToastAnimation
            NumberAnimation {
                target: mediaToastPreview
                property: "opacity"
                to: 0.0
                duration: 250
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: mediaToastPreview
                property: "scale"
                to: 0.8
                duration: 250
                easing.type: Easing.InQuad
            }
            onFinished: mediaToastPreview.visible = false
        }

        Timer {
            id: toastTimer
            interval: 2500
            repeat: false
            onTriggered: hideToastAnimation.start()
        }
    }

    // Full Screen Preview Dialog
    Popup {
        id: previewPopup
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: parent.height * 0.9
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.9)
            radius: 16
            border.color: "#3d3d3d"
            border.width: 1
        }

        contentItem: Item {
            Image {
                anchors.fill: parent
                anchors.margins: 20
                source: lastCapturedPath
                fillMode: Image.PreserveAspectFit
                cache: false
            }

            QGCLabel {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 20
                text: isLastCaptureVideo ? qsTr("Last Captured Video Frame") : qsTr("Last Captured Photo")
                color: "white"
                font.bold: true
                font.pointSize: ScreenTools.largeFontPointSize
            }

            QGCButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 20
                text: qsTr("Close")
                onClicked: previewPopup.close()
            }
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    DeadMouseArea { anchors.fill: parent }

    RowLayout {
        id:                 mainLayout
        anchors.margins:    _margins
        anchors.top:        parent.top
        anchors.left:       parent.left
        spacing:            _margins

        ColumnLayout {
            Layout.fillHeight:  true
            spacing:            _margins
            visible:            _camera.hasZoom

            QGCLabel {
                Layout.alignment:   Qt.AlignHCenter
                text:               qsTr("Zoom")
                font.pointSize:     ScreenTools.smallFontPointSize
            }

            QGCSlider {
                Layout.alignment:   Qt.AlignHCenter
                Layout.fillHeight:  true
                orientation:        Qt.Vertical
                to:                 100
                from:               0
                value:              _camera.zoomLevel
                live:               true
                onValueChanged:     _camera.zoomLevel = value
            }
        }

        ColumnLayout {
            spacing: 0

            ColumnLayout {
                spacing: _margins * 0.8

                // Camera name
                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               _camera.modelName
                    visible:            _cameraManager.cameras.length > 1
                }

                // Premium Mode Toggle Switch
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: ScreenTools.defaultFontPixelWidth * 11
                    height: ScreenTools.defaultFontPixelHeight * 2.2
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.45)
                    border.color: Qt.rgba(1, 1, 1, 0.2)
                    border.width: 1

                    // Highlight Toggle Pill
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: parent.radius
                        color: _cameraInPhotoMode ? "white" : qgcPal.colorRed
                        x: _cameraInPhotoMode ? 0 : parent.width / 2
                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }

                    Row {
                        anchors.fill: parent

                        // Photo Button
                        Item {
                            width: parent.width / 2
                            height: parent.height
                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: isTablet ? 20 : 15
                                height: width
                                source: "/qmlimages/camera_photo.svg"
                                color: _cameraInPhotoMode ? "black" : "white"
                                Behavior on color { ColorAnimation { duration: 300 } }
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    _camera.setCameraModePhoto()
                                    shutterAnimation.start()
                                }
                            }
                        }

                        // Video Button
                        Item {
                            width: parent.width / 2
                            height: parent.height
                            QGCColoredImage {
                                anchors.centerIn: parent
                                width:isTablet ? 20 : 15
                                height: width
                                source: "/qmlimages/camera_video.svg"
                                color: "white" // Always white on red or dark background
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: _camera.setCameraModeVideo()
                            }
                        }
                    }
                }

                // Animated Shutter Button
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    width: ScreenTools.defaultFontPixelWidth * 5.5
                    height: width

                    Rectangle {
                        id: outerShutterRing
                        anchors.centerIn: parent
                        width: parent.width
                        height: width
                        radius: width / 2
                        border.color: "white"
                        border.width: 3
                        color: "transparent"
                        opacity: shutterMouseArea.containsMouse ? 0.8 : 1.0
                        scale: shutterMouseArea.pressed ? 0.94 : (shutterMouseArea.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * (_isShootingInCurrentMode ? 0.45 : 0.8)
                        height: width
                        radius: _isShootingInCurrentMode ? 6 : width / 2
                        color: _cameraInPhotoMode ? "white" : qgcPal.colorRed

                        property bool _isShootingInPhotoMode: _cameraInPhotoMode && _camera.photoCaptureStatus === MavlinkCameraControl.PHOTO_CAPTURE_IN_PROGRESS
                        property bool _isShootingInVideoMode: (!_cameraInPhotoMode && _camera.videoCaptureStatus === MavlinkCameraControl.VIDEO_CAPTURE_STATUS_RUNNING)
                        property bool _isShootingInCurrentMode: _cameraInPhotoMode ? _isShootingInPhotoMode : _isShootingInVideoMode

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }

                    MouseArea {
                        id: shutterMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (_cameraInPhotoMode) {
                                if (_camera.photoCaptureStatus === MavlinkCameraControl.PHOTO_CAPTURE_INTERVAL_IN_PROGRESS) {
                                    _camera.stopTakePhoto()
                                } else {
                                    _camera.takePhoto()
                                    QGroundControl.videoManager.grabImage()
                                    shutterAnimation.start()
                                }
                            } else {
                                _camera.toggleVideoRecording()
                            }
                        }
                    }
                }

                // Record time / Capture count with animated recording pulse
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: _smallMargins

                    // Recording Red Dot indicator
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: qgcPal.colorRed
                        visible: _cameraInVideoMode && !_videoCaptureIdle

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: _cameraInVideoMode && !_videoCaptureIdle
                            NumberAnimation { to: 0.2; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }

                    QGCLabel {
                        text: _cameraInVideoMode ? (_videoCaptureIdle ? "00:00:00" : _camera.recordTimeStr) :
                                                   (_activeVehicle ? ('00000' + _activeVehicle.cameraTriggerPoints.count).slice(-5) : "00000")
                        color: "white"
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.bold: !_videoCaptureIdle
                    }
                }

                //-- Status Information
                ColumnLayout {
                    Layout.alignment:   Qt.AlignHCenter
                    spacing:            0
                    visible:            !_isSelectingMode

                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("Free Space: ") + _camera.storageFreeStr
                        font.pointSize:     ScreenTools.defaultFontPointSize
                        visible:            _camera.storageStatus === MavlinkCameraControl.STORAGE_READY
                    }

                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("Battery: ") + _camera.batteryRemainingStr
                        font.pointSize:     ScreenTools.defaultFontPointSize
                        visible:            _camera.batteryRemaining >= 0
                    }
                }
            }

            ColumnLayout {
                id:                 trackingControls
                Layout.alignment:   Qt.AlignHCenter
                spacing:            _margins
                visible:            !_isSelectingMode && _camera && _camera.hasTracking

                Rectangle {
                    Layout.alignment:       Qt.AlignHCenter
                    color:                  _camera.trackingEnabled ? qgcPal.colorRed : qgcPal.windowShadeLight
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 6
                    Layout.preferredHeight: Layout.preferredWidth
                    border.color:           qgcPal.buttonText
                    border.width:           3

                    QGCColoredImage {
                        height:             parent.height * 0.5
                        width:              height
                        anchors.centerIn:   parent
                        source:             "/qmlimages/TrackingIcon.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height
                        color:              qgcPal.text

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _camera.trackingEnabled = !_camera.trackingEnabled;
                                if (!_camera.trackingEnabled) {
                                    !camera.stopTracking()
                                }
                            }
                        }
                    }
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Camera Tracking")
                    font.pointSize:     ScreenTools.defaultFontPointSize
                    visible:            _camera && _camera.hasTracking
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: _margins * 2

                // Last Captured Media Preview Thumbnail
                Item {
                    id: thumbnailPreview
                    width: ScreenTools.defaultFontPixelHeight * 2
                    height: width
                    visible: lastCapturedPath !== ""

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: "black"
                        border.color: "white"
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: lastCapturedPath
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                        }

                        // Play indicator icon if it was a video
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.4
                            height: width
                            radius: width / 2
                            color: Qt.rgba(0, 0, 0, 0.6)
                            visible: isLastCaptureVideo

                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: parent.width * 0.6
                                height: width
                                source: "/qmlimages/camera_video.svg"
                                color: "white"
                                fillMode: Image.PreserveAspectFit
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            previewPopup.open()
                        }
                    }
                }

                // Settings Gear Button
                Item {
                    width: ScreenTools.defaultFontPixelHeight * 1.5
                    height: width

                    QGCColoredImage {
                        id: gearIcon
                        anchors.centerIn: parent
                        height: parent.height * 0.6
                        width: height
                        source: "/res/gear-black.svg"
                        mipmap: true
                        sourceSize.height: height
                        color: "white"
                        fillMode: Image.PreserveAspectFit

                        scale: gearMouseArea.containsMouse ? 1.15 : 1.0
                        rotation: gearMouseArea.containsMouse ? 45 : 0
                        Behavior on scale { NumberAnimation { duration: 200 } }
                        Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        id: gearMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: settingsDialogComponent.createObject(mainWindow).open()
                    }
                }
            }
        }

        Component {
            id: settingsDialogComponent

            QGCPopupDialog {
                title:      qsTr("Settings")
                buttons:    Dialog.Close

                property bool _multipleMavlinkCameras:          _cameraManager.cameras.count > 1
                property bool _multipleMavlinkCameraStreams:    _camera.streamLabels.length > 1
                property bool _cameraStorageSupported:          _camera.storageStatus !== MavlinkCameraControl.STORAGE_NOT_SUPPORTED
                property var  _videoSettings:                   QGroundControl.settingsManager.videoSettings

                Column {
                    spacing: 0
                    width:  35 * ScreenTools.defaultFontPixelWidth

                    Rectangle {
                        width:          parent.width
                        height:         settingsCol.height
                        color:          "transparent"
                        border.color:   "#E2E8F0"
                        border.width:   1
                        radius:         8
                        clip:           true

                        Column {
                            id:         settingsCol
                            width:      parent.width
                            spacing:    0

                            // 1. Camera
                            Rectangle {
                                width: parent.width; height: 60; visible: _multipleMavlinkCameras
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Camera"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: _cameraManager.cameraLabels
                                        currentIndex: _cameraManager.currentCamera
                                        onActivated: (index) => { _cameraManager.currentCamera = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 2. Video Stream
                            Rectangle {
                                width: parent.width; height: 60; visible: _multipleMavlinkCameraStreams
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Video Stream"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: _camera.streamLabels
                                        currentIndex: _camera.currentStream
                                        onActivated: (index) => { _camera.currentStream = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 3. Thermal View Mode
                            Rectangle {
                                width: parent.width; height: 60; visible: _camera.thermalStreamInstance
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Thermal View Mode"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: [ qsTr("Off"), qsTr("Blend"), qsTr("Full"), qsTr("Picture In Picture") ]
                                        currentIndex: _camera.thermalMode
                                        onActivated: (index) => { _camera.thermalMode = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 4. Blend Opacity
                            Rectangle {
                                width: parent.width; height: 60; visible: _camera.thermalStreamInstance && _camera.thermalMode === MavlinkCameraControl.THERMAL_BLEND
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Blend Opacity"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCSlider {
                                        Layout.preferredWidth: 150
                                        to: 100; from: 0; live: true; value: _camera.thermalOpacity
                                        onValueChanged: _camera.thermalOpacity = value
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 5. Active Settings Repeater
                            Repeater {
                                model: _camera.activeSettings
                                Rectangle {
                                    width: parent.width; height: 60
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                        property var    _fact:      _camera.getFact(modelData)
                                        property bool   _isBool:    _fact.typeIsBool
                                        property bool   _isCombo:   !_isBool && _fact.enumStrings.length > 0
                                        property bool   _isSlider:  _fact && !isNaN(_fact.increment)
                                        property bool   _isEdit:    !_isBool && !_isSlider && _fact.enumStrings.length < 1

                                        QGCLabel { text: parent._fact ? parent._fact.shortDescription : ""; Layout.fillWidth: true; color: "#2C3E50"; font.bold: true; elide: Text.ElideRight }

                                        FactComboBox {
                                            Layout.preferredWidth: 150; sizeToContents: true; fact: parent._fact; indexModel: false; visible: parent._isCombo
                                        }
                                        FactTextField {
                                            Layout.preferredWidth: 150; fact: parent._fact; visible: parent._isEdit
                                        }
                                        QGCSlider {
                                            Layout.preferredWidth: 150; to: parent._fact.max; from: parent._fact.min; stepSize: parent._fact.increment; visible: parent._isSlider; live: false
                                            property bool initialized: false
                                            onValueChanged: { if (initialized) parent._fact.value = value }
                                            Component.onCompleted: { value = parent._fact.value; initialized = true }
                                        }
                                        QGCSwitch {
                                            checked: parent._fact ? parent._fact.value : false; visible: parent._isBool
                                            onClicked: parent._fact.value = checked ? 1 : 0
                                        }
                                    }
                                    Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                                }
                            }

                            // 6. Photo Mode
                            Rectangle {
                                width: parent.width; height: 60; visible: _camera.capturesPhotos
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Photo Mode"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: [ qsTr("Single"), qsTr("Time Lapse") ]
                                        currentIndex: _camera.photoCaptureMode
                                        onActivated: (index) => { _camera.photoCaptureMode = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 7. Photo Interval
                            Rectangle {
                                width: parent.width; height: 60; visible: _camera.capturesPhotos && _camera.photoCaptureMode === MavlinkCameraControl.PHOTO_CAPTURE_TIMELAPSE
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Photo Interval (sec)"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCSlider {
                                        Layout.preferredWidth: 150
                                        to: 60; from: 1; stepSize: 1; live: true; value: _camera.photoLapse; displayValue: true
                                        onValueChanged: _camera.photoLapse = value
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 8. Video Grid Lines
                            Rectangle {
                                width: parent.width; height: 60; visible: _camera.hasVideoStream
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Video Grid Lines"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCSwitch {
                                        checked: _videoSettings.gridLines.rawValue
                                        onClicked: _videoSettings.gridLines.rawValue = checked ? 1 : 0
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 9. Video Screen Fit
                            Rectangle {
                                width: parent.width; height: 60; visible: _camera.hasVideoStream
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Video Screen Fit"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    FactComboBox {
                                        Layout.preferredWidth: 150
                                        fact: _videoSettings.videoFit
                                        indexModel: false
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 10. Reset Camera Defaults
                            Rectangle {
                                width: parent.width; height: 60
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Reset Camera Defaults"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCButton {
                                        text: qsTr("Reset")
                                        Layout.preferredWidth: 100
                                        onClicked: resetPrompt.open()
                                    }
                                }
                                MessageDialog {
                                    id: resetPrompt
                                    title: qsTr("Reset Camera to Factory Settings")
                                    text: qsTr("Confirm resetting all settings?")
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes) { _camera.resetSettings(); resetPrompt.close() }
                                        else resetPrompt.close()
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom; visible: _cameraStorageSupported }
                            }

                            // 11. Storage Format
                            Rectangle {
                                width: parent.width; height: 60; visible: _cameraStorageSupported
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                    QGCLabel { text: qsTr("Storage"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCButton {
                                        text: qsTr("Format")
                                        Layout.preferredWidth: 100
                                        onClicked: formatPrompt.open()
                                    }
                                }
                                MessageDialog {
                                    id: formatPrompt
                                    title: qsTr("Format Camera Storage")
                                    text: qsTr("Confirm erasing all files?")
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes) { _camera.formatCard(); formatPrompt.close() }
                                        else formatPrompt.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
