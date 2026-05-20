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

    property int    expandedIndex: -1

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        id:                 editorColumn
        anchors.left:       parent.left
        anchors.right:      parent.right
        spacing:            ScreenTools.defaultFontPixelHeight / 2

        SectionHeader {
            id:             pointsHeader
            Layout.fillWidth: true
            text:           qsTr("Spot Spraying Waypoints")
            checked:        true
        }


        Column {
            width:          parent.width
            Layout.fillWidth: true
            spacing:        ScreenTools.defaultFontPixelHeight / 2
            visible:        pointsHeader.checked

            Repeater {
                model: missionItem ? missionItem.points : []

                Rectangle {
                    id: cardRect
                    property bool isCardExpanded: true // Expand cards by default so fields are immediately visible!

                    width: parent.width
                    height: contentCol.implicitHeight + (ScreenTools.defaultFontPixelHeight * 1.5)
                    color: isCardExpanded ? qgcPal.windowShade : qgcPal.windowShadeDark
                    radius: 8
                    border.color: qgcPal.windowShadeDark
                    border.width: 1

                    ColumnLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight * 0.7
                        spacing: ScreenTools.defaultFontPixelHeight * 0.5

                        // Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: (modelData.pwm > 1200) ? "#2ECC71" : "#E74C3C"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCLabel {
                                text: qsTr("Waypoint %1").arg(index + 1)
                                font.bold: true
                                font.pointSize: ScreenTools.mediumFontPointSize
                                Layout.fillWidth: true
                            }

                            QGCColoredImage {
                                source:             "/qmlimages/EditArrow.svg"
                                color:              qgcPal.text
                                width:              ScreenTools.defaultFontPixelWidth * 1.5
                                height:             width
                                sourceSize.height:  height
                                rotation:           isCardExpanded ? 90 : 0
                            }
                        }

                        // Editable Fields (Visible only when expanded)
                        GridLayout {
                            visible: isCardExpanded
                            columns: 2
                            columnSpacing: ScreenTools.defaultFontPixelWidth
                            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.4
                            Layout.fillWidth: true

                            QGCLabel { text: qsTr("Lat") }
                            QGCTextField {
                                text: modelData.coordinate.latitude.toFixed(6)
                                onEditingFinished: {
                                    var coord = modelData.coordinate
                                    coord.latitude = parseFloat(text)
                                    modelData.coordinate = coord
                                }
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Lon") }
                            QGCTextField {
                                text: modelData.coordinate.longitude.toFixed(6)
                                onEditingFinished: {
                                    var coord = modelData.coordinate
                                    coord.longitude = parseFloat(text)
                                    modelData.coordinate = coord
                                }
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Alt (m)") }
                            QGCTextField {
                                text: modelData.altitude.toFixed(1)
                                onEditingFinished: modelData.altitude = parseFloat(text)
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Speed (m/s)") }
                            QGCTextField {
                                text: modelData.speed.toFixed(1)
                                onEditingFinished: modelData.speed = parseFloat(text)
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Hover (s)") }
                            QGCTextField {
                                text: modelData.duration.toFixed(1)
                                onEditingFinished: modelData.duration = parseFloat(text)
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Spray") }
                            QGCCheckBox {
                                text: (modelData.pwm > 1200) ? qsTr("ON") : qsTr("OFF")
                                checked: modelData.pwm > 1200
                                onClicked: modelData.pwm = checked ? 1500.0 : 1000.0
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Click area only for the top header part of the card
                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: ScreenTools.defaultFontPixelHeight * 2.5
                        onClicked: {
                            cardRect.isCardExpanded = !cardRect.isCardExpanded
                        }
                    }
                }
            }
        }
    }
}
