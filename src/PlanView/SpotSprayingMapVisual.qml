import QtQuick
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

Item {
    property var    map
    property var    missionItem

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
        model: missionItem.points
        delegate: MapQuickItem {
            coordinate: modelData.coordinate
            anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height / 2)
            sourceItem: MissionItemIndexLabel {
                label: index + 1
                checked: missionItem.isCurrentItem
            }
        }
    }
}
