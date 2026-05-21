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
    signal pointClicked(int pointIndex)        // ← ADD THIS

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

    property var _markerItems: []

    function _rebuildMarkers() {
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
                "coordinate": pt.coordinate,
                "markerIndex": j                // ← pass index
            })
            map.addMapItem(marker)
            _markerItems.push(marker)
        }
    }

    Component.onCompleted: {
        map.addMapItem(sprayPolyline)
        _rebuildMarkers()
    }

    Component.onDestruction: {
        map.removeMapItem(sprayPolyline)
        for (var i = 0; i < _markerItems.length; i++) {
            map.removeMapItem(_markerItems[i])
            _markerItems[i].destroy()
        }
    }

    onMissionItemChanged: _rebuildMarkers()

    Component {
        id: markerComponent
        MapQuickItem {
            property int markerIndex: 0         // ← index of this point
            anchorPoint: Qt.point(10, 10)
            sourceItem: Rectangle {
                width:  20
                height: 20
                radius: 10
                color:  "red"
                border.color: "white"
                border.width: 2

                // Index label inside red dot
                Text {
                    anchors.centerIn: parent
                    text: markerIndex + 1
                    color: "white"
                    font.bold: true
                    font.pixelSize: 9
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.clicked(missionItem.sequenceNumber)
                        root.pointClicked(markerIndex)   // ← emit which point
                    }
                }
            }
        }
    }

    MapPolyline {
        id: sprayPolyline
        path: polygonPath
        line.width: 3
        line.color: "yellow"
        visible: polygonPath.length >= 2
    }
}
