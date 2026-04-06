/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

Item {
    id:             control
    // Footprint matches the background circle's radius
    implicitWidth:  compassRadius * 1.8
    implicitHeight: implicitWidth

    property real attitudeSize:         ScreenTools.defaultFontPixelHeight * 0.75
    property real attitudeSpacing:      ScreenTools.defaultFontPixelHeight / 4
    property real extraInset:           attitudeSize + attitudeSpacing
    property real extraValuesWidth:     compassRadius
    property real defaultCompassRadius: (mainWindow.width * 0.15) / 2
    property real maxCompassRadius:     ScreenTools.defaultFontPixelHeight * 2.5
    property real compassRadius:        Math.min(defaultCompassRadius, maxCompassRadius)
    property real compassBorder:        ScreenTools.defaultFontPixelHeight / 2
    property var  vehicle:              globals.activeVehicle
    property var  qgcPal:               QGroundControl.globalPalette

    property real _totalAttitudeSize: attitudeSize + attitudeSpacing

    IntegratedAttitudeIndicator {
        id:                     rollIndicator
        anchors.centerIn:       parent
        attitudeAngleDegrees:   vehicle ? vehicle.roll.rawValue : 0
        compassRadius:          control.compassRadius
    }

    IntegratedAttitudeIndicator {
        anchors.centerIn:       parent
        attitudeAngleDegrees:   vehicle ? vehicle.pitch.rawValue : 0
        compassRadius:          control.compassRadius
        transformOrigin:        Item.Center
        rotation:               90
    }

    Rectangle {
        anchors.centerIn:   parent
        width:              compassRadius * 1.8
        height:             width
        radius:             width / 2
        color:              qgcPal.window
        opacity:            0.5

        QGCCompassWidget {
            size:               parent.width - compassBorder
            vehicle:            globals.activeVehicle
            anchors.centerIn:   parent
        }
    }
}
