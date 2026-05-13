import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import MapGlobals

QGCFlickable {
    id:             root
    contentHeight:  geoFenceEditorRect.height
    clip:           true
    interactive:    true
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds

    property var    myGeoFenceController
    property var    flightMap
    property string activeEditType: ""

    readonly property real  _editFieldWidth:    Math.min(width - _margin * 2, ScreenTools.defaultFontPixelWidth * 15)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth * 1.5
    readonly property real  _radius:            8

    readonly property color _colorBgSecondary:  "#444444"
    readonly property color _colorBgTertiary:   "#333333"
    readonly property color _colorBorder:       "#555555"
    readonly property color _colorAccent:       "#666666"
    readonly property color _colorTextPrimary:  "#ffffff"
    readonly property color _colorTextSecondary:"#aaaaaa"
    readonly property bool  isAgri:             QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri"

    // ── Slider component ────────────────────────────────────────────
    Component {
        id: volumeSliderComponent
        RowLayout {
            width:   parent ? parent.width : implicitWidth
            spacing: 2
            property var fact: null

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 0.9
                Layout.preferredWidth:  Layout.preferredHeight
                radius: 4
                color:  minusArea.pressed ? _colorAccent : _colorBgSecondary
                border.color: _colorBorder; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "−"; font.bold: true
                    color: _colorTextPrimary
                    font.pointSize: ScreenTools.mediumFontPointSize + 2
                }
                MouseArea {
                    id: minusArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (parent.parent.fact) {
                            var s = parent.parent.fact.increment ? parent.parent.fact.increment : 1
                            parent.parent.fact.value -= s
                        }
                    }
                }
            }

            FactTextField {
                id: factField
                Layout.fillWidth:       true
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 0.9
                Layout.alignment:       Qt.AlignVCenter
                fact:                   parent.fact
                showUnits:              true
                color:                  _colorTextPrimary
                font.pointSize:         ScreenTools.defaultFontPointSize + 1
                horizontalAlignment:    Qt.AlignHCenter
                background: Rectangle {
                    color:        factField.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: factField.activeFocus ? _colorAccent : _colorBorder
                    border.width: factField.activeFocus ? 2 : 1
                    radius:       4
                }
            }

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 0.9
                Layout.preferredWidth:  Layout.preferredHeight
                radius: 4
                color:  plusArea.pressed ? _colorAccent : _colorBgSecondary
                border.color: _colorBorder; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "+"; font.bold: true
                    color: _colorTextPrimary
                    font.pointSize: ScreenTools.mediumFontPointSize + 2
                }
                MouseArea {
                    id: plusArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (parent.parent.fact) {
                            var s = parent.parent.fact.increment ? parent.parent.fact.increment : 1
                            parent.parent.fact.value += s
                        }
                    }
                }
            }
        }
    }

    // ── Root card ───────────────────────────────────────────────────
    Rectangle {
        id:           geoFenceEditorRect
        anchors.left:  parent.left
        anchors.right: parent.right
        height:        mainCol.y + mainCol.height + _margin * 2
        color:         "#E6222222"
        radius:        6
        border.color:  "#444444"
        border.width:  1

        ColumnLayout {
            id:                mainCol
            anchors.left:      parent.left
            anchors.right:     parent.right
            anchors.top:       parent.top
            anchors.margins:   _margin
            spacing:           _margin

            // ── Title ──
            QGCLabel {
                text:           qsTr("Obstacles Settings")
                color:          _colorTextPrimary
                font.bold:      true
                font.pointSize: ScreenTools.mediumFontPointSize + 2
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1; color: "#444444"
            }

            // ── Info / unsupported text ──
            QGCLabel {
                Layout.fillWidth: true
                wrapMode:     Text.WordWrap
                color:        _colorTextSecondary
                font.pointSize: myGeoFenceController.supported
                                ? ScreenTools.smallFontPointSize + 2
                                : ScreenTools.defaultFontPointSize + 2
                text: myGeoFenceController.supported
                      ? qsTr("Mark obstacle zones on the map by tapping 4 corners.")
                      : qsTr("This vehicle does not support Obstacles.")
            }

            // ── Fence params (if any) ──
            Repeater {
                model: myGeoFenceController.params
                RowLayout {
                    Layout.fillWidth: true
                    property bool showCombo: modelData.enumStrings.length > 0
                    QGCLabel {
                        text: myGeoFenceController.paramLabels[index]
                        color: _colorTextPrimary; font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize + 2
                    }
                    Item { Layout.fillWidth: true }
                    Loader {
                        width:           _editFieldWidth
                        visible:         !parent.showCombo
                        sourceComponent: volumeSliderComponent
                        property var targetFact: modelData
                        onTargetFactChanged: if (item) item.fact = targetFact
                        onLoaded:            if (item) item.fact = targetFact
                    }
                    FactComboBox {
                        width:      _editFieldWidth
                        indexModel: false
                        fact:       parent.showCombo ? modelData : _nullFact
                        visible:    parent.showCombo
                        property var _nullFact: Fact { }
                    }
                }
            }

            // ════════════════════════════════════════════════════════
            // ──  SQUARE OBSTACLES
            // ════════════════════════════════════════════════════════
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Section header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle { width: 4; height: 20; radius: 2; color: "#2ECC71" }
                    Text {
                        text:           qsTr("SQUARE OBSTACLES")
                        color:          "#2ECC71"
                        font.bold:      true
                        font.pointSize: 12
                    }
                }

                // Add button
                Button {
                    Layout.fillWidth: true
                    height: 50
                    contentItem: Text {
                        text:                qsTr("＋  Add Square Area")
                        color:               "white"
                        font.bold:           true
                        font.pointSize:      13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius:       10
                        color:        parent.pressed ? "#1A7A40" : "#27AE60"
                        border.color: "#2ECC71"
                        border.width: 1
                    }
                    onClicked: {
                        MapGlobals.lastButtonPressTime = new Date().getTime()
                        if (isAgri) {
                            MapGlobals.squareCornerStep = 0
                            MapGlobals.tempCorners = []
                        } else {
                            var r = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y,
                                            flightMap.centerViewport.width, flightMap.centerViewport.height)
                            myGeoFenceController.addInclusionPolygon(
                                flightMap.toCoordinate(Qt.point(r.x, r.y), false),
                                flightMap.toCoordinate(Qt.point(r.x + r.width, r.y + r.height), false))
                        }
                        myGeoFenceController.clearAllInteractive()
                        root.activeEditType = "polygon"
                    }
                }

                // Progress indicator (visible while picking corners)
                Rectangle {
                    visible:          MapGlobals.squareCornerStep >= 0
                    Layout.fillWidth: true
                    height:           squareProgressCol.implicitHeight + 32
                    radius:           10
                    color:            "#1A2A3A"
                    border.width:     0

                    ColumnLayout {
                        id:              squareProgressCol
                        anchors.fill:    parent
                        anchors.topMargin: 16
                        anchors.bottomMargin: 16
                        anchors.leftMargin: 12
                        anchors.rightMargin: 24 
                        spacing:         8

                        // Step circles
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            spacing: 6 // Reduced spacing to prevent clipping
                            Repeater {
                                model: 4
                                Column {
                                    spacing: 4
                                    Rectangle {
                                        width:        34; height: 34; radius: 17
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color:        index < MapGlobals.squareCornerStep  ? "#2ECC71"
                                                    : index === MapGlobals.squareCornerStep ? "#3498DB"
                                                    : "#2C2C2C"
                                        border.color: index === MapGlobals.squareCornerStep ? "white"
                                                    : index < MapGlobals.squareCornerStep   ? "#2ECC71"
                                                    : "#555555"
                                        border.width: 2
                                        Text {
                                            anchors.centerIn:    parent
                                            text:                (index + 1).toString()
                                            color:               index <= MapGlobals.squareCornerStep ? "white" : "#666666"
                                            font.bold:           true
                                            font.pointSize:      12
                                        }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text:       index === MapGlobals.squareCornerStep
                                                    ? qsTr("← tap") : ""
                                        color:      "#3498DB"
                                        font.pointSize: 10
                                    }
                                }
                            }
                        }
                    }

                    // Top-right corner minimalist Cancel/Undo icon (Smaller)
                    Text {
                        anchors.top:          parent.top
                        anchors.right:        parent.right
                        anchors.topMargin:    2
                        anchors.rightMargin:  4
                        text:                 MapGlobals.squareCornerStep > 0 ? "↩" : "✖"
                        color:                "#E74C3C"
                        font.bold:            true
                        font.pointSize:       12 

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (MapGlobals.squareCornerStep > 0) {
                                    var c = MapGlobals.tempCorners; c.pop(); MapGlobals.tempCorners = c
                                    MapGlobals.squareCornerStep--
                                } else {
                                    MapGlobals.squareCornerStep = -1; MapGlobals.tempCorners = []
                                }
                            }
                        }
                    }
                }

                // Square obstacle cards
                Repeater {
                    model: myGeoFenceController.polygons
                    Rectangle {
                        Layout.fillWidth: true
                        height:           squareCardCol.implicitHeight + 24
                        color:            object.interactive ? "#1A2A3A" : "#242424"
                        radius:           10
                        border.color:     object.interactive ? "#3498DB" : "#3A3A3A"
                        border.width:     object.interactive ? 2 : 1

                        ColumnLayout {
                            id:              squareCardCol
                            anchors.fill:    parent
                            anchors.margins: 14
                            spacing:         12

                            // Card header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    color: "#1E4D2B"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⬜"; font.pointSize: 14
                                    }
                                }
                                Text {
                                    text:           qsTr("Square #") + (index + 1)
                                    color:          "white"
                                    font.bold:      true
                                    font.pointSize: 12
                                    Layout.fillWidth: true
                                }
                                QGCSwitch {
                                    checked:   object.inclusion
                                    onClicked: object.inclusion = checked
                                }
                            }

                            // Edit / Delete buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Button {
                                    Layout.fillWidth: true
                                    height: 40
                                    contentItem: Text {
                                        text:                object.interactive ? qsTr("✏  Editing…") : qsTr("✏  Edit")
                                        color:               "white"
                                        font.bold:           true
                                        font.pointSize:      12
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment:   Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius:       8
                                        color:        object.interactive ? "#1F618D" : "#2C2C2C"
                                        border.color: object.interactive ? "#3498DB" : "#505050"
                                        border.width: 1
                                    }
                                    onClicked: {
                                        myGeoFenceController.clearAllInteractive()
                                        object.interactive = !object.interactive
                                    }
                                }

                                Button {
                                    width: 40; height: 40
                                    contentItem: Text {
                                        text:                "🗑"
                                        color:               "#E74C3C"
                                        font.pointSize:      15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment:   Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius:       8
                                        color:        parent.pressed ? "#7B241C" : "#2C2C2C"
                                        border.color: "#E74C3C"
                                        border.width: 1
                                    }
                                    onClicked: myGeoFenceController.deletePolygon(index)
                                }
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1; color: "#3A3A3A"
            }

            // ════════════════════════════════════════════════════════
            // ── CIRCULAR OBSTACLES
            // ════════════════════════════════════════════════════════
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Section header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle { width: 4; height: 20; radius: 2; color: "#3498DB" }
                    Text {
                        text:           qsTr("CIRCULAR OBSTACLES")
                        color:          "#3498DB"
                        font.bold:      true
                        font.pointSize: 12
                    }
                }

                // Add button
                Button {
                    Layout.fillWidth: true
                    height: 50
                    contentItem: Text {
                        text:                qsTr("＋  Add Circular Area")
                        color:               "white"
                        font.bold:           true
                        font.pointSize:      13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius:       10
                        color:        parent.pressed ? "#1A5276" : "#2E86C1"
                        border.color: "#3498DB"
                        border.width: 1
                    }
                    onClicked: {
                        MapGlobals.lastButtonPressTime = new Date().getTime()
                        if (isAgri) {
                            MapGlobals.circleAddMode = true
                        } else {
                            var r = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y,
                                            flightMap.centerViewport.width, flightMap.centerViewport.height)
                            myGeoFenceController.addInclusionCircle(
                                flightMap.toCoordinate(Qt.point(r.x + r.width/2, r.y + r.height/2), false), 10)
                        }
                        myGeoFenceController.clearAllInteractive()
                        root.activeEditType = "circle"
                    }
                }

                // ── Circle placement instruction banner (Minimized) ──────────────
                Rectangle {
                    visible:          MapGlobals.circleAddMode
                    Layout.fillWidth: true
                    height:           50
                    radius:           8
                    color:            "#0D2137"
                    border.width:     0 

                    RowLayout {
                        anchors.fill:    parent
                        anchors.margins: 10
                        spacing:         8

                        Rectangle {
                            width:  10; height: 10; radius: 5
                            color:  "#3498DB"
                            SequentialAnimation on opacity {
                                running:  MapGlobals.circleAddMode
                                loops:    Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }

                        Text {
                            text:           qsTr("Waiting for map tap...")
                            color:          "#3498DB"
                            font.bold:      true
                            font.pointSize: 11
                            Layout.fillWidth: true
                        }
                    }

                    // Top-right corner minimalist cancel icon (Smaller & Broader)
                    Text {
                        anchors.top:          parent.top
                        anchors.right:        parent.right
                        anchors.topMargin:    4
                        anchors.rightMargin:  8
                        text:                 "✖"
                        color:                "white"
                        font.bold:            true
                        font.pointSize:       14

                        MouseArea {
                            anchors.fill: parent
                            onClicked:    MapGlobals.circleAddMode = false
                        }
                    }
                }

                // Circle obstacle cards
                Repeater {
                    model: myGeoFenceController.circles
                    Rectangle {
                        Layout.fillWidth: true
                        height:           circleCardCol.implicitHeight + 24
                        color:            object.interactive ? "#1A2A3A" : "#242424"
                        radius:           10
                        border.color:     object.interactive ? "#3498DB" : "#3A3A3A"
                        border.width:     object.interactive ? 2 : 1

                        ColumnLayout {
                            id:              circleCardCol
                            anchors.fill:    parent
                            anchors.margins: 14
                            spacing:         12

                            // Card header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    color: "#1A2E4A"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⭕"; font.pointSize: 14
                                    }
                                }
                                Text {
                                    text:           qsTr("Circle #") + (index + 1)
                                    color:          "white"
                                    font.bold:      true
                                    font.pointSize: 12
                                    Layout.fillWidth: true
                                }
                                QGCSwitch {
                                    checked:   object.inclusion
                                    onClicked: object.inclusion = checked
                                }
                            }

                            // Radius slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text {
                                    text:      qsTr("Safety Radius (m)")
                                    color:     _colorTextSecondary
                                    font.pointSize: 10
                                }
                                Loader {
                                    Layout.fillWidth:  true
                                    sourceComponent:   volumeSliderComponent
                                    property var targetFact: object.radius
                                    onTargetFactChanged: if (item) item.fact = targetFact
                                    onLoaded:            if (item) item.fact = targetFact
                                }
                            }

                            // Edit / Delete buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Button {
                                    Layout.fillWidth: true
                                    height: 40
                                    contentItem: Text {
                                        text:                object.interactive ? qsTr("✏  Editing…") : qsTr("✏  Edit")
                                        color:               "white"
                                        font.bold:           true
                                        font.pointSize:      12
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment:   Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius:       8
                                        color:        object.interactive ? "#1F618D" : "#2C2C2C"
                                        border.color: object.interactive ? "#3498DB" : "#505050"
                                        border.width: 1
                                    }
                                    onClicked: {
                                        myGeoFenceController.clearAllInteractive()
                                        object.interactive = !object.interactive
                                    }
                                }

                                Button {
                                    width: 40; height: 40
                                    contentItem: Text {
                                        text:                "🗑"
                                        color:               "#E74C3C"
                                        font.pointSize:      15
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment:   Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        radius:       8
                                        color:        parent.pressed ? "#7B241C" : "#2C2C2C"
                                        border.color: "#E74C3C"
                                        border.width: 1
                                    }
                                    onClicked: myGeoFenceController.deleteCircle(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
