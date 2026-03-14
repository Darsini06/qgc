import QtQuick

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

Rectangle {
    id: tabBar
    height: 40
    color: "#f1f5f9"
    radius: 8
    border.color: "#e2e8f0"
    border.width: 1

    property int currentIndex: QGroundControl.settingsManager.planViewSettings.displayPresetsTabFirst.rawValue ? 2 : 0
    property int _visibleTabCount: 4

    Rectangle {
        id: sliderHighlight
        width: (tabBar.width - 8) / tabBar._visibleTabCount
        height: tabBar.height - 8
        y: 4
        x: 4 + (tabBar.currentIndex * width)
        color: "white"
        radius: 6
        border.color: "#d1d5db"
        border.width: 1
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        MouseArea {
            width: (tabBar.width - 8) / tabBar._visibleTabCount
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBar.currentIndex = 0
            QGCColoredImage {
                source: "/qmlimages/PatternGrid.png"
                height: ScreenTools.defaultFontPixelHeight
                width: height
                anchors.centerIn: parent
                color: tabBar.currentIndex === 0 ? "black" : "#64748b"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            width: (tabBar.width - 8) / tabBar._visibleTabCount
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBar.currentIndex = 1
            QGCColoredImage {
                source: "/qmlimages/PatternCamera.png"
                height: ScreenTools.defaultFontPixelHeight
                width: height
                anchors.centerIn: parent
                color: tabBar.currentIndex === 1 ? "black" : "#64748b"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            width: (tabBar.width - 8) / tabBar._visibleTabCount
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBar.currentIndex = 2
            QGCColoredImage {
                source: "/qmlimages/PatternTerrain.png"
                height: ScreenTools.defaultFontPixelHeight
                width: height
                anchors.centerIn: parent
                color: tabBar.currentIndex === 2 ? "black" : "#64748b"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        MouseArea {
            width: (tabBar.width - 8) / tabBar._visibleTabCount
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBar.currentIndex = 3
            QGCColoredImage {
                source: "/qmlimages/PatternPresets.png"
                height: ScreenTools.defaultFontPixelHeight
                width: height
                anchors.centerIn: parent
                color: tabBar.currentIndex === 3 ? "black" : "#64748b"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
