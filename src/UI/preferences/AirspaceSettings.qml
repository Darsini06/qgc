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
                        text: "Airspace Information"
                        font.pointSize: ScreenTools.largeFontPointSize
                        font.bold: true
                    }

                    QGCLabel {
                        text: "View airspace zone legends and manage display preferences"
                        font.pointSize: ScreenTools.smallFontPointSize
                        color: qgcPal.text
                    }
                }
            }

            // Zone Type Legend & Selection
            GroupBox {
                Layout.fillWidth: true
                Layout.margins: ScreenTools.defaultFontPixelWidth
                title: "Airspace Zones & Legend"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScreenTools.defaultFontPixelHeight


                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: ScreenTools.defaultFontPixelHeight * 0.5
                        columnSpacing: ScreenTools.defaultFontPixelWidth

                        // Red Zone
                        QGCCheckBox {
                            id: _hideRed
                            checked: true
                            onClicked: { QGroundControl.saveGlobalSetting("Airspace.HideRed", !checked) }
                        }
                        Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            color: "#ff0505"
                            opacity: 0.6
                            border.color: "#ff0505"
                            border.width: 2
                        }
                        QGCLabel {
                            text: "Red Zone"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        QGCLabel {
                            text: "Prohibited - No Fly Area"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        // Inner Yellow Zone
                        QGCCheckBox {
                            id: _hideInnerYellow
                            checked: true
                            onClicked: { QGroundControl.saveGlobalSetting("Airspace.HideInnerYellow", !checked) }
                        }
                        Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            color: "#d48a00"
                            opacity: 0.5
                            border.color: "#d48a00"
                            border.width: 2
                        }
                        QGCLabel {
                            text: "Inner Yellow"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        QGCLabel {
                            text: "Restricted - ATC Permission Required"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        // Outer Yellow Zone
                        QGCCheckBox {
                            id: _hideOuterYellow
                            checked: true
                            onClicked: { QGroundControl.saveGlobalSetting("Airspace.HideOuterYellow", !checked) }
                        }
                        Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            color: "#b89b00"
                            opacity: 0.4
                            border.color: "#b89b00"
                            border.width: 2
                        }
                        QGCLabel {
                            text: "Outer Yellow"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        QGCLabel {
                            text: "Restricted - Height Limit 200ft"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        // Military Zone
                        QGCCheckBox {
                            id: _hideMilitary
                            checked: true
                            onClicked: { QGroundControl.saveGlobalSetting("Airspace.HideMilitary", !checked) }
                        }
                        Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            color: "#ff0505"
                            opacity: 0.6
                            border.color: "#ff0505"
                            border.width: 2
                        }
                        QGCLabel {
                            text: "Military"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        QGCLabel {
                            text: "Military Restricted - Warning"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        // Airport
                        QGCCheckBox {
                            id: _hideAirport
                            checked: true
                            onClicked: { QGroundControl.saveGlobalSetting("Airspace.HideAirport", !checked) }
                        }
                        Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            color: "#4169E1"
                            opacity: 0.3
                            border.color: "#000080"
                            border.width: 2
                        }
                        QGCLabel {
                            text: "Airport"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        QGCLabel {
                            text: "Airport Area - Warning"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        // CTR
                        QGCCheckBox {
                            id: _hideCTR
                            checked: true
                            onClicked: { QGroundControl.saveGlobalSetting("Airspace.HideCTR", !checked) }
                        }
                        Rectangle {
                            width: ScreenTools.defaultFontPixelHeight * 1.5
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            color: "#9370DB"
                            opacity: 0.25
                            border.color: "#4B0082"
                            border.width: 2
                        }
                        QGCLabel {
                            text: "CTR"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        QGCLabel {
                            text: "Control Zone - Warning"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }
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
