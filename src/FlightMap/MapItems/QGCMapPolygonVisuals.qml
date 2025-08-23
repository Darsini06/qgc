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

import MapGlobals 1.0
import Qt.labs.platform 1.1 as Platform

/// QGCMapPolygon map visuals
Item {
    id: _root
    property int selectedVertexIndex : -1                   // Will store the MapQuickItem the user clicked
    property var    mapControl                                  ///< Map control to place item in
    property var    mapPolygon                                  ///< QGCMapPolygon object
    property bool   interactive:        mapPolygon.interactive
    property color  interiorColor:      "transparent"
    property color  altColor:           "transparent"
    property real   interiorOpacity:    1
    property int    borderWidth:        0
    property color  borderColor:        "black"

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
    property var    _appSettings:                       QGroundControl.settingsManager.appSettings
    property real _zorderDragHandle:    QGroundControl.zOrderMapItems + 3   // Highest to prevent splitting when items overlap
    property real _zorderSplitHandle:   QGroundControl.zOrderMapItems + 2
    property real _zorderCenterHandle:  QGroundControl.zOrderMapItems + 1   // Lowest such that drag or split takes precedence
    property var    _planMasterController:              planMasterController
    readonly property string _polygonToolsText: qsTr("")//("Polygon Tools")
    readonly property string _traceText:        qsTr("")//qsTr("Click in the map to add vertices. Click 'Done Tracing' when finished.")
    property var gcsPosition: QGroundControl.qgcPositionManager.gcsPosition
    property real gcsHeading: QGroundControl.qgcPositionManager.gcsHeading

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property var activeVehicleCoordinate: activeVehicle ? activeVehicle.coordinate : QtPositioning.coordinate()

    // Drawer {
    //           id: arrowDrawer
    //           edge: Qt.RightEdge
    //           width: 200
    //           //visible: false  // Hidden until a marker is clicked
    //           onClosed: _root.selectedVertexIndex = -1

    //           // A simple column of arrow buttons
    //           Column {
    //               anchors.centerIn: parent
    //               spacing: 10

    //               Button {
    //                   text: "Up"
    //                   onClicked: {
    //                       moveSelectedMarker(0, -5)
    //                   }
    //               }
    //               Row {
    //                   spacing: 10
    //                   Button {
    //                       text: "Left"
    //                       onClicked: {
    //                           moveSelectedMarker(-5, 0)
    //                       }
    //                   }
    //                   Button {
    //                       text: "Right"
    //                       onClicked: {
    //                           moveSelectedMarker(5, 0)
    //                       }
    //                   }
    //               }
    //               Button {
    //                   text: "Down"
    //                   onClicked: {
    //                       moveSelectedMarker(0, 5)
    //                   }
    //               }
    //           }
    //       }




    function addCommonVisuals() {
        console.log("addCommonVisuals method")
        if (_objMgrCommonVisuals.empty) {
            _objMgrCommonVisuals.createObject(polygonComponent, mapControl, true)
        }
    }



    function dailogclose() {
        customDialogItem.visible=false;
    }

    function tracemode() {
        mapPolygon.traceMode = false
    }

    function removeCommonVisuals() {
        console.log("removeCommonVisuals method")
        _objMgrCommonVisuals.destroyObjects()
    }

    function addEditingVisuals() {
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
        if (_objMgrToolVisuals.empty) {
            var toolbar = _objMgrToolVisuals.createObject(toolbarComponent, mapControl)
            toolbar.z = QGroundControl.zOrderWidgets
            var edit = MapGlobals.edit
            console.log("MapGlobals.edit")
            console.log("MapGlobals.edit",MapGlobals.edit)
            if(MapGlobals.edit==="edit"){
                customdialog.createObject(mainWindow).open()
                //customDialogItem.visible=true;
            }else if (MapGlobals.edit==="edit2"){
                _saveCurrentVertices()
                _circleMode = false
                mapPolygon.traceMode = true
                console.log("MapGlobals.edit1")
            }else{
                _saveCurrentVertices()
                _circleMode = false
                mapPolygon.traceMode = true
                console.log("MapGlobals.edit2")
            }




        }
    }

    function removeToolVisuals() {
        console.log("removeToolVisuals method")
        _objMgrToolVisuals.destroyObjects()
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
        if (interactive) {
            addEditingVisuals()
            addToolbarVisuals()
        } else {
            //mapPolygon.traceMode = false
            removeEditingVisuals()
            removeToolVisuals()
        }
    }

    function _saveCurrentVertices() {
        console.log("_saveCurrentVertices")
        _savedVertices = [ ]
        _savedCircleMode = _circleMode
        console.log("_savedCircleMode",MapGlobals.mapPolygon)
        console.log("_savedCircleMode",MapGlobals.mapPolygon.count)
        for (var i=0; i<mapPolygon.count; i++) {
            _savedVertices.push(mapPolygon.vertexCoordinate(i))
        }
        console.log("_savedCircleMode",_savedCircleMode)


    }

    function edit() {
        _planMasterController.edit()
    }

    function _restorePreviousVertices() {
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
        target: mapPolygon
        onTraceModeChanged: {
            if (mapPolygon.traceMode) {
                _instructionText = _traceText
                // _objMgrTraceVisuals.createObject(traceMouseAreaComponent, mapControl, false)
            } else {
                _instructionText = _polygonToolsText
                _objMgrTraceVisuals.destroyObjects()
            }
        }
    }

    Component.onCompleted: {
        addCommonVisuals()
        _handleInteractiveChanged()
    }
    Component.onDestruction: mapPolygon.traceMode = true

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

    QGCMenu {
        id: menu

        property int _editingVertexIndex: -1

        function popupVertex(curIndex) {
            menu._editingVertexIndex = curIndex
            removeVertexItem.visible = (mapPolygon.count > 0 && menu._editingVertexIndex >= 0)
            menu.popup()
        }

        function popupCenter() {
            menu.popup()
        }

        QGCMenuItem {
            id:             removeVertexItem
            visible:        !_circleMode
            text:           qsTr("Remove vertex")
            onTriggered: {
                if (menu._editingVertexIndex >= 0) {
                    mapPolygon.removeVertex(menu._editingVertexIndex)
                }
            }
        }

        QGCMenuSeparator {
            visible:        removeVertexItem.visible
        }

        QGCMenuItem {
            text:           qsTr("Set radius..." )
            visible:        _circleMode
            onTriggered:    _editCircleRadius = true
        }

        QGCMenuItem {
            text:           qsTr("Edit position..." )
            visible:        _circleMode
            onTriggered:    editCenterPositionDialog.createObject(mainWindow).open()
        }

        QGCMenuItem {
            text:           qsTr("Edit position..." )
            visible:        !_circleMode && menu._editingVertexIndex >= 0
            onTriggered:    editVertexPositionDialog.createObject(mainWindow).open()
        }

        QGCMenuItem {
            text:           qsTr("Adjust with arrows")
            visible:        !_circleMode
            onTriggered:    {
                _root.selectedVertexIndex = menu._editingVertexIndex
                //arrowDrawer.open()
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


    Component {
        id: polygonComponent

        MapPolygon {
            color:          mapPolygon.showAltColor ? altColor : interiorColor
            opacity:        interiorOpacity
            border.color:   borderColor
            border.width:   borderWidth
            path:           mapPolygon.path
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

            sourceItem: Text {
                text:     _unitsConversion.metersToAppSettingsHorizontalDistanceUnits(distance).toFixed(1) + " " +
                          _unitsConversion.appSettingsHorizontalDistanceUnitsString
                color:    "black"
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
            visible:        false//!_circleMode

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

            onClicked: if(_root.interactive) menu.popupVertex(polygonVertex)
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
                color: "white"  // Blue background
                border.color: "black"//Qt.rgba(1, 1, 1, 1)  // White border
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: (polygonVertex + 1)
                    color: "black"
                    font.bold: true
                    font.pixelSize: 10
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
                        menu.popupVertex(polygonVertex)
                    }
                }
            }
        }
    }



    // Add all polygon vertex drag handles to the map
    Component {
        id: dragHandlesComponent

        Repeater {
            model: mapPolygon.pathModel

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
            coordinate: mapPolygon.center
            onCoordinateChanged: {
                // Prevent spamming signals on vertex changes by setting centerDrag = true when changing center position.
                // This also fixes a bug where Qt gets confused by all the signalling and draws a bad visual.
                mapPolygon.centerDrag = true
                mapPolygon.center = coordinate
                mapPolygon.centerDrag = false
            }
        }
    }

    Component {
        id: editVertexPositionDialog

        EditPositionDialog {
            title:      qsTr("Edit Vertex Position")
            coordinate: mapPolygon.vertexCoordinate(menu._editingVertexIndex)
            onCoordinateChanged: {
                mapPolygon.adjustVertex(menu._editingVertexIndex, coordinate)
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
            id: toolbarRoot
            // Position and size this container to match the available viewport area
            x: mapControl.centerViewport.x
            y: mapControl.centerViewport.y
            width: mapControl.centerViewport.width
            height: mapControl.centerViewport.height

            Platform.FileDialog {
                        id: kmlFileDialog
                        title: "Select KML File"
                        nameFilters: ["KML files (*.kml)"]
                        onAccepted: {
                            var filePath = kmlFileDialog.file.toString()
                            loadKmlFile(filePath)
                        }
                        onRejected: {
                            console.log("KML load cancelled")
                            MapGlobals.mark_with = "Mark_With_Manual" // Reset to default
                        }
                    }

            function parseKML(data) {
                // Simple KML parser - adjust based on your KML structure
                var coordRegex = /<coordinates>([\s\S]*?)<\/coordinates>/
                var match = coordRegex.exec(data)

                if (match && match[1]) {
                    var coords = match[1].trim().split(' ')
                    for (var i = 0; i < coords.length; i++) {
                        var parts = coords[i].split(',')
                        if (parts.length >= 2) {
                            var lon = parseFloat(parts[0])
                            var lat = parseFloat(parts[1])
                            mapPolygon.appendVertex(QtPositioning.coordinate(lat, lon))
                        }
                    }
                }
            }

            function loadKmlFile(filePath) {
                console.log("Loading KML file:", filePath)
                var xhr = new XMLHttpRequest
                xhr.open("GET", filePath)
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            parseKML(xhr.responseText)
                        } else {
                            console.log("Error loading KML file:", xhr.statusText)
                        }
                    }
                }
                xhr.send()
            }

                    Component.onCompleted: {
                        if (MapGlobals.mark_with === "KML_File") {
                            kmlFileDialog.open()
                        }
                    }

            PlanEditToolbar {
                id: toolbar
                anchors.horizontalCenter: mapControl.left
                anchors.horizontalCenterOffset: mapControl.centerViewport.left + (mapControl.centerViewport.width / 2)
                y:                              mapControl.centerViewport.top
                availableWidth:                 mapControl.centerViewport.width

                visible:            false//mapPolygon.traceMode  // added

                // QGCButton {
                //     _horizontalPadding: 0
                //     text:               qsTr("Basic")
                //     visible:            !mapPolygon.traceMode
                //     onClicked:          _resetPolygon()
                // }

                // QGCButton {
                //     _horizontalPadding: 0
                //     text:               qsTr("Circular")
                //     visible:            !mapPolygon.traceMode
                //     onClicked:          _resetCircle()
                // }

                // QGCButton {
                //     _horizontalPadding: 0
                //     text:               mapPolygon.traceMode ? qsTr("Done Tracing") : qsTr("Trace")
                //     onClicked: {
                //         if (mapPolygon.traceMode) {
                //             if (mapPolygon.count < 3) {
                //                 _restorePreviousVertices()
                //             }else{
                //                 _planMasterController.saveToSelectedFile()
                //                 //mapPolygon.traceMode = false
                //                 mainWindow.planmap()
                //             }


                //             console.log("mapPolygon.traceMode if part")

                //         } else {

                //             customdialog.createObject(mainWindow).open()
                //             // _saveCurrentVertices()
                //             // _circleMode = false
                //             // mapPolygon.traceMode = true
                //             // mapPolygon.clear();
                //             // console.log("mapPolygon.traceMode else part")
                //         }

                //     }
                // }

                // QGCButton {
                //     _horizontalPadding: 0
                //     text:               qsTr("Load KML/SHP...")
                //     onClicked:          kmlOrSHPLoadDialog.openForLoad()
                //     visible:            !mapPolygon.traceMode
                // }
            }

            Image {
                id: controlImage
                source: "qrc:/InstrumentValueIcons/location.svg"
                anchors.centerIn: parent  // Centers both horizontally and vertically
                width: 32
                height: 32
                visible: mapPolygon.traceMode && MapGlobals.mark_with === "Mark_With_Manual"


                // MouseArea {
                //     anchors.fill: parent
                //     onClicked: {
                //         console.log("SVG image clicked")
                //         // Add your click action here
                //     }
                // }
            }


            RowLayout {

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 50
                anchors.rightMargin: 20
                spacing: 20
                visible: mapPolygon.traceMode


                Column {
                    spacing: 10
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.center
                    anchors.bottomMargin: 20
                    visible: mapPolygon.traceMode

                    Button  {
                        text: " Boundry Marking "
                        height: 34
                        font.bold: true
                        background: Rectangle {
                            radius: 20
                            color: "#ccccff"
                        }
                        onClicked: {

                            if(MapGlobals.mark_with === "Mark_With_GPS") {

                                console.log("Mark_With_GPS")
                                if (gcsPosition.isValid) {

                                    mapPolygon.appendVertex(gcsPosition)

                                    // if (mapPolygon) {
                                    // mapPolygon.appendVertex(gcsPosition)

                                    // if (isObstacleMode) {
                                    // addObstacleVisual()
                                    // } else {
                                    // addCommonVisuals()
                                    // }
                                    // }
                                }

                            }

                            else if (MapGlobals.mark_with === "Mark_With_Drone"){

                                console.log("Mark_With_Drone")
                                if (activeVehicle && activeVehicleCoordinate.isValid) {

                                    mapPolygon.appendVertex(activeVehicleCoordinate)

                                    // if (mapPolygon) {
                                    // mapPolygon.appendVertex(activeVehicleCoordinate)
                                    // if (isObstacleMode) {
                                    // addObstacleVisual()
                                    // } else {
                                    // addCommonVisuals()
                                    // }
                                    // }
                                }

                            }
                            else {

                                console.log("Mark_With_Manual")
                                // Convert the bottom-center point of controlImage to mapControl's coordinate space.
                                var bottomPoint = mapControl.mapFromItem(controlImage, controlImage.width / 2, controlImage.height);
                                // Then convert that point (in pixels) to a geographic coordinate.
                                var bottomCoord = mapControl.toCoordinate(bottomPoint, false);
                                mapPolygon.appendVertex(bottomCoord)


                                // if (mapPolygon) {
                                // mapPolygon.appendVertex(bottomCoord)

                                // if (isObstacleMode) {
                                // addObstacleVisual()
                                // } else {
                                // addCommonVisuals()
                                // }
                                // }

                            }

                        }
                    }
                    Button {
                        text: " Obstacle Point "
                        height: 34
                        font.bold: true
                        background: Rectangle {
                            radius: 20
                            color: "#ccccff"
                        }
                        onClicked: {
                            // Handle Button 2 click
                        }
                    }
                }


            }

            RowLayout {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: 20
                anchors.rightMargin: 20
                spacing: 20
                visible: mapPolygon.traceMode

                Row {
                    spacing: 30
                    //anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: "Cancel"
                        width: 100
                        height: 40
                        font.bold: true
                        background: Rectangle {
                            radius: 20
                            color: "#ccccff"
                        }
                        onClicked: {

                        }

                    }

                    Button {
                        text: " Save "
                        width: 100
                        height: 40
                        font.bold: true
                        background: Rectangle {
                            radius: 20
                            color: "#ccccff"
                        }
                        onClicked: {
                            if (mapPolygon.count < 3) {
                                _restorePreviousVertices()
                            }else{
                                _planMasterController.saveToSelectedFile()
                                //mapPolygon.traceMode = false
                                mainWindow.planmap()
                            }
                        }
                    }
                }

            }

        }

    }


    // Function to move the selected marker by dx/dy meters
    function moveSelectedMarker(dxMeters, dyMeters) {
        if (_root.selectedVertexIndex === -1 ||
                _root.selectedVertexIndex >= mapPolygon.count) return

        var vertex = mapPolygon.pathModel.get(_root.selectedVertexIndex)
        if (!vertex) return

        var coord = vertex.coordinate
        var earthRadius = 6378137.0  // WGS-84

        // Convert meter deltas to degrees
        var newLat = coord.latitude + (dyMeters / earthRadius) * (180/Math.PI)
        var newLon = coord.longitude + (dxMeters / (earthRadius * Math.cos(coord.latitude * Math.PI/180))) * (180/Math.PI)

        mapPolygon.adjustVertex(_root.selectedVertexIndex, QtPositioning.coordinate(newLat, newLon))
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



                _saveCurrentVertices()
                _circleMode = false
                mapPolygon.traceMode = true
                mapPolygon.clear();
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
                    border.color: "#3399ff"
                    border.width: 2

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        // Title
                        Label {
                            text: qsTr("Set Ground Name")
                            font.bold: true
                            font.pointSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                        }

                        // Name Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: qsTr("Name :"); Layout.preferredWidth: 80 }
                            TextField {
                                id: filenameTextField
                                Layout.fillWidth: true
                            }
                        }

                        // Phone Number Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: qsTr("Ph No:"); Layout.preferredWidth: 80 }
                            TextField {
                                id: filenameTextField1
                                Layout.fillWidth: true
                                validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,10}$/ }
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                        }

                        // Ground Name Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: qsTr("Ground Name:"); Layout.preferredWidth: 80 }
                            TextField {
                                id: filenameTextField2
                                Layout.fillWidth: true
                            }
                        }

                        // Buttons
                        Row {
                            spacing: 30
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                text: "Cancel"
                                width: 100
                                background: Rectangle {
                                    radius: 10
                                    color: "#ccccff"
                                }
                                onClicked: mobileFileSaveDialog.onRejected()
                            }

                            Button {
                                text: "Confirm"
                                width: 100
                                background: Rectangle {
                                    radius: 10
                                    color: "#ccccff"
                                }
                                onClicked: mobileFileSaveDialog.accepted()
                            }
                        }
                    }
                }
            }



            //     Column {
            //         id:         fileSaveColumn
            //         width:      40 * ScreenTools.defaultFontPixelWidth
            //         spacing:    ScreenTools.defaultFontPixelHeight / 2



            //         Row {
            //             spacing: 20
            //             anchors.horizontalCenter: parent.horizontalCenter

            //             QGCLabel { text: qsTr("Set Ground Name") }



            //         }


            //         RowLayout {
            //             anchors.left:   parent.left
            //             anchors.right:  parent.right
            //             spacing:        ScreenTools.defaultFontPixelWidth

            //             QGCLabel { text: qsTr("Name:") }

            //             QGCTextField {
            //                 id:                 filenameTextField
            //                 Layout.fillWidth:   true
            //                 onTextChanged:      replaceMessage.visible = false
            //             }
            //         }

            //         RowLayout {
            //             anchors.left:   parent.left
            //             anchors.right:  parent.right
            //             spacing:        ScreenTools.defaultFontPixelWidth

            //             QGCLabel { text: qsTr("Ph No:") }

            //             QGCTextField {
            //                 id:                 filenameTextField1
            //                 Layout.fillWidth:   true
            //                 validator:          RegularExpressionValidator { regularExpression: /^[0-9]{0,10}$/ }
            //                 inputMethodHints:   Qt.ImhDigitsOnly
            //                 onTextChanged:      replaceMessage.visible = false
            //             }
            //         }

            //         RowLayout {
            //             anchors.left:   parent.left
            //             anchors.right:  parent.right
            //             spacing:        ScreenTools.defaultFontPixelWidth

            //             QGCLabel { text: qsTr("Ground name:") }

            //             QGCTextField {
            //                 id:                 filenameTextField2
            //                 Layout.fillWidth:   true
            //                 onTextChanged:      replaceMessage.visible = false
            //             }
            //         }


            //         Row {
            //             spacing: 20
            //             anchors.horizontalCenter: parent.horizontalCenter

            //             Button {
            //                 text: "Cancel"
            //                 background: Rectangle {
            //                     radius: 10
            //                     color: "#ccccff"
            //                 }
            //                 onClicked: mobileFileSaveDialog.onRejected()
            //             }

            //             Button {
            //                 text: "Confirm"
            //                 background: Rectangle {
            //                     radius: 10
            //                     color: "#ccccff"
            //                 }
            //                 onClicked: {
            //                     mobileFileSaveDialog.accepted()
            //                 }
            //             }
            //         }

            //         }


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

    Component{
        id: customdialog


        Item {
            id: customDialogItem
            anchors.fill: parent
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: 400
                    height: 300
                    radius: 15
                    color: "#991B1C3E"
                    border.color: "#005BBB"
                    border.width: 2

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        // Title
                        Label {
                            text: qsTr("Set Ground Name3")
                            font.bold: true
                            color: "white"
                            font.pointSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                        }

                        // Name Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: qsTr("Name :"); Layout.preferredWidth: 80;font.bold: true
                                font.pointSize: 14
                                color: "white"}
                            TextField {
                                id: filenameTextField
                                Layout.fillWidth: true
                            }
                        }


                        // Phone Number Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: qsTr("Ph No:"); Layout.preferredWidth: 80;font.bold: true
                                font.pointSize: 14
                                color: "white"}
                            TextField {
                                id: filenameTextField1
                                Layout.fillWidth: true
                                validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,10}$/ }
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                        }

                        // Ground Name Field
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: qsTr("Ground Name:"); Layout.preferredWidth: 80;font.bold: true
                                font.pointSize: 14
                                color: "white"}
                            TextField {
                                id: filenameTextField2
                                Layout.fillWidth: true
                            }
                        }


                        // Buttons
                        Row {
                            spacing: 30
                            anchors.horizontalCenter: parent.horizontalCenter

                            Button {
                                text: "Cancel"
                                width: 100
                                height: 34
                                font.bold: true

                                contentItem: Text {
                                    text: qsTr("Cancel")
                                    font.bold: true
                                    font.pointSize: 14
                                    color: "white"       // ✅ Text color
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    anchors.fill: parent
                                }

                                background: Rectangle {
                                    radius: 20
                                    color: "#1b1c3e"      // ✅ Background color
                                    border.color: "#005BBB"  // ✅ Border color (you can change this)
                                    border.width: 2
                                }

                                onClicked: {
                                    mainWindow.showFlyView()
                                    customDialogItem.visible = false;
                                    MapGlobals.editdialog = "editdialog1"
                                }
                            }


                            Button {
                                width: 100
                                height: 34

                                contentItem: Text {
                                    text: "Confirm"
                                    font.bold: true
                                    font.pointSize: 14
                                    color: "white"  // ✅ White text
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    anchors.fill: parent
                                }

                                background: Rectangle {
                                    radius: 20
                                    color: "#1b1c3e"         // ✅ Background color
                                    border.color: "#005BBB"  // ✅ Border color (change to what you want)
                                    border.width: 2
                                }

                                onClicked: {
                                    if (filenameTextField.text.length < 3 ||
                                            filenameTextField1.text.length < 3 ||
                                            filenameTextField2.text.length < 3) {

                                        mobileFileSaveDialog.preventClose = true
                                        mainWindow.showToastMessage("Please fill all fields")
                                        return
                                    }

                                    let concatenatedText = filenameTextField.text.substring(0, 3) +
                                        filenameTextField1.text.substring(0, 3) +
                                        filenameTextField2.text.substring(0, 3)

                                    _appSettings.username = concatenatedText
                                    console.log(concatenatedText)

                                    _saveCurrentVertices()
                                    _circleMode = false
                                    mapPolygon.traceMode = true
                                    mapPolygon.clear()
                                    customDialogItem.visible = false
                                    MapGlobals.editdialog = "editdialog1"
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
