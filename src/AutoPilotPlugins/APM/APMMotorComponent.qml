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

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.ScreenTools

SetupPage {
    id:             motorPage
    pageComponent:  pageComponent

    readonly property int _barHeight:           10
    readonly property int _barWidth:            5
    readonly property int _sliderHeight:        10
    readonly property int _motorTimeoutSecs:    3

    FactPanelController {
        id:             controller
    }

    Component {
        id: pageComponent

        Column {
            spacing: ScreenTools.defaultFontPixelHeight

            QGCLabel {
                text:       qsTr("Warning: Unable to determine motor count")
                color:      qgcPal.warningText
                visible:    controller.vehicle.motorCount == -1
            }

            // Changed from Row to Column for vertical layout
            Column {
                id:         motorSliders
                enabled:    safetySwitch.checked
                spacing:    ScreenTools.defaultFontPixelHeight

                // Main motor sliders in a horizontal row within the column
                Row {
                    spacing: ScreenTools.defaultFontPixelWidth * 2

                    Repeater {
                        id: sliderRepeater
                        model: controller.vehicle.motorCount == -1 ? 8 : controller.vehicle.motorCount

                        Column {
                            property alias motorSlider: slider
                            spacing: ScreenTools.defaultFontPixelHeight / 2

                            QGCLabel {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: controller.vehicle.motorIndexToLetter ? controller.vehicle.motorIndexToLetter(index) : "M" + (index + 1)
                            }

                            QGCSlider {
                                id: slider
                                width: ScreenTools.defaultFontPixelWidth * 8
                                orientation: Qt.Horizontal
                                from: 0
                                to: 100
                                stepSize: 1
                                value: 0
                                live: false

                                onValueChanged: {
                                    controller.vehicle.motorTest(index + 1, value, value == 0 ? 0 : _motorTimeoutSecs, true)
                                    if (value != 0) {
                                        motorTimer.restart()
                                    }
                                }

                                Timer {
                                    id: motorTimer
                                    interval: _motorTimeoutSecs * 1000
                                    repeat: false
                                    running: false

                                    onTriggered: {
                                        allSlider.value = 0
                                        slider.value = 0
                                    }
                                }
                            }
                        }
                    } // Repeater

                    // "All" slider in its own row
                    Row {
                        spacing: ScreenTools.defaultFontPixelWidth * 2

                        Column {
                            spacing: ScreenTools.defaultFontPixelHeight / 2

                            QGCLabel {
                                anchors.horizontalCenter:   parent.horizontalCenter
                                text:                       qsTr("All")
                            }

                            QGCSlider {
                                id:                         allSlider
                                width:                      ScreenTools.defaultFontPixelWidth * 8  // Set width for horizontal slider
                                orientation:                Qt.Horizontal  // Changed to Horizontal
                                from:                       0
                                to:                         100
                                stepSize:                   1
                                value:                      0
                                live:                       false

                                onValueChanged: {
                                    for (var sliderIndex=0; sliderIndex<sliderRepeater.count; sliderIndex++) {
                                        sliderRepeater.itemAt(sliderIndex).motorSlider.value = allSlider.value
                                    }
                                }
                            }
                        } // Column
                    } // Row


                } // Row

            } // Column (main motor sliders container)

            QGCLabel {
                anchors.left:   parent.left
                anchors.right:  parent.right
                wrapMode:       Text.WordWrap
                text:           qsTr("Moving the sliders will causes the motors to spin. Make sure you remove all props.")
            }

            Row {
                spacing: ScreenTools.defaultFontPixelWidth

                Switch {
                    id: safetySwitch
                    onClicked: {
                        if (!checked) {
                            for (var sliderIndex=0; sliderIndex<sliderRepeater.count; sliderIndex++) {
                                sliderRepeater.itemAt(sliderIndex).motorSlider.value = 0
                            }
                            allSlider.value = 0
                        }
                    }
                }

                QGCLabel {
                    color:  qgcPal.warningText
                    text:   safetySwitch.checked ? qsTr("Careful: Motor sliders are enabled") : qsTr("Propellers are removed - Enable motor sliders")
                }
            } // Row
        } // Column
    } // Component
} // SetupPage
