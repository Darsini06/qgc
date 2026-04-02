import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

Menu {
    id: menu

    background: Rectangle {
        implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
        implicitHeight: 40
        color:          "#FFFFFF"
        border.color:   "#301934"
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
            color:              menuItem.highlighted ? "white" : "black"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            elide:              Text.ElideRight
        }

        background: Rectangle {
            implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
            implicitHeight: 40
            color:          menuItem.highlighted ? "#301934" : "transparent"
            radius:         6
        }
    }
}
