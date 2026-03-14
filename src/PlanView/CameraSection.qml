import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

// Camera section for mission item editors
Column {
    anchors.left:   parent.left
    anchors.right:  parent.right
    spacing:        _margin

    property alias buttonGroup:  cameraSectionHeader.buttonGroup
    property alias showSpacer:      cameraSectionHeader.showSpacer
    property alias checked:         cameraSectionHeader.checked

    property var    _camera:        missionItem.cameraSection
    property real   _fieldWidth:    ScreenTools.defaultFontPixelWidth * 16
    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2

    SectionHeader {
        id:             cameraSectionHeader
        anchors.left:   parent.left
        anchors.right:  parent.right
        text:           qsTr("Camera")
        checked:        true
        color:          "#e8e4f8"
    }

    Column {
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        _margin
        visible:        cameraSectionHeader.checked

        FactComboBox {
            id:             cameraActionCombo
            anchors.left:   parent.left
            anchors.right:  parent.right
            fact:           _camera.cameraAction
            indexModel:     false
            
            contentItem: Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: ScreenTools.comboBoxPadding
                text: cameraActionCombo.currentText
                color: "#ffffff"
                font.pointSize: ScreenTools.defaultFontPointSize
                verticalAlignment: Text.AlignVCenter
            }
            
            delegate: ItemDelegate {
                width: cameraActionCombo.width
                contentItem: Text {
                    text: modelData
                    color: "black"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: cameraActionCombo.highlightedIndex === index ? "#cccccc" : "#ffffff"
                }
            }
            
            background: Rectangle {
                radius: 10
                color: "#4a2c6d"
                border.color: "#3d3a50"
                border.width: 1
            }
        }

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth
            visible:        _camera.cameraAction.rawValue === 1

            QGCLabel {
                text:               qsTr("Time")
                color:              "#c8c4dc"
                Layout.fillWidth:   true
            }
            FactTextField {
                fact:                   _camera.cameraPhotoIntervalTime
                Layout.preferredWidth:  _fieldWidth
                Layout.preferredHeight: 32
                color:                  "#ffffff"
                background: Rectangle {
                    radius: 10
                    color: "#27253b"
                    border.color: "#3d3a50"
                    border.width: 1
                }
            }
        }

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth
            visible:        _camera.cameraAction.rawValue === 2

            QGCLabel {
                text:               qsTr("Distance")
                color:              "#c8c4dc"
                Layout.fillWidth:   true
            }
            FactTextField {
                fact:                   _camera.cameraPhotoIntervalDistance
                Layout.preferredWidth:  _fieldWidth
                Layout.preferredHeight: 32
                color:                  "#ffffff"
                background: Rectangle {
                    radius: 10
                    color: "#27253b"
                    border.color: "#3d3a50"
                    border.width: 1
                }
            }
        }

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.defaultFontPixelWidth
            visible:        _camera.cameraModeSupported

            QGCCheckBox {
                id:                 modeCheckBox
                text:               qsTr("Mode")
                textColor:          "#c8c4dc"
                checked:            _camera.specifyCameraMode
                onClicked:          _camera.specifyCameraMode = checked
            }
            FactComboBox {
                id:                 cameraModeCombo
                fact:               _camera.cameraMode
                indexModel:         false
                enabled:            modeCheckBox.checked
                Layout.fillWidth:   true
                Layout.preferredHeight: 32
                
                contentItem: Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: ScreenTools.comboBoxPadding
                    text: cameraModeCombo.currentText
                    color: "#ffffff"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    verticalAlignment: Text.AlignVCenter
                }
                
                delegate: ItemDelegate {
                    width: cameraModeCombo.width
                    contentItem: Text {
                        text: modelData
                        color: "black"
                        font.pointSize: ScreenTools.defaultFontPointSize
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: cameraModeCombo.highlightedIndex === index ? "#cccccc" : "#ffffff"
                    }
                }

                background: Rectangle {
                    radius: 10
                    color: "#4a2c6d"
                    border.color: "#3d3a50"
                    border.width: 1
                }
            }
        }

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth : ScreenTools.defaultFontPixelWidth * 2

            // Gimbal Checkbox Column
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight * 0.2
                Layout.alignment: Qt.AlignVCenter
                QGCLabel { 
                    text: qsTr("Gimbal")
                    color: "#c8c4dc"
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                QGCCheckBox {
                    id:                 gimbalCheckBox
                    checked:            _camera.specifyGimbal
                    onClicked:          _camera.specifyGimbal = checked
                    textColor:          "#c8c4dc"
                    Layout.alignment:   Qt.AlignHCenter
                }
            }

            // Pitch Column
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight * 0.2
                Layout.fillWidth: true
                QGCLabel { 
                    text:               qsTr("Pitch")
                    color:              "#c8c4dc" 
                    Layout.alignment:   Qt.AlignHCenter
                }
                FactTextField {
                    fact:                   _camera.gimbalPitch
                    Layout.fillWidth:       true
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * (ScreenTools.isMobile ? 8 : 12)
                    Layout.preferredHeight: ScreenTools.isMobile ? 28 : 32
                    enabled:                gimbalCheckBox.checked
                    horizontalAlignment:    TextInput.AlignHCenter
                    font.pixelSize:         ScreenTools.defaultFontPixelHeight * 0.85
                    color:                  "#ffffff"
                    background: Rectangle {
                        radius:         10
                        color:          "#27253b"
                        border.color:   "#3d3a50"
                        border.width:   1
                    }
                }
            }

            // Yaw Column
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight * 0.2
                Layout.fillWidth: true
                QGCLabel { 
                    text:               qsTr("Yaw")
                    color:              "#c8c4dc" 
                    Layout.alignment:   Qt.AlignHCenter
                }
                FactTextField {
                    fact:                   _camera.gimbalYaw
                    Layout.fillWidth:       true
                    Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * (ScreenTools.isMobile ? 8 : 12)
                    Layout.preferredHeight: ScreenTools.isMobile ? 28 : 32
                    enabled:                gimbalCheckBox.checked
                    horizontalAlignment:    TextInput.AlignHCenter
                    font.pixelSize:         ScreenTools.defaultFontPixelHeight * 0.85
                    color:                  "#ffffff"
                    background: Rectangle {
                        radius:         10
                        color:          "#27253b"
                        border.color:   "#3d3a50"
                        border.width:   1
                    }
                }
            }
        }
    }
}
