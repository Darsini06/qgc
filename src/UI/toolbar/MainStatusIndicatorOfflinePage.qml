 /****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
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
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

ToolIndicatorPage {
    id:         control
    showExpand: true

    property var    linkConfigs:            QGroundControl.linkManager.linkConfigurations
    property bool   noLinks:                true
    property var    editingConfig:          null
    property var    autoConnectSettings:    QGroundControl.settingsManager.autoConnectSettings

    Component.onCompleted: {
        for (var i = 0; i < linkConfigs.count; i++) {
            var linkConfig = linkConfigs.get(i)
            if (!linkConfig.dynamic && !linkConfig.isAutoConnect) {
                noLinks = false
                break
            }
        }
    }

    contentComponent: Component {
        SettingsGroupLayout { 
            heading: qsTr("Select Link to Connect")

            QGCLabel {
                text:       qsTr("No Links Configured")
                visible:    noLinks
                color : "white"
            }
        
            Repeater {
                model: linkConfigs

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 55
                    color: object.link ? "#10B981" : (mouseArea.containsMouse ? "#334155" : "transparent")
                    border.width: 0
                    radius: 8
                    visible: !object.dynamic

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 10
                        
                        QGCLabel {
                            Layout.fillWidth: true
                            text: object.name
                            color: "white" // Always sharp white
                            font.bold: true
                            font.pixelSize: ScreenTools.defaultFontPointSize * 1.1
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        
                        Row {
                            spacing: 6
                            visible: object.link
                            Layout.alignment: Qt.AlignVCenter
                            
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            QGCLabel {
                                text: qsTr("Connected")
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: object.link ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !object.link
                        onClicked: {
                            QGroundControl.linkManager.createConnectedLink(object)
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }
        }
    }

    expandedComponent: Component {
        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            SettingsGroupLayout {
                LabelledButton {
                    label:      qsTr("Communication Links")
                    buttonText: qsTr("Configure")

                    onClicked: {
                        //mainWindow.showSettingsTool(qsTr("Comm Links"))
                        mainWindow.showToolSelectDialog1(4)
                        mainWindow.closeIndicatorDrawer()
                    }
                }
            }

            SettingsGroupLayout {
                heading:        qsTr("AutoConnect")
                visible:        autoConnectSettings.visible

                Repeater {
                    id: autoConnectRepeater

                    model: [
                        autoConnectSettings.autoConnectPixhawk,
                        autoConnectSettings.autoConnectSiKRadio,
                        autoConnectSettings.autoConnectLibrePilot,
                        autoConnectSettings.autoConnectUDP,
                        autoConnectSettings.autoConnectZeroConf,
                        autoConnectSettings.autoConnectRTKGPS,
                    ]

                    property var names: [ qsTr("Pixhawk"), qsTr("SiK Radio"), qsTr("LibrePilot"), qsTr("UDP"), qsTr("Zero-Conf"), qsTr("RTK") ]

                    FactCheckBoxSlider {
                        Layout.fillWidth:   true
                        text:               autoConnectRepeater.names[index]
                        fact:               modelData
                        visible:            modelData.visible
                    }
                }
            }
        }
    }
}
