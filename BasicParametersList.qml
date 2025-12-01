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
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.FactControls

Item {
    id:         _root

    property Fact   _editorDialogFact: Fact { }
    property int    _rowHeight:         ScreenTools.defaultFontPixelHeight * 2
    property int    _rowWidth:          10 // Dynamic adjusted at runtime
    property bool   _searchFilter:      searchText.text.trim() != "" || controller.showModifiedOnly  ///< true: showing results of search
    property var    _searchResults      ///< List of parameter names from search results
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _showRCToParam:     _activeVehicle.px4Firmware
    property var    _appSettings:       QGroundControl.settingsManager.appSettings
    property var    _controller:        controller
    property Fact rc7OptionFact: controller.getParameterFact(-1, "MNT1_TYPE")
    property Fact cameratype: controller.getParameterFact(-1, "CAM1_TYPE")
    property Fact mnt1pitchmax: controller.getParameterFact(-1, "MNT1_PITCH_MAX")


    ParameterEditorController {
        id: controller
    }


    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            z: -10
            color: "#1b1c3e"
        }
        // ---- Curved Gradient Background ----
        Canvas {
            anchors.fill: parent
            z: -1
            opacity: 0.95
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                // 🎨 Create diagonal gradient
                var gradient = ctx.createLinearGradient(0, 0, width, height)
                gradient.addColorStop(0, "#14163C")
                gradient.addColorStop(1, "#6A85FB")
                ctx.fillStyle = gradient

                // 🌀 Create a curved path from top-left to bottom-right
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.quadraticCurveTo(width * 0.4, height * 0.1, width, height * 0.9)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: parent.width * 0.5
            height: parent.height * 0.9
            radius: width * 0.5
            rotation: 30
            opacity: 0.95
            anchors.rightMargin: 1//-width * 0.25
            anchors.bottomMargin: 1//-height * 0.2
            z: -1

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#14163C" } // Deep indigo
                GradientStop { position: 1.0; color: "#6A85FB" } // Blue gradient
            }
        }



    }




    //---------------------------------------------
    //-- Header
    Row {
        id:             header
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        ScreenTools.defaultFontPixelWidth
        visible: QGroundControl.loadGlobalSetting("tab","tab")==="None"?true:false
        anchors.margins: 20
        height: 50

        Timer {
            id:         clearTimer
            interval:   100;
            running:    false;
            repeat:     false
            onTriggered: {
                searchText.text = ""
                controller.searchText = ""
            }
        }

        QGCLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Search:")
            color:"white"
            font.pixelSize: 20       // ✅ Bigger text
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
        }

        QGCTextField {
                    id:                 searchText
                    height: 25               // ✅ Increase height of the input box
                    width:150
                            font.pixelSize: 18       // ✅ Bigger input text
                            padding: 10              // ✅ Add some inner spacing
                            background: Rectangle {  // ✅ Modern styled background
                                color: "white"   // Slightly transparent white background
                                radius: 6
                                border.color: "#ffffff55"
                                border.width: 1
                            }
                    placeholderText:    qsTr("          ")//qsTr("    Search here    ")
                    Layout.fillWidth:   true
                    text:               controller.searchText
                    onDisplayTextChanged: controller.searchText = displayText
                    anchors.verticalCenter: parent.verticalCenter
                    Component.onCompleted: if(QGroundControl.loadGlobalSetting("tab","tab")==="None"){
                                               controller.searchText = ""
                                           }else if(QGroundControl.loadGlobalSetting("tab","tab")==="Spray"){
                                               controller.searchText = "SPRAY"
                                           }else if(QGroundControl.loadGlobalSetting("tab","tab")==="Battery"){
                                               controller.searchText = "BATT_LOW_VOLT|BATT_CRT_VOLT"
                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="None"){
                                               controller.searchText = "CAM1_TYPE|CAM1_DURATION|CAM1_SERVO_ON|CAM1_SERVO_OFF|CAM1_TRIGG_DIST|CAM1_RELAY_ON|CAM1_INTRVAL_MIN|CAM1_MNT_INST|CAM1_OPTIONS|CAM_MAX_ROLL|CAM_AUTO_ONLY|CAM1_FEEDBAK_PIN|CAM1_FEEDBAK_POL|CAM1_HFOV|CAM1_VFOV|MNT1_TYPE|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_ROLL_MIN|MNT1_ROLL_MAX|MNT1_YAW_MIN|MNT1_YAW_MAX|MNT1_RC_RATE|SERVO9_FUNCTION|SERVO9_MIN|SERVO9_MAX|SERVO10_FUNCTION|SERVO10_MIN|SERVO10_MAX|SERVO11_FUNCTION|SERVO11_MIN|SERVO11_MAX|RC6_OPTION|RC7_OPTION|RC8_OPTION|RC9_OPTION|RC10_OPTION|RC11_OPTION|RC12_OPTION|RC13_OPTION"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 1 // 300 is typically the value for "Mount Yaw"
                                                   mnt1pitchmax.rawValue = 25// default 20
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               } else {
                                                   console.log("RC7_OPTION parameter not available")
                                               }
                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="Servo Gimbal"){
                                               controller.searchText = "MNT1_TYPE|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_ROLL_MIN|MNT1_ROLL_MAX|MNT1_YAW_MIN|MNT1_YAW_MAX|MNT1_RC_RATE|SERVO9_FUNCTION|SERVO9_MIN|SERVO9_MAX|SERVO10_FUNCTION|SERVO10_MIN|SERVO10_MAX|SERVO11_FUNCTION|SERVO11_MIN|SERVO11_MAX|RC6_OPTION|RC7_OPTION|RC8_OPTION|MNT1_LEAD_RLL|MNT1_LEAD_PTCH"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 1 // 300 is typically the value for "Mount Yaw"
                                                   mnt1pitchmax.rawValue = 25// default 20
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               } else {
                                                   console.log("RC7_OPTION parameter not available")
                                               }
                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="STorM32 Gimbal"){
                                               controller.searchText = "SERIAL2_BAUD|SERIAL2_PROTOCOL|BRD_SER2_RTSCTS|MNT1_TYPE|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_ROLL_MIN|MNT1_ROLL_MAX|MNT1_YAW_MIN|MNT1_YAW_MAX|RC6_OPTION|RC7_OPTION|RC8_OPTION"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 4 // 300 is typically the value for "Mount Yaw"
                                                   mnt1pitchmax.rawValue = 25// default 20
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               } else {
                                                   console.log("RC7_OPTION parameter not available")
                                               }
                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="Brushless PWM Gimbal"){
                                               controller.searchText = "MNT1_TYPE|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_ROLL_MIN|MNT1_ROLL_MAX|MNT1_YAW_MIN|MNT1_YAW_MAX|MNT1_RC_RATE|SERVO9_FUNCTION|SERVO9_MIN|SERVO9_MAX|SERVO10_FUNCTION|SERVO10_MIN|SERVO10_MAX|SERVO11_FUNCTION|SERVO11_MIN|SERVO11_MAX|RC6_OPTION|RC7_OPTION|RC8_OPTION|MNT1_LEAD_RLL|MNT1_LEAD_PTCH"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 7 // 300 is typically the value for "Mount Yaw"
                                                   mnt1pitchmax.rawValue = 25  // default 20
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               } else {
                                                   console.log("RC7_OPTION parameter not available")
                                               }
                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="CADDX Gimbals"){
                                               controller.searchText = "SERIAL1_PROTOCOL|SERIAL1_BAUD|MNT1_TYPE|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_YAW_MIN|MNT1_YAW_MAX|MNT1_RC_RATE|RC6_OPTION|RC7_OPTION|RC8_OPTION"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 13 // 300 is typically the value for "Mount Yaw"
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               }}
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="Gremsy Gimbals"){
                                               controller.searchText = "SERIAL1_PROTOCOL|SERIAL1_BAUD|MNT1_TYPE|CAM1_TYPE|SERIAL2_OPTIONS|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_ROLL_MAX|MNT1_YAW_MIN|MNT1_YAW_MIN|MNT1_YAW_MAX|MNT1_RC_RATE|RC6_OPTION|RC7_OPTION|RC8_OPTION|RC9_OPTION|RC10_OPTION|RC11_OPTION|RC12_OPTION|RC13_OPTION"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 4 // 300 is typically the value for "Mount Yaw"
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               }}
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="Xacti Gimbals"){
                                               controller.searchText = "CAN_D1_PROTOCOL|CAN_D1_UC_NODE|CAN_P1_DRIVER|MNT1_TYPE|MNT1_PITCH_MIN|MNT1_PITCH_MAX|MNT1_YAW_MIN|MNT1_YAW_MAX|MNT1_RC_RATE|CAM1_TYPE|CAM1_INTRVAL_MIN|RC6_OPTION|RC7_OPTION|RC8_OPTION|RC9_OPTION|RC10_OPTION|RC11_OPTION|RC12_OPTION|CAM1_FEEDBAK_PIN|SERVO14_FUNCTION|RELAY1_PIN|SERVO13_FUNCTION"
                                               if (rc7OptionFact) {
                                                   rc7OptionFact.rawValue = 10 // 300 is typically the value for "Mount Yaw"
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               }

                                               else {
                                                   console.log("RC7_OPTION parameter not available")
                                               }
                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="SERVO"){
                                               controller.searchText = "CAM1_DURATION|CAM1_RELAY_ON|CAM1_SERVO_OFF|CAM1_SERVO_ON|CAM1_TYPE|SERVO10_FUNCTION"
                                               if (cameratype) {
                                                   cameratype.rawValue = 1 // 300 is typically the value for "Mount Yaw"
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               }

                                           }
                                           else if(QGroundControl.loadGlobalSetting("tab","tab")==="Relay"){
                                               controller.searchText = "CAM1_DURATION|CAM1_RELAY_ON|RELAY_DEFAULT|CAM1_TYPE|RELAY_PIN|SERVO13_FUNCTION"
                                               if (cameratype) {
                                                   cameratype.rawValue = 2 // 300 is typically the value for "Mount Yaw"
                                                   console.log("Set RC7_OPTION to Mount Yaw")
                                               }

                                           }
                }


        QGCButton {
                                           text: qsTr("Clear")
                                           onClicked: {
                                               if(ScreenTools.isMobile) {
                                                   Qt.inputMethod.hide();
                                               }
                                               clearTimer.start()
                                           }
                                           anchors.verticalCenter: parent.verticalCenter
                                       }

        QGCCheckBox {
            text: qsTr("Show modified only")
            anchors.verticalCenter: parent.verticalCenter
            checked: controller.showModifiedOnly
            onClicked: controller.showModifiedOnly = checked
            visible: QGroundControl.multiVehicleManager.activeVehicle.px4Firmware


        }

                                   } // Row - Header

    Row {
        id:             header1
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        ScreenTools.defaultFontPixelWidth
        visible: true
        anchors.margins: 20
        height: 50
            QGCButton {
                anchors.right:  parent.right
                text:           qsTr("Tools")
                onClicked:      toolsMenu.popup()
                visible: true
                anchors.verticalCenter: parent.verticalCenter
            }
            } // Row - Header

            QGCMenu {
                id:                 toolsMenu
                QGCMenuItem {
                    text:           qsTr("Refresh")
                    onTriggered:	controller.refresh()
                }
                QGCMenuItem {
                    text:           qsTr("Reset all to firmware's defaults")
                    onTriggered:    mainWindow.showMessageDialog(qsTr("Reset All"),
                                                                 qsTr("Select Reset to reset all parameters to their defaults.\n\nNote that this will also completely reset everything, including UAVCAN nodes, all vehicle settings, setup and calibrations."),
                                                                 Dialog.Cancel | Dialog.Reset,
                                                                 function() { controller.resetAllToDefaults() })
                }
                QGCMenuItem {
                    text:           qsTr("Reset to vehicle's configuration defaults")
                    visible:        !_activeVehicle.apmFirmware
                    onTriggered:    mainWindow.showMessageDialog(qsTr("Reset All"),
                                                                 qsTr("Select Reset to reset all parameters to the vehicle's configuration defaults."),
                                                                 Dialog.Cancel | Dialog.Reset,
                                                                 function() { controller.resetAllToVehicleConfiguration() })
                }
                QGCMenuSeparator { }
                QGCMenuItem {
                    text:           qsTr("Load from file...")
                    onTriggered: {
                        fileDialog.title =          qsTr("Load Parameters")
                        fileDialog.openForLoad()
                    }
                }
                QGCMenuItem {
                    text:           qsTr("Save to file...")
                    onTriggered: {
                        fileDialog.title =          qsTr("Save Parameters")
                        fileDialog.openForSave()
                    }
                }
                QGCMenuSeparator { visible: _showRCToParam }
                QGCMenuItem {
                    text:           qsTr("Clear all RC to Param")
                    onTriggered:	_activeVehicle.clearAllParamMapRC()
                    visible:        _showRCToParam
                }
                QGCMenuSeparator { }
                QGCMenuItem {
                    text:           qsTr("Reboot Vehicle")
                    onTriggered:    mainWindow.showMessageDialog(qsTr("Reboot Vehicle"),
                                                                 qsTr("Select Ok to reboot vehicle."),
                                                                 Dialog.Cancel | Dialog.Ok,
                                                                 function() { _activeVehicle.rebootVehicle() })
                }
            }

            /// Group buttons
            QGCFlickable {
                id :                groupScroll
                width:              ScreenTools.defaultFontPixelWidth * 15
                anchors.top:        header.bottom
                anchors.bottom:     parent.bottom
                clip:               true
                pixelAligned:       true
                contentHeight:      groupedViewCategoryColumn.height
                flickableDirection: Flickable.VerticalFlick
                visible:            !_searchFilter

                ColumnLayout {
                    id:             groupedViewCategoryColumn
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        Math.ceil(ScreenTools.defaultFontPixelHeight * 0.15)

                    Repeater {
                        model: controller.categories

                        Column {
                            Layout.fillWidth:   true
                            spacing:            Math.ceil(ScreenTools.defaultFontPixelHeight * 0.15)


                            SectionHeader {
                                id:             categoryHeader
                                anchors.left:   parent.left
                                anchors.right:  parent.right
                                text:           object.name
                                checked:        object == controller.currentCategory

                                onCheckedChanged: {
                                    if (checked) {
                                        controller.currentCategory  = object
                                    }
                                }
                            }

                            Repeater {
                                model: categoryHeader.checked ? object.groups : 0

                                QGCButton {
                                    width:          ScreenTools.defaultFontPixelWidth * 15
                                    text:           object.name
                                    height:         _rowHeight
                                    checked:        object == controller.currentGroup
                                    autoExclusive:  true

                                    onClicked: {
                                        if (!checked) _rowWidth = 10
                                        checked = true
                                        controller.currentGroup = object
                                    }
                                }
                            }
                        }
                    }
                }
            }

            QGCListView {
                id: editorListView
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left: _searchFilter ? parent.left : groupScroll.right
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.bottom: parent.bottom
                orientation: ListView.Vertical
                model: controller.parameters
                cacheBuffer: height > 0 ? height * 2 : 0
                clip: true

                // Track currently edited index
                property int editedIndex: -1

                delegate: Rectangle {
                    id: delegateRoot
                    height: 50//_rowHeight
                    width: _rowWidth
                    color: "transparent"

                    // Store the fact for this item
                    property Fact itemFact: object
                    property bool isBeingEdited: editorListView.editedIndex === index

                    Row {
                        id: factRow
                        spacing: Math.ceil(ScreenTools.defaultFontPixelWidth * 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                        QGCLabel {
                            id: nameLabel
                            width: ScreenTools.defaultFontPixelWidth * 15
                            text: itemFact.name
                            clip: true
                            color: "white"
                        }

                        // Dynamic input display: TextField or ComboBox
                        Item {
                            width: ScreenTools.defaultFontPixelWidth * 15
                            height: valueLoader.item ? valueLoader.item.implicitHeight : 40

                            Loader {
                                id: valueLoader
                                anchors.fill: parent
                                active: true
                                sourceComponent: itemFact.enumStrings.length === 0 ? textFieldComponent : comboBoxComponent
                            }

                            Component {
                                id: textFieldComponent
                                QGCTextField {
                                    id: textField
                                    text: itemFact.valueString
                                    readOnly: delegateRoot.isBeingEdited ? false : true
                                    width: parent.width
                                    color: delegateRoot.isBeingEdited ? "black" : "gray"

                                    // Handle focus changes
                                    onActiveFocusChanged: {
                                        if (activeFocus) {
                                            editorListView.editedIndex = index
                                        } else if (editorListView.editedIndex === index) {
                                            // Save when focus is lost
                                            if (itemFact.valueString !== text) {
                                                itemFact.value = text
                                            }
                                            editorListView.editedIndex = -1
                                        }
                                    }

                                    // Handle Enter key press
                                    Keys.onReturnPressed: {
                                        if (itemFact.valueString !== text) {
                                            itemFact.value = text
                                        }
                                        editorListView.editedIndex = -1
                                        focus = false
                                    }

                                    // Handle Escape key press
                                    Keys.onEscapePressed: {
                                        text = itemFact.valueString
                                        editorListView.editedIndex = -1
                                        focus = false
                                    }
                                }
                            }

                            Component {
                                id: comboBoxComponent
                                QGCComboBox {
                                    id: comboBox
                                    width: parent.width
                                    model: itemFact.enumStrings
                                    currentIndex: itemFact.enumIndex
                                    enabled: delegateRoot.isBeingEdited

                                    // Handle selection changes
                                    onActivated: {
                                        if (currentIndex !== itemFact.enumIndex) {
                                            itemFact.enumIndex = currentIndex
                                        }
                                        editorListView.editedIndex = -1
                                    }

                                    // Click to edit
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!delegateRoot.isBeingEdited) {
                                                editorListView.editedIndex = index
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        QGCLabel {
                            text: itemFact.shortDescription
                            width: ScreenTools.defaultFontPixelWidth * 15
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            color: "white"
                        }

                        Component.onCompleted: {
                            if (_rowWidth < factRow.width + ScreenTools.defaultFontPixelWidth) {
                                _rowWidth = factRow.width + ScreenTools.defaultFontPixelWidth
                            }
                        }
                    }

                    Rectangle {
                        width: _rowWidth
                        height: 1
                        color: qgcPal.text
                        opacity: 0.15
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                    }

                    // Click to edit the entire row
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            if (!delegateRoot.isBeingEdited) {
                                editorListView.editedIndex = index
                                // Set focus to the appropriate control
                                if (valueLoader.item) {
                                    if (itemFact.enumStrings.length === 0) {
                                        valueLoader.item.forceActiveFocus()
                                        valueLoader.item.selectAll()
                                    } else {
                                        valueLoader.item.popup.visible = true
                                    }
                                }
                            } else {
                                editorListView.editedIndex = -1
                            }
                        }
                    }
                }
            }







            // /// Parameter list
            // QGCListView {
            //     id:                 editorListView
            //     anchors.leftMargin: ScreenTools.defaultFontPixelWidth
            //     anchors.left:       _searchFilter ? parent.left : groupScroll.right
            //     anchors.right:      parent.right
            //     anchors.top:        header.bottom
            //     anchors.bottom:     parent.bottom
            //     orientation:        ListView.Vertical
            //     model:              controller.parameters
            //     cacheBuffer:        height > 0 ? height * 2 : 0
            //     clip:               true

            //     delegate: Rectangle {
            //         height: _rowHeight
            //         width:  _rowWidth
            //         color: "white"

            //         Row {
            //             id:     factRow
            //             spacing: Math.ceil(ScreenTools.defaultFontPixelWidth * 0.5)
            //             anchors.verticalCenter: parent.verticalCenter
            //             property Fact modelFact: object

            //             QGCLabel {
            //                 id: nameLabel
            //                 width: ScreenTools.defaultFontPixelWidth * 20
            //                 text: factRow.modelFact.name
            //                 clip: true
            //             }

            //             // Dynamic input display: TextField or ComboBox
            //             Item {
            //                 width: ScreenTools.defaultFontPixelWidth * 20
            //                 height: valueLoader.item ? valueLoader.item.implicitHeight : 40

            //                 Loader {
            //                     id: valueLoader
            //                     anchors.fill: parent
            //                     active: true
            //                     sourceComponent: factRow.modelFact.enumStrings.length === 0 ? textFieldComponent : comboBoxComponent
            //                 }

            //                 Component {
            //                     id: textFieldComponent
            //                     QGCTextField {
            //                         text: factRow.modelFact.valueString
            //                         readOnly: false
            //                         width: parent.width

            //                         MouseArea {
            //                             anchors.fill: parent
            //                             onClicked: {
            //                                 console.log("TextField clicked:", parent.text)
            //                                 // Trigger dialog or edit logic here
            //                             }
            //                         }
            //                     }
            //                 }

            //                 Component {
            //                     id: comboBoxComponent
            //                     QGCComboBox {
            //                         width: parent.width
            //                         model: factRow.modelFact.enumStrings
            //                         currentIndex: factRow.modelFact.enumIndex

            //                         onActivated: {
            //                             console.log("ComboBox selected:", currentText)
            //                             factRow.modelFact.enumIndex = currentIndex
            //                         }

            //                         MouseArea {
            //                             anchors.fill: parent
            //                             onClicked: {
            //                                 console.log("ComboBox clicked")
            //                             }
            //                         }
            //                     }
            //                 }
            //             }

            //             QGCLabel {
            //                 text: factRow.modelFact.shortDescription
            //                 width: ScreenTools.defaultFontPixelWidth * 20
            //                 wrapMode: Text.WordWrap
            //             }

            //             Component.onCompleted: {
            //                 if (_rowWidth < factRow.width + ScreenTools.defaultFontPixelWidth) {
            //                     _rowWidth = factRow.width + ScreenTools.defaultFontPixelWidth
            //                 }
            //             }
            //         }

            //         Rectangle {
            //             width: _rowWidth
            //             height: 1
            //             color: qgcPal.text
            //             opacity: 0.15
            //             anchors.bottom: parent.bottom
            //             anchors.left: parent.left
            //         }

            //         // Click for full row (optional, e.g., open parameter editor)
            //         MouseArea {
            //             anchors.fill: parent
            //             acceptedButtons: Qt.LeftButton
            //             onClicked: {
            //                 console.log("Row clicked: ", factRow.modelFact.name)
            //                 // Example: _editorDialogFact = factRow.modelFact
            //                 // editorDialogComponent.createObject(mainWindow).open()
            //             }
            //         }
            //     }
            // }

            QGCFileDialog {
                id:             fileDialog
                folder:         _appSettings.parameterSavePath
                nameFilters:    [ qsTr("Parameter Files (*.%1)").arg(_appSettings.parameterFileExtension) , qsTr("All Files (*)") ]

                onAcceptedForSave: (file) => {
                                       controller.saveToFile(file)
                                       close()
                                   }

                onAcceptedForLoad: (file) => {
                                       close()
                                       if (controller.buildDiffFromFile(file)) {
                                           parameterDiffDialog.createObject(mainWindow).open()
                                       }
                                   }
            }

            Component {
                id: editorDialogComponent

                ParameterEditorDialog {
                    fact:           _editorDialogFact
                    showRCToParam:  _showRCToParam
                }
            }

            Component {
                id: parameterDiffDialog

                ParameterDiffDialog {
                    paramController: _controller
                }
            }
        }
