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

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.UTMSP

Rectangle {
    id:         _root
    width:      ScreenTools.defaultFontPixelWidth * 35
    height: Math.max(320, mainLayout.implicitHeight + 60)
    radius:     20//ScreenTools.defaultFontPixelWidth / 2
    color: "#CCFFFFFF"
    visible:    _utmspEnabled === true ? utmspSliderTrigger: false
    border.width: 2//width * 0.05
    border.color: "#301934"
    anchors.centerIn: parent

    property var    guidedController
    property var    guidedValueSlider
    property string title                                       // Currently unused
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth / 2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    // Properties of UTM adapter
    property bool   utmspSliderTrigger
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported

    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            slider.focus = true
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    // Close Button
        Rectangle {
            id: closeButton

            width: 40
            height: 40
            radius: 20
            color: "#E53935"

            anchors {
                top: parent.top
                right: parent.right
                topMargin: -10
                rightMargin: -10
            }

            z: 999

            QGCColoredImage {
                anchors.fill: parent
                anchors.margins: 10
                source: "/res/XDelete.svg"
                fillMode: Image.PreserveAspectFit
                color: "white"
            }

            QGCMouseArea {
                fillItem: parent
                onClicked: confirmCancelled()
            }
        }


    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        guidedValueSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    QGCPalette { id: qgcPal }

    ColumnLayout {
        id: mainLayout

            anchors.centerIn: parent
            width: parent.width - 40

            spacing: 20

            QGCLabel {
                    id: messageText

                    Layout.fillWidth: true

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    wrapMode: Text.WordWrap

                    font.pointSize: ScreenTools.defaultFontPointSize + 2
                    font.bold: true

                    color: "#222222"
                }

                QGCCheckBox {
                    id: optionCheckBox

                    Layout.alignment: Qt.AlignHCenter

                    text: ""
                    visible: text !== ""
                }


            Item {
                        Layout.fillWidth: true
                        width: 120
                                height: 120

                        Rectangle {
                            id: circularButton
                            width: 100
                            height: 100
                            radius: 50
                            color: "white"
                            border.color: "#301934"
                            border.width: 2
                            anchors.centerIn: parent

                                QGCLabel {
                                    id: messageText12
                                    anchors.centerIn: parent
                                       horizontalAlignment: Text.AlignHCenter
                                       verticalAlignment: Text.AlignVCenter
                                    wrapMode:               Text.WordWrap
                                    font.pointSize:         ScreenTools.defaultFontPointSize
                                    font.bold:              true
                                    color: "black"
                                    text:       qsTr("Press & Hold")
                                }

                            MouseArea {
                                id: holdArea
                                anchors.fill: parent
                                hoverEnabled: true

                                onPressed: progressTimer.start()
                                onReleased: {
                                    progressTimer.stop()
                                    progressState.value = 0
                                    progressCircle.requestPaint()
                                }
                                onEntered: circularButton.color = "#ccccff"
                                onExited: circularButton.color = "white"
                            }

                            Canvas {
                                id: progressCircle
                                anchors.fill: parent

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.arc(width / 2, height / 2, 35, -Math.PI / 2, (2 * Math.PI * progressState.value) - Math.PI / 2, false)
                                    ctx.lineWidth = 6
                                    ctx.strokeStyle = "#301934"
                                    ctx.stroke()
                                }
                            }
                        }


                    }

                    Timer {
                        id: progressTimer
                        interval: 100
                        repeat: true
                        onTriggered: {
                            if (progressState.value < 1.0) {
                                progressState.value += 0.1
                                progressCircle.requestPaint()
                            } else {
                                progressTimer.stop()
                                progressState.value = 0
                                progressCircle.requestPaint()

                                console.log("QGCLabel clicked")


                                _root.visible = false
                                var sliderOutputValue = 0
                                if (guidedValueSlider.visible) {
                                    sliderOutputValue = guidedValueSlider.getOutputValue()
                                    guidedValueSlider.visible = false
                                }
                                hideTrigger = false
                                guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                                if (mapIndicator) {
                                    mapIndicator.actionConfirmed()
                                    mapIndicator = undefined
                                }

                                UTMSPStateStorage.indicatorOnMissionStatus = true
                                UTMSPStateStorage.currentNotificationIndex = 7
                                UTMSPStateStorage.currentStateIndex = 3
                            }
                        }
                    }

            SliderSwitch {
                id:                 slider
                confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
                Layout.fillWidth:   true
                enabled: _utmspEnabled === true? utmspSliderTrigger : true
                opacity: if(_utmspEnabled){utmspSliderTrigger === true ? 1 : 0.5} else{1}


                onAccept: {

                    console.log("QGCLabel clicked")


                    _root.visible = false
                    var sliderOutputValue = 0
                    if (guidedValueSlider.visible) {
                        sliderOutputValue = guidedValueSlider.getOutputValue()
                        guidedValueSlider.visible = false
                    }
                    hideTrigger = false
                    guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                    if (mapIndicator) {
                        mapIndicator.actionConfirmed()
                        mapIndicator = undefined
                    }

                    UTMSPStateStorage.indicatorOnMissionStatus = true
                    UTMSPStateStorage.currentNotificationIndex = 7
                    UTMSPStateStorage.currentStateIndex = 3
                }
            }



    }
}
