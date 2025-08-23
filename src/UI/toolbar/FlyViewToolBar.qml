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
    height: ScreenTools.toolbarHeight
    color:  "#1b1c3e"//"#A6ADFF"//qgcPal.toolbarBackground

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.toolBarColor

    function dropMessageIndicatorTool() {
        toolIndicators.dropMessageIndicatorTool();
    }

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

    Rectangle {
        anchors.fill: viewButtonRow


        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;                                     color: _mainStatusBGColor }
            GradientStop { position: currentButton.x + currentButton.width; color: _mainStatusBGColor }
            GradientStop { position: 1;                                     color: _root.color }
        }
    }

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
            onClicked:              mainWindow.newscreen()
            icon.color:"white"

        }


        MainStatusIndicator {
            Layout.preferredHeight: viewButtonRow.height
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
        }




    }



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

        FlyViewToolBarIndicators { id: toolIndicators }


    }

    //-------------------------------------------------------------------------
    //-- Branding Logo
    Image {
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
        visible:                false//_activeVehicle && !_communicationLost && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
        fillMode:               Image.PreserveAspectFit
        source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
        mipmap:                 true

        property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
        property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
        property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
        property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
        property bool   _userBrandingIndoor:    QGroundControl.settingsManager.brandImageSettings.visible && _userBrandImageIndoor.length != 0
        property bool   _userBrandingOutdoor:   QGroundControl.settingsManager.brandImageSettings.visible && _userBrandImageOutdoor.length != 0
        property string _brandImageIndoor:      brandImageIndoor()
        property string _brandImageOutdoor:     brandImageOutdoor()

        function brandImageIndoor() {
            if (_userBrandingIndoor) {
                return _userBrandImageIndoor
            } else {
                if (_userBrandingOutdoor) {
                    return _userBrandImageOutdoor
                } else {
                    if (_corePluginBranding) {
                        return QGroundControl.corePlugin.brandImageIndoor
                    } else {
                        return _activeVehicle ? _activeVehicle.brandImageIndoor : ""
                    }
                }
            }
        }

        function brandImageOutdoor() {
            if (_userBrandingOutdoor) {
                return _userBrandImageOutdoor
            } else {
                if (_userBrandingIndoor) {
                    return _userBrandImageIndoor
                } else {
                    if (_corePluginBranding) {
                        return QGroundControl.corePlugin.brandImageOutdoor
                    } else {
                        return _activeVehicle ? _activeVehicle.brandImageOutdoor : ""
                    }
                }
            }
        }
    }

    Item {
        width: parent.width
        height: parent.height

        Rectangle {
            id: curvedBackground
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 300
            anchors.rightMargin: 300
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height * 0.10
            width:280
            radius: 150
            color: "#7d8df7"
            antialiasing: true
            clip: true

            // Fake square top edge
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.50
                color: "#7d8df7"
            }

            Item {
                anchors.fill: parent
                anchors.topMargin:30
                anchors.bottomMargin:10
                anchors.bottom: parent.bottom

                // Centered Image (instead of text)
                Image {
                    source: "/qmlimages/NewImages/aviatrickslogo.png"  // Change path if needed
                    anchors.centerIn: parent
                    width: 500
                    height: 250
                    fillMode: Image.PreserveAspectFit
                    opacity: 1.0//0.0

                    // SequentialAnimation on opacity {
                    //     running: true
                    //     loops: Animation.Infinite
                    //     NumberAnimation { from: 0.0; to: 1.0; duration: 1000 }
                    //     PauseAnimation { duration: 500 }
                    //     NumberAnimation { from: 1.0; to: 0.0; duration: 1000 }
                    // }
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
    //         anchors.leftMargin: 250
    //         anchors.rightMargin: 200
    //         anchors.verticalCenter: parent.verticalCenter
    //         height: parent.height* 0.10
    //         radius: 150
    //         color: "#7d8df7"
    //         antialiasing: true
    //         clip: true

    //         // Fake square top edge by overlaying a rectangle
    //         Rectangle {
    //             anchors.left: parent.left
    //             anchors.right: parent.right
    //             height: parent.height* 0.05 // same as radius
    //             color: "#7d8df7"
    //         }

    //         Item {
    //             anchors.fill: parent
    //             anchors.margins: 10

    //             // Centered Text
    //             Text {
    //                 text: "AVIATRICKS"
    //                 font.pixelSize: 20
    //                 font.bold: true
    //                 color: "white"
    //                 anchors.centerIn: parent
    //                 opacity: 0.0

    //                 SequentialAnimation on opacity {
    //                     running: true
    //                     loops: Animation.Infinite
    //                     NumberAnimation { from: 0.0; to: 1.0; duration: 1000 }
    //                     PauseAnimation { duration: 500 }
    //                     NumberAnimation { from: 1.0; to: 0.0; duration: 1000 }
    //                 }
    //             }


    //         }

    //     }
    // }





    RowLayout {
        anchors.verticalCenter:  parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin:     20
        spacing: 10

        BatteryIndicator {
                                            id: batteryIndicator
                                            width:40
                                            height: 40                // Fixed height for the indicator
                                            visible: true//activeVehicle ? true : false
                                          }




        // Battery Icon
        Column {
            Layout.alignment: Qt.AlignVCenter
            visible: !activeVehicle

            // Text {
            //     text: "Battery"
            //     font.pixelSize: 14
            //     color: "white"
            //     horizontalAlignment: Text.AlignHCenter
            // }

            Row {
                spacing: 5
                Image {
                    width: 25
                    height: 25
                    source: "/qmlimages/NewImages/battery.png"
                }

            }
        }




       Rectangle { width: 2; height: 40; color: "transparent" } // Separator



        // Satellite Icon
        Column {

            Row {

                       spacing: 5
                       QGCColoredImage {
                           visible: activeVehicle ? false : true
                           width: 25
                           height: 25
                           source: "/qmlimages/NewImages/satellite.png"
                           color: "white"
                       }


                   GPSIndicator {
                                                           id: gpsindicator
                                                           width:60 // Adjust width as needed
                                                           height: 50                // Fixed height for the indicator
                                                           visible: activeVehicle ? true : false
                                                          }
                   }
        }





        // // Spray Icon
        // Column {
        //     spacing: 2
        //     Text {

        //         text: "Spray"
        //         font.pixelSize: 14
        //         color: "white"
        //         horizontalAlignment: Text.AlignHCenter
        //     }
        //     Row {
        //                 spacing: 5
        //                 QGCColoredImage {
        //                     //visible: activeVehicle ? false : true
        //                     width: 20
        //                     height: 20
        //                     source: "/qmlimages/NewImages/satellite.png"
        //                     color: "white"
        //                 }
        //                 Text {
        //                     //visible: activeVehicle ? false : true
        //                     text: " : N/A"
        //                     font.pixelSize: 14
        //                     color: "white"
        //                     verticalAlignment: Text.AlignVCenter
        //                 }

        //                 // TelemetryRSSIIndicator {
        //                 //                                     id: telemetryRSSIIndicator1
        //                 //                                     width:80 // Adjust width as needed
        //                 //                                     height: 50                // Fixed height for the indicator
        //                 //                                     visible: activeVehicle ? true : false
        //                 //                                   }
        //             }
        // }


        // Radar Icon
        Column {
            spacing: 2
            Row {
                        spacing: 5
                        QGCColoredImage {
                            width: 25
                            height: 25
                            source: "/qmlimages/RC.svg"
                            color: "white"
                        }



                    }


        }




        //Rectangle { width: 2; height: 40; color: "gray" } // Separator


            Row {
                        spacing: 5

                        Item {
                            width: 25
                            height: 25

                            QGCColoredImage {
                                id: settingsIcon
                                anchors.fill: parent
                                source: "/qmlimages/NewImages/settings.png"
                                color:"white"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    mainWindow.showToolSelectDialog()
                                }
                            }
                        }

                        // QGCToolBarButton {
                        //                                 id: button4
                        //                                 Layout.preferredHeight: largeProgressBar1.height
                        //                                 Layout.preferredWidth: 30
                        //                                 icon.source: "/qmlimages/NewImages/settings.png"
                        //                                 icon.width: 20
                        //                                 icon.height: 20
                        //                                 logo: true
                        //                                 onClicked: mainWindow.showToolSelectDialog()
                        //                                 transform: Rotation {
                        //                                                 angle: 90    // ✅ Rotate icon by 90 degrees
                        //                                                 origin.x: button4.width / 2
                        //                                                 origin.y: button4.height / 2
                        //                                             }
                        //                             }



}


    }

//     Rectangle {
//         id: statusBar
//             width: (40 + 20) * 4 // Adjust width based on icons
//             height: parent.height
//             anchors.verticalCenter:  parent.verticalCenter
//             anchors.right: parent.right
//             color: "#A6ADFF"


//         RowLayout {
//             anchors.verticalCenter:  parent.verticalCenter
//             //spacing: 5

//             BatteryIndicator {
//                                                 id: batteryIndicator
//                                                 width:40
//                                                 height: 40                // Fixed height for the indicator
//                                                 visible: activeVehicle ? true : false
//                                               }




//             // Battery Icon
//             Column {
//                 Layout.alignment: Qt.AlignVCenter
//                 visible: !activeVehicle

//                 // Text {
//                 //     text: "Battery"
//                 //     font.pixelSize: 14
//                 //     color: "white"
//                 //     horizontalAlignment: Text.AlignHCenter
//                 // }

//                 Row {
//                     spacing: 5
//                     Image {
//                         width: 25
//                         height: 25
//                         source: "/qmlimages/NewImages/battery.png"
//                     }

//                 }
//             }




//            //Rectangle { width: 2; height: 40; color: "gray" } // Separator



//             // Satellite Icon
//             Column {

//                 Row {

//                            spacing: 5
//                            QGCColoredImage {
//                                visible: activeVehicle ? false : true
//                                width: 25
//                                height: 25
//                                source: "/qmlimages/NewImages/satellite.png"
//                                color: "white"
//                            }


//                        GPSIndicator {
//                                                                id: gpsindicator
//                                                                width:50 // Adjust width as needed
//                                                                height: 50                // Fixed height for the indicator
//                                                                visible: activeVehicle ? true : false
//                                                               }
//                        }
//             }





//             // // Spray Icon
//             // Column {
//             //     spacing: 2
//             //     Text {

//             //         text: "Spray"
//             //         font.pixelSize: 14
//             //         color: "white"
//             //         horizontalAlignment: Text.AlignHCenter
//             //     }
//             //     Row {
//             //                 spacing: 5
//             //                 QGCColoredImage {
//             //                     //visible: activeVehicle ? false : true
//             //                     width: 20
//             //                     height: 20
//             //                     source: "/qmlimages/NewImages/satellite.png"
//             //                     color: "white"
//             //                 }
//             //                 Text {
//             //                     //visible: activeVehicle ? false : true
//             //                     text: " : N/A"
//             //                     font.pixelSize: 14
//             //                     color: "white"
//             //                     verticalAlignment: Text.AlignVCenter
//             //                 }

//             //                 // TelemetryRSSIIndicator {
//             //                 //                                     id: telemetryRSSIIndicator1
//             //                 //                                     width:80 // Adjust width as needed
//             //                 //                                     height: 50                // Fixed height for the indicator
//             //                 //                                     visible: activeVehicle ? true : false
//             //                 //                                   }
//             //             }
//             // }


//             // Radar Icon
//             Column {
//                 spacing: 2
//                 Row {
//                             spacing: 5
//                             QGCColoredImage {
//                                 width: 25
//                                 height: 25
//                                 source: "/qmlimages/RC.svg"
//                                 color: "white"
//                             }

//                         }


//             }



//             //Rectangle { width: 2; height: 40; color: "gray" } // Separator


//                 Row {
//                             spacing: 5

//                             Item {
//                                 width: 25
//                                 height: 25

//                                 Image {
//                                     id: settingsIcon
//                                     anchors.fill: parent
//                                     source: "/qmlimages/NewImages/settings.png"
//                                 }

//                                 MouseArea {
//                                     anchors.fill: parent
//                                     onClicked: {
//                                         mainWindow.showToolSelectDialog()
//                                     }
//                                 }
//                             }

//                             // QGCToolBarButton {
//                             //                                 id: button4
//                             //                                 Layout.preferredHeight: largeProgressBar1.height
//                             //                                 Layout.preferredWidth: 30
//                             //                                 icon.source: "/qmlimages/NewImages/settings.png"
//                             //                                 icon.width: 20
//                             //                                 icon.height: 20
//                             //                                 logo: true
//                             //                                 onClicked: mainWindow.showToolSelectDialog()
//                             //                                 transform: Rotation {
//                             //                                                 angle: 90    // ✅ Rotate icon by 90 degrees
//                             //                                                 origin.x: button4.width / 2
//                             //                                                 origin.y: button4.height / 2
//                             //                                             }
//                             //                             }



// }


//         }


//     }

    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    // Modern parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        radius:         4  // Rounded corners
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide

        // Modern progress bar with gradient and animation
        // Rectangle {
        //     id: progressBarTrack
        //     anchors.top:    parent.top
        //     anchors.bottom: parent.bottom
        //     anchors.left:   parent.left
        //     width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        //     radius:         4

        //     gradient: Gradient {
        //         GradientStop { position: 0.0; color: qgcPal.colorGreen }
        //         GradientStop { position: 1.0; color: Qt.lighter(qgcPal.colorGreen, 1.2) }
        //     }

        //     // Animation for active loading
        //     SequentialAnimation on opacity {
        //         running: _showLargeProgress && !_initialDownloadComplete
        //         loops: Animation.Infinite
        //         NumberAnimation { from: 0.8; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
        //         NumberAnimation { from: 1.0; to: 0.8; duration: 800; easing.type: Easing.InOutQuad }
        //     }
        // }

        // Segmented progress bar (2nd row, 2nd column style)
        Row {
            id: segmentedProgressBar
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            visible: _showLargeProgress

            property int totalSegments: 20
            property real progress: _activeVehicle ? _activeVehicle.loadProgress : 0

            Repeater {
                model: segmentedProgressBar.totalSegments

                Rectangle {
                    width: (segmentedProgressBar.width - (segmentedProgressBar.spacing * (segmentedProgressBar.totalSegments - 1))) / segmentedProgressBar.totalSegments
                    height: segmentedProgressBar.height
                    radius: 2
                    color: index < Math.round(segmentedProgressBar.progress * segmentedProgressBar.totalSegments)
                           ? qgcPal.colorGreen : Qt.lighter(qgcPal.window, 1.1)
                    border.color: "#cccccc"
                }
            }
        }

        // Loading indicator with icon and animation
        Row {
            anchors.centerIn: parent
            spacing: ScreenTools.defaultFontPixelWidth

            // Animated spinner
            Item {
                width: ScreenTools.largeFontPixelSize
                height: width
                anchors.verticalCenter: parent.verticalCenter

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1200
                    loops: Animation.Infinite
                    running: _showLargeProgress
                }

                Image {
                    anchors.fill: parent
                    source: "/qmlimages/NewImages/settings.png"
                    sourceSize.width: width
                    sourceSize.height: height
                    opacity: 0.8
                }
            }

            QGCLabel {
                text: qsTr("Downloading Parameters") + (_activeVehicle ? " (" + Math.round(_activeVehicle.loadProgress * 100) + "%)" : "")
                font.pointSize: ScreenTools.largeFontPointSize
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // // Close hint (modern version)
        // QGCLabel {
        //     anchors.margins:    _margin
        //     anchors.right:      parent.right
        //     anchors.bottom:     parent.bottom
        //     text:               qsTr("Click to hide")
        //     font.pointSize:     ScreenTools.smallFontPointSize
        //     opacity:            0.7

        //     property real _margin: ScreenTools.defaultFontPixelWidth / 2
        // }

        // MouseArea {
        //     anchors.fill:   parent
        //     onClicked:      largeProgressBar._userHide = true
        // }
    }

    // // Large parameter download progress bar
    // Rectangle {
    //     id:             largeProgressBar
    //     anchors.bottom: parent.bottom
    //     anchors.left:   parent.left
    //     anchors.right:  parent.right
    //     height:         parent.height
    //     color:          qgcPal.window
    //     visible:        _showLargeProgress

    //     property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
    //     property bool _userHide:                false
    //     property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

    //     Connections {
    //         target:                 QGroundControl.multiVehicleManager
    //         function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
    //     }

    //     Rectangle {
    //         anchors.top:    parent.top
    //         anchors.bottom: parent.bottom
    //         width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
    //         color:          qgcPal.colorGreen
    //     }

    //     QGCLabel {
    //         anchors.centerIn:   parent
    //         text:               qsTr("Downloading")
    //         font.pointSize:     ScreenTools.largeFontPointSize
    //     }

    //     // QGCLabel {
    //     //     anchors.margins:    _margin
    //     //     anchors.right:      parent.right
    //     //     anchors.bottom:     parent.bottom
    //     //     text:               qsTr("Click anywhere to hide")

    //     //     property real _margin: ScreenTools.defaultFontPixelWidth / 2
    //     // }



    //     // MouseArea {
    //     //     anchors.fill:   parent
    //     //     onClicked:      largeProgressBar._userHide = true
    //     // }
    // }

}
