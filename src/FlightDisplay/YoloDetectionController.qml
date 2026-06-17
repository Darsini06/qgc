import QtQuick

QtObject {
    id: root

    property string modelPath: ""
    property string labelsPath: ""
    readonly property bool modelReady: false
    readonly property string statusText: qsTr("AI detection is unavailable in this build.")
    readonly property var detections: []

    function reloadModel() {
    }

    function detectImage(imagePath) {
    }
}
