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

    radius:         8
    opacity:        _currentItem ? 1.0 : 0.75
    border.width:   _currentItem ? 1 : 1
    border.color:   _currentItem ? "#8a6cad" : "#3d2455"

    property var    map                 ///< Map control
    property var    masterController
    property var    missionItem         ///< MissionItem associated with this editor
    property bool   readOnly            ///< true: read only view, false: full editing view

    signal clicked
    signal remove
    signal selectNextNotReadyItem
    signal editItemClicked(var popupItem)
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
            height:             45



            // ── Standard commandPicker ────────────────────
            Item {
                id:                     commandPicker
                anchors.left:           parent.left
                anchors.leftMargin:     10
                anchors.right:          parent.right
                anchors.rightMargin:    editItemBtn.visible ? (editItemBtn.width + 20) : 10
                anchors.verticalCenter: parent.verticalCenter
                height:                 parent.height
                visible:                !commandLabel.visible

                RowLayout {
                    id:                     innerLayout
                    anchors.centerIn:       parent
                    spacing:                _padding

                    property real _padding: ScreenTools.comboBoxPadding

                    QGCLabel {
                        text:                   (missionItem.commandName === "Survey" && QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri") ? qsTr("Plot") : missionItem.commandName
                        color:                  "white"
                        font.bold:              true
                        font.pointSize:         14
                        font.family:            "Outfit"
                        horizontalAlignment:    Text.AlignHCenter
                        verticalAlignment:      Text.AlignVCenter
                        Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
                    }

                    QGCColoredImage {
                        height:             14
                        width:              14
                        fillMode:           Image.PreserveAspectFit
                        smooth:             true
                        antialiasing:       true
                        color:              "white"
                        source:             "/qmlimages/arrow-down.png"
                    }
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  {
                        commandDialog.createObject(mainWindow).open()
                    }
                }
            }

            Component {
                id: commandDialog

                MissionCommandDialog {
                    vehicle:                    masterController.controllerVehicle
                    missionItem:                _root.missionItem
                    map:                        _root.map
                    flyThroughCommandsAllowed:  true
                }
            }

            // ── Standard commandLabel ────────────────────
            QGCLabel {
                id:                     commandLabel
                anchors.left:           parent.left
                anchors.leftMargin:     10
                anchors.right:          parent.right
                anchors.rightMargin:    editItemBtn.visible ? (editItemBtn.width + 20) : 10
                anchors.verticalCenter: parent.verticalCenter
                visible:                (!missionItem.isCurrentItem || !missionItem.isSimpleItem || _waypointsOnlyMode || missionItem.isTakeoffItem)
                text:                   ( missionItem.commandName === "Survey" && QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri" ) ? qsTr("Plot") : missionItem.commandName
                color:                  "white"
                font.bold:              true
                font.pointSize:         14
                font.family:            "Outfit"
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
            }

            QGCButton {
                id:                     editItemBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right:          parent.right
                anchors.rightMargin:    10
                height:                 30
                width:                  60
                text:                   qsTr("Edit")
                visible:                missionItem.commandName === "Mission Start" ||
                                        missionItem.commandName === "Survey"
                onClicked:              editItemClicked(missionItem)

                background: Rectangle {
                    color:  editItemBtn.pressed ? "#444" : "#222"
                    radius: 4
                    border.color: "white"
                    border.width: 1
                }
                contentItem: Text {
                    text:                   editItemBtn.text
                    color:                  "white"
                    font.pointSize:         12
                    horizontalAlignment:    Text.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                }
            }
        } // topRowLayout Item

        // ── RTL description row (only when RTL is current item) ───────────
        Item {
            id:                 rtlDescRow
            width:              parent.width
            height:             visible ? (rtlDescLabel.implicitHeight + 16) : 0
            visible:            _currentItem && missionItem.commandName === "Return To Launch"

            // Top separator line
            Rectangle {
                width:              parent.width
                height:             1
                color:              Qt.rgba(1, 1, 1, 0.12)
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
            }

            QGCLabel {
                id:                     rtlDescLabel
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.leftMargin:     12
                anchors.rightMargin:    12
                anchors.verticalCenter: parent.verticalCenter
                text:                   qsTr("Sends the vehicle back to its launch position.")
                color:                  Qt.rgba(1, 1, 1, 0.65)
                font.pointSize:         10
                font.family:            "Outfit"
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                wrapMode:               Text.Wrap
            }
        } // rtlDescRow

        // ── Inline editor (excludes Mission Start, Survey, Return To Launch) ──
        Loader {
            id:                 editorLoader
            width:              _root.width > 0 ? _root.width - (_innerMargin * 2) : 200
            source:             (_currentItem
                                 && missionItem.commandName !== "Mission Start"
                                 && missionItem.commandName !== "Survey"
                                 && missionItem.commandName !== "Return To Launch")
                                ? missionItem.editorQml : ""
            visible:            (_currentItem
                                 && missionItem.commandName !== "Mission Start"
                                 && missionItem.commandName !== "Survey"
                                 && missionItem.commandName !== "Return To Launch")

            property var    masterController:   _masterController
            property real   availableWidth:     _root.width > 0 ? _root.width - (_innerMargin * 2) : 200
            property var    editorRoot:         _root
        }
    } // Column
} // Rectangle
