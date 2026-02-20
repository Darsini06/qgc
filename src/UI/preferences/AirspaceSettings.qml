/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette

/// Settings page for airspace configuration
Rectangle {
    id: _root
    color: qgcPal.window

    property var airspaceManager: QGroundControl.airspaceManager

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    QGCFlickable {
        anchors.fill: parent
        contentHeight: _mainColumn.height
        contentWidth: _mainColumn.width

        ColumnLayout {
            id: _mainColumn
            width: _root.width
            spacing: ScreenTools.defaultFontPixelHeight

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: _headerColumn.height + ScreenTools.defaultFontPixelHeight * 2
                color: qgcPal.windowShade

                ColumnLayout {
                    id: _headerColumn
                    anchors.centerIn: parent
                    width: parent.width - ScreenTools.defaultFontPixelWidth * 2
                    spacing: ScreenTools.defaultFontPixelHeight * 0.5

                    QGCLabel {
                        text: "Airspace Settings"
                        font.pointSize: ScreenTools.largeFontPointSize
                        font.bold: true
                    }

                    QGCLabel {
                        text: "Configure GeoJSON airspace data service and display options"
                        font.pointSize: ScreenTools.smallFontPointSize
                        color: qgcPal.text
                    }
                }
            }

            // Server Configuration
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth
                title: "Server Configuration"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth

                        QGCLabel {
                            text: "API URL:"
                            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 15
                        }

                        QGCTextField {
                            id: _serverUrlField
                            Layout.fillWidth: true
                            text: airspaceManager ? airspaceManager.serverUrl : ""
                            placeholderText: "https://yourserver.com/api/facilities"
                        }

                        QGCButton {
                            text: "Save"
                            onClicked: {
                                if (airspaceManager) {
                                    airspaceManager.serverUrl = _serverUrlField.text
                                    _statusLabel.text = "Server URL saved"
                                    _statusLabel.color = qgcPal.colorGreen
                                }
                            }
                        }
                    }

                    QGCLabel {
                        text: "Enter the base URL for your GeoJSON airspace API endpoint"
                        font.pointSize: ScreenTools.tinyFontPointSize
                        color: qgcPal.warningText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    QGCCheckBox {
                        text: "Offline Mode (Use cached data only)"
                        checked: airspaceManager ? airspaceManager.offlineModeEnabled : false
                        onClicked: {
                            if (airspaceManager) {
                                airspaceManager.offlineModeEnabled = checked
                            }
                        }
                    }
                }
            }

            // Display Options
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth
                title: "Display Options"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight

                    QGCCheckBox {
                        id: _showAirspaceCheck
                        text: "Show Airspace Zones"
                        checked: airspaceManager ? airspaceManager.showAirspace : true
                        onClicked: {
                            if (airspaceManager) {
                                airspaceManager.showAirspace = checked
                            }
                        }
                    }

                    QGCCheckBox {
                        id: _showLabelsCheck
                        text: "Show Zone Labels"
                        checked: airspaceManager ? airspaceManager.showLabels : true
                        enabled: _showAirspaceCheck.checked
                        onClicked: {
                            if (airspaceManager) {
                                airspaceManager.showLabels = checked
                            }
                        }
                    }

                    QGCCheckBox {
                        id: _showIconsCheck
                        text: "Show Airport/Facility Icons"
                        checked: airspaceManager ? airspaceManager.showIcons : true
                        enabled: _showAirspaceCheck.checked
                        onClicked: {
                            if (airspaceManager) {
                                airspaceManager.showIcons = checked
                            }
                        }
                    }

                    QGCLabel {
                        text: "Note: Display settings are applied to the map overlay"
                        font.pointSize: ScreenTools.tinyFontPointSize
                        color: qgcPal.warningText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Mission Validation
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth
                title: "Mission Validation"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight

                    QGCCheckBox {
                        id: _enableValidationCheck
                        text: "Enable Airspace Restriction Validation"
                        checked: true
                    }

                    QGCCheckBox {
                        text: "Block mission upload in prohibited zones (Red)"
                        checked: true
                        enabled: _enableValidationCheck.checked
                    }

                    QGCCheckBox {
                        text: "Warn for restricted zones (Yellow/Military)"
                        checked: true
                        enabled: _enableValidationCheck.checked
                    }

                    QGCLabel {
                        text: "Mission validation checks waypoints against airspace restrictions before upload"
                        font.pointSize: ScreenTools.tinyFontPointSize
                        color: qgcPal.warningText
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Cache Management
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth
                title: "Cache Management"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight

                    QGCLabel {
                        text: "Airspace data is cached locally for offline use"
                        font.pointSize: ScreenTools.smallFontPointSize
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScreenTools.defaultFontPixelWidth

                        QGCButton {
                            text: "Refresh Data"
                            onClicked: {
                                if (airspaceManager) {
                                    airspaceManager.refreshAirspaceData()
                                    _statusLabel.text = "Refreshing airspace data..."
                                    _statusLabel.color = qgcPal.text
                                }
                            }
                        }

                        QGCButton {
                            text: "Clear Cache"
                            onClicked: {
                                _clearCacheDialog.open()
                            }
                        }
                    }
                }
            }

            // Zone Type Legend
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth
                title: "Zone Type Legend"

                GridLayout {
                    anchors.fill: parent
                    columns: 3
                    rowSpacing: ScreenTools.defaultFontPixelHeight * 0.5
                    columnSpacing: ScreenTools.defaultFontPixelWidth

                    // Red Zone
                    Rectangle {
                        width: ScreenTools.defaultFontPixelHeight * 2
                        height: ScreenTools.defaultFontPixelHeight * 2
                        color: "#FF0000"
                        opacity: 0.4
                        border.color: "#8B0000"
                        border.width: 2
                    }
                    QGCLabel {
                        text: "Red Zone"
                        font.bold: true
                    }
                    QGCLabel {
                        text: "Prohibited - Flight Blocked"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    // Yellow Zone
                    Rectangle {
                        width: ScreenTools.defaultFontPixelHeight * 2
                        height: ScreenTools.defaultFontPixelHeight * 2
                        color: "#FFFF00"
                        opacity: 0.3
                        border.color: "#FFA500"
                        border.width: 2
                    }
                    QGCLabel {
                        text: "Yellow Zone"
                        font.bold: true
                    }
                    QGCLabel {
                        text: "Restricted - Warning"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    // Military Zone
                    Rectangle {
                        width: ScreenTools.defaultFontPixelHeight * 2
                        height: ScreenTools.defaultFontPixelHeight * 2
                        color: "#8B0000"
                        opacity: 0.5
                        border.color: "#FF0000"
                        border.width: 2
                    }
                    QGCLabel {
                        text: "Military"
                        font.bold: true
                    }
                    QGCLabel {
                        text: "Military Restricted - Warning"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    // Airport
                    Rectangle {
                        width: ScreenTools.defaultFontPixelHeight * 2
                        height: ScreenTools.defaultFontPixelHeight * 2
                        color: "#4169E1"
                        opacity: 0.3
                        border.color: "#000080"
                        border.width: 2
                    }
                    QGCLabel {
                        text: "Airport"
                        font.bold: true
                    }
                    QGCLabel {
                        text: "Airport Area - Warning"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }

                    // CTR
                    Rectangle {
                        width: ScreenTools.defaultFontPixelHeight * 2
                        height: ScreenTools.defaultFontPixelHeight * 2
                        color: "#9370DB"
                        opacity: 0.25
                        border.color: "#4B0082"
                        border.width: 2
                    }
                    QGCLabel {
                        text: "CTR"
                        font.bold: true
                    }
                    QGCLabel {
                        text: "Control Zone - Warning"
                        font.pointSize: ScreenTools.smallFontPointSize
                    }
                }
            }

            // Status
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: _statusColumn.height + ScreenTools.defaultFontPixelHeight
                Layout.margins: ScreenTools.defaultFontPixelWidth
                color: qgcPal.windowShade
                radius: ScreenTools.defaultFontPixelHeight * 0.25
                visible: _statusLabel.text !== ""

                ColumnLayout {
                    id: _statusColumn
                    anchors.centerIn: parent
                    width: parent.width - ScreenTools.defaultFontPixelWidth * 2
                    spacing: ScreenTools.defaultFontPixelHeight * 0.25

                    QGCLabel {
                        id: _statusLabel
                        text: ""
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Loading indicator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: _loadingRow.height + ScreenTools.defaultFontPixelHeight
                Layout.margins: ScreenTools.defaultFontPixelWidth
                color: qgcPal.windowShade
                radius: ScreenTools.defaultFontPixelHeight * 0.25
                visible: airspaceManager && airspaceManager.isLoading

                RowLayout {
                    id: _loadingRow
                    anchors.centerIn: parent
                    spacing: ScreenTools.defaultFontPixelWidth

                    BusyIndicator {
                        running: parent.parent.visible
                    }

                    QGCLabel {
                        text: "Loading airspace data..."
                    }
                }
            }
        }
    }

    // Clear cache confirmation dialog
    QGCPopupDialog {
        id: _clearCacheDialog
        title: "Clear Airspace Cache"
        buttons: Dialog.Yes | Dialog.No

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight

            QGCLabel {
                text: "Are you sure you want to clear the airspace cache?"
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            QGCLabel {
                text: "Cached data will be deleted and re-downloaded on next map view."
                font.pointSize: ScreenTools.smallFontPointSize
                color: qgcPal.warningText
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        onAccepted: {
            if (airspaceManager) {
                airspaceManager.clearCache()
                _statusLabel.text = "Cache cleared successfully"
                _statusLabel.color = qgcPal.colorGreen
            }
        }
    }

    // Monitor airspace manager signals
    Connections {
        target: airspaceManager

        function onZonesChanged() {
            if (airspaceManager) {
                _statusLabel.text = "Loaded " + airspaceManager.zones.length + " airspace zones"
                _statusLabel.color = qgcPal.colorGreen
            }
        }

        function onErrorMessageChanged() {
            if (airspaceManager && airspaceManager.errorMessage !== "") {
                _statusLabel.text = "Error: " + airspaceManager.errorMessage
                _statusLabel.color = qgcPal.colorRed
            }
        }
    }
}
