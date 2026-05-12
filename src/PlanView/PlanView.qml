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
import MapGlobals

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
    property int    _editingLayer:                      _layerMission
    property bool   isMissionTab:                       _editingLayer === _layerMission
    property bool   isFenceTab:                         _editingLayer === _layerGeoFence
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

    property bool showReturnWaypoint: QGroundControl.loadGlobalSetting("waypointvisible","") === "waypointvisible"
    property bool waypointMark: QGroundControl.loadGlobalSetting("waypointMark","true")==="true"
    property bool returnWaypointEnabled: QGroundControl.loadGlobalSetting("returnWaypointEnabled", "true") === "true"

    property real compassBottomY: compassNorth.y + compassNorth.height + (ScreenTools.defaultFontPixelHeight * 0.5)
    property real compassNorthX:   compassNorth.x

    AirspaceRestrictionValidator {
        id: _airspaceValidator
        airspaceManager: QGroundControl.airspaceManager
    }

    // Shared responsive base
    property real baseSize: parent.width * 0.045    // 6% of screen width
    property real iconSize: baseSize * 0.8   // icon inside the circle
    property var _currentVIIndex: _missionController.currentPlanViewVIIndex
    property var _currentItem:   (_currentVIIndex >= 0 && _currentVIIndex < _missionController.visualItems.count) ? _missionController.visualItems.get(_currentVIIndex) : null

    on_CurrentItemChanged: {
        if (_currentItem && _currentItem.mapPolygon !== undefined) {
             _currentItem.mapPolygon = mapPolygonvisuals.mapPolygon
        }
    }
    property var activePolygon:  (_currentItem && _currentItem.surveyAreaPolygon) ? _currentItem.surveyAreaPolygon : mapPolygonvisuals.mapPolygon

    Connections {
        target: _planMasterController
        onPlanSaved: (filename) => {
            console.log("Plan saved, updating DB:", filename)
            MapGlobals.saveMissionLog(filename, _planMasterController.saveToJsonString(), _planMasterController)
        }
    }

    property bool gridLines : MapGlobals.gridLines

    Component.onCompleted: {
        QGroundControl.saveGlobalSetting("waypointvisible", "");  // reset when entering PlanView
        QGroundControl.saveGlobalSetting("returnWaypointEnabled", "true")
        _editingLayer = _layerMission
    }

    onVisibleChanged: {

        if(visible) {
            droneType = QGroundControl.loadGlobalSetting("loadpage","loadpage");
            editorMap.zoomLevel = QGroundControl.flightMapZoom
            editorMap.center    = QGroundControl.flightMapPosition

            if (!_planMasterController.containsItems) {
                toolStrip.simulateClick(toolStrip.fileButtonIndex)
            }

            showReturnWaypoint = QGroundControl.loadGlobalSetting("waypointvisible","") === "waypointvisible"
            console.log("showReturnWaypoint : ",showReturnWaypoint)

            returnWaypointEnabled = QGroundControl.loadGlobalSetting("returnWaypointEnabled", "true") === "true"

            console.log("returnWaypointEnabled in PlanView : ",returnWaypointEnabled)

            waypointMark = QGroundControl.loadGlobalSetting("waypointMark", "true") === "true"

        }
    }


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
        fileUploadbtn.visible=true
        MapGlobals.share_edit_visibility = true
        MapGlobals.isReviewMode = true
        MapGlobals.showMissionItems = false
    }

    function loaddata1() {

        _planMasterController.loadFromSelectedFile1()

        fileUploadbtn.visible= true

        MapGlobals.share_edit_visibility = true

    }

    function loaddata2() {
        //_planMasterController.loadFromSelectedFile1()
        fileUploadbtn.visible=true
        MapGlobals.share_edit_visibility = true
    }

    function data1() {
        _planMasterController.data()
        //mobileFileSaveDialogComponent.createObject(mainWindow).open()
    }


    function newmapfile(file) {

        console.log("file data:",file)
        _planMasterController.loadFromFile(file)
        _planMasterController.fitViewportToItems()
        _missionController.setCurrentPlanViewSeqNum(0, true)
        //close()

        mainWindow.showPlanView()
    }


    // Left Top Back Arrow Navigation explicitly removed as requested by user

    function syncCloud() {
        if (QGroundControl.loadBoolGlobalSetting("login", false)) {
            var planName = _planMasterController.currentPlanFile ? _planMasterController.currentPlanFile.split('/').pop().split('\\').pop() : "Untitled.plan"
            var planContent = JSON.parse(_planMasterController.saveToText())
            MapGlobals.savePlanToCloud(planName, planContent, function(success) {
                if (success) {
                    mainWindow.showToastMessage("Plan synced to cloud");
                }
            })
        }
    }

    Connections {
        target: MapGlobals
        onRequestCloudSync: syncCloud()
        onLoadLocalPlan: (path) => {
            console.log("PlanView: loading local plan:", path)
            _planMasterController.loadFromFile(path)
            MapGlobals.isReviewMode = true
            MapGlobals.showMissionItems = false
        }
        onLoadCloudPlan: (data) => {
            console.log("PlanView: loading cloud plan data")
            try {
                var json = (typeof data === "string") ? JSON.parse(data) : data
                _planMasterController.loadFromJson(json)
                MapGlobals.isReviewMode = true
                MapGlobals.showMissionItems = false
            } catch (e) {
                console.error("Failed to process cloud plan data:", e)
            }
        }
    }

    ColumnLayout {
        id: leftActionsColumn
        anchors.bottom: editdata.top
        anchors.left: parent.left
        anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 1.1
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 1.5
        spacing: ScreenTools.defaultFontPixelHeight * 1.1

        Rectangle {
            id: sharebtn
            Layout.alignment: Qt.AlignLeft
            width: baseSize
            height: baseSize
            radius: width / 2
            color: Qt.rgba(0, 0, 0, 0.40)  // Transparent black circle
            border.color: Qt.rgba(0, 0, 0, 0.40)
            border.width: 0
            opacity: 0.95
            visible: true

            QGCColoredImage {
                source: "qrc:/InstrumentValueIcons/share-alt.svg"
                width: iconSize
                height: iconSize
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    dialog.open()
                }
            }
        }

        // Save button
        Rectangle {
            Layout.alignment: Qt.AlignLeft
            width:  baseSize
            height: baseSize
            radius: width / 2
            color:  Qt.rgba(0, 0, 0, 0.40)  // Transparent black circle
            border.color: Qt.rgba(0, 0, 0, 0.40)
            border.width: 0
            opacity: 0.95
            visible: true

            QGCColoredImage {
                source: "/qmlimages/MapCenter.svg"
                width:  iconSize
                height: iconSize
                anchors.centerIn: parent
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (activePolygon && activePolygon.traceMode) {
                        if (activePolygon.count < 3) {
                            console.log("Save: Not enough vertices (<3), restoring previous vertices")
                            mapPolygonvisuals.restorePreviousVertices()
                            return
                        }
                        activePolygon.traceMode = false
                    }
                    if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping") {
                        _planMasterController.saveToSelectedFile1()
                    } else {
                        _planMasterController.saveToSelectedFile()
                    }
                    MapGlobals.share_edit_visibility = false
                }
            }
        }
    }

    MapFitFunctions {
        id:                         mapFitFunctions  // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        editorMap
        usePlannedHomePosition:     true
        planMasterController:       _planMasterController
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
                Layout.preferredWidth: dp(60)
                spacing:    dp(4)

                QGCLabel {
                    Layout.fillWidth:       true
                    wrapMode:               QGCLabel.WordWrap
                    color:                  "black"
                    font.family:            "Outfit"
                    font.pointSize:         ScreenTools.defaultFontPointSize
                    horizontalAlignment:    Text.AlignHCenter
                    text:                   _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                qsTr("The vehicle associated with the plan in the Plan View is no longer available. What would you like to do with that plan?") :
                                                qsTr("The plan being worked on in the Plan View is not from the current vehicle. What would you like to do with that plan?")
                }

                // Action 1: Discard/Load
                Rectangle {
                    Layout.fillWidth:   true
                    height:             dp(8)
                    radius:             12
                    color:              discMA.pressed ? "white" : (discMA.containsMouse ? "#2d2e4a" : Qt.rgba(255,255,255,0.05))
                    border.color:       Qt.rgba(255,255,255,0.15)
                    border.width:       1

                    Text {
                        anchors.centerIn: parent
                        width:          parent.width * 0.9
                        elide:          Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text:           _planMasterController.dirty ?
                                            (_planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                                 qsTr("Discard Unsaved Changes") :
                                                 qsTr("Discard Unsaved Changes, Load New Plan From Vehicle")) :
                                            qsTr("Load New Plan From Vehicle")
                        color:          "black"
                        font.bold:      true
                        font.family:    "Outfit"
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }

                    MouseArea {
                        id: discMA
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            _planMasterController.showPlanFromManagerVehicle()
                            _promptForPlanUsageShowing = false
                            close();
                        }
                    }
                }

                // Action 2: Keep Current
                Rectangle {
                    Layout.fillWidth:   true
                    height:             dp(8)
                    radius:             12
                    color:              keepMA.pressed ? Qt.darker("#000000", 1.2) : (keepMA.containsMouse ? Qt.lighter("#000000", 1.1) : "#000000")
                    border.color: "#000000"

                    Text {
                        anchors.centerIn: parent
                        width:          parent.width * 0.9
                        elide:          Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text:           _planMasterController.managerVehicle.isOfflineEditingVehicle ?
                                            qsTr("Keep Current Plan") :
                                            qsTr("Keep Current Plan, Don't Update From Vehicle")
                        color:          "white"
                        font.bold:      true
                        font.family:    "Outfit"
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }

                    MouseArea {
                        id: keepMA
                        anchors.fill: parent
                        hoverEnabled: true
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
            if (readyForSaveState() === VisualMissionItem.NotReadyForSaveData) {
                waitingOnIncompleteDataMessage(save)
                return false
            } else if (readyForSaveState() === VisualMissionItem.NotReadyForSaveTerrain) {
                waitingOnTerrainDataMessage(save)
                return false
            }
            return true
        }

        function upload() {
            if (!checkReadyForSaveUpload(false /* save */)) {
                console.log("upload_clicked")
                return
            }

            if (_airspaceValidator) {
                if (!_airspaceValidator.validateMission(_missionController)) {
                    _airspaceRestrictionDialog.open()
                    return
                }
            }

            switch (_missionController.sendToVehiclePreCheck()) {
            case MissionController.SendToVehiclePreCheckStateOk:
                MapGlobals.saveMissionLog(_planMasterController.currentPlanFile || "New Mission", _planMasterController.saveToJsonString(), _planMasterController)
                sendToVehicle()
                console.log("upload_clicked1")
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
            console.log("mapping saved")
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
                mapPolygonvisuals._resetPolygon()
            }else if(QGroundControl.loadGlobalSetting("mapping","mapping")==="circle"){
                mapPolygonvisuals._resetCircle()
            }
        }

        function saveToSelectedFile1() {
            console.log("agri saved")
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

    QGCMapPolygonVisuals {
        id:                     mapPolygonvisuals
        mapControl:             editorMap
        cardinalBottomScreenY:  planToolBar.y + planToolBar.height + (ScreenTools.defaultFontPixelHeight * 0.6)
        cardinalLeftScreenX:    (ScreenTools.isMobile ? parent.width * 0.50 : 450) + (ScreenTools.defaultFontPixelWidth * 6.5)
    }

    QGCFileDialog {
        id:             fileDialog
        folder:         _appSettings ? _appSettings.missionSavePath : ""

        property bool planFiles: true    ///< true: working with plan files, false: working with kml file

        onAcceptedForSave: (file) => {
                               console.log("Clicke Files at onAcceptedForSave")
                               if (planFiles) {

                                   if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                                       _planMasterController.saveToFile1(file)
                                       mainWindow.showFlyView()
                                   } else if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
                                       _planMasterController.saveToFile(file)
                                       mainWindow.showMapping()
                                   }
                               } else {
                                   _planMasterController.saveToKml(file)
                               }
                               close()
                           }

        onAcceptedForOverwrite: (fallbackFile) => {
            console.log("Overwrite accepted")
            if (_planMasterController.currentPlanFile !== "") {
                if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                    _planMasterController.saveToFile1(_planMasterController.currentPlanFile)
                    if (planFiles) {
                        mainWindow.showFlyView()
                    }
                } else {
                    _planMasterController.saveToCurrent()
                    if (planFiles) {
                        mainWindow.showMapping()
                    }
                }
            } else {
                var file = fallbackFile
                if (planFiles) {
                    if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                        _planMasterController.saveToFile1(file)
                        mainWindow.showFlyView()
                    } else if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
                        _planMasterController.saveToFile(file)
                        mainWindow.showMapping()
                    }
                } else {
                    _planMasterController.saveToKml(file)
                }
            }
            close()
        }

        onAcceptedForLoad: (file) => {
                               console.log("Click Files at onAcceptedForLoad")
                               MapGlobals.setGridLines(true)
                               _planMasterController.loadFromFile(file)
                               _planMasterController.fitViewportToItems()
                               _missionController.setCurrentPlanViewSeqNum(0, true)
                               close()


                               mainWindow.showPlanView()
                           }

        onAcceptedCloudPlan: (planData) => {
                               console.log("Clicked Cloud File at onAcceptedCloudPlan")
                               MapGlobals.setGridLines(true)
                               _planMasterController.loadFromJson(planData)
                               _planMasterController.fitViewportToItems()
                               _missionController.setCurrentPlanViewSeqNum(0, true)
                               close()

                               mainWindow.showPlanView()
                           }
    }

    Component {
        id: saveOptionsDialogComponent
        QGCPopupDialog {
            id:         saveOptionsPopup
            title:      qsTr("Save Plan Options")
            showButtons: false
            
            Column {
                width:      parent.width
                spacing:    25
                bottomPadding: 10

                QGCLabel {
                    width:              parent.width
                    text:               qsTr("Choose your save preference:")
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize:     14
                    font.bold:          true
                    color:              "black"
                    font.family:        "Outfit"
                }

                // Save Button (Local Overwrite)
                Rectangle {
                    width:          parent.width
                    height:         70
                    radius:         15
                    color:          saveMouse.containsMouse ? "#f0f0f0" : "#ffffff"
                    border.color:   "#e0e0e0"
                    border.width:   1
                    visible:        _planMasterController.currentPlanFile !== ""

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 10
                            color: "#E3F2FD"
                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: "qrc:/res/save.svg"
                                color: "#2196F3"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            QGCLabel {
                                text: qsTr("Save")
                                font.bold: true
                                font.pointSize: 13
                                color: "black"
                            }
                            QGCLabel {
                                text: qsTr("Overwrite current plan file")
                                font.pointSize: 10
                                color: "#666666"
                            }
                        }
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            saveOptionsPopup.close()
                            if (_planMasterController.currentPlanFile !== "") {
                                _planMasterController.saveToCurrent()
                            } else {
                                if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping") {
                                    _planMasterController.saveToSelectedFile1()
                                } else {
                                    _planMasterController.saveToSelectedFile()
                                }
                            }
                        }
                    }
                }

                // Save As Button
                Rectangle {
                    width:          parent.width
                    height:         70
                    radius:         15
                    color:          saveAsMouse.containsMouse ? "#f0f0f0" : "#ffffff"
                    border.color:   "#e0e0e0"
                    border.width:   1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 10
                            color: "#FFF3E0"
                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: "qrc:/res/save.svg"
                                color: "#FF9800"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            QGCLabel {
                                text: qsTr("Save As")
                                font.bold: true
                                font.pointSize: 13
                                color: "black"
                            }
                            QGCLabel {
                                text: qsTr("Save as a new plan file")
                                font.pointSize: 10
                                color: "#666666"
                            }
                        }
                    }

                    MouseArea {
                        id: saveAsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            saveOptionsPopup.close()
                            if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping") {
                                _planMasterController.saveToSelectedFile1()
                            } else {
                                _planMasterController.saveToSelectedFile()
                            }
                        }
                    }
                }

                // Cloud Save Button
                Rectangle {
                    width:          parent.width
                    height:         110
                    radius:         15
                    color:          cloudSaveMouse.containsMouse ? "#E8F5E9" : "#ffffff"
                    border.color:   "#C8E6C9"
                    border.width:   1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15

                        Rectangle {
                            width: 40
                            height: 40
                            radius: 10
                            color: "#E8F5E9"
                            QGCColoredImage {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                source: "qrc:/InstrumentValueIcons/share-alt.svg"
                                color: "#4CAF50"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            QGCLabel {
                                text: qsTr("Cloud Save")
                                font.bold: true
                                font.pointSize: 13
                                color: "black"
                            }
                            QGCLabel {
                                text: qsTr("(save in cloud only in another phonbe you can see yur plans)")
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                font.pointSize: 10
                                color: "#455A64"
                                font.italic: true
                            }
                        }
                    }

                    MouseArea {
                        id: cloudSaveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            saveOptionsPopup.close()
                            if (_planMasterController.currentPlanFile !== "") {
                                _planMasterController.saveToCurrent()
                            } else {
                                if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping") {
                                    _planMasterController.saveToSelectedFile1()
                                } else {
                                    _planMasterController.saveToSelectedFile()
                                }
                            }
                            syncCloud()
                        }
                    }
                }
            }
        }
    }


    AirspaceRestrictionDialog {
        id:         _airspaceRestrictionDialog
        validator:  _airspaceValidator
        isBlocked:  _airspaceValidator ? _airspaceValidator.blockMissionUpload : false
        message:    _airspaceValidator ? _airspaceValidator.restrictionMessage : ""
    }

    Item {
        id:             panel
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.top:    parent.top
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

            property real _rightToolWidth:      rightPanel.width + rightPanel.anchors.rightMargin
            property rect centerViewport:   Qt.rect(_leftToolWidth + _margin,  _margin, editorMap.width - _leftToolWidth - _rightToolWidth - (_margin * 2), (terrainStatus.visible ? terrainStatus.y : height - _margin) - _margin)

            property real _leftToolWidth:       toolStrip.x + toolStrip.width

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

                                      if(QGroundControl.loadGlobalSetting("waypointMark","true")==="true"){
                                          insertSimpleItemAfterCurrent(coordinate)
                                      }


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
                    visible:     true
                    opacity:     _editingLayer == _layerMission || _editingLayer == _layerUTMSP ? 1 : editorMap._nonInteractiveOpacity
                    interactive: _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                    vehicle:     _planMasterController.controllerVehicle
                    onClicked:   (sequenceNumber) => {
                                     _missionController.setCurrentPlanViewSeqNum(sequenceNumber, false)
                                     for (var i = 0; i < _missionController.visualItems.count; i++) {
                                         var item = _missionController.visualItems.get(i)
                                         if (item.sequenceNumber === sequenceNumber) {
                                             missionItemDialog.currentMissionItem = item
                                             missionItemDialog.currentIndex = i
                                             missionItemDialog.open()
                                             missionItemDialog.visible = true
                                             break
                                         }
                                     }
                                 }
                }
            }

            // Add lines between waypoints
            MissionLineView {
                showSpecialVisual:      _missionController.isROIBeginCurrentItem
                model:                  _missionController.simpleFlightPathSegments
                plannedHomePosition:    _missionController.plannedHomePosition
                opacity:            _editingLayer == _layerMission ||  _editingLayer == _layerUTMSP  ? 1 : editorMap._nonInteractiveOpacity
            }

            // Direction arrows in waypoint lines
            MapItemView {
                model: _editingLayer == _layerMission ||_editingLayer == _layerUTMSP ? _missionController.directionArrows : undefined

                delegate: MapLineArrow {
                    fromCoord:      object ? object.coordinate1 : undefined
                    toCoord:        object ? object.coordinate2 : undefined
                    visible:        object && fromCoord && fromCoord.isValid && toCoord && toCoord.isValid && (fromCoord.distanceTo(_missionController.plannedHomePosition) > 0.5) && (toCoord.distanceTo(_missionController.plannedHomePosition) > 0.5)
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
            anchors.top:        planToolBar.bottom
            anchors.topMargin:  0
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
                    color: "#BF000000" // Dark Transparent Black 75% alpha
                    radius: 12
                    border.color: "white"  // Light border for dark background
                    border.width: 2
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 25
                    width: parent.width * 0.8

                    Text {
                        text: "Are you sure you want to share the plan?"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 16
                        color: "white"
                        font.bold: true
                    }

                    Button {
                        text: qsTr("Share")
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120
                        height: 40
                        background: Rectangle {
                            color: Qt.rgba(0, 0, 0, 0.60)  // Darker for button action
                            radius: 20
                            border.color: Qt.rgba(0, 0, 0, 0.40)
                            border.width: 0
                        }
                        contentItem: Text {
                            text: parent.text
                            font.bold: true
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
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


                if(QGroundControl.loadGlobalSetting("waypointMark","true")==="true"){
                    console.log("waypointMark",waypointMark)
                    addWaypointRallyPointAction.checked = QGroundControl.loadGlobalSetting("loadpage","loadpage")=== "Camera" || "Mapping"&& QGroundControl.loadGlobalSetting("waypoint","waypoint")=== "waypoint" ? true : false
                }
            }

            onDropped: allAddClickBoolsOff()
        }

        //-----------------------------------------------------------
        //Right pane for mission editing controls
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
            z : -1
            color:              "transparent"//qgcPal.window
            opacity:            layerTabBar.visible ? 0.2 : 0
            anchors.bottom:     parent.bottom
            anchors.right:      parent.right
            anchors.rightMargin: _toolsMargin
            anchors.top:      planToolBar.bottom
            anchors.topMargin: 0
            visible:           _editingLayer != _layerMission
        }

        //-------------------------------------------------------
        // Right Panel Controls

        Item {
            anchors.fill:           rightPanel
            anchors.topMargin:      0
            z : 0
            visible: true

            DeadMouseArea {
                anchors.fill:   parent
                visible:        false
            }

            Column {
                id:                 rightControls
                spacing:            ScreenTools.defaultFontPixelHeight * 0.4
                anchors.left:       parent.left
                anchors.right:      parent.right

                anchors.top:        parent.top
                anchors.topMargin:  ScreenTools.defaultFontPixelHeight * 0.75

                // 1st: Boundary Point
                Loader {
                    id:                 boundaryButtonsLoader
                    width:              parent.width
                    active:             isMissionTab && activePolygon && (activePolygon.traceMode || mapPolygonvisuals.mapping)
                    visible:            active && !MapGlobals.isReviewMode

                    sourceComponent: Column {
                        spacing:            ScreenTools.defaultFontPixelHeight * 0.6
                        width:              boundaryButtonsLoader.width
                        topPadding:         ScreenTools.defaultFontPixelHeight * 2.5

                        Button {
                            id: boundaryPointBtn
                            width:              parent.width
                            height:             ScreenTools.defaultFontPixelHeight * 2.5
                            padding:            ScreenTools.defaultFontPixelHeight * 0.5
                            background: Rectangle {
                                radius: ScreenTools.defaultFontPixelHeight * 0.45
                                color: Qt.rgba(0, 0, 0, 0.41)
                                anchors.fill: parent
                            }
                            contentItem: Text {
                                text:               qsTr("Boundary Point")
                                font.bold:          true
                                color:              "white"
                                font.pointSize:     ScreenTools.defaultFontPointSize
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                                font.family:        "Outfit"
                            }
                            onClicked: {
                                console.log("Boundary Point clicked in PlanView")
                                mapPolygonvisuals.appendVertexToPolygon(activePolygon)
                            }
                        }
                    }
                }

                // 2nd: Obstacles button
                Column {
                    id:         layerTabBar
                    width:      parent.width
                    spacing:    0
                    visible:    _geoFenceController.supported && !MapGlobals.isReviewMode && MapGlobals.editdialog !== "editdialog"

                    property int currentIndex: 0
                    property bool fenceVisible: _geoFenceController.supported


                    // Row 2 — Fence/Obstacles (only one definition!)
                    Rectangle {
                        visible:  layerTabBar.fenceVisible
                        width:    parent.width
                        height:   ScreenTools.defaultFontPixelHeight * 2.5
                        radius:   ScreenTools.defaultFontPixelHeight * 0.45
                        color:    layerTabBar.currentIndex === 1 ? "black" : Qt.rgba(0, 0, 0, 0.41)
                        border.width: 0

                        Text {
                            id: fenceTabText
                            text: qsTr("Obstacles")
                            color: "white"
                            font.bold:          true
                            font.pointSize:     ScreenTools.defaultFontPointSize
                            font.family:        "Outfit"
                            anchors.centerIn:   parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (_editingLayer === _layerGeoFence) {
                                    _editingLayer = _layerMission
                                    layerTabBar.currentIndex = 0
                                } else {
                                    _editingLayer = _layerGeoFence
                                    layerTabBar.currentIndex = 1
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id:         layerTabBarUTMSP
                    width:      parent.width
                    height:     ScreenTools.defaultFontPixelHeight * 2.2
                    color:      "#f1f5f9"
                    radius:     ScreenTools.defaultFontPixelHeight * 0.45
                    border.color: "#e2e8f0"
                    border.width: 1
                    visible:    QGroundControl.corePlugin.options.enablePlanViewSelector && _utmspEnabled && !MapGlobals.isReviewMode

                    property int currentIndex: 0
                    property bool rallyVisible: _rallyPointController.supported
                    property int _visibleTabCount: 1 + (rallyVisible ? 1 : 0) + 1

                    Rectangle {
                        id: sliderHighlightUTMSP
                        width: (layerTabBarUTMSP.width - 8) / Math.max(1, layerTabBarUTMSP._visibleTabCount)
                        height: layerTabBarUTMSP.height - 8
                        y: 4
                        x: {
                            var tabWidth = width;
                            if (layerTabBarUTMSP.currentIndex === 0) return 4;
                            if (layerTabBarUTMSP.currentIndex === 1) return 4 + tabWidth;
                            if (layerTabBarUTMSP.currentIndex === 2) return 4 + tabWidth * (layerTabBarUTMSP.rallyVisible ? 2 : 1);
                            return 4;
                        }
                        color: "white"
                        radius: 6
                        border.color: "#d1d5db"
                        border.width: 1

                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 0

                        MouseArea {
                            width: (layerTabBarUTMSP.width - 8) / Math.max(1, layerTabBarUTMSP._visibleTabCount)
                            height: parent.height
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                layerTabBarUTMSP.currentIndex = 0
                                _editingLayer = _layerMission
                            }
                            Text {
                                text: qsTr("Mission")
                                anchors.centerIn: parent
                                font.pointSize: 12
                                font.bold: layerTabBarUTMSP.currentIndex === 0
                                color: layerTabBarUTMSP.currentIndex === 0 ? "black" : "#64748b"
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            width: (layerTabBarUTMSP.width - 8) / Math.max(1, layerTabBarUTMSP._visibleTabCount)
                            height: parent.height
                            visible: layerTabBarUTMSP.rallyVisible
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                layerTabBarUTMSP.currentIndex = 1
                                _editingLayer = _layerRallyPoints
                            }
                            Text {
                                text: qsTr("Rally")
                                anchors.centerIn: parent
                                font.pointSize: 12
                                font.bold: layerTabBarUTMSP.currentIndex === 1
                                color: layerTabBarUTMSP.currentIndex === 1 ? "black" : "#64748b"
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            width: (layerTabBarUTMSP.width - 8) / Math.max(1, layerTabBarUTMSP._visibleTabCount)
                            height: parent.height
                            visible: _utmspEnabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                layerTabBarUTMSP.currentIndex = 2
                                _editingLayer = _layerUTMSP
                            }
                            Text {
                                text: qsTr("UTM-Adapter")
                                anchors.centerIn: parent
                                font.pointSize: 12
                                font.bold: layerTabBarUTMSP.currentIndex === 2
                                color: layerTabBarUTMSP.currentIndex === 2 ? "black" : "#64748b"
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                }

            }


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
            //-------------------------------------------------------
            // Mission Item Editor
            Item {
                id:                     missionItemEditor
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.top:            MapGlobals.isReviewMode ? planToolBar.bottom : rightControls.bottom
                anchors.topMargin:      -(ScreenTools.defaultFontPixelHeight * 3.5)
                anchors.bottom:         parent.bottom
                anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 0.35
                visible:                _editingLayer == _layerMission

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
                    visible:            _editingLayer == _layerMission

                    footer: Item {
                        width:  missionItemEditorListView.width
                        height: 20
                        visible: _editingLayer == _layerMission
                    }

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

                    delegate: Item {
                        property bool _showItem : true
                        width: missionItemEditorListView.width
                        visible: MapGlobals.showMissionItems
                        height: visible ? innerEditor.height : 0

                        MissionExpand {
                            id: innerEditor
                                map: editorMap
                                masterController:  _planMasterController
                                missionItem:    object
                                width:          parent.width
                                readOnly:       false
                                onClicked: (sequenceNumber) => {
                                    _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false)
                                }
                                onEditItemClicked: (popupItem) => {
                                    itemEditPopup.popupMissionItem = popupItem
                                    itemEditPopup.open()
                                }
                                onDeselect: {
                                    _missionController.setCurrentPlanViewSeqNum(-1, false)
                                }
                        }
                    }
                }
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

            UTMSPAdapterEditor {
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

            // 3rd: Save Plan at the bottom
            Button {
                id:                     savePlanBtn
                anchors.bottom:         parent.bottom
                anchors.bottomMargin:   ScreenTools.defaultFontPixelHeight * 0.5
                anchors.left:           parent.left
                anchors.right:          parent.right
                height:                 ScreenTools.defaultFontPixelHeight * 2.5
                text:                   qsTr("Save Plan")
                visible:                _editingLayer == _layerMission && (!MapGlobals.isReviewMode || MapGlobals.showMissionItems)
                
                background: Rectangle {
                    radius: ScreenTools.defaultFontPixelHeight * 0.45
                    color: "black"
                    border.color: "white"
                    border.width: 1
                }

                contentItem: Text {
                    text:               savePlanBtn.text
                    font.bold:          true
                    color:              "white"
                    font.pointSize:     14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                    font.family:        "Outfit"
                }

                onClicked: {
                    var currentCommand = _currentItem ? _currentItem.commandName : "";
                    var isMissionActionPage = (currentCommand === "Mission Start" || currentCommand === "Survey" || currentCommand === "Return To Launch");
                    
                    // Check if we are in Boundary or Obstacle editing mode
                    var isBoundaryMode = (boundaryButtonsLoader && boundaryButtonsLoader.visible) || 
                                         (layerTabBar && layerTabBar.currentIndex === 1) || 
                                         (activePolygon && activePolygon.traceMode);

                    if (isMissionActionPage && !isBoundaryMode) {
                        MapGlobals.save = "save1"
                        if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping") {
                            _planMasterController.saveToSelectedFile1()
                        } else {
                            _planMasterController.saveToSelectedFile()
                        }
                    } else {
                        if (activePolygon && activePolygon.traceMode) {
                            if (activePolygon.count < 3) {
                                console.log("Save: Not enough vertices (<3), restoring previous vertices")
                                mapPolygonvisuals.restorePreviousVertices()
                                return
                            }
                            activePolygon.traceMode = false
                        }
                        if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping") {
                            _planMasterController.saveToSelectedFile1()
                        } else {
                            _planMasterController.saveToSelectedFile()
                        }
                    }
                }
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

        // Popup {
        //     id: missionItemDialog
        //     width: ScreenTools.isMobile ? parent.width * 0.45 : 450
        //     height: ScreenTools.isMobile ? parent.height * 0.75 : 600

        //     // Position in the bottom-right corner
        //     x: parent.width - width - 20
        //     property real targetY: parent.height - height - 20
        //     y: targetY

        //     modal: false
        //     dim: false
        //     closePolicy: Popup.NoAutoClose
        //     parent: Overlay.overlay

        //     property int currentIndex: -1
        //     property var currentMissionItem: null

        //     // Slide animation from bottom
        //     enter: Transition {
        //         NumberAnimation { property: "y"; from: missionItemDialog.parent.height; to: missionItemDialog.targetY; duration: 350; easing.type: Easing.OutExpo }
        //     }
        //     exit: Transition {
        //         NumberAnimation { property: "y"; to: missionItemDialog.parent.height; duration: 250; easing.type: Easing.InCubic }
        //     }

        //     background: Rectangle {
        //         color:        "#BF000000" // Dark Transparent Black 75% alpha
        //         radius:       15          // Rounded dialog corners (as shown in image)
        //         border.color: "#3a3750"
        //         border.width: 1
        //     }

        //     // Header Area
        //     Item {
        //         id: drawerHeader
        //         width: parent.width
        //         height: 60
        //         anchors.top: parent.top

        //         Text {
        //             text: missionItemDialog.currentMissionItem ? missionItemDialog.currentMissionItem.commandName : "Edit Item"
        //             font.pixelSize: 18
        //             font.bold: true
        //             color: "#e8e4f0"   // Light text on dark background
        //             anchors.centerIn: parent
        //         }

        //         Rectangle {
        //             id: closeBtn
        //             width: 32
        //             height: 32
        //             radius: 16
        //             color: closeBtnArea.pressed ? "#3d3a50" : (closeBtnArea.containsMouse ? "#2e2b42" : "#1e1b2e")
        //             border.color: "#4a4560"
        //             border.width: 1
        //             anchors.right: parent.right
        //             anchors.verticalCenter: parent.verticalCenter
        //             anchors.margins: 15
        //             Behavior on color { ColorAnimation { duration: 100 } }

        //             QGCColoredImage {
        //                 source: "qrc:/InstrumentValueIcons/close.svg"
        //                 color: closeBtnArea.containsMouse ? "#e0dcf8" : "#9898bb"
        //                 width: 14
        //                 height: 14
        //                 anchors.centerIn: parent
        //                 Behavior on color { ColorAnimation { duration: 100 } }
        //             }

        //             MouseArea {
        //                 id: closeBtnArea
        //                 anchors.fill: parent
        //                 hoverEnabled: true
        //                 cursorShape: Qt.PointingHandCursor
        //                 onClicked: {
        //                     missionItemDialog.close()
        //                     mainWindow.showPlanView()
        //                 }
        //             }
        //         }

        //         // Subtle divider line
        //         Rectangle {
        //             width: parent.width
        //             height: 1
        //             color: "#3d3a50"
        //             anchors.bottom: parent.bottom
        //         }
        //     }

        //     QGCFlickable {
        //         id: flickableEditor
        //         anchors.top: drawerHeader.bottom
        //         anchors.left: parent.left
        //         anchors.right: parent.right
        //         anchors.bottom: parent.bottom
        //         contentWidth: width
        //         anchors.margins: 10
        //         contentHeight: editorContent.implicitHeight
        //         clip: true
        //         flickableDirection: Flickable.VerticalFlick

        //         Column {
        //             id: editorContent
        //             width: flickableEditor.width

        //             MissionItemEditor {
        //                 id: editor
        //                 width: parent.width
        //                 map: editorMap
        //                 masterController: _planMasterController
        //                 missionItem: missionItemDialog.currentMissionItem
        //                 readOnly: false

        //                 onClicked: (sequenceNumber) => {
        //                                _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false)
        //                            }

        //                 onRemove: {
        //                     var removeVIIndex = missionItemDialog.currentIndex
        //                     _missionController.removeVisualItem(removeVIIndex)
        //                     if (removeVIIndex >= _missionController.visualItems.count) {
        //                         removeVIIndex--
        //                     }

        //                     if(missionItemDialog.currentMissionItem && missionItemDialog.currentMissionItem.commandName==="Return To Launch"){
        //                         QGroundControl.saveGlobalSetting("waypoint", "waypoint")
        //                         MapGlobals.waypoint="waypoint"
        //                         returnWaypointEnabled=true
        //                         waypointMark=true
        //                     } else if(missionItemDialog.currentMissionItem && missionItemDialog.currentMissionItem.commandName==="Takeoff"){
        //                         QGroundControl.saveGlobalSetting("Takeoff", "Takeoff")
        //                         mapclear()
        //                     }

        //                     missionItemDialog.close()
        //                 }

        //                 onSelectNextNotReadyItem: {
        //                     selectNextNotReady()
        //                 }
        //             }
        //         }
        //     }
        // }

        // Popup {
        //     id: geoFenceDrawer
        //     width: ScreenTools.isMobile ? parent.width * 0.45 : 450
        //     height: ScreenTools.isMobile ? parent.height * 0.75 : 600

        //     // Position in the bottom-right corner
        //     x: parent.width - width - 20
        //     property real targetY: parent.height - height - 20
        //     y: targetY

        //     modal: false
        //     dim: false
        //     closePolicy: Popup.NoAutoClose
        //     parent: Overlay.overlay
        //     visible: _editingLayer == _layerGeoFence
        //     onClosed: {
        //         if (layerTabBar.currentIndex === 1) {
        //             layerTabBar.currentIndex = 0;
        //         }
        //     }

        //     // Slide animation from bottom
        //     enter: Transition {
        //         NumberAnimation { property: "y"; from: geoFenceDrawer.parent.height; to: geoFenceDrawer.targetY; duration: 350; easing.type: Easing.OutExpo }
        //     }
        //     exit: Transition {
        //         NumberAnimation { property: "y"; to: geoFenceDrawer.parent.height; duration: 250; easing.type: Easing.InCubic }
        //     }

        //     background: Rectangle {
        //         color:        "#BF000000" // Dark Transparent Black 75% alpha
        //         radius:       15
        //         border.color: "#3a3750"
        //         border.width: 1
        //     }

        //     Item {
        //         id: geoFenceDrawerHeader
        //         width: parent.width
        //         height: 60
        //         anchors.top: parent.top

        //         Text {
        //             text: qsTr("GeoFence Settings")
        //             font.pixelSize: 18
        //             font.bold: true
        //             color: "#e8e4f0"
        //             anchors.centerIn: parent
        //         }

        //         Rectangle {
        //             id: geoFenceCloseBtn
        //             width: 32
        //             height: 32
        //             radius: 16
        //             color: closeGeoArea.pressed ? "#3d3a50" : (closeGeoArea.containsMouse ? "#2e2b42" : "#1e1b2e")
        //             border.color: "#4a4560"
        //             border.width: 1
        //             anchors.right: parent.right
        //             anchors.verticalCenter: parent.verticalCenter
        //             anchors.rightMargin: 15
        //             Behavior on color { ColorAnimation { duration: 100 } }

        //             QGCColoredImage {
        //                 source: "qrc:/InstrumentValueIcons/close.svg"
        //                 color: closeGeoArea.containsMouse ? "#e0dcf8" : "#9898bb"
        //                 width: 14
        //                 height: 14
        //                 anchors.centerIn: parent
        //                 Behavior on color { ColorAnimation { duration: 100 } }
        //             }

        //             MouseArea {
        //                 id: closeGeoArea
        //                 anchors.fill: parent
        //                 hoverEnabled: true
        //                 cursorShape: Qt.PointingHandCursor
        //                 onClicked: {
        //                     geoFenceDrawer.close()
        //                 }
        //             }
        //         }

        //         Rectangle {
        //             width: parent.width
        //             height: 1
        //             color: "#3d3a50"
        //             anchors.bottom: parent.bottom
        //         }
        //     }

        //     GeoFenceEditor {
        //         id: geoFenceEditor
        //         anchors.top: geoFenceDrawerHeader.bottom
        //         anchors.left: parent.left
        //         anchors.right: parent.right
        //         anchors.bottom: parent.bottom
        //         anchors.margins: 10
        //         myGeoFenceController: _geoFenceController
        //         flightMap: editorMap
        //     }
        // }

        Item {
            id: editdata
            width: childrenRect.width
            height: childrenRect.height
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.5
            anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 1.5

            Row {
                spacing: 10    // space between the two buttons

                // ========== Upload Button ==========
                Button {
                    id: fileUploadbtn
                    width: baseSize
                    height: baseSize

                    background: Rectangle {
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.40)  // Transparent black button
                        border.color: Qt.rgba(0, 0, 0, 0.40)
                        border.width: 0
                        anchors.fill: parent
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        QGCColoredImage {
                            source: "/qmlimages/NewImages/fileupload.svg"
                            width: iconSize
                            height: iconSize
                            anchors.centerIn: parent
                            color: "white"
                        }
                    }

                    onClicked: {
                        console.log("Upload clicked")
                        waypointMark=false
                        if(_activeVehicle) {
                            if (_utmspEnabled) {
                                QGroundControl.utmspManager.utmspVehicle.triggerActivationStatusBar(true);
                                UTMSPStateStorage.removeFlightPlanState = true
                                UTMSPStateStorage.indicatorDisplayStatus = true
                            }
                            _planMasterController.upload()
                        } else {
                            mainWindow.showToastMessage("Drone Not Connected");
                        }
                    }
                }

                // ========== Return Waypoint Button ==========
                Button {
                    width: baseSize
                    height: baseSize

                    visible: showReturnWaypoint
                    enabled: returnWaypointEnabled

                    background: Rectangle {
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.40)  // Transparent black button
                        border.color: Qt.rgba(0, 0, 0, 0.40)
                        border.width: 0
                        anchors.fill: parent
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        QGCColoredImage {
                            source: "/res/rtl.svg"
                            width: iconSize
                            height: iconSize
                            anchors.centerIn: parent
                            color: "white"
                        }
                    }

                    onClicked: {
                        waypointMark=false
                        // MapGlobals.waypoint="waypoint1"
                        // QGroundControl.saveGlobalSetting("waypoint", "waypoint1")
                        console.log("returnWaypoint clicked")

                        toolStrip.allAddClickBoolsOff()
                        insertLandItemAfterCurrent()
                        QGroundControl.saveGlobalSetting("returnWaypointEnabled", "false")
                        returnWaypointEnabled = false
                    }
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
                    radius: 12
                    color: "#BF000000" // Dark Transparent Black 75% alpha
                    border.color: "#471880"
                    border.width: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 25
                        anchors.margins: 20

                        // Centered Title
                        Label {
                            text: qsTr("Are you sure you want to share the plan?")
                            font.bold: true
                            font.pointSize: 16
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        // Buttons Row
                        Row {
                            spacing: 30
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                text: " Share"
                                width: 120
                                height: 40
                                background: Rectangle {
                                    radius: 20
                                    color: Qt.rgba(0, 0, 0, 0.40)  // Transparent black dialog button
                                    border.color: Qt.rgba(0, 0, 0, 0.40)
                                    border.width: 0
                                }
                                contentItem: Text {
                                    text: parent.text
                                    font.bold: true
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
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
            anchors.bottomMargin: 40
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
            //anchors.bottom:         terrainStatus.visible ? terrainStatus.top : parent.bottom
            anchors.top:            parent.top
            anchors.left:           toolStrip.y + toolStrip.height + _toolsMargin > mapScale.y ? toolStrip.right: parent.left
            mapControl:             editorMap
            buttonsOnLeft:          true
            terrainButtonVisible:   false//_editingLayer === _layerMission
            terrainButtonChecked:   terrainStatus.visible
            onTerrainButtonClicked: terrainStatus.toggleVisible()
            visible:true
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
        MapGlobals.share_edit_visibility = false
        MapGlobals.isReviewMode = false
        MapGlobals.showMissionItems = false
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

    // --- Slide-up Mission Actions Popup ---
    // Popup {
    //     id: missionActionsPopup
    //     width: ScreenTools.defaultFontPixelWidth * 45
    //     height: 60

    //     x: (parent.width - width) / 2
    //     property real targetY: parent.height - height - 80 // Anchor exactly above the bottom tab bar
    //     y: targetY

    //     modal: false    // So user can still click map while open
    //     dim: false

    //     enter: Transition {
    //         NumberAnimation { property: "y"; from: missionActionsPopup.parent.height; to: missionActionsPopup.targetY; duration: 250; easing.type: Easing.OutQuart }
    //     }
    //     exit: Transition {
    //         NumberAnimation { property: "y"; to: missionActionsPopup.parent.height; duration: 250; easing.type: Easing.OutQuart }
    //     }

    //     background: Rectangle {
    //         color: Qt.rgba(0, 0, 0, 0.40)
    //     }

    //     contentItem: RowLayout {
    //         spacing: 12

    //         Repeater {
    //             model: {
    //                 var actions = [ { "text": qsTr("Mission Start"), "action": "start" } ]
    //                 if (droneType !== "Agri") {
    //                     actions.push({ "text": qsTr("Takeoff"), "action": "takeoff" })
    //                 }
    //                 actions.push({ "text": qsTr("Survey"), "action": "survey" })
    //                 actions.push({ "text": qsTr("Return To Launch"), "action": "rtl" })
    //                 return actions
    //             }

    //             Rectangle {
    //                 Layout.fillWidth: true
    //                 Layout.fillHeight: true
    //                 radius: 12
    //                 color: Qt.rgba(0, 0, 0, 0.40)  // Transparent black popup item
    //                 border.color: Qt.rgba(0, 0, 0, 0.40)
    //                 border.width: 0

    //                 Text {
    //                     anchors.centerIn: parent
    //                     text: modelData.text
    //                     color: "white"
    //                     font.pointSize: 10
    //                     font.bold: true
    //                     font.family: "Outfit"
    //                 }

    //                 MouseArea {
    //                     anchors.fill: parent
    //                     cursorShape: Qt.PointingHandCursor
    //                     onClicked: {
    //                         missionActionsPopup.close()

    //                         var items = _missionController.visualItems
    //                         var targetIndex = -1
    //                         var targetItem  = null

    //                         if (modelData.action === "start") {
    //                             // Always open item 0 (Mission Start / planned home)
    //                             targetIndex = 0
    //                             targetItem  = items.get(0)
    //                             if (targetItem)
    //                                 _missionController.setCurrentPlanViewSeqNum(targetItem.sequenceNumber, false)

    //                         } else if (modelData.action === "survey") {
    //                             // Find first existing Survey; insert new one only if absent
    //                             for (var i = 0; i < items.count; i++) {
    //                                 var it = items.get(i)
    //                                 if (it && it.commandName === "Survey") {
    //                                     targetIndex = i
    //                                     targetItem  = it
    //                                     _missionController.setCurrentPlanViewSeqNum(it.sequenceNumber, false)
    //                                     break
    //                                 }
    //                             }
    //                             if (!targetItem) {
    //                                 insertComplexItemAfterCurrent("Survey")
    //                                 targetIndex = _missionController.currentPlanViewVIIndex
    //                                 targetItem  = items.get(targetIndex)
    //                             }

    //                         } else if (modelData.action === "takeoff") {
    //                             for (var k = 0; k < items.count; k++) {
    //                                 var tkfIt = items.get(k)
    //                                 if (tkfIt && tkfIt.commandName === "Takeoff") {
    //                                     targetIndex = k
    //                                     targetItem = tkfIt
    //                                     _missionController.setCurrentPlanViewSeqNum(tkfIt.sequenceNumber, false)
    //                                     break
    //                                 }
    //                             }
    //                             if (!targetItem) {
    //                                 insertTakeItemAfterCurrent()
    //                                 targetIndex = _missionController.currentPlanViewVIIndex
    //                                 targetItem = items.get(targetIndex)
    //                             }

    //                         } else if (modelData.action === "rtl") {
    //                             // Find first existing Return-To-Launch; insert new one only if absent
    //                             for (var j = 0; j < items.count; j++) {
    //                                 var rtlIt = items.get(j)
    //                                 if (rtlIt && rtlIt.commandName === "Return To Launch") {
    //                                     targetIndex = j
    //                                     targetItem  = rtlIt
    //                                     _missionController.setCurrentPlanViewSeqNum(rtlIt.sequenceNumber, false)
    //                                     break
    //                                 }
    //                             }
    //                             if (!targetItem) {
    //                                 insertLandItemAfterCurrent()
    //                                 targetIndex = _missionController.currentPlanViewVIIndex
    //                                 targetItem  = items.get(targetIndex)
    //                             }
    //                         }

    //                         if (targetItem) {
    //                             missionItemDialog.currentMissionItem = targetItem
    //                             missionItemDialog.currentIndex       = targetIndex
    //                             missionItemDialog.open()
    //                         }
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }


    PlanViewToolBar {
        id:                     planToolBar
        planMasterController:   _planMasterController
        z:                      100
        //plantypes:planType
    }

    // Compass icon — placed as direct child of _root so anchor to planToolBar.bottom works correctly
    Item {
        id:                 compassNorth
        width:              baseSize
        height:             baseSize
        anchors.top:        planToolBar.bottom
        anchors.left:       parent.left
        anchors.topMargin:  ScreenTools.defaultFontPixelHeight * 0.1
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 0.25
        z:                  QGroundControl.zOrderWidgets + 1

        Rectangle {
            width:        baseSize
            height:       baseSize
            radius:       width / 2
            color:        "transparent"
            border.width: 0
            border.color: Qt.rgba(0, 0, 0, 0.40)
            clip:         true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    MapGlobals.mapRotation = 0
                }
            }

            QGCColoredImage {
                id:               compassArrow
                source:           "/qmlimages/NewImages/cardinal_point.svg"
                anchors.centerIn: parent
                width:            iconSize
                height:           iconSize
                fillMode:         Image.PreserveAspectFit
                transform: Rotation {
                    origin.x: compassArrow.width  / 2
                    origin.y: compassArrow.height / 2
                    angle:    -MapGlobals.mapRotation
                }
                color: "white"
            }
        }
    }

    // Popup for Mission Start / Survey Item Editing
    Popup {
        id: itemEditPopup
        property var popupMissionItem: null

        // Reserve space: planToolBar height + bottom margin
        readonly property real _maxPopupHeight: parent ? (parent.height - planToolBar.height - ScreenTools.defaultFontPixelHeight * 2) : 500
        // title (~40) + spacing(12) + doneBtn(40) + spacing(12) + padding(20)
        readonly property real _reservedHeight: 124

        // Responsive width
        width:  Math.min(ScreenTools.defaultFontPixelWidth * 25, parent.width * 0.85)
        height: Math.min(popupInnerCol.implicitHeight + ScreenTools.defaultFontPixelHeight * 4, _maxPopupHeight)
        
        // Left side, keeping it classy and subtle
        x: ScreenTools.defaultFontPixelWidth
        y: parent ? parent.height - height - ScreenTools.defaultFontPixelHeight * 1.5 : 0
        
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape
        parent: Overlay.overlay

        background: Rectangle {
            color: Qt.rgba(0.05, 0.05, 0.05, 0.35)
            radius: 12
            border.color: Qt.rgba(1, 1, 1, 0.30)
            border.width: 1
        }

        contentItem: Column {
            id: popupInnerCol
            spacing: 12
            width: itemEditPopup.width - 40
            anchors.centerIn: parent

            Text {
                text: itemEditPopup.popupMissionItem ? qsTr(((itemEditPopup.popupMissionItem.commandName === "Survey" && QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri") ? "Plot" : itemEditPopup.popupMissionItem.commandName) + " Settings") : qsTr("Settings")
                font.pointSize: 16
                font.bold: true
                color: "white"
                font.family: "Outfit"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ScrollView {
                id:     popupScrollView
                width:  parent.width
                // Height = total popup minus space for title, done button, spacings and padding
                height: Math.max(100, itemEditPopup._maxPopupHeight - itemEditPopup._reservedHeight)
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy:   ScrollBar.AsNeeded

                Column {
                    width: popupScrollView.width

                    MissionSettingsEditor {
                        id:             missionStartEditorInst
                        width:          popupScrollView.width
                        availableWidth: popupScrollView.width
                        missionItem:    (itemEditPopup.popupMissionItem && itemEditPopup.popupMissionItem.commandName === "Mission Start")
                                            ? itemEditPopup.popupMissionItem : null
                        masterController: _planMasterController
                        visible:        itemEditPopup.popupMissionItem !== null && itemEditPopup.popupMissionItem.commandName === "Mission Start"
                    }

                    Loader {
                        id:     genericEditorLoader
                        width:  popupScrollView.width
                        source: (itemEditPopup.popupMissionItem &&
                                 itemEditPopup.popupMissionItem.commandName !== "Mission Start" &&
                                 itemEditPopup.popupMissionItem.commandName !== "Survey")
                                    ? itemEditPopup.popupMissionItem.editorQml : ""
                        visible: itemEditPopup.popupMissionItem !== null &&
                                 itemEditPopup.popupMissionItem.commandName !== "Mission Start" &&
                                 itemEditPopup.popupMissionItem.commandName !== "Survey"

                        property var    missionItem:        itemEditPopup.popupMissionItem
                        property var    masterController:   _planMasterController
                        property real   availableWidth:     popupScrollView.width
                        property var    editorRoot:         null
                    }

                    Loader {
                        id:     surveyEditorLoader
                        width:  popupScrollView.width
                        source: (itemEditPopup.popupMissionItem && itemEditPopup.popupMissionItem.commandName === "Survey")
                                    ? itemEditPopup.popupMissionItem.editorQml : ""
                        visible: itemEditPopup.popupMissionItem !== null && itemEditPopup.popupMissionItem.commandName === "Survey"

                        property var    missionItem:        itemEditPopup.popupMissionItem
                        property var    masterController:   _planMasterController
                        property real   availableWidth:     popupScrollView.width
                        property var    editorRoot:         null
                    }
                }
            }

            Button {
                text: qsTr("Done")
                anchors.horizontalCenter: parent.horizontalCenter
                width: 150
                height: 40
                onClicked: itemEditPopup.close()

                background: Rectangle {
                    color: "white"
                    radius: 20
                }
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

//     // --- Survey Adjustment Overlay (Agri Mode) ---
//     // --- Survey Adjustment Overlay (Agri Mode) ---
//     Rectangle {
//         id: surveyAdjustmentOverlay
//         anchors.bottom:             parent.bottom
//         anchors.horizontalCenter:   parent.horizontalCenter
//         anchors.bottomMargin:       20
//         width:                      Math.min(1100, parent.width * 0.98)
//         height:                     70
//         radius:                     35
//         color:                      "#FFFFFF"
//         border.color:               "#E0E0E0"
//         border.width:               1
//         visible:                    true//MapGlobals.isReviewMode && _isSurveySelected && droneType === "Agri"
//         z:                          1000

//         property var currentSurveyItem: (_missionController && _missionController.currentPlanViewSeqNum !== -1) ? _missionController.visualItems.get(_missionController.currentPlanViewSeqNum) : null
//         readonly property bool _isSurveySelected: currentSurveyItem && currentSurveyItem.commandName === "Survey"

//         RowLayout {
//             anchors.fill:       parent
//             anchors.margins:    15
//             spacing:            30

//             // Indentation Control
//             RowLayout {
//                 spacing: 12
//                 Rectangle {
//                     width:          40
//                     height:         40
//                     radius:         20
//                     color:          "#F5F5F5"
//                     border.color:   "#DDD"
//                     border.width:   1
//                     QGCLabel {
//                         anchors.centerIn:   parent
//                         text:               "−"
//                         color:              "black"
//                         font.bold:          true
//                         font.pointSize:     18
//                     }
//                     MouseArea {
//                         anchors.fill: parent
//                         onClicked: if (surveyAdjustmentOverlay.currentSurveyItem) surveyAdjustmentOverlay.currentSurveyItem.boundaryIndentation = surveyAdjustmentOverlay.currentSurveyItem.boundaryIndentation - 0.5
//                     }
//                 }
//                 Rectangle {
//                     width:          40
//                     height:         40
//                     radius:         20
//                     color:          "#F5F5F5"
//                     border.color:   "#DDD"
//                     border.width:   1
//                     QGCLabel {
//                         anchors.centerIn:   parent
//                         text:               "+"
//                         color:              "black"
//                         font.bold:          true
//                         font.pointSize:     18
//                     }
//                     MouseArea {
//                         anchors.fill: parent
//                         onClicked: if (surveyAdjustmentOverlay.currentSurveyItem) surveyAdjustmentOverlay.currentSurveyItem.boundaryIndentation = surveyAdjustmentOverlay.currentSurveyItem.boundaryIndentation + 0.5
//                     }
//                 }
//                 QGCLabel {
//                     text:           qsTr("Indentation ") + (surveyAdjustmentOverlay.currentSurveyItem ? surveyAdjustmentOverlay.currentSurveyItem.boundaryIndentation.toFixed(1) : "0.0") + "m"
//                     color:          "black"
//                     font.pointSize: ScreenTools.mediumFontPointSize
//                     font.bold:      true
//                 }
//             }

//             // Obstacle Margin Control
//             RowLayout {
//                 spacing: 12
//                 Rectangle {
//                     width:          40
//                     height:         40
//                     radius:         20
//                     color:          "#F5F5F5"
//                     border.color:   "#DDD"
//                     border.width:   1
//                     QGCLabel {
//                         anchors.centerIn:   parent
//                         text:               "−"
//                         color:              "black"
//                         font.bold:          true
//                         font.pointSize:     18
//                     }
//                     MouseArea {
//                         anchors.fill: parent
//                         onClicked: if (surveyAdjustmentOverlay.currentSurveyItem) surveyAdjustmentOverlay.currentSurveyItem.obstacleIndentation = surveyAdjustmentOverlay.currentSurveyItem.obstacleIndentation - 0.5
//                     }
//                 }
//                 Rectangle {
//                     width:          40
//                     height:         40
//                     radius:         20
//                     color:          "#F5F5F5"
//                     border.color:   "#DDD"
//                     border.width:   1
//                     QGCLabel {
//                         anchors.centerIn:   parent
//                         text:               "+"
//                         color:              "black"
//                         font.bold:          true
//                         font.pointSize:     18
//                     }
//                     MouseArea {
//                         anchors.fill: parent
//                         onClicked: if (surveyAdjustmentOverlay.currentSurveyItem) surveyAdjustmentOverlay.currentSurveyItem.obstacleIndentation = surveyAdjustmentOverlay.currentSurveyItem.obstacleIndentation + 0.5
//                     }
//                 }
//                 QGCLabel {
//                     text:           qsTr("Obstacle Margin ") + (surveyAdjustmentOverlay.currentSurveyItem ? surveyAdjustmentOverlay.currentSurveyItem.obstacleIndentation.toFixed(1) : "0.0") + "m"
//                     color:          "black"
//                     font.pointSize: ScreenTools.mediumFontPointSize
//                     font.bold:      true
//                 }
//             }

//             // Choose All
//             QGCCheckBox {
//                 text:           qsTr("Choose all")
//                 font.pointSize: ScreenTools.smallFontPointSize
//             }

//             Item { Layout.fillWidth: true }

//             // Navigation
//             RowLayout {
//                 spacing: 15
//                 QGCButton {
//                     text: qsTr("Previous")
//                     onClicked: {
//                         var count = _missionController.visualItems.count
//                         var start = _missionController.currentPlanViewSeqNum
//                         for (var i = 1; i <= count; i++) {
//                             var idx = (start - i + count) % count
//                             var item = _missionController.visualItems.get(idx)
//                             if (item.commandName === "Survey") {
//                                 _missionController.setCurrentPlanViewSeqNum(idx, true)
//                                 return
//                             }
//                         }
//                     }
//                 }
//                 QGCButton {
//                     text: qsTr("Next")
//                     onClicked: {
//                         var count = _missionController.visualItems.count
//                         var start = _missionController.currentPlanViewSeqNum
//                         for (var i = 1; i <= count; i++) {
//                             var idx = (start + i) % count
//                             var item = _missionController.visualItems.get(idx)
//                             if (item.commandName === "Survey") {
//                                 _missionController.setCurrentPlanViewSeqNum(idx, true)
//                                 return
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }

// }

} // root Item

