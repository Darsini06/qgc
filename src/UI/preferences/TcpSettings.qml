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

GridLayout {
    columns:        2
    rowSpacing:     _rowSpacing
    columnSpacing:  _colSpacing

    function saveSettings() {
        subEditConfig.host = hostField.text
        subEditConfig.port = parseInt(portField.text)
    }

    QGCLabel { text: qsTr("Server Address"); color: "#DDDDDD" }
    QGCTextField {
        id:                     hostField
        Layout.preferredWidth:  _secondColumnWidth
        text:                   subEditConfig.host
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

    QGCLabel { text: qsTr("Port"); color: "#DDDDDD" }
    QGCTextField {
        id:                     portField
        Layout.preferredWidth:  _secondColumnWidth
        text:                   subEditConfig.port.toString()
        inputMethodHints:       Qt.ImhFormattedNumbersOnly
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
