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
    readonly property color _colorTextSecondary: "#e0e0e0"
    readonly property color _colorAccent:        "#000000"
    readonly property color _colorBgTertiary:    "transparent"


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

        // --- Area Card: Full Width at Top ---
        Rectangle {
            Layout.fillWidth: true
            height:           72
            radius:           12
            color:            _colorBgTertiary
            border.color:     Qt.rgba(255,255,255,0.05)
            
            Column {
                anchors.centerIn: parent
                spacing: 2
                QGCLabel {
                    text: _application === "Agri" ? qsTr("COVERED AREA") : qsTr("SURVEY AREA")
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.bold: true
                    color: _colorTextSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                RowLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    QGCLabel {
                        text: missionItem.coveredArea.toLocaleString(Qt.locale(), "f", 1)
                        font.pointSize: ScreenTools.largeFontPointSize
                        font.bold: true
                        color: _colorTextPrimary
                        Layout.alignment: Qt.AlignBottom
                    }
                    QGCLabel {
                        text: "m²"
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.bold: true
                        color: _colorTextSecondary
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 2
                    }
                }
            }
        }

        // --- Middle Row: Photos and Interval ---
        RowLayout {
            Layout.fillWidth: true
            spacing:          ScreenTools.defaultFontPixelWidth
            visible:          _application !== "Agri"

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
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.bold: true
                        color: _colorTextSecondary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QGCLabel {
                        text: missionItem.cameraShots
                        font.pointSize: ScreenTools.mediumFontPointSize
                        font.bold: true
                        color: _colorTextPrimary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

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
                        font.pointSize: ScreenTools.defaultFontPointSize
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
        }

        // --- Bottom Row: Estimated Time (Full Width) ---
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
                    text: qsTr("ESTIMATED FLIGHT TIME")
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.bold: true
                    color: _colorTextSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                QGCLabel {
                    text: MapGlobals.time
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true
                    color: _colorTextPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
