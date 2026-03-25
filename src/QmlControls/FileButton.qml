import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

/// File Button controls used by QGCFileDialog control
Rectangle {
    implicitWidth:  ScreenTools.implicitButtonWidth
    implicitHeight: 45 // Fixed row height for a clean table look
    
    color:          mouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent"
    border.color:   Qt.rgba(255, 255, 255, 0.1)
    border.width:   1
    radius:         4
    
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
        color:                  "white"
        font.pixelSize:         16
        font.bold:              true
        elide:                  Text.ElideRight
    }

    QGCColoredImage {
        id:                     hamburger
        anchors.rightMargin:    12
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
