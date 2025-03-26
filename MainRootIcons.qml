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
import QGroundControl.QGCMapEngineManager
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

    property var map  // Add this property to hold a reference to the map
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle // Access the active drone

    property var flightMap

    property var    gcsPosition:                    QGroundControl.qgcPositionManger.gcsPosition


    spacing: 10  // Space between icons

    Component.onCompleted: {
        QGroundControl.mapEngineManager.loadTileSets()
    }

    Connections {
        target: _mapEngineManager
        onErrorMessageChanged: errorDialogComponent.createObject(mainWindow).open()
    }

    Rectangle {
        width: 40
        height: 40
        radius: width / 2
        color: "#B3B3B3"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                MapGlobals.mapRotation = 0
            }
        }

        Image {
            id: compassArrow
            source: "/qmlimages/NewImages/CompassArrow.png"
            anchors.centerIn: parent
            width: 45
            height: 45
            transform: Rotation {
                origin.x: compassArrow.width / 2
                origin.y: compassArrow.height / 2
                angle: -MapGlobals.mapRotation
            }
        }
    }

    Rectangle {
        width: 40
        height: 40
        radius: width / 2
        color: "#B3B3B3"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!_currentlyImportOrExporting) {
                    _mapEngineManager.importAction = QGCMapEngineManager.ActionNone
                    importDialogComponent.createObject(mainWindow).open()
                }
            }
        }

        Image {
            source: "/qmlimages/NewImages/Eraser.png"
            anchors.centerIn: parent
            width: 25
            height: 25
        }
    }

    Rectangle {
        width: 40
        height: 40
        radius: width / 2
        color: "#B3B3B3"

        MouseArea {
            anchors.fill: parent
            onClicked: {
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

        Image {
            source: "/qmlimages/NewImages/MapSwitch.png"
            anchors.centerIn: parent
            width: 25
            height: 25
        }
    }

    Rectangle   {
        width: 40
        height: 40
        radius: width / 2
        color: "#B3B3B3"

        MouseArea {
            anchors.fill: parent
            onClicked: {
                iconsContainer.visible = !iconsContainer.visible
            }
        }

        Image {
            source: "/qmlimages/NewImages/MapRedirect.png"
            anchors.centerIn: parent
            width: 25
            height: 25
        }

        // The container that holds the two icons, initially hidden
        Rectangle {
            id: iconsContainer
            width: 90
            height: 50
            radius: 10
            anchors.top: parent.bottom
            anchors.topMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -15
            border.color: "black"
            border.width: 2
            visible: false  // Hidden initially

            Row
            {
                id: iconRow
                anchors.centerIn: parent
                spacing: 10  // Space between the icons

                // First Image Icon
                Image {
                    id: icon1
                    source: "/qmlimages/NewImages/DroneRedirect.png"  // Replace with your actual image path
                    width: 45
                    height: 45
                    fillMode: Image.PreserveAspectFit

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("Clicked - Map valid:", !!map,
                                        "Vehicle valid:", !!_activeVehicle,
                                        "Coord valid:", map ? map._activeVehicleCoordinate.isValid : false)
                            MapGlobals.forceRecenter = true
                            MapGlobals.recenterInterval = 0
                            if (map) {
                                if (map.panRecenterTimer.running) {
                                    map.panRecenterTimer.stop()
                                }
                                map.panRecenterTimer.interval = 0
                                map.panRecenterTimer.start()
                            }

                            // Reset after 100ms to allow trigger
                            Qt.callLater(function() {
                                MapGlobals.recenterInterval = 10000
                                MapGlobals.forceRecenter = false
                            })
                        }
                    }
                }

                // Second Image Icon
                Image {
                    id: icon2
                    source: "/qmlimages/NewImages/MapRedirect1.png"  // Replace with your actual image path
                    width: 25
                    height: 25
                    fillMode: Image.PreserveAspectFit
                    //color : "white"
                    y: 8

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                           if(flightMap && flightMap.gcsPosition.isValid){
                               flightMap.center = flightMap.gcsPosition
                               flightMap.zoomLevel = 15
                           }

                        }
                    }
                }
            }
        }

    }


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
}
