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
    property var masterController

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

               delegate: Rectangle {
                    id: cardRect
                    Component.onCompleted: {
                        console.log("------ POINT ------")
                        console.log("LAT:", object.coordinate.latitude)
                        console.log("LON:", object.coordinate.longitude)
                        console.log("ALT:", object.altitude)
                        console.log("SPEED:", object.speed)
                        console.log("PWM:", object.pwm)
                        console.log("DURATION:", object.duration)
                    }
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
                                color: (object.pwm > 1200) ? "#2ECC71" : "#E74C3C"
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
                               text: object.coordinate.latitude.toFixed(6)
                                onEditingFinished: {
                                   var coord = object.coordinate
                                    coord.latitude = parseFloat(text)
                                    object.coordinate = coord
                                }
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Lon") }

                            QGCTextField {
                                text: object.coordinate.longitude.toFixed(6)
                                onEditingFinished: {
                                   var coord = object.coordinate
                                    coord.longitude = parseFloat(text)
                                    object.coordinate = coord
                                }
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Alt (m)") }

                            QGCTextField {
                               text: object.altitude.toFixed(1)
                                onEditingFinished: object.altitude = parseFloat(text)
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Speed (m/s)") }

                            QGCTextField {
                               text: object.speed.toFixed(1)
                                onEditingFinished: object.speed = parseFloat(text)
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Hover (s)") }
                            QGCTextField {
                                text: object.duration.toFixed(1)
                                onEditingFinished: object.duration = parseFloat(text)
                                Layout.fillWidth: true
                            }

                            QGCLabel { text: qsTr("Spray") }
                            QGCCheckBox {
                                text: (object.pwm > 1200) ? qsTr("ON") : qsTr("OFF")
                                checked: object.pwm > 1200
                                onClicked: object.pwm = checked ? 1500.0 : 1000.0
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
