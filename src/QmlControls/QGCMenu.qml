import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

Menu {
    id: menu

    background: Rectangle {
        implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
        implicitHeight: 40
        color:          "#2D1C42"  // Mission Dark Background
        border.color:   "#4A2C6D"  // Mission Border
        border.width:   1
        radius:         8
    }

    delegate: MenuItem {
        id: menuItem
        implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
        implicitHeight: 40

        contentItem: Text {
            text:               menuItem.text
            font.family:        "Outfit"
            font.pointSize:     11
            font.bold:          true
            color:              menuItem.highlighted ? "white" : "#D0D0D0"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            elide:              Text.ElideRight
        }

        background: Rectangle {
            implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
            implicitHeight: 40
            color:          menuItem.highlighted ? "#4A2C6D" : "transparent"
            radius:         6
        }
    }
}
