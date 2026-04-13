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
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools


SetupPage {
    id:             safetyPage
    pageComponent:  safetyPageComponent


property bool   showBorder:         true
    Component {
        id: safetyPageComponent

        ColumnLayout {
            id:         flowLayout
            width:      availableWidth
            //width:  flowLayout.width *0.8
            //spacing:    _margins
            Layout.fillWidth:   true
            anchors.horizontalCenter: parent.horizontalCenter


            FactPanelController { id: controller; }

            QGCPalette { id: ggcPal; colorGroupEnabled: true }

            property Fact _batt1Monitor:                    controller.getParameterFact(-1, "BATT_MONITOR")
            property Fact _batt2Monitor:                    controller.getParameterFact(-1, "BATT2_MONITOR", false /* reportMissing */)
            property bool _batt2MonitorAvailable:           controller.parameterExists(-1, "BATT2_MONITOR")
            property bool _batt1MonitorEnabled:             _batt1Monitor.rawValue !== 0
            property bool _batt2MonitorEnabled:             _batt2MonitorAvailable ? _batt2Monitor.rawValue !== 0 : false
            property bool _batt1ParamsAvailable:            controller.parameterExists(-1, "BATT_CAPACITY")
            property bool _batt2ParamsAvailable:            controller.parameterExists(-1, "BATT2_CAPACITY")

            property Fact _failsafeBatt1LowAct:             controller.getParameterFact(-1, "BATT_FS_LOW_ACT", false /* reportMissing */)
            property Fact _failsafeBatt2LowAct:             controller.getParameterFact(-1, "BATT2_FS_LOW_ACT", false /* reportMissing */)
            property Fact _failsafeBatt1CritAct:            controller.getParameterFact(-1, "BATT_FS_CRT_ACT", false /* reportMissing */)
            property Fact _failsafeBatt2CritAct:            controller.getParameterFact(-1, "BATT2_FS_CRT_ACT", false /* reportMissing */)
            property Fact _failsafeBatt1LowMah:             controller.getParameterFact(-1, "BATT_LOW_MAH", false /* reportMissing */)
            property Fact _failsafeBatt2LowMah:             controller.getParameterFact(-1, "BATT2_LOW_MAH", false /* reportMissing */)
            property Fact _failsafeBatt1CritMah:            controller.getParameterFact(-1, "BATT_CRT_MAH", false /* reportMissing */)
            property Fact _failsafeBatt2CritMah:            controller.getParameterFact(-1, "BATT2_CRT_MAH", false /* reportMissing */)
            property Fact _failsafeBatt1LowVoltage:         controller.getParameterFact(-1, "BATT_LOW_VOLT", false /* reportMissing */)
            property Fact _failsafeBatt2LowVoltage:         controller.getParameterFact(-1, "BATT2_LOW_VOLT", false /* reportMissing */)
            property Fact _failsafeBatt1CritVoltage:        controller.getParameterFact(-1, "BATT_CRT_VOLT", false /* reportMissing */)
            property Fact _failsafeBatt2CritVoltage:        controller.getParameterFact(-1, "BATT2_CRT_VOLT", false /* reportMissing */)

            property Fact _armingCheck: controller.getParameterFact(-1, "ARMING_CHECK")

            property real _margins:         ScreenTools.defaultFontPixelHeight
            property real _innerMargin:     _margins / 2
            property bool _showIcon:        !ScreenTools.isTinyScreen
            property bool _roverFirmware:   controller.parameterExists(-1, "MODE1") // This catches all usage of ArduRover firmware vehicle types: Rover, Boat...

            property bool _isNarrow:        flowLayout.width < ScreenTools.defaultFontPixelWidth * 60
            property real _urlFieldWidth:   ScreenTools.defaultFontPixelWidth * 30
            
            property string _restartRequired: qsTr("Requires vehicle reboot")

            Component {
                id: batteryFailsafeComponent

                GridLayout {
                    id:                 mainGrid
                    columns:            _isNarrow ? 1 : 2
                    columnSpacing:      _margins
                    rowSpacing:         _innerMargin
                    Layout.fillWidth:   true

                    QGCLabel {
                        text:           qsTr("Low action:")
                        font.bold:      true
                        color:          "black"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                    }
                    FactComboBox {
                        fact:           failsafeBattLowAct
                        indexModel:     false
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text:           qsTr("Critical action:")
                        font.bold:      true
                        color:          "black"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                    }
                    FactComboBox {
                        fact:           failsafeBattCritAct
                        indexModel:     false
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text:           qsTr("Low voltage threshold:")
                        font.bold:      true
                        color:          "black"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                    }
                    FactTextField {
                        fact:           failsafeBattLowVoltage
                        showUnits:      true
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text:           qsTr("Critical voltage threshold:")
                        font.bold:      true
                        color:          "black"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                    }
                    FactTextField {
                        fact:           failsafeBattCritVoltage
                        showUnits:      true
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text:           qsTr("Low mAh threshold:")
                        font.bold:      true
                        color:          "black"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                    }
                    FactTextField {
                        fact:           failsafeBattLowMah
                        showUnits:      true
                        Layout.fillWidth: true
                    }

                    QGCLabel {
                        text:           qsTr("Critical mAh threshold:")
                        font.bold:      true
                        color:          "black"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                    }
                    FactTextField {
                        fact:           failsafeBattCritMah
                        showUnits:      true
                        Layout.fillWidth: true
                    }
                } // ColumnLayout
            }

            Component {
                id: restartRequiredComponent

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCLabel {
                        text: _restartRequired
                        color: "white"
                    }

                    QGCButton {
                        text:       qsTr("Reboot vehicle")
                        onClicked:  controller.vehicle.rebootVehicle()
                    }
                }
            }

            Column {
                spacing: _margins
                Layout.fillWidth:   true
                visible: _batt1MonitorEnabled

                QGCLabel {
                    text:       qsTr("Battery1 Failsafe Triggers")
                    font.bold:   true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width:              mainGrid.implicitWidth + (_margins * 2)
                    height:             mainGrid.implicitHeight + (_margins * 2)
                    color:              "white"
                    border.color:       QGroundControl.globalPalette.groupBorder
                    border.width:       showBorder ? 1 : 0
                    radius:             ScreenTools.defaultFontPixelHeight / 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    Loader {
                        id:                 battery1FailsafeLoader
                        anchors.centerIn:   parent
                        sourceComponent:    _batt1ParamsAvailable ? batteryFailsafeComponent : restartRequiredComponent

                        property Fact battMonitor:              _batt1Monitor
                        property bool battParamsAvailable:      _batt1ParamsAvailable
                        property Fact failsafeBattLowAct:       _failsafeBatt1LowAct
                        property Fact failsafeBattCritAct:      _failsafeBatt1CritAct
                        property Fact failsafeBattLowMah:       _failsafeBatt1LowMah
                        property Fact failsafeBattCritMah:      _failsafeBatt1CritMah
                        property Fact failsafeBattLowVoltage:   _failsafeBatt1LowVoltage
                        property Fact failsafeBattCritVoltage:  _failsafeBatt1CritVoltage
                    }
                } // Rectangle
            } // Column - Battery Failsafe Settings


            Column {
                spacing: _margins
                Layout.fillWidth:   true
                visible: _batt2MonitorEnabled

                QGCLabel {
                    text:       qsTr("Battery2 Failsafe Triggers")
                    font.bold:   true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width:              mainGrid.implicitWidth + (_margins * 2)
                    height:             mainGrid.implicitHeight + (_margins * 2)
                    color:              "white"
                    border.color:       QGroundControl.globalPalette.groupBorder
                    border.width:       showBorder ? 1 : 0
                    radius:             ScreenTools.defaultFontPixelHeight / 2

                    Loader {
                        id:                 battery2FailsafeLoader
                        anchors.centerIn:   parent
                        sourceComponent:    _batt2ParamsAvailable ? batteryFailsafeComponent : restartRequiredComponent

                        property Fact battMonitor:              _batt2Monitor
                        property bool battParamsAvailable:      _batt2ParamsAvailable
                        property Fact failsafeBattLowAct:       _failsafeBatt2LowAct
                        property Fact failsafeBattCritAct:      _failsafeBatt2CritAct
                        property Fact failsafeBattLowMah:       _failsafeBatt2LowMah
                        property Fact failsafeBattCritMah:      _failsafeBatt2CritMah
                        property Fact failsafeBattLowVoltage:   _failsafeBatt2LowVoltage
                        property Fact failsafeBattCritVoltage:  _failsafeBatt2CritVoltage
                    }
                } // Rectangle
            } // Column - Battery Failsafe Settings

            Component {
                id: planeGeneralFS

                Column {
                    spacing: _margins
                    Layout.fillWidth:   true

                    property Fact _failsafeThrEnable:   controller.getParameterFact(-1, "THR_FAILSAFE")
                    property Fact _failsafeThrValue:    controller.getParameterFact(-1, "THR_FS_VALUE")
                    property Fact _failsafeGCSEnable:   controller.getParameterFact(-1, "FS_GCS_ENABL")

                    QGCLabel {
                        text:       qsTr("Failsafe Triggers")
                        font.bold:   true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:              Math.min(availableWidth - (_margins * 2), ScreenTools.defaultFontPixelWidth * 80)
                        height:             fsColumn.height + (_margins * 2)
                        color:              "white"
                        border.color:       QGroundControl.globalPalette.groupBorder
                        border.width:       showBorder ? 1 : 0
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        GridLayout {
                            id:                 fsColumn
                            x:                  _margins
                            y:                  _margins
                            width:              parent.width - (_margins * 2)
                            columns:            _isNarrow ? 1 : 2
                            columnSpacing:      _margins
                            rowSpacing:         _innerMargin

                            QGCCheckBox {
                                id:             throttleEnableCheckBox
                                text:           qsTr("Throttle PWM threshold:")
                                checked:        _failsafeThrEnable.value === 1
                                Layout.alignment: Qt.AlignVCenter
                                onClicked:      _failsafeThrEnable.value = (checked ? 1 : 0)
                            }

                            FactTextField {
                                fact:           _failsafeThrValue
                                showUnits:      true
                                enabled:        throttleEnableCheckBox.checked
                                Layout.fillWidth: true
                            }

                            QGCCheckBox {
                                text:           qsTr("GCS failsafe")
                                checked:        _failsafeGCSEnable.value != 0
                                Layout.columnSpan: _isNarrow ? 1 : 2
                                onClicked:      _failsafeGCSEnable.value = checked ? 1 : 0
                            }
                        }
                    } // Rectangle - Failsafe trigger settings
                } // Column - Failsafe trigger settings
            }

            Loader {
                sourceComponent: controller.vehicle.fixedWing ? planeGeneralFS : undefined
                Layout.fillWidth:   true
            }

            Component {
                id: roverGeneralFS

                Column {
                    spacing: _margins
                    Layout.fillWidth:   true

                    property Fact _failsafeGCSEnable:   controller.getParameterFact(-1, "FS_GCS_ENABLE")
                    property Fact _failsafeThrEnable:   controller.getParameterFact(-1, "FS_THR_ENABLE")
                    property Fact _failsafeThrValue:    controller.getParameterFact(-1, "FS_THR_VALUE")
                    property Fact _failsafeAction:      controller.getParameterFact(-1, "FS_ACTION")
                    property Fact _failsafeCrashCheck:  controller.getParameterFact(-1, "FS_CRASH_CHECK")

                    QGCLabel {
                        id:         failsafeLabel
                        text:       qsTr("Failsafe Triggers")
                        font.bold:   true
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 20
                        color: "black"
                    }

                    Rectangle {
                        id:                 failsafeSettings
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:              Math.min(availableWidth - (_margins * 2), ScreenTools.defaultFontPixelWidth * 80)
                        height:             fsGrid.height + (_margins * 2)
                        color:              "white"
                        border.color:       QGroundControl.globalPalette.groupBorder
                        border.width:       showBorder ? 1 : 0
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        GridLayout {
                            id:                 fsGrid
                            x:                  _margins
                            y:                  _margins
                            width:              parent.width - (_margins * 2)
                            columns:            _isNarrow ? 1 : 2
                            columnSpacing:      _margins
                            rowSpacing:         _innerMargin

                            QGCLabel {
                                text:           qsTr("Ground Station failsafe:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactComboBox {
                                fact:           _failsafeGCSEnable
                                indexModel:     false
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("Throttle failsafe:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactComboBox {
                                fact:           _failsafeThrEnable
                                indexModel:     false
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("PWM threshold:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactTextField {
                                fact:           _failsafeThrValue
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("Failsafe Crash Check:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactComboBox {
                                fact:           _failsafeCrashCheck
                                indexModel:     false
                                Layout.fillWidth: true
                            }
                        }
                    } // Rectangle - Failsafe Settings
                } // Column - Failsafe Settings
            }

            Loader {
                sourceComponent: _roverFirmware ? roverGeneralFS : undefined
                Layout.fillWidth:   true
            }

            Component {
                id: copterGeneralFS

                Column {
                    Layout.fillWidth:   true
                    spacing: _margins

                    property Fact _failsafeGCSEnable:               controller.getParameterFact(-1, "FS_GCS_ENABLE")
                    property Fact _failsafeBattLowAct:              controller.getParameterFact(-1, "r.BATT_FS_LOW_ACT", false /* reportMissing */)
                    property Fact _failsafeBattMah:                 controller.getParameterFact(-1, "r.BATT_LOW_MAH", false /* reportMissing */)
                    property Fact _failsafeBattVoltage:             controller.getParameterFact(-1, "r.BATT_LOW_VOLT", false /* reportMissing */)
                    property Fact _failsafeThrEnable:               controller.getParameterFact(-1, "FS_THR_ENABLE")
                    property Fact _failsafeThrValue:                controller.getParameterFact(-1, "FS_THR_VALUE")

                    QGCLabel {
                        text:       qsTr("General Failsafe Triggers")
                        font.pixelSize: 20
                                        color: "white"
                        font.bold:   true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:              Math.min(availableWidth - (_margins * 2), ScreenTools.defaultFontPixelWidth * 80)
                        height:             generalFailsafeGrid.height + (_margins * 2)
                        color:              "white"
                        border.color:       QGroundControl.globalPalette.groupBorder
                        border.width:       showBorder ? 1 : 0
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        GridLayout {
                            id:                 generalFailsafeGrid
                            x:                  _margins
                            y:                  _margins
                            width:              parent.width - (_margins * 2)
                            columns:            _isNarrow ? 1 : 2
                            columnSpacing:      _margins
                            rowSpacing:         _innerMargin

                            QGCLabel {
                                text:           qsTr("Ground Station failsafe:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactComboBox {
                                fact:           _failsafeGCSEnable
                                indexModel:     false
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("Throttle failsafe:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            QGCComboBox {
                                model:          [qsTr("Disabled"), qsTr("Always RTL"), qsTr("Continue with Mission in Auto Mode"), qsTr("Always Land")]
                                currentIndex:   _failsafeThrEnable.value
                                Layout.fillWidth: true
                                onActivated: (index) => { _failsafeThrEnable.value = index }
                            }

                            QGCLabel {
                                text:           qsTr("PWM threshold:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactTextField {
                                fact:           _failsafeThrValue
                                showUnits:      true
                                Layout.fillWidth: true
                            }
                        } // ColumnLayout
                    } // Rectangle - Failsafe Settings
                } // Column - General Failsafe Settings
            }

            Loader {
                sourceComponent: controller.vehicle.multiRotor ? copterGeneralFS : undefined
                Layout.fillWidth:   true
            }

            Component {
                id: copterGeoFence

                Column {
                    spacing: _margins
                    Layout.fillWidth:   true

                    property Fact _fenceAction: controller.getParameterFact(-1, "FENCE_ACTION")
                    property Fact _fenceAltMax: controller.getParameterFact(-1, "FENCE_ALT_MAX")
                    property Fact _fenceEnable: controller.getParameterFact(-1, "FENCE_ENABLE")
                    property Fact _fenceMargin: controller.getParameterFact(-1, "FENCE_MARGIN")
                    property Fact _fenceRadius: controller.getParameterFact(-1, "FENCE_RADIUS")
                    property Fact _fenceType:   controller.getParameterFact(-1, "FENCE_TYPE")

                    readonly property int _maxAltitudeFenceBitMask: 1
                    readonly property int _circleFenceBitMask:      2
                    readonly property int _polygonFenceBitMask:     4

                    QGCLabel {
                        text:           qsTr("GeoFence")
                        font.pixelSize: 20
                                        color: "black"
                        font.bold:      true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:              Math.min(availableWidth - (_margins * 2), ScreenTools.defaultFontPixelWidth * 80)
                        height:             mainLayout.height + (_margins * 2)
                        color:              "white"
                        border.color:       QGroundControl.globalPalette.groupBorder
                        border.width:       showBorder ? 1 : 0
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        GridLayout {
                            id:                 mainLayout
                            x:                  _margins
                            y:                  _margins
                            width:              parent.width - (_margins * 2)
                            columns:            _isNarrow ? 1 : 2
                            columnSpacing:      _margins
                            rowSpacing:         _innerMargin

                            FactCheckBox {
                                id:             enabledCheckBox
                                text:           qsTr("Enabled")
                                fact:           _fenceEnable
                                Layout.columnSpan: _isNarrow ? 1 : 2
                            }

                            QGCCheckBox {
                                text:           qsTr("Maximum Altitude")
                                checked:        _fenceType.rawValue & _maxAltitudeFenceBitMask
                                enabled:        enabledCheckBox.checked
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 30
                                onClicked: {
                                    if (checked) {
                                        _fenceType.rawValue |= _maxAltitudeFenceBitMask
                                    } else {
                                        _fenceType.value &= ~_maxAltitudeFenceBitMask
                                    }
                                }
                            }
                            FactTextField {
                                fact:           _fenceAltMax
                                enabled:        enabledCheckBox.checked && (_fenceType.rawValue & _maxAltitudeFenceBitMask)
                                Layout.fillWidth: true
                            }

                            QGCCheckBox {
                                text:           qsTr("Circle centered on Home")
                                checked:        _fenceType.rawValue & _circleFenceBitMask
                                enabled:        enabledCheckBox.checked
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 30
                                onClicked: {
                                    if (checked) {
                                        _fenceType.rawValue |= _circleFenceBitMask
                                    } else {
                                        _fenceType.value &= ~_circleFenceBitMask
                                    }
                                }
                            }
                            FactTextField {
                                fact:           _fenceRadius
                                showUnits:      true
                                enabled:        enabledCheckBox.checked && (_fenceType.rawValue & _circleFenceBitMask)
                                Layout.fillWidth: true
                            }

                            QGCCheckBox {
                                text:           qsTr("Inclusion/Exclusion Circles+Polygons")
                                checked:        _fenceType.rawValue & _polygonFenceBitMask
                                enabled:        enabledCheckBox.checked
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 30
                                onClicked: {
                                    if (checked) {
                                        _fenceType.rawValue |= _polygonFenceBitMask
                                    } else {
                                        _fenceType.value &= ~_polygonFenceBitMask
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }

                            QGCLabel {
                                text:           qsTr("Breach action")
                                color:          "black"
                                font.bold:      true
                                enabled:        enabledCheckBox.checked
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 30
                            }
                            FactComboBox {
                                fact:           _fenceAction
                                indexModel:     false
                                enabled:        enabledCheckBox.checked
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("Fence margin")
                                color:          "black"
                                font.bold:      true
                                enabled:        enabledCheckBox.checked
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 30
                            }
                            FactTextField {
                                fact:           _fenceMargin
                                enabled:        enabledCheckBox.checked
                                Layout.fillWidth: true
                            }
                        }
                    } // Rectangle - GeoFence Settings
                } // Column - GeoFence Settings
            }

            Loader {
                sourceComponent: controller.vehicle.multiRotor ? copterGeoFence : undefined
                Layout.fillWidth:   true
            }

            Component {
                id: copterRTL

                Column {
                    spacing: _margins
                    Layout.fillWidth:   true


                    property Fact _landSpeedFact:   controller.getParameterFact(-1, "LAND_SPEED")
                    property Fact _rtlAltFact:      controller.getParameterFact(-1, "RTL_ALT")
                    property Fact _rtlLoitTimeFact: controller.getParameterFact(-1, "RTL_LOIT_TIME")
                    property Fact _rtlAltFinalFact: controller.getParameterFact(-1, "RTL_ALT_FINAL")

                    QGCLabel {
                        id:             rtlLabel
                        text:           qsTr("Return to Launch")
                        font.bold:      true
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 20
                                        color: "white"
                    }

                    Rectangle {
                        id:     rtlSettings
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:              Math.min(availableWidth - (_margins * 2), ScreenTools.defaultFontPixelWidth * 80)
                        height:             rtlGrid.height + (_margins * 2)
                        color:              "white"
                        border.color:       QGroundControl.globalPalette.groupBorder
                        border.width:       showBorder ? 1 : 0
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        QGCColoredImage {
                            id:                 icon
                            visible:            _showIcon
                            anchors.margins:    _margins
                            anchors.left:       parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            height:             ScreenTools.defaultFontPixelWidth * 15
                            width:              ScreenTools.defaultFontPixelWidth * 15
                            color:              ggcPal.text
                            sourceSize.width:   width
                            mipmap:             true
                            fillMode:           Image.PreserveAspectFit
                            source:             "/qmlimages/ReturnToHomeAltitude.svg"
                        }

                        GridLayout {
                            id:                 rtlGrid
                            x:                  _showIcon ? icon.x + icon.width + _margins : _margins
                            y:                  _margins
                            width:              parent.width - (_showIcon ? icon.width + (_margins * 3) : (_margins * 2))
                            columns:            _isNarrow ? 1 : 2
                            columnSpacing:      _margins
                            rowSpacing:         _innerMargin

                            QGCRadioButton {
                                id:             returnAtCurrentRadio
                                text:           qsTr("Return at current altitude")
                                checked:        _rtlAltFact.value == 0
                                Layout.columnSpan: _isNarrow ? 1 : 2
                                onClicked:      _rtlAltFact.value = 0
                            }

                            QGCRadioButton {
                                id:             returnAltRadio
                                text:           qsTr("Return at specified altitude:")
                                checked:        _rtlAltFact.value != 0
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                                onClicked:      { _rtlAltFact.value = 3000; rltAltField.forceActiveFocus() }
                            }
                            FactTextField {
                                id:             rltAltField
                                fact:           _rtlAltFact
                                showUnits:      true
                                enabled:        returnAltRadio.checked
                                Layout.fillWidth: true
                            }

                            QGCCheckBox {
                                id:             homeLoiterCheckbox
                                checked:        _rtlLoitTimeFact.value > 0
                                text:           qsTr("Loiter above Home for:")
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                                onClicked:      _rtlLoitTimeFact.value = (checked ? 60 : 0)
                            }
                            FactTextField {
                                id:             landDelayField
                                fact:           _rtlLoitTimeFact
                                showUnits:      true
                                enabled:        homeLoiterCheckbox.checked
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("Final land stage altitude:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactTextField {
                                id:             rltAltFinalField
                                fact:           _rtlAltFinalFact
                                showUnits:      true
                                Layout.fillWidth: true
                            }

                            QGCLabel {
                                text:           qsTr("Final land stage descent speed:")
                                color:          "black"
                                font.bold:      true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                            }
                            FactTextField {
                                id:             landSpeedField
                                fact:           _landSpeedFact
                                showUnits:      true
                                Layout.fillWidth: true
                            }
                        }
                    } // Rectangle - RTL Settings
                } // Column - RTL Settings
            }

            Loader {
                sourceComponent: controller.vehicle.multiRotor ? copterRTL : undefined
                Layout.fillWidth:   true
            }

            Component {
                id: planeRTL

                Column {
                    spacing: _margins
                    Layout.fillWidth:   true

                    property Fact _rtlAltFact: {
                        if (controller.firmwareMajorVersion < 4 || (controller.firmwareMajorVersion === 4 && controller.firmwareMinorVersion < 5)) {
                            return controller.getParameterFact(-1, "ALT_HOLD_RTL")
                        } else {
                            return controller.getParameterFact(-1, "RTL_ALTITUDE")
                        }
                    }

                    QGCLabel {
                        text:           qsTr("Return to Launch")
                        font.bold:      true
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 20
                                        color: "white"
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width:              Math.min(availableWidth - (_margins * 2), ScreenTools.defaultFontPixelWidth * 80)
                        height:             planeRtlGrid.height + (_margins * 2)
                        color:              "white"
                        border.color:       QGroundControl.globalPalette.groupBorder
                        border.width:       showBorder ? 1 : 0
                        radius:             ScreenTools.defaultFontPixelHeight / 2

                        GridLayout {
                            id:                 planeRtlGrid
                            x:                  _margins
                            y:                  _margins
                            width:              parent.width - (_margins * 2)
                            columns:            _isNarrow ? 1 : 2
                            columnSpacing:      _margins
                            rowSpacing:         _innerMargin

                            QGCRadioButton {
                                id:             returnAtCurrentRadio
                                text:           qsTr("Return at current altitude")
                                checked:        _rtlAltFact.value < 0
                                Layout.columnSpan: _isNarrow ? 1 : 2
                                onClicked:      _rtlAltFact.value = -1
                            }

                            QGCRadioButton {
                                id:             returnAltRadio
                                text:           qsTr("Return at specified altitude:")
                                checked:        _rtlAltFact.value >= 0
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: _isNarrow ? -1 : ScreenTools.defaultFontPixelWidth * 25
                                onClicked:      { _rtlAltFact.value = 10000; rltAltField.forceActiveFocus() }
                            }
                            FactTextField {
                                id:             rltAltField
                                fact:           _rtlAltFact
                                showUnits:      true
                                enabled:        returnAltRadio.checked
                                Layout.fillWidth: true
                            }
                        }
                    } // Rectangle - RTL Settings
                } // Column - RTL Settings
            }

            Loader {
                sourceComponent: controller.vehicle.fixedWing ? planeRTL : undefined
                Layout.fillWidth:   true
            }

            Column {
                spacing: _margins
                Layout.fillWidth:   true

                QGCLabel {
                    text:           qsTr("Arming Checks")
                    font.bold:      true
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 20
                                    color: "white"
                }



                Rectangle {
                    width:  parent.width//flowLayout.width *0.8
                    height: armingCheckInnerColumn.height + (_margins * 2)
                    color:              "white"
                    border.color:       QGroundControl.globalPalette.groupBorder
                    border.width:       showBorder ? 1 : 0
                    radius:             ScreenTools.defaultFontPixelHeight / 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    ColumnLayout {
                        id:                 armingCheckInnerColumn
                        anchors.margins:    _margins
                        anchors.top:        parent.top
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing: _margins

                        FactBitmask {
                            id:                 armingCheckBitmask
                            Layout.fillWidth:   true
                            firstEntryIsAll:    true
                            fact:               _armingCheck
                        }

                        QGCLabel {
                            id:             armingCheckWarning
                            Layout.fillWidth:   true
                            wrapMode:       Text.WordWrap
                            color:          qgcPal.warningText
                            font.bold:      true
                            text:            qsTr("Warning: Turning off arming checks can lead to loss of Vehicle control.")
                            visible:        _armingCheck.value != 1
                        }
                    }
                } // Rectangle - Arming checks
            } // Column - Arming Checks
        } // Flow
    } // Component - safetyPageComponent

} // SetupView
