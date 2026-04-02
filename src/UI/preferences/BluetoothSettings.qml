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
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: _rowSpacing

    function saveSettings() { }

    Component.onCompleted: subEditConfig.startScan()

    // Header section
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 30

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Refresh")
            color: !subEditConfig.scanning ? "black" : "gray"
            font.pixelSize: 13
            font.bold: true
            font.family: "Outfit"
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
    }

    // Content area
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 180
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
                color: "black"
                font.pixelSize: 13
                font.family: "Outfit"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            text: qsTr("No Bluetooth devices found\nClick 'Refresh' to scan again")
            color: "#666666"
            font.pixelSize: 13
            font.family: "Outfit"
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
                spacing: 0
                width: parent.width
                implicitHeight: contentHeight
                model: subEditConfig.nameList

                delegate: Item {
                    width: deviceList.width
                    height: 44

                    property bool isSelected: subEditConfig.devName === modelData

                    Rectangle {
                        anchors.fill: parent
                        color: isSelected ? "#301934" : (mouseArea.containsMouse ? "#F1F5F9" : "transparent")
                        
                        // Bottom Separator Line
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: "#DDE1EA"
                        }

                        // Selection Bar Indicator
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 3
                            color: isSelected ? "#FFFFFF" : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: modelData
                                Layout.fillWidth: true
                                color: isSelected ? "white" : "black"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "Outfit"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            // Selected indicator blip
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "#FFFFFF"
                                visible: isSelected
                                Layout.alignment: Qt.AlignVCenter
                                
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 14; height: 14; radius: 7
                                    color: "white"; opacity: 0.2
                                }
                            }
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
