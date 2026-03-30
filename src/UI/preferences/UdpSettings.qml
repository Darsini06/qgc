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
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

ColumnLayout {
    spacing: _rowSpacing

    function saveSettings() {
        // No need
    }

    QGCLabel {
        Layout.preferredWidth: _secondColumnWidth
        Layout.fillWidth:       true
        font.pointSize:         ScreenTools.smallFontPointSize
        wrapMode:               Text.WordWrap
        color:                  "#888888" // Softer for notes
        text:                   qsTr("Note: For best perfomance, please disable AutoConnect to UDP devices on the General page.")
    }

    RowLayout {
        spacing: _colSpacing

        QGCLabel { text: qsTr("Port"); color: "#DDDDDD" }
        QGCTextField {
            id:                     portField
            text:                   subEditConfig.localPort.toString()
            focus:                  true
            Layout.preferredWidth:  _secondColumnWidth
            inputMethodHints:       Qt.ImhFormattedNumbersOnly
            onTextChanged:          subEditConfig.localPort = parseInt(portField.text)
            textColor:              "white"
            leftPadding:            16
            rightPadding:           16
            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: portField.activeFocus ? "#4a2c6d" : "#333333"
                border.width: portField.activeFocus ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
        }
    }

    QGCLabel { text: qsTr("Server Addresses (optional)"); color: "#DDDDDD" }

    Repeater {
        model: subEditConfig.hostList

        delegate: RowLayout {
            spacing: _colSpacing

            QGCLabel {
                Layout.preferredWidth:  _secondColumnWidth
                text:                   modelData
                color:                  "white"
            }

            QGCButton {
                id:         removeBtn
                text:       qsTr("Remove")
                onClicked:  subEditConfig.removeHost(modelData)
                contentItem: Text {
                    text: removeBtn.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Outfit"
                }
                background: Rectangle {
                    implicitHeight: 36
                    implicitWidth: 80
                    radius: 8
                    color: removeBtn.pressed ? "#c81e1e" : (removeBtn.hovered ? "#ef4444" : "#333333")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }

    RowLayout {
        spacing: _colSpacing

        QGCTextField {
            id:                     hostField
            Layout.preferredWidth:  _secondColumnWidth
            placeholderText:        qsTr("Example: 127.0.0.1:14550")
            textColor:              "white"
            leftPadding:            16
            rightPadding:           16
            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: hostField.activeFocus ? "#4a2c6d" : "#333333"
                border.width: hostField.activeFocus ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
        }
        QGCButton {
            id:         addServerBtn
            text:       qsTr("Add Server")
            enabled:    hostField.text !== ""
            onClicked: {
                subEditConfig.addHost(hostField.text)
                hostField.text = ""
            }
            contentItem: Text {
                text: addServerBtn.text
                color: addServerBtn.enabled ? "white" : "#888888"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                font.bold: true
                font.family: "Outfit"
            }
            background: Rectangle {
                implicitHeight: 44
                implicitWidth: 120
                radius: 8
                color: addServerBtn.enabled ? (addServerBtn.pressed ? "#3a1c5d" : (addServerBtn.hovered ? "#5a3c7d" : "#4a2c6d")) : "#333333"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }
}
