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

    property var _mapsSettings: _settingsManager ? _settingsManager.mapsSettings : null
    property var _mapEngineManager: QGroundControl.mapEngineManager

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property bool _currentlyImportOrExporting: _mapEngineManager.importAction === QGCMapEngineManager.ActionExporting || _mapEngineManager.importAction === QGCMapEngineManager.ActionImporting

    property var _mapProviderFact: _settingsManager ? _settingsManager.flightMapSettings.mapProvider : null
    property var _mapTypeFact: _settingsManager ? _settingsManager.flightMapSettings.mapType : null

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
        RowLayout {
            id: icons_row
            spacing: 15
            layoutDirection: Qt.RightToLeft
            anchors.right: parent.right

            // ========== COMPASS ARROW ==========
            Rectangle {
                Layout.preferredWidth: baseSize
                Layout.preferredHeight: baseSize
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: "white"
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        MapGlobals.mapRotation = 0
                        iconsContainer.close();
                    }
                }

                QGCColoredImage {
                    id: compassArrow
                    source: "/qmlimages/NewImages/cardinal_point.svg"
                    anchors.centerIn: parent
                    width: iconSize * 0.65
                    height: iconSize * 0.65
                    fillMode: Image.PreserveAspectFit
                    transform: Rotation {
                        origin.x: compassArrow.width / 2
                        origin.y: compassArrow.height / 2
                        angle: -MapGlobals.mapRotation
                    }
                    color : "transparent"
                }

            }


            // Erase
            Rectangle {
                Layout.preferredWidth: baseSize
                Layout.preferredHeight: baseSize
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: "white"
                border.width: width * 0.05
                border.color: "white"
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        planViewRef.mapclear()
                    }
                }

                QGCColoredImage {
                    source: "/qmlimages/NewImages/map_eraser.svg"
                    anchors.centerIn: parent
                    width: iconSize * 0.5
                    height: iconSize * 0.5
                    color : "transparent"
                }
            }

            // ========== MAP SWITCH ==========
            Rectangle {
                id: mapSwitchButton
                Layout.preferredWidth: baseSize
                Layout.preferredHeight: baseSize
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: "white"
                border.width: width * 0.05
                border.color: "white"
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        iconsContainer.close();
                        if (mapTypePopup.opened) {
                            mapTypePopup.close();
                        } else {
                            mapTypePopup.open();
                        }
                    }
                }

                QGCColoredImage {
                    source: "/qmlimages/NewImages/map_switch.svg"
                    anchors.centerIn: parent
                    width: iconSize * 0.5
                    height: iconSize * 0.5
                    color : "black"
                }

                // Dropdown Popup for Map Types - BALANCED VERY SMALL VERSION
                Popup {
                    id: mapTypePopup
                    y: parent.height + 8
                    x: - (width - parent.width) // Right aligned with button
                    width: ScreenTools.defaultFontPixelWidth * 22
                    height: contentLayout.implicitHeight + 16
                    padding: 0
                    margins: 0

                    background: Rectangle {
                        color: "#2C2C2C" // Deep Dark Grey
                        radius: 12
                        border.color: "#3D3D3D"
                        border.width: 1

                        // Subtle compact shadow
                        layer.enabled: true
                        layer.effect: Qt.createQmlObject("import QtQuick; import QtQuick.Effects; MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowColor: \"#A0000000\"; shadowVerticalOffset: 3 }", mapTypePopup)
                    }

                    contentItem: ColumnLayout {
                        id: contentLayout
                        spacing: 8
                        anchors.fill: parent
                        anchors.topMargin: 10
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 20 // Adjusted for label containment

                        // Miniature Header with 'X'
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: qsTr("Map type")
                                font.pixelSize: ScreenTools.defaultFontPointSize * 0.8
                                font.bold: true
                                color: "#FFFFFF"
                            }

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                color: xMouseArea.containsMouse ? "#444444" : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Item {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: 1.2
                                        radius: 1
                                        color: "#FFFFFF"
                                        rotation: 45
                                        antialiasing: true
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: 1.2
                                        radius: 1
                                        color: "#FFFFFF"
                                        rotation: -45
                                        antialiasing: true
                                    }
                                }

                                MouseArea {
                                    id: xMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: mapTypePopup.close()
                                }
                            }
                        }

                        // Grid with Light Gaps
                        Row {
                            id: mapTypeGrid
                            Layout.fillWidth: true
                            spacing: 6 // Light gap between columns

                            readonly property string _rootPath: "qrc:/qmlimages/NewImages/"
                            readonly property string _selectionColor: "#AC82FF"

                            component MapIconColumn: Column {
                                property string label: ""
                                property string typeNameSuffix: ""
                                property string iconSource: ""
                                spacing: 6 // Light gap between image and text
                                width: (parent.width - 18) / 4

                                Rectangle {
                                    width: parent.width
                                    height: width
                                    radius: 8
                                    color: "#3D3D3D"
                                    border.color: _mapTypeFact.rawValue.toLowerCase().includes(typeNameSuffix.toLowerCase()) ? mapTypeGrid._selectionColor : "#444444"
                                    border.width: _mapTypeFact.rawValue.toLowerCase().includes(typeNameSuffix.toLowerCase()) ? 2 : 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: mapTypeGrid._rootPath + iconSource
                                        fillMode: Image.AlwaysCrop
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            var types = _mapEngineManager.mapTypeList(_mapProviderFact.rawValue)
                                            var found = types.find(t => t.toLowerCase().includes(typeNameSuffix.toLowerCase()))
                                            if (found) {
                                                _mapTypeFact.rawValue = found
                                            }
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: label
                                    horizontalAlignment: Text.AlignHCenter
                                    color: _mapTypeFact.rawValue.toLowerCase().includes(typeNameSuffix.toLowerCase()) ? mapTypeGrid._selectionColor : "#999999"
                                    font.pixelSize: ScreenTools.defaultFontPointSize * 0.65
                                    font.bold: _mapTypeFact.rawValue.toLowerCase().includes(typeNameSuffix.toLowerCase())
                                    elide: Text.ElideRight
                                }
                            }

                            MapIconColumn {
                                label: qsTr("Default")
                                typeNameSuffix: "street"
                                iconSource: "map_default.jpeg"
                            }
                            MapIconColumn {
                                label: qsTr("Satellite")
                                typeNameSuffix: "satellite"
                                iconSource: "map_satellite.jpeg"
                            }
                            MapIconColumn {
                                label: qsTr("Terrain")
                                typeNameSuffix: "terrain"
                                iconSource: "map_terrain.jpeg"
                            }
                            MapIconColumn {
                                label: qsTr("Hybrid")
                                typeNameSuffix: "hybrid"
                                iconSource: "map_hybrid.jpeg"
                            }
                        }
                    }
                }
            }

            // ========== MAP REDIRECT ==========
            Rectangle {
                id : mapRedirect
                Layout.preferredWidth: baseSize
                Layout.preferredHeight: baseSize
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: "white"
                border.width: width * 0.05
                border.color: "white"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Main button clicked");
                        toggleIcons()
                    }
                }

                QGCColoredImage {
                    source: "/qmlimages/NewImages/redirect.svg"
                    anchors.centerIn: parent
                    width: iconSize * 0.5
                    height: iconSize * 0.5
                    color : "black"
                }

                Popup {
                    id: iconsContainer
                    width: baseSize * 2
                    height: baseSize * 1
                    y: parent.height + baseSize * 0.1
                    x: parent.width - width  // Mirrors the leftMargin: -width and left: parent.right

                    padding: 0
                    margins: 0
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                    background: Rectangle {
                        radius: iconsContainer.width * 0.1
                        color: "#2C2C2C"
                        border.color: "#3D3D3D"
                        border.width: iconsContainer.width * 0.02
                    }

                    contentItem: Item {
                        Row {
                            anchors.centerIn: parent
                            spacing: baseSize * 0.4

                            QGCColoredImage {
                                id: icon1
                                source: "/qmlimages/NewImages/drone_redirect.svg"
                                width: iconSize * 0.5
                                height: iconSize * 0.5
                                fillMode: Image.PreserveAspectFit
                                color: "white"

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        console.log("DroneRedirect clicked");

                                        if(_activeVehicle){
                                            MapGlobals.forceRecenter = true;
                                            MapGlobals.recenterInterval = 0;

                                            Qt.callLater(function() {
                                                MapGlobals.recenterInterval = 10000;
                                                MapGlobals.forceRecenter = false;
                                            });
                                        }else {
                                            mainWindow.showToastMessage("Drone Not Connected");
                                        }

                                        iconsContainer.close();
                                    }
                                }
                            }

                            QGCColoredImage {
                                id: icon2
                                source: "/qmlimages/NewImages/map_redirect.svg"
                                width: iconSize * 0.5
                                height: iconSize * 0.5
                                fillMode: Image.PreserveAspectFit
                                color: "white"

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        console.log("MapRedirect1 clicked");
                                        MapGlobals.recenterMap();

                                        if(flightMap && flightMap.gcsPosition.isValid){

                                            flightMap.center = flightMap.gcsPosition;

                                        }else{

                                        }
                                        iconsContainer.close();
                                    }
                                }
                            }
                        }
                    }
                }
            }


            QGCCompassWidget {
                id:                     compass
                Layout.preferredHeight: baseSize * 1.5
                Layout.preferredWidth:  baseSize * 1.5
                Layout.alignment:       Qt.AlignVCenter
                size:                   baseSize * 1.5
                vehicle:                _activeVehicle
                visible :               _activeVehicle
            }

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

    // Import dialog component (kept for reference)
    Component {
        id: importDialogComponent

        QGCPopupDialog {
            title: qsTr("Import TileSets")
            buttons: Dialog.Ok | Dialog.Cancel

            onAccepted: {
                close()
                fileDialog.title = qsTr("Import Tiles")
                fileDialog.openForLoad()
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth / 2

                QGCRadioButton {
                    text: qsTr("Append to existing sets")
                    checked: !_mapEngineManager.importReplace
                    onClicked: _mapEngineManager.importReplace = !checked
                }

                QGCRadioButton {
                    text: qsTr("Replace existing sets")
                    checked: _mapEngineManager.importReplace
                    onClicked: _mapEngineManager.importReplace = checked
                }
            }
        }
    }

    QGCFileDialog {
        id: fileDialog
        folder: _appSettings.missionSavePath
        nameFilters: [qsTr("Tile Sets (*.%1)").arg(defaultSuffix)]
        defaultSuffix: _appSettings.tilesetFileExtension

        onAcceptedForLoad: (file) => {
                               close()
                               _mapEngineManager.importSets(file)
                           }
    }

    Component {
        id: errorDialogComponent

        QGCSimpleMessageDialog {
            title: qsTr("Error Message")
            text: _mapEngineManager.errorMessage
            buttons: Dialog.Close
        }
    }

    // Function to clear the map - revised to use available methods
    function clearMap() {

        if (!flightMap) {
            console.error("Flight map is not defined");
            return;
        }

        // Use the available methods from QGCMapEngineManager to clear the map
        try {
            // Delete all tile sets
            if (_mapEngineManager && _mapEngineManager.deleteTileSet) {
                // Delete all existing tile sets
                var tileSets = _mapEngineManager.tileSets
                for (var i = 0; i < tileSets.length; i++) {
                    _mapEngineManager.deleteTileSet(tileSets[i].name)
                }
            }

            // Try to use existing QGC methods to reset/reload the map
            if (flightMap) {
                // Force map to reload with default empty state
                if (typeof flightMap.reload === "function") {
                    flightMap.reload()
                }

                // Clear any mission items, polygons, etc.
                if (typeof flightMap.clearMapItems === "function") {
                    flightMap.clearMapItems()
                }
            }

            // Reset to default map provider if needed
            if (_mapProviderFact && _mapProviderFact.defaultValue !== undefined) {
                _mapProviderFact.rawValue = _mapProviderFact.defaultValue
            }

            // Reset to default map type if needed
            if (_mapTypeFact && _mapTypeFact.defaultValue !== undefined) {
                _mapTypeFact.rawValue = _mapTypeFact.defaultValue
            }

            // Show success message
            var message = qsTr("Map cleared successfully")
            if (typeof mainWindow.showMessageDialog === "function") {
                mainWindow.showMessageDialog(qsTr("Map Cleared"), message)
            }

        } catch (error) {

            console.error("Error clearing map:", error)

            // Show error message
            if (typeof mainWindow.showMessageDialog === "function") {

                mainWindow.showMessageDialog(
                            qsTr("Error"),
                            qsTr("Failed to clear map: ") + error.toString())

            }
        }
    }

}
