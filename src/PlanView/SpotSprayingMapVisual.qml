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

    Component.onCompleted: {
        map.addMapItem(sprayPolygon)
        map.addMapItem(sprayPolyline)
    }

    Component.onDestruction: {
        map.removeMapItem(sprayPolygon)
        map.removeMapItem(sprayPolyline)
    }

    MapPolygon {
        id: sprayPolygon
        path: polygonPath
        border.width: 3
        border.color: "#00BFFF"
        color: Qt.rgba(0, 0.7, 1, 0.25)
        visible: polygonPath.length >= 3
    }


    MapPolyline {
         id: sprayPolyline
         path: polygonPath
         line.width: 3
         line.color: "yellow"
         visible: polygonPath.length >= 2
     }

    Repeater {
        model: missionItem && missionItem.points ? missionItem.points : 0
        delegate: MapQuickItem {
            coordinate: object.coordinate
            anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height / 2)
            sourceItem: MissionItemIndexLabel {
                label: index + 1
                checked: false
                onClicked: root.clicked(missionItem.sequenceNumber)
            }
        }
    }
}
