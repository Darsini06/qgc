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
    height:     editorColumn.height

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
            Layout.fillWidth: true
            spacing:        ScreenTools.defaultFontPixelHeight / 2
            visible:        pointsHeader.checked

            Repeater {
                model: missionItem.points

                Column {
                    width: parent.width
                    spacing: ScreenTools.defaultFontPixelHeight / 4

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: qgcPal.windowShade
                    }

                    QGCLabel { text: qsTr("Point %1").arg(index + 1); font.bold: true }

                    GridLayout {
                        columns: 2
                        columnSpacing: ScreenTools.defaultFontPixelWidth
                        rowSpacing: ScreenTools.defaultFontPixelHeight / 4

                        QGCLabel { text: qsTr("Lat") }
                        QGCTextField {
                            text: modelData.coordinate.latitude.toFixed(6)
                            onEditingFinished: modelData.coordinate.latitude = parseFloat(text)
                            Layout.fillWidth: true
                        }

                        QGCLabel { text: qsTr("Lon") }
                        QGCTextField {
                            text: modelData.coordinate.longitude.toFixed(6)
                            onEditingFinished: modelData.coordinate.longitude = parseFloat(text)
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

                        QGCLabel { text: qsTr("PWM") }
                        QGCTextField {
                            text: modelData.pwm.toFixed(0)
                            onEditingFinished: modelData.pwm = parseFloat(text)
                            Layout.fillWidth: true
                        }

                        QGCLabel { text: qsTr("Duration (s)") }
                        QGCTextField {
                            text: modelData.duration.toFixed(1)
                            onEditingFinished: modelData.duration = parseFloat(text)
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        QGCButton {
            text: qsTr("Add Point")
            onClicked: {
                var coord = missionItem.coordinate
                if (missionItem.points.count > 0) {
                    coord = missionItem.points.get(missionItem.points.count - 1).coordinate
                }
                missionItem.points.append(missionItem.createPoint(coord))
            }
        }
    }
}
