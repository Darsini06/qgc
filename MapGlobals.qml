pragma Singleton
import QtQuick


QtObject {
    property real mapRotation: 0
    property int recenterInterval: 10000 // Default 10 seconds
    property bool forceRecenter: false
}
