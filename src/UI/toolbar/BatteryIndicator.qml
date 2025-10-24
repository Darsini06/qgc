/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import MAVLink

//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    //width:          batteryIndicatorRow.width

    property bool       showIndicator:      true
    property bool       waitForParameters:  false   // UI won't show until parameters are ready
    property Component  expandedPageComponent

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property Fact   _indicatorDisplay:  QGroundControl.settingsManager.batteryIndicatorSettings.display
    property bool   _showPercentage:    _indicatorDisplay.rawValue === 0
    property bool   _showVoltage:       _indicatorDisplay.rawValue === 1
    property bool   _showBoth:          _indicatorDisplay.rawValue === 2
property real lastPercentage : 100  // Keep it global so it's preserved
    // Fetch battery settings
    property var batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings

    // Properties to hold the thresholds
    property int threshold1: batterySettings.threshold1.rawValue
    property int threshold2: batterySettings.threshold2.rawValue

    // Control visibility based on battery state display setting
    property bool batteryState: batterySettings.battery_state_display.rawValue
    property bool threshold1visible: batterySettings.threshold1visible.rawValue
    property bool threshold2visible: batterySettings.threshold2visible.rawValue

    // In your batterySettings properties:
    property int cellCount: batterySettings.cellCount.rawValue
    property real fullVoltagePerCell: batterySettings.fullVoltagePerCell.rawValue
    property real emptyVoltagePerCell: batterySettings.emptyVoltagePerCell.rawValue

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Repeater {
            model: _activeVehicle ? _activeVehicle.batteries : 0

            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                sourceComponent:    batteryVisual

                property var battery: object
            }
        }
    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorDrawer(batteryPopup, control)
        }
    }

    Component {
        id: batteryPopup

        ToolIndicatorPage {
            showExpand:         expandedComponent ? true : false
            waitForParameters:  control.waitForParameters
            contentComponent:   batteryContentComponent
            expandedComponent:  batteryExpandedComponent
        }
    }

    Component {
        id: batteryVisual

        Row {
            anchors.top:    parent.top
                        anchors.bottom: parent.bottom

                        function calculatePercentageFromVoltage() {
                            if (isNaN(battery.voltage.rawValue)) return NaN;

                            var cellCount = control.cellCount > 0 ? control.cellCount : 3; // fallback if undefined
                            var fullVoltage = control.fullVoltagePerCell > 0 ? control.fullVoltagePerCell : 4.2;
                            var emptyVoltage = control.emptyVoltagePerCell > 0 ? control.emptyVoltagePerCell : 3.0;

                            var cellVoltage = battery.voltage.rawValue / cellCount;
                            var percentage = (cellVoltage - emptyVoltage) / (fullVoltage - emptyVoltage) * 100;

                            // Clamp between 0-100%
                            return Math.max(0, Math.min(100, percentage));
                        }

                        // function calculatePercentageFromVoltage() {
                        //     if (isNaN(battery.voltage.rawValue)) return NaN;

                        //     // Example for 3S LiPo (adjust these values for your battery)
                        //     var cellCount = 3; // Change this to match your battery
                        //     var fullVoltagePerCell = 4.2;
                        //     var emptyVoltagePerCell = 3.0;

                        //     var cellVoltage = battery.voltage.rawValue / cellCount;
                        //     var percentage = (cellVoltage - emptyVoltagePerCell) / (fullVoltagePerCell - emptyVoltagePerCell) * 100;

                        //     // Clamp between 0-100%
                        //     return Math.max(0, Math.min(100, percentage));
                        // }

                        function getBatteryColor() {
                            var percentage = !isNaN(battery.percentRemaining.rawValue)
                                           ? battery.percentRemaining.rawValue
                                           : calculatePercentageFromVoltage();

                            if (isNaN(percentage)) {
                                return "white"; // Unknown state
                            }

                            switch (battery.chargeState.rawValue) {
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                                    if (percentage > threshold1) return qgcPal.colorGreen;
                                    else if (percentage > threshold2) return qgcPal.colorYellowGreen;
                                    else return qgcPal.colorYellow;
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW: return qgcPal.colorOrange;
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                                    return qgcPal.colorRed;
                                default: return "white";
                            }
                        }

            // function getBatteryColor() {
            //     switch (battery.chargeState.rawValue) {
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
            //             if (!isNaN(battery.percentRemaining.rawValue)) {
            //                 if (battery.percentRemaining.rawValue > threshold1) {
            //                     return qgcPal.colorGreen
            //                 } else if (battery.percentRemaining.rawValue > threshold2) {
            //                     return qgcPal.colorYellowGreen
            //                 } else {
            //                     return qgcPal.colorYellow
            //                 }
            //             } else {
            //                 return "black"
            //             }
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
            //             return qgcPal.colorOrange
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
            //             return qgcPal.colorRed
            //         default:
            //             return "black"
            //     }
            // }


                        function getBatterySvgSource() {
                            const threshold1 = 100
                            const threshold2 = 40

                            if (!isNaN(battery.voltage.rawValue)) {
                                const voltage = battery.voltage.rawValue
                                const cellCount = battery.cellCount > 0 ? battery.cellCount : 3
                                const percentage = getBatteryPercentageFromVoltage(voltage, cellCount)

                                if (percentage > threshold1) {
                                    return "/qmlimages/BatteryGreen.svg"
                                } else if (percentage > threshold2) {
                                    return "/qmlimages/BatteryYellowGreen.svg"
                                } else if (percentage > 15) {
                                    return "/qmlimages/BatteryYellow.svg"
                                } else {
                                    return "/qmlimages/BatteryCritical.svg"
                                }
                            }

                            // Fallback to chargeState
                            switch (battery.chargeState.rawValue) {
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                                    return "/qmlimages/BatteryOrange.svg"
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                                    return "/qmlimages/BatteryCritical.svg"
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                                case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                                    return "/qmlimages/BatteryEMERGENCY.svg"
                                default:
                                    return "/qmlimages/Battery.svg"
                            }
                        }



            // function getBatterySvgSource() {

            //     switch (battery.chargeState.rawValue) {
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
            //             if (!isNaN(battery.percentRemaining.rawValue)) {
            //                 if (battery.percentRemaining.rawValue > threshold1) {
            //                     return "/qmlimages/BatteryGreen.svg"
            //                 } else if (battery.percentRemaining.rawValue > threshold2) {
            //                     return "/qmlimages/BatteryYellowGreen.svg"
            //                 } else {
            //                     return "/qmlimages/BatteryYellow.svg"
            //                 }
            //             }
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
            //             return "/qmlimages/BatteryOrange.svg" // Low with orange svg
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
            //             return "/qmlimages/BatteryCritical.svg" // Critical with red svg
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
            //         case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
            //             return "/qmlimages/BatteryEMERGENCY.svg" // Exclamation mark
            //         default:
            //             return "/qmlimages/Battery.svg" // Fallback if percentage is unavailable
            //     }
            // }




                        function getBatteryPercentageFromVoltage(voltage) {
                            const minVoltage = 9.6
                            const maxVoltage = 12.6

                            if (voltage < minVoltage) {
                                lastPercentage = -1
                                return -1  // Voltage too low
                            }

                            var currentPercentage = ((voltage - minVoltage) / (maxVoltage - minVoltage)) * 100
                            currentPercentage = Math.max(0, Math.min(100, currentPercentage))
                            currentPercentage = Math.floor(currentPercentage)  // Round down

                            // Only allow percentage to drop
                            if (currentPercentage < lastPercentage) {
                                lastPercentage = currentPercentage
                            }

                            return lastPercentage
                        }

                        function resetBatteryPercentage() {
                            lastPercentage = 100
                        }


            // function getBatteryPercentageFromVoltage(voltage) {
            //     if (voltage >= 12.60) return 100
            //     else if (voltage >= 12.45) return 95
            //     else if (voltage >= 12.30) return 90
            //     else if (voltage >= 12.15) return 85
            //     else if (voltage >= 12.00) return 80
            //     else if (voltage >= 11.85) return 75
            //     else if (voltage >= 11.70) return 70
            //     else if (voltage >= 11.55) return 65
            //     else if (voltage >= 11.40) return 60
            //     else if (voltage >= 11.25) return 55
            //     else if (voltage >= 11.10) return 50
            //     else if (voltage >= 10.95) return 45
            //     else if (voltage >= 10.80) return 40
            //     else if (voltage >= 10.65) return 35
            //     else if (voltage >= 10.50) return 30
            //     else if (voltage >= 10.35) return 25
            //     else if (voltage >= 10.20) return 20
            //     else if (voltage >= 10.05) return 15
            //     else if (voltage >= 9.90)  return 10
            //     else if (voltage >= 9.75)  return 5
            //     else return 0
            // }

            function getBatteryPercentageText() {
                if (!isNaN(battery.voltage.rawValue)) {
                    const voltage = battery.voltage.rawValue
                    const percentage = getBatteryPercentageFromVoltage(voltage)
                    return percentage + "%"
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return qsTr("n/a")
            }


            // function getBatteryPercentageText() {
            //     if (!isNaN(battery.percentRemaining.rawValue)) {
            //         if (battery.percentRemaining.rawValue > 98.9) {
            //             return qsTr("100%");
            //         } else {
            //             return battery.percentRemaining.valueString + battery.percentRemaining.units;
            //         }
            //     } else if (!isNaN(battery.voltage.rawValue)) {
            //         var voltagePercentage = calculatePercentageFromVoltage();
            //         if (!isNaN(voltagePercentage)) {
            //             return voltagePercentage.toFixed(0) + "%";
            //         }
            //     } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
            //         return battery.chargeState.enumStringValue;
            //     }
            //     return qsTr("n/a");
            // }
            // function getBatteryPercentageText() {
            //     if (!isNaN(battery.percentRemaining.rawValue)) {
            //         if (battery.percentRemaining.rawValue > 98.9) {
            //             return qsTr("100%")
            //         } else {
            //             return battery.percentRemaining.valueString + battery.percentRemaining.units
            //         }
            //     } else if (!isNaN(battery.voltage.rawValue)) {
            //         return battery.voltage.valueString + battery.voltage.units
            //     } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
            //         return battery.chargeState.enumStringValue
            //     }
            //     return qsTr("n/a")
            // }

            function getBatteryVoltageText() {
                if (!isNaN(battery.voltage.rawValue)) {
                    return battery.voltage.valueString + battery.voltage.units
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return qsTr("n/a")
            }

            QGCColoredImage {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              20
                height:20
                sourceSize.width:   width
                source:             getBatterySvgSource()
                fillMode:           Image.PreserveAspectFit
                color:              getBatteryColor()
            }

           ColumnLayout {
                id:                     batteryInfoColumn
                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                spacing:                0

                QGCLabel {
                    Layout.alignment:       Qt.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                    color:                  "white"
                    width: 10
                                        height: 20
                    text:                   getBatteryPercentageText()
                    //font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                    visible:                _showBoth || _showPercentage
                }

                QGCLabel {
                    Layout.alignment:       Qt.AlignHCenter
                    width: 10
                    height: 20
                    //font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                    color:                  "white"
                    text:                   getBatteryVoltageText()
                    visible:                _showBoth || _showVoltage
                }
            }
        }
    }

    Component {
        id: batteryContentComponent

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

            Component {
                id: batteryValuesAvailableComponent

                QtObject {
                    property bool functionAvailable:         battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
                    property bool showFunction:              functionAvailable && battery.function.rawValue != MAVLink.MAV_BATTERY_FUNCTION_ALL
                    property bool temperatureAvailable:      !isNaN(battery.temperature.rawValue)
                    property bool currentAvailable:          !isNaN(battery.current.rawValue)
                    property bool mahConsumedAvailable:      !isNaN(battery.mahConsumed.rawValue)
                    property bool timeRemainingAvailable:    !isNaN(battery.timeRemaining.rawValue)
                    property bool percentRemainingAvailable: !isNaN(battery.percentRemaining.rawValue)
                    property bool chargeStateAvailable:      battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
                }
            }

            Repeater {
                model: _activeVehicle ? _activeVehicle.batteries : 0

                SettingsGroupLayout {
                    heading:        qsTr("Battery %1").arg(_activeVehicle.batteries.length === 1 ? qsTr("Status") : object.id.rawValue)
                    contentSpacing: 0
                    showDividers:   false

                    property var batteryValuesAvailable: batteryValuesAvailableLoader.item

                    Loader {
                        id:                 batteryValuesAvailableLoader
                        sourceComponent:    batteryValuesAvailableComponent

                        property var battery: object
                    }

                    LabelledLabel {
                        label:  qsTr("Charge State")
                        labelText:  object.chargeState.enumStringValue
                        visible:    batteryValuesAvailable.chargeStateAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Remaining")
                        labelText:  object.timeRemainingStr.value
                        visible:    batteryValuesAvailable.timeRemainingAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Remaining")
                        labelText:  object.percentRemaining.valueString + " " + object.percentRemaining.units
                        visible:    batteryValuesAvailable.percentRemainingAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Voltage")
                        labelText:  object.voltage.valueString + " " + object.voltage.units
                    }

                    LabelledLabel {
                        label:      qsTr("Consumed")
                        labelText:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                        visible:    batteryValuesAvailable.mahConsumedAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Temperature")
                        labelText:  object.temperature.valueString + " " + object.temperature.units
                        visible:    batteryValuesAvailable.temperatureAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Function")
                        labelText:  object.function.enumStringValue
                        visible:    batteryValuesAvailable.showFunction
                    }
                }
            }
        }
    }

    Component {
        id: batteryExpandedComponent

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            FactPanelController { id: controller }

            Loader {
                sourceComponent: expandedPageComponent
            }

            SettingsGroupLayout {
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Battery Display")
                    color:"white"}
                    FactComboBox {
                        id:             editModeCheckBox
                        fact:           QGroundControl.settingsManager.batteryIndicatorSettings.display
                        sizeToContents: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Vehicle Power")
                    color:"white"}
                    QGCButton {
                        text: qsTr("Configure")
                        onClicked: {
                            mainWindow.showVehicleSetupTool(qsTr("Power"))
                            mainWindow.closeIndicatorDrawer()
                        }
                    }
                }

            }

            SettingsGroupLayout {
                heading: qsTr("Battery State Display")
                Layout.fillWidth: true
                spacing: ScreenTools.defaultFontPixelHeight * 0.05  // Reduced outer spacing
                visible: batteryState  // Control visibility of the entire group

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Reduced spacing between elements

                    // Battery 100%
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                        QGCColoredImage {
                            source: "/qmlimages/BatteryGreen.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorGreen
                        }
                        QGCLabel { text: qsTr("100%")
                        color:"white"}
                    }

                    // Threshold 1
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field
                        QGCColoredImage {
                            source: "/qmlimages/BatteryYellowGreen.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorYellowGreen
                        }

                        QGCLabel { text: qsTr("80%")
                        color:"white"}
                        FactTextField {
                            id: threshold1Field
                            fact: batterySettings.threshold1
                            implicitWidth: ScreenTools.defaultFontPixelWidth * 5.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            visible: false//threshold1visible
                            onEditingFinished: {
                                // Validate and set the new threshold value
                                batterySettings.setThreshold1(parseInt(text));
                            }
                        }
                    }
                    QGCLabel {
                        visible: !threshold1visible
                        text: qsTr("") + batterySettings.threshold1.rawValue.toString() + qsTr("%")
                    }

                    // Threshold 2
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field
                        QGCColoredImage {
                            source: "/qmlimages/BatteryYellow.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorYellow
                        }
                        QGCLabel { text: qsTr("60%")
                        color:"white"}
                        FactTextField {
                            id: threshold2Field
                            fact: batterySettings.threshold2
                            implicitWidth: ScreenTools.defaultFontPixelWidth * 5.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            visible: false//threshold2visible
                            onEditingFinished: {
                                // Validate and set the new threshold value
                                batterySettings.setThreshold2(parseInt(text));
                            }
                        }
                    }
                    QGCLabel {
                        visible: !threshold2visible
                        text: qsTr("") + batterySettings.threshold2.rawValue.toString() + qsTr("%")
                    }

                    // Low state
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                        QGCColoredImage {
                            source: "/qmlimages/BatteryOrange.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorOrange
                        }
                        QGCLabel { text: qsTr("Low")
                        color:"white"}
                    }

                    // Critical state
                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                        QGCColoredImage {
                            source: "/qmlimages/BatteryCritical.svg"
                            height: ScreenTools.defaultFontPixelHeight * 5
                            width: ScreenTools.defaultFontPixelWidth * 6
                            fillMode: Image.PreserveAspectFit
                            color: qgcPal.colorRed
                        }
                        QGCLabel { text: qsTr("Critical")
                        color:"white"}
                    }
                }
            }

        }
    }
}
