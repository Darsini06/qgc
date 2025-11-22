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
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight * 0.8
    color:  "#1b1c3e"//qgcPal.toolbarBackground

    property var    planMasterController

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   _controllerProgressPct: planMasterController.missionController.progressPct
    property var plantypes
    QGCPalette { id: qgcPal }


    /// Bottom single pixel divider
    // Rectangle {
    //     anchors.left:   parent.left
    //     anchors.right:  parent.right
    //     anchors.bottom: parent.bottom
    //     height:         1
    //     color:          "white"
    //     visible:        qgcPal.globalTheme === QGCPalette.Light
    // }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCToolBarButton {
            id:                     currentButton1
            Layout.preferredHeight: viewButtonRow.height
            icon.source:            "qrc:/InstrumentValueIcons/home.svg"
            logo:                   true
            onClicked:
            {
                // if(MapGlobals.editdialog==="editdialog1"){
                //     if (planType === "Plan") {
                //         mainWindow.showFlyView()
                //         mainWindow.closefile()
                //     } else {
                //         mainWindow.showFlyView1()
                //         mainWindow.closefile()
                //     }
                // }else{
                //     mainWindow.cameraView()

                // }

                //waypoint visible logic
                QGroundControl.saveGlobalSetting("waypointvisible", "")

                //waypoint enable disable logic
                QGroundControl.saveGlobalSetting("returnWaypointEnabled", "true")

                if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Camera"){
                    mainWindow.cameraView()
                    mainWindow.closefile()
                }else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
                    mainWindow.showMapping()
                    mainWindow.closefile()
                }
                else{
                    if (planType === "Plan") {
                                            mainWindow.showFlyView()
                                            mainWindow.closefile()
                                        } else {
                                            mainWindow.showFlyView1()
                                            mainWindow.closefile()
                                        }
                }
            }
        }

    }


    // Item {
    //     width: parent.width
    //     height: parent.height

    //     Rectangle {
    //         id: curvedBackground
    //         anchors.top: parent.top
    //         anchors.left: parent.left
    //         anchors.right: parent.right
    //         anchors.bottom: parent.bottom
    //         anchors.leftMargin: 300
    //         anchors.rightMargin: 300
    //         anchors.verticalCenter: parent.verticalCenter
    //         height: parent.height * 0.10
    //         radius: 150
    //         color: "#7d8df7"
    //         antialiasing: true
    //         clip: true

    //         // Fake square top edge
    //         Rectangle {
    //             anchors.left: parent.left
    //             anchors.right: parent.right
    //             height: parent.height * 0.50
    //             color: "#7d8df7"
    //         }

    //         Item {
    //             anchors.fill: parent
    //             anchors.topMargin:30
    //             anchors.bottomMargin:10
    //             anchors.bottom: parent.bottom

    //             // Centered Image (instead of text)
    //             Image {
    //                 source: "/qmlimages/NewImages/aviatrickslogo.png"  // Change path if needed
    //                 anchors.centerIn: parent
    //                 width: 500
    //                 height: 250
    //                 fillMode: Image.PreserveAspectFit
    //                 opacity: 1.0//0.0

    //                 // SequentialAnimation on opacity {
    //                 //     running: true
    //                 //     loops: Animation.Infinite
    //                 //     NumberAnimation { from: 0.0; to: 1.0; duration: 1000 }
    //                 //     PauseAnimation { duration: 500 }
    //                 //     NumberAnimation { from: 1.0; to: 0.0; duration: 1000 }
    //                 // }
    //             }
    //         }
    //     }
    // }


    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        contentWidth:           toolIndicators.width
        flickableDirection:     Flickable.HorizontalFlick

        PlanToolBarIndicators {
            id:                     toolIndicators
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            planMasterController:   _root.planMasterController
        }
    }

    // Small mission download progress bar
    Rectangle {
        id:             progressBar
        anchors.left:   parent.left
        anchors.bottom: parent.bottom
        height:         4
        width:          _controllerProgressPct * parent.width
        color:          qgcPal.colorGreen
        visible:        false

        onVisibleChanged: {
            if (visible) {
                largeProgressBar._userHide = false
            }
        }
    }

    Rectangle {
        id:             largeProgressBar1
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        height:         parent.height
        color:          "#1b1c3e"
        width:50


        QGCToolBarButton {
            id:                     currentButton
            Layout.preferredHeight: largeProgressBar1.height
            icon.source:            "/qmlimages/NewImages/settings.png"
            logo:                   true
            onClicked:              mainWindow.showToolSelectDialog()
            Layout.alignment:        Qt.AlignRight
        }

    }

    // Large mission download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          "#1b1c3e"//qgcPal.window
        visible:        _showLargeProgress

        property bool _userHide:                false
        property bool _showLargeProgress:       progressBar.visible && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            onActiveVehicleChanged: largeProgressBar._userHide = false
        }

        Rectangle {
            // anchors.top:    parent.top
            // anchors.bottom: parent.bottom
            width:          _controllerProgressPct * parent.width
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            height: 30
            radius: 6
        }

        Rectangle {
            id: progressFill
            anchors.verticalCenter: progressBackground.verticalCenter
            anchors.left: progressBackground.left
            height: progressBackground.height
            width: _controllerProgressPct * parent.width
            radius: 6
            color: "#7d8df7"
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Syncing Mission")
            font.pointSize:     ScreenTools.largeFontPointSize
            visible:            _controllerProgressPct !== 1
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Done")
            font.pointSize:     ScreenTools.largeFontPointSize
            visible:            _controllerProgressPct === 1
        }

        // QGCLabel {
        //     anchors.margins:    _margin
        //     anchors.right:      parent.right
        //     anchors.bottom:     parent.bottom
        //     text:               qsTr("Click anywhere to hide")

        //     property real _margin: ScreenTools.defaultFontPixelWidth / 2
        // }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }

    // Progress bar
    Connections {
        target: planMasterController.missionController

        onProgressPctChanged: {
            if (_controllerProgressPct === 1) {
                if (_root.visible) {
                    resetProgressTimer.start()
                } else {
                    progressBar.visible = false
                }
            } else if (_controllerProgressPct > 0) {
                progressBar.visible = true
            }
        }
    }

    Timer {
        id:             resetProgressTimer
        interval:       3000
        onTriggered:    progressBar.visible = false
    }
}
