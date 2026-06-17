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

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
//import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// 3D Viewer modules
import Viewer3D

Item {
    id: _root

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController
    property var pipView:           _pipView

    // Properties of UTM adapter
    property bool utmspSendActTrigger: false
    property string planType:""

    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }


    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property bool   _aiMode:                planType === "AI" || QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "AI"
    property bool   _locationMapOverride:   false
    property bool   _cameraLocationMapOpen: false
    property bool   _cameraShotHoverMode: true
    property bool   _cameraRouteRunning: false
    property bool   _cameraRouteWaitingForTakeoff: false
    property bool   _cameraRouteCaptureStarted: false
    property int    _cameraRouteCurrentIndex: -1
    property int    _cameraRouteDwellTicks: 0
    property int    _cameraRouteTakeoffAltitude: 25
    property int    _cameraRouteArrivalMeters: 5
    property string _cameraRouteCaptureMode: "photo"
    property bool   _cameraMode:            !_locationMapOverride && (planType === "Camera" || QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Camera" || _aiMode)
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedActionList:      guidedActionList
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    Component.onCompleted: {
        console.log("PlanView received planType:", planType);
    }

    onVisibleChanged: {
        if (!visible) {
            _pipView._setPipIsExpanded(false)
        }
    }

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
    }


    function camerastate() {
        console.log("FlyView camerastate");
        _locationMapOverride = false
        _cameraLocationMapOpen = false
        planType = "Camera"
        _pipView._initForItems()
        Qt.callLater(_forceCameraMainView)
    }

    function videoModeState(modeName) {
        console.log("FlyView videoModeState", modeName);
        _locationMapOverride = false
        _cameraLocationMapOpen = false
        planType = modeName ? modeName : "Camera"
        _pipView._initForItems()
        if (planType === "Camera" || planType === "AI") {
            Qt.callLater(_forceCameraMainView)
        }
        if (planType === "Logistics") {
            Qt.callLater(logisticsCenterOnDesktopLocation)
        }
    }

    function _forceCameraMainView() {
        if (planType !== "Camera" && planType !== "AI" && QGroundControl.loadGlobalSetting("loadpage", "loadpage") !== "Camera" && QGroundControl.loadGlobalSetting("loadpage", "loadpage") !== "AI") {
            return
        }
        _locationMapOverride = false
        _cameraLocationMapOpen = false
        mapControl.pipState.state = mapControl.pipState.pipState
        videoControl.pipState.state = videoControl.pipState.fullState
        QGroundControl.saveBoolGlobalSetting("MainFlyWindowIsMap", false)
        _pipView._setPipIsExpanded(true)
    }

    function showCameraLocationMap() {
        _locationMapOverride = true
        _pipView._initForItems()
    }

    function toggleCameraLocationMap() {
        _cameraLocationMapOpen = !_cameraLocationMapOpen
        if (_cameraLocationMapOpen) {
            Qt.callLater(_focusCameraLocationMap)
        }
    }

    function _focusCameraLocationMap() {
        if (!_cameraLocationMapOpen || !cameraLocationMap) {
            return false
        }
        if (_activeVehicle && _activeVehicle.coordinate && _activeVehicle.coordinate.isValid) {
            cameraLocationMap.center = _activeVehicle.coordinate
            cameraLocationMap.zoomLevel = Math.max(cameraLocationMap.zoomLevel, 17)
            return true
        }
        if (cameraLocationMap.centerOnTransmitter) {
            return cameraLocationMap.centerOnTransmitter()
        }
        return false
    }

    function _showCameraShotToast(message) {
        if (typeof mainWindow !== "undefined" && mainWindow.showToastMessage) {
            mainWindow.showToastMessage(message)
        } else {
            console.log(message)
        }
    }

    function _markCameraShotWaypoint(coordinate) {
        if (!coordinate || !coordinate.isValid) {
            return
        }
        cameraShotWaypointModel.append({
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: coordinate.altitude
        })
        _showCameraShotToast(qsTr("Camera waypoint added"))
    }

    function _cameraRouteCoordinate(index) {
        if (index < 0 || index >= cameraShotWaypointModel.count) {
            return QtPositioning.coordinate()
        }
        var item = cameraShotWaypointModel.get(index)
        return QtPositioning.coordinate(item.latitude, item.longitude, item.altitude)
    }

    function _cameraRouteCurrentCoordinate() {
        return _cameraRouteCoordinate(_cameraRouteCurrentIndex)
    }

    function _cameraRouteDistanceMeters(index) {
        if (index < 0 || index >= cameraShotWaypointModel.count || !_activeVehicle || !_activeVehicle.coordinate || !_activeVehicle.coordinate.isValid) {
            return NaN
        }
        return _activeVehicle.coordinate.distanceTo(_cameraRouteCoordinate(index))
    }

    function _cameraRouteDistanceLabel(index) {
        var distance = _cameraRouteDistanceMeters(index)
        if (isNaN(distance)) {
            return qsTr("--")
        }
        return distance >= 1000 ? (distance / 1000).toFixed(1) + qsTr(" km") : Math.round(distance) + qsTr(" m")
    }

    function _cameraRouteStatusLabel() {
        if (_cameraRouteWaitingForTakeoff) {
            return qsTr("Takeoff")
        }
        if (_cameraRouteRunning && _cameraRouteCurrentIndex >= 0) {
            return qsTr("WP ") + (_cameraRouteCurrentIndex + 1) + "/" + cameraShotWaypointModel.count
        }
        return cameraShotWaypointModel.count + qsTr(" WP")
    }

    function _gotoCameraRouteCurrent() {
        var coordinate = _cameraRouteCurrentCoordinate()
        if (!coordinate.isValid) {
            return
        }
        _cameraRouteCaptureStarted = false
        _cameraRouteDwellTicks = 0
        _activeVehicle.guidedModeGotoLocation(coordinate)
        _showCameraShotToast(qsTr("Flying to camera waypoint ") + (_cameraRouteCurrentIndex + 1))
    }

    function _startCameraRoute(captureMode) {
        if (cameraShotWaypointModel.count === 0) {
            _showCameraShotToast(qsTr("Tap the map to add camera waypoints"))
            return
        }
        if (!_activeVehicle) {
            _showCameraShotToast(qsTr("No active vehicle"))
            return
        }
        if (!cameraRoutePreflight.criticalReady) {
            _showCameraShotToast(cameraRoutePreflight.firstCriticalReason())
            mainWindow.showPreFlightChecklistIfNeeded()
            return
        }
        _cameraRouteCaptureMode = captureMode ? captureMode : _cameraRouteCaptureMode
        _cameraRouteCurrentIndex = 0
        _cameraRouteRunning = true
        _cameraRouteCaptureStarted = false
        _cameraRouteDwellTicks = 0
        if (!_activeVehicle.armed) {
            _activeVehicle.armed = true
        }
        if (!_activeVehicle.flying && _activeVehicle.takeoffVehicleSupported) {
            _cameraRouteWaitingForTakeoff = true
            _activeVehicle.guidedModeTakeoff(_cameraRouteTakeoffAltitude)
            _showCameraShotToast(qsTr("Autonomous camera route: takeoff requested"))
            return
        }
        _cameraRouteWaitingForTakeoff = false
        _gotoCameraRouteCurrent()
    }

    PreFlightReadiness {
        id: cameraRoutePreflight
        appWindow: mainWindow
    }

    function _hoverCameraShot() {
        if (_activeVehicle && _activeVehicle.pauseVehicleSupported) {
            _activeVehicle.pauseVehicle()
            _showCameraShotToast(qsTr("Hover mode requested"))
        } else {
            _showCameraShotToast(qsTr("Hover is not supported by this vehicle"))
        }
    }

    function _captureCameraShot(mode) {
        if (mode === "video") {
            videoControl._toggleRecording()
        } else {
            videoControl._capturePhoto()
        }
    }

    function _stopCameraRoute() {
        _cameraRouteRunning = false
        _cameraRouteWaitingForTakeoff = false
        _cameraRouteCaptureStarted = false
        _cameraRouteCurrentIndex = -1
        _cameraRouteDwellTicks = 0
        _showCameraShotToast(qsTr("Camera route stopped"))
    }

    function _clearCameraRoute() {
        _stopCameraRoute()
        cameraShotWaypointModel.clear()
        _showCameraShotToast(qsTr("Camera waypoints cleared"))
    }

    function _advanceCameraRoute() {
        _cameraRouteCurrentIndex++
        _cameraRouteCaptureStarted = false
        _cameraRouteDwellTicks = 0
        if (_cameraRouteCurrentIndex >= cameraShotWaypointModel.count) {
            _cameraRouteRunning = false
            _cameraRouteCurrentIndex = -1
            _showCameraShotToast(qsTr("Autonomous camera route complete"))
            return
        }
        _gotoCameraRouteCurrent()
    }

    function _tickCameraRoute() {
        if (!_cameraRouteRunning || !_activeVehicle) {
            return
        }
        if (_cameraRouteWaitingForTakeoff) {
            if (_activeVehicle.flying || (_activeVehicle.altitudeRelative && _activeVehicle.altitudeRelative.rawValue > Math.max(3, _cameraRouteTakeoffAltitude * 0.45))) {
                _cameraRouteWaitingForTakeoff = false
                _gotoCameraRouteCurrent()
            }
            return
        }
        if (_cameraRouteDwellTicks > 0) {
            _cameraRouteDwellTicks--
            if (_cameraRouteDwellTicks === 0) {
                if (_cameraRouteCaptureMode === "video" && videoControl._recordingActive) {
                    videoControl._toggleRecording()
                }
                _advanceCameraRoute()
            }
            return
        }
        var distance = _cameraRouteDistanceMeters(_cameraRouteCurrentIndex)
        if (isNaN(distance) || distance > _cameraRouteArrivalMeters || _cameraRouteCaptureStarted) {
            return
        }
        _cameraRouteCaptureStarted = true
        if (_cameraShotHoverMode) {
            _hoverCameraShot()
        }
        if (_cameraRouteCaptureMode === "video") {
            if (!videoControl._recordingActive) {
                videoControl._toggleRecording()
            }
            _cameraRouteDwellTicks = 4
        } else {
            videoControl._capturePhoto()
            _cameraRouteDwellTicks = 2
        }
    }

    function logisticsCenterOnDesktopLocation() {
        if (mapControl && mapControl.centerOnTransmitter) {
            return mapControl.centerOnTransmitter()
        }
        return false
    }

    function logisticsDesktopCoordinate() {
        if (mapControl && mapControl.gcsPositionDetected && mapControl.gcsPosition && mapControl.gcsPosition.isValid) {
            return mapControl.gcsPosition
        }
        return QtPositioning.coordinate()
    }

    function logisticsMapCenterCoordinate() {
        if (mapControl && mapControl.center && mapControl.center.isValid) {
            return mapControl.center
        }
        return QtPositioning.coordinate()
    }


    function dropMessageIndicatorTool() {
        toolbar.dropMessageIndicatorTool();
    }


    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    ListModel {
        id: cameraShotWaypointModel
    }

    Timer {
        interval: 1000
        repeat: true
        running: _cameraRouteRunning
        onTriggered: _tickCameraRoute()
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
        z:          100    // Overlay on top of map
    }

    Item {
        id:                 mapHolder
        anchors.top:        parent.top        // Extend map behind toolbar for transparency
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
            pipView:                _pipView
            pipMode:                _cameraMode || !_mainWindowIsMap
            toolInsets:             customOverlay.totalToolInsets
            topReservedInset:       toolbar.height
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
            visible:                true
        }

        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
            anchors.fill: parent
            visible:    _cameraMode
            z:          _cameraMode ? 1 : 0
        }

        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                    (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0

        }

        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2 // we need to add one extra layer for map 3d viewer (normally was 1)
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            topReservedInset:       toolbar.height
            visible:                !QGroundControl.videoManager.fullScreen && !_cameraMode
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
        }

        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       widgetLayer
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            visible:            !QGroundControl.videoManager.fullScreen && !_cameraMode
        }

        FlightTimelinePanel {
            id: flightTimelinePanel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight
            width: implicitWidth
            height: implicitHeight
            z: QGroundControl.zOrderTopMost - 1
            timeline: typeof mainWindow !== "undefined" ? mainWindow.flightTimeline : null
            replayController: typeof mainWindow !== "undefined" ? mainWindow.logReplayController : null
            mapControl: _mapControl
            visible: !QGroundControl.videoManager.fullScreen
        }

        Rectangle {
            id: cameraLocationMapPanel
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 4.8
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 5.4
            width: Math.min(parent.width * 0.34, ScreenTools.defaultFontPixelWidth * 46)
            height: Math.min(parent.height * 0.34, ScreenTools.defaultFontPixelHeight * 25)
            radius: ScreenTools.defaultFontPixelHeight * 0.55
            color: Qt.rgba(0, 0, 0, 0.78)
            border.color: Qt.rgba(1, 1, 1, 0.36)
            border.width: 1
            clip: true
            visible: _cameraMode && _cameraLocationMapOpen && !QGroundControl.videoManager.fullScreen
            z: 95

            FlyViewMap {
                id:                     cameraLocationMap
                anchors.fill:           parent
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 4.8
                anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 6.4
                planMasterController:   _planController
                rightPanelWidth:        0
                pipView:                _pipView
                pipMode:                true
                topReservedInset:       0
                mapName:                "CameraLocationInset"
                enabled:                cameraLocationMapPanel.visible
                visible:                cameraLocationMapPanel.visible

                MapItemView {
                    model: cameraShotWaypointModel

                    delegate: MapQuickItem {
                        coordinate: QtPositioning.coordinate(latitude, longitude, altitude)
                        visible: true
                        z: QGroundControl.zOrderTopMost
                        anchorPoint.x: sourceItem.width / 2
                        anchorPoint.y: sourceItem.height

                        sourceItem: Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 4.4
                            height: ScreenTools.defaultFontPixelHeight * 3.0
                            radius: ScreenTools.defaultFontPixelHeight * 0.35
                            color: _cameraRouteRunning && index === _cameraRouteCurrentIndex ? "#16A085" : Qt.rgba(0.95, 0.62, 0.05, 0.92)
                            border.color: "white"
                            border.width: _cameraRouteRunning && index === _cameraRouteCurrentIndex ? 2 : 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: ScreenTools.defaultFontPixelHeight * 0.25
                                spacing: 0

                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("WP ") + (index + 1)
                                    color: "white"
                                    font.bold: true
                                    font.pointSize: ScreenTools.smallFontPointSize * 0.8
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: _cameraRouteDistanceLabel(index)
                                    color: "white"
                                    font.bold: true
                                    font.pointSize: ScreenTools.smallFontPointSize * 0.8
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: cameraWaypointMouseArea
                anchors.fill: cameraLocationMap
                enabled: cameraLocationMapPanel.visible
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton
                z: cameraLocationMap.z + 1

                onClicked: function(mouse) {
                    var mapPoint = Qt.point(mouse.x, mouse.y)
                    _markCameraShotWaypoint(cameraLocationMap.toCoordinate(mapPoint, false))
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: ScreenTools.defaultFontPixelHeight * 4.8
                color: Qt.rgba(0, 0, 0, 0.78)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.8
                    anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.5
                    anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.35
                    anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.35
                    spacing: ScreenTools.defaultFontPixelHeight * 0.25

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth * 0.5

                        QGCColoredImage {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.1
                            Layout.preferredHeight: Layout.preferredWidth
                            source: "qrc:/InstrumentValueIcons/map.svg"
                            color: "#75E6DA"
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Map + Camera Split")
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 1.8
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: closeCameraMapMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08)

                            Label {
                                anchors.centerIn: parent
                                text: "X"
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            MouseArea {
                                id: closeCameraMapMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: _cameraLocationMapOpen = false
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Path, subject position, and camera footprint")
                        color: Qt.rgba(1, 1, 1, 0.72)
                        font.pointSize: ScreenTools.smallFontPointSize * 0.88
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: ScreenTools.defaultFontPixelHeight * 6.4
                color: Qt.rgba(0, 0, 0, 0.62)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.8
                    anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 0.8
                    anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.35
                    anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.35
                    spacing: ScreenTools.defaultFontPixelHeight * 0.35

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: cameraShotWaypointModel.count > 0
                                  ? qsTr("Autonomous route: ") + cameraShotWaypointModel.count + qsTr(" waypoints")
                                  : qsTr("Tap map to add camera waypoints")
                            color: "white"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                            elide: Text.ElideRight
                        }

                        Label {
                            text: _cameraRouteStatusLabel()
                            color: "#75E6DA"
                            font.bold: true
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth * 0.45

                        Repeater {
                            model: [
                                { label: qsTr("Photo Route"), action: function() { _cameraShotHoverMode = true; _startCameraRoute("photo") } },
                                { label: qsTr("Video Route"), action: function() { _cameraShotHoverMode = true; _startCameraRoute("video") } },
                                { label: qsTr("Stop"), action: function() { _stopCameraRoute() } },
                                { label: qsTr("Clear"), action: function() { _clearCameraRoute() } }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2.1
                                radius: ScreenTools.defaultFontPixelHeight * 0.35
                                enabled: cameraShotWaypointModel.count > 0
                                opacity: enabled ? 1.0 : 0.5
                                color: cameraWaypointButtonMouse.containsMouse ? "#16A085" : Qt.rgba(1, 1, 1, 0.12)
                                border.color: Qt.rgba(1, 1, 1, 0.28)
                                border.width: 1

                                Label {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "white"
                                    font.bold: true
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: cameraWaypointButtonMouse
                                    anchors.fill: parent
                                    enabled: parent.enabled
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.action()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      widgetLayer.z + 1
            insetsToView:           widgetLayer.totalToolInsets
            visible:                false
        }

        GuidedActionsController {
            id:                 guidedActionsController
            missionController:  _missionController
            actionList:         _guidedActionList
            guidedValueSlider:     _guidedValueSlider
        }

        GuidedActionList {
            id:                         guidedActionList
            anchors.margins:            _margins
            anchors.bottom:             parent.bottom
            anchors.horizontalCenter:   parent.horizontalCenter
            z:                          QGroundControl.zOrderTopMost
            guidedController:           _guidedController
        }

        //-- Guided value slider (e.g. altitude)
        GuidedValueSlider {
            id:                 guidedValueSlider
            anchors.margins:    _toolsMargin
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            z:                  QGroundControl.zOrderTopMost
            visible:            false
        }

        Viewer3D {
            id:                     viewer3DWindow
            anchors.fill:           parent
        }
    }
}
