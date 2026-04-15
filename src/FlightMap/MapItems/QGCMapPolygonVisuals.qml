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
import QtLocation
import QtPositioning
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.FlightMap
import QGroundControl.ShapeFileHelper
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controllers

import MapGlobals
import Qt.labs.platform as Platform

/// QGCMapPolygon map visuals
Item {
    id: _root
    property int selectedVertexIndex : -1                   // Will store the MapQuickItem the user clicked
    property var    mapControl                                  ///< Map control to place item in
    property var    mapPolygon                                  ///< QGCMapPolygon object

    property bool            interactive:        mapPolygon ? mapPolygon.interactive : false
    property color  interiorColor:      "transparent"
    property color  altColor:           "transparent"
    property real   interiorOpacity:    1
    property int    borderWidth:        mapping ? 4 : 0
    property color  borderColor:        mapping ? "white" : "black"

    property bool   _circleMode:                false
    property real   _circleRadius
    property bool   _circleRadiusDrag:          false
    property var    _circleRadiusDragCoord:     QtPositioning.coordinate()
    property bool   _editCircleRadius:          false
    property string _instructionText:           _polygonToolsText
    property var    _savedVertices:             [ ]
    property bool   _savedCircleMode
    property bool   _isVertexBeingDragged:      true
    property string concatenatedText: ""
    property var    _appSettings:       QGroundControl.settingsManager.appSettings
    property real _zorderDragHandle:    QGroundControl.zOrderMapItems + 3   // Highest to prevent splitting when items overlap
    property real _zorderSplitHandle:   QGroundControl.zOrderMapItems + 2
    property real _zorderCenterHandle:  QGroundControl.zOrderMapItems + 1   // Lowest such that drag or split takes precedence

    property var _planMasterController:              planMasterController
    property var _missionController:              planMasterController.missionController


    readonly property string _polygonToolsText: qsTr("")//("Polygon Tools")
    readonly property string _traceText:        qsTr("")//qsTr("Click in the map to add vertices. Click 'Done Tracing' when finished.")
    property var gcsPosition: QGroundControl.qgcPositionManager.gcsPosition
    property real gcsHeading: QGroundControl.qgcPositionManager.gcsHeading

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var activeVehicleCoordinate: activeVehicle ? activeVehicle.coordinate : QtPositioning.coordinate()
    property bool   mapping:                false

    property var    _toolbarItem:           null

    property string droneType: "loadpage"


    // Base size relative to screen
    property real baseSize: Math.min(Screen.width, Screen.height) * 0.06

    // Button & icon sizes
    property real buttonSize: Math.max(45, Math.min(baseSize, 64))
    property real iconSize: buttonSize * 0.2

    property real cardinalLeftScreenX:   0
    property real cardinalBottomScreenY: 0

    onVisibleChanged : {
        if (visible) {
            droneType = QGroundControl.loadGlobalSetting("loadpage","loadpage");
            if(droneType==="Mapping"){
                mapping = true
            }
        }
    }


    function addCommonVisuals() {
        console.log("addCommonVisuals method")
        if (_objMgrCommonVisuals.empty) {
            _objMgrCommonVisuals.createObject(polygonComponent, mapControl, true)
        }
    }


    // function dailogclose() {
    //     customDialogItem.visible=false;
    // }

    function tracemode() {
        mapPolygon.traceMode = false
    }

    function removeCommonVisuals() {
        console.log("removeCommonVisuals method")
        _objMgrCommonVisuals.destroyObjects()
    }

    function addEditingVisuals() {
        console.log("new_addEditingVisuals()")
        if (_objMgrEditingVisuals.empty) {
            _objMgrEditingVisuals.createObjects(
                        [ dragHandlesComponent, splitHandlesComponent, centerDragHandleComponent, edgeLengthHandlesComponent ],
                        mapControl,
                        false /* addToMap */)
        }
    }

    function removeEditingVisuals() {
        console.log("removeEditingVisuals method")
        _objMgrEditingVisuals.destroyObjects()
    }

    function addToolbarVisuals() {
        console.log("new_addToolbarVisuals")
        if (_objMgrToolVisuals.empty) {
            // if(QGroundControl.loadGlobalSetting("mapping","mapping")==="basic"){
            //     _resetPolygon()
            // }else if(QGroundControl.loadGlobalSetting("mapping","mapping")==="circle"){
            //     _resetCircle()
            // }
            _toolbarItem = _objMgrToolVisuals.createObject(toolbarComponent, mapControl)
            _toolbarItem.z = QGroundControl.zOrderWidgets
            var edit = MapGlobals.edit
            console.log("MapGlobals.edit")
            console.log("MapGlobals.edit",MapGlobals.edit)
            if(MapGlobals.edit==="edit"){
                if(QGroundControl.loadGlobalSetting("load","load")==="load"){
                    customdialog.createObject(mainWindow).open()
                }

            }else if (MapGlobals.edit==="edit2"){
                _saveCurrentVertices()
                _circleMode = false
                if (mapPolygon) mapPolygon.traceMode = true
            }else{
                _saveCurrentVertices()
                _circleMode = false
                if (mapPolygon) mapPolygon.traceMode = true
            }
        }
    }

    function removeToolVisuals() {
        console.log("removeToolVisuals method")
        _objMgrToolVisuals.destroyObjects()
        _toolbarItem = null
    }

    function addCircleVisuals() {
        if (_objMgrCircleVisuals.empty) {
            _objMgrCircleVisuals.createObject(radiusVisualsComponent, mapControl)
        }
    }

    /// Calculate the default/initial 4 sided polygon
    function defaultPolygonVertices() {
        // Initial polygon is inset to take 2/3rds space
        var rect = Qt.rect(mapControl.centerViewport.x, mapControl.centerViewport.y, mapControl.centerViewport.width, mapControl.centerViewport.height)
        rect.x += (rect.width * 0.25) / 2
        rect.y += (rect.height * 0.25) / 2
        rect.width *= 0.75
        rect.height *= 0.75

        var centerCoord =       mapControl.toCoordinate(Qt.point(rect.x + (rect.width / 2), rect.y + (rect.height / 2)),   false /* clipToViewPort */)
        var topLeftCoord =      mapControl.toCoordinate(Qt.point(rect.x, rect.y),                                          false /* clipToViewPort */)
        var topRightCoord =     mapControl.toCoordinate(Qt.point(rect.x + rect.width, rect.y),                             false /* clipToViewPort */)
        var bottomLeftCoord =   mapControl.toCoordinate(Qt.point(rect.x, rect.y + rect.height),                            false /* clipToViewPort */)
        var bottomRightCoord =  mapControl.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height),               false /* clipToViewPort */)

        // Initial polygon has max width and height of 3000 meters
        var halfWidthMeters =   Math.min(topLeftCoord.distanceTo(topRightCoord), 3000) / 2
        var halfHeightMeters =  Math.min(topLeftCoord.distanceTo(bottomLeftCoord), 3000) / 2
        topLeftCoord =      centerCoord.atDistanceAndAzimuth(halfWidthMeters, -90).atDistanceAndAzimuth(halfHeightMeters, 0)
        topRightCoord =     centerCoord.atDistanceAndAzimuth(halfWidthMeters, 90).atDistanceAndAzimuth(halfHeightMeters, 0)
        bottomLeftCoord =   centerCoord.atDistanceAndAzimuth(halfWidthMeters, -90).atDistanceAndAzimuth(halfHeightMeters, 180)
        bottomRightCoord =  centerCoord.atDistanceAndAzimuth(halfWidthMeters, 90).atDistanceAndAzimuth(halfHeightMeters, 180)

        return [ topLeftCoord, topRightCoord, bottomRightCoord, bottomLeftCoord  ]
    }

    /// Reset polygon back to initial default
    function _resetPolygon() {
        console.log("_resetPolygon method")
        mapPolygon.beginReset()
        mapPolygon.clear()
        mapPolygon.appendVertices(defaultPolygonVertices())
        mapPolygon.endReset()
        _circleMode = false
    }

    function _createCircularPolygon(center, radius) {
        console.log("_createCircularPolygon method")
        var unboundCenter = center.atDistanceAndAzimuth(0, 0)
        var segments = 16
        var angleIncrement = 360 / segments
        var angle = 0
        mapPolygon.beginReset()
        mapPolygon.clear()
        _circleRadius = radius
        for (var i=0; i<segments; i++) {
            var vertex = unboundCenter.atDistanceAndAzimuth(radius, angle)
            mapPolygon.appendVertex(vertex)
            angle += angleIncrement
        }
        mapPolygon.endReset()
        _circleMode = true
    }

    /// Reset polygon to a circle which fits within initial polygon
    function _resetCircle() {
        var initialVertices = defaultPolygonVertices()
        var width = initialVertices[0].distanceTo(initialVertices[1])
        var height = initialVertices[1].distanceTo(initialVertices[2])
        var radius = Math.min(width, height) / 2
        var center = initialVertices[0].atDistanceAndAzimuth(width / 2, 90).atDistanceAndAzimuth(height / 2, 180)
        _createCircularPolygon(center, radius)
    }

    function _handleInteractiveChanged() {
        console.log("new_handleInteractiveChanged")
        if (interactive) {
            console.log("new_interactive")
            addEditingVisuals()
            addToolbarVisuals()
        } else {
            console.log("new_interactive_else")
            //mapPolygon.traceMode = false
            removeEditingVisuals()
            removeToolVisuals()
        }
    }

    function appendVertexToPolygon(polygon) {
        console.log("appendVertexToPolygon - Polygon:", polygon)
        if (!polygon) {
            console.log("Cannot append vertex: polygon is undefined")
            return
        }
        
        console.log("Marking mode:", MapGlobals.mark_with)

        if (MapGlobals.mark_with === "Mark_With_GPS") {
            if (gcsPosition.isValid) {
                polygon.appendVertex(gcsPosition)
            } else {
                console.log("GPS position not valid")
            }
        } else if (MapGlobals.mark_with === "Mark_With_Drone") {
            if (activeVehicleCoordinate.isValid) {
                polygon.appendVertex(activeVehicleCoordinate)
            } else {
                console.log("Drone position not valid")
            }
        } else {
            // Manual marking - Use centerViewport to match the visible map center marker
            if (mapControl) {
                var vp = mapControl.centerViewport
                var centerPoint = (vp && vp.width > 0)
                    ? Qt.point(vp.x + vp.width / 2, vp.y + vp.height / 2)
                    : Qt.point(mapControl.width / 2, mapControl.height / 2)
                var centerCoord = mapControl.toCoordinate(centerPoint, false)

                if (centerCoord && centerCoord.isValid) {
                    console.log("Boundary Point: Marking at visible map center:", centerCoord)
                    polygon.appendVertex(centerCoord)
                } else {
                    console.log("Boundary Point: Failed to resolve valid coordinate. vp:", vp, "mapControl:", mapControl)
                }
            } else {
                console.log("Boundary Point: Manual marking failed: mapControl is undefined")
            }
        }
    }

    function restorePreviousVertices() {
        _restorePreviousVertices()
    }

    function _saveCurrentVertices() {
        if (!mapPolygon) return
        _savedVertices = [ ]
        _savedCircleMode = _circleMode
        for (var i=0; i<mapPolygon.count; i++) {
            _savedVertices.push(mapPolygon.vertexCoordinate(i))
        }
    }

    function edit() {
        _planMasterController.edit()
    }

    function _restorePreviousVertices() {
        if (!mapPolygon) return
        mapPolygon.beginReset()
        mapPolygon.clear()
        for (var i=0; i<_savedVertices.length; i++) {
            mapPolygon.appendVertex(_savedVertices[i])
        }
        mapPolygon.endReset()
        _circleMode = _savedCircleMode
    }

    onInteractiveChanged: _handleInteractiveChanged()

    on_CircleModeChanged: {
        if (_circleMode) {
            addCircleVisuals()
        } else {
            _objMgrCircleVisuals.destroyObjects()
        }
    }

    Connections {
        target: mapPolygon || null
        ignoreUnknownSignals: true
        function onTraceModeChanged() {
            if (mapPolygon && mapPolygon.traceMode) {
                _instructionText = _fenceText
                _objMgrTraceVisuals.createObject(traceMouseAreaComponent, mapControl, false)
            } else {
                _instructionText = _polygonToolsText
                _objMgrTraceVisuals.destroyObjects()
            }
        }
    }

    Component.onCompleted: {
        console.log("new_onCompleted")
        addCommonVisuals()
        _handleInteractiveChanged()
    }
    Component.onDestruction: {
        // Do not set property values during destruction as it can trigger signal loops
        // and access partially destroyed objects, leading to crashes.
    }

    QGCDynamicObjectManager { id: _objMgrCommonVisuals }
    QGCDynamicObjectManager { id: _objMgrToolVisuals }
    QGCDynamicObjectManager { id: _objMgrEditingVisuals }
    QGCDynamicObjectManager { id: _objMgrTraceVisuals }
    QGCDynamicObjectManager { id: _objMgrCircleVisuals }

    QGCPalette { id: qgcPal }

    KMLOrSHPFileDialog {
        id:             kmlOrSHPLoadDialog
        title:          qsTr("Select Polygon File")

        onAcceptedForLoad: (file) => {
                               mapPolygon.loadKMLOrSHPFile(file)
                               mapFitFunctions.fitMapViewportToMissionItems()
                               close()
                           }
    }

    // QGCMenu {
    //     id: menu

    //     property int _editingVertexIndex: -1

    //     function popupVertex(curIndex) {
    //         menu._editingVertexIndex = curIndex
    //         removeVertexItem.visible = (mapPolygon.count > 0 && menu._editingVertexIndex >= 0)
    //         menu.popup()
    //     }

    //     function popupCenter() {
    //         menu.popup()
    //     }

    //     QGCMenuItem {
    //         id:             removeVertexItem
    //         visible:        !_circleMode
    //         text:           qsTr("Remove vertex")
    //         onTriggered: {
    //             if (menu._editingVertexIndex >= 0) {
    //                 mapPolygon.removeVertex(menu._editingVertexIndex)
    //             }
    //         }
    //     }

    //     QGCMenuSeparator {
    //         visible:        removeVertexItem.visible
    //     }

    //     QGCMenuItem {
    //         text:           qsTr("Set radius..." )
    //         visible:        _circleMode
    //         onTriggered:    _editCircleRadius = true
    //     }

    //     QGCMenuItem {
    //         text:           qsTr("Edit position..." )
    //         visible:        _circleMode
    //         onTriggered:    editCenterPositionDialog.createObject(mainWindow).open()
    //     }

    //     QGCMenuItem {
    //         text:           qsTr("Edit position..." )
    //         visible:        !_circleMode && menu._editingVertexIndex >= 0
    //         onTriggered:    editVertexPositionDialog.createObject(mainWindow).open()
    //     }

    //     QGCMenuItem {
    //         text:           qsTr("Adjust with arrows")
    //         visible:        !_circleMode
    //         onTriggered:    {
    //             _root.selectedVertexIndex = menu._editingVertexIndex
    //             //arrowDrawer.open()
    //         }
    //     }
    // }

    MouseArea {
        id: dismissOverlay
        // Cover the full map area. _root has no size so we bind to mapControl's dimensions.
        x:      0
        y:      0
        width:  mapControl ? mapControl.width : 0
        height: mapControl ? mapControl.height : 0
        z:              vertexMenu.z - 1
        visible:        vertexMenu.visible && mapControl
        preventStealing: true
        onClicked:      vertexMenu.closeMenu()
    }

    // Custom animated context menu popup
    Rectangle {
        id: vertexMenu
        visible: false
        x: 30
        y: 60
        z: 1000
        radius: 8
        color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.75)
        border.color: qgcPal.text
        border.width: 1
        opacity: 0

        width:  menuColumn.implicitWidth  + 28
        height: menuColumn.implicitHeight + 8

        // Drop shadow effect
        layer.enabled: true
        layer.effect: null

        property int _editingVertexIndex: -1
        property bool _showRemove: false

        function popupVertex(curIndex) {
            vertexMenu._editingVertexIndex = curIndex
            vertexMenu._showRemove = (mapPolygon.count > 3 && curIndex >= 0)

            var coordinate = mapPolygon.vertexCoordinate(curIndex)
            if (coordinate && coordinate.isValid) {
                var point = mapControl.fromCoordinate(coordinate, false)
                var centerPoint = mapControl.fromCoordinate(mapPolygon.center, false)
                var menuX = (point.x < centerPoint.x) ? (point.x - vertexMenu.width - 20) : (point.x + 20)
                var menuY = (point.y < centerPoint.y) ? (point.y - vertexMenu.height - 20) : (point.y + 20)
                vertexMenu.x = Math.max(10, Math.min(menuX, mapControl.width - vertexMenu.width - 10))
                vertexMenu.y = Math.max(10, Math.min(menuY, mapControl.height - vertexMenu.height - 10))
            } else {
                vertexMenu.x = 30
                vertexMenu.y = 60
            }

            openAnimation.start()
        }

        function popupCenter() {
            vertexMenu._editingVertexIndex = -1
            vertexMenu._showRemove = false

            var coordinate = mapPolygon.center
            if (coordinate && coordinate.isValid) {
                var point = mapControl.fromCoordinate(coordinate, false)
                var menuX = point.x + 20
                var menuY = point.y - (vertexMenu.height / 2)
                vertexMenu.x = Math.max(10, Math.min(menuX, mapControl.width - vertexMenu.width - 10))
                vertexMenu.y = Math.max(10, Math.min(menuY, mapControl.height - vertexMenu.height - 10))
            } else {
                vertexMenu.x = 30
                vertexMenu.y = 60
            }

            openAnimation.start()
        }

        function closeMenu() {
            closeAnimation.start()
        }

        // Fade in animation
        NumberAnimation {
            id: openAnimation
            target: vertexMenu
            property: "opacity"
            from: 0
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
            onStarted: {
                vertexMenu.visible = true
            }
        }

        // Fade out animation
        NumberAnimation {
            id: closeAnimation
            target: vertexMenu
            property: "opacity"
            from: 1
            to: 0
            duration: 200
            easing.type: Easing.InCubic
            onFinished: {
                vertexMenu.visible = false
            }
        }

        Column {
            id: menuColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 2
            }
            spacing: 0

            // Remove vertex
            Rectangle {
                visible:        vertexMenu._showRemove
                implicitWidth:  removeRow.implicitWidth  + 28
                implicitHeight: removeRow.implicitHeight + 20
                color:          "transparent"//removeMouseArea.containsMouse ? app_color : "transparent"
                radius:         8

                Behavior on color {

                    ColorAnimation {
                        duration: 120
                    }
                }

                Row {

                    id: removeRow
                    anchors.centerIn: parent
                    spacing: 10

                    // Trash icon
                    QGCColoredImage {
                        width:              ScreenTools.defaultFontPixelHeight
                        height:             ScreenTools.defaultFontPixelHeight
                        anchors.verticalCenter: parent.verticalCenter
                        sourceSize.height:  height
                        source:             "/res/TrashDelete.svg"
                        fillMode:           Image.PreserveAspectFit
                        mipmap:             true
                        smooth:             true
                        color:              qgcPal.text
                    }

                    Text {
                        text:               qsTr("Delete")
                        color:              qgcPal.text
                        font.pointSize:     ScreenTools.defaultFontPointSize
                        font.weight:        Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: removeMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (vertexMenu._editingVertexIndex >= 0) {
                            mapPolygon.removeVertex(vertexMenu._editingVertexIndex)
                        }
                        vertexMenu.closeMenu()
                    }
                }
            }

            // Divider
            Rectangle {
                visible: vertexMenu._showRemove
                width:  menuColumn.implicitWidth
                height: 1
                color: qgcPal.text
                opacity: 0.2
                //anchors.horizontalCenter: parent.horizontalCenter
            }

            // "Edit position..." item
            Rectangle {
                id: editBtn
                visible: !_circleMode && vertexMenu._editingVertexIndex >= 0
                implicitWidth:  editRow.implicitWidth  + 28
                implicitHeight: editRow.implicitHeight + 20
                color:  "transparent"//editMouseArea.containsMouse ? app_color  : "transparent"
                radius: 8

                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: editRow
                    anchors.centerIn: parent
                    spacing: 10

                    QGCColoredImage {
                        width:              ScreenTools.defaultFontPixelHeight * 0.9
                        height:             ScreenTools.defaultFontPixelHeight * 0.9
                        anchors.verticalCenter: parent.verticalCenter
                        sourceSize.height:  height
                        source:             "qrc:/InstrumentValueIcons/edit-pencil.svg"
                        fillMode:           Image.PreserveAspectFit
                        mipmap:             true
                        smooth:             true
                        color:              qgcPal.text
                    }

                    Text {
                        text: qsTr("Edit")
                        color: qgcPal.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: editMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        vertexMenu.closeMenu()
                        editVertexPositionDialog.createObject(mainWindow).open()
                    }
                }
            }
        }

    }

    PlanMasterController {
        id:         planMasterController
        flyView:    false

        Component.onCompleted: {
            console.log("QgcMapPolygon PlanMasterController .onCompleted")
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


        function edit() {
            console.log("saved edit plan")
            _saveCurrentVertices()
            _circleMode = false
            mapPolygon.traceMode = true
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

        function saveToSelectedFile1() {
            if (!checkReadyForSaveUpload(true /* save */)) {
                return
            }
            fileDialog.title =          qsTr("Save Plan")
            fileDialog.planFiles =      true
            fileDialog.nameFilters =    _planMasterController.saveNameFilters
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

    Component {
        id: polygonComponent

        MapPolygon {
            z:              QGroundControl.zOrderMapItems + 5
            color:          (mapPolygon && mapPolygon.showAltColor) ? altColor : interiorColor
            opacity:        interiorOpacity
            border.color:   borderColor
            border.width:   borderWidth
            path:           mapPolygon ? mapPolygon.path : []

            // Modern subtle pulsing fill effect for an active mission coverage area
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: interactive && (interiorOpacity > 0)
                NumberAnimation { to: Math.max(0.05, interiorOpacity * 0.4); duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: interiorOpacity; duration: 1800; easing.type: Easing.InOutSine }
            }

            // Glow ring expansion on the border
            SequentialAnimation on border.width {
                loops: Animation.Infinite
                running: interactive && (borderWidth > 0)
                NumberAnimation { to: borderWidth + 2; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { to: borderWidth; duration: 1800; easing.type: Easing.InOutSine }
            }
        }
    }

    Component {
        id: edgeLengthHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  sourceItem.width / 2
            anchorPoint.y:  sourceItem.height / 2
            visible:        !_circleMode

            property int vertexIndex
            property real distance

            property var _unitsConversion: QGroundControl.unitsConversion

            sourceItem: Rectangle {
                id: textContainer
                height: displayText.contentHeight + 6 // Padding
                width: displayText.contentWidth + 12 // Padding
                radius: height / 2 // Rounded corners
                color: Qt.rgba(0, 0, 0, 0.40) // transparent black background
                border.color: "transparent"
                border.width: 0

                Text {
                    id: displayText
                    anchors.centerIn: parent
                    text: _unitsConversion.metersToAppSettingsHorizontalDistanceUnits(distance).toFixed(1) + " " +
                          _unitsConversion.appSettingsHorizontalDistanceUnitsString
                    color: "white"
                    font.pixelSize: 8
                }
            }
        }
    }

    Component {
        id: edgeLengthHandlesComponent

        Repeater {
            model: _isVertexBeingDragged ? mapPolygon.path : undefined

            delegate: Item {
                property var _edgeLengthHandle
                property var _vertices:     mapPolygon.path

                function _setHandlePosition() {
                    var nextIndex = index + 1
                    if (nextIndex > _vertices.length - 1) {
                        nextIndex = 0
                    }
                    var distance = _vertices[index].distanceTo(_vertices[nextIndex])
                    var azimuth = _vertices[index].azimuthTo(_vertices[nextIndex])
                    _edgeLengthHandle.coordinate =_vertices[index].atDistanceAndAzimuth(distance / 3, azimuth)
                    _edgeLengthHandle.distance = distance
                }

                Component.onCompleted: {
                    _edgeLengthHandle = edgeLengthHandleComponent.createObject(mapControl)
                    _edgeLengthHandle.vertexIndex = index
                    _setHandlePosition()
                    mapControl.addMapItem(_edgeLengthHandle)
                }

                Component.onDestruction: {
                    if (_edgeLengthHandle) {
                        _edgeLengthHandle.destroy()
                    }
                }
            }
        }
    }

    Component {
        id: splitHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  sourceItem.width / 2
            anchorPoint.y:  sourceItem.height / 2
            visible:        !_circleMode

            property int vertexIndex

            sourceItem: SplitIndicator {
                z:          _zorderSplitHandle
                onClicked:  if(_root.interactive) mapPolygon.splitPolygonSegment(mapQuickItem.vertexIndex)
            }
        }
    }

    Component {
        id: splitHandlesComponent

        Repeater {
            model: mapPolygon.path

            delegate: Item {
                property var _splitHandle
                property var _vertices:     mapPolygon.path

                function _setHandlePosition() {
                    var nextIndex = index + 1
                    if (nextIndex > _vertices.length - 1) {
                        nextIndex = 0
                    }
                    var distance = _vertices[index].distanceTo(_vertices[nextIndex])
                    var azimuth = _vertices[index].azimuthTo(_vertices[nextIndex])
                    _splitHandle.coordinate = _vertices[index].atDistanceAndAzimuth(distance / 2, azimuth)
                }

                Component.onCompleted: {
                    _splitHandle = splitHandleComponent.createObject(mapControl)
                    _splitHandle.vertexIndex = index
                    _setHandlePosition()
                    mapControl.addMapItem(_splitHandle)
                }

                Component.onDestruction: {
                    if (_splitHandle) {
                        _splitHandle.destroy()
                    }
                }
            }
        }
    }

    // Control which is used to drag polygon vertices
    Component {
        id: dragAreaComponent

        MissionItemIndicatorDrag {
            id:             dragArea
            mapControl:     _root.mapControl
            z:              _zorderDragHandle
            visible:        !_circleMode
            onDragStart:    _isVertexBeingDragged = true
            onDragStop:     { _isVertexBeingDragged = true; mapPolygon.verifyClockwiseWinding() }

            property int polygonVertex

            property bool _creationComplete: false

            Component.onCompleted: _creationComplete = true

            onItemCoordinateChanged: {
                if (_creationComplete) {
                    // During component creation some bad coordinate values got through which screws up draw
                    mapPolygon.adjustVertex(polygonVertex, itemCoordinate)
                }
            }
            onClicked: {
                console.log("Click the Point:", polygonVertex)
                if(_root.interactive) vertexMenu.popupVertex(polygonVertex)
            }
        }
    }


    Component {
        id: centerDragHandle
        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  dragHandle.width  * 0.5
            anchorPoint.y:  dragHandle.height * 0.5
            z:              _zorderDragHandle
            sourceItem: Rectangle {
                id:             dragHandle
                width:          ScreenTools.defaultFontPixelHeight * 1.5
                height:         width
                radius:         width * 0.5
                color:          Qt.rgba(1,1,1,0.8)
                border.color:   Qt.rgba(0,0,0,0.25)
                border.width:   1
                QGCColoredImage {
                    width:      parent.width
                    height:     width
                    color:      Qt.rgba(0,0,0,1)
                    mipmap:     true
                    fillMode:   Image.PreserveAspectFit
                    source:     "/qmlimages/MapCenter.svg"
                    sourceSize.height:  height
                    anchors.centerIn:   parent
                }
            }
        }
    }

    // Component {
    //     id: dragHandleComponent

    //     MapQuickItem {
    //         id:             mapQuickItem
    //         anchorPoint.x:  dragHandle.width  / 2
    //         anchorPoint.y:  dragHandle.height / 2
    //         z:              _zorderDragHandle
    //         visible:        !_circleMode

    //         property int polygonVertex

    //         sourceItem: Rectangle {
    //             id:             dragHandle
    //             width:          ScreenTools.defaultFontPixelHeight * 1.5
    //             height:         width
    //             radius:         width * 0.5
    //             color:          Qt.rgba(1,1,1,0.8)
    //             border.color:   Qt.rgba(0,0,0,0.25)
    //             border.width:   1
    //         }
    //     }
    // }


    Component {
        id: dragHandleComponent

        MapQuickItem {
            id: mapQuickItem
            anchorPoint.x: dragHandle.width / 2
            anchorPoint.y: dragHandle.height / 2
            z:  QGroundControl.zOrderMapItems + 3
            visible: !_circleMode
            objectName: "markerItem"

            // Index or label for the marker
            property int markerIndex: 0

            // Add this property so polygonVertex can be assigned:
            property int polygonVertex: -1


            // 1) Define a signal for when this marker is clicked
            signal markerClicked(var clickedMarker)

            // Show a small circle with the marker number inside
            sourceItem: Rectangle {
                id: dragHandle
                width: ScreenTools.defaultFontPixelHeight * 1.5
                height: width
                radius: width / 2
                color: "#fcfcfc"  // 1% darker than white
                border.color: "black"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: (polygonVertex + 1)
                    color: "black"
                    font.bold: true
                    font.pixelSize: 10
                    // Hide index number when grid is ON; circle itself stays visible
                    opacity: MapGlobals.gridLines ? 0 : 1
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }
                }

                // Use a MouseArea here to handle clicks
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // // Save the clicked marker in the main view and open the drawer
                        //  _root.selectedVertexIndex = mapQuickItem
                        // arrowDrawer.open()
                        // // Emit the markerClicked signal if further handling is needed
                        // mapQuickItem.markerClicked(mapQuickItem)
                        vertexMenu.popupVertex(polygonVertex)
                    }
                }
            }
        }
    }



    // Add all polygon vertex drag handles to the map
    Component {
        id: dragHandlesComponent

        Repeater {
            model: mapPolygon ? mapPolygon.pathModel : null

            delegate: Item {
                property var _visuals: [ ]

                Component.onCompleted: {
                    var dragHandle = dragHandleComponent.createObject(mapControl)
                    dragHandle.coordinate = Qt.binding(function() { return object.coordinate })
                    dragHandle.markerIndex = index + 1  // Assign numbers 1,2,3,4 based on index
                    dragHandle.polygonVertex = Qt.binding(function() { return index })
                    mapControl.addMapItem(dragHandle)

                    //Connect the markerClicked signal to a function in this scope
                    dragHandle.markerClicked.connect(function(clickedMarker) {
                        // This code runs when the user clicks the marker
                        _root.selectedVertexIndex = clickedMarker
                        //arrowDrawer.open()
                    })

                    var dragArea = dragAreaComponent.createObject(mapControl, { "itemIndicator": dragHandle, "itemCoordinate": object.coordinate })
                    dragArea.polygonVertex = Qt.binding(function() { return index })
                    _visuals.push(dragHandle)
                    _visuals.push(dragArea)
                }

                Component.onDestruction: {
                    for (var i=0; i<_visuals.length; i++) {
                        _visuals[i].destroy()
                    }
                    _visuals = [ ]
                }
            }
        }
    }

    Component {
        id: editCenterPositionDialog

        EditPositionDialog {
            title:      qsTr("Edit Center Position")
            coordinate: mapPolygon ? mapPolygon.center : QtPositioning.coordinate()
            onCoordinateChanged: {
                if (mapPolygon) {
                    mapPolygon.centerDrag = true
                    mapPolygon.center = coordinate
                    mapPolygon.centerDrag = false
                }
            }
        }
    }

    Component {
        id: editVertexPositionDialog

        EditPositionDialog {
            title:      qsTr("Edit Boundary Point")
            coordinate: mapPolygon.vertexCoordinate(vertexMenu._editingVertexIndex)
            onCoordinateChanged: {
                mapPolygon.adjustVertex(vertexMenu._editingVertexIndex, coordinate)
                mapPolygon.verifyClockwiseWinding()
            }
        }
    }

    Component {
        id: centerDragAreaComponent

        MissionItemIndicatorDrag {
            mapControl:                 _root.mapControl
            z:                          _zorderCenterHandle
            onItemCoordinateChanged:    mapPolygon.center = itemCoordinate
            onDragStart:                mapPolygon.centerDrag = true
            onDragStop:                 mapPolygon.centerDrag = false
        }
    }

    Component {
        id: centerDragHandleComponent

        Item {
            property var dragHandle
            property var dragArea

            Component.onCompleted: {
                dragHandle = centerDragHandle.createObject(mapControl)
                dragHandle.coordinate = Qt.binding(function() { return mapPolygon.center })
                mapControl.addMapItem(dragHandle)
                dragArea = centerDragAreaComponent.createObject(mapControl, { "itemIndicator": dragHandle, "itemCoordinate": mapPolygon.center })
            }

            Component.onDestruction: {
                dragHandle.destroy()
                dragArea.destroy()
            }
        }
    }

    // Component {
    //     id: toolbarComponent

    //     PlanEditToolbar {
    //         anchors.horizontalCenter:       mapControl.left
    //         anchors.horizontalCenterOffset: mapControl.centerViewport.left + (mapControl.centerViewport.width / 2)
    //         y:                              mapControl.centerViewport.top
    //         availableWidth:                 mapControl.centerViewport.width

    //         QGCButton {
    //             _horizontalPadding: 0
    //             text:               qsTr("Basic")
    //             visible:            !mapPolygon.traceMode
    //             onClicked:          _resetPolygon()
    //         }

    //         QGCButton {
    //             _horizontalPadding: 0
    //             text:               qsTr("Circular")
    //             visible:            !mapPolygon.traceMode
    //             onClicked:          _resetCircle()
    //         }

    //         QGCButton {
    //             _horizontalPadding: 0
    //             text:               mapPolygon.traceMode ? qsTr("Done Tracing") : qsTr("Trace")
    //             onClicked: {
    //                 if (mapPolygon.traceMode) {
    //                     if (mapPolygon.count < 3) {
    //                         _restorePreviousVertices()
    //                     }
    //                     mapPolygon.traceMode = false

    //                 } else {
    //                      mobileFileSaveDialogComponent.createObject(mainWindow).open()

    //                 }
    //             }
    //         }

    //         QGCButton {
    //             _horizontalPadding: 0
    //             text:               qsTr("Load KML/SHP...")
    //             onClicked:          kmlOrSHPLoadDialog.openForLoad()
    //             visible:            !mapPolygon.traceMode
    //         }
    //     }
    // }


    Component {
        id: toolbarComponent

        Item {
            // This item is parented to mapControl, so x/y are in mapControl coordinates
            width: mapControl.width
            height: mapControl.height

            Component.onCompleted: {
                if (MapGlobals.mark_with === "KML_File" && MapGlobals.kmlPath !== "") {
                    console.log("Loading external KML from local storage:", MapGlobals.kmlPath)
                    mapPolygon.loadKMLOrSHPFile(MapGlobals.kmlPath)
                    mapFitFunctions.fitMapViewportToMissionItems()
                }
            }

            // Viewport-based toolbar (hidden)
            Item {
                id: toolbarRoot
                x: mapControl.centerViewport.x
                y: mapControl.centerViewport.y
                width: mapControl.centerViewport.width
                height: mapControl.centerViewport.height

                PlanEditToolbar {
                    id: toolbar
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    availableWidth: parent.width
                    visible: false
                }

                Image {
                    id: controlImage
                    source: "/qmlimages/NewImages/location.png"
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    visible: (mapPolygon ? mapPolygon.traceMode : false) && MapGlobals.mark_with === "Mark_With_Manual" || mapping
                }
            }

            // Buttons positioned directly below the compass icon
            // cardinalLeftScreenX and cardinalBottomScreenY are in mapControl (panel) space

            //only for


            // Click-outside-to-dismiss overlay — sibling of vertexMenu, fills the whole mapControl area
            MouseArea {
                anchors.fill: parent
                z:            vertexMenu.z - 1
                visible:      vertexMenu.visible
                onClicked:    vertexMenu.closeMenu()
            }

            Rectangle {
                id: vertexMenu
                visible: false
                x: 30
                y: 60
                z: 1000
                radius: 8
                color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.75)
                border.color: qgcPal.text
                border.width: 1
                opacity: 0

                width:  menuColumn.implicitWidth  + 28
                height: menuColumn.implicitHeight + 8

                layer.enabled: true
                layer.effect: null

                property int _editingVertexIndex: -1
                property bool _showRemove: false

                function popupVertex(curIndex) {
                    vertexMenu._editingVertexIndex = curIndex
                    vertexMenu._showRemove = (mapPolygon.count > 3 && curIndex >= 0)

                    var coordinate = mapPolygon.vertexCoordinate(curIndex)
                    if (coordinate && coordinate.isValid) {
                        var point = mapControl.fromCoordinate(coordinate, false)
                        var centerPoint = mapControl.fromCoordinate(mapPolygon.center, false)
                        var menuX = (point.x < centerPoint.x) ? (point.x - vertexMenu.width - 20) : (point.x + 20)
                        var menuY = (point.y < centerPoint.y) ? (point.y - vertexMenu.height - 20) : (point.y + 20)
                        vertexMenu.x = Math.max(10, Math.min(menuX, mapControl.width - vertexMenu.width - 10))
                        vertexMenu.y = Math.max(10, Math.min(menuY, mapControl.height - vertexMenu.height - 10))
                    } else {
                        vertexMenu.x = 30
                        vertexMenu.y = 60
                    }

                    openAnimation.start()
                }

                function popupCenter() {
                    vertexMenu._editingVertexIndex = -1
                    vertexMenu._showRemove = false

                    var coordinate = mapPolygon.center
                    if (coordinate && coordinate.isValid) {
                        var point = mapControl.fromCoordinate(coordinate, false)
                        var menuX = point.x + 20
                        var menuY = point.y - (vertexMenu.height / 2)
                        vertexMenu.x = Math.max(10, Math.min(menuX, mapControl.width - vertexMenu.width - 10))
                        vertexMenu.y = Math.max(10, Math.min(menuY, mapControl.height - vertexMenu.height - 10))
                    } else {
                        vertexMenu.x = 30
                        vertexMenu.y = 60
                    }

                    openAnimation.start()
                }

                function closeMenu() {
                    closeAnimation.start()
                }

                // Fade in animation
                NumberAnimation {
                    id: openAnimation
                    target: vertexMenu
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                    onStarted: {
                        vertexMenu.visible = true
                    }
                }

                // Fade out animation
                NumberAnimation {
                    id: closeAnimation
                    target: vertexMenu
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 200
                    easing.type: Easing.InCubic
                    onFinished: {
                        vertexMenu.visible = false
                    }
                }

                Column {
                    id: menuColumn
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: 2
                    }
                    spacing: 0

                    // Remove vertex
                    Rectangle {
                        visible:        vertexMenu._showRemove
                        implicitWidth:  removeRow.implicitWidth  + 28
                        implicitHeight: removeRow.implicitHeight + 20
                        color:          "transparent"
                        radius:         8

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        Row {
                            id: removeRow
                            anchors.centerIn: parent
                            spacing: 10

                            QGCColoredImage {
                                width:              ScreenTools.defaultFontPixelHeight
                                height:             ScreenTools.defaultFontPixelHeight
                                anchors.verticalCenter: parent.verticalCenter
                                sourceSize.height:  height
                                source:             "/res/TrashDelete.svg"
                                fillMode:           Image.PreserveAspectFit
                                mipmap:             true
                                smooth:             true
                                color:              qgcPal.text
                            }

                            Text {
                                text:               qsTr("Delete")
                                color:              qgcPal.text
                                font.pointSize:     ScreenTools.defaultFontPointSize
                                font.weight:        Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: removeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (vertexMenu._editingVertexIndex >= 0) {
                                    mapPolygon.removeVertex(vertexMenu._editingVertexIndex)
                                }
                                vertexMenu.closeMenu()
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        visible: vertexMenu._showRemove
                        width:  menuColumn.implicitWidth
                        height: 1
                        color: qgcPal.text
                        opacity: 0.2
                    }

                    // "Edit position..." item
                    Rectangle {
                        id: editBtn
                        visible: !_circleMode && vertexMenu._editingVertexIndex >= 0
                        implicitWidth:  editRow.implicitWidth  + 28
                        implicitHeight: editRow.implicitHeight + 20
                        color:  "transparent"
                        radius: 8

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            id: editRow
                            anchors.centerIn: parent
                            spacing: 10



                            QGCColoredImage {
                                width:              ScreenTools.defaultFontPixelHeight * 0.9
                                height:             ScreenTools.defaultFontPixelHeight * 0.9
                                anchors.verticalCenter: parent.verticalCenter
                                sourceSize.height:  height
                                source:             "qrc:/InstrumentValueIcons/edit-pencil.svg"
                                fillMode:           Image.PreserveAspectFit
                                mipmap:             true
                                smooth:             true
                                color:              qgcPal.text
                            }

                            Text {
                                text: qsTr("Edit")
                                color: qgcPal.text
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: editMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                vertexMenu.closeMenu()
                                editVertexPositionDialog.createObject(mainWindow).open()
                            }
                        }
                    }
                }
            } // vertexMenu
        }

    }

    // Function to move the selected marker by dx/dy meters
    function moveSelectedMarker(dxMeters, dyMeters) {
        if (!mapPolygon) return
        if (_root.selectedVertexIndex === -1 ||
                _root.selectedVertexIndex >= mapPolygon.count) return

        var vertex = mapPolygon.pathModel.get(_root.selectedVertexIndex)
        if (!vertex) return

        var coord = vertex.coordinate
        var earthRadius = 6378137.0  // WGS-84

        // Convert meter deltas to degrees
        var newLat = coord.latitude + (dyMeters / earthRadius) * (180/Math.PI)
        var newLon = coord.longitude + (dxMeters / (earthRadius * Math.cos(coord.latitude * Math.PI/180))) * (180/Math.PI)

        if (mapPolygon) {
            mapPolygon.adjustVertex(_root.selectedVertexIndex, QtPositioning.coordinate(newLat, newLon))
        }
    }


    // // Mouse area to capture clicks for tracing a polygon
    // Component {
    //     id:  traceMouseAreaComponent

    //     MouseArea {
    //         anchors.fill:       mapControl
    //         preventStealing:    true
    //         z:                  QGroundControl.zOrderMapItems + 1   // Over item indicators

    //         onClicked: (mouse) => {

    //             if(_utmspEnabled){

    //                 if (mouse.button === Qt.LeftButton) {
    //                     mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */))
    //                 }
    //             }
    //             else{
    //                 if (mouse.button === Qt.LeftButton && _root.interactive) {
    //                     mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */))
    //                 }
    //             }
    //         }
    //     }
    // }

    Component {
        id: mobileFileSaveDialogComponent

        QGCPopupDialog {
            id:         mobileFileSaveDialog
            title:      _root.title
            //buttons:    Dialog.Cancel | Dialog.Ok

            onAccepted: {
                if (filenameTextField.text.length < 3 || filenameTextField1.text.length < 3 || filenameTextField2.text.length < 3) {
                    mobileFileSaveDialog.preventClose = true
                    return
                }

                let concatenatedText = filenameTextField.text.substring(0, 3) +
                    filenameTextField1.text.substring(0, 3) +
                    filenameTextField2.text.substring(0, 3);

                _appSettings.username = concatenatedText;
                console.log(concatenatedText);
                console.log("confirm action");

                MapGlobals.setGridLines(false)

                _saveCurrentVertices()

                _circleMode = false
                if (mapPolygon) {
                    mapPolygon.traceMode = true
                    mapPolygon.clear();
                }
            }

            onRejected: mainWindow.showFlyView()

            Rectangle {
                width: 400
                height: 300
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    radius: 10
                    color: "#ffffffcc" // semi-transparent white
                    border.color: app_color
                    border.width: 2

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        // Header
                        Rectangle {
                            width: parent.width + 40
                            height: 50
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: app_color
                            radius: 10
                            // Rounded top only
                            Rectangle {
                                anchors.bottom: parent.bottom
                                height: 10
                                width: parent.width
                                color: parent.color
                            }

                            Label {
                                text: qsTr("Set Ground Name")
                                font.bold: true
                                color: "white"
                                font.pointSize: 14
                                anchors.centerIn: parent
                                font.family: "Outfit"
                            }
                        }

                        // Name Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Label { text: qsTr("Name :"); Layout.preferredWidth: 80; color: "black"; font.bold: true }
                            TextField {
                                id: filenameTextField
                                Layout.fillWidth: true
                                color: "black"
                                background: Rectangle {
                                    radius: 8
                                    color: "white"
                                    border.color: filenameTextField.activeFocus ? app_color : "#DDE1EA"
                                    border.width: 1
                                }
                            }
                        }

                        // Phone Number Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Label { text: qsTr("Ph No:"); Layout.preferredWidth: 80; color: "black"; font.bold: true }
                            TextField {
                                id: filenameTextField1
                                Layout.fillWidth: true
                                color: "black"
                                validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,10}$/ }
                                inputMethodHints: Qt.ImhDigitsOnly
                                background: Rectangle {
                                    radius: 8
                                    color: "white"
                                    border.color: filenameTextField1.activeFocus ? app_color : "#DDE1EA"
                                    border.width: 1
                                }
                            }
                        }

                        // Ground Name Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Label { text: qsTr("Ground Name:"); Layout.preferredWidth: 80; color: "black"; font.bold: true }
                            TextField {
                                id: filenameTextField2
                                Layout.fillWidth: true
                                color: "black"
                                background: Rectangle {
                                    radius: 8
                                    color: "white"
                                    border.color: filenameTextField2.activeFocus ? app_color : "#DDE1EA"
                                    border.width: 1
                                }
                            }
                        }

                        // Buttons
                        Row {
                            spacing: 30
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                id: cancelBtnMobile
                                text: qsTr("Cancel")
                                width: 100
                                background: Rectangle {
                                    radius: 12
                                    color: cancelBtnMobile.pressed ? "#C0392B" : (cancelBtnMobile.hovered ? "#E74C3C" : "#E74C3C")
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: mobileFileSaveDialog.onRejected()
                            }

                            Button {
                                id: confirmBtnMobile
                                text: qsTr("Confirm")
                                width: 100
                                background: Rectangle {
                                    radius: 12
                                    color: confirmBtnMobile.pressed ? Qt.darker(app_color, 1.2) : (confirmBtnMobile.hovered ? Qt.lighter(app_color, 1.2) : app_color)
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: mobileFileSaveDialog.accepted()
                            }
                        }
                    }
                }
            }
        }

    }

    Component {
        id: radiusDragHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  dragHandle.width / 2
            anchorPoint.y:  dragHandle.height / 2
            z:              QGroundControl.zOrderMapItems + 2

            sourceItem: Rectangle {
                id:         dragHandle
                width:      ScreenTools.defaultFontPixelHeight * 1.5
                height:     width
                radius:     width / 2
                color:      "black"
                opacity:    interiorOpacity * .90
            }
        }
    }

    Component {
        id: customdialog

        Dialog {
            id:             customDialog
            modal:          true
            dim:            true
            closePolicy:    Popup.NoAutoClose
            anchors.centerIn: parent
            width:          ScreenTools.defaultFontPixelWidth * 38
            height:         ScreenTools.defaultFontPixelHeight * 11
            padding:        0

            background: Rectangle {
                radius: 20
                color: "white"
                border.width: 0
            }

            contentItem: ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.28
                    color: app_color
                    radius: 20
                    // Top rounded corners only
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.radius
                        color: parent.color
                    }

                    Text {
                        text:               qsTr("Set Ground Name")
                        font.bold:          true
                        color:              "white"
                        font.pointSize:     14
                        anchors.centerIn:    parent
                        font.family:        "Outfit"
                    }
                }

                // Separator 1
                Rectangle {
                    Layout.fillWidth: true
                    height:             1
                    color:              "white"
                    opacity:            0.15
                }

                // Content Area
                Item {
                    Layout.fillWidth:   true
                    Layout.fillHeight:  true
                    RowLayout {
                        anchors {
                            left:           parent.left
                            right:          parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin:     25
                            rightMargin:    25
                        }
                        spacing:          15

                        Text {
                            text:           qsTr("Project Name:")
                            color:          "black"
                            font.bold:      true
                            font.pointSize: 11
                        }

                        TextField {
                            id:             nameField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            placeholderText: qsTr("Enter your project name")
                            placeholderTextColor: "#888888"
                            font.pointSize: 11
                            color:          "black"
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding:    15
                            background: Rectangle {
                                radius:         10
                                color:          "#FFFFFF"
                                border.color:   nameField.activeFocus ? "#262626" : "#DDE1EA"
                                border.width:   nameField.activeFocus ? 2 : 1
                            }
                        }
                    }
                }

                // Separator 2
                Rectangle {
                    Layout.fillWidth: true
                    height:             1
                    color:              "white"
                    opacity:            0.15
                }

                // Buttons Area
                Item {
                    Layout.fillWidth:   true
                    Layout.preferredHeight: parent.height * 0.32
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Cancel Column
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Button {
                                id:             cancelBtn
                                anchors.centerIn: parent
                                width: 125
                                height: 36
                                onClicked: {
                                    QGroundControl.saveGlobalSetting("load", "load")

                                    customDialog.close()
                                    if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                                        mainWindow.showFlyView()
                                    } else if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
                                        mainWindow.showMapping()
                                    }
                                    MapGlobals.editdialog = "editdialog1"
                                }
                                background: Rectangle {
                                    radius:     12
                                    color:      cancelBtn.pressed ? "#C0392B" : (cancelBtn.hovered ? "#E74C3C" : "#E74C3C")
                                    border.width: 0
                                }
                                contentItem: Text {
                                    text:               qsTr("Cancel")
                                    color:              "white"
                                    font.bold:          true
                                    font.pointSize:     12
                                    font.family:        "Outfit"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment:   Text.AlignVCenter
                                }
                            }
                        }

                        // Vertical Separator
                        Rectangle {
                            Layout.fillHeight: true
                            width: 1
                            color: "white"
                            opacity: 0.15
                            Layout.topMargin: 10
                            Layout.bottomMargin: 10
                        }

                        // Confirm Column
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Button {
                                id:             confirmBtn
                                anchors.centerIn: parent
                                width: 125
                                height: 36
                                onClicked: {
                                    QGroundControl.saveGlobalSetting("load", "load1")

                                    if (nameField.text.length < 3) {
                                        mainWindow.showToastMessage(qsTr("Please enter a valid project name"))
                                        return
                                    }

                                    MapGlobals.setGridLines(false)

                                    let concatenatedText = nameField.text.substring(0, 10)
                                    _appSettings.username = concatenatedText

                                    if (QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri") {
                                        _saveCurrentVertices()
                                        _circleMode = false
                                        mapPolygon.traceMode = true
                                        if(MapGlobals.mark_with !== "KML_File") {
                                            mapPolygon.clear()
                                        }
                                    } else if (QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Mapping") {
                                        mapping = true
                                        if(QGroundControl.loadGlobalSetting("mapping", "mapping") === "basic") {
                                            _resetPolygon()
                                        } else if(QGroundControl.loadGlobalSetting("mapping", "mapping") === "circle") {
                                            _resetCircle()
                                        }
                                    }

                                    customDialog.close()
                                    MapGlobals.editdialog = "editdialog1"
                                }
                                background: Rectangle {
                                    radius:     12
                                    color:      confirmBtn.pressed ? Qt.darker(app_color, 1.2) : (confirmBtn.hovered ? Qt.lighter(app_color, 1.1) : app_color)
                                    border.width: 0
                                }
                                contentItem: Text {
                                    text:               qsTr("Confirm")
                                    color:              "white"
                                    font.bold:          true
                                    font.pointSize:     12
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment:   Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    Component {
        id: radiusDragAreaComponent

        MissionItemIndicatorDrag {
            mapControl: _root.mapControl

            property real _lastRadius

            onItemCoordinateChanged: {
                var radius = mapPolygon.center.distanceTo(itemCoordinate)
                // Prevent signalling re-entrancy
                if (!_circleRadiusDrag && Math.abs(radius - _lastRadius) > 0.1) {
                    _circleRadiusDrag = true
                    _createCircularPolygon(mapPolygon.center, radius)
                    _circleRadiusDragCoord = itemCoordinate
                    _circleRadiusDrag = false
                    _lastRadius = radius
                }
            }
        }
    }

    Component {
        id: radiusVisualsComponent

        Item {
            property var    circleCenterCoord:  mapPolygon.center

            function _calcRadiusDragCoord() {
                _circleRadiusDragCoord = circleCenterCoord.atDistanceAndAzimuth(_circleRadius, 90)
            }

            onCircleCenterCoordChanged: {
                if (!_circleRadiusDrag) {
                    _calcRadiusDragCoord()
                }
            }

            QGCDynamicObjectManager {
                id: _objMgr
            }

            Component.onCompleted: {
                _calcRadiusDragCoord()
                var radiusDragHandle = _objMgr.createObject(radiusDragHandleComponent, mapControl, true)
                radiusDragHandle.coordinate = Qt.binding(function() { return _circleRadiusDragCoord })
                var radiusDragIndicator = radiusDragAreaComponent.createObject(mapControl, { "itemIndicator": radiusDragHandle, "itemCoordinate": _circleRadiusDragCoord })
                _objMgr.addObject(radiusDragIndicator)

            }
        }
    }

}