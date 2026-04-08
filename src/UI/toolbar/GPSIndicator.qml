/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette

// Used as the base class control for nboth VehicleGPSIndicator and RTKGPSIndicator

Item {
    id:             control
    width:          gpsIndicatorRow.width

    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool   _rtkConnected:  QGroundControl.gpsRtk.connected.value

    Item {
        id:             gpsIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width:          bgRect.width

        Rectangle {
            id: bgRect
            height: parent.height
            width: contentRowLayout.width + ScreenTools.defaultFontPixelWidth * 1.5
            color: "transparent"
            border.width: 0
            clip: true

            // Inner gauge fill based on satellite count (max 20)
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                
                width: {
                    var satCount = _activeVehicle ? _activeVehicle.gps.count.value : 0
                    var pct = Math.max(0, Math.min(100, (satCount / 20.0) * 100))
                    return parent.width * (pct / 100.0)
                }
                
                color: {
                    var hdop = _activeVehicle ? _activeVehicle.gps.hdop.value : 99
                    if (hdop <= 1.5) return qgcPal.colorGreen
                    if (hdop <= 2.5) return qgcPal.colorYellow
                    return qgcPal.colorRed
                }
                opacity: 0.25
                radius: parent.radius
            }

            RowLayout {
                id: contentRowLayout
                anchors.centerIn: parent
                spacing: ScreenTools.defaultFontPixelWidth / 2

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    
                    QGCLabel {
                        id:                     gpsLabel
                        rotation:               _rtkConnected ? 90 : 0
                        text:                   qsTr("RTK")
                        color:                  "white"
                        Layout.alignment:       Qt.AlignVCenter
                        visible:                _rtkConnected
                        font.pointSize:         ScreenTools.smallFontPointSize - 2
                    }

                    QGCColoredImage {
                        id:                 gpsIcon
                        Layout.preferredWidth:  20
                        Layout.preferredHeight: 20
                        source:             "/qmlimages/Gps.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  Layout.preferredHeight
                        opacity:            (_activeVehicle && _activeVehicle.gps.count.value >= 0) ? 1 : 0.5
                        color:              "white"
                        Layout.alignment:   Qt.AlignVCenter
                    }
                }

                ColumnLayout {
                    id:                     gpsValuesColumn
                    Layout.alignment:       Qt.AlignVCenter
                    visible:                _activeVehicle && !isNaN(_activeVehicle.gps.hdop.value)
                    spacing:                -2

                    QGCLabel {
                        Layout.alignment:   Qt.AlignHCenter
                        color:              "white"
                        text:               _activeVehicle ? _activeVehicle.gps.count.valueString : ""
                        font.pointSize:     ScreenTools.smallFontPointSize
                        font.bold:          true
                    }

                    QGCLabel {
                        id:                 hdopValue
                        Layout.alignment:   Qt.AlignHCenter
                        color:              "white"
                        text:               _activeVehicle ? _activeVehicle.gps.hdop.value.toFixed(1) : ""
                        font.pointSize:     ScreenTools.smallFontPointSize - 2
                        opacity:            0.8
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill:   parent
        hoverEnabled:   true
        onClicked:      mainWindow.showIndicatorDrawer(gpsIndicatorPage, control)
    }

    Component {
        id: gpsIndicatorPage

        GPSIndicatorPage { }
    }
}
