/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

/// Dialog shown when mission upload is blocked or warned due to airspace restrictions
QGCPopupDialog {
    id: _root

    property var validator              ///< AirspaceRestrictionValidator instance
    property bool isBlocked: false      ///< Whether mission is blocked (red zone)
    property string message: ""         ///< Restriction message
    property var onAccept: null         ///< Callback when user accepts (for warnings)
    property var onCancel: null         ///< Callback when user cancels

    title: isBlocked ? "Mission Upload Blocked" : "Airspace Restriction Warning"
    buttons: {
        if (isBlocked) {
            return Dialog.Ok
        } else {
            return Dialog.Ok | Dialog.Cancel
        }
    }

    onAccepted: {
        if (onAccept) {
            onAccept()
        }
    }

    onRejected: {
        if (onCancel) {
            onCancel()
        }
    }

    ColumnLayout {
        spacing: ScreenTools.defaultFontPixelHeight
        width: ScreenTools.defaultFontPixelWidth * 50

        // Icon
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 4

            QGCColoredImage {
                anchors.centerIn: parent
                width: ScreenTools.defaultFontPixelHeight * 4
                height: ScreenTools.defaultFontPixelHeight * 4
                source: isBlocked ? "/qmlimages/Stop.svg" : "/qmlimages/Warning.svg"
                color: isBlocked ? qgcPal.colorRed : qgcPal.colorOrange
                fillMode: Image.PreserveAspectFit
            }
        }

        // Message
        QGCLabel {
            Layout.fillWidth: true
            text: message
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: ScreenTools.defaultFontPointSize
        }

        // Detailed explanation
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: _detailsColumn.height + ScreenTools.defaultFontPixelHeight
            color: Qt.rgba(0, 0, 0, 0.1)
            radius: ScreenTools.defaultFontPixelHeight * 0.25
            border.color: qgcPal.text
            border.width: 1

            ColumnLayout {
                id: _detailsColumn
                anchors.centerIn: parent
                width: parent.width - ScreenTools.defaultFontPixelWidth * 2
                spacing: ScreenTools.defaultFontPixelHeight * 0.5

                QGCLabel {
                    Layout.fillWidth: true
                    text: isBlocked ? 
                          "Your mission path intersects a prohibited airspace zone (Red Zone)." :
                          "Your mission path intersects a restricted airspace zone."
                    wrapMode: Text.WordWrap
                    font.pixelSize: ScreenTools.smallFontPointSize
                }

                QGCLabel {
                    Layout.fillWidth: true
                    text: isBlocked ?
                          "Flight in this area is not permitted. Please modify your mission to avoid this zone." :
                          "Flight in this area requires special authorization or caution. Ensure you have the necessary permissions before proceeding."
                    wrapMode: Text.WordWrap
                    font.pixelSize: ScreenTools.smallFontPointSize
                    color: qgcPal.warningText
                }
            }
        }

        // Zone type legend
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: ScreenTools.defaultFontPixelHeight * 0.25
            columnSpacing: ScreenTools.defaultFontPixelWidth

            QGCLabel {
                text: "Zone Types:"
                font.bold: true
                font.pixelSize: ScreenTools.smallFontPointSize
            }
            Item { width: 1; height: 1 }

            Rectangle {
                width: ScreenTools.defaultFontPixelHeight
                height: ScreenTools.defaultFontPixelHeight
                color: "#FF0000"
                opacity: 0.4
                border.color: "#8B0000"
                border.width: 2
            }
            QGCLabel {
                text: "Red Zone - Prohibited (Flight Blocked)"
                font.pixelSize: ScreenTools.tinyFontPointSize
            }

            Rectangle {
                width: ScreenTools.defaultFontPixelHeight
                height: ScreenTools.defaultFontPixelHeight
                color: "#FFFF00"
                opacity: 0.3
                border.color: "#FFA500"
                border.width: 2
            }
            QGCLabel {
                text: "Yellow Zone - Restricted (Warning Only)"
                font.pixelSize: ScreenTools.tinyFontPointSize
            }

            Rectangle {
                width: ScreenTools.defaultFontPixelHeight
                height: ScreenTools.defaultFontPixelHeight
                color: "#8B0000"
                opacity: 0.5
                border.color: "#FF0000"
                border.width: 2
            }
            QGCLabel {
                text: "Military Zone - Restricted (Warning Only)"
                font.pixelSize: ScreenTools.tinyFontPointSize
            }
        }

        // Action guidance
        QGCLabel {
            Layout.fillWidth: true
            text: isBlocked ?
                  "Click OK to return to mission planning and modify your route." :
                  "Click OK to proceed with mission upload, or Cancel to modify your route."
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: ScreenTools.smallFontPointSize
            font.italic: true
        }
    }
}
