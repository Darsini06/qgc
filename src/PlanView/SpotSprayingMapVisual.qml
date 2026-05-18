import QtQuick
import QtLocation
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightMap

MapItemGroup {
    id: _root
    
    property var map        // Provided by creator
    property var _missionItem: object // the complex item

    MapItemView {
        model: _missionItem ? _missionItem.points : null
        delegate: MapQuickItem {
            coordinate: object ? object.coordinate : undefined
            anchorPoint: Qt.point(sourceItem.width / 2, sourceItem.height / 2)
            z: QGroundControl.zOrderMapItems
            
            sourceItem: MissionItemIndexLabel {
                label:      index + 1
                checked:    _missionItem.isCurrentItem
                onClicked:  {
                    // Optionally handle click
                }
            }
        }
    }
}
