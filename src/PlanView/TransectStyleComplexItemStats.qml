import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

import MapGlobals

// Statistics section for TransectStyleComplexItems
GridLayout {
    // The following properties must be available up the hierarchy chain
    //property var    missionItem       ///< Mission Item for editor

    columns:        2
    columnSpacing:  ScreenTools.defaultFontPixelWidth * 1.5
    rowSpacing:     ScreenTools.defaultFontPixelHeight * 0.5

    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#8e8e93"
    readonly property color _colorAccent:        "#301934"

    property real currentArea: missionItem.surveyAreaPolygon.area

    Connections {
        target: missionItem.surveyAreaPolygon
        onPathChanged: {
            currentArea = missionItem.surveyAreaPolygon.area
            MapGlobals.acres = QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(currentArea).toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString
        }
    }

    // Label column
    QGCLabel { text: qsTr("Survey Area");     color: _colorTextSecondary; font.pointSize: ScreenTools.smallFontPointSize }
    QGCLabel { 
        text: {
            var val = QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(currentArea)
            var unitStr = QGroundControl.unitsConversion.appSettingsAreaUnitsString
            if (val > 0 && val < 0.01) {
                return val.toFixed(4) + " " + unitStr
            }
            return val.toFixed(2) + " " + unitStr
        }
        color: _colorTextPrimary
        font.bold: true 
    }

    QGCLabel { text: qsTr("Photo Count");     color: _colorTextSecondary; font.pointSize: ScreenTools.smallFontPointSize }
    QGCLabel { text: missionItem.cameraShots; color: _colorTextPrimary; font.bold: true }

    QGCLabel { text: qsTr("Photo Interval");  color: _colorTextSecondary; font.pointSize: ScreenTools.smallFontPointSize }
    QGCLabel { text: missionItem.timeBetweenShots.toFixed(1) + " " + qsTr("secs"); color: _colorTextPrimary; font.bold: true }

    QGCLabel { text: qsTr("Trigger Distance"); color: _colorTextSecondary; font.pointSize: ScreenTools.smallFontPointSize }
    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintFrontal.valueString + " " + missionItem.cameraCalc.adjustedFootprintFrontal.units; color: _colorTextPrimary; font.bold: true }

    QGCLabel { text: qsTr("Time");            color: _colorTextSecondary; font.pointSize: ScreenTools.smallFontPointSize }
    QGCLabel { text: MapGlobals.time;         color: _colorTextPrimary; font.bold: true }
}
