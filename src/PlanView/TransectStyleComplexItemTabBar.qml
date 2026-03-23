import QtQuick

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

Rectangle {
    id: tabBar
    height: 42
    color: "#282830"
    radius: 10
    border.color: "#3e3e4a"
    border.width: 1

    property int currentIndex: QGroundControl.settingsManager.planViewSettings.displayPresetsTabFirst.rawValue ? 2 : 0
    property int _visibleTabCount: 4

    // Glowing active tab indicator
    Rectangle {
        id: sliderHighlight
        width: (tabBar.width - 8) / tabBar._visibleTabCount
        height: tabBar.height - 8
        y: 4
        x: 4 + (tabBar.currentIndex * width)
        color: "#4a2c6d"
        radius: 7
        border.color: "#6d3da0"
        border.width: 1

        // Inner glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: parent.radius - 2
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
        }

        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutExpo } }
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
                color: tabBar.currentIndex === 0 ? "#ffffff" : "#8e8e93"
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
                color: tabBar.currentIndex === 1 ? "#ffffff" : "#8e8e93"
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
                color: tabBar.currentIndex === 2 ? "#ffffff" : "#8e8e93"
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
                color: tabBar.currentIndex === 3 ? "#ffffff" : "#8e8e93"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
