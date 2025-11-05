
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
import MapGlobals 1.0

Row {
    id: icons_row
    property real mapRotation: 0
    property var _settingsManager: QGroundControl.settingsManager
    property var _mapsSettings: _settingsManager ? _settingsManager.mapsSettings : null
    property var _mapEngineManager: QGroundControl.mapEngineManager
    property bool _currentlyImportOrExporting: _mapEngineManager.importAction === QGCMapEngineManager.ActionExporting || _mapEngineManager.importAction === QGCMapEngineManager.ActionImporting

    property var _mapProviderFact: _settingsManager ? _settingsManager.flightMapSettings.mapProvider : null
    property var _mapTypeFact: _settingsManager ? _settingsManager.flightMapSettings.mapType : null

    property var flightMap

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property real   _maxWidth:          ScreenTools.defaultFontPixelHeight * 15
    property real   _innerRadius:       (width - (_topBottomMargin * 3)) / 4
    property real   _outerRadius:       _innerRadius + _topBottomMargin
    property real   _spacing:           ScreenTools.defaultFontPixelHeight * 0.33
    property real   _topBottomMargin:   (width * 0.05) / 2

    spacing: 10  // Space between icons

    Component.onCompleted: {
        QGroundControl.mapEngineManager.loadTileSets()
    }

    Connections {
        target: _mapEngineManager
        onErrorMessageChanged: errorDialogComponent.createObject(mainWindow).open()
    }

    function toggleIcons() {
        iconsContainer.visible = !iconsContainer.visible;
    }

    // CompassArrow
    Rectangle {
        width: 40
        height: 40
        radius: width / 2   // Makes it a circle
        color: "#1b1c3e"    // Dark blue background
        border.width: width * 0.05
        border.color: "#005BBB"
        clip: true          // This ensures content stays within the circular bounds

        MouseArea {
            anchors.fill: parent
            onClicked: {
                MapGlobals.mapRotation = 0

                iconsContainer.visible = false;
            }
        }

        QGCColoredImage {
            id: takeofficon
            source: "/qmlimages/NewImages/CompassArrow.png"
            anchors.centerIn: parent
            width: 45
            height: 45
            transform: Rotation {
                origin.x: takeofficon.width / 2    // Changed from compassArrow to takeofficon
                origin.y: takeofficon.height / 2   // Changed from compassArrow to takeofficon
                angle: -MapGlobals.mapRotation
            }
        }
    }

    // Rectangle {
    //     width: 40
    //     height: 40
    //     radius: width / 2
    //     color: "#B3B3B3"

    //     MouseArea {
    //         anchors.fill: parent
    //         onClicked: {
    //             // Show confirmation dialog before clearing the map
    //             clearMapDialogComponent.createObject(mainWindow).open()
    //         }
    //     }

    //     Image {
    //         source: "/qmlimages/NewImages/Eraser.png"
    //         anchors.centerIn: parent
    //         width: 25
    //         height: 25
    //     }
    // }

    // Erase
    Rectangle {
        width: 40
        height: 40
        radius: width / 2   // Makes it a circle
        color: "#1b1c3e"    // Dark blue background
        border.width: width * 0.05
        border.color: "#005BBB"
        clip: true          // This ensures content stays within the circular bounds

        MouseArea {
            anchors.fill: parent
            onClicked: {
                iconsContainer.visible = false;

                clearMapDialogComponent.createObject(mainWindow).open()

            }
        }

        QGCColoredImage {
            source: "/qmlimages/NewImages/Eraser.png"
            anchors.centerIn: parent
            width: 25
            height: 25
        }
    }

    // Rectangle {
    //     width: 40
    //     height: 40
    //     radius: width / 2
    //     color: "#B3B3B3"

    //     MouseArea {
    //         anchors.fill: parent
    //         onClicked: {
    //             if (!_mapProviderFact || !_mapTypeFact) {
    //                 console.error("Map provider or map type fact is not defined.");
    //                 return;
    //             }
    //             var mapTypes = _mapEngineManager.mapTypeList(_mapProviderFact.rawValue);
    //             if (mapTypes.length === 0) return;
    //             var currentIndex = mapTypes.indexOf(_mapTypeFact.rawValue);
    //             if (currentIndex === -1) currentIndex = 0;
    //             var nextIndex = (currentIndex + 1) % mapTypes.length;
    //             _mapTypeFact.rawValue = mapTypes[nextIndex];
    //         }
    //     }

    //     Image {
    //         source: "/qmlimages/NewImages/MapSwitch.png"
    //         anchors.centerIn: parent
    //         width: 25
    //         height: 25
    //     }
    // }


    // Map Switch
    Rectangle {
        width: 40
        height: 40
        radius: width / 2   // Makes it a circle
        color: "#1b1c3e"    // Dark blue background
        border.width: width * 0.05
        border.color: "#005BBB"
        clip: true          // This ensures content stays within the circular bounds

        MouseArea {
            anchors.fill: parent
            onClicked: {

                iconsContainer.visible = false;

                if (!_mapProviderFact || !_mapTypeFact) {
                    console.error("Map provider or map type fact is not defined.");
                    return;
                }
                var mapTypes = _mapEngineManager.mapTypeList(_mapProviderFact.rawValue);
                if (mapTypes.length === 0) return;
                var currentIndex = mapTypes.indexOf(_mapTypeFact.rawValue);
                if (currentIndex === -1) currentIndex = 0;
                var nextIndex = (currentIndex + 1) % mapTypes.length;
                _mapTypeFact.rawValue = mapTypes[nextIndex];
            }
        }

        QGCColoredImage {
            source: "/qmlimages/NewImages/MapSwitch.png"
            anchors.centerIn: parent
            width: 25
            height: 25
        }
    }

    // Rectangle {
    //     width: 40
    //     height: 40
    //     radius: width / 2
    //     color: "#B3B3B3"

    //     MouseArea {
    //         anchors.fill: parent
    //         onClicked: {
    //             iconsContainer.visible = !iconsContainer.visible
    //         }
    //     }

    //     Image {
    //         source: "/qmlimages/NewImages/MapRedirect.png"
    //         anchors.centerIn: parent
    //         width: 25
    //         height: 25
    //     }

    //     // The container that holds the two icons, initially hidden
    //     Rectangle {
    //         id: iconsContainer
    //         width: 90
    //         height: 50
    //         radius: 10
    //         anchors.top: parent.bottom
    //         anchors.topMargin: 5
    //         anchors.horizontalCenter: parent.horizontalCenter
    //         anchors.horizontalCenterOffset: -15
    //         border.color: "black"
    //         border.width: 2
    //         visible: false  // Hidden initially

    //         Row {
    //             id: iconRow
    //             anchors.centerIn: parent
    //             spacing: 10  // Space between the icons

    //             Image {
    //                 id: icon1
    //                 source: "/qmlimages/NewImages/DroneRedirect.png"
    //                 width: 45
    //                 height: 45
    //                 fillMode: Image.PreserveAspectFit

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         MapGlobals.forceRecenter = true
    //                         MapGlobals.recenterInterval = 0

    //                         iconsContainer.visible = false

    //                         Qt.callLater(function() {
    //                             MapGlobals.recenterInterval = 10000
    //                             MapGlobals.forceRecenter = false
    //                         })
    //                     }
    //                 }
    //             }

    //             Image {
    //                 id: icon2
    //                 source: "/qmlimages/NewImages/MapRedirect1.png"
    //                 width: 25
    //                 height: 25
    //                 fillMode: Image.PreserveAspectFit
    //                 y: 8

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     onClicked: {
    //                         MapGlobals.recenterMap()

    //                         if(flightMap && flightMap.gcsPosition.isValid) {
    //                             flightMap.center = flightMap.gcsPosition
    //                         }

    //                         iconsContainer.visible = false
    //                     }
    //                 }
    //             }
    //         }
    //     }

    // }


    Rectangle {
        id : mapRedirect
        width: 40
        height: 40
        radius: width / 2
        color: "#1b1c3e"
        border.width: 2
        border.color: "#005BBB"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("Main button clicked");
                toggleIcons()
            }
        }

        QGCColoredImage {
            source: "/qmlimages/NewImages/MapRedirect.png"
            anchors.centerIn: parent
            width: 25
            height: 25
            color: "white"
        }

        Rectangle {
            id: iconsContainer
            width: 100  // Increased for better spacing
            height: 50
            radius: 10
            color: "#1b1c3e"
            border.color: "#005BBB"
            border.width: 2
            visible: false
            z: 1000

            // Centered below button
            anchors {
                top: parent.bottom
                left: parent.right
                topMargin: 5
                leftMargin: -width

                // top: parent.bottom
                // horizontalCenter: parent.horizontalCenter
                // topMargin: 5
            }

            Row {
                anchors.centerIn: parent
                spacing: 20  // Increased spacing

                QGCColoredImage {
                    id: icon1
                    source: "/qmlimages/NewImages/DroneRedirect.png"
                    width: 25  // Restored original size
                    height: 25
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

                            iconsContainer.visible = false;
                        }
                    }
                }

                QGCColoredImage {
                    id: icon2
                    source: "/qmlimages/NewImages/MapRedirect1.png"
                    width: 25
                    height: 25
                    fillMode: Image.PreserveAspectFit
                    color: "white"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("MapRedirect1 clicked");
                            MapGlobals.recenterMap();

                            if(flightMap && flightMap.gcsPosition.isValid){

                                flightMap.center = flightMap.gcsPosition;
                            }/*else{
                                mainWindow.showToastMessage("GPS Not Showed");
                            }*/
                            iconsContainer.visible = false;
                        }
                    }
                }
            }
        }
    }

    // Rectangle {
    //     id:                 visualInstrument
    //     width: _outerRadius
    //     height:             _outerRadius * 1.8
    //     //Layout.fillWidth:   true
    //     radius:             _outerRadius
    //     color:              "white"//qgcPal.window

    //     QGCCompassWidget {
    //         id:                     compass
    //         //anchors.centerIn: parent
    //         size:                   _innerRadius * 1.8
    //         vehicle:                globals.activeVehicle
    //         //anchors.verticalCenter: parent.verticalCenter
    //     }
    // }


    QGCCompassWidget {
        id:                     compass
        //anchors.centerIn: parent
        size:                   _innerRadius * 1.2
        vehicle:                globals.activeVehicle
        //anchors.verticalCenter: parent.verticalCenter
    }


    // New confirmation dialog for clearing the map
    Component {
        id: clearMapDialogComponent

        QGCPopupDialog {
            title: qsTr("Clear Map")
            buttons: Dialog.Yes | Dialog.No

            onAccepted: {
                clearMap()
                close()
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel {
                    text: qsTr("Are you sure you want to clear the map?")
                    Layout.fillWidth: true
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
                            qsTr("Failed to clear map: ") + error.toString()
                            )

            }
        }
    }

}
