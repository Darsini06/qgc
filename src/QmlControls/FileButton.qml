import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

/// File Button controls used by QGCFileDialog control
Rectangle {
    implicitWidth:  ScreenTools.implicitButtonWidth
    implicitHeight: 40 // Tighter row height
    
    color:          mouseArea.containsMouse ? "#F1F5F9" : "transparent"
    border.color:   "#DDE1EA"
    border.width:   highlight ? 2 : 0
    radius:         8
    
    property alias  text:       label.text
    property bool   highlight:  false

    signal clicked
    signal hamburgerClicked

    property real _margins: 15

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    QGCLabel {
        id:                     label
        anchors.margins:        _margins
        anchors.left:           parent.left
        anchors.right:          hamburger.left
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        verticalAlignment:      Text.AlignVCenter
        horizontalAlignment:    Text.AlignLeft  // Table-like left alignment
        color:                  "black"
        font.pixelSize:         16
        font.bold:              true
        elide:                  Text.ElideRight
    }

    QGCColoredImage {
        id:                     hamburger
        anchors.rightMargin:    20
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        width:                  _hamburgerSize
        height:                 _hamburgerSize
        sourceSize.height:      _hamburgerSize
        source:                 "/res/TrashDelete.svg"
        color:                  trashMouseArea.containsMouse ? "#E74C3C" : "#95A5A6"

        property real _hamburgerSize: 20
    }

    MouseArea {
        id:             mouseArea
        anchors.fill:   parent
        hoverEnabled:   true
        cursorShape:    Qt.PointingHandCursor
        onClicked:      parent.clicked()
    }

    MouseArea {
        id:               trashMouseArea
        anchors.centerIn: hamburger
        width:            36
        height:           36
        hoverEnabled:     true
        cursorShape:      Qt.PointingHandCursor
        onClicked:        parent.hamburgerClicked()
    }
}
