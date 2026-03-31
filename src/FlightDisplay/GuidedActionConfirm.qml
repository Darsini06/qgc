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
    height:     mainLayout.height + (_margins * 2)
    radius:     20//ScreenTools.defaultFontPixelWidth / 2
    color:      "white"
    visible:    _utmspEnabled === true ? utmspSliderTrigger: false
    border.width: 2//width * 0.05
    border.color: "#301934"

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

        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: "red"//qgcPal.primaryButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4

            QGCColoredImage {
                anchors.margins: 10
                anchors.fill: parent
                source: "/res/XDelete.svg"
                fillMode: Image.PreserveAspectFit
                color: "white"//qgcPal.text
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
        id:                 mainLayout
        anchors.centerIn:   parent
        width:              parent.width - (_margins * 2)
        spacing:            _margins

        QGCLabel {
            id:                     messageText
            Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            font.pointSize:         ScreenTools.defaultFontPointSize
            font.bold:              true
            color:"black"
        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth

            Item {
                        Layout.fillWidth: true
                        height: 100

                        Rectangle {
                            id: circularButton
                            width: 100
                            height: 100
                            radius: 50
                            color: "white"
                            border.color: "#301934"
                            border.width: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter

                                QGCLabel {
                                    id:                     messageText12
                                    anchors.centerIn: parent
                                       horizontalAlignment: Text.AlignHCenter
                                       verticalAlignment: Text.AlignVCenter
                                    wrapMode:               Text.WordWrap
                                    font.pointSize:         ScreenTools.defaultFontPointSize
                                    font.bold:              true
                                    color: "black"
                                    text:       qsTr("Press here")
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
                                width: parent.width
                                height: parent.height
                                anchors.centerIn: parent

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

            Rectangle {
                height: slider.height * 0.75
                width:  height
                radius: height / 2
                color:  "#301934"

                QGCColoredImage {
                    anchors.margins:    parent.height / 4
                    anchors.fill:       parent
                    source:             "/res/XDelete.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              "white"
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  confirmCancelled()
                }
            }
        }
    }
}
