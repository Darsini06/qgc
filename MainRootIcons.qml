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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette
import QGroundControl.QGCMapEngineManager 1.0
import QGroundControl.FlightMap
import QGroundControl.Vehicle
import MapGlobals

Item {
    id: icons_root
    implicitWidth:  mainColumn.width
    implicitHeight: mainColumn.height

    // Shared responsive base
    property real baseSize: parent.width * 0.045
    property real iconSize: baseSize * 1.2

    property real mapRotation: 0
    property var _settingsManager: QGroundControl.settingsManager
    property var _mapEngineManager: QGroundControl.mapEngineManager
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property var flightMap
    property var planViewRef

    Component.onCompleted: {
        QGroundControl.mapEngineManager.loadTileSets()
    }
    function toggleIcons() {
        iconsContainer.visible = !iconsContainer.visible
    }

    // MAIN COLUMN: Action Buttons on top, Slider below
    Column {
        id: mainColumn
        anchors.right: parent.right
        spacing: 20

        // ROW OF ACTION ICONS
        Row {
            id: icons_row
            spacing: 12
            layoutDirection: Qt.RightToLeft

            //  ========== COMPASS ARROW ==========
            Rectangle {
                width: baseSize; height: baseSize; radius: width / 2; color: "transparent"; clip: true
                MouseArea { anchors.fill: parent; onClicked: { MapGlobals.mapRotation = 0; iconsContainer.visible = false; } }
                QGCColoredImage {
                    id: compassArrow
                    source: "/qmlimages/NewImages/cardinal_point.svg"
                    anchors.centerIn: parent; width: iconSize * 0.65; height: iconSize * 0.65
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation { origin.x: compassArrow.width / 2; origin.y: compassArrow.height / 2; angle: -MapGlobals.mapRotation }
                    color : "transparent"
                }
            }

            // Erase
            Rectangle {
                width: baseSize; height: baseSize; radius: width / 2; color: Qt.rgba(0, 0, 0, 0.40); clip: true
                MouseArea { anchors.fill: parent; onClicked: { if (planViewRef) planViewRef.mapclear() } }
                QGCColoredImage { source: "/qmlimages/NewImages/map_eraser.svg"; anchors.centerIn: parent; width: iconSize * 0.5; height: iconSize * 0.5; color : "white" }
            }

            // ========== MAP SWITCH ==========
            Rectangle {
                id: mapSwitchButton
                width: baseSize; height: baseSize; radius: width / 2; color: Qt.rgba(0, 0, 0, 0.40); clip: true
                MouseArea { anchors.fill: parent; onClicked: { iconsContainer.visible = false; if (mapTypePopup.opened) mapTypePopup.close(); else mapTypePopup.open(); } }
                QGCColoredImage { source: "/qmlimages/NewImages/map_switch.svg"; anchors.centerIn: parent; width: iconSize * 0.5; height: iconSize * 0.5; color : "white" }
                Popup {
                    id: mapTypePopup
                    y: parent.height + 8; x: - (width - parent.width); width: ScreenTools.defaultFontPixelWidth * 22; height: contentLayout.implicitHeight + 16; padding: 0; margins: 0
                    background: Rectangle { color: Qt.rgba(0, 0, 0, 0.4); radius: 12; border.color: Qt.rgba(255, 255, 255, 0.1); border.width: 1 }
                    contentItem: ColumnLayout {
                        id: contentLayout; spacing: 8; anchors.fill: parent; anchors.margins: 10
                        RowLayout {
                            Layout.fillWidth: true; Layout.preferredHeight: 18
                            Text { text: qsTr("Map type"); font.pixelSize: ScreenTools.defaultFontPointSize * 0.8; font.bold: true; color: "white"; Layout.fillWidth: true }
                            MouseArea { width: 18; height: 18; onClicked: mapTypePopup.close(); Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 18 } }
                        }
                        Row {
                            spacing: 6
                            Repeater {
                                model: [{ label: qsTr("Default"), type: "street", icon: "map_default.jpeg" }, { label: qsTr("Satellite"), type: "satellite", icon: "map_satellite.jpeg" }, { label: qsTr("Terrain"), type: "terrain", icon: "map_terrain.jpeg" }, { label: qsTr("Hybrid"), type: "hybrid", icon: "map_hybrid.jpeg" }]
                                Column {
                                    spacing: 4; width: (contentLayout.width - 30) / 4
                                    Rectangle {
                                        width: parent.width; height: width; radius: 8; color: "transparent"
                                        border.color: (QGroundControl.settingsManager.flightMapSettings.mapType.rawValue.toLowerCase().includes(modelData.type)) ? "#AC82FF" : Qt.rgba(255, 255, 255, 0.2)
                                        border.width: 1
                                        Image { anchors.fill: parent; source: "qrc:/qmlimages/NewImages/" + modelData.icon; fillMode: Image.AlwaysCrop }
                                        MouseArea { anchors.fill: parent; onClicked: { var types = _mapEngineManager.mapTypeList(QGroundControl.settingsManager.flightMapSettings.mapProvider.rawValue); var found = types.find(t => t.toLowerCase().includes(modelData.type)); if (found) QGroundControl.settingsManager.flightMapSettings.mapType.rawValue = found } }
                                    }
                                    Text { width: parent.width; text: modelData.label; horizontalAlignment: Text.AlignHCenter; color: "white"; font.pixelSize: ScreenTools.defaultFontPointSize * 0.6; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                }
            }

            // ========== MAP REDIRECT ==========
            Rectangle {
                id : mapRedirect
                width: baseSize; height: baseSize; radius: width / 2; color: Qt.rgba(0, 0, 0, 0.40); clip: false
                MouseArea { anchors.fill: parent; onClicked: toggleIcons() }
                QGCColoredImage { source: "/qmlimages/NewImages/redirect.svg"; anchors.centerIn: parent; width: iconSize * 0.5; height: iconSize * 0.5; color : "white" }
                Rectangle {
                    id: iconsContainer; width: baseSize * 2; height: baseSize * 1; radius: width * 0.1; color: Qt.rgba(0, 0, 0, 0.40); visible: false; z: 1000; anchors { top: parent.bottom; right: parent.right; topMargin: 5 }
                    Row {
                        anchors.centerIn: parent; spacing: 10
                        QGCColoredImage {
                            source: "/qmlimages/NewImages/drone_redirect.svg"; width: iconSize * 0.5; height: width; color : "white"
                            MouseArea { anchors.fill: parent; onClicked: { if(_activeVehicle) { MapGlobals.forceRecenter = true; MapGlobals.recenterInterval = 0; Qt.callLater(() => { MapGlobals.recenterInterval = 10000; MapGlobals.forceRecenter = false }) } else mainWindow.showToastMessage("Drone Not Connected"); iconsContainer.visible = false } }
                        }
                        QGCColoredImage {
                            source: "/qmlimages/NewImages/map_redirect.svg"; width: iconSize * 0.5; height: width; color : "white"
                            MouseArea { anchors.fill: parent; onClicked: { MapGlobals.recenterMap(); if(flightMap && flightMap.gcsPosition.isValid) flightMap.center = flightMap.gcsPosition; iconsContainer.visible = false } }
                        }
                    }
                }
            }

            QGCCompassWidget { size: baseSize * 1.5; vehicle: _activeVehicle; visible: _activeVehicle }
        }

        // --- SPRAY_PUMP_RATE Seekbar Loader ---
        // We wait for parametersReady so that getParameter() calls will succeed.
        Loader {
            id: sliderLoader
            anchors.right: parent.right
            active: _activeVehicle && _activeVehicle.parameterManager.parametersReady
            visible: active
            sourceComponent: sliderComponent
        }
    }

    Component {
        id: sliderComponent
        Rectangle {
            id: sliderContainer
            width: ScreenTools.defaultFontPixelWidth * 30
            height: sliderColumn.height + 20
            color: Qt.rgba(0, 0, 0, 0.40)
            radius: 8

            FactPanelController { id: controller }

            Column {
                id: sliderColumn
                anchors.centerIn: parent; spacing: 8; width: parent.width - 20
                Text { text: qsTr("Spray Pump Rate"); color: "white"; font.bold: true; font.pixelSize: ScreenTools.defaultFontPointSize }
                FactSlider {
                    id:     pumpSlider
                    fact:   controller.getParameterFact(-1, "SPRAY_PUMP_RATE")
                    width:  parent.width
                }
            }
        }
    }

    QGCFileDialog { id: fileDialog; folder: _appSettings.missionSavePath; nameFilters: [qsTr("Tile Sets (*.%1)").arg(defaultSuffix)]; defaultSuffix: _appSettings.tilesetFileExtension; onAcceptedForLoad: (file) => { close(); _mapEngineManager.importSets(file) } }
    Component { id: errorDialogComponent; QGCSimpleMessageDialog { title: qsTr("Error Message"); text: _mapEngineManager.errorMessage; buttons: Dialog.Close } }
    function clearMap() { if (!flightMap) return; try { if (_mapEngineManager && _mapEngineManager.deleteTileSet) { var tileSets = _mapEngineManager.tileSets; for (var i = 0; i < tileSets.length; i++) _mapEngineManager.deleteTileSet(tileSets[i].name) }; if (flightMap) { if (typeof flightMap.reload === "function") flightMap.reload(); if (typeof flightMap.clearMapItems === "function") flightMap.clearMapItems() }; mainWindow.showMessageDialog(qsTr("Map Cleared"), qsTr("Map cleared successfully")) } catch (error) { mainWindow.showMessageDialog(qsTr("Error"), qsTr("Failed to clear map: ") + error.toString()) } }
}
