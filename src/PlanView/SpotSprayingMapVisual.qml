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
    property int selectedPointIndex: -1

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
            property int markerIndex: 0
            anchorPoint: Qt.point(16, 16)    // UPDATE anchor to center of glow
            sourceItem: Item {
                width: 32
                height: 32

                // Glow/pulse ring - shows when this point is selected
                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: width / 2
                    color: "transparent"
                    border.color: "#FFD700"   // gold highlight
                    border.width: 2.5
                    visible: root.selectedPointIndex === markerIndex

                    // Pulse animation
                    SequentialAnimation on scale {
                        running: root.selectedPointIndex === markerIndex
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.3; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }

                // Red circle marker
                Rectangle {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    radius: 10
                    color: "red"
                    border.color: "white"
                    border.width: 2

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
                            root.selectedPointIndex = markerIndex  // SET SELECTED
                            root.clicked(missionItem.sequenceNumber)
                            root.pointClicked(markerIndex)
                        }
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
