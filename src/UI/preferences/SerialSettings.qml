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
        // No Need
    }

    GridLayout {
        columns:        2
        rowSpacing:     _rowSpacing
        columnSpacing:  _colSpacing

        QGCLabel { text: qsTr("Serial Port"); color: "#DDDDDD" }
        QGCComboBox {
            id:                     commPortCombo
            Layout.preferredWidth:  _secondColumnWidth
            enabled:                QGroundControl.linkManager.serialPorts.length > 0

            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: commPortCombo.activeFocus || commPortCombo.pressed ? "#4a2c6d" : "#333333"
                border.width: commPortCombo.activeFocus || commPortCombo.pressed ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
            contentItem: Text {
                text: commPortCombo.currentText
                font: commPortCombo.font
                color: "white"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 16
            }

            indicator: QGCColoredImage {
                anchors.rightMargin:    ScreenTools.comboBoxPadding
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                height:                 ScreenTools.defaultFontPixelWidth
                width:                  height
                source:                 "/qmlimages/arrow-down.png"
                color:                  "white"
            }

            popup: Popup {
                y: commPortCombo.height - 1
                width: commPortCombo.width
                implicitHeight: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: commPortCombo.delegateModel
                    currentIndex: commPortCombo.highlightedIndex
                }
                background: Rectangle {
                    color: "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1
                    radius: 4
                }
            }

            delegate: ItemDelegate {
                width: commPortCombo.width
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font: commPortCombo.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                background: Rectangle {
                    color: parent.highlighted ? "#4a2c6d" : "#2A2A2A"
                }
            }

            onActivated: (index) => {
                if (index != -1) {
                    if (index >= QGroundControl.linkManager.serialPortStrings.length) {
                        // This item was adding at the end, must use added text as name
                        subEditConfig.portName = commPortCombo.textAt(index)
                    } else {
                        subEditConfig.portName = QGroundControl.linkManager.serialPorts[index]
                    }
                }
            }

            Component.onCompleted: {
                var index = -1
                var serialPorts = [ ]
                if (QGroundControl.linkManager.serialPortStrings.length !== 0) {
                    for (var i=0; i<QGroundControl.linkManager.serialPortStrings.length; i++) {
                        serialPorts.push(QGroundControl.linkManager.serialPortStrings[i])
                    }
                    if (subEditConfig.portDisplayName === "" && QGroundControl.linkManager.serialPorts.length > 0) {
                        subEditConfig.portName = QGroundControl.linkManager.serialPorts[0]
                    }
                    index = serialPorts.indexOf(subEditConfig.portDisplayName)
                    if (index === -1) {
                        serialPorts.push(subEditConfig.portName)
                        index = serialPorts.indexOf(subEditConfig.portName)
                    }
                }
                if (serialPorts.length === 0) {
                    serialPorts = [ qsTr("None Available") ]
                    index = 0
                }
                commPortCombo.model = serialPorts
                commPortCombo.currentIndex = index
            }
        }

        QGCLabel { text: qsTr("Baud Rate"); color: "#DDDDDD" }
        QGCComboBox {
            id:                     baudCombo
            Layout.preferredWidth:  _secondColumnWidth
            model:                  QGroundControl.linkManager.serialBaudRates

            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: baudCombo.activeFocus || baudCombo.pressed ? "#4a2c6d" : "#333333"
                border.width: baudCombo.activeFocus || baudCombo.pressed ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
            contentItem: Text {
                text: baudCombo.currentText
                font: baudCombo.font
                color: "white"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 16
            }

            indicator: QGCColoredImage {
                anchors.rightMargin:    ScreenTools.comboBoxPadding
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                height:                 ScreenTools.defaultFontPixelWidth
                width:                  height
                source:                 "/qmlimages/arrow-down.png"
                color:                  "white"
            }

            popup: Popup {
                y: baudCombo.height - 1
                width: baudCombo.width
                implicitHeight: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: baudCombo.delegateModel
                    currentIndex: baudCombo.highlightedIndex
                }
                background: Rectangle {
                    color: "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1
                    radius: 4
                }
            }

            delegate: ItemDelegate {
                width: baudCombo.width
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font: baudCombo.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                background: Rectangle {
                    color: parent.highlighted ? "#4a2c6d" : "#2A2A2A"
                }
            }

            onActivated: (index) => {
                if (index != -1) {
                    subEditConfig.baud = parseInt(QGroundControl.linkManager.serialBaudRates[index])
                }
            }

            Component.onCompleted: {
                var baud = "57600"
                if(subEditConfig != null) {
                    baud = subEditConfig.baud.toString()
                }
                var index = baudCombo.find(baud)
                if (index === -1) {
                    console.warn(qsTr("Baud rate name not in combo box"), baud)
                } else {
                    baudCombo.currentIndex = index
                }
            }
        }
    }

    QGCCheckBox {
        id:         advancedSettings
        text:       qsTr("Advanced Settings")
        textColor:  "white"
        checked:    false
    }

    GridLayout {
        columns:        2
        rowSpacing:     _rowSpacing
        columnSpacing:  _colSpacing
        visible:        advancedSettings.checked

        QGCCheckBox {
            Layout.columnSpan:  2
            text:               qsTr("Enable Flow Control")
            textColor:          "white"
            checked:            subEditConfig.flowControl !== 0
            onCheckedChanged:   subEditConfig.flowControl = checked ? 1 : 0
        }

        QGCLabel { text: qsTr("Parity"); color: "#DDDDDD" }

        QGCComboBox {
            id:                     parityCombo
            Layout.preferredWidth:  _secondColumnWidth
            model:                  [qsTr("None"), qsTr("Even"), qsTr("Odd")]

            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: parityCombo.activeFocus ? "#4a2c6d" : "#333333"
                border.width: parityCombo.activeFocus ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
            contentItem: Text {
                text: parityCombo.currentText
                font: parityCombo.font
                color: "white"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 16
            }

            indicator: QGCColoredImage {
                anchors.rightMargin:    ScreenTools.comboBoxPadding
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                height:                 ScreenTools.defaultFontPixelWidth
                width:                  height
                source:                 "/qmlimages/arrow-down.png"
                color:                  "white"
            }

            popup: Popup {
                y: parityCombo.height - 1
                width: parityCombo.width
                implicitHeight: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: parityCombo.delegateModel
                    currentIndex: parityCombo.highlightedIndex
                }
                background: Rectangle {
                    color: "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1
                    radius: 4
                }
            }

            delegate: ItemDelegate {
                width: parityCombo.width
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font: parityCombo.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                background: Rectangle {
                    color: parent.highlighted ? "#4a2c6d" : "#2A2A2A"
                }
            }

            onActivated: (index) => {
                // Hard coded values from qserialport.h
                switch (index) {
                case 0:
                    subEditConfig.parity = 0
                    break
                case 1:
                    subEditConfig.parity = 2
                    break
                case 2:
                    subEditConfig.parity = 3
                    break
                }
            }

            Component.onCompleted: {
                switch (subEditConfig.parity) {
                case 0:
                    currentIndex = 0
                    break
                case 2:
                    currentIndex = 1
                    break
                case 3:
                    currentIndex = 2
                    break
                default:
                    console.warn("Unknown parity", subEditConfig.parity)
                    break
                }
            }
        }

        QGCLabel { text: qsTr("Data Bits"); color: "#DDDDDD" }

        QGCComboBox {
            id:                     dataBitsCombo
            Layout.preferredWidth:  _secondColumnWidth
            model:                  [ "5", "6", "7", "8" ]

            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: dataBitsCombo.activeFocus ? "#4a2c6d" : "#333333"
                border.width: dataBitsCombo.activeFocus ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
            contentItem: Text {
                text: dataBitsCombo.currentText
                font: dataBitsCombo.font
                color: "white"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 16
            }

            indicator: QGCColoredImage {
                anchors.rightMargin:    ScreenTools.comboBoxPadding
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                height:                 ScreenTools.defaultFontPixelWidth
                width:                  height
                source:                 "/qmlimages/arrow-down.png"
                color:                  "white"
            }

            popup: Popup {
                y: dataBitsCombo.height - 1
                width: dataBitsCombo.width
                implicitHeight: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: dataBitsCombo.delegateModel
                    currentIndex: dataBitsCombo.highlightedIndex
                }
                background: Rectangle {
                    color: "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1
                    radius: 4
                }
            }

            delegate: ItemDelegate {
                width: dataBitsCombo.width
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font: dataBitsCombo.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                background: Rectangle {
                    color: parent.highlighted ? "#4a2c6d" : "#2A2A2A"
                }
            }
            currentIndex:           Math.max(Math.min(subEditConfig.dataBits - 5, 3), 0)
            onActivated: (index) => { subEditConfig.dataBits = index + 5 }
        }

        QGCLabel { text: qsTr("Stop Bits"); color: "#DDDDDD" }

        QGCComboBox {
            id:                     stopBitsCombo
            Layout.preferredWidth:  _secondColumnWidth
            model:                  [ "1", "2" ]

            background: Rectangle {
                color: "#1A1A1A"
                radius: 8
                border.color: stopBitsCombo.activeFocus ? "#4a2c6d" : "#333333"
                border.width: stopBitsCombo.activeFocus ? 2 : 1
                implicitHeight: 44
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }
            contentItem: Text {
                text: stopBitsCombo.currentText
                font: stopBitsCombo.font
                color: "white"
                verticalAlignment: Text.AlignVCenter
                leftPadding: 16
            }

            indicator: QGCColoredImage {
                anchors.rightMargin:    ScreenTools.comboBoxPadding
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                height:                 ScreenTools.defaultFontPixelWidth
                width:                  height
                source:                 "/qmlimages/arrow-down.png"
                color:                  "white"
            }

            popup: Popup {
                y: stopBitsCombo.height - 1
                width: stopBitsCombo.width
                implicitHeight: contentItem.implicitHeight
                padding: 1
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: stopBitsCombo.delegateModel
                    currentIndex: stopBitsCombo.highlightedIndex
                }
                background: Rectangle {
                    color: "#2A2A2A"
                    border.color: "#444444"
                    border.width: 1
                    radius: 4
                }
            }

            delegate: ItemDelegate {
                width: stopBitsCombo.width
                contentItem: Text {
                    text: modelData
                    color: "white"
                    font: stopBitsCombo.font
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                background: Rectangle {
                    color: parent.highlighted ? "#4a2c6d" : "#2A2A2A"
                }
            }
            currentIndex:           Math.max(Math.min(subEditConfig.stopBits - 1, 1), 0)
            onActivated: (index) => { subEditConfig.stopBits = index + 1 }
        }
    }
}
