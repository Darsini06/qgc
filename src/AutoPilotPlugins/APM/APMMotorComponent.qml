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

        Item {
            width:  motorPage.availableWidth
            height: motorPage.availableHeight

            // Center the entire UI in the dialog
            Column {
                id: contentColumn
                anchors.centerIn: parent
                spacing: ScreenTools.defaultFontPixelHeight * 2
                width: implicitWidth

                // 1️⃣ Warning message
                QGCLabel {
                    text: qsTr("Warning: Unable to determine motor count")
                    color: qgcPal.warningText
                    visible: controller.vehicle.motorCount == -1
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // 3️⃣ Info text
                QGCLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Moving the sliders will cause the motors to spin. Make sure you remove all props.")
                }

                // 2️⃣ Motor sliders shown horizontally in one line
                Row {
                    id: motorRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: ScreenTools.defaultFontPixelWidth * 3
                    enabled: safetySwitch.checked

                    // Each motor slider
                    Repeater {
                        id: sliderRepeater
                        model: controller.vehicle.motorCount == -1 ? 8 : controller.vehicle.motorCount

                        Column {
                            property alias motorSlider: slider
                            spacing: ScreenTools.defaultFontPixelHeight / 2
                            width: ScreenTools.defaultFontPixelWidth * 10

                            QGCLabel {
                                text: controller.vehicle.motorIndexToLetter
                                      ? controller.vehicle.motorIndexToLetter(index)
                                      : "M" + (index + 1)
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                            }

                            QGCSlider {
                                id: slider
                                width: parent.width
                                orientation: Qt.Horizontal
                                from: 0
                                to: 100
                                stepSize: 1
                                value: 0
                                live: false

                                onValueChanged: {
                                    controller.vehicle.motorTest(
                                        index + 1, value,
                                        value == 0 ? 0 : _motorTimeoutSecs,
                                        true
                                    )
                                    if (value != 0) motorTimer.restart()
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
                    }

                    // "All" slider in same row
                    Column {
                        spacing: ScreenTools.defaultFontPixelHeight / 2
                        width: ScreenTools.defaultFontPixelWidth * 10

                        QGCLabel {
                            text: qsTr("All")
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        QGCSlider {
                            id: allSlider
                            width: parent.width
                            orientation: Qt.Horizontal
                            from: 0
                            to: 100
                            stepSize: 1
                            value: 0
                            live: false

                            onValueChanged: {
                                for (var sliderIndex = 0; sliderIndex < sliderRepeater.count; sliderIndex++) {
                                    sliderRepeater.itemAt(sliderIndex).motorSlider.value = allSlider.value
                                }
                            }
                        }
                    }
                }


                // 4️⃣ Safety switch + warning text (horizontal row)
                Row {
                    spacing: ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter: parent.horizontalCenter

                    Switch {
                        id: safetySwitch
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            if (!checked) {
                                for (var sliderIndex = 0; sliderIndex < sliderRepeater.count; sliderIndex++) {
                                    sliderRepeater.itemAt(sliderIndex).motorSlider.value = 0
                                }
                                allSlider.value = 0
                            }
                        }
                    }

                    QGCLabel {
                        anchors.verticalCenter: parent.verticalCenter
                        color: qgcPal.warningText
                        text: safetySwitch.checked ?
                                  qsTr("Careful: Motor sliders are enabled") :
                                  qsTr("Propellers are removed - Enable motor sliders")
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

} // SetupPage
