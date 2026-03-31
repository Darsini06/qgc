import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

MenuItem {
    id: menuItem
    
    // MenuItem height logic is sometimes overridden to support !visible
    height: visible ? 40 : 0
    implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
    implicitHeight: 40

    contentItem: Text {
        id:                 label
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
