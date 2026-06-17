import QtQuick

Rectangle {
    id: toggleRoot
    width:              48
    height:             26
    radius:             height / 2
    color:              checked ? "#79AE6F" : "#E0E0E0"
    border.color:       checked ? "#79AE6F" : "#CCCCCC"
    border.width:       1
    
    property bool checked: false
    signal toggled(bool newValue)

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Rectangle {
        id: thumb
        width:              20
        height:             20
        radius:             height / 2
        color:              "white"
        anchors.verticalCenter: parent.verticalCenter
        x:                  checked ? (parent.width - width - 3) : 3

        Behavior on x {
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
    }

    MouseArea {
        anchors.fill:       parent
        cursorShape:        Qt.PointingHandCursor
        onClicked: {
            toggleRoot.toggled(!toggleRoot.checked)
        }
    }
}
