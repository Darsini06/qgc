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

    // Auto-fetch airspace data when map moves
    Connections {
        target: map
        
        function onCenterChanged() {
            if (_root.visible && airspaceManager) {
                _fetchTimer.restart()
            }
        }
        
        function onZoomLevelChanged() {
            if (_root.visible && airspaceManager) {
                _fetchTimer.restart()
            }
        }

        function onMapReadyChanged() {
            if (map.mapReady && _root.visible && airspaceManager) {
                _fetchTimer.restart()
            }
        }
    }

    // Debounce timer for fetching airspace data
    Timer {
        id: _fetchTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (map && airspaceManager) {
                _fetchAirspaceForCurrentView()
            }
        }
    }

    // Fetch airspace data for current map view
    function _fetchAirspaceForCurrentView() {
        if (!map || !map.mapReady) return

        var region = map.visibleRegion
        if (!region) {
            console.log("AirspaceMapOverlay: No visibleRegion yet")
            return
        }

        // In Qt 6, visibleRegion is a QGeoShape. Try to get a rectangle.
        var bbox = region.boundingGeoRectangle ? region.boundingGeoRectangle() : region
        
        if (!bbox || isNaN(bbox.center.latitude) || isNaN(bbox.center.longitude)) {
            // console.log("AirspaceMapOverlay: BBOX center is NaN - map probably not initialized")
            return
        }

        var topLeft = bbox.topLeft
        var bottomRight = bbox.bottomRight

        if (!topLeft || !bottomRight || isNaN(topLeft.latitude) || isNaN(bottomRight.latitude)) {
            console.log("AirspaceMapOverlay: Invalid topLeft/bottomRight coordinates")
            return
        }

        // Add buffer to bbox (10% on each side)
        var latDiff = Math.abs(topLeft.latitude - bottomRight.latitude)
        var lonDiff = Math.abs(bottomRight.longitude - topLeft.longitude)
        
        if (latDiff === 0 || lonDiff === 0) {
            // console.log("AirspaceMapOverlay: Zero size bbox - too zoomed in or not ready")
            return
        }

        // Buffer added to bbox
        var latBuffer = latDiff * 0.1
        var lonBuffer = lonDiff * 0.1

        var minLat = Math.min(topLeft.latitude, bottomRight.latitude) - latBuffer
        var maxLat = Math.max(topLeft.latitude, bottomRight.latitude) + latBuffer
        var minLon = Math.min(topLeft.longitude, bottomRight.longitude) - lonBuffer
        var maxLon = Math.max(topLeft.longitude, bottomRight.longitude) + lonBuffer

        // console.log("AirspaceMapOverlay: Fetching data for BBOX:", minLat.toFixed(4), minLon.toFixed(4), "to", maxLat.toFixed(4), maxLon.toFixed(4))
        airspaceManager.fetchAirspaceData(minLat, minLon, maxLat, maxLon)
    }

    // Render airspace zones using MapItemView for correct map coordinate rendering
    MapItemView {
        id:                 mapItemsView
        parent:             _root.map // ENSURE this is a direct child of the Map for rendering
        model:              airspaceManager ? airspaceManager.zones : []
        visible:            _root.visible
        
        delegate: MapItemGroup {
            id: zoneGroup

            property var zone: modelData

            // The Polygon
            MapPolygon {
                id: zonePolygon
                color: zone.fillColor
                opacity: zone.fillOpacity
                border.color: zone.borderColor
                border.width: zone.borderWidth
                path: {
                    var pathArray = []
                    var coords = zone.coordinates
                    for (var i = 0; i < coords.length; i++) {
                        var coord = coords[i]
                        if (coord.length >= 2) {
                            pathArray.push(QtPositioning.coordinate(coord[1], coord[0]))
                        }
                    }
                    return pathArray
                }
            }

            // Zone label (Hidden by default, shown on click via popup)
            // Keeping this for reference but setting visible to false
            MapQuickItem {
                visible: false
                coordinate: zone.iconPosition
                // ... rest of static label code
            }

            // Airport/Facility icon (Keep if desired, or hide)
            MapQuickItem {
                visible: _root.showIcons && zone.zoneType === "airport"
                coordinate: zone.iconPosition
                anchorPoint.x: airportIcon.width / 2
                anchorPoint.y: airportIcon.height / 2
                sourceItem: QGCColoredImage {
                    id: airportIcon
                    width: ScreenTools.defaultFontPixelHeight * 1.5
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    source: "/qmlimages/Airframe/Plane.svg"
                    color: zone.borderColor
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.8
                }
            }
        }
    }

    // Timer to hide popup after 2 seconds
    Timer {
        id: _popupHideTimer
        interval: 2000
        repeat: false
        onTriggered: _zoneInfoPopup.hide()
    }

    Connections {
        target: _root.map
        function onMapClicked(position) {
            var coord = _root.map.toCoordinate(position)
            var restrictions = _root.airspaceManager.getRestrictionsAtCoordinate(coord.latitude, coord.longitude, 0)
            
            if (restrictions.length > 0) {
                // Prioritize zones: Red > InnerYellow > OuterYellow > Others
                var selectedZone = restrictions[0]
                var priority = { "red": 4, "inneryellow": 3, "outeryellow": 2, "green": 1 }
                
                var currentPri = priority[selectedZone.zoneType] || 0
                
                for (var i = 1; i < restrictions.length; i++) {
                    var z = restrictions[i]
                    var p = priority[z.zoneType] || 0
                    if (p > currentPri) {
                        selectedZone = z
                        currentPri = p
                    }
                }
                
                _zoneInfoPopup.show(selectedZone)
                _popupHideTimer.restart()
            }
        }
    }

    // Zone information popup (UI Overlay - Screen Coordinates)
    Rectangle {
        id: _zoneInfoPopup
        anchors.centerIn: parent
        width: Math.max(_zoneInfoColumn.width + ScreenTools.defaultFontPixelWidth * 4, ScreenTools.defaultFontPixelWidth * 25)
        height: _zoneInfoColumn.height + ScreenTools.defaultFontPixelHeight * 1.5
        radius: ScreenTools.defaultFontPixelHeight * 0.5
        color: Qt.rgba(0, 0, 0, 0.85)
        border.color: currentZone ? currentZone.borderColor : "white"
        border.width: 2
        visible: false
        z: 9999 // Ensure it's on top of everything

        property var currentZone: null

        function show(zone) {
            currentZone = zone
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
                text: _zoneInfoPopup.currentZone ? _zoneInfoPopup.currentZone.name : ""
                color: "white"
                font.bold: true
                font.pixelSize: ScreenTools.mediumFontPointSize
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            QGCLabel {
                text: _zoneInfoPopup.currentZone ? 
                      "(" + _zoneInfoPopup.currentZone.zoneType.toUpperCase() + ")" : ""
                color: _zoneInfoPopup.currentZone ? _zoneInfoPopup.currentZone.borderColor : "yellow"
                font.pixelSize: ScreenTools.smallFontPointSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            QGCLabel {
                visible: _zoneInfoPopup.currentZone && _zoneInfoPopup.currentZone.description !== ""
                text: _zoneInfoPopup.currentZone ? _zoneInfoPopup.currentZone.description : ""
                color: "white"
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
