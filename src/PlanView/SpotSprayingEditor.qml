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
        }

        Column {
            id:             pointsContainer
            Layout.fillWidth: true
            spacing:        ScreenTools.defaultFontPixelHeight / 2
            visible:        pointsHeader.checked

            Repeater {
                model: missionItem.points

                Rectangle {
                    width:          pointsContainer.width
                    height:         cardColumn.implicitHeight + (ScreenTools.defaultFontPixelHeight * 1.5)
                    color:          qgcPal.windowShade
                    radius:         8
                    border.color:   qgcPal.windowShadeDark
                    border.width:   1

                    ColumnLayout {
                        id:                 cardColumn
                        anchors.fill:       parent
                        anchors.margins:    ScreenTools.defaultFontPixelHeight * 0.7
                        spacing:            ScreenTools.defaultFontPixelHeight * 0.5

                        // 1. Header Row (Waypoint Title and Spray Status indicator dot)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth

                            Rectangle {
                                width:          8
                                height:         8
                                radius:         4
                                color:          modelData.spray ? "#2ECC71" : "#E74C3C"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCLabel {
                                text:           qsTr("Waypoint %1").arg(index + 1)
                                font.bold:      true
                                font.pointSize: ScreenTools.mediumFontPointSize
                                Layout.fillWidth: true
                            }
                        }

                        // 2. Editable Values Grid (Lat, Lon, Alt, Speed, Hover Time, Spray toggle)
                        GridLayout {
                            columns:            2
                            columnSpacing:      ScreenTools.defaultFontPixelWidth
                            rowSpacing:         ScreenTools.defaultFontPixelHeight * 0.4
                            Layout.fillWidth:   true

                            // Latitude input
                            QGCLabel {
                                text:           qsTr("Latitude")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCTextField {
                                text:               modelData.coordinate.latitude.toFixed(6)
                                onEditingFinished:  {
                                    var newLat = parseFloat(text)
                                    var currentLon = modelData.coordinate.longitude
                                    modelData.coordinate = QtPositioning.coordinate(newLat, currentLon)
                                }
                                Layout.fillWidth:   true
                            }

                            // Longitude input
                            QGCLabel {
                                text:           qsTr("Longitude")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCTextField {
                                text:               modelData.coordinate.longitude.toFixed(6)
                                onEditingFinished:  {
                                    var newLon = parseFloat(text)
                                    var currentLat = modelData.coordinate.latitude
                                    modelData.coordinate = QtPositioning.coordinate(currentLat, newLon)
                                }
                                Layout.fillWidth:   true
                            }

                            // Altitude input
                            QGCLabel {
                                text:           qsTr("Altitude (m)")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCTextField {
                                text:               modelData.altitude.toFixed(1)
                                onEditingFinished:  modelData.altitude = parseFloat(text)
                                Layout.fillWidth:   true
                            }

                            // Speed input
                            QGCLabel {
                                text:           qsTr("Speed (m/s)")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCTextField {
                                text:               modelData.speed.toFixed(1)
                                onEditingFinished:  modelData.speed = parseFloat(text)
                                Layout.fillWidth:   true
                            }

                            // Hover time input (in seconds)
                            QGCLabel {
                                text:           qsTr("Hover Time (s)")
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCTextField {
                                text:               (modelData.duration * 60.0).toFixed(1)
                                onEditingFinished:  modelData.duration = parseFloat(text) / 60.0
                                Layout.fillWidth:   true
                            }

                            // Spray Toggle
                            QGCLabel {
                                text:           qsTr("Spraying")
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            QGCCheckBox {
                                text:           modelData.spray ? qsTr("ON") : qsTr("OFF")
                                checked:        modelData.spray
                                onClicked:      modelData.spray = checked
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
