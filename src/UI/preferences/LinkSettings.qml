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
ColumnLayout  {

    Layout.fillWidth: true
    spacing: ScreenTools.defaultFontPixelHeight * 0.5

    property var _linkManager: QGroundControl.linkManager
    property color app_color: "#301934"
    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle


    // Success path
    Connections {
        target: QGroundControl.multiVehicleManager

        function onActiveVehicleChanged(vehicle) {
            if (vehicle) {
                mainWindow.showToastMessage("Drone Connected")
            } else {
                mainWindow.showToastMessage("Drone DisConnected")
            }
            mainWindow.connecting_drone = false
            mainWindow.close_dialog_showToast("")
        }
    }

    // Failure path
    Connections {
        target: QGroundControl.linkManager

        function onCommunicationError(linkName, errorMessage) {
            console.log("LinkSettings: connect failed for", linkName)
            mainWindow.connecting_drone = false     // stop loading screen
            mainWindow.close_dialog_showToast("")   // close any open dialogs
            mainWindow.showToastMessage("Connection failed: " + errorMessage)
        }
    }

    // --- Links Section ---
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#E0E0E0"
        Layout.topMargin: ScreenTools.defaultFontPixelHeight * 0.5
        Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.5
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text:             qsTr("Communication Links")
            font.pixelSize:   ScreenTools.mediumFontPointSize
            color:            "black"
            font.bold:        true
            //topPadding:       ScreenTools.defaultFontPixelHeight
            bottomPadding:   ScreenTools.defaultFontPixelHeight * 0.3
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width:            130
            height:           36
            radius:           18
            color:            addMouse.containsMouse ? "#D6EAF8" : "#EBF5FB"
            border.color:     "#301934"
            border.width:     1

            Text {
                anchors.centerIn: parent
                text:             qsTr("+ Add New Link")
                color:            "#301934"
                font.bold:        true
                font.pixelSize:   14
            }

            MouseArea {
                id:             addMouse
                anchors.fill:   parent
                hoverEnabled:   true
                cursorShape:    Qt.PointingHandCursor
                onClicked:      typeSelectionDialogComponent.createObject(mainWindow).open()
            }
        }
    }

    Repeater {
        model: _linkManager.linkConfigurations

        ColumnLayout {
            id:               linkRow
            Layout.fillWidth: true
            visible:          !object.dynamic
            spacing:          ScreenTools.defaultFontPixelHeight / 4

            Rectangle {
                Layout.fillWidth: true
                implicitHeight:   mainRowWrapper.implicitHeight + 30
                color:            object.link ? "#F4FDF8" : "#FFFFFF"
                radius:           10
                border.color:     object.link ? "#301934" : "#E2E8F0"
                border.width:     object.link ? 2 : 1

                RowLayout {
                    id:               mainRowWrapper
                    anchors.left:     parent.left
                    anchors.right:    parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins:  20
                    spacing:          _isNarrow ? 10 : 20

                    // Status Dot
                    Rectangle {
                        width:  12
                        height: 12
                        radius: 6
                        color:  object.link ? "#301934" : "#9E9E9E"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Link Details
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text:             object.name
                            color:            "#2C3E50"
                            font.bold:        true
                            //font.pixelSize:   18
                            font.pointSize: ScreenTools.defaultFontPointSize
                            elide:            Text.ElideRight
                        }

                        Text {
                            text:             object.link ? qsTr("Connected") : qsTr("Disconnected")
                            color:            object.link ? "#301934" : "#7F8C8D"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }

                    // Actions
                    RowLayout {
                        spacing: _isNarrow ? 8 : 15
                        Layout.alignment: Qt.AlignVCenter

                        // Delete Action
                        Rectangle {
                            width:  36
                            height: 36
                            radius: 8
                            color:  deleteArea.containsMouse ? "#FDEDEC" : "transparent"
                            border.color: deleteArea.containsMouse ? "#E74C3C" : "transparent"

                            QGCColoredImage {
                                anchors.centerIn: parent
                                height:           18
                                width:            18
                                sourceSize.height: 18
                                fillMode:         Image.PreserveAspectFit
                                color:            "#E74C3C"
                                source:           "/res/TrashDelete.svg"
                            }

                            MouseArea {
                                id: deleteArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cfg = object
                                    if (!cfg) return
                                    mainWindow.showMessageDialog(
                                                qsTr("Delete Link"),
                                                qsTr("Are you sure you want to delete '%1'?").arg(cfg.name),
                                                Dialog.Ok | Dialog.Cancel,
                                                function() { _linkManager.removeConfiguration(cfg) }
                                                )
                                }
                            }
                        }

                        // Connect/Disconnect Action
                        Rectangle {
                            width:            100
                            height:           36
                            radius:           18
                            color:            object.link ? (connectMouse.containsMouse ? "#FADBD8" : "#FDEDEC") : (connectMouse.containsMouse ? "#301934" : "#301934")
                            border.color:     object.link ? "#E74C3C" : "transparent"
                            border.width:     1

                            Connections {
                                target: object
                                function onLinkChanged() {
                                    console.log("object.linkChanged fired, link is now:", object.link)
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text:             object.link ? qsTr("Disconnect") : qsTr("Connect")
                                color:            object.link ? "#C0392B" : "white"
                                font.bold:        true
                                font.pixelSize:   14
                            }

                            MouseArea {
                                id:             connectMouse
                                anchors.fill:   parent
                                hoverEnabled:   true
                                cursorShape:    Qt.PointingHandCursor
                                onClicked: {
                                    if (!object) {
                                        console.warn("LinkSettings: config object is null")
                                        return
                                    }

                                    if (object.link) {
                                        console.log("Click DisConnect Button")
                                        _linkManager.disconnectLink(object)
                                    } else {
                                        // Check Bluetooth availability before connecting
                                        // object is a LinkConfiguration — if it's Bluetooth type,
                                        // it has isBluetoothAvailable()
                                        console.log("click Connect Button",object.linkType)

                                        if (object.linkType === 0) {  // 0 = TypeBluetooth
                                            if (!object.isBluetoothAvailable()) {
                                                console.log("Please turn ON Bluetooth")
                                                mainWindow.showToastMessage("Please turn ON Bluetooth");
                                                return
                                            }
                                        }

                                        if (activeVehicle) {
                                            mainWindow.showToastMessage(
                                                        qsTr("Please disconnect the active vehicle before connecting a new one"))
                                            return
                                        }

                                        _linkManager.createConnectedLink(object)
                                        mainWindow.connecting_drone = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Bottom Spacer
    Item {
        Layout.preferredHeight: 20
    }


    // First Dialog – Type Selection Only
    Component {
        id: typeSelectionDialogComponent

        QGCPopupDialog {
            id: typeDialog
            title: qsTr("Select Link Type")
            buttons: false
            closeOnClickOutside: true

            popupWidth: ScreenTools.isMobile ? Math.min(mainWindow.width * 0.9, 380) : 520
            
            property int selectedType: -1

            ColumnLayout {
                spacing: ScreenTools.isMobile ? 8 : 12
                width: parent.width - 24
                anchors.horizontalCenter: parent.horizontalCenter
                Layout.fillWidth: true

                Repeater {
                    model: _linkManager.linkTypeStrings
                    delegate: Rectangle {
                        id: typeItem
                        visible: modelData !== "Mock Link" && modelData !== "Log Replay"
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? (ScreenTools.isMobile ? 46 : 56) : 0
                        radius: 8
                        color: typeMouseArea.containsMouse ? "#F8F9FA" : "#FFFFFF"
                        border.color: typeMouseArea.containsMouse ? "#301934" : "#E2E8F0"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: ScreenTools.isMobile ? 12 : 16

                            // Number Icon Box
                            Rectangle {
                                width: ScreenTools.isMobile ? 28 : 34
                                height: width
                                radius: 8
                                Layout.alignment: Qt.AlignVCenter
                                color: typeMouseArea.containsMouse ? "#301934" : "#F1F5F9"
                                border.color: typeMouseArea.containsMouse ? "#301934" : "#DDE1EA"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Outfit"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                                    font.bold: true
                                    color: typeMouseArea.containsMouse ? "white" : "black"
                                    text: (index + 1)
                                }
                            }

                            // Connection Type Title
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                                font.bold: true
                                color: "black"
                                elide: Text.ElideRight
                            }

                            // Arrow Indicator
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: "→"
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.4
                                font.bold: true
                                color: typeMouseArea.containsMouse ? "white" : "#666666"
                            }
                        }

                        MouseArea {
                            id: typeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
                        }
                    }
                }
            }
        }
    }

    // Second Dialog - Configuration (without type dropdown)
    Component {
        id: linkConfigDialogComponent

        QGCPopupDialog {
            id : linkConfigDialog
            title: selectedType === 0 ? "Bluetooth Devices"
                                      : originalConfig ? qsTr("Edit Link")
                                                       : qsTr("Add New Link")
            buttons:        Dialog.Save | Dialog.Cancel
            acceptAllowed:  nameField.text !== ""

            property var originalConfig
            property var editingConfig
            property int selectedType

            property bool _connectionInitiated: false

            Connections {
                target: linkConfigDialog.editingConfig
                enabled: linkConfigDialog.editingConfig !== null

                function onShowToast(message) {
                    mainWindow.showToastMessage(message)
                }
            }

            onAccepted: {

                if ( _connectionInitiated ) {
                    console.log("linkConfigDialog: ignoring duplicate accept")
                    return
                }

                linkSettingsLoader.item.saveSettings()
                editingConfig.devName = nameField.text
                editingConfig.name    = editingConfig.devName

                if (originalConfig) {

                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)

                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)

                    if (activeVehicle) {
                        mainWindow.showToastMessage(
                                    qsTr("Please disconnect the active vehicle before connecting a new one"))
                        return
                    }

                    _connectionInitiated = true         // mark as initiated
                    mainWindow.connecting_drone = true  // only set true once
                    _linkManager.createConnectedLink(editingConfig)
                    console.log("click save button editingConfig : ")
                }
            }

            onRejected: {
                _connectionInitiated = false  // reset on cancel
                _linkManager.cancelConfigurationEditing(editingConfig)
            }

            // ---------- MAIN LAYOUT ----------
            ColumnLayout {
                id: mainColumn
                spacing: ScreenTools.defaultFontPixelHeight / 2
                Layout.fillWidth: true


                // ---- Name row (not shown for Bluetooth) ----
                RowLayout {
                    spacing: linkSettingsLoader._colSpacing
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"

                    QGCLabel { 
                        text: qsTr("Name")
                        color: "black"
                        Layout.preferredWidth: linkSettingsLoader._firstColumnWidth
                    }

                    QGCTextField {
                        id:               nameField
                        Layout.preferredWidth: linkSettingsLoader._secondColumnWidth
                        text:             linkConfigDialog.editingConfig.devName
                        placeholderText:  qsTr("Enter name")
                        textColor:        "black"
                        leftPadding:      16
                        rightPadding:     16
                        background: Rectangle {
                            color: "#FFFFFF"
                            radius: 8
                            border.color: nameField.activeFocus ? "#301934" : "#DDE1EA"
                            border.width: nameField.activeFocus ? 2 : 1
                            implicitHeight: 44
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                // ---- Device list / settings loader ----
                Loader {
                    id: linkSettingsLoader
                    Layout.fillWidth: true        // << ensures it spans the whole dialog
                    source: subEditConfig.settingsURL

                    property var subEditConfig:         linkConfigDialog.editingConfig
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





