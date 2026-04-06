import QtQuick
import QtQuick.Controls
import QGroundControl
import QGroundControl.Palette
import QGroundControl.ScreenTools

Menu {
    id: menu

    property bool isAgri: QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri"

    background: Rectangle {
        implicitWidth:  ScreenTools.defaultFontPixelWidth * 12
        implicitHeight: 40
        color:          "#FFFFFF"
        border.color:   isAgri ? "#79AE6F" : "#808080"
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
            color:          menuItem.highlighted ? (isAgri ? "#79AE6F" : "#808080") : "transparent"
            radius:         6
        }
    }
}
