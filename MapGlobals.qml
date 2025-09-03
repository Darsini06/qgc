pragma Singleton
import QtQuick
import QGroundControl
import QGroundControl.Controls
import QtPositioning
import QGroundControl.QGCPositionManager


QtObject {
    property real mapRotation: 0
    property int recenterInterval: 10000 // Default 10 seconds
    property bool forceRecenter: false
    property var activeFlightMap: null  // Add global map reference
    property var gcsPosition: QGroundControl.qgcPositionManager.gcsPosition

    property string comefrom: "Plan"
    property string edit: "edit1"
    property string save: "save1"
    property real altitude: 0
    property string mapPolygon:" "

    property string time: "00:00:00"

    property string mark_with: "Mark_With_Manual"

    property string acres: ""

    property string appType: ""

    property string kmlPath: ""

    property bool share_edit_visibility : false


    function recenterMap() {
        if (activeFlightMap && gcsPosition.isValid) {
            activeFlightMap.center = gcsPosition
            activeFlightMap.zoomLevel = 15
        }
    }

}
