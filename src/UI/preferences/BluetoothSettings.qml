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

    function saveSettings() { }

    Component.onCompleted: subEditConfig.startScan()

    // Header section
    RowLayout {
        Layout.fillWidth: true

        Item { Layout.fillWidth: true } // spacer

        // Right-aligned controls
        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignRight

            Text {
                text: qsTr("Refresh")
                color: !subEditConfig.scanning ? "blue" : "gray"
                font.pixelSize: 12
                font.underline: refreshMouseArea.containsMouse && !subEditConfig.scanning

                MouseArea {
                    id: refreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !subEditConfig.scanning
                    onClicked: subEditConfig.startScan()
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }

            Text {
                text: qsTr("Stop")
                color: subEditConfig.scanning ? "red" : "gray"
                font.pixelSize: 12
                font.underline: stopMouseArea.containsMouse && subEditConfig.scanning

                MouseArea {
                    id: stopMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: subEditConfig.scanning
                    onClicked: subEditConfig.stopScan()
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    // Content area
    Item {
        Layout.alignment: Qt.AlignHCenter

        property int minWidth: 220
        Layout.preferredWidth: minWidth  // Use fixed minWidth instead of dynamic calculation
        Layout.preferredHeight: 150
        clip: true

        // Loading state
        Column {
            anchors.centerIn: parent
            spacing: 10
            visible: subEditConfig.scanning && subEditConfig.nameList.length === 0

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
            }

            Text {
                text: qsTr("Scanning for devices...")
                color: "gray"
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            text: qsTr("No Bluetooth devices found\nClick 'Refresh' to scan again")
            color: "gray"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            visible: !subEditConfig.scanning && subEditConfig.nameList.length === 0
        }

        // Devices list
        ScrollView {
            visible: subEditConfig.nameList.length > 0
            anchors.fill: parent
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true
            contentWidth: availableWidth

            ListView {
                id: deviceList
                spacing: 8
                width: parent.width
                implicitHeight: contentHeight

                model: subEditConfig.nameList

                delegate: Item {
                    width: deviceList.width
                    height: 40  // Fixed height for buttons

                    property bool isSelected: subEditConfig.devName === modelData

                    Rectangle {
                        // Visual representation of button
                        anchors.centerIn: parent
                        width: Math.min(deviceList.width - 40, textItem.implicitWidth + 20)
                        height: 40
                        radius: 15
                        color: {
                            if (isSelected) {
                                return "#2196F3"  // Blue background for selected item
                            } else if (mouseArea.containsPress) {
                                return "#d0d0d0"  // Pressed state
                            } else if (mouseArea.containsMouse) {
                                return "#e8e8e8"  // Hover state
                            } else {
                                return "#f0f0f0"  // Default state
                            }
                        }
                        border.color: isSelected ? "#1976D2" : "#a0a0a0"
                        border.width: isSelected ? 2 : 1

                        Text {
                            id: textItem
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            width: parent.width - 10
                            color: isSelected ? "white" : "black"  // White text for selected item
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData !== "") {
                                    subEditConfig.devName = modelData
                                    console.log("Bluetooth Device name: ", modelData)
                                    QGroundControl.saveGlobalSetting("bluetooth_name", modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
