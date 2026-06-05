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

import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools

SetupPage {
    id:             cameraPage
    pageComponent:  cameraPageComponent

    Component {
        id: cameraPageComponent

        Column {
            spacing:    _margins
            width:      availableWidth

            FactPanelController { id: controller; }

            QGCPalette { id: qgcPal; colorGroupEnabled: true }

            property Fact _mountRetractX:       controller.getParameterFact(-1, "MNT_RETRACT_X")
            property Fact _mountRetractY:       controller.getParameterFact(-1, "MNT_RETRACT_Y")
            property Fact _mountRetractZ:       controller.getParameterFact(-1, "MNT_RETRACT_Z")

            property Fact _mountNeutralX:       controller.getParameterFact(-1, "MNT_NEUTRAL_X")
            property Fact _mountNeutralY:       controller.getParameterFact(-1, "MNT_NEUTRAL_Y")
            property Fact _mountNeutralZ:       controller.getParameterFact(-1, "MNT_NEUTRAL_Z")

            property Fact _mountRCInTilt:       controller.getParameterFact(-1, "MNT_RC_IN_TILT")
            property Fact _mountStabTilt:       controller.getParameterFact(-1, "MNT_STAB_TILT")
            property Fact _mountAngMinTilt:     controller.getParameterFact(-1, "MNT_ANGMIN_TIL")
            property Fact _mountAngMaxTilt:     controller.getParameterFact(-1, "MNT_ANGMAX_TIL")

            property Fact _mountRCInRoll:       controller.getParameterFact(-1, "MNT_RC_IN_ROLL")
            property Fact _mountStabRoll:       controller.getParameterFact(-1, "MNT_STAB_ROLL")
            property Fact _mountAngMinRoll:     controller.getParameterFact(-1, "MNT_ANGMIN_ROL")
            property Fact _mountAngMaxRoll:     controller.getParameterFact(-1, "MNT_ANGMAX_ROL")

            property Fact _mountRCInPan:        controller.getParameterFact(-1, "MNT_RC_IN_PAN")
            property Fact _mountStabPan:        controller.getParameterFact(-1, "MNT_STAB_PAN")
            property Fact _mountAngMinPan:      controller.getParameterFact(-1, "MNT_ANGMIN_PAN")
            property Fact _mountAngMaxPan:      controller.getParameterFact(-1, "MNT_ANGMAX_PAN")

            property Fact _rc5Function:         controller.getParameterFact(-1, "SERVO5_FUNCTION")
            property Fact _rc6Function:         controller.getParameterFact(-1, "SERVO6_FUNCTION")
            property Fact _rc7Function:         controller.getParameterFact(-1, "SERVO7_FUNCTION")
            property Fact _rc8Function:         controller.getParameterFact(-1, "SERVO8_FUNCTION")
            property Fact _rc9Function:         controller.getParameterFact(-1, "SERVO9_FUNCTION")
            property Fact _rc10Function:        controller.getParameterFact(-1, "SERVO10_FUNCTION")
            property Fact _rc11Function:        controller.getParameterFact(-1, "SERVO11_FUNCTION")
            property Fact _rc12Function:        controller.getParameterFact(-1, "SERVO12_FUNCTION")
            property Fact _rc13Function:        controller.getParameterFact(-1, "SERVO13_FUNCTION")
            property Fact _rc14Function:        controller.getParameterFact(-1, "SERVO14_FUNCTION")

            property bool _tiltEnabled:         false
            property bool _panEnabled:          false
            property bool _rollEnabled:         false

            property bool _servoReverseIsBool:  controller.parameterExists(-1, "RC5_REVERSED")

            // Gimbal Settings not available on older firmware
            property bool _showGimbaLSettings:  controller.parameterExists(-1, "MNT_DEFLT_MODE")

            readonly property real  _margins:                       ScreenTools.defaultFontPixelHeight
            readonly property int   _rcFunctionDisabled:            0
            readonly property int   _rcFunctionMountPan:            6
            readonly property int   _rcFunctionMountTilt:           7
            readonly property int   _rcFunctionMountRoll:           8
            readonly property int   _firstGimbalOutChannel:         5
            readonly property int   _lastGimbalOutChannel:          14
            readonly property int   _mountDefaultModeRCTargetting:  3

            Component.onCompleted: {
                if (_showGimbaLSettings) {
                    gimbalSettingsLoader.sourceComponent = gimbalSettings
                }
                calcGimbalOutValues()
            }

            function setGimbalSettingsServoInfo(loader, channel) {
                var rcPrefix = "SERVO" + channel + "_"

                loader.gimbalOutIndex = channel - 4
                loader.servoPWMMinFact = controller.getParameterFact(-1, rcPrefix + "MIN")
                loader.servoPWMMaxFact = controller.getParameterFact(-1, rcPrefix + "MAX")
                loader.servoReverseFact = controller.getParameterFact(-1, rcPrefix + "REVERSED")
            }

            /// Gimbal output channels are stored in SERVO#_FUNCTION parameters. We need to loop through those
            /// to find them and setup the ui accordindly.
            function calcGimbalOutValues() {
                gimbalDirectionTiltLoader.gimbalOutIndex = 0
                gimbalDirectionPanLoader.gimbalOutIndex = 0
                gimbalDirectionRollLoader.gimbalOutIndex = 0
                _tiltEnabled = false
                _panEnabled = false
                _rollEnabled = false
                for (var channel=_firstGimbalOutChannel; channel<=_lastGimbalOutChannel; channel++) {
                    var functionFact = controller.getParameterFact(-1, "SERVO" + channel + "_FUNCTION")
                    if (functionFact.value == _rcFunctionMountTilt) {
                        _tiltEnabled = true
                        setGimbalSettingsServoInfo(gimbalDirectionTiltLoader, channel)
                    } else if (functionFact.value == _rcFunctionMountPan) {
                        _panEnabled = true
                        setGimbalSettingsServoInfo(gimbalDirectionPanLoader, channel)
                    } else if (functionFact.value == _rcFunctionMountRoll) {
                        _rollEnabled = true
                        setGimbalSettingsServoInfo(gimbalDirectionRollLoader, channel)
                    }
                }
            }

            function setRCFunction(channel, rcFunction) {
                // First clear any previous settings for this function
                for (var index=_firstGimbalOutChannel; index<=_lastGimbalOutChannel; index++) {
                    var functionFact = controller.getParameterFact(-1, "SERVO" + index + "_FUNCTION")
                    if (functionFact.value != _rcFunctionDisabled && functionFact.value == rcFunction) {
                        functionFact.value = _rcFunctionDisabled
                    }
                }

                // Now set the function into the new channel
                if (channel != 0) {
                    var functionFact = controller.getParameterFact(-1, "SERVO" + channel + "_FUNCTION")
                    functionFact.value = rcFunction
                }
            }

            // Whenever any SERVO#_FUNCTION parameters changes we need to go looking for gimbal output channels again
            Connections { target: _rc5Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc6Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc7Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc8Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc9Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc10Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc11Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc12Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc13Function; onValueChanged: calcGimbalOutValues() }
            Connections { target: _rc14Function; onValueChanged: calcGimbalOutValues() }

            // Whenever an MNT_RC_IN_* setting is changed make sure to turn on RC targeting
            Connections {
                target:         _mountRCInPan
                onValueChanged: _mountDefaultMode.value = _mountDefaultModeRCTargetting
            }

            Connections {
                target:         _mountRCInRoll
                onValueChanged: _mountDefaultMode.value = _mountDefaultModeRCTargetting
            }

            Connections {
                target:         _mountRCInTilt
                onValueChanged: _mountDefaultMode.value = _mountDefaultModeRCTargetting
            }

            ListModel {
                id: gimbalOutModel
                // It appears that QGCComboBox can't handle models that don't have a initial item
                // after onModelChanged
                ListElement { text: qsTr("Disabled"); value: 0 }

                function update(number) {
                    // Not enough channels
                    if(number < 6) {
                        return
                    }
                    for(var i = 5; i <= number; i++) {
                        var text = qsTr("Channel ") + i
                        append({"text": text, "value": i})
                    }
                }

                Component.onCompleted: {
                    // Number of main outputs
                    var baseValue = 8
                    // Extra outputs
                    // http://ardupilot.org/copter/docs/parameters.html#brd-pwm-count-auxiliary-pin-config
                    var brd_pwm_count_value = controller.getParameterFact(-1, "BRD_PWM_COUNT").value
                    update(8 + (brd_pwm_count_value == 7 ? 3 : brd_pwm_count_value))
                }
            }

            Component {
                id: gimbalDirectionSettings

                // The following properties must be set in the Loader
                //      property string directionTitle
                //      property bool directionEnabled
                //      property int gimbalOutIndex
                //      property Fact mountRcInFact
                //      property Fact mountStabFact
                //      property Fact mountAngMinFact
                //      property Fact mountAngMaxFact
                //      property Fact servoPWMMinFact
                //      property Fact servoPWMMaxFact
                //      property Fact servoReverseFact
                //      property bool servoReverseIsBool
                //      property int rcFunction

                Column {
                    spacing: _margins / 2

                    QGCLabel {
                        id:         directionLabel
                        text:       qsTr("Gimbal ") + directionTitle
                        font.bold:   true
                        color:      "black"
                    }

                    Rectangle {
                        id:                 rectangle
                        width:              innerColumn.width + (_margins * 2)
                        height:             innerColumn.height + (_margins * 2)
                        color:              "white"
                        border.color:       "black"
                        border.width:       1
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        Column {
                            id:                 innerColumn
                            anchors.margins:    _margins
                            anchors.top:        parent.top
                            anchors.left:       parent.left
                            spacing:            _margins

                            Row {
                                spacing: _margins
                                QGCLabel {
                                    id:                 gimbalOutLabel
                                    anchors.baseline:   gimbalOutCombo.baseline
                                    text:               qsTr("Output channel:")
                                    color:              "black"
                                    font.bold:          true
                                }

                                QGCComboBox {
                                    id:                 gimbalOutCombo
                                    width:              ScreenTools.defaultFontPixelWidth * 12
                                    model:              gimbalOutModel
                                    textRole:           "text"
                                    currentIndex:       gimbalOutIndex

                                    onActivated: (index) => { setRCFunction(gimbalOutModel.get(index).value, rcFunction) }
                                }
                            }

                            Row {
                                spacing: _margins
                                enabled: directionEnabled

                                QGCLabel {
                                    id:                 mountRcInLabel
                                    anchors.baseline:   mountRcInCombo.baseline
                                    text:               qsTr("Input channel:")
                                    color:              "black"
                                    font.bold:          true
                                }

                                FactComboBox {
                                    id:                 mountRcInCombo
                                    width:              ScreenTools.defaultFontPixelWidth * 12
                                    fact:               mountRcInFact
                                    indexModel:         false
                                }
                            }

                            Row {
                                spacing: _margins
                                enabled: directionEnabled

                                FactCheckBox {
                                    id:                 mountStabCheckBox
                                    text:               qsTr("Stabilize")
                                    fact:               mountStabFact
                                    checkedValue:       1
                                    uncheckedValue:     0
                                }

                                FactCheckBox {
                                    id:                 servoReverseCheckBox
                                    text:               qsTr("Servo reverse")
                                    checkedValue:       _servoReverseIsBool ? 1 : -1
                                    uncheckedValue:     _servoReverseIsBool ? 0 : 1
                                    fact:               servoReverseFact

                                    property bool _servoReverseIsBool: servoReverseIsBool
                                }
                            }

                            Row {
                                id:                 angleLimitRow
                                spacing:            _margins
                                enabled:            directionEnabled
                                property var _labelBaseline: mountAngMinField.baseline

                                QGCLabel {
                                    id:                 mountAngLabel
                                    anchors.baseline:   angleLimitRow._labelBaseline
                                    text:               qsTr("Gimbal angle limits:")
                                    color:              "black"
                                    font.bold:          true
                                }

                                QGCLabel {
                                    id:                 mountAngMinLabel
                                    anchors.baseline:   angleLimitRow._labelBaseline
                                    text:               qsTr("min")
                                    color:              "black"
                                }

                                FactTextField {
                                    id:                 mountAngMinField
                                    fact:               mountAngMinFact
                                }

                                QGCLabel {
                                    id:                 mountAngMaxLabel
                                    anchors.baseline:   angleLimitRow._labelBaseline
                                    text:               qsTr("max")
                                    color:              "black"
                                }

                                FactTextField {
                                    id:                 mountAngMaxField
                                    fact:               mountAngMaxFact
                                }
                            }

                            Row {
                                id:                 servoLimitRow
                                spacing:            _margins
                                enabled:            directionEnabled
                                property var _labelBaseline: servoPWMMinField.baseline

                                QGCLabel {
                                    id:                 servoPWMLabel
                                    anchors.baseline:   servoLimitRow._labelBaseline
                                    text:               qsTr("Servo PWM limits:")
                                    color:              "black"
                                    font.bold:          true
                                }

                                QGCLabel {
                                    id:                 servoPWMMinLabel
                                    anchors.baseline:   servoLimitRow._labelBaseline
                                    text:               qsTr("min")
                                    color:              "black"
                                }

                                FactTextField {
                                    id:                 servoPWMMinField
                                    fact:               servoPWMMinFact
                                }

                                QGCLabel {
                                    id:                 servoPWMMaxLabel
                                    anchors.baseline:   servoLimitRow._labelBaseline
                                    text:               qsTr("max")
                                    color:              "black"
                                }

                                FactTextField {
                                    id:                 servoPWMMaxField
                                    fact:               servoPWMMaxFact
                                }
                            }
                        } // Column
                    } // Rectangle
                } // Column
            } // Component - gimbalDirectionSettings

            Component {
                id: gimbalSettings

                Column {
                    spacing: _margins / 2

                    property Fact _mountDefaultMode:    controller.getParameterFact(-1, "MNT_DEFLT_MODE")
                    property Fact _mountType:           controller.getParameterFact(-1, "MNT_TYPE")

                    QGCLabel {
                        id:             settingsLabel
                        text:           qsTr("Gimbal Settings")
                        font.bold:      true
                        color:          "black"
                    }

                    Rectangle {
                        id:                 rectangle
                        width:              innerColumn.width + (_margins * 2)
                        height:             innerColumn.height + (_margins * 2)
                        color:              "white"
                        border.color:       "black"
                        border.width:       1
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        Column {
                            id:                 innerColumn
                            anchors.margins:    _margins
                            anchors.top:        parent.top
                            anchors.left:       parent.left
                            spacing:            _margins

                            Row {
                                spacing: _margins
                                QGCLabel {
                                    id:                 gimbalTypeLabel
                                    anchors.baseline:   gimbalTypeCombo.baseline
                                    text:               qsTr("Type:")
                                    color:              "black"
                                    font.bold:          true
                                }

                                FactComboBox {
                                    id:                 gimbalTypeCombo
                                    width:              ScreenTools.defaultFontPixelWidth * 15
                                    fact:               _mountType
                                    indexModel:         false
                                }
                            }

                            QGCLabel {
                                id:                     rebootLabel
                                width:                  ScreenTools.defaultFontPixelWidth * 30
                                wrapMode:               Text.WordWrap
                                text:                   qsTr("Gimbal Type changes takes affect next reboot of autopilot")
                                color:                  "black"
                            }

                            Row {
                                spacing: _margins
                                QGCLabel {
                                    id:                 gimbalModeLabel
                                    anchors.baseline:   gimbalModeCombo.baseline
                                    text:               qsTr("Default Mode:")
                                    color:              "black"
                                    font.bold:          true
                                }

                                FactComboBox {
                                    id:                 gimbalModeCombo
                                    width:              ScreenTools.defaultFontPixelWidth * 15
                                    fact:               _mountDefaultMode
                                    indexModel:         false
                                }
                            }
                        } // Column
                    } // Rectangle
                } // Column
            } // Component - gimbalSettings

            Loader {
                id:                 gimbalDirectionTiltLoader
                sourceComponent:    gimbalDirectionSettings

                property string directionTitle:     qsTr("Tilt")
                property bool   directionEnabled:   _tiltEnabled
                property int    gimbalOutIndex:     0
                property Fact   mountRcInFact:      _mountRCInTilt
                property Fact   mountStabFact:      _mountStabTilt
                property Fact   mountAngMinFact:    _mountAngMinTilt
                property Fact   mountAngMaxFact:    _mountAngMaxTilt
                property Fact   servoPWMMinFact:    Fact { }
                property Fact   servoPWMMaxFact:    Fact { }
                property Fact   servoReverseFact:   Fact { }
                property bool   servoReverseIsBool: _servoReverseIsBool
                property int    rcFunction:         _rcFunctionMountTilt
            }

            Loader {
                id:                 gimbalDirectionRollLoader
                sourceComponent:    gimbalDirectionSettings

                property string directionTitle:     qsTr("Roll")
                property bool   directionEnabled:   _rollEnabled
                property int    gimbalOutIndex:     0
                property Fact   mountRcInFact:      _mountRCInRoll
                property Fact   mountStabFact:      _mountStabRoll
                property Fact   mountAngMinFact:    _mountAngMinRoll
                property Fact   mountAngMaxFact:    _mountAngMaxRoll
                property Fact   servoPWMMinFact:    Fact { }
                property Fact   servoPWMMaxFact:    Fact { }
                property Fact   servoReverseFact:   Fact { }
                property bool   servoReverseIsBool: _servoReverseIsBool
                property int    rcFunction:         _rcFunctionMountRoll
            }

            Loader {
                id:                 gimbalDirectionPanLoader
                sourceComponent:    gimbalDirectionSettings

                property string directionTitle:     qsTr("Pan")
                property bool   directionEnabled:   _panEnabled
                property int    gimbalOutIndex:     0
                property Fact   mountRcInFact:      _mountRCInPan
                property Fact   mountStabFact:      _mountStabPan
                property Fact   mountAngMinFact:    _mountAngMinPan
                property Fact   mountAngMaxFact:    _mountAngMaxPan
                property Fact   servoPWMMinFact:    Fact { }
                property Fact   servoPWMMaxFact:    Fact { }
                property Fact   servoReverseFact:   Fact { }
                property bool   servoReverseIsBool: _servoReverseIsBool
                property int    rcFunction:         _rcFunctionMountPan
            }

            Loader {
                id: gimbalSettingsLoader
            }
        } // Column
    } // Component
} // SetupPage
