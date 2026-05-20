import QtQuick
import QtLocation
import QtPositioning
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Item {
    property var  map
    property var  missionItem
    property bool interactive: true
    property var  vehicle: null

    signal clicked(int sequenceNumber)

    property var _mapItems: []
    property int _lastPointCount: 0

    // Reload when mission item changes
    onMissionItemChanged: {
        _lastPointCount = 0
        _addMapItems()
    }

    Component.onCompleted: _addMapItems()
    Component.onDestruction: _removeMapItems()

    // Watch point count changes
    Connections {
        target: (missionItem && missionItem.points) ? missionItem.points : null
        ignoreUnknownSignals: true

        function onCountChanged() {
            var n = missionItem.points.count
            console.log("SpotSprayingMapVisual count:", n)

            if (n !== _lastPointCount) {
                _lastPointCount = n
                _addMapItems()
            }
        }
    }

    // ============================================================
    // ADD MAP ITEMS
    // ============================================================
    function _addMapItems() {

        _removeMapItems()

        if (!map || !missionItem || !missionItem.points) {
            console.log("Map or missionItem missing")
            return
        }

        var cnt = missionItem.points.count

        console.log("TOTAL POINTS:", cnt)

        if (cnt === 0)
            return

        var pathCoords = []

        // Collect coordinates
        for (var i = 0; i < cnt; i++) {

            var pt = missionItem.points.get(i)

            if (pt && pt.coordinate && pt.coordinate.isValid()) {

                console.log(
                    "POINT:",
                    i,
                    pt.coordinate.latitude,
                    pt.coordinate.longitude
                )

                pathCoords.push(pt.coordinate)
            }
        }

        if (pathCoords.length === 0) {
            console.log("No valid coordinates")
            return
        }

        // ========================================================
        // CREATE POLYGON
        // ========================================================

        if (pathCoords.length >= 3) {

            // close polygon
            var closedPath = pathCoords.concat([pathCoords[0]])

            var polygon = polygonComponent.createObject(map, {
                path: closedPath
            })

            map.addMapItem(polygon)

            _mapItems.push(polygon)
        }

        // ========================================================
        // CREATE POLYLINE
        // ========================================================

        if (pathCoords.length >= 2) {

            var linePath = pathCoords.concat([pathCoords[0]])

            var polyline = polylineComponent.createObject(map, {
                path: linePath
            })

            map.addMapItem(polyline)

            _mapItems.push(polyline)
        }

        // ========================================================
        // CREATE POINT LABELS
        // ========================================================

        for (var j = 0; j < pathCoords.length; j++) {

            var label = pointIndicator.createObject(map, {
                coordinate: pathCoords[j],
                pointIndex: j + 1
            })

            map.addMapItem(label)

            _mapItems.push(label)
        }

        // ========================================================
        // FIT MAP
        // ========================================================

        _fitMapToCoords(pathCoords)
    }

    // ============================================================
    // REMOVE ITEMS
    // ============================================================
    function _removeMapItems() {

        for (var i = 0; i < _mapItems.length; i++) {

            if (_mapItems[i]) {
                map.removeMapItem(_mapItems[i])
                _mapItems[i].destroy()
            }
        }

        _mapItems = []
    }

    // ============================================================
    // FIT MAP TO COORDS
    // ============================================================
    function _fitMapToCoords(coords) {

        if (!coords || coords.length === 0)
            return

        var minLat = 90
        var maxLat = -90
        var minLng = 180
        var maxLng = -180

        for (var i = 0; i < coords.length; i++) {

            if (coords[i].latitude < minLat)
                minLat = coords[i].latitude

            if (coords[i].latitude > maxLat)
                maxLat = coords[i].latitude

            if (coords[i].longitude < minLng)
                minLng = coords[i].longitude

            if (coords[i].longitude > maxLng)
                maxLng = coords[i].longitude
        }

        var centerLat = (minLat + maxLat) / 2
        var centerLng = (minLng + maxLng) / 2

        var span = Math.max(maxLat - minLat, maxLng - minLng)

        var zoom = 18

        if (span > 1.0)
            zoom = 10
        else if (span > 0.1)
            zoom = 13
        else if (span > 0.01)
            zoom = 15
        else if (span > 0.001)
            zoom = 17

        Qt.callLater(function() {

            map.center = QtPositioning.coordinate(centerLat, centerLng)

            map.zoomLevel = zoom

            console.log("Map centered")
        })
    }

    // ============================================================
    // POLYGON
    // ============================================================
    Component {

        id: polygonComponent

        MapPolygon {

            color: "#3300BFFF"

            border.width: 3

            border.color: "#00BFFF"
        }
    }

    // ============================================================
    // POLYLINE
    // ============================================================
    Component {

        id: polylineComponent

        MapPolyline {

            line.width: 2

            line.color: "#00BFFF"
        }
    }

    // ============================================================
    // POINT LABELS
    // ============================================================
    Component {

        id: pointIndicator

        MapQuickItem {

            property int pointIndex: 0

            anchorPoint: Qt.point(
                sourceItem.width / 2,
                sourceItem.height / 2
            )

            sourceItem: MissionItemIndexLabel {

                label: pointIndex

                checked: missionItem
                         ? missionItem.isCurrentItem
                         : false
            }
        }
    }
}
