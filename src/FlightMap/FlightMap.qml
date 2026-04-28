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
import QtLocation
import QtPositioning
import QtQuick.Dialogs

import MapGlobals

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Vehicle
import QGroundControl.QGCPositionManager

Map {
    id: _map

    plugin:             Plugin { name: "QGroundControl" }
    opacity:            1.0
    smooth:             true
    antialiasing:       true
    copyrightsVisible:  false

    // Behind map to avoid white flashes
    Rectangle {
        anchors.fill:   parent
        color:          "#333333"
        z:              -1
    }

    Behavior on zoomLevel {
        enabled:         !pinch.active && !dragHandler.active && !wheelHandler.active
        NumberAnimation {
            duration:   500
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on center {
        enabled:         !pinch.active && !dragHandler.active
        CoordinateAnimation {
            duration:   500
            easing.type: Easing.InOutQuad
        }
    }

    WheelHandler {
        id: wheelHandler
        // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
        acceptedDevices:    Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland" ?
                                PointerDevice.Mouse | PointerDevice.TouchPad : PointerDevice.Mouse
        rotationScale:      1 / 120
        property:           "zoomLevel"
    }

    bearing: MapGlobals.mapRotation

    property string mapName:                        'defaultMap'
    property bool   isSatelliteMap:                 false //activeMapType.name.indexOf("Satellite") > -1 || activeMapType.name.indexOf("Hybrid") > -1
    property var    gcsPosition:                    QGroundControl.qgcPositionManager.gcsPosition
    property real   gcsHeading:                     QGroundControl.qgcPositionManager.gcsHeading
    property bool   allowGCSLocationCenter:         false   ///< true: map will center/zoom to gcs location one time
    property bool   allowVehicleLocationCenter:     false   ///< true: map will center/zoom to vehicle location one time
    property bool   firstGCSPositionReceived:       false   ///< true: first gcs position update was responded to
    property bool   firstVehiclePositionReceived:   false   ///< true: first vehicle position update was responded to
    property bool   planView:                       false   ///< true: map being using for Plan view, items should be draggable

    readonly property real  maxZoomLevel: 22

    Component.onCompleted: {
        MapGlobals.activeFlightMap = this
        console.log("FlightMap instance registered globally")
    }


    property real mapRotation: 0


    function rotateMap(delta) {
        console.log("Rotating map by delta:", delta); // Debug log
        MapGlobals.mapRotation += delta  // Subtracting instead of adding to rotate in the opposite direction
        if (MapGlobals.mapRotation >= 360) MapGlobals.mapRotation -= 360
        if (MapGlobals.mapRotation <= -360) MapGlobals.mapRotation += 360
        console.log("New mapRotation:", MapGlobals.mapRotation);
    }

    function resetRotation() {
        MapGlobals.mapRotation = 0;
    }

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()

    function setVisibleRegion(region) {
        // TODO: Is this still necessary with Qt 5.11?
        // This works around a bug on Qt where if you set a visibleRegion and then the user moves or zooms the map
        // and then you set the same visibleRegion the map will not move/scale appropriately since it thinks there
        // is nothing to do.
        _map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(0, 0), QtPositioning.coordinate(0, 0))
        _map.visibleRegion = region
    }

    function _possiblyCenterToVehiclePosition() {
        if (!firstVehiclePositionReceived && allowVehicleLocationCenter && _activeVehicleCoordinate.isValid) {
            firstVehiclePositionReceived = true
            center = _activeVehicleCoordinate
            zoomLevel = QGroundControl.flightMapInitialZoom
            console.log("_possiblyCenterToVehiclePosition method")
        }
    }

    function centerToSpecifiedLocation() {
        specifyMapPositionDialog.createObject(mainWindow).open()
    }

    Component {
        id: specifyMapPositionDialog
        EditPositionDialog {
            title:                  qsTr("Specify Position")
            coordinate:             center
            onCoordinateChanged:    center = coordinate
        }
    }

    // Center map to gcs location
    onGcsPositionChanged: {
        if (gcsPosition.isValid && allowGCSLocationCenter && !firstGCSPositionReceived && !firstVehiclePositionReceived) {
            firstGCSPositionReceived = true
            //-- Only center on gsc if we have no vehicle (and we are supposed to do so)
            var _activeVehicleCoordinate = _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
            // if(QGroundControl.settingsManager.flyViewSettings.keepMapCenteredOnVehicle.rawValue || !_activeVehicleCoordinate.isValid)
            // Set current location and zoom
            center = gcsPosition
            zoomLevel = 19

            console.log("GCS Position Updated:", gcsPosition)
        }
    }

    function updateActiveMapType() {
        var settings =  QGroundControl.settingsManager.flightMapSettings
        var fullMapName = settings.mapProvider.value + " " + settings.mapType.value

        for (var i = 0; i < _map.supportedMapTypes.length; i++) {
            if (fullMapName === _map.supportedMapTypes[i].name) {
                _map.activeMapType = _map.supportedMapTypes[i]
                return
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: _possiblyCenterToVehiclePosition()

    onMapReadyChanged: {
        if (_map.mapReady) {
            updateActiveMapType()
            _possiblyCenterToVehiclePosition()
        }
    }

    Connections {
        target: QGroundControl.settingsManager.flightMapSettings.mapType
        function onRawValueChanged() { updateActiveMapType() }

    }

    Connections {
        target: QGroundControl.settingsManager.flightMapSettings.mapProvider
        function onRawValueChanged() { updateActiveMapType() }
    }

    signal mapPanStart
    signal mapPanStop
    signal mapClicked(var position)

    PinchHandler {
        id:                 pinch
        target:             null
        grabPermissions:    PointerHandler.TakeOverForbidden

        property var pinchStartCentroid

        onActiveChanged: {
            if (active) {
                pinchStartCentroid = _map.toCoordinate(pinch.centroid.position, false)
            }
        }
        onScaleChanged: (delta) => {
                            _map.zoomLevel += Math.log2(delta)
                            _map.alignCoordinateToPoint(pinchStartCentroid, pinch.centroid.position)
                        }

        onRotationChanged: (angleDelta) => {
                               rotateMap(-angleDelta)  // Negate the angleDelta to rotate in the opposite direction
                           }

    }


    /*
    WheelHandler {
        // moved up for behavior reference
    }
    */

    DragHandler {
        id:             dragHandler
        target:         null
        grabPermissions: PointerHandler.TakeOverForbidden

        onActiveChanged: {
            if (active) {
                mapPanStart()
            } else {
                mapPanStop()
            }
        }

        onActiveTranslationChanged: (delta) => _map.pan(-delta.x, -delta.y)
    }

    TapHandler {
        onTapped: (eventPoint) => mapClicked(eventPoint.position)
    }

    /// Ground Station location
    MapQuickItem {
        anchorPoint.x:  sourceItem.width / 2
        anchorPoint.y:  sourceItem.height / 2
        visible:        gcsPosition.isValid
        coordinate:     gcsPosition

        sourceItem: Item {
            property real size: ScreenTools.defaultFontPixelHeight * (isNaN(gcsHeading) ? 1.75 : 2.5)
            width: size
            height: size

            Timer {
                interval: 500
                running: true
                repeat: true
                onTriggered: {
                    var page = QGroundControl.loadGlobalSetting("loadpage", "loadpage")
                    if (page === "Agri") mapItemImage.color = "green"
                    else if (page === "Camera") mapItemImage.color = "grey"
                    else mapItemImage.color = "grey"
                }
            }

            // Pulse Effect
            Rectangle {
                anchors.centerIn: parent
                width:            parent.width * 1.5
                height:           width
                radius:           width / 2
                color:            mapItemImage.color
                opacity:          0
                z:                -1
                
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.5; to: 2.0; duration: 2000; easing.type: Easing.OutQuart }
                }
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.6; to: 0.0; duration: 2000; easing.type: Easing.OutQuart }
                }
            }

            QGCColoredImage {
                id:             mapItemImage
                anchors.fill:   parent
                source:         isNaN(gcsHeading) ? "/res/QGCLogoFull" : "/res/QGCLogoFull"
                mipmap:         true
                antialiasing:   true
                fillMode:       Image.PreserveAspectFit
                sourceSize.height: height
                color: "red" // fallback initial color, will be updated by timer
                transform: Rotation {
                    origin.x:       mapItemImage.width  / 2
                    origin.y:       mapItemImage.height / 2
                    angle:          isNaN(gcsHeading) ? 0 : gcsHeading
                }
            }
        }
    }

    VehicleMapItem {
        id: myVehicleItem
        mapRotation: mapRotation  // <-- pass the rotation value
    }

    AirspaceMapOverlay {
        id:                 airspaceOverlay
        map:                _map
        airspaceManager:    QGroundControl.airspaceManager
    }


} // Map
