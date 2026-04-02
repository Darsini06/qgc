/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

/// Airspace overlay component for displaying GeoJSON-based airspace restrictions
Item {
    id: _root

    property var map                    ///< Map control this is being used with
    property var airspaceManager        ///< AirspaceManager instance
    property bool showAirspace: airspaceManager ? airspaceManager.showAirspace : true    ///< Toggle airspace visibility
    property bool showLabels: airspaceManager ? airspaceManager.showLabels : true      ///< Toggle zone labels
    property bool showIcons: airspaceManager ? airspaceManager.showIcons : true       ///< Toggle airport/facility icons

    visible: showAirspace && airspaceManager

    property bool _isMapMoving: false

    // Timer to reset moving state
    Timer {
        id: _movingStateTimer
        interval: 250
        repeat: false
        onTriggered: _isMapMoving = false
    }

    function _setMapMoving() {
        _isMapMoving = true
        _movingStateTimer.restart()
    }

    // Auto-fetch airspace data when map moves significantly
    Connections {
        target: map
        
        function onCenterChanged() {
            _setMapMoving()
            if (_root.visible && airspaceManager) {
                var distanceMoved = map.center.distanceTo(_lastFetchCenter)
                // Threshold: 500m
                if (distanceMoved > 500) {
                    _fetchTimer.restart()
                }
            }
        }
        
        function onZoomLevelChanged() {
            _setMapMoving()
            if (_root.visible && airspaceManager) {
                if (Math.abs(map.zoomLevel - _lastFetchZoom) > 0.5) {
                    _fetchTimer.restart()
                }
            }
        }

        function onMapReadyChanged() {
            if (map.mapReady && _root.visible && airspaceManager) {
                _fetchTimer.restart()
            }
        }

        function onRotationChanged() {
            _setMapMoving()
        }
    }

    // Debounce timer for fetching airspace data
    Timer {
        id: _fetchTimer
        interval: 2000 // Increased further for even better "fast action" performance
        repeat: false
        onTriggered: {
            if (map && airspaceManager) {
                _fetchAirspaceForCurrentView()
                _lastFetchCenter = map.center
                _lastFetchZoom = map.zoomLevel
            }
        }
    }

    // Fetch airspace data for current map view
    function _fetchAirspaceForCurrentView() {
        if (!map || !map.mapReady) return

        var region = map.visibleRegion
        if (!region) return

        var bbox = region.boundingGeoRectangle ? region.boundingGeoRectangle() : region
        if (!bbox || isNaN(bbox.center.latitude)) return

        var topLeft = bbox.topLeft
        var bottomRight = bbox.bottomRight

        // Add buffer (expanded to 30% for even more "static" feel as you pan)
        var latDiff = Math.abs(topLeft.latitude - bottomRight.latitude)
        var lonDiff = Math.abs(bottomRight.longitude - topLeft.longitude)
        
        if (latDiff === 0 || lonDiff === 0) return

        var latBuffer = latDiff * 0.3
        var lonBuffer = lonDiff * 0.3

        var minLat = Math.min(topLeft.latitude, bottomRight.latitude) - latBuffer
        var maxLat = Math.max(topLeft.latitude, bottomRight.latitude) + latBuffer
        var minLon = Math.min(topLeft.longitude, bottomRight.longitude) - lonBuffer
        var maxLon = Math.max(topLeft.longitude, bottomRight.longitude) + lonBuffer

        airspaceManager.fetchAirspaceData(minLat, minLon, maxLat, maxLon)
    }

    // Render airspace zones using MapItemView for correct map coordinate rendering
    MapItemView {
        id:                 mapItemsView
        parent:             _root.map 
        model:              airspaceManager ? airspaceManager.zones : []
        // Performance: Hide overlay while panning and only show if zoomed in essentially (zoom > 1)
        visible:            _root.visible && !_isMapMoving && map.zoomLevel > 1
        
        delegate: MapItemGroup {
            id: zoneGroup
            property var zone: modelData

            // Circle rendering
            MapCircle {
                visible: zone.radius > 0
                center: zone.iconPosition
                radius: zone.radius
                color: zone.fillColor
                opacity: zone.fillOpacity
                border.width: zone.borderWidth
                border.color: zone.borderColor
            }

            // Polygon rendering
            MapPolygon {
                visible: zone.radius === 0
                color: zone.fillColor
                opacity: zone.fillOpacity
                border.width: zone.borderWidth
                border.color: zone.borderColor
                path: zone.path 
            }
        }
    }

    // Timer to hide popup after 5 seconds
    Timer {
        id: _popupHideTimer
        interval: 5000
        repeat: false
        onTriggered: _zoneInfoPopup.hide()
    }

    Connections {
        target: _root.map
        function onMapClicked(position) {
            var coord = _root.map.toCoordinate(position)
            var restrictions = _root.airspaceManager.getRestrictionsAtCoordinate(coord.latitude, coord.longitude, 0)
            
            if (restrictions.length > 0) {
                // Prioritize zones: Red > Temporary > Boundary > Runway > Yellow > Others
                var selectedZone = restrictions[0]
                var priority = { "red": 7, "temporary": 6, "boundary": 5, "runway": 4, "inneryellow": 3, "outeryellow": 2, "others": 1, "green": 0 }
                
                var currentPri = priority[selectedZone.zoneType] || 0
                
                for (var i = 1; i < restrictions.length; i++) {
                    var z = restrictions[i]
                    var p = priority[z.zoneType] || 0
                    if (p > currentPri) {
                        selectedZone = z
                        currentPri = p
                    }
                }
                
                _zoneInfoPopup.show(selectedZone, position)
                _popupHideTimer.restart()
            }
        }
    }

    // Zone information popup (UI Overlay - Screen Coordinates)
    Rectangle {
        id: _zoneInfoPopup
        width: Math.max(_zoneInfoColumn.width + ScreenTools.defaultFontPixelWidth * 4, ScreenTools.defaultFontPixelWidth * 20)
        height: _zoneInfoColumn.height + ScreenTools.defaultFontPixelHeight * 2
        radius: 4
        color: "white"
        border.color: "#A020F0"
        border.width: 3
        visible: false
        z: 9999 

        property var currentZone: null

        function show(zone, pos) {
            currentZone = zone
            // Position near the click location
            x = Math.max(0, Math.min(_root.width - width, pos.x - width / 2))
            y = Math.max(0, Math.min(_root.height - height, pos.y - height - 20))
            visible = true
        }

        function hide() {
            visible = false
            currentZone = null
        }

        Column {
            id: _zoneInfoColumn
            anchors.centerIn: parent
            spacing: ScreenTools.defaultFontPixelHeight * 0.25
            width: parent.width - ScreenTools.defaultFontPixelWidth * 2

            QGCLabel {
                text: {
                    if (!_zoneInfoPopup.currentZone) return ""
                    // If it's a "red" zone and name is generic, use "Red Zone"
                    var name = _zoneInfoPopup.currentZone.name
                    if (name.toLowerCase().indexOf("red") === -1 && _zoneInfoPopup.currentZone.zoneType === "red") {
                        return name + " (Red Zone)"
                    }
                    return name
                }
                color: "#FF4500" // Bright orange-red like screenshot
                font.bold: true
                font.pixelSize: ScreenTools.largeFontPointSize
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            QGCLabel {
                visible: _zoneInfoPopup.currentZone && _zoneInfoPopup.currentZone.description !== "" && _zoneInfoPopup.currentZone.description !== _zoneInfoPopup.currentZone.name
                text: _zoneInfoPopup.currentZone ? _zoneInfoPopup.currentZone.description : ""
                color: "#333333" // Dark grey for description
                font.pixelSize: ScreenTools.smallFontPointSize
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 3
            }
        }
    }

    // Loading indicator (UI Overlay)
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: ScreenTools.defaultFontPixelWidth
        width: _loadingRow.width + ScreenTools.defaultFontPixelWidth
        height: _loadingRow.height + ScreenTools.defaultFontPixelHeight * 0.5
        radius: ScreenTools.defaultFontPixelHeight * 0.25
        color: Qt.rgba(1, 1, 1, 0.9)
        visible: airspaceManager && airspaceManager.isLoading

        Row {
            id: _loadingRow
            anchors.centerIn: parent
            spacing: ScreenTools.defaultFontPixelWidth * 0.5
            BusyIndicator {
                width: ScreenTools.defaultFontPixelHeight * 1.5
                height: width
            }
            QGCLabel {
                text: "Loading Airspace..."
                color: "black"
                font.pixelSize: ScreenTools.smallFontPointSize
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Error message (UI Overlay)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.margins: ScreenTools.defaultFontPixelWidth
        width: _errorLabel.width + ScreenTools.defaultFontPixelWidth * 2
        height: _errorLabel.height + ScreenTools.defaultFontPixelHeight
        radius: ScreenTools.defaultFontPixelHeight * 0.25
        color: Qt.rgba(0.8, 0, 0, 0.9)
        border.color: "red"
        border.width: 2
        visible: airspaceManager && airspaceManager.errorMessage !== ""

        QGCLabel {
            id: _errorLabel
            anchors.centerIn: parent
            text: airspaceManager ? airspaceManager.errorMessage : ""
            color: "white"
            font.pixelSize: ScreenTools.smallFontPointSize
            wrapMode: Text.WordWrap
            width: Math.min(_root.width * 0.8, ScreenTools.defaultFontPixelWidth * 50)
        }
    }

    Component.onCompleted: {
        console.log("AirspaceMapOverlay: Component completed")
        if (airspaceManager) {
            _fetchTimer.start()
        }
    }
}
