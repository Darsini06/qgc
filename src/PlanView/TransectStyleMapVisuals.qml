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
import MapGlobals
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

    // Shared responsive base
    property real baseSize: parent.width * 0.045    // 6% of screen width
    property real iconSize: baseSize    // icon inside the circle

    property bool gridLines : MapGlobals.gridLines

    signal clicked(int sequenceNumber)

    function _addVisualElements() {
        console.log("edited")
        var toAdd = [ fullTransectsComponent, entryTransectComponent, exitTransectComponent, entryPointComponent, exitPointComponent,
                     entryArrow1Component, entryArrow2Component, exitArrow1Component, exitArrow2Component ]
        objMgr.createObjects(toAdd, map, true /* parentObjectIsMap */)
    }


    function edit1() {
        console.log("edited button clicked")
        if(_root.interactive) {
            clicked(_missionItem.sequenceNumber)
        }
    }


    function _destroyVisualElements() {
        objMgr.destroyObjects()
    }

    Component.onCompleted: {
        //console.log("edited : ",object.surveyAreaPolygon)
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

    property bool _isAgri: QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri"
    property color _themeColor: _isAgri ? "#79AE6F" : "#808080" // Agri Green or Professional Gray
    property color _themeBorder: _isAgri ? Qt.darker("#79AE6F", 1.2) : "black"
    property color _gridColor: _isAgri ? "#0D4D15" : "#4A4A4A" // Dark Green or Dark Gray

    // Area polygon
    QGCMapPolygonVisuals {
        id:                 mapPolygonVisuals
        mapControl:         map
        mapPolygon:         _mapPolygon
        interactive:        polygonInteractive && _missionItem.isCurrentItem && _root.interactive
        borderWidth:        _missionItem.isCurrentItem ? 4 : 2
        borderColor:        _missionItem.isCurrentItem ? "white" : _themeBorder
        interiorColor:      _themeColor
        altColor:           QGroundControl.globalPalette.surveyPolygonTerrainCollision
        interiorOpacity:    (_missionItem.isCurrentItem ? 0.35 : 0.15) * _root.opacity
    }

    // Full set of transects lines. Shown when item is selected.
    Component {
        id: fullTransectsComponent
        MapPolyline {
            line.color: _gridColor
            line.width: 5
            z:          QGroundControl.zOrderMapItems
            path:       _transectPoints
            visible:    gridLines ? _currentItem : false
            opacity:    _root.opacity
        }
    }

    // Entry and exit transect lines only. Used when item is not selected.
    Component {
        id: entryTransectComponent

        MapPolyline {
            line.color: _gridColor
            line.width: 2
            path:       _showPartialEntryExit ? [ _transectPoints[0], _transectPoints[1] ] : []
            visible:    gridLines ? _showPartialEntryExit : false
            opacity:    _root.opacity
        }
    }


    Component {
        id: exitTransectComponent

        MapPolyline {
            line.color: _gridColor
            line.width: 2
            path:       _showPartialEntryExit ? [ _transectPoints[_lastPointIndex - 1], _transectPoints[_lastPointIndex] ] : []
            visible:    gridLines ? _showPartialEntryExit : false
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
            visible:        false//gridLines ? _missionItem.exitCoordinate.isValid : false
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
            visible:        gridLines ? _currentItem : false
            opacity:        _root.opacity
        }
    }

    Component {
        id: entryArrow2Component

        MapLineArrow {
            fromCoord:      _transectPoints[nextTrueTransectIndex]
            toCoord:        _transectPoints[nextTrueTransectIndex + 1]
            arrowPosition:  1
            visible:         gridLines ? ( _currentItem && _transectCount > 3) : false
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
            visible:        gridLines ? _currentItem : false
            opacity:        _root.opacity
        }
    }

    Component {
        id: exitArrow2Component

        MapLineArrow {
            fromCoord:      _transectPoints[prevTrueTransectIndex - 1]
            toCoord:        _transectPoints[prevTrueTransectIndex]
            arrowPosition:  13
            visible:        gridLines ? (_currentItem && _transectCount > 3) : false
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
            visible:       false //gridLines ? _missionItem.exitCoordinate.isValid : false
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

    // Button {
    //     id: editBtn

    //     text: "Edit"
    //     visible: MapGlobals.share_edit_visibility

    //     padding: 15
    //     implicitWidth: 46
    //     implicitHeight: 46

    //     background: Rectangle {
    //         radius: width / 2
    //         color: "#301934"
    //         border.color: "#005BBB"
    //         border.width: 2
    //     }

    //     contentItem: QGCColoredImage {
    //         source: "qrc:/InstrumentValueIcons/edit-pencil.svg"
    //         width: 16
    //         height: 16
    //         anchors.centerIn: parent
    //         color: "white"
    //     }

    //     onClicked: {
    //                 console.log("Edit in TransectStyleMapVisuals.qml")
    //                 if(_root.interactive) _root.clicked(_missionItem.sequenceNumber)
    //             }
    // }


    Component {
        id: editPositionDialog

        EditPositionDialog {
            coordinate:             _missionItem.isSurveyItem ? _missionItem.centerCoordinate : _missionItem.coordinate
            onCoordinateChanged:    _missionItem.isSurveyItem ? _missionItem.centerCoordinate = coordinate : _missionItem.coordinate = coordinate
        }
    }

    Item {
        x: map.parent.parent.compassNorthX
        y: map.parent.parent.compassBottomY

        Button {
            id: editBtn
            padding: 0
            visible: MapGlobals.share_edit_visibility
            implicitWidth: baseSize
            implicitHeight: baseSize

            background: Rectangle {
                radius: width / 2
                color: "white"//"#1b1c3e"
                //border.color: "#005BBB"
                //border.width: 2
            }

            contentItem: Item {
                anchors.fill: parent

                QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/edit-pencil.svg"
                    width: iconSize * 0.5
                    height: iconSize * 0.5
                    anchors.centerIn: parent
                    color: "black"
                }
            }

            onClicked: {
                console.log("Edit clicked")
                if(_root.interactive) _root.clicked(_missionItem.sequenceNumber)

                MapGlobals.share_edit_visibility = false
                MapGlobals.showMissionItems = true
            }
        }
    }
}
