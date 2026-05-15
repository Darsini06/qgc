import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQml
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette


/// Mission item edit control
Rectangle {
    id:             _root
    height:         mainColumn.height
    clip:           true

    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.41) }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.41) }
    }

    radius:         ScreenTools.defaultFontPixelHeight * 0.45
    opacity:        _currentItem ? 1.0 : 0.75
    border.width:   1
    border.color:   _currentItem ? "#8a6cad" : "#3d2455"

    property var    map                 ///< Map control
    property var    masterController
    property var    missionItem         ///< MissionItem associated with this editor
    property bool   readOnly            ///< true: read only view, false: full editing view

    signal clicked
    signal remove
    signal selectNextNotReadyItem
    signal editItemClicked(var popupItem)
    signal selectCommandClicked(var missionItem)
    signal deselect

    property var    _masterController:          masterController
    property var    _missionController:         _masterController.missionController
    property bool   _currentItem:               missionItem.isCurrentItem || (missionItem.commandName === "Survey") || (missionItem.commandName === "Mission Start")
    property color  _outerTextColor:            "white"//_currentItem ? qgcPal.primaryButtonText : qgcPal.text
    property bool   _noMissionItemsAdded:       ListView.view.model.count === 1
    property real   _sectionSpacer:             ScreenTools.defaultFontPixelWidth / 2  // spacing between section headings
    property bool   _singleComplexItem:         _missionController.complexMissionItemNames.length === 1
    property bool   _readyForSave:              missionItem.readyForSaveState === VisualMissionItem.ReadyForSave

    readonly property real  _editFieldWidth:    Math.min(width - _innerMargin * 2, ScreenTools.defaultFontPixelWidth * 12)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _innerMargin:       2
    readonly property real  _radius:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _hamburgerSize:     commandPicker.height * 0.75
    readonly property real  _trashSize:         commandPicker.height * 0.75
    readonly property bool  _waypointsOnlyMode: QGroundControl.corePlugin.options.missionWaypointsOnly

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: enabled
    }

    FocusScope {
        id:             currentItemScope
        anchors.fill:   parent

        MouseArea {
            anchors.fill:   parent
            onClicked: {
                console.log("missionitem",currentItemScope)
                currentItemScope.focus = true
                _root.clicked()
            }
        }
    }

    Component {
        id: editPositionDialog

        EditPositionDialog {
            coordinate:             missionItem.isSurveyItem ?  missionItem.centerCoordinate : missionItem.coordinate
            onCoordinateChanged:    missionItem.isSurveyItem ?  missionItem.centerCoordinate = coordinate : missionItem.coordinate = coordinate
        }
    }



    Column {
        id:     mainColumn
        width:  parent.width
        spacing: 0

        // ── Top row: label + Edit button ──────────────────────────────────
        Item {
            id:                 topRowLayout
            width:              parent.width
            height:             ScreenTools.defaultFontPixelHeight * 2.5



            // ── Standard commandPicker ────────────────────
            Item {
                id:                     commandPicker
                anchors.left:           parent.left
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 0.5
                anchors.right:          parent.right
                anchors.rightMargin:    editItemBtn.visible ? (editItemBtn.width + ScreenTools.defaultFontPixelWidth) : ScreenTools.defaultFontPixelWidth * 0.5
                anchors.verticalCenter: parent.verticalCenter
                height:                 parent.height
                visible:                !commandLabel.visible

                RowLayout {
                    id:                     innerLayout
                    anchors.centerIn:       parent
                    spacing:                _padding

                    property real _padding: ScreenTools.comboBoxPadding

                    QGCLabel {
                        Layout.maximumWidth:    commandPicker.width - innerLayout._padding
                        text:                   (missionItem.commandName === "Survey" && QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri") ? qsTr("Plot") : missionItem.commandName
                        color:                  "white"
                        font.bold:              true
                        font.pointSize:         ScreenTools.defaultFontPointSize
                        font.family:            "Outfit"
                        horizontalAlignment:    Text.AlignHCenter
                        verticalAlignment:      Text.AlignVCenter
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                        fontSizeMode:           Text.Fit
                        minimumPointSize:       8

                        MouseArea {
                            anchors.fill: parent
                            onClicked:    _root.selectCommandClicked(missionItem)
                        }
                    }

                    QGCColoredImage {
                        id:                 arrowImage
                        visible:            false
                        height:             14
                        width:              14
                        fillMode:           Image.PreserveAspectFit
                        smooth:             true
                        antialiasing:       true
                        color:              "white"
                        source:             "/qmlimages/arrow-down.png"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (missionItem.isCurrentItem) {
                                    _root.deselect()
                                } else {
                                    _root.selectCommandClicked(missionItem)
                                }
                            }
                        }
                    }
                }


            }

            // ── Standard commandLabel ────────────────────
            QGCLabel {
                id:                     commandLabel
                anchors.left:           parent.left
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 0.5
                anchors.right:          parent.right
                anchors.rightMargin:    editItemBtn.visible ? (editItemBtn.width + ScreenTools.defaultFontPixelWidth) : ScreenTools.defaultFontPixelWidth * 0.5
                anchors.verticalCenter: parent.verticalCenter
                visible:                (!missionItem.isCurrentItem || !missionItem.isSimpleItem || _waypointsOnlyMode || missionItem.isTakeoffItem)
                text:                   ( missionItem.commandName === "Survey" && QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri" ) ? qsTr("Plot") : missionItem.commandName
                color:                  "white"
                font.bold:              true
                font.pointSize:         ScreenTools.defaultFontPointSize
                font.family:            "Outfit"
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                fontSizeMode:           Text.Fit
                minimumPointSize:       8

                MouseArea {
                    anchors.fill: parent
                    enabled:      missionItem.commandName === "Return To Launch"
                    onClicked: {
                        _root.clicked()
                        _root.selectCommandClicked(missionItem)
                    }
                }
            }

            QGCButton {
                id:                     editItemBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right:          parent.right
                anchors.rightMargin:    ScreenTools.defaultFontPixelWidth * 0.5
                height:                 ScreenTools.defaultFontPixelHeight * 1.5
                width:                  ScreenTools.defaultFontPixelWidth * 6
                text:                   qsTr("Edit")
                visible:                true // Allow editing all items via left popup
                onClicked:              editItemClicked(missionItem)

                background: Rectangle {
                    color:  editItemBtn.pressed ? "#444" : "#222"
                    radius: ScreenTools.defaultFontPixelHeight * 0.2
                    border.color: "white"
                    border.width: 1
                }
                contentItem: Text {
                    text:                   editItemBtn.text
                    color:                  "white"
                    font.pointSize:         ScreenTools.smallFontPointSize
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                }
            }
        } // topRowLayout Item

        // ── Inline editor (Moved to left sidebar popup) ──
        Item {
            id: editorLoader
            width: 0
            height: 0
            visible: false
        }
    } // Column
} // Rectangle
