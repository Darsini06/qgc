import QtQuick
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Item {
    property var    map
    property var    missionItem

    property bool   interactive: true
    property var    vehicle:     null

    Component {
        id: pointIndicator

        MapQuickItem {
            anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height / 2)

            sourceItem: MissionItemIndexLabel {
                label:      index + 1
                checked:    missionItem.isCurrentItem
            }
        }
    }

    Repeater {
        model: missionItem ? missionItem.points : []  // ← Add null check
        delegate: MapQuickItem {
            coordinate: modelData.coordinate
            anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height / 2)
            sourceItem: MissionItemIndexLabel {
                label:      index + 1
                checked:    missionItem ? missionItem.isCurrentItem : false  // ← Add null check
            }
        }
    }
}
