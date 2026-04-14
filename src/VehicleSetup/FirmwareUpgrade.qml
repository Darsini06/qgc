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
import QtQuick.Effects

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controllers
import QGroundControl.ScreenTools

SetupPage {
    id:             firmwarePage
    pageComponent:  firmwarePageComponent
    pageName:       qsTr("Firmware")
    showAdvanced:   globals.activeVehicle && globals.activeVehicle.apmFirmware

    Component {
        id: firmwarePageComponent

        Item {
            width:  availableWidth
            height: availableHeight

            // ── Design tokens (Light Theme) ────────────────────────────────
            readonly property color bgDeep:      "#F8FAFC"
            readonly property color bgCard:      "#FFFFFF"
            readonly property color borderColor: "#E2E8F0"
            readonly property color accentBlue:  "#6366F1"
            readonly property color accentGlow:  "#4F46E5"
            readonly property color textPrimary: "#1E293B"
            readonly property color textMuted:   "#64748B"
            readonly property color successGrn:  "#16A34A"
            readonly property color warningAmb:  "#D97706"

            // ── Functional strings ─────────────────────────────────────────
            readonly property string highlightPrefix:   "<font color=\"" + qgcPal.warningText + "\">"
            readonly property string highlightSuffix:   "</font>"
            readonly property string welcomeText:       qsTr("%1 can upgrade the firmware on Pixhawk devices and SiK Radios.").arg(QGroundControl.appName)
            readonly property string welcomeTextSingle: qsTr("Update the autopilot firmware to the latest version")
            readonly property string plugInText:        "<big>" + highlightPrefix + qsTr("Plug in your device") + highlightSuffix + qsTr(" via USB to ") + highlightPrefix + qsTr("start") + highlightSuffix + qsTr(" firmware upgrade.") + "</big>"
            readonly property string flashFailText:     qsTr("If upgrade failed, make sure to connect ") + highlightPrefix + qsTr("directly") + highlightSuffix + qsTr(" to a powered USB port on your computer, not through a USB hub. ") +
                                                        qsTr("Also make sure you are only powered via USB ") + highlightPrefix + qsTr("not battery") + highlightSuffix + "."
            readonly property string qgcUnplugText1:    qsTr("All %1 connections to vehicles must be ").arg(QGroundControl.appName) + highlightPrefix + qsTr(" disconnected ") + highlightSuffix + qsTr("prior to firmware upgrade.")
            readonly property string qgcUnplugText2:    highlightPrefix + "<big>" + qsTr("Please unplug your Pixhawk and/or Radio from USB.") + "</big>" + highlightSuffix

            readonly property int _defaultFimwareTypePX4:   12
            readonly property int _defaultFimwareTypeAPM:   3

            property var    _firmwareUpgradeSettings:   QGroundControl.settingsManager.firmwareUpgradeSettings
            property var    _defaultFirmwareFact:       _firmwareUpgradeSettings.defaultFirmwareType
            property bool   _defaultFirmwareIsPX4:      true
            property string firmwareWarningMessage
            property bool   firmwareWarningMessageVisible: false
            property bool   initialBoardSearch:            true
            property string firmwareName
            property bool   _singleFirmwareMode:        QGroundControl.corePlugin.options.firmwareUpgradeSingleURL.length != 0

            function setupPageCompleted() {
                controller.startBoardSearch()
                _defaultFirmwareIsPX4 = _defaultFirmwareFact.rawValue === _defaultFimwareTypePX4
            }

            // ── Controller & File Dialog ──────────────────────────────────
            QGCFileDialog {
                id:             customFirmwareDialog
                title:          qsTr("Select Firmware File")
                nameFilters:    [qsTr("Firmware Files (*.px4 *.apj *.bin *.ihx)"), qsTr("All Files (*)")]
                folder:         QGroundControl.settingsManager.appSettings.logSavePath
                onAcceptedForLoad: (file) => {
                    controller.flashFirmwareUrl(file)
                    close()
                }
            }

            FirmwareUpgradeController {
                id:          controller
                progressBar: progressBar
                statusLog:   statusTextArea

                property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

                onActiveVehicleChanged: {
                    if (!globals.activeVehicle) statusTextArea.append(plugInText)
                }
                onNoBoardFound: {
                    initialBoardSearch = false
                    if (!QGroundControl.multiVehicleManager.activeVehicleAvailable) statusTextArea.append(plugInText)
                }
                onBoardGone: {
                    initialBoardSearch = false
                    if (!QGroundControl.multiVehicleManager.activeVehicleAvailable) statusTextArea.append(plugInText)
                }
                onBoardFound: {
                    if (initialBoardSearch) {
                        statusTextArea.append(qgcUnplugText1)
                        statusTextArea.append(qgcUnplugText2)
                        var availableDevices = controller.availableBoardsName()
                        if (availableDevices.length > 1) {
                            statusTextArea.append(highlightPrefix + qsTr("Multiple devices detected! Remove all detected devices to perform the firmware upgrade."))
                            statusTextArea.append(qsTr("Detected [%1]: ").arg(availableDevices.length) + availableDevices.join(", "))
                        }
                        if (QGroundControl.multiVehicleManager.activeVehicle) {
                            QGroundControl.multiVehicleManager.activeVehicle.vehicleLinkManager.autoDisconnect = true
                        }
                    } else {
                        statusTextArea.append(highlightPrefix + qsTr("Found device") + highlightSuffix + ": " + controller.boardType)
                    }
                }
                onShowFirmwareSelectDlg: firmwareSelectDialogComponent.createObject(mainWindow).open()
                onError:                 statusTextArea.append(flashFailText)
            }

            // ── Firmware Selection Dialog ──────────────────────────────────
            Component {
                id: firmwareSelectDialogComponent

                QGCPopupDialog {
                    id:      firmwareSelectDialog
                    title:   qsTr("Firmware Setup")
                    buttons: Dialog.Ok | Dialog.Cancel

                    property bool showFirmwareTypeSelection: _advanced.checked

                    function firmwareVersionChanged(model) {
                        firmwareWarningMessageVisible = false
                        firmwareBuildTypeCombo.model  = null
                        firmwareBuildTypeCombo.model  = model
                        firmwareBuildTypeCombo.currentIndex = 1
                        firmwareBuildTypeCombo.currentIndex = 0
                    }

                    function updatePX4VersionDisplay() {
                        var versionString = ""
                        if (_advanced.checked) {
                            switch (controller.selectedFirmwareBuildType) {
                            case FirmwareUpgradeController.StableFirmware:
                                versionString = controller.px4StableVersion; break
                            case FirmwareUpgradeController.BetaFirmware:
                                versionString = controller.px4BetaVersion;   break
                            }
                        } else {
                            versionString = controller.px4StableVersion
                        }
                        px4FlightStackRadio.text = qsTr("PX4 Pro ") + versionString
                    }

                    Component.onCompleted: {
                        firmwarePage.advanced = false
                        firmwarePage.showAdvanced = false
                        updatePX4VersionDisplay()
                    }

                    Connections {
                        target:  controller
                        onError: reject()
                    }

                    onAccepted: {
                        if (_singleFirmwareMode) {
                            controller.flashSingleFirmwareMode(controller.selectedFirmwareBuildType)
                        } else {
                            var firmwareBuildType = firmwareBuildTypeCombo.model.get(firmwareBuildTypeCombo.currentIndex).firmwareType
                            var vehicleType       = FirmwareUpgradeController.DefaultVehicleFirmware
                            var stack             = apmFlightStack.checked ? FirmwareUpgradeController.AutoPilotStackAPM : FirmwareUpgradeController.AutoPilotStackPX4

                            if (apmFlightStack.checked) {
                                if (firmwareBuildType === FirmwareUpgradeController.CustomFirmware) {
                                    vehicleType = apmVehicleTypeCombo.currentIndex
                                } else {
                                    if (controller.apmFirmwareNames.length === 0) {
                                        mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("Either firmware list is still downloading, or no firmware is available for current selection."))
                                        firmwareSelectDialog.preventClose = true
                                        return
                                    }
                                    if (ardupilotFirmwareSelectionCombo.currentIndex == -1) {
                                        mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("You must choose a board type."))
                                        firmwareSelectDialog.preventClose = true
                                        return
                                    }
                                    var firmwareUrl = controller.apmFirmwareUrls[ardupilotFirmwareSelectionCombo.currentIndex]
                                    if (firmwareUrl == "") {
                                        mainWindow.showMessageDialog(firmwareSelectDialog.title, qsTr("No firmware was found for the current selection."))
                                        firmwareSelectDialog.preventClose = true
                                        return
                                    }
                                    controller.flashFirmwareUrl(controller.apmFirmwareUrls[ardupilotFirmwareSelectionCombo.currentIndex])
                                    return
                                }
                            }
                            if (firmwareBuildType === FirmwareUpgradeController.CustomFirmware) {
                                customFirmwareDialog.openForLoad()
                            } else {
                                controller.flash(stack, firmwareBuildType, vehicleType)
                            }
                        }
                    }

                    function reject() {
                        statusTextArea.append(highlightPrefix + qsTr("Upgrade cancelled") + highlightSuffix)
                        statusTextArea.append("------------------------------------------")
                        controller.cancel()
                        close()
                    }

                    ListModel {
                        id: firmwareBuildTypeList
                        ListElement { text: qsTr("Standard Version (stable)");  firmwareType: FirmwareUpgradeController.StableFirmware    }
                        ListElement { text: qsTr("Beta Testing (beta)");         firmwareType: FirmwareUpgradeController.BetaFirmware      }
                        ListElement { text: qsTr("Developer Build (master)");    firmwareType: FirmwareUpgradeController.DeveloperFirmware  }
                        ListElement { text: qsTr("Custom firmware file...");     firmwareType: FirmwareUpgradeController.CustomFirmware     }
                    }

                    ListModel {
                        id: singleFirmwareModeTypeList
                        ListElement { text: qsTr("Standard Version");        firmwareType: FirmwareUpgradeController.StableFirmware  }
                        ListElement { text: qsTr("Custom firmware file..."); firmwareType: FirmwareUpgradeController.CustomFirmware   }
                    }

                    ColumnLayout {
                        width:   Math.max(ScreenTools.defaultFontPixelWidth * 40, firmwareRadiosColumn.width)
                        spacing: globals.defaultTextHeight / 2

                        QGCLabel { Layout.fillWidth: true; wrapMode: Text.WordWrap
                            text: (_singleFirmwareMode || !QGroundControl.apmFirmwareSupported)
                                  ? qsTr("Press Ok to upgrade your vehicle.")
                                  : qsTr("Detected Pixhawk board. You can select from the following flight stacks:")
                        }

                        Column {
                            id:      firmwareRadiosColumn
                            spacing: 0
                            visible: !_singleFirmwareMode && QGroundControl.apmFirmwareSupported

                            Component.onCompleted: {
                                if (!QGroundControl.apmFirmwareSupported) {
                                    _defaultFirmwareFact.rawValue = _defaultFimwareTypePX4
                                    firmwareVersionChanged(firmwareBuildTypeList)
                                }
                            }

                            QGCRadioButton {
                                id:        px4FlightStackRadio
                                text:      qsTr("PX4 Pro ")
                                font.bold: _defaultFirmwareIsPX4
                                checked:   _defaultFirmwareIsPX4
                                onClicked: { _defaultFirmwareFact.rawValue = _defaultFimwareTypePX4; firmwareVersionChanged(firmwareBuildTypeList) }
                            }
                            QGCRadioButton {
                                id:        apmFlightStack
                                text:      qsTr("ArduPilot")
                                font.bold: !_defaultFirmwareIsPX4
                                checked:   !_defaultFirmwareIsPX4
                                onClicked: { _defaultFirmwareFact.rawValue = _defaultFimwareTypeAPM; firmwareVersionChanged(firmwareBuildTypeList) }
                            }
                        }

                        FactComboBox { Layout.fillWidth: true; visible: apmFlightStack.checked; fact: _firmwareUpgradeSettings.apmChibiOS;  indexModel: false }
                        FactComboBox { id: apmVehicleTypeCombo; Layout.fillWidth: true; visible: apmFlightStack.checked; fact: _firmwareUpgradeSettings.apmVehicleType; indexModel: false }

                        QGCComboBox {
                            id:              ardupilotFirmwareSelectionCombo
                            Layout.fillWidth: true
                            visible:         apmFlightStack.checked && !controller.downloadingFirmwareList && controller.apmFirmwareNames.length !== 0
                            model:           controller.apmFirmwareNames
                            onModelChanged:  currentIndex = controller.apmFirmwareNamesBestIndex
                        }

                        QGCLabel { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Downloading list of available firmwares..."); visible: controller.downloadingFirmwareList }
                        QGCLabel { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("No Firmware Available"); visible: !controller.downloadingFirmwareList && (QGroundControl.apmFirmwareSupported && controller.apmFirmwareNames.length === 0) }

                        QGCCheckBox {
                            id:      _advanced
                            text:    qsTr("Advanced settings")
                            checked: false
                            onClicked: { firmwareBuildTypeCombo.currentIndex = 0; firmwareWarningMessageVisible = false; updatePX4VersionDisplay() }
                        }

                        QGCLabel { Layout.fillWidth: true; wrapMode: Text.WordWrap; visible: showFirmwareTypeSelection
                            text: _singleFirmwareMode
                                  ? qsTr("Select the standard version or one from the file system (previously downloaded):")
                                  : qsTr("Select which version of the above flight stack you would like to install:")
                        }

                        QGCComboBox {
                            id:              firmwareBuildTypeCombo
                            Layout.fillWidth: true
                            visible:         showFirmwareTypeSelection
                            textRole:        "text"
                            model:           _singleFirmwareMode ? singleFirmwareModeTypeList : firmwareBuildTypeList
                            onActivated: (index) => {
                                controller.selectedFirmwareBuildType = model.get(index).firmwareType
                                if (model.get(index).firmwareType === FirmwareUpgradeController.BetaFirmware) {
                                    firmwareWarningMessageVisible = true
                                    firmwareVersionWarningLabel.text = qsTr("WARNING: BETA FIRMWARE. This firmware version is ONLY intended for beta testers. Although it has received FLIGHT TESTING, it represents actively changed code. Do NOT use for normal operation.")
                                } else if (model.get(index).firmwareType === FirmwareUpgradeController.DeveloperFirmware) {
                                    firmwareWarningMessageVisible = true
                                    firmwareVersionWarningLabel.text = qsTr("WARNING: CONTINUOUS BUILD FIRMWARE. This firmware has NOT BEEN FLIGHT TESTED. It is only intended for DEVELOPERS. Run bench tests without props first. Do NOT fly this without additional safety precautions. Follow the forums actively when using it.")
                                } else {
                                    firmwareWarningMessageVisible = false
                                }
                                updatePX4VersionDisplay()
                            }
                        }

                        QGCLabel { id: firmwareVersionWarningLabel; Layout.fillWidth: true; wrapMode: Text.WordWrap; visible: firmwareWarningMessageVisible }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // MAIN UI – Clean White Light Layout
            // ══════════════════════════════════════════════════════════════════

            // ── White background ──
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#F8FAFC" }
                    GradientStop { position: 1.0; color: "#EEF2FF" }
                }
            }

            ColumnLayout {
                anchors.fill:    parent
                anchors.margins: ScreenTools.defaultFontPixelHeight
                spacing:         ScreenTools.defaultFontPixelHeight * 0.8

                // ── Header Row ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelWidth

                    // Icon badge
                    Rectangle {
                        width:  ScreenTools.defaultFontPixelHeight * 2.8
                        height: width
                        radius: 10
                        color:  "#EEF2FF"
                        border.color: "#C7D2FE"
                        border.width: 1

                        QGCColoredImage {
                            anchors.centerIn:   parent
                            width:              parent.width * 0.6
                            height:             width
                            source:             "qrc:/InstrumentValueIcons/arrow-thin-up.svg"
                            color:              "#4F46E5"
                            fillMode:           Image.PreserveAspectFit
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        QGCLabel {
                            text:           qsTr("FIRMWARE UPGRADE")
                            color:          "#1E293B"
                            font.family:    "Outfit"
                            font.bold:      true
                            font.pointSize: ScreenTools.largeFontPointSize * 1.1
                            font.letterSpacing: 1.5
                        }
                        QGCLabel {
                            text:           qsTr("Flash and manage autopilot firmware")
                            color:          "#64748B"
                            font.family:    "Outfit"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Live status pill
                    Rectangle {
                        id: statusPill
                        height: ScreenTools.defaultFontPixelHeight * 1.6
                        width:  statusPillRow.implicitWidth + ScreenTools.defaultFontPixelWidth * 2
                        radius: height / 2
                        color:  "#DCFCE7"
                        border.color: "#86EFAC"
                        border.width: 1

                        Row {
                            id: statusPillRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                width:  7; height: 7; radius: 4
                                color: "#16A34A"
                                anchors.verticalCenter: parent.verticalCenter
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.2; duration: 900 }
                                    NumberAnimation { from: 0.2; to: 1.0; duration: 900 }
                                }
                            }
                            Text {
                                text:  qsTr("READY")
                                color: "#16A34A"
                                font.family:    "Outfit"
                                font.bold:      true
                                font.pointSize: ScreenTools.smallFontPointSize * 0.9
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // ── Divider ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color:  "#E2E8F0"
                }

                // ── Progress Card ──────────────────────────────────────────
                Rectangle {
                    id: progressCard
                    Layout.fillWidth: true
                    height:  progressCardCol.implicitHeight + ScreenTools.defaultFontPixelHeight * 1.4
                    radius:  14
                    color:   "#FFFFFF"
                    border.color: "#E2E8F0"
                    border.width: 1
                    visible: !flashBootloaderButton.visible

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor:   Qt.rgba(0, 0, 0, 0.07)
                        shadowBlur:    0.8
                        shadowVerticalOffset: 3
                    }

                    ColumnLayout {
                        id: progressCardCol
                        anchors {
                            left: parent.left; right: parent.right
                            top: parent.top
                            margins: ScreenTools.defaultFontPixelHeight * 0.8
                        }
                        spacing: ScreenTools.defaultFontPixelHeight * 0.5

                        RowLayout {
                            Layout.fillWidth: true
                            QGCLabel {
                                text:        qsTr("FLASH PROGRESS")
                                color:       "#64748B"
                                font.family: "Outfit"
                                font.bold:   true
                                font.pointSize: ScreenTools.smallFontPointSize * 0.9
                                font.letterSpacing: 1.2
                            }
                            Item { Layout.fillWidth: true }
                            QGCLabel {
                                text:        Math.round(progressBar.value * 100) + "%"
                                color:       "#4F46E5"
                                font.family: "Outfit"
                                font.bold:   true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }

                        // Custom styled progress bar
                        Item {
                            Layout.fillWidth: true
                            height: 8

                            Rectangle {
                                anchors.fill: parent
                                radius: 4
                                color: "#EEF2FF"
                            }
                            Rectangle {
                                width:  parent.width * progressBar.value
                                height: parent.height
                                radius: 4
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#6366F1" }
                                    GradientStop { position: 1.0; color: "#A78BFA" }
                                }
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }

                            // Hidden real progress bar feeding the value
                            ProgressBar {
                                id:      progressBar
                                visible: false
                                from:    0; to: 1
                            }
                        }
                    }
                }

                // ── Bootloader Button (advanced mode only) ─────────────────
                QGCButton {
                    id:        flashBootloaderButton
                    text:      qsTr("⚡  Flash ChibiOS Bootloader")
                    visible:   firmwarePage.advanced
                    onClicked: globals.activeVehicle.flashBootloader()

                    background: Rectangle {
                        radius: 10
                        color: parent.hovered ? "#EEF2FF" : "#FFFFFF"
                        border.color: "#6366F1"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    contentItem: Text {
                        text:  parent.text
                        color: "#4F46E5"
                        font.family:    "Outfit"
                        font.bold:      true
                        font.pointSize: ScreenTools.defaultFontPointSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                    }
                }

                // ── Status Log Card ───────────────────────────────────────
                Rectangle {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    radius:  12
                    color:   "#FFFFFF"
                    border.color: "#E2E8F0"
                    border.width: 1

                    ScrollView {
                        anchors.fill:    parent
                        anchors.margins: 12
                        clip:            true

                        TextArea {
                            id:               statusTextArea
                            textFormat:       TextEdit.RichText
                            text:             (_singleFirmwareMode ? welcomeTextSingle : welcomeText) + "\n"
                            color:            "#1E293B"
                            font.family:      "Cascadia Code"
                            font.pointSize:   ScreenTools.smallFontPointSize
                            wrapMode:         TextArea.Wrap
                            readOnly:         true
                            selectByMouse:    true
                            background:       null
                            leftPadding:      0
                            topPadding:       0

                            onTextChanged: cursorPosition = text.length
                        }
                    }
                }
            } // ColumnLayout (main)
        } // Item (root)
    } // Component
} // SetupPage
