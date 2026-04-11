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
    width:          batteryIndicatorRow.width
    height:         batteryIndicatorRow.height

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
        id: mouseArea
        anchors.fill:   parent
        hoverEnabled:   true
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

        Item {
            id:             batteryVisualRoot
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          batteryContainer.width

            property var battery: parent.battery // Correctly pass battery from Loader

            function calculatePercentageFromVoltage() {
                if (!battery || !battery.voltage || isNaN(battery.voltage.rawValue)) return NaN;
                var cells = control.cellCount > 0 ? control.cellCount : 3;
                var full = control.fullVoltagePerCell > 0 ? control.fullVoltagePerCell : 4.2;
                var empty = control.emptyVoltagePerCell > 0 ? control.emptyVoltagePerCell : 3.0;
                var cellVoltage = battery.voltage.rawValue / cells;
                var percentage = (cellVoltage - empty) / (full - empty) * 100;
                return Math.max(0, Math.min(100, percentage));
            }

            function getBatteryColor() {
                if (!battery) return "white";
                var percentage = (battery.percentRemaining && !isNaN(battery.percentRemaining.rawValue))
                               ? battery.percentRemaining.rawValue
                               : calculatePercentageFromVoltage();
                if (isNaN(percentage)) return "white";
                var chargeState = battery.chargeState ? battery.chargeState.rawValue : MAVLink.MAV_BATTERY_CHARGE_STATE_OK;
                switch (chargeState) {
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

            function getBatterySvgSource() {
                if (!battery) return "/qmlimages/Battery.svg";
                if (battery.voltage && !isNaN(battery.voltage.rawValue)) {
                    const voltage = battery.voltage.rawValue;
                    const percentage = getBatteryPercentageFromVoltage(voltage);
                    if (percentage > threshold1) return "/qmlimages/BatteryGreen.svg";
                    else if (percentage > threshold2) return "/qmlimages/BatteryYellowGreen.svg";
                    else if (percentage > 20) return "/qmlimages/BatteryYellow.svg";
                    else return "/qmlimages/BatteryCritical.svg";
                }
                switch (battery.chargeState.rawValue) {
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW: return "/qmlimages/BatteryOrange.svg"
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL: return "/qmlimages/BatteryCritical.svg"
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                        return "/qmlimages/BatteryEMERGENCY.svg"
                    default: return "/qmlimages/Battery.svg"
                }
            }

            function getBatteryPercentageFromVoltage(voltage) {
                if (isNaN(voltage)) return -1;
                var cells = control.cellCount > 0 ? control.cellCount : 3;
                var full = control.fullVoltagePerCell > 0 ? control.fullVoltagePerCell : 4.2;
                var empty = control.emptyVoltagePerCell > 0 ? control.emptyVoltagePerCell : 3.0;
                const minVoltage = empty * cells;
                const maxVoltage = full * cells;
                if (voltage < minVoltage) return 0;
                var currentPercentage = ((voltage - minVoltage) / (maxVoltage - minVoltage)) * 100;
                return Math.max(0, Math.min(100, Math.floor(currentPercentage)));
            }

            function getBatteryPercentageText() {
                if (!battery) return qsTr("n/a");
                if (battery.percentRemaining && !isNaN(battery.percentRemaining.rawValue)) {
                    return battery.percentRemaining.valueString + "%"
                } else if (battery.voltage && !isNaN(battery.voltage.rawValue)) {
                    return getBatteryPercentageFromVoltage(battery.voltage.rawValue) + "%"
                }
                return (battery.chargeState && battery.chargeState.enumStringValue !== "Undefined") ? battery.chargeState.enumStringValue : qsTr("n/a")
            }

            function getBatteryVoltageText() {
                if (!battery || !battery.voltage || isNaN(battery.voltage.rawValue)) return qsTr("n/a");
                return battery.voltage.valueString + "V"
            }

            Rectangle {
                id: batteryContainer
                height: parent.height
                width: contentRow.width + ScreenTools.defaultFontPixelWidth * 1.5
                radius: height / 2
                color: mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.3)
                border.color: mouseArea.containsMouse ? "white" : Qt.rgba(1, 1, 1, 0.2)
                border.width: 1
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: {
                        if (!battery) return 0;
                        var pctRemaining = (battery.percentRemaining && !isNaN(battery.percentRemaining.rawValue)) ? battery.percentRemaining.rawValue : calculatePercentageFromVoltage();
                        pctRemaining = Math.max(0, Math.min(100, pctRemaining || 0));
                        return parent.width * (pctRemaining / 100);
                    }
                    color: getBatteryColor()
                    opacity: 0.25
                    radius: parent.radius
                }

                RowLayout {
                    id: contentRow
                    anchors.centerIn: parent
                    spacing: ScreenTools.defaultFontPixelWidth / 2

                    QGCColoredImage {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        sourceSize.width: Layout.preferredWidth
                        source: getBatterySvgSource()
                        fillMode: Image.PreserveAspectFit
                        color: getBatteryColor()
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: -2
                        visible: _showBoth || _showPercentage || _showVoltage

                        QGCLabel {
                            Layout.alignment: Qt.AlignHCenter
                            color: "white"
                            text: getBatteryPercentageText()
                            font.pointSize: ScreenTools.smallFontPointSize
                            visible: _showBoth || _showPercentage
                            font.bold: true
                        }

                        QGCLabel {
                            Layout.alignment: Qt.AlignHCenter
                            color: "white"
                            text: getBatteryVoltageText()
                            font.pointSize: ScreenTools.smallFontPointSize - 2
                            visible: _showBoth || _showVoltage
                            opacity: 0.8
                        }
                    }
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
                    heading:        qsTr("Battery Status")/*.arg(_activeVehicle.batteries.length === 1 ? qsTr("Status") : object.id.rawValue)*/
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
                        visible:    false//batteryValuesAvailable.timeRemainingAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Remaining")
                        labelText:  object.percentRemaining.valueString + " " + object.percentRemaining.units
                        visible:    false//batteryValuesAvailable.percentRemainingAvailable
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
                        color: "white"
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
                        color: "white"
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