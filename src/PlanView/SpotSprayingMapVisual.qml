import QtQuick
import QtLocation
import QtPositioning
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Item {
    id: root

    property var map
    property var missionItem
    property bool interactive: true
    property var vehicle: null

    signal clicked(int sequenceNumber)

    property var polygonPath: {
        var coords = []
        if (!missionItem || !missionItem.points) return coords
        var count = missionItem.points.count
        for (var i = 0; i < count; i++) {
            var pt = missionItem.points.get(i)
            if (pt && pt.coordinate && pt.coordinate.isValid) {
                coords.push(pt.coordinate)
            }
        }
        return coords
    }

    property var closedPath: {
        if (polygonPath.length < 2) return polygonPath
        var closed = polygonPath.slice()
        closed.push(polygonPath[0])   // close the loop
        return closed
    }

    // Dynamically created corner markers
    property var _markerItems: []

    function _rebuildMarkers() {
        // Remove old markers
        for (var i = 0; i < _markerItems.length; i++) {
            map.removeMapItem(_markerItems[i])
            _markerItems[i].destroy()
        }
        _markerItems = []

        if (!missionItem || !missionItem.points) return

        var count = missionItem.points.count
        for (var j = 0; j < count; j++) {
            var pt = missionItem.points.get(j)
            if (!pt || !pt.coordinate || !pt.coordinate.isValid) continue

            var marker = markerComponent.createObject(map, {
                "coordinate": pt.coordinate
            })
            map.addMapItem(marker)
            _markerItems.push(marker)
        }
    }

    Component.onCompleted: {
        map.addMapItem(sprayPolygon)
        map.addMapItem(sprayPolyline)
        _rebuildMarkers()
    }

    Component.onDestruction: {
        map.removeMapItem(sprayPolygon)
        map.removeMapItem(sprayPolyline)
        for (var i = 0; i < _markerItems.length; i++) {
            map.removeMapItem(_markerItems[i])
            _markerItems[i].destroy()
        }
    }

    // Watch for points changing
    onMissionItemChanged: _rebuildMarkers()

    // Red dot marker component
    Component {
        id: markerComponent
        MapQuickItem {
            anchorPoint: Qt.point(10, 10)
            sourceItem: Rectangle {
                width:  20
                height: 20
                radius: 10
                color:  "red"
                border.color: "white"
                border.width: 2
            }
        }
    }

    MapPolygon {
        id: sprayPolygon
        path: polygonPath
        border.width: 0
        color: "transparent"     // ← no fill
        visible: false           // ← hide completely
    }

    MapPolyline {
        id: sprayPolyline
        path: polygonPath
        line.width: 3
        line.color: "yellow"
        visible: polygonPath.length >= 2
    }
}
