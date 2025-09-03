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

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.FlightMap
import MapGlobals 1.0
/// Base control for both Survey and Corridor Scan map visuals
Item {
    id: _root
    property var    map                                                 ///< Map control to place item in
    property bool   polygonInteractive: true
    property bool   interactive: true
    property var    vehicle

    property var    _missionItem:               object
    property var    _mapPolygon:                object.surveyAreaPolygon
    property bool   _currentItem:               object.isCurrentItem
    property var    _transectPoints:            _missionItem.visualTransectPoints
    property int    _transectCount:             _transectPoints.length / (_hasTurnaround ? 4 : 2)
    property bool   _hasTurnaround:             _missionItem.turnAroundDistance.rawValue !== 0
    property int    _firstTrueTransectIndex:    _hasTurnaround ? 1 : 0
    property int    _lastTrueTransectIndex:     _transectPoints.length - (_hasTurnaround ? 2 : 1)
    property int    _lastPointIndex:            _transectPoints.length - 1
    property bool   _showPartialEntryExit:      !_currentItem && _hasTurnaround &&_transectPoints.length >= 2
    property var    _fullTransectsComponent:    null
    property var    _entryTransectsComponent:   null
    property var    _exitTransectsComponent:    null
    property var    _entryCoordinate
    property var    _exitCoordinate

    signal clicked(int sequenceNumber)

    function _addVisualElements() {
        console.log("edited")
        var toAdd = [ fullTransectsComponent, entryTransectComponent, exitTransectComponent, entryPointComponent, exitPointComponent,
                     entryArrow1Component, entryArrow2Component, exitArrow1Component, exitArrow2Component ]
        objMgr.createObjects(toAdd, map, true /* parentObjectIsMap */)
    }


    function edit1() {

        if(_root.interactive) {
            clicked(_missionItem.sequenceNumber)
        }


    }


    function _destroyVisualElements() {
        objMgr.destroyObjects()
    }

    Component.onCompleted: {
        console.log("edited",object.surveyAreaPolygon)
        _addVisualElements()
        // if (_root.interactive && _missionItem.sequenceNumber === 0) {
        //     _root.clicked(_missionItem.sequenceNumber)
        // }
        clicked(_missionItem.sequenceNumber)
    }



    Component.onDestruction: {

        _destroyVisualElements()
    }

    QGCDynamicObjectManager {
        id: objMgr
    }

    // Area polygon
    QGCMapPolygonVisuals {
        id:                 mapPolygonVisuals
        mapControl:         map
        mapPolygon:         _mapPolygon
        interactive:        polygonInteractive && _missionItem.isCurrentItem && _root.interactive
        borderWidth:        5
        borderColor:        "black"
        interiorColor:      QGroundControl.globalPalette.surveyPolygonInterior
        altColor:           QGroundControl.globalPalette.surveyPolygonTerrainCollision
        interiorOpacity:    0.5 * _root.opacity
    }

    // Full set of transects lines. Shown when item is selected.
    Component {
        id: fullTransectsComponent
        MapPolyline {
            line.color: "white"
            line.width: 5
            path:       _transectPoints
            visible:    _currentItem
            opacity:    _root.opacity
        }
    }

    // Entry and exit transect lines only. Used when item is not selected.
    Component {
        id: entryTransectComponent

        MapPolyline {
            line.color: "white"
            line.width: 2
            path:       _showPartialEntryExit ? [ _transectPoints[0], _transectPoints[1] ] : []
            visible:    _showPartialEntryExit
            opacity:    _root.opacity
        }
    }


    Component {
        id: exitTransectComponent

        MapPolyline {
            line.color: "white"
            line.width: 2
            path:       _showPartialEntryExit ? [ _transectPoints[_lastPointIndex - 1], _transectPoints[_lastPointIndex] ] : []
            visible:    _showPartialEntryExit
            opacity:    _root.opacity
        }
    }

    // Entry point
    Component {
        id: entryPointComponent

        MapQuickItem {
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            z:              QGroundControl.zOrderMapItems
            coordinate:     _missionItem.coordinate
            visible:        _missionItem.exitCoordinate.isValid
            opacity:        _root.opacity

            sourceItem: MissionItemIndexLabel {
                index:      _missionItem.sequenceNumber
                checked:    _missionItem.isCurrentItem
                onClicked:  if(_root.interactive) _root.clicked(_missionItem.sequenceNumber)

                Component.onCompleted: {
                    // Automatically trigger the clicked behavior if condition is true
                    if (_root.interactive) {
                        _root.clicked(_missionItem.sequenceNumber)
                    }
                }
            }
        }
    }

    Component {
        id: entryArrow1Component

        MapLineArrow {
            fromCoord:      _transectPoints[_firstTrueTransectIndex]
            toCoord:        _transectPoints[_firstTrueTransectIndex + 1]
            arrowPosition:  1
            visible:        _currentItem
            opacity:        _root.opacity
        }
    }

    Component {
        id: entryArrow2Component

        MapLineArrow {
            fromCoord:      _transectPoints[nextTrueTransectIndex]
            toCoord:        _transectPoints[nextTrueTransectIndex + 1]
            arrowPosition:  1
            visible:        _currentItem && _transectCount > 3
            opacity:        _root.opacity

            property int nextTrueTransectIndex: _firstTrueTransectIndex + (_hasTurnaround ? 4 : 2)
        }
    }

    Component {
        id: exitArrow1Component

        MapLineArrow {
            fromCoord:      _transectPoints[_lastTrueTransectIndex - 1]
            toCoord:        _transectPoints[_lastTrueTransectIndex]
            arrowPosition:  3
            visible:        _currentItem
            opacity:        _root.opacity
        }
    }

    Component {
        id: exitArrow2Component

        MapLineArrow {
            fromCoord:      _transectPoints[prevTrueTransectIndex - 1]
            toCoord:        _transectPoints[prevTrueTransectIndex]
            arrowPosition:  13
            visible:        _currentItem && _transectCount > 3
            opacity:        _root.opacity

            property int prevTrueTransectIndex: _lastTrueTransectIndex - (_hasTurnaround ? 4 : 2)
        }
    }

    // Exit point
    Component {
        id: exitPointComponent

        MapQuickItem {
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            z:              QGroundControl.zOrderMapItems
            coordinate:     _missionItem.exitCoordinate
            visible:        _missionItem.exitCoordinate.isValid
            opacity:        _root.opacity

            sourceItem: MissionItemIndexLabel {
                index:      _missionItem.lastSequenceNumber
                checked:    _missionItem.isCurrentItem
                onClicked:  if(_root.interactive) _root.clicked(_missionItem.sequenceNumber)

                Component.onCompleted: {
                    // Automatically trigger the clicked behavior if condition is true
                    if (_root.interactive) {
                        _root.clicked(_missionItem.sequenceNumber)
                    }
                }
            }
        }
    }

    Button {
        text: "Edit"
        visible: MapGlobals.share_edit_visibility

        // Set padding for the button (space between background border and content)
        padding: 15  // This adds 10px padding inside the button around the icon

        // Set the button size to accommodate icon + padding
        implicitWidth: 46  // icon width (16) + padding (10*2 = 20) = 36
        implicitHeight: 46 // icon height (16) + padding (10*2 = 20) = 36

        // Styling properties
        background: Rectangle {
            radius: width / 2 // Makes it perfectly round (circle)
            color: "#1b1c3e" // light purple
            border.color: "#005BBB"
            border.width: 2

            // Add external padding by making the background smaller than the button
            anchors.fill: parent
            anchors.margins: 5 // This creates 5px external padding around the rounded rectangle
        }

        contentItem: QGCColoredImage {
            source: "qrc:/InstrumentValueIcons/edit-pencil.svg"
            width: 16
            height: 16
            anchors.centerIn: parent // Center the icon within the container
            color: "white"
        }

        onClicked: {
            console.log("Edit in TransectStyleMapVisuals.qml")
            if(_root.interactive) _root.clicked(_missionItem.sequenceNumber)
        }
    }

}

