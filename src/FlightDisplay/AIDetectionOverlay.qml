/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtCore

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.ScreenTools

Item {
    id: root

    property bool detectionEnabled: false
    property bool videoActive: false
    property var videoItem

    readonly property bool modelReady: yoloController.modelReady
    readonly property var detections: yoloController.detections

    visible: detectionEnabled

    YoloDetectionController {
        id: yoloController
    }

    Timer {
        id: yoloFrameTimer
        interval: 600
        repeat: true
        running: root.detectionEnabled && root.videoActive && root.modelReady && root.videoItem
        onTriggered: {
            var framePath = StandardPaths.writableLocation(StandardPaths.TempLocation) + "/qgc_ai_yolo_frame.jpg"
            root.videoItem.grabToImage(function(result) {
                if (result.saveToFile(framePath)) {
                    yoloController.detectImage(framePath)
                }
            }, Qt.size(640, 360))
        }
    }

    Rectangle {
        id: statusPill
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: ScreenTools.defaultFontPixelWidth
        width: Math.min(parent.width - (anchors.margins * 2), Math.max(statusText.implicitWidth + ScreenTools.defaultFontPixelWidth * 4, ScreenTools.defaultFontPixelWidth * 28))
        height: Math.max(statusText.implicitHeight + ScreenTools.defaultFontPixelHeight, ScreenTools.defaultFontPixelHeight * 2.8)
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.68)
        border.color: modelReady ? "#2bd86b" : "#f5b642"
        border.width: 1

        QGCLabel {
            id: statusText
            anchors.centerIn: parent
            width: parent.width - ScreenTools.defaultFontPixelWidth * 2
            text: yoloController.statusText
            color: "white"
            font.bold: true
            font.pointSize: ScreenTools.smallFontPointSize
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    Repeater {
        model: root.modelReady ? root.detections : []

        delegate: Item {
            x: Math.max(0, Math.min(parent.width, modelData.x * parent.width))
            y: Math.max(0, Math.min(parent.height, modelData.y * parent.height))
            width: Math.max(ScreenTools.defaultFontPixelWidth * 6, modelData.w * parent.width)
            height: Math.max(ScreenTools.defaultFontPixelHeight * 3, modelData.h * parent.height)

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: "#2bd86b"
                border.width: 2
                radius: 3
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                height: labelText.implicitHeight + 6
                width: Math.min(parent.width, labelText.implicitWidth + 12)
                color: "#2bd86b"
                radius: 3

                QGCLabel {
                    id: labelText
                    anchors.centerIn: parent
                    text: (modelData.label || qsTr("Object")) + (modelData.confidence !== undefined ? (" " + Math.round(modelData.confidence * 100) + "%") : "")
                    color: "black"
                    font.bold: true
                    font.pointSize: ScreenTools.smallFontPointSize
                    elide: Text.ElideRight
                    width: parent.width - 8
                }
            }
        }
    }
}
