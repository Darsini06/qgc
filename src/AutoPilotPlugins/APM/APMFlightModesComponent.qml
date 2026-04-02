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

import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.ScreenTools

SetupPage {
    id: flightModePage

    readonly property string _modeChannelParam: controller.modeChannelParam
    readonly property string _modeParamPrefix:  controller.modeParamPrefix
    readonly property var    _pwmStrings:       [ "PWM 0 - 1230", "PWM 1231 - 1360", "PWM 1361 - 1490", "PWM 1491 - 1620", "PWM 1621 - 1749", "PWM 1750 +" ]

    property real   _margins:                   ScreenTools.defaultFontPixelHeight
    property Fact   _nullFact
    property bool   _fltmodeChExists:           controller.parameterExists(-1, _modeChannelParam)
    property Fact   _fltmodeCh:                 _fltmodeChExists ? controller.getParameterFact(-1, _modeChannelParam) : _nullFact
    property bool   _ch7OptAvailable:           controller.parameterExists(-1, "CH7_OPT")
    property int    _rcOptionStart:             _ch7OptAvailable ? 7 : 6
    property int    _rcOptionStop:              _ch7OptAvailable ? 12 : 16
    property bool   _customSimpleMode:          controller.simpleMode === APMFlightModesComponentController.SimpleModeCustom

    property string selectedTab: "flightMode"

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    APMFlightModesComponentController {
        id: controller
    }


    Column {
        anchors.fill: parent
        spacing: _margins

        // Tabs Header
        Row {
            id: tabRow
            width: parent.width
            spacing: _margins

            Rectangle {
                id: tabFlightMode
                width: parent.width / 2 - (_margins / 2)
                height: ScreenTools.defaultFontPixelHeight * 1.5
                color: selectedTab === "flightMode" ? "#301934" : "#ffffff"
                radius:         10
                border.width:   2
                border.color:   selectedTab === "flightMode" ? "#301934" : "#DDE1EA"

                MouseArea {
                    anchors.fill: parent
                    onClicked: selectedTab = "flightMode"
                }

                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("Flight Mode Settings")
                    font.bold: true
                    color: selectedTab === "flightMode" ? "white" : "black"
                }
            }

            Rectangle {
                id: tabSwitchOptions
                width: parent.width / 2 - (_margins / 2)
                height: ScreenTools.defaultFontPixelHeight * 1.5
                color: selectedTab === "switchOptions" ? "#301934" : "#ffffff"
                radius:         10
                border.width:   2
                border.color:   selectedTab === "switchOptions" ? "#301934" : "#DDE1EA"
                MouseArea {
                    anchors.fill: parent
                    onClicked: selectedTab = "switchOptions"
                }
                QGCLabel {
                    anchors.centerIn: parent
                    text: qsTr("Switch Options")
                    font.bold: true
                    color: selectedTab === "switchOptions" ? "white" : "black"
                }
            }
        }

        Loader {
            id: tabLoader
            anchors.top: tabRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            sourceComponent: selectedTab === "flightMode" ? flightModeComponent : switchOptionComponent
        }
    }


    Component {
        id: flightModeComponent

        ScrollView {
            visible: selectedTab === "flightMode"
            anchors.fill: parent
            clip: true

            Column {
                id: columnContent
                width: parent.width
                spacing: _margins


                Rectangle {
                    width: parent.width
                    height: flightModeColumn.implicitHeight + (ScreenTools.defaultFontPixelWidth * 2) // Add padding
                    //color: qgcPal.windowShade

                    Column {
                        id: flightModeColumn
                        width: parent.width - (_margins * 2)
                        anchors.centerIn: parent
                        padding: ScreenTools.defaultFontPixelWidth
                        spacing: ScreenTools.defaultFontPixelHeight


                        Row {
                            spacing: _margins
                            visible: _fltmodeChExists

                            QGCLabel {
                                anchors.baseline: modeChannelCombo.baseline
                                text: qsTr("Flight mode channel:")
                                color: "black"
                            }

                            QGCComboBox {
                                id: modeChannelCombo
                                width: ScreenTools.defaultFontPixelWidth * 15
                                model: [qsTr("Not assigned"), qsTr("Channel 1"), qsTr("Channel 2"),
                                    qsTr("Channel 3"), qsTr("Channel 4"), qsTr("Channel 5"),
                                    qsTr("Channel 6"), qsTr("Channel 7"), qsTr("Channel 8")]
                                currentIndex: _fltmodeCh.value
                                onActivated: (index) => { _fltmodeCh.value = index }
                            }
                        }

                        GridLayout {
                            rows: _customSimpleMode ? 7 : 6
                            flow: GridLayout.TopToBottom
                            width: parent.width
                            // no fixed height, let content define it

                            QGCLabel { text: ""; visible: _customSimpleMode }

                            //Flight Mode
                            Repeater {
                                model: 6
                                QGCLabel {
                                    text: qsTr("Flight Mode ") + index
                                    color: controller.activeFlightMode == index ? "#301934" : "black"
                                    font.bold: controller.activeFlightMode == index ? true : false
                                    property int index: modelData + 1
                                }
                            }

                            QGCLabel { text: ""; visible: _customSimpleMode }

                            //Flight Mode DropDown
                            Repeater {
                                model: 6
                                FactComboBox {
                                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 15
                                    fact: controller.getParameterFact(-1, _modeParamPrefix + index)
                                    indexModel: false
                                    property int index: modelData + 1
                                }
                            }

                            QGCLabel {
                                text: qsTr("Simple")
                                font.pointSize: ScreenTools.smallFontPointSize
                                visible: _customSimpleMode
                            }

                            Repeater {
                                model: controller.simpleModeEnabled

                                QGCCheckBox {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: _customSimpleMode
                                    checked: modelData
                                    onClicked: controller.setSimpleMode(index, checked)
                                }
                            }

                            QGCLabel {
                                text: qsTr("Super-Simple")
                                font.pointSize: ScreenTools.smallFontPointSize
                                visible: _customSimpleMode
                            }

                            Repeater {
                                model: controller.superSimpleModeEnabled

                                QGCCheckBox {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: _customSimpleMode
                                    checked: modelData
                                    onClicked: controller.setSuperSimpleMode(index, checked)
                                }
                            }

                            QGCLabel { text: ""; visible: _customSimpleMode }

                            Repeater {
                                model: 6
                                QGCLabel {
                                    text: _pwmStrings[modelData]
                                    color: "black"
                                }
                            }
                        }

                        // RowLayout {
                        //     spacing: _margins
                        //     visible: controller.simpleModesSupported

                        //     QGCLabel { text: qsTr("Simple Mode") }

                        //     QGCComboBox {
                        //         model: controller.simpleModeNames
                        //         currentIndex: controller.simpleMode
                        //         onActivated: (index) => { controller.simpleMode = index }
                        //     }
                        // }
                    }
                }
            }
        }
    }

    Component {
        id: switchOptionComponent

        ScrollView {
            visible: selectedTab === "switchOptions"
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: ScreenTools.defaultFontPixelHeight

                // This empty item pushes the content to center vertically
                Item {
                    width: parent.width
                    height: 0 // This will be calculated below
                }

                Column {
                    id: channelOptColumn
                    width: parent.width
                    spacing: ScreenTools.defaultFontPixelHeight
                    topPadding: 15

                    Repeater {
                        model: _rcOptionStop - _rcOptionStart + 1

                        Row {
                            spacing: ScreenTools.defaultFontPixelWidth * 2
                            width: parent.width
                            // This centers the entire row content horizontally
                            property int rowWidth: ScreenTools.defaultFontPixelWidth * 25 // Adjust this based on your content width
                            leftPadding: (parent.width - rowWidth) / 2.5

                            property int index: modelData + _rcOptionStart
                            property Fact nullFact: Fact { }

                            QGCLabel {
                                anchors.baseline: optCombo.baseline
                                text: qsTr("Channel option %1 :").arg(index)
                                color: controller.channelOptionEnabled[modelData + (_ch7OptAvailable ? 1 : 0)] ? "#301934" : "black"
                            }

                            FactComboBox {
                                id: optCombo
                                width: ScreenTools.defaultFontPixelWidth * 15
                                fact: controller.getParameterFact(-1, "r.RC" + index + "_OPTION")
                                indexModel: false
                            }
                        }
                    }
                }

                // This empty item balances the top one for vertical centering
                Item {
                    width: parent.width
                    height: 0 // This will be calculated below
                }
            }
        }
    }

}


