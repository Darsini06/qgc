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
import QtLocation
import QtPositioning
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.settings 1.0
import QGroundControl
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controllers
import QGroundControl.ShapeFileHelper
import QGroundControl.FlightDisplay
import QGroundControl.UTMSP
import MapGlobals 1.0

Item {
    id: _root


    property bool planControlColapsed: false

    readonly property int   _decimalPlaces:             8
    readonly property real  _margin:                    ScreenTools.defaultFontPixelHeight * 0.5
    readonly property real  _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    readonly property real  _radius:                    ScreenTools.defaultFontPixelWidth  * 0.5
    readonly property real  _rightPanelWidth:           Math.min(width / 3, ScreenTools.defaultFontPixelWidth * 20)
    readonly property var   _defaultVehicleCoordinate:  QtPositioning.coordinate(37.803784, -122.462276)
    readonly property bool  _waypointsOnlyMode:         QGroundControl.corePlugin.options.missionWaypointsOnly

    property var    _planMasterController:              planMasterController
    property var    _missionController:                 _planMasterController.missionController
    property var    _geoFenceController:                _planMasterController.geoFenceController
    property var    _rallyPointController:              _planMasterController.rallyPointController
    property var    _visualItems:                       _missionController.visualItems
    property bool   _lightWidgetBorders:                editorMap.isSatelliteMap
    property bool   _addROIOnClick:                     false
    property bool   _singleComplexItem:                 _missionController.complexMissionItemNames.length === 1
    property int    _editingLayer:                      {if(!_utmspEnabled){layerTabBar.currentIndex ? _layers[layerTabBar.currentIndex] : _layerMission}else{layerTabBarUTMSP.currentIndex ? _layersUTMSP[layerTabBarUTMSP.currentIndex] : _layerMission}}
    property int    _toolStripBottom:                   toolStrip.height + toolStrip.y
    property var    _appSettings:                       QGroundControl.settingsManager.appSettings
    property var    _planViewSettings:                  QGroundControl.settingsManager.planViewSettings
    property bool   _promptForPlanUsageShowing:         false
    property bool   _utmspEnabled:                      QGroundControl.utmspSupported
    property bool   _resetGeofencePolygon:              false   //Reset the Geofence Polygon
    property var    _vehicleID
    property bool   _triggerSubmit
    property bool   _resetRegisterFlightPlan

    readonly property var       _layers:                    [_layerMission, _layerGeoFence, _layerRallyPoints]
    readonly property var       _layersUTMSP:               [_layerMission, _layerRallyPoints, _layerUTMSP] //Adds additional UTMSP layer

    readonly property int       _layerMission:              1
    readonly property int       _layerGeoFence:             2
    readonly property int       _layerRallyPoints:          3
    readonly property int       _layerUTMSP:                4 // Additional Tab button when UTMSP is enabled
    readonly property string    _armedVehicleUploadPrompt:  qsTr("Vehicle is currently armed. Do you want to upload the mission to the vehicle?")

    property string planType:""

    property string passedValue: ""
    property var selectedPlanCreator: null

    property var  _activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle
    property string droneType: "loadpage"

    //     Component.onCompleted: {
    //         console.log("PlanView received planType:", _appSettings.screenplanType);

    // console.log("PlanView creater", _planMasterController.planCreators);

    //         var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2),
    //                                    editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
    //         var centerCoord = editorMap.toCoordinate(centerPoint, false)
    //         _planMasterController.planCreators[0].createPlan(centerCoord)

    //             //createPlanRemoveAllPromptDialog.createObject(mainWindow, { mapCenter: _mapCenter(), planCreator: object }).open()
    //             //_planMasterController.planCreator[0].createPlan(mapCenter)

    //     }
    function mapclear() {
        console.log("MapClear")
        if (_utmspEnabled) {
            QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
            UTMSPStateStorage.removeFlightPlanState = true
            UTMSPStateStorage.indicatorDisplayStatus = true
        }
        _planMasterController.removeAll()
        //_planMasterController.upload();
        uploadload()
    }

    function uploadload() {
        if (_utmspEnabled) {
            QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
            UTMSPStateStorage.removeFlightPlanState = true
            UTMSPStateStorage.indicatorDisplayStatus = true
        }
        // _planMasterController.removeAll()
        _planMasterController.upload();
    }

    function mapCenter() {
        var coordinate = editorMap.center
        coordinate.latitude  = coordinate.latitude.toFixed(_decimalPlaces)
        coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
        coordinate.altitude  = coordinate.altitude.toFixed(_decimalPlaces)
        return coordinate
    }

    property bool _firstMissionLoadComplete:    false
    property bool _firstFenceLoadComplete:      false
    property bool _firstRallyLoadComplete:      false
    property bool _firstLoadComplete:           false



    function loaddata() {
        _planMasterController.loadFromSelectedFile()
        editdata.visible=true
        MapGlobals.share_edit_visibility = true
    }

    function loaddata1() {
        _planMasterController.loadFromSelectedFile1()
        editdata.visible=false
        MapGlobals.share_edit_visibility = false

    }

    function loaddata2() {
        //_planMasterController.loadFromSelectedFile1()
        editdata.visible=true
        MapGlobals.share_edit_visibility = true
    }

    function data1(){
        _planMasterController.data()
        //mobileFileSaveDialogComponent.createObject(mainWindow).open()
    }

    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 20
        anchors.rightMargin: 20
        spacing: 20  // Adjust this value to control space between icons

        Rectangle {
            id: sharebtn
            Layout.alignment: Qt.AlignRight
            width: 40
            height: 40
            radius: width / 2  // Makes it a circle
            color: "black"     // Black background
            visible: true



            QGCColoredImage {
                source: "qrc:/InstrumentValueIcons/share-alt.svg"
                width: 24
                height: 24
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked:
                {
                    dialog.open()
                }

                // onClicked: {
                //     // mainWindow.showPlanView()
                //     // //viewer3DWindow.close()

                // }
            }
        }

    }

    MapFitFunctions {
        id:                         mapFitFunctions  // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        editorMap
        usePlannedHomePosition:     true
        planMasterController:       _planMasterController
    }

    onVisibleChanged: {
        if(visible) {
            droneType = QGroundControl.loadGlobalSetting("loadpage","loadpage");
            editorMap.zoomLevel = QGroundControl.flightMapZoom
            editorMap.center    = QGroundControl.flightMapPosition
            if (!_planMasterController.containsItems) {
                toolStrip.simulateClick(toolStrip.fileButtonIndex)
            }
        }
    }


    Connections {
        target: _appSettings ? _appSettings.defaultMissionItemAltitude : null
        function onRawValueChanged() {
            if (_visualItems.count > 1) {
                mainWindow.showMessageDialog(qsTr("Apply new altitude"),
                                             qsTr("You have changed the default altitude for mission items. Would you like to apply that altitude to all the items in the current mission?"),
                                             Dialog.Yes | Dialog.No,
                                             function() { _missionController.applyDefaultMissionAltitude() })
            }
        }
    }

    Component {
        id: promptForPlanUsageOnVehicleChangePopupComponent
        QGCPopupDialog {
            title:      _planMasterController.managerVehicle.isOfflineEditingVehicle ? qsTr("Plan View - Vehicle Disconnected") : qsTr("Plan View - Vehicle Changed")
            buttons:    Dialog.NoButton

            ColumnLayout {
                QGCLabel {
                    Layout.maximumWidth:    parent.width
                    wrapMode:               QGCLabel.WordWrap
                    text:                   _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                qsTr("The vehicle associated with the plan in the Plan View is no longer available. What would you like to do with that plan?") :
                                                qsTr("The plan being worked on in the Plan View is not from the current vehicle. What would you like to do with that plan?")
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.dirty ?
                                            (_planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                 qsTr("Discard Unsaved Changes") :
                                                 qsTr("Discard Unsaved Changes, Load New Plan From Vehicle")) :
                                            qsTr("Load New Plan From Vehicle")
                    onClicked: {
                        _planMasterController.showPlanFromManagerVehicle()
                        _promptForPlanUsageShowing = false
                        close();
                    }
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                            qsTr("Keep Current Plan") :
                                            qsTr("Keep Current Plan, Don't Update From Vehicle")
                    onClicked: {
                        if (!_planMasterController.managerVehicle.isOfflineEditingVehicle) {
                            _planMasterController.dirty = true
                        }
                        _promptForPlanUsageShowing = false
                        close()
                    }
                }
            }
        }
    }

    PlanMasterController {
        id:         planMasterController
        flyView:    false

        Component.onCompleted: {
            _planMasterController.start()
            _missionController.setCurrentPlanViewSeqNum(0, true)
        }

        onPromptForPlanUsageOnVehicleChange: {
            if (!_promptForPlanUsageShowing) {
                _promptForPlanUsageShowing = true
                promptForPlanUsageOnVehicleChangePopupComponent.createObject(mainWindow).open()
            }
        }

        function waitingOnIncompleteDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan has incomplete items. Complete all items and %1 again.").arg(saveOrUpload))
        }

        function waitingOnTerrainDataMessage(save) {
            var saveOrUpload = save ? qsTr("Save") : qsTr("Upload")
            mainWindow.showMessageDialog(qsTr("Unable to %1").arg(saveOrUpload), qsTr("Plan is waiting on terrain data from server for correct altitude values."))
        }

        function checkReadyForSaveUpload(save) {
            if (readyForSaveState() == VisualMissionItem.NotReadyForSaveData) {
                waitingOnIncompleteDataMessage(save)
                return false
            } else if (readyForSaveState() == VisualMissionItem.NotReadyForSaveTerrain) {
                waitingOnTerrainDataMessage(save)
                return false
            }
            return true
        }

        function upload() {
            if (!checkReadyForSaveUpload(false /* save */)) {
                return
            }
            switch (_missionController.sendToVehiclePreCheck()) {
            case MissionController.SendToVehiclePreCheckStateOk:
                sendToVehicle()
                break
            case MissionController.SendToVehiclePreCheckStateActiveMission:
                mainWindow.showMessageDialog(qsTr("Send To Vehicle"), qsTr("Current mission must be paused prior to uploading a new Plan"))
                break
            case MissionController.SendToVehiclePreCheckStateFirwmareVehicleMismatch:
                mainWindow.showMessageDialog(qsTr("Plan Upload"),
                                             qsTr("This Plan was created for a different firmware or vehicle type than the firmware/vehicle type of vehicle you are uploading to. " +
                                                  "This can lead to errors or incorrect behavior. " +
                                                  "It is recommended to recreate the Plan for the correct firmware/vehicle type.\n\n" +
                                                  "Click 'Ok' to upload the Plan anyway."),
                                             Dialog.Ok | Dialog.Cancel,
                                             function() { _planMasterController.sendToVehicle() })
                break
            }
        }

        function loadFromSelectedFile() {
            fileDialog.title =          qsTr("Select Plan File")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.loadNameFilters1
            fileDialog.openForLoad()
        }

        function loadFromSelectedFile1() {
            fileDialog.title =          qsTr("Select Plan File")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.loadNameFilters
            fileDialog.openForLoad()
        }
        function saveToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save Plan")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.saveNameFilters1
            fileDialog.openForSave()
        }

        function data() {
            // Find the SurveyPlanCreator in the list
            var surveyCreator = null
            for (var i = 0; i < _planMasterController.planCreators.count; i++) {
                var creator = _planMasterController.planCreators.get(i)
                if (creator.name === "Survey") { // Adjust this check based on your actual creator's name property
                    surveyCreator = creator
                    break
                }
            }

            if (surveyCreator) {
                console.log("surveyCreator",surveyCreator)
                QGroundControl.saveGlobalSetting("surveyCreator", surveyCreator)
                // Calculate center coordinate
                var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2),
                                           editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
                var centerCoord = editorMap.toCoordinate(centerPoint, false)

                // Create the plan
                surveyCreator.createPlan(centerCoord)


            } else {
                console.log("Survey plan creator not found")
            }
            if(QGroundControl.loadGlobalSetting("mapping","mapping")==="basic"){
                filename._resetPolygon()
            }else if(QGroundControl.loadGlobalSetting("mapping","mapping")==="circle"){
                filename._resetCircle()
            }



        }

        function saveToSelectedFile1() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save Plan")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.saveNameFilters1
            fileDialog.openForSave()
        }

        function fitViewportToItems() {
            mapFitFunctions.fitMapViewportToMissionItems()
        }

        function saveKmlToSelectedFile() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save KML")
            fileDialog.planFiles =      false
            fileDialog.nameFilters =    ShapeFileHelper.fileDialogKMLFilters
            fileDialog.openForSave()
        }
    }


    Connections {
        target: _missionController

        function onNewItemsFromVehicle() {
            if (_visualItems && _visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
            }
            _missionController.setCurrentPlanViewSeqNum(0, true)
        }
    }

    function insertSimpleItemAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertROIAfterCurrent(coordinate) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertROIMissionItem(coordinate, nextIndex, true /* makeCurrentItem */)
    }

    function insertCancelROIAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertCancelROIMissionItem(nextIndex, true /* makeCurrentItem */)
    }

    function insertComplexItemAfterCurrent(complexItemName) {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertComplexMissionItem(complexItemName, mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertTakeItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertTakeoffItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function insertLandItemAfterCurrent() {
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertLandItem(mapCenter(), nextIndex, true /* makeCurrentItem */)
    }

    function selectNextNotReady() {
        var foundCurrent = false
        for (var i=0; i<_missionController.visualItems.count; i++) {
            var vmi = _missionController.visualItems.get(i)
            if (vmi.readyForSaveState === VisualMissionItem.NotReadyForSaveData) {
                _missionController.setCurrentPlanViewSeqNum(vmi.sequenceNumber, true)
                break
            }
        }
    }
    QGCMapPolygonVisuals{
        id:filename
    }

    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings ? _appSettings.missionSavePath : ""

        property bool planFiles: true    ///< true: working with plan files, false: working with kml file

        onAcceptedForSave: (file) => {
                               if (planFiles) {
                                   _planMasterController.saveToFile1(file)
                                   mainWindow.showFlyView()
                               } else {
                                   _planMasterController.saveToKml(file)
                               }
                               close()
                           }

        onAcceptedForLoad: (file) => {
                               _planMasterController.loadFromFile(file)
                               _planMasterController.fitViewportToItems()
                               _missionController.setCurrentPlanViewSeqNum(0, true)
                               close()


                               mainWindow.showPlanView()
                           }
    }

    TransectStyleMapVisuals {
        id:                     transect

    }

    PlanViewToolBar {
        id:                     planToolBar
        planMasterController:   _planMasterController
        //plantypes:planType
    }

    Item {
        id:             panel
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    planToolBar.bottom
        anchors.bottom: parent.bottom

        FlightMap {
            id:                         editorMap
            anchors.fill:               parent
            mapName:                    "MissionEditor"
            allowGCSLocationCenter:     true
            allowVehicleLocationCenter: true
            planView:                   true

            zoomLevel:                  QGroundControl.flightMapZoom
            center:                     QGroundControl.flightMapPosition

            // This is the center rectangle of the map which is not obscured by tools
            property rect centerViewport:   Qt.rect(_leftToolWidth + _margin,  _margin, editorMap.width - _leftToolWidth - _rightToolWidth - (_margin * 2), (terrainStatus.visible ? terrainStatus.y : height - _margin) - _margin)

            property real _leftToolWidth:       toolStrip.x + toolStrip.width
            property real _rightToolWidth:      rightPanel.width + rightPanel.anchors.rightMargin
            property real _nonInteractiveOpacity:  0.5

            // Initial map position duplicates Fly view position
            Component.onCompleted: editorMap.center = QGroundControl.flightMapPosition

            QGCMapPalette { id: mapPal; lightColors: editorMap.isSatelliteMap }

            onZoomLevelChanged: {
                QGroundControl.flightMapZoom = editorMap.zoomLevel
            }
            onCenterChanged: {
                QGroundControl.flightMapPosition = editorMap.center
            }

            onMapClicked: (mouse) => {

                              // Take focus to close any previous editing
                              editorMap.focus = true
                              var coordinate = editorMap.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                              coordinate.latitude = coordinate.latitude.toFixed(_decimalPlaces)
                              coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
                              coordinate.altitude = coordinate.altitude.toFixed(_decimalPlaces)
                              if(_utmspEnabled){
                                  QGroundControl.utmspManager.utmspVehicle.updateLastCoordinates(coordinate.latitude, coordinate.longitude)
                              }

                              switch (_editingLayer) {
                                  case _layerMission:
                                  if (addWaypointRallyPointAction.checked) {
                                      insertSimpleItemAfterCurrent(coordinate)
                                  } else if (_addROIOnClick) {
                                      insertROIAfterCurrent(coordinate)
                                      _addROIOnClick = false
                                  }

                                  break
                                  case _layerRallyPoints:
                                  if (_rallyPointController.supported && addWaypointRallyPointAction.checked) {
                                      _rallyPointController.addPoint(coordinate)
                                  }
                                  break

                                  case _layerUTMSP:
                                  if (addWaypointRallyPointAction.checked) {
                                      insertSimpleItemAfterCurrent(coordinate)
                                  } else if (_addROIOnClick) {
                                      insertROIAfterCurrent(coordinate)
                                      _addROIOnClick = false
                                  }
                                  break
                              }
                          }

            // Add the mission item visuals to the map
            Repeater {
                model: _missionController.visualItems
                delegate: MissionItemMapVisual {
                    map:         editorMap
                    opacity:     _editingLayer == _layerMission || _editingLayer == _layerUTMSP ? 1 : editorMap._nonInteractiveOpacity
                    interactive: _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                    vehicle:     _planMasterController.controllerVehicle
                    onClicked:   (sequenceNumber) => { _missionController.setCurrentPlanViewSeqNum(sequenceNumber, false) }
                }
            }

            // Add lines between waypoints
            MissionLineView {
                showSpecialVisual:  _missionController.isROIBeginCurrentItem
                model:              _missionController.simpleFlightPathSegments
                opacity:            _editingLayer == _layerMission ||  _editingLayer == _layerUTMSP  ? 1 : editorMap._nonInteractiveOpacity
            }

            // Direction arrows in waypoint lines
            MapItemView {
                model: _editingLayer == _layerMission ||_editingLayer == _layerUTMSP ? _missionController.directionArrows : undefined

                delegate: MapLineArrow {
                    fromCoord:      object ? object.coordinate1 : undefined
                    toCoord:        object ? object.coordinate2 : undefined
                    arrowPosition:  3
                    z:              QGroundControl.zOrderWaypointLines + 1
                }
            }

            // Incomplete segment lines
            MapItemView {
                model: _missionController.incompleteComplexItemLines

                delegate: MapPolyline {
                    path:       [ object.coordinate1, object.coordinate2 ]
                    line.width: 1
                    line.color: "red"
                    z:          QGroundControl.zOrderWaypointLines
                    opacity:    _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                }
            }

            // UI for splitting the current segment
            MapQuickItem {
                id:             splitSegmentItem
                anchorPoint.x:  sourceItem.width / 2
                anchorPoint.y:  sourceItem.height / 2
                z:              QGroundControl.zOrderWaypointLines + 1
                visible:        _editingLayer == _layerMission ||  _editingLayer == _layerUTMSP

                sourceItem: SplitIndicator {
                    onClicked:  _missionController.insertSimpleMissionItem(splitSegmentItem.coordinate,
                                                                           _missionController.currentPlanViewVIIndex,
                                                                           true /* makeCurrentItem */)
                }

                function _updateSplitCoord() {
                    if (_missionController.splitSegment) {
                        var distance = _missionController.splitSegment.coordinate1.distanceTo(_missionController.splitSegment.coordinate2)
                        var azimuth = _missionController.splitSegment.coordinate1.azimuthTo(_missionController.splitSegment.coordinate2)
                        splitSegmentItem.coordinate = _missionController.splitSegment.coordinate1.atDistanceAndAzimuth(distance / 2, azimuth)
                    } else {
                        coordinate = QtPositioning.coordinate()
                    }
                }


                Connections {
                    target:                 _missionController
                    function onSplitSegmentChanged()  { splitSegmentItem._updateSplitCoord() }
                }

                Connections {
                    target:                 _missionController.splitSegment
                    function onCoordinate1Changed()   { splitSegmentItem._updateSplitCoord() }
                    function onCoordinate2Changed()   { splitSegmentItem._updateSplitCoord() }
                }
            }

            // Add the vehicles to the map
            MapItemView {
                model: QGroundControl.multiVehicleManager.vehicles
                delegate: VehicleMapItem {
                    vehicle:        object
                    coordinate:     object.coordinate
                    map:            editorMap
                    size:           ScreenTools.defaultFontPixelHeight * 3
                    z:              QGroundControl.zOrderMapItems - 1
                }
            }

            GeoFenceMapVisuals {
                map:                    editorMap
                myGeoFenceController:   _geoFenceController
                interactive:            _editingLayer == _layerGeoFence
                homePosition:           _missionController.plannedHomePosition
                planView:               true
                opacity:                _editingLayer != _layerGeoFence ? editorMap._nonInteractiveOpacity : 1
            }

            RallyPointMapVisuals {
                map:                    editorMap
                myRallyPointController: _rallyPointController
                interactive:            _editingLayer == _layerRallyPoints
                planView:               true
                opacity:                _editingLayer != _layerRallyPoints ? editorMap._nonInteractiveOpacity : 1
            }

            UTMSPMapVisuals {
                id: utmspvisual
                enabled:                _utmspEnabled
                map:                    editorMap
                currentMissionItems:    _visualItems
                myGeoFenceController:   _geoFenceController
                interactive:            _editingLayer == _layerUTMSP
                homePosition:           _missionController.plannedHomePosition
                planView:               true
                opacity:                _editingLayer != _layerUTMSP ? editorMap._nonInteractiveOpacity : 1
                resetCheck:             _resetGeofencePolygon
            }

            Connections {
                target: utmspEditor
                function onResetGeofencePolygonTriggered() {
                    resetTimer.start()
                }
            }
            Timer {
                id: resetTimer
                interval: 2500
                running: false
                repeat: false
                onTriggered: {
                    _resetGeofencePolygon = true
                }
            }
        }

        //-----------------------------------------------------------
        // Left tool strip
        ToolStrip {
            id:                 toolStrip
            anchors.margins:    _toolsMargin
            anchors.left:       parent.left
            anchors.top:        parent.top
            z:                  QGroundControl.zOrderWidgets
            maxHeight:          parent.height - toolStrip.y
            title:              qsTr("Plan")

            readonly property int flyButtonIndex:       0
            readonly property int fileButtonIndex:      1
            readonly property int takeoffButtonIndex:   2
            readonly property int waypointButtonIndex:  3
            readonly property int roiButtonIndex:       4
            readonly property int patternButtonIndex:   5
            readonly property int landButtonIndex:      6
            readonly property int centerButtonIndex:    7

            property bool _isRallyLayer:    _editingLayer == _layerRallyPoints
            property bool _isMissionLayer:  _editingLayer == _layerMission
            property bool _isUtmspLayer:     _editingLayer == _layerUTMSP

            ToolStripActionList {
                id: toolStripActionList
                model: [
                    // ToolStripAction {
                    //     text:           qsTr("Fly")
                    //     iconSource:     "/qmlimages/PaperPlane.svg"
                    //     onTriggered:    mainWindow.showFlyView()
                    //     visible:                planType==="Plan"?false:true
                    // },
                    // ToolStripAction {
                    //     text:                   qsTr("File")
                    //     enabled:                !_planMasterController.syncInProgress
                    //     visible:                true
                    //     showAlternateIcon:      _planMasterController.dirty
                    //     iconSource:             "/qmlimages/MapSync.svg"
                    //     alternateIconSource:    "/qmlimages/MapSyncChanged.svg"
                    //     onTriggered: {

                    //         _planMasterController.data()
                    //     }


                    // },
                    ToolStripAction {
                        text:       qsTr("Share")
                        iconSource: "qrc:/InstrumentValueIcons/share-alt.svg"
                        //enabled:    _missionController.isInsertTakeoffValid
                        visible:    planType==="Plan"?true:false//(toolStrip._isMissionLayer || toolStrip._isUtmspLayer) && !_planMasterController.controllerVehicle.rover
                        onTriggered: {

                            dialog.open()

                            // if(_planMasterController.currentPlanFile !== "") {
                            //     _planMasterController.saveToCurrent()
                            // } else {
                            //     _planMasterController.saveToSelectedFile1()
                            // }
                        }
                    },
                    ToolStripAction {
                        text:       qsTr("Takeoff")
                        iconSource: "/res/takeoff.svg"
                        enabled:    _missionController.isInsertTakeoffValid
                        visible:    planType==="Plan"?false:(toolStrip._isMissionLayer || toolStrip._isUtmspLayer) && !_planMasterController.controllerVehicle.rover
                        onTriggered: {
                            toolStrip.allAddClickBoolsOff()
                            insertTakeItemAfterCurrent()
                            _triggerSubmit = true
                        }
                    },

                    ToolStripAction {
                        id:                 addWaypointRallyPointAction
                        text:               _editingLayer == _layerRallyPoints ? qsTr("Rally Point") : qsTr("Waypoint")
                        iconSource:         "/qmlimages/MapAddMission.svg"
                        enabled:            toolStrip._isRallyLayer ? true : _missionController.flyThroughCommandsAllowed
                        visible:           toolStrip._isRallyLayer || toolStrip._isMissionLayer || toolStrip._isUtmspLayer
                        checkable:          true
                    }
                    //     ToolStripAction {
                    //         text:               _missionController.isROIActive ? qsTr("Cancel ROI") : qsTr("ROI")
                    //         iconSource:         "/qmlimages/MapAddMission.svg"
                    //         enabled:            !_missionController.onlyInsertTakeoffValid
                    //         visible:            planType==="Plan"?false:toolStrip._isMissionLayer && _planMasterController.controllerVehicle.roiModeSupported
                    //         checkable:          !_missionController.isROIActive
                    //         onCheckedChanged:   _addROIOnClick = checked
                    //         onTriggered: {
                    //             if (_missionController.isROIActive) {
                    //                 toolStrip.allAddClickBoolsOff()
                    //                 insertCancelROIAfterCurrent()
                    //             }
                    //         }
                    //         property bool myAddROIOnClick: _addROIOnClick
                    //         onMyAddROIOnClickChanged: checked = _addROIOnClick
                    //     },
                    //     ToolStripAction {
                    //         text:               _singleComplexItem ? _missionController.complexMissionItemNames[0] : qsTr("Pattern")
                    //         iconSource:         "/qmlimages/MapDrawShape.svg"
                    //         enabled:            _missionController.flyThroughCommandsAllowed
                    //         visible:            planType==="Plan"?false:toolStrip._isMissionLayer
                    //         dropPanelComponent: _singleComplexItem ? undefined : patternDropPanel
                    //         onTriggered: {
                    //             toolStrip.allAddClickBoolsOff()
                    //             if (_singleComplexItem) {
                    //                 insertComplexItemAfterCurrent(_missionController.complexMissionItemNames[0])
                    //             }
                    //         }
                    //     },
                    //     ToolStripAction {
                    //         text:       _planMasterController.controllerVehicle.multiRotor ? qsTr("Return") : qsTr("Land")
                    //         iconSource: "/res/rtl.svg"
                    //         enabled:    _missionController.isInsertLandValid
                    //         visible:    planType==="Plan"?false:toolStrip._isMissionLayer || toolStrip._isUtmspLayer
                    //         onTriggered: {
                    //             toolStrip.allAddClickBoolsOff()
                    //             insertLandItemAfterCurrent()
                    //         }
                    //     },
                    //     ToolStripAction {
                    //         text:               qsTr("Center")
                    //         iconSource:         "/qmlimages/MapCenter.svg"
                    //         enabled:            true
                    //         visible:            planType==="Plan"?false:true
                    //         dropPanelComponent: centerMapDropPanel
                    //     }

                ]
            }


            Dialog {
                id: dialog
                modal: true
                dim: true
                parent:  Overlay.overlay
                anchors.centerIn: parent
                width: parent.width * 0.4   // 80% of screen width
                height: parent.height * 0.2 // 50% of screen height
                background: Rectangle {
                    color: "white"
                    radius: 10
                    border.color: "black"
                    border.width: 1
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 20
                    width: parent.width * 0.7

                    Text {
                        text: "Are you sure you want to share the plan?"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 14
                    }

                    Button {
                        text: qsTr("Share")
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: {
                            dialog.close()
                            if (_planMasterController.currentPlanFile !== "") {
                                _planMasterController.saveToCurrent()
                            } else {
                                _planMasterController.saveToSelectedFile1()
                            }
                        }
                    }
                }
            }

            model: toolStripActionList.model

            function allAddClickBoolsOff() {
                _addROIOnClick =        false

                addWaypointRallyPointAction.checked = QGroundControl.loadGlobalSetting("loadpage","loadpage")=== "Camera" || "Mapping"&& QGroundControl.loadGlobalSetting("waypoint","waypoint")=== "waypoint" ? true : false

            }

            onDropped: allAddClickBoolsOff()
        }

        //-----------------------------------------------------------
        // Right pane for mission editing controls
        Rectangle {
            id:                 rightPanel
            height:             parent.height
            width:{
                if(_utmspEnabled){
                    _rightPanelWidth + ScreenTools.defaultFontPixelWidth * 21.667
                }
                else{
                    _rightPanelWidth
                }
            }
            color:              qgcPal.window
            opacity:            layerTabBar.visible ? 0.2 : 0
            anchors.bottom:     parent.bottom
            anchors.right:      parent.right
            anchors.rightMargin: _toolsMargin
            //visible: false
        }
        //-------------------------------------------------------
        // Right Panel Controls

        Item {
            anchors.fill:           rightPanel
            anchors.topMargin:      _toolsMargin
            //visible: false

            DeadMouseArea {
                anchors.fill:   parent
            }

            Column {
                id:                 rightControls
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.top:        parent.top
                //-------------------------------------------------------

                // Mission Controls (Expanded)
                QGCTabBar {
                    id:         layerTabBar
                    width:      parent.width
                    visible:    QGroundControl.corePlugin.options.enablePlanViewSelector  && !_utmspEnabled
                    Component.onCompleted: currentIndex = 0

                    QGCTabButton {
                        text:       qsTr("Mission")
                    }
                    QGCTabButton {
                        text:       qsTr("Fence")
                        enabled:    _geoFenceController.supported
                        visible: droneType==="Mapping"?true:false
                    }
                    // QGCTabButton {
                    //     text:       qsTr("Rally")
                    //     enabled:    _rallyPointController.supported
                    // }
                }

                QGCTabBar {
                    id:         layerTabBarUTMSP
                    width:      parent.width
                    visible:    QGroundControl.corePlugin.options.enablePlanViewSelector && _utmspEnabled
                    QGCTabButton {
                        text:       qsTr("Mission")
                    }
                    QGCTabButton {
                        text:       qsTr("Rally")
                        enabled:    _rallyPointController.supported
                    }
                    QGCTabButton {
                        id: utmspbutton
                        text:       qsTr("UTM-Adapter")
                        visible: _utmspEnabled
                    }
                }
            }
            //-------------------------------------------------------
            // Mission Item Editor
            Item {
                id:                     missionItemEditor
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:         parent.bottom
                anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 0.25
                visible:                _editingLayer == _layerMission && !planControlColapsed
                QGCListView {
                    id:                 missionItemEditorListView
                    anchors.fill:       parent
                    spacing:            ScreenTools.defaultFontPixelHeight / 4
                    orientation:        ListView.Vertical
                    model:              _missionController.visualItems
                    cacheBuffer:        Math.max(height * 2, 0)
                    clip:               true
                    currentIndex:       _missionController.currentPlanViewSeqNum
                    highlightMoveDuration: 250
                    visible:            _editingLayer == _layerMission && !planControlColapsed

                    // // Remove items with commandName "Takeoff" when the component is completed.
                    // Component.onCompleted:
                    // {
                    //     // Loop backwards to avoid index shifting.
                    //     for (var i = _missionController.visualItems.count - 1; i >= 0; i--) {
                    //         var item = _missionController.visualItems.get(i);
                    //         if (item.commandName === "Takeoff") {
                    //             _missionController.visualItems.remove(i);
                    //         }
                    //     }
                    // }

                    //-- List Elements

                    delegate: MissionExpand {
                        //visible: missionItem.commandName !== "Takeoff"
                        map:            editorMap
                        masterController:  _planMasterController
                        missionItem:    object
                        width:          missionItemEditorListView.width
                        readOnly:       false
                        //onClicked: (sequenceNumber) => { _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false) }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false)
                                missionItemDialog.currentMissionItem = object
                                missionItemDialog.currentIndex = index
                                missionItemDialog.open()
                                missionItemDialog.visible = true
                            }
                        }
                        // onRemove: {
                        //     var removeVIIndex = index
                        //     _missionController.removeVisualItem(removeVIIndex)
                        //     if (removeVIIndex >= _missionController.visualItems.count) {
                        //         removeVIIndex--
                        //     }
                        // }
                        //onSelectNextNotReadyItem:   selectNextNotReady()
                    }
                }
            }
            // GeoFence Editor
            GeoFenceEditor {
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:         parent.bottom
                anchors.left:           parent.left
                anchors.right:          parent.right
                myGeoFenceController:   _geoFenceController
                flightMap:              editorMap
                visible:                _editingLayer == _layerGeoFence
            }

            // Rally Point Editor
            RallyPointEditorHeader {
                id:                     rallyPointHeader
                anchors.top:            rightControls.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.left:           parent.left
                anchors.right:          parent.right
                visible:                _editingLayer == _layerRallyPoints
                controller:             _rallyPointController
            }


            RallyPointItemEditor {
                id:                     rallyPointEditor
                anchors.top:            rallyPointHeader.bottom
                anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.25
                anchors.left:           parent.left
                anchors.right:          parent.right
                visible:                _editingLayer == _layerRallyPoints && _rallyPointController.points.count
                rallyPoint:             _rallyPointController.currentRallyPoint
                controller:             _rallyPointController
            }


            UTMSPAdapterEditor{
                id: utmspEditor
                enabled:                 _utmspEnabled
                anchors.top:             rightControls.bottom
                anchors.topMargin:       ScreenTools.defaultFontPixelHeight * 0.25
                anchors.bottom:          parent.bottom
                anchors.left:            parent.left
                anchors.right:           parent.right
                currentMissionItems:     _visualItems
                myGeoFenceController:    _geoFenceController
                flightMap:               editorMap
                visible:                 _editingLayer == _layerUTMSP
                triggerSubmitButton:     _triggerSubmit
                resetRegisterFlightPlan: _resetRegisterFlightPlan
            }

        }

        QGCLabel {
            // Elevation provider notice on top of terrain plot
            readonly property string _licenseString: QGroundControl.elevationProviderNotice

            id:                         licenseLabel
            visible:                    terrainStatus.visible && _licenseString !== ""
            anchors.bottom:             terrainStatus.top
            anchors.horizontalCenter:   terrainStatus.horizontalCenter
            anchors.bottomMargin:       ScreenTools.defaultFontPixelWidth * 0.5
            font.pointSize:             ScreenTools.smallFontPointSize
            text:                       qsTr("Powered by %1").arg(_licenseString)
        }

        Dialog {
            id: missionItemDialog
            modal: true
            dim: true
            property int currentIndex: -1
            property var currentMissionItem: null
            parent: Overlay.overlay
            anchors.centerIn: parent

            Rectangle {
                id: closeBtn
                width: 30
                height: 30
                radius: width / 2
                color: "red"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10

                Text {
                    text: "X"
                    color: "white"
                    anchors.centerIn: parent
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked:{
                        missionItemDialog.visible = false
                        mainWindow.showPlanView()

                    }
                }
            }
            width: Math.min(Screen.width * 0.9, 600)
            height: Math.min(editorContent.implicitHeight +25, Screen.height * 0.8)


            // Center positioning will happen in Component.onCompleted and onOpened
            onOpened: {
                x = (Screen.width - width) / 2
                y = (Screen.height - height) / 2
            }

            contentItem: Rectangle {
                width: parent.width
                height: parent.height
                color: Qt.rgba(0.98, 0.98, 0.98, 1)
                border.color: "#cccccc"
                border.width: 1
                radius: 8

                QGCFlickable {
                    id: flickableEditor
                    anchors.fill: parent
                    contentWidth: width
                    anchors.margins: 1
                    contentHeight: editorContent.implicitHeight
                    clip: true

                    flickableDirection: Flickable.VerticalFlick
                    Column {
                        id: editorContent
                        width: flickableEditor.width

                        MissionItemEditor {
                            id: editor
                            width: parent.width
                            map: editorMap
                            masterController: _planMasterController
                            missionItem: missionItemDialog.currentMissionItem
                            readOnly: false

                            onClicked: (sequenceNumber) => {
                                           _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false)
                                           // Optional
                                       }

                            onRemove: {
                                var removeVIIndex = missionItemDialog.currentIndex
                                _missionController.removeVisualItem(removeVIIndex)
                                if (removeVIIndex >= _missionController.visualItems.count) {
                                    removeVIIndex--
                                }
                                missionItemDialog.close()
                            }

                            onSelectNextNotReadyItem: {
                                selectNextNotReady()
                            }
                        }
                    }
                }
            }
        }


        Item {
            id: editdata
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: 60   // increased from 20 → lifts it up
            //anchors.leftMargin: 10

            Button {
                id: uploadBtn
                text: ""
                width: 46
                height: 46

                padding: 15

                background: Rectangle {
                    radius: width / 2
                    color: "#1b1c3e"
                    border.color: "#005BBB"
                    border.width: 2
                    anchors.fill: parent
                    anchors.margins: 5
                }

                contentItem: QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/cloud-upload.svg"
                    width: 16
                    height: 16
                    anchors.centerIn: parent // Center the icon within the container
                    color: "white"
                }

                onClicked: {
                    console.log("Upload_data")
                    if (_utmspEnabled) {
                        QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
                        UTMSPStateStorage.removeFlightPlanState = true
                        UTMSPStateStorage.indicatorDisplayStatus = true
                    }
                    _planMasterController.upload();
                }
            }

            Button {
                id: uploadBtn1
                //visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"?true:false
                text: ""
                width: 46
                height: 46
                anchors.left: uploadBtn.right
                anchors.leftMargin: 10
                anchors.bottom: uploadBtn.bottom
                padding: 15

                background: Rectangle {
                    radius: width / 2
                    color: "#1b1c3e"
                    border.color: "#005BBB"
                    border.width: 2
                    anchors.fill: parent
                    anchors.margins: 5
                }

                contentItem: QGCColoredImage {
                    source: "/res/rtl.svg"
                    width: 16
                    height: 16
                    anchors.centerIn: parent // Center the icon within the container
                    color: "white"
                }

                onClicked: {
                    toolStrip.allAddClickBoolsOff()
                    insertLandItemAfterCurrent()
                }
            }

        }

        Component {
            id: customdialog

            Item {
                id: customDialogItem
                parent: Overlay.overlay
                anchors.centerIn: parent
                width: 600
                height: 200

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: "#80ffffff"
                    border.color: "#ccccff"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 20
                        anchors.margins: 20

                        // Centered Title
                        Label {
                            text: qsTr("Are you sure you want to share the plan?")
                            font.bold: true
                            font.pointSize: 16
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        // Buttons Row
                        Row {
                            spacing: 30
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                text: " Share"
                                width: 100
                                height: 34
                                font.bold: true
                                background: Rectangle {
                                    radius: 20
                                    color: "#ccccff"
                                }
                                onClicked: {
                                    if (_planMasterController.currentPlanFile !== "") {
                                        _planMasterController.saveToCurrent()
                                    } else {
                                        _planMasterController.saveToSelectedFile1()
                                    }
                                    customDialogItem.visible=false;
                                }

                            }

                        }
                    }
                }
            }

        }

        TerrainStatus {
            id:                 terrainStatus
            anchors.margins:    _toolsMargin
            anchors.leftMargin: 0
            anchors.left:       mapScale.left
            anchors.right:      rightPanel.left
            anchors.bottom:     parent.bottom
            height:             ScreenTools.defaultFontPixelHeight * 7
            missionController:  _missionController
            visible:            false//_internalVisible && _editingLayer === _layerMission && QGroundControl.corePlugin.options.showMissionStatus

            onSetCurrentSeqNum: _missionController.setCurrentPlanViewSeqNum(seqNum, true)

            property bool _internalVisible: _planViewSettings.showMissionItemStatus.rawValue

            function toggleVisible() {
                _internalVisible = !_internalVisible
                _planViewSettings.showMissionItemStatus.rawValue = _internalVisible
            }
        }

        MapScale {
            id:                     mapScale
            anchors.margins:        _toolsMargin
            anchors.bottom:         terrainStatus.visible ? terrainStatus.top : parent.bottom
            anchors.left:           toolStrip.y + toolStrip.height + _toolsMargin > mapScale.y ? toolStrip.right: parent.left
            mapControl:             editorMap
            buttonsOnLeft:          true
            terrainButtonVisible:   _editingLayer === _layerMission
            terrainButtonChecked:   terrainStatus.visible
            onTerrainButtonClicked: terrainStatus.toggleVisible()
            visible:false
        }
    }

    function showLoadFromFileOverwritePrompt(title) {
        mainWindow.showMessageDialog(title,
                                     qsTr("You have unsaved/unsent changes. Loading from a file will lose these changes. Are you sure you want to load from a file?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() { _planMasterController.loadFromSelectedFile() } )
    }

    Component {
        id: createPlanRemoveAllPromptDialog

        QGCSimpleMessageDialog {
            title:      qsTr("Create Plan")
            text:       qsTr("Are you sure you want to remove current plan and create a new plan? ")
            buttons:    Dialog.Yes | Dialog.No

            property var mapCenter
            property var planCreator

            onAccepted: {
                planCreator.createPlan(mapCenter)

                // // Set the newly created item as the current item
                // var newSeqNum = _missionController.visualItems.count - 1
                // if (newSeqNum >= 0) {
                // _missionController.setCurrentPlanViewSeqNum(newSeqNum, false)
                // }

            }
        }
    }

    function clearButtonClicked() {
        mainWindow.showMessageDialog(qsTr("Clear"),
                                     qsTr("Are you sure you want to remove all mission items and clear the mission from the vehicle?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() { _planMasterController.removeAllFromVehicle();
                                         _missionController.setCurrentPlanViewSeqNum(0, true);
                                         if(_utmspEnabled)
                                         {_resetRegisterFlightPlan = true;
                                             QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(false);
                                             UTMSPStateStorage.startTimeStamp = "";
                                             UTMSPStateStorage.showActivationTab = false;
                                             UTMSPStateStorage.flightID = "";
                                             UTMSPStateStorage.enableMissionUploadButton = false;
                                             UTMSPStateStorage.indicatorPendingStatus = true;
                                             UTMSPStateStorage.indicatorApprovedStatus = false;
                                             UTMSPStateStorage.indicatorActivatedStatus = false;
                                             UTMSPStateStorage.currentStateIndex = 0}})
    }

    //- ToolStrip DropPanel Components

    Component {
        id: centerMapDropPanel

        CenterMapDropPanel {
            map:            editorMap
            fitFunctions:   mapFitFunctions
        }
    }

    Component {
        id: patternDropPanel

        ColumnLayout {
            spacing:    ScreenTools.defaultFontPixelWidth * 0.5

            QGCLabel { text: qsTr("Create complex pattern:") }

            Repeater {
                model: _missionController.complexMissionItemNames

                QGCButton {
                    text:               modelData
                    Layout.fillWidth:   true

                    onClicked: {
                        insertComplexItemAfterCurrent(modelData)
                        dropPanel.hide()
                    }
                }
            }
        } // Column
    }

    function downloadClicked(title) {
        if (_planMasterController.dirty) {
            mainWindow.showMessageDialog(title,
                                         qsTr("You have unsaved/unsent changes. Loading from the Vehicle will lose these changes. Are you sure you want to load from the Vehicle?"),
                                         Dialog.Yes | Dialog.Cancel,
                                         function() { _planMasterController.loadFromVehicle() })
        } else {
            _planMasterController.loadFromVehicle()
        }
    }

    Component {
        id: syncDropPanel

        ColumnLayout {
            id:         columnHolder
            spacing:    _margin

            property string _overwriteText: qsTr("Plan overwrite")

            QGCLabel {
                id:                 unsavedChangedLabel
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                text:               globals.activeVehicle ?
                                        qsTr("You have unsaved changes. You should upload to your vehicle, or save to a file.") :
                                        qsTr("You have unsaved changes.")
                visible:            _planMasterController.dirty
            }

            SectionHeader {
                id:                 createSection
                Layout.fillWidth:   true
                text:               qsTr("Create Plan")
                showSpacer:         false
            }

            GridLayout {
                columns:            2
                columnSpacing:      _margin
                rowSpacing:         _margin
                Layout.fillWidth:   true
                visible:            createSection.checked

                Repeater {
                    model: _planMasterController.planCreators

                    Rectangle {
                        id:     button
                        width:  ScreenTools.defaultFontPixelHeight * 7
                        height: planCreatorNameLabel.y + planCreatorNameLabel.height
                        color:  button.pressed || button.highlighted ? qgcPal.buttonHighlight : qgcPal.button

                        property bool highlighted: mouseArea.containsMouse
                        property bool pressed:     mouseArea.pressed

                        Image {
                            id:                 planCreatorImage
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            source:             object.imageResource
                            sourceSize.width:   width
                            fillMode:           Image.PreserveAspectFit
                            mipmap:             true
                        }

                        QGCLabel {
                            id:                     planCreatorNameLabel
                            anchors.top:            planCreatorImage.bottom
                            anchors.left:           parent.left
                            anchors.right:          parent.right
                            horizontalAlignment:    Text.AlignHCenter
                            text:                   object.name
                            color:                  button.pressed || button.highlighted ? qgcPal.buttonHighlightText : qgcPal.buttonText
                        }

                        QGCMouseArea {
                            id:                 mouseArea
                            anchors.fill:       parent
                            hoverEnabled:       true
                            preventStealing:    true
                            onClicked: {
                                selectedPlanCreator = object
                                object.createPlan(_mapCenter())
                                console.log("object_selected",object)
                                if (_planMasterController.containsItems) {
                                    console.log("Grid Layout If Part")
                                    createPlanRemoveAllPromptDialog.createObject(mainWindow, { mapCenter: _mapCenter(), planCreator: object }).open()
                                } else {
                                    console.log("Grid Layout Else Part")
                                    object.createPlan(_mapCenter())

                                    // Set the newly created item as the current item
                                    // var newSeqNum = _missionController.visualItems.count - 1
                                    // if (newSeqNum >= 0) {
                                    // _missionController.setCurrentPlanViewSeqNum(newSeqNum, false)
                                    // }
                                }
                                dropPanel.hide()
                            }

                            function _mapCenter() {
                                var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2), editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
                                return editorMap.toCoordinate(centerPoint, false /* clipToViewPort */)
                            }

                        }
                    }
                }
            }

            SectionHeader {
                id:                 storageSection
                Layout.fillWidth:   true
                text:               qsTr("Storage")
            }

            GridLayout {
                columns:            3
                rowSpacing:         _margin
                columnSpacing:      ScreenTools.defaultFontPixelWidth
                visible:            storageSection.checked

                QGCButton {
                    text:               qsTr("Open...")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress
                    onClicked: {
                        dropPanel.hide()
                        if (_planMasterController.dirty) {
                            showLoadFromFileOverwritePrompt(columnHolder._overwriteText)
                        } else {
                            _planMasterController.loadFromSelectedFile()
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Save")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress && _planMasterController.currentPlanFile !== ""
                    onClicked: {
                        dropPanel.hide()
                        if(_planMasterController.currentPlanFile !== "") {
                            _planMasterController.saveToCurrent()
                        } else {
                            _planMasterController.saveToSelectedFile1()
                        }
                    }
                }

                QGCButton {
                    text:               qsTr("Save As...")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.syncInProgress && _planMasterController.containsItems
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.saveToSelectedFile()
                    }
                }

                QGCButton {
                    Layout.columnSpan:  3
                    Layout.fillWidth:   true
                    text:               qsTr("Save Mission Waypoints As KML...")
                    enabled:            !_planMasterController.syncInProgress && _visualItems.count > 1
                    onClicked: {
                        // First point does not count
                        if (_visualItems.count < 2) {
                            mainWindow.showMessageDialog(qsTr("KML"), qsTr("You need at least one item to create a KML."))
                            return
                        }
                        dropPanel.hide()
                        _planMasterController.saveKmlToSelectedFile()
                    }
                }
            }

            SectionHeader {
                id:                 vehicleSection
                Layout.fillWidth:   true
                text:               qsTr("Vehicle")
            }

            RowLayout {
                Layout.fillWidth:   true
                spacing:            _margin
                visible:            vehicleSection.checked

                QGCButton {
                    text:               qsTr("Upload")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress && _planMasterController.containsItems
                    visible:            !QGroundControl.corePlugin.options.disableVehicleConnection
                    onClicked: {
                        dropPanel.hide()
                        _planMasterController.upload()
                    }
                }

                QGCButton {
                    text:               qsTr("Download")
                    Layout.fillWidth:   true
                    enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress
                    visible:            !QGroundControl.corePlugin.options.disableVehicleConnection

                    onClicked: {
                        dropPanel.hide()
                        downloadClicked(columnHolder._overwriteText)
                    }
                }

                QGCButton {
                    text:               qsTr("Clear")
                    Layout.fillWidth:   true
                    Layout.columnSpan:  2
                    enabled:            !_planMasterController.offline && !_planMasterController.syncInProgress
                    visible:            !QGroundControl.corePlugin.options.disableVehicleConnection
                    onClicked: {
                        dropPanel.hide()
                        clearButtonClicked()
                    }
                }
            }
        }
    }

    function newmap() {


        var creator = _planMasterController.planCreators[0] // or selectedPlanCreator
        if (creator) {
            var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2),
                                       editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
            var centerCoord = editorMap.toCoordinate(centerPoint, false)
            creator.createPlan(centerCoord)
            console.log("No plan creator available1")
        } else {
            console.log("No plan creator available")
        }
    }

    function _mapCenter() {
        var centerPoint = Qt.point(editorMap.centerViewport.left + (editorMap.centerViewport.width / 2), editorMap.centerViewport.top + (editorMap.centerViewport.height / 2))
        return editorMap.toCoordinate(centerPoint, false /* clipToViewPort */)
    }

    Connections {
        target: utmspEditor
        function onVehicleIDSent(id) {
            _vehicleID = id
        }
    }

    Connections {
        target: utmspEditor
        function onRemoveFlightPlanTriggered() {
            _planMasterController.removeAllFromVehicle();
            _missionController.setCurrentPlanViewSeqNum(0, true);
            if(_utmspEnabled){_resetRegisterFlightPlan = true}
        }
    }
}
