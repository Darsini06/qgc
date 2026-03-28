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
import QtQuick.Dialogs
import QtQuick.Effects

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Controllers

QGCPopupDialog {
    id:         root
    title:      qsTr("Edit Vertex Position")
    buttons:    0 // We will provide custom buttons for special alignment

    property alias coordinate:                  controller.coordinate
    property bool  showSetPositionFromVehicle:  true

    // Mission Theme Palette
    property color app_color:       "#4a2c6d"
    property color secondary_color: "#7c4dff"
    property color accent_color:    "#4a2c6d"
    property color cardBgColor:     Qt.rgba(20/255, 20/255, 30/255, 0.85)
    property color borderColor:     Qt.rgba(255, 255, 255, 0.15)

    property real _margin:          ScreenTools.defaultFontPixelWidth
    property real _textFieldWidth:  ScreenTools.defaultFontPixelWidth * 22
    property bool _showGeographic:  coordinateSystemCombo.currentIndex === 0
    property bool _showUTM:         coordinateSystemCombo.currentIndex === 1
    property bool _showMGRS:        coordinateSystemCombo.currentIndex === 2
    property bool _showVehicle:     coordinateSystemCombo.currentIndex === 3

    EditPositionDialogController {
        id: controller
        Component.onCompleted: initValues()
    }

    ColumnLayout {
        id:         mainColumn
        width:      parent.width
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing:    _margin * 2

        // Coordinate System Selection - Left Aligned to match sketch
        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            dp(1)

            Label {
                text:               qsTr("Coordinate system")
                color:              "white"
                font.pointSize:     ScreenTools.smallFontPointSize
                font.bold:          true
                Layout.alignment:   Qt.AlignLeft
            }

            QGCComboBox {
                id:                 coordinateSystemCombo
                Layout.preferredWidth: dp(32)
                model:              showSetPositionFromVehicle && globals.activeVehicle ? 
                                        [ qsTr("Geographic"), qsTr("Universal Transverse Mercator"), qsTr("Military Grid Reference"), qsTr("Vehicle Position") ] :
                                        [ qsTr("Geographic"), qsTr("Universal Transverse Mercator"), qsTr("Military Grid Reference") ]
                
                font.family:        "Outfit"
                font.bold:          true

                contentItem: Text {
                    leftPadding:    12
                    text:           parent.currentText
                    color:          "white"
                    verticalAlignment: Text.AlignVCenter
                    font.family:    "Outfit"
                    font.bold:      true
                }
                
                background: Rectangle {
                    implicitHeight: dp(6.5)
                    color:          Qt.rgba(255, 255, 255, 0.08)
                    radius:         12
                    border.color:   coordinateSystemCombo.activeFocus ? secondary_color : borderColor
                    border.width:   1
                }

                // Customizing the Dropdown List
                delegate: ItemDelegate {
                    width:  coordinateSystemCombo.width
                    height: dp(6)
                    
                    contentItem: Text {
                        text:                   modelData
                        color:                  "white"
                        font.family:            "Outfit"
                        font.pointSize:         ScreenTools.defaultFontPointSize
                        verticalAlignment:      Text.AlignVCenter
                        leftPadding:            12
                    }

                    background: Rectangle {
                        color:  coordinateSystemCombo.currentIndex === index ? secondary_color : (hovered ? Qt.rgba(255,255,255,0.05) : "transparent")
                        radius: 8
                    }
                }

                popup: Popup {
                    y:              coordinateSystemCombo.height + 4
                    width:          coordinateSystemCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding:        4

                    contentItem: ListView {
                        clip:           true
                        implicitHeight: contentHeight
                        model:          coordinateSystemCombo.delegateModel
                        currentIndex:   coordinateSystemCombo.highlightedIndex
                    }

                    background: Rectangle {
                        color:          "#1a1b2e" // Deep dark charcoal
                        border.color:   borderColor
                        border.width:   1
                        radius:         12
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0,0,0,0.5)
                            shadowBlur: 0.8
                        }
                    }
                }
            }
        }

        // Geographic Section - Two columns in a row as per sketch
        RowLayout {
            Layout.fillWidth:   true
            spacing:            _margin * 2
            visible:            _showGeographic

            // Latitude
            ColumnLayout {
                Layout.fillWidth: true
                spacing: dp(1)
                Label {
                    text: qsTr("latitude")
                    color: "white"
                    font.pointSize: ScreenTools.smallFontPointSize * 0.9
                    font.bold: true
                }
                FactTextField {
                    fact: controller.latitude
                    Layout.fillWidth: true
                    textColor: "white"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Outfit"
                    background: Rectangle {
                        implicitHeight: dp(6)
                        color: Qt.rgba(255, 255, 255, 0.08)
                        radius: 8
                        border.color: parent.activeFocus ? secondary_color : borderColor
                        border.width: parent.activeFocus ? 1.5 : 1
                    }
                }
            }

            // Longitude
            ColumnLayout {
                Layout.fillWidth: true
                spacing: dp(1)
                Label {
                    text: qsTr("longitude")
                    color: "white"
                    font.pointSize: ScreenTools.smallFontPointSize * 0.9
                    font.bold: true
                }
                FactTextField {
                    fact: controller.longitude
                    Layout.fillWidth: true
                    textColor: "white"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Outfit"
                    background: Rectangle {
                        implicitHeight: dp(6)
                        color: Qt.rgba(255, 255, 255, 0.08)
                        radius: 8
                        border.color: parent.activeFocus ? secondary_color : borderColor
                        border.width: parent.activeFocus ? 1.5 : 1
                    }
                }
            }
        }

        // UTM Section
        GridLayout {
            Layout.fillWidth:   true
            columns:            2
            rowSpacing:         _margin
            columnSpacing:      _margin * 2
            visible:            _showUTM

            ColumnLayout {
                spacing: dp(1)
                Label { text: qsTr("Zone"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; font.family: "Outfit" }
                FactTextField {
                    fact: controller.zone
                    Layout.maximumWidth:  dp(16)
                    Layout.fillWidth:     true
                    textColor: "white"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Outfit"
                    background: Rectangle { implicitHeight: dp(6); color: Qt.rgba(255,255,255,0.08); radius: 8; border.color: parent.activeFocus ? secondary_color : borderColor; border.width: 1 }
                }
            }
            ColumnLayout {
                spacing: dp(1)
                Label { text: qsTr("Hemisphere"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; font.family: "Outfit" }
                FactComboBox {
                    id:                 hemisphereCombo
                    fact:               controller.hemisphere
                    Layout.maximumWidth: dp(16)
                    Layout.fillWidth:   true
                    indexModel:         false
                    font.family:        "Outfit"
                    font.bold:          true

                    contentItem: Text {
                        leftPadding:    12
                        text:           hemisphereCombo.currentText
                        color:          "white"
                        verticalAlignment: Text.AlignVCenter
                        font.family:    "Outfit"
                        font.bold:      true
                    }
                    
                    background: Rectangle {
                        implicitHeight: dp(6)
                        color:          Qt.rgba(255, 255, 255, 0.08)
                        radius:         8
                        border.color:   hemisphereCombo.activeFocus ? secondary_color : borderColor
                        border.width:   1
                    }

                    delegate: ItemDelegate {
                        width:  hemisphereCombo.width
                        height: dp(6)
                        contentItem: Text {
                            text:                   modelData
                            color:                  "white"
                            font.family:            "Outfit"
                            verticalAlignment:      Text.AlignVCenter
                            leftPadding:            12
                        }
                        background: Rectangle {
                            color:  hemisphereCombo.currentIndex === index ? secondary_color : (hovered ? Qt.rgba(255,255,255,0.05) : "transparent")
                            radius: 8
                        }
                    }

                    popup: Popup {
                        y:              hemisphereCombo.height + 4
                        width:          hemisphereCombo.width
                        implicitHeight: contentItem.implicitHeight
                        padding:        4
                        contentItem: ListView {
                            clip:           true
                            implicitHeight: contentHeight
                            model:          hemisphereCombo.delegateModel
                        }
                        background: Rectangle {
                            color:          "#1a1b2e"
                            border.color:   borderColor
                            border.width:   1
                            radius:         12
                        }
                    }
                }
            }
            ColumnLayout {
                spacing: dp(1)
                Label { text: qsTr("Easting"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; font.family: "Outfit" }
                FactTextField {
                    fact: controller.easting
                    Layout.maximumWidth: dp(18)
                    Layout.fillWidth: true
                    textColor: "white"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Outfit"
                    background: Rectangle { implicitHeight: dp(6); color: Qt.rgba(255,255,255,0.08); radius: 8; border.color: parent.activeFocus ? secondary_color : borderColor; border.width: 1 }
                }
            }
            ColumnLayout {
                spacing: dp(1)
                Label { text: qsTr("Northing"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; font.family: "Outfit" }
                FactTextField {
                    fact: controller.northing
                    Layout.maximumWidth: dp(18)
                    Layout.fillWidth: true
                    textColor: "white"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Outfit"
                    background: Rectangle { implicitHeight: dp(6); color: Qt.rgba(255,255,255,0.08); radius: 8; border.color: parent.activeFocus ? secondary_color : borderColor; border.width: 1 }
                }
            }
        }

        // MGRS Section
        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            dp(1)
            visible:            _showMGRS

            Label { text: qsTr("MGRS"); color: "white"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; font.family: "Outfit" }
            FactTextField {
                fact: controller.mgrs
                Layout.fillWidth: true
                textColor: "white"
                horizontalAlignment: Text.AlignHCenter
                font.family: "Outfit"
                background: Rectangle { implicitHeight: dp(6); color: Qt.rgba(255,255,255,0.08); radius: 8; border.color: parent.activeFocus ? secondary_color : borderColor; border.width: 1 }
            }
        }

        // Vehicle Position Section
        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            dp(2)
            visible:            _showVehicle

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("Set the position to the current location of the active vehicle.")
                color:              "white"
                wrapMode:           Text.WordWrap
                font.family:        "Outfit"
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                height: dp(12)
                color: Qt.rgba(255, 255, 255, 0.05)
                radius: 12
                border.color: borderColor
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: dp(1)
                    QGCLabel { 
                        text: qsTr("Vehicle Coordinate:") 
                        color: secondary_color
                        font.bold: true
                        font.family: "Outfit"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QGCLabel { 
                        text: globals.activeVehicle ? globals.activeVehicle.coordinate.toString() : qsTr("No active vehicle")
                        color: "white"
                        font.family: "Outfit"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // Action Buttons Row - Perfectly Symmetric Horizontal 50/50 Split
        // Action Buttons - Centered Bottom Group
        Row {
            Layout.alignment:   Qt.AlignHCenter
            Layout.topMargin:   _margin * 2
            spacing:            dp(2)

            // Close Button
            Rectangle {
                width:  dp(22)
                height: dp(7)
                radius: 8
                color:  closeMA.pressed ? "#1a1b2e" : (closeMA.containsMouse ? "#2d2e4a" : "transparent")
                border.color: Qt.rgba(255, 255, 255, 0.15)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text:  qsTr("close")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.family: "Outfit"
                    textFormat: Text.PlainText
                }

                MouseArea {
                    id: closeMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            // Update Position Button
            Rectangle {
                width:  dp(28)
                height: dp(7)
                radius: 8
                color:  updateMA.pressed ? Qt.darker("#4a2c6d", 1.2) : (updateMA.containsMouse ? Qt.lighter("#4a2c6d", 1.1) : "#4a2c6d")
                opacity: globals.validationError ? 0.5 : 1.0

                Text {
                    anchors.centerIn: parent
                    text:  qsTr("update position")
                    color: "white"
                    font.bold: true
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.family: "Outfit"
                    textFormat: Text.PlainText
                }

                MouseArea {
                    id: updateMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: !globals.validationError
                    onClicked: {
                        if (_showGeographic)      controller.setFromGeo()
                        else if (_showUTM)        controller.setFromUTM()
                        else if (_showMGRS)       controller.setFromMGRS()
                        else if (_showVehicle)    controller.setFromVehicle()
                        root.close()
                    }
                }
            }
        }
    }

    // Helper function for consistent spacing
    function dp(val) { return val * ScreenTools.defaultFontPixelWidth * 0.8; }
}
