import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette

Item {
    id:         root
    width:      availableWidth
    height:     editorColumn.implicitHeight

    property var    missionItem
    property real   availableWidth
    property var    masterController
    property int    selectedIndex:  -1
    property bool   showAllPoints:  false
    property int    expandedIndex:  -1

    onSelectedIndexChanged: {
        console.log("OPENING INDEX:", selectedIndex)
        if (selectedIndex >= 0 && !showAllPoints) {
            Qt.callLater(function() {
                expandedIndex = selectedIndex
            })
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        id:             editorColumn
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        8

        // ── Header ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4

            Rectangle {
                width:  4
                height: 18
                radius: 2
                color:  "#4CAF50"
            }

            Text {
                text:             qsTr("Spot Spraying Waypoints")
                color:            "#ffffff"
                font.bold:        true
                font.pixelSize:   15
                font.family:      "Outfit"
                Layout.fillWidth: true
                leftPadding:      6
            }

            Rectangle {
                width:   countLabel.implicitWidth + 14
                height:  22
                radius:  11
                color:   Qt.rgba(1,1,1,0.15)
                border.color: Qt.rgba(1,1,1,0.3)
                border.width: 1
                Text {
                    id:               countLabel
                    anchors.centerIn: parent
                    text:             missionItem && missionItem.points ? missionItem.points.count + qsTr(" pts") : "0 pts"
                    color:            "#ffffff"
                    font.pixelSize:   11
                    font.bold:        true
                    font.family:      "Outfit"
                }
            }
        }

        // ── Waypoint Cards ───────────────────────────────────────
        Column {
            Layout.fillWidth: true
            width:   parent.width
            spacing: 6

            Repeater {
                model: (missionItem && missionItem.points) ? missionItem.points : 0

                delegate: Item {
                    id:      cardWrapper
                    width:   parent.width
                    visible: root.showAllPoints ? true : (index === root.selectedIndex)
                    height:  visible ? cardRect.height : 0

                    property var    point:        object
                    property bool   isExpanded:   (root.expandedIndex === index)
                    property bool   isSprayOn:    point.pwm > 1200
                    property string editingField: ""

                    Rectangle {
                        id:     cardRect
                        width:  parent.width
                        height: cardCol.implicitHeight + 16
                        radius: 10
                        color:  cardWrapper.isExpanded
                                ? Qt.rgba(1,1,1,0.13)
                                : Qt.rgba(1,1,1,0.07)
                        border.color: cardWrapper.isExpanded
                                      ? Qt.rgba(1,1,1,0.35)
                                      : Qt.rgba(1,1,1,0.15)
                        border.width: 1

                        // Left accent bar
                        Rectangle {
                            width:   4
                            height:  parent.height - 16
                            radius:  2
                            anchors.left:           parent.left
                            anchors.leftMargin:     0
                            anchors.verticalCenter: parent.verticalCenter
                            color: cardWrapper.isSprayOn ? "#4CAF50" : "#E74C3C"
                        }

                        ColumnLayout {
                            id:                  cardCol
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.top:         parent.top
                            anchors.margins:     10
                            anchors.leftMargin:  16
                            spacing:             0

                            // ── Header row ──────────────────────
                            RowLayout {
                                Layout.fillWidth: true
                                spacing:          8
                                Layout.bottomMargin: 4

                                Rectangle {
                                    width:  28
                                    height: 28
                                    radius: 14
                                    color:  Qt.rgba(1,1,1,0.15)
                                    border.color: Qt.rgba(1,1,1,0.35)
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text:             index + 1
                                        color:            "#ffffff"
                                        font.bold:        true
                                        font.pixelSize:   12
                                        font.family:      "Outfit"
                                    }
                                }

                                Text {
                                    text:             qsTr("Waypoint %1").arg(index + 1)
                                    color:            "#ffffff"
                                    font.bold:        true
                                    font.pixelSize:   14
                                    font.family:      "Outfit"
                                    Layout.fillWidth: true
                                }

                                // Spray pill
                                Rectangle {
                                    width:   pillText.implicitWidth + 18
                                    height:  22
                                    radius:  11
                                    color:   cardWrapper.isSprayOn
                                             ? Qt.rgba(0.3,0.85,0.4,0.22)
                                             : Qt.rgba(0.9,0.3,0.2,0.22)
                                    border.color: cardWrapper.isSprayOn ? "#4CAF50" : "#E74C3C"
                                    border.width: 1.5
                                    Text {
                                        id:               pillText
                                        anchors.centerIn: parent
                                        text:             cardWrapper.isSprayOn ? qsTr("ON") : qsTr("OFF")
                                        color:            cardWrapper.isSprayOn ? "#4CAF50" : "#E74C3C"
                                        font.pixelSize:   11
                                        font.bold:        true
                                        font.family:      "Outfit"
                                    }
                                }

                                Text {
                                    text:           cardWrapper.isExpanded ? "▲" : "▼"
                                    color:          "#ffffff"
                                    font.pixelSize: 11
                                    font.bold:      true
                                }
                            }

                            // ── Divider ──────────────────────────
                            Rectangle {
                                visible:          cardWrapper.isExpanded
                                Layout.fillWidth: true
                                height:           1
                                color:            Qt.rgba(1,1,1,0.15)
                                Layout.topMargin: 2
                                Layout.bottomMargin: 6
                            }

                            // ── Fields ───────────────────────────
                            ColumnLayout {
                                visible:          cardWrapper.isExpanded
                                Layout.fillWidth: true
                                Layout.rightMargin: 6
                                spacing:          2

                                // LAT
                                FieldRow {
                                    label:        qsTr("Latitude")
                                    displayValue: point.coordinate.latitude.toFixed(6)
                                    isEditing:    cardWrapper.editingField === "lat"
                                    onEditClicked:  cardWrapper.editingField = "lat"
                                    onSaveValue: (val) => {
                                        var coord = point.coordinate
                                        coord.latitude = parseFloat(val)
                                        point.coordinate = coord
                                        cardWrapper.editingField = ""
                                    }
                                    onCancelEdit: cardWrapper.editingField = ""
                                    Layout.fillWidth: true
                                }

                                FieldRow {
                                    label:        qsTr("Longitude")
                                    displayValue: point.coordinate.longitude.toFixed(6)
                                    isEditing:    cardWrapper.editingField === "lon"
                                    onEditClicked:  cardWrapper.editingField = "lon"
                                    onSaveValue: (val) => {
                                        var coord = point.coordinate
                                        coord.longitude = parseFloat(val)
                                        point.coordinate = coord
                                        cardWrapper.editingField = ""
                                    }
                                    onCancelEdit: cardWrapper.editingField = ""
                                    Layout.fillWidth: true
                                }

                                FieldRow {
                                    label:        qsTr("Altitude (m)")
                                    displayValue: point.altitude.toFixed(1)
                                    isEditing:    cardWrapper.editingField === "alt"
                                    onEditClicked:  cardWrapper.editingField = "alt"
                                    onSaveValue: (val) => {
                                        point.altitude = parseFloat(val)
                                        cardWrapper.editingField = ""
                                    }
                                    onCancelEdit: cardWrapper.editingField = ""
                                    Layout.fillWidth: true
                                }

                                FieldRow {
                                    label:        qsTr("Speed (m/s)")
                                    displayValue: point.speed.toFixed(1)
                                    isEditing:    cardWrapper.editingField === "speed"
                                    onEditClicked:  cardWrapper.editingField = "speed"
                                    onSaveValue: (val) => {
                                        point.speed = parseFloat(val)
                                        cardWrapper.editingField = ""
                                    }
                                    onCancelEdit: cardWrapper.editingField = ""
                                    Layout.fillWidth: true
                                }

                                FieldRow {
                                    label:        qsTr("Hover (s)")
                                    displayValue: point.duration.toFixed(1)
                                    isEditing:    cardWrapper.editingField === "hover"
                                    onEditClicked:  cardWrapper.editingField = "hover"
                                    onSaveValue: (val) => {
                                        point.duration = parseFloat(val)
                                        cardWrapper.editingField = ""
                                    }
                                    onCancelEdit: cardWrapper.editingField = ""
                                    Layout.fillWidth: true
                                }

                                // ── Spray toggle row ─────────────
                                RowLayout {
                                    Layout.fillWidth: true
                                    height:           38
                                    spacing:          8

                                    Text {
                                        text:             qsTr("Spray")
                                        color:            "#ffffff"
                                        font.bold:        true
                                        font.pixelSize:   13
                                        font.family:      "Outfit"
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width:  56
                                        height: 28
                                        radius: 14
                                        color:  cardWrapper.isSprayOn
                                                ? Qt.rgba(0.3,0.85,0.4,0.35)
                                                : Qt.rgba(1,1,1,0.12)
                                        border.color: cardWrapper.isSprayOn ? "#4CAF50" : Qt.rgba(1,1,1,0.25)
                                        border.width: 1.5

                                        Rectangle {
                                            width:  22
                                            height: 22
                                            radius: 11
                                            color:  cardWrapper.isSprayOn ? "#4CAF50" : "#aaaaaa"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: cardWrapper.isSprayOn ? parent.width - width - 3 : 3
                                            Behavior on x {
                                                NumberAnimation { duration: 150; easing.type: Easing.InOutSine }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked:    point.pwm = cardWrapper.isSprayOn ? 1000.0 : 1500.0
                                        }
                                    }
                                }

                                Item { height: 4 }
                            }
                        }

                        MouseArea {
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            anchors.top:   parent.top
                            height:        50
                            onClicked: {
                                if (root.expandedIndex === index) {
                                    root.expandedIndex = -1
                                } else {
                                    root.selectedIndex = index
                                    root.expandedIndex = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component FieldRow: ColumnLayout {
        id:      fieldRow
        spacing: 0
        Layout.fillWidth: true

        property string label:        ""
        property string displayValue: ""
        property bool   isEditing:    false

        signal editClicked()
        signal saveValue(string val)
        signal cancelEdit()

        // ── Top row: Label | Full Value | Edit button ──
        RowLayout {
            Layout.fillWidth: true
            height:           40
            spacing:          8

            // Label
            Text {
                text:              fieldRow.label
                color:             "#F5F5F5"
                font.bold:         true
                font.pixelSize:    13
                font.family:       "Outfit"
                Layout.preferredWidth: 90
                Layout.alignment:  Qt.AlignVCenter
            }

            // Full value — always visible
            Text {
                text:             fieldRow.displayValue
                color:            "#FFFFFF"
                font.pixelSize:   13
                font.family:      "Outfit"
                Layout.fillWidth: true
                elide:            Text.ElideRight
                rightPadding:     4
                Layout.alignment: Qt.AlignVCenter
            }
            Rectangle {
                visible:          !fieldRow.isEditing
                width:            32
                height:           26
                radius:           7
                color:            Qt.rgba(1,1,1,0.1)
                border.color:     Qt.rgba(1,1,1,0.3)
                border.width:     1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text:             "✏️"
                    font.pixelSize:   14
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked:    fieldRow.editClicked()
                }
            }
        }

        ColumnLayout {
            visible:          fieldRow.isEditing
            Layout.fillWidth: true
            spacing:          6
            Layout.bottomMargin: 4

            // Input box
            Rectangle {
                Layout.fillWidth: true
                height:           34
                radius:           8
                color:            Qt.rgba(1,1,1,0.12)
                border.color:     "#4CAF50"
                border.width:     1.2

                TextInput {
                    id:                editInput
                    anchors.fill:      parent
                    anchors.margins:   8
                    text:              fieldRow.displayValue
                    color:             "#FFFFFF"
                    font.pixelSize:    13
                    font.bold:         true
                    font.family:       "Outfit"
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse:     true
                    onVisibleChanged:  if (visible) { selectAll(); forceActiveFocus() }
                    Keys.onReturnPressed: fieldRow.saveValue(text)
                    Keys.onEscapePressed: fieldRow.cancelEdit()
                }
            }

            // Save + Cancel row below input
            RowLayout {
                Layout.fillWidth: true
                spacing:          8

                // Save button
                Rectangle {
                    Layout.fillWidth: true
                    height:           34
                    radius:           8
                    color:            Qt.rgba(0.3,0.85,0.4,0.28)
                    border.color:     "#4CAF50"
                    border.width:     1

                    Text {
                        anchors.centerIn: parent
                        text:             qsTr("Save")
                        color:            "#4CAF50"
                        font.pixelSize:   12
                        font.bold:        true
                        font.family:      "Outfit"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:    fieldRow.saveValue(editInput.text)
                    }
                }

                // Cancel button
                Rectangle {
                    Layout.fillWidth: true
                    height:           34
                    radius:           8
                    color:            Qt.rgba(0.9,0.3,0.2,0.2)
                    border.color:     "#E74C3C"
                    border.width:     1

                    Text {
                        anchors.centerIn: parent
                        text:             qsTr("Cancel")
                        color:            "#E74C3C"
                        font.pixelSize:   12
                        font.bold:        true
                        font.family:      "Outfit"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:    fieldRow.cancelEdit()
                    }
                }
            }
        }
        // Thin divider between fields
        Rectangle {
            Layout.fillWidth: true
            height:           1
            color:            Qt.rgba(1,1,1,0.08)
        }
    }
}
