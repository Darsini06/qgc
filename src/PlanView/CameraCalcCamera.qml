import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

// Camera calculator "Camera" section for mission item editors
ColumnLayout {
    spacing: _margin

    property var    cameraCalc

    property real   _margin:            ScreenTools.defaultFontPixelWidth / 2
    property real   _fieldWidth:        ScreenTools.defaultFontPixelWidth * 10.5
    property var    _vehicle:           QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property var    _vehicleCameraList: _vehicle ? _vehicle.staticCameraList : []

    Component.onCompleted: {
        cameraBrandCombo.selectCurrentBrand()
        cameraModelCombo.selectCurrentModel()
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ColumnLayout {
        Layout.fillWidth:   true
        spacing:            _margin

        QGCComboBox {
            id:                 cameraBrandCombo
            Layout.fillWidth:   true
            model:              cameraCalc.cameraBrandList
            onModelChanged:     selectCurrentBrand()
            onActivated: (index) => { cameraCalc.cameraBrand = currentText }

            contentItem: Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: ScreenTools.comboBoxPadding
                text: cameraBrandCombo.currentText
                color: "#ffffff"
                font.pointSize: ScreenTools.defaultFontPointSize
                verticalAlignment: Text.AlignVCenter
            }
            
            delegate: ItemDelegate {
                width: cameraBrandCombo.width
                contentItem: Text {
                    text: modelData
                    color: "black"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: cameraBrandCombo.highlightedIndex === index ? "#cccccc" : "#ffffff"
                }
            }
            
            background: Rectangle {
                radius: 10
                color: "#000000"
                border.color: "#3d3a50"
                border.width: 1
            }

            Connections {
                target:                 cameraCalc
                onCameraBrandChanged:   cameraBrandCombo.selectCurrentBrand()
            }

            function selectCurrentBrand() {
                currentIndex = cameraBrandCombo.find(cameraCalc.cameraBrand)
            }
        }

        QGCComboBox {
            id:                 cameraModelCombo
            Layout.fillWidth:   true
            model:              cameraCalc.cameraModelList
            visible:            !cameraCalc.isManualCamera && !cameraCalc.isCustomCamera
            onModelChanged:     selectCurrentModel()
            onActivated: (index) => { cameraCalc.cameraModel = currentText }

            contentItem: Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: ScreenTools.comboBoxPadding
                text: cameraModelCombo.currentText
                color: "#ffffff"
                font.pointSize: ScreenTools.defaultFontPointSize
                verticalAlignment: Text.AlignVCenter
            }
            
            delegate: ItemDelegate {
                width: cameraModelCombo.width
                contentItem: Text {
                    text: modelData
                    color: "black"
                    font.pointSize: ScreenTools.defaultFontPointSize
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: cameraModelCombo.highlightedIndex === index ? "#cccccc" : "#ffffff"
                }
            }
            
            background: Rectangle {
                radius: 10
                color: "#301934"
                border.color: "#3d3a50"
                border.width: 1
            }

            Connections {
                target:                 cameraCalc
                onCameraModelChanged:   cameraModelCombo.selectCurrentModel()
            }

            function selectCurrentModel() {
                currentIndex = cameraModelCombo.find(cameraCalc.cameraModel)
            }
        }

        // Camera based grid ui
        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            _margin
            visible:            !cameraCalc.isManualCamera

            RowLayout {
                Layout.alignment:   Qt.AlignHCenter
                spacing:            _margin
                visible:            !cameraCalc.fixedOrientation.value

                QGCRadioButton {
                    width:          _editFieldWidth
                    text:           "Landscape"
                    textColor:      "#ffffff"
                    checked:        !!cameraCalc.landscape.value
                    onClicked:      cameraCalc.landscape.value = 1
                }

                QGCRadioButton {
                    id:             cameraOrientationPortrait
                    text:           "Portrait"
                    textColor:      "#ffffff"
                    checked:        !cameraCalc.landscape.value
                    onClicked:      cameraCalc.landscape.value = 0
                }
            }

            // Custom camera specs
            ColumnLayout {
                id:                 custCameraCol
                Layout.fillWidth:   true
                spacing:            _margin
                enabled:            cameraCalc.isCustomCamera

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            _margin

                    Item { Layout.fillWidth: true }
                    QGCLabel {
                        Layout.preferredWidth:  _root._fieldWidth
                        text:                   qsTr("Width")
                        color:                  "#ffffff"
                    }
                    QGCLabel {
                        Layout.preferredWidth:  _root._fieldWidth
                        text:                   qsTr("Height")
                        color:                  "#ffffff"
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            _margin

                    QGCLabel { text: qsTr("Sensor"); Layout.fillWidth: true; color: "#ffffff" }
                    FactTextField {
                        Layout.preferredWidth:  _root._fieldWidth
                        fact:                   cameraCalc.sensorWidth
                        color:                  "#ffffff"
                        background: Rectangle { radius: 10; color: "#27253b"; border.color: "#3d3a50"; border.width: 1 }
                    }
                    FactTextField {
                        Layout.preferredWidth:  _root._fieldWidth
                        fact:                   cameraCalc.sensorHeight
                        color:                  "#ffffff"
                        background: Rectangle { radius: 10; color: "#27253b"; border.color: "#3d3a50"; border.width: 1 }
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            _margin

                    QGCLabel { text: qsTr("Image"); Layout.fillWidth: true; color: "#ffffff" }
                    FactTextField {
                        Layout.preferredWidth:  _root._fieldWidth
                        fact:                   cameraCalc.imageWidth
                        color:                  "#ffffff"
                        background: Rectangle { radius: 10; color: "#27253b"; border.color: "#3d3a50"; border.width: 1 }
                    }
                    FactTextField {
                        Layout.preferredWidth:  _root._fieldWidth
                        fact:                   cameraCalc.imageHeight
                        color:                  "#ffffff"
                        background: Rectangle { radius: 10; color: "#27253b"; border.color: "#3d3a50"; border.width: 1 }
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            _margin
                    QGCLabel {
                        text:                   qsTr("Focal length")
                        Layout.fillWidth:       true
                        color:                  "#ffffff"
                    }
                    FactTextField {
                        Layout.preferredWidth:  _root._fieldWidth
                        fact:                   cameraCalc.focalLength
                        color:                  "#ffffff"
                        background: Rectangle { radius: 10; color: "#27253b"; border.color: "#3d3a50"; border.width: 1 }
                    }
                }
            }
        }
    }
}
