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
        ColumnLayout {
            spacing: 8
            Layout.preferredWidth: 280
            
            // -- PROFESSIONAL ELITE HEADER --
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                
                QGCLabel {
                    anchors.centerIn:       parent
                    text:                   qsTr("Select Link to Connect")
                    font.bold:              true
                    font.pointSize:         11
                    color:                  "#000000"
                    font.family:            "Outfit"
                }

                // Separator Line
                Rectangle {
                    anchors.bottom:         parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:                  parent.width * 0.95
                    height:                 1
                    color:                  "#DDE1EA"
                    opacity:                1.0
                }

                // Refined "+" Button
                Rectangle {
                    anchors.right:          parent.right
                    anchors.rightMargin:    5
                    anchors.verticalCenter: parent.verticalCenter
                    width:                  28
                    height:                 28
                    radius:                 width / 2
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: ma.containsMouse ? "#FFFFFF" : "#F8F9FA" }
                        GradientStop { position: 1.0; color: ma.containsMouse ? "#F1F5F9" : "#E2E8F0" }
                    }
                    
                    border.color:           ma.containsMouse ? "#301934" : "#DDE1EA"
                    border.width:           1
                    
                    QGCLabel {
                        anchors.centerIn:   parent
                        text:               "+"
                        font.bold:          true
                        font.pointSize:     14
                        color:              ma.containsMouse ? "#301934" : "black"
                        anchors.verticalCenterOffset: -1 // Visual alignment
                    }
                    
                    MouseArea {
                        id:                 ma
                        anchors.fill:       parent
                        hoverEnabled:       true
                        onClicked: {
                            mainWindow.showToolSelectDialog1(4)
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }
            }

            // -- PROFESSIONAL TABLE ROWS --
            Column {
                Layout.fillWidth: true
                spacing: 4
                
                QGCLabel {
                    text:       qsTr("No Links Configured")
                    visible:    noLinks
                    color:      "#999999"
                    font.family: "Outfit"
                    width:      parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
            
                Repeater {
                    model: linkConfigs

                    delegate: Rectangle {
                        width:  280
                        height: 42
                        radius: 6
                        border.width:   1
                        border.color:   object.link ? "#301934" : (mouseArea.containsMouse ? "#301934" : "#E2E8F0")
                        
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: object.link ? "#301934" : (mouseArea.containsMouse ? "#F1F5F9" : "#FFFFFF") }
                            GradientStop { position: 1.0; color: object.link ? "#301d4a" : (mouseArea.containsMouse ? "#E2E8F0" : "#F8F9FA") }
                        }
                        
                        visible: !object.dynamic

                        // Left Indicator Bar
                        Rectangle {
                            anchors.left:   parent.left
                            anchors.top:    parent.top
                            anchors.bottom: parent.bottom
                            width:          4
                            radius:         2
                            color:          object.link ? "#FFFFFF" : "transparent"
                            anchors.margins: 4
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12
                            
                            QGCLabel {
                                Layout.fillWidth: true
                                text:           object.name
                                color:          object.link ? "white" : "black"
                                font.bold:      true
                                font.pointSize: 10
                                font.family:    "Outfit"
                                elide:          Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            // Connected Status with White Glow
                            Row {
                                spacing: 8
                                visible: object.link
                                Layout.alignment: Qt.AlignVCenter
                                
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "white" 
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    // Subtle Glow
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 14; height: 14; radius: 7
                                        color: "white"; opacity: 0.2
                                    }
                                }
                                
                                QGCLabel {
                                    text:           qsTr("Connected")
                                    color:          "white"
                                    font.pointSize: 9
                                    font.bold:      true
                                    font.family:    "Outfit"
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
    }

    expandedComponent: Component {
        ColumnLayout {
            spacing: 15
            Layout.preferredWidth: 280

            // Configuration Options (Dark Section)
            Rectangle {
                Layout.fillWidth: true
                height:         120
                color:          "#F8F9FA"
                radius:         10
                border.color:   "#DDE1EA"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    QGCLabel {
                        text: qsTr("Auto-Connect Configuration")
                        color: "black"
                        font.bold: true
                        font.family: "Outfit"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        QGCLabel { text: qsTr("Pixhawk USB"); color: "#1E1E2E"; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: autoConnectSettings.autoConnectPixhawk }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        QGCLabel { text: qsTr("UDP Network"); color: "#1E1E2E"; Layout.fillWidth: true }
                        FactCheckBoxSlider { fact: autoConnectSettings.autoConnectUDP }
                    }
                }
            }
        }
    }
}
