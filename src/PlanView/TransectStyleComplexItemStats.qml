import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

import MapGlobals

// Statistics section for TransectStyleComplexItems - Premium HUD Version
Item {
    id: _root
    implicitHeight: mainLayout.implicitHeight
    implicitWidth:  parent.width

    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#8e8e93"
    readonly property color _colorAccent:        "#471880"
    readonly property color _colorBgTertiary:    "#32323b"


    property real currentArea: missionItem.surveyAreaPolygon.area

    Connections {
        target: missionItem.surveyAreaPolygon
        onPathChanged: {
            currentArea = missionItem.surveyAreaPolygon.area
            MapGlobals.acres = QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(currentArea).toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString
        }
    }

    // Label column
    // QGCLabel { text: qsTr("Survey Area");     color: _colorTextSecondary; font.pointSize: ScreenTools.smallFontPointSize }

    // QGCLabel {
    //     text: {
    //         var val = QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(currentArea)
    //         var unitStr = QGroundControl.unitsConversion.appSettingsAreaUnitsString
    //         if (val > 0 && val < 0.01) {
    //             return val.toFixed(4) + " " + unitStr
    //         }
    //         return val.toFixed(2) + " " + unitStr
    //     }
    //     color: _colorTextPrimary
    //     font.bold: true
    // }

    property string _application: QGroundControl.loadGlobalSetting("loadpage","loadpage");


    ColumnLayout {
        id:             mainLayout
        anchors.fill:   parent
        spacing:        ScreenTools.defaultFontPixelHeight * 0.75

        // --- TOP ROW: Area and Photo Count ---
        RowLayout {
            Layout.fillWidth: true
            spacing:          ScreenTools.defaultFontPixelWidth

            // Area Card
            Rectangle {
                Layout.fillWidth: true
                height:           64
                radius:           12
                color:            _colorBgTertiary
                border.color:     Qt.rgba(255,255,255,0.05)
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    QGCLabel {
                        text: _application === "Agri" ? qsTr("COVERED AREA") : qsTr("SURVEY AREA")
                        font.pixelSize: ScreenTools.smallFontPointSize * 0.8
                        font.bold: true
                        color: _colorTextSecondary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QGCLabel {
                        text: QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(missionItem.coveredArea).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: _colorTextPrimary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Photos Card
            Rectangle {
                Layout.fillWidth: true
                height:           64
                radius:           12
                color:            _colorBgTertiary
                border.color:     Qt.rgba(255,255,255,0.05)
                visible:          _application !== "Agri"
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    QGCLabel {
                        text: qsTr("TOTAL PHOTOS")
                        font.pixelSize: ScreenTools.smallFontPointSize * 0.8
                        font.bold: true
                        color: _colorTextSecondary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QGCLabel {
                        text: missionItem.cameraShots
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: _colorAccent
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // --- BOTTOM ROW: Interval and Estimated Time ---
        RowLayout {
            Layout.fillWidth: true
            spacing:          ScreenTools.defaultFontPixelWidth

            // Interval Card
            Rectangle {
                Layout.fillWidth: true
                height:           64
                radius:           12
                color:            _colorBgTertiary
                border.color:     Qt.rgba(255,255,255,0.05)
                visible:          _application !== "Agri"
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    QGCLabel {
                        text: qsTr("INTERVAL")
                        font.pixelSize: ScreenTools.smallFontPointSize * 0.8
                        font.bold: true
                        color: _colorTextSecondary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QGCLabel {
                        text: missionItem.timeBetweenShots.toFixed(1) + "s"
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: _colorTextPrimary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Time Card
            Rectangle {
                Layout.fillWidth: true
                height:           64
                radius:           12
                color:            _colorBgTertiary
                border.color:     Qt.rgba(255,255,255,0.05)
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    QGCLabel {
                        text: qsTr("EST. TIME")
                        font.pixelSize: ScreenTools.smallFontPointSize * 0.8
                        font.bold: true
                        color: _colorTextSecondary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QGCLabel {
                        text: MapGlobals.time
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: "#2ECC71" // Emerald Green for success/time
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
