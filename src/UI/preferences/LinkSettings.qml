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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette

SettingsPage {
    property var _linkManager:          QGroundControl.linkManager
    property var _autoConnectSettings:  QGroundControl.settingsManager.autoConnectSettings

    SettingsGroupLayout {
        heading:        qsTr("AutoConnect")
        visible:        _autoConnectSettings.visible

        Repeater {
            id: autoConnectRepeater

            model: [
                _autoConnectSettings.autoConnectPixhawk,
                _autoConnectSettings.autoConnectSiKRadio,
                _autoConnectSettings.autoConnectLibrePilot,
                _autoConnectSettings.autoConnectUDP,
                _autoConnectSettings.autoConnectZeroConf,
                _autoConnectSettings.autoConnectRTKGPS,
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

    SettingsGroupLayout {
        heading: qsTr("Links")

        Repeater {
            model: _linkManager.linkConfigurations
            
            RowLayout {
                Layout.fillWidth:   true
                visible:            !object.dynamic

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               object.name
                }
                QGCColoredImage {
                    height:                 ScreenTools.minTouchPixels
                    width:                  height
                    sourceSize.height:      height
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    smooth:                 true
                    color:                  qgcPalEdit.text
                    source:                 "/res/pencil.svg"
                    enabled:                !object.link

                    QGCPalette {
                        id: qgcPalEdit
                        colorGroupEnabled: parent.enabled
                    }

                    QGCMouseArea {
                        fillItem: parent
                        onClicked: {
                            var editingConfig = _linkManager.startConfigurationEditing(object)
                            linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: object }).open()
                        }
                    }
                }
                QGCColoredImage {
                    height:                 ScreenTools.minTouchPixels
                    width:                  height
                    sourceSize.height:      height
                    fillMode:               Image.PreserveAspectFit
                    mipmap:                 true
                    smooth:                 true
                    color:                  qgcPalDelete.text
                    source:                 "/res/TrashDelete.svg"

                    QGCPalette {
                        id: qgcPalDelete
                        colorGroupEnabled: parent.enabled
                    }

                    QGCMouseArea {
                        fillItem:   parent
                        onClicked:  mainWindow.showMessageDialog(
                                        qsTr("Delete Link"),
                                        qsTr("Are you sure you want to delete '%1'?").arg(object.name),
                                        Dialog.Ok | Dialog.Cancel,
                                        function () {
                                            _linkManager.removeConfiguration(object)
                                        })
                    }
                }
                QGCButton {
                    text:       object.link ? qsTr("Disconnect") : qsTr("Connect")
                    onClicked: {
                        if (object.link) {
                            object.link.disconnect()
                            object.linkChanged()
                        } else {
                            _linkManager.createConnectedLink(object)

                        }
                    }
                }
            }
        }

        LabelledButton {
            label:      qsTr("Add New Link")
            buttonText: qsTr("Add")

            onClicked: {
                typeSelectionDialogComponent.createObject(mainWindow).open()
            }
        }
    }

    // First Dialog – Type Selection Only
    Component {
        id: typeSelectionDialogComponent

        QGCPopupDialog {
            id: typeDialog
            title: qsTr("Select Link Type")
            buttons: false
            closeOnClickOutside: true

            property int selectedType: -1

            ColumnLayout {
                spacing: 15                     // we’ll control spacing ourselves
                Layout.fillWidth: true

                Repeater {
                    model: _linkManager.linkTypeStrings
                    delegate: RowLayout {
                        Layout.fillWidth: true        // row spans full width
                        spacing: 20

                        Rectangle {
                            width: 25
                            height: 25
                            radius: width/2
                            color: "#7F56D9"

                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 14
                                color: "white"
                                text: index + 1
                            }
                        }

                        //Item { Layout.fillWidth: true }

                        // clickable text
                        Text {
                            text: modelData
                            //Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 16
                            color: "black"   // adjust to your theme

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    typeDialog.selectedType = index
                                    typeDialog.close()
                                    var editingConfig = _linkManager.createConfiguration(index, "")
                                    linkConfigDialogComponent.createObject(mainWindow, {
                                                                               editingConfig: editingConfig,
                                                                               originalConfig: null,
                                                                               selectedType: index
                                                                           }).open()
                                }
                                // hoverEnabled: true
                                // onEntered: parent.color = "blue"   // optional hover effect
                                // onExited:  parent.color = "green"
                            }
                        }

                         Item { Layout.fillWidth: true }

                        // // full-width divider
                        // Rectangle {
                        //     Layout.fillWidth: true
                        //     height: 1
                        //     color: "#aaaaaa"  // divider colour
                        // }
                    }
                }
            }
        }
    }

    // Second Dialog - Configuration (without type dropdown)
    Component {
        id: linkConfigDialogComponent

        QGCPopupDialog {
            title:          selectedType === 3 ? "Bluetooth Devices"
                                               : originalConfig ? qsTr("Edit Link")
                                               : qsTr("Add New Link")
            buttons:        Dialog.Save | Dialog.Cancel
            acceptAllowed:  nameField.text !== ""

            property var originalConfig
            property var editingConfig
            property int selectedType

            onAccepted: {
                linkSettingsLoader.item.saveSettings()
                editingConfig.devName = nameField.text
                editingConfig.name    = editingConfig.devName

                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                    _linkManager.createConnectedLink(editingConfig)
                }
            }

            onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

            // ---------- MAIN LAYOUT ----------
            ColumnLayout {
                id: mainColumn
                spacing: ScreenTools.defaultFontPixelHeight / 2
                Layout.fillWidth: true


                // ---- Name row (not shown for Bluetooth) ----
                RowLayout {
                    Layout.fillWidth: true    // row stretches full width
                    spacing: ScreenTools.defaultFontPixelWidth
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"

                    QGCLabel { text: qsTr("Name") }

                    QGCTextField {
                        id:               nameField
                        Layout.fillWidth: true   // text field grows to take remaining width
                        text:             editingConfig.devName
                        placeholderText:  qsTr("Enter name")
                    }
                }

                // ---- Device list / settings loader ----
                Loader {
                    id: linkSettingsLoader
                    Layout.fillWidth: true        // << ensures it spans the whole dialog
                    source: subEditConfig.settingsURL

                    property var subEditConfig:         editingConfig
                    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
                }
            }
        }
    }

}


// LabelledButton {
//     label:      qsTr("Add New Link")
//     buttonText: qsTr("Add")

//     onClicked: {
//         var editingConfig = _linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
//         linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open()
//     }
// }

// Component {
//     id: linkDialogComponent

//     QGCPopupDialog {
//         title:          originalConfig ? qsTr("Edit Link") : qsTr("Add New Link")
//         buttons:        Dialog.Save | Dialog.Cancel
//         acceptAllowed:  nameField.text !== "" //true

//         property var originalConfig
//         property var editingConfig

//         onAccepted: {
//             linkSettingsLoader.item.saveSettings()
//             editingConfig.devName = nameField.text
//             editingConfig.name = editingConfig.devName

//             console.log("Bluetooth Save Button",editingConfig.devName)

//             if (originalConfig) {
//                 console.log("Bluetooth Save Button Edit Link",originalConfig)
//                 _linkManager.endConfigurationEditing(originalConfig, editingConfig)

//             } else {
//                 // If it was edited, it's no longer "dynamic"
//                 editingConfig.dynamic = false
//                 _linkManager.endCreateConfiguration(editingConfig)

//                   _linkManager.createConnectedLink(editingConfig)

//                  console.log("Bluetooth Save Button Add New Link",originalConfig)
//             }
//         }

//         onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

//         ColumnLayout {
//             spacing: ScreenTools.defaultFontPixelHeight / 2

//             RowLayout {
//                 Layout.fillWidth:   true
//                 spacing:            ScreenTools.defaultFontPixelWidth
//                 visible: true

//                 QGCLabel { text: qsTr("Name") }

//                 QGCTextField  {
//                     id:                 nameField
//                     Layout.fillWidth:   true
//                     text:               editingConfig.devName
//                     placeholderText:    qsTr("Enter name")
//                 }
//             }

//             // QGCCheckBoxSlider {
//             //     Layout.fillWidth:   true
//             //     text:               qsTr("Automatically Connect on Start")
//             //     checked:            editingConfig.autoConnect
//             //     onCheckedChanged:   editingConfig.autoConnect = checked
//             // }

//             // QGCCheckBoxSlider {
//             //     Layout.fillWidth:   true
//             //     text:               qsTr("High Latency")
//             //     checked:            editingConfig.highLatency
//             //     onCheckedChanged:   editingConfig.highLatency = checked
//             // }

//             LabelledComboBox {
//                 label:                  qsTr("Type")
//                 enabled:                originalConfig == null
//                 model:                  _linkManager.linkTypeStrings
//                 Component.onCompleted:  comboBox.currentIndex = editingConfig.linkType

//                 onActivated: (index) => {
//                     if (index !== editingConfig.linkType) {
//                         // Save current name
//                         var name = nameField.text
//                         // Create new link configuration
//                         editingConfig = _linkManager.createConfiguration(index, name)
//                     }
//                 }
//             }

//             Loader {
//                 id:     linkSettingsLoader
//                 source: subEditConfig.settingsURL

//                 property var subEditConfig:         editingConfig
//                 property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
//                 property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
//                 property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
//                 property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
//             }
//         }
//     }
// }





