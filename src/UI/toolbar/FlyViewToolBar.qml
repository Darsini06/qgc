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





}


    }



    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         ScreenTools.toolbarHeight//_root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          "#7d8df7"//qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    // Modern parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          "#1b1c3e"//qgcPal.window
        radius:         4  // Rounded corners
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide

        // Smooth progress bar with moving icon at center
        Item {
            id: progressBarContainer
            anchors.fill: parent
            anchors.margins: 6
            visible: _showLargeProgress

            property real progress: _activeVehicle ? _activeVehicle.loadProgress : 0

            // Background bar
            Rectangle {
                id: progressBackground
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: 30
                radius: 6
                color: Qt.lighter(qgcPal.window, 1.1)
                border.color: "#cccccc"
            }

            // Foreground bar (progress fill)
            Rectangle {
                id: progressFill
                anchors.verticalCenter: progressBackground.verticalCenter
                anchors.left: progressBackground.left
                height: progressBackground.height
                width: progressBackground.width * progressBarContainer.progress
                radius: 6
                color: "#7d8df7"
            }

            Image {
                id: progressIcon
                source: "/qmlimages/NewImages/agri.png"
                sourceSize.width: 50
                sourceSize.height: 50
                opacity: 0.9

                // Horizontal movement
                x: progressBackground.x + (progressBackground.width * progressBarContainer.progress) - width / 2

                // Vertical bounce
                y: progressBackground.y - 20 + bounceOffset

                // 🔄 Tilt the icon by 45 degrees
                rotation: 45
                transformOrigin: Item.Center  // Rotate around center

                // Bouncing animation using bounceOffset
                property real bounceOffset: 0

                SequentialAnimation on bounceOffset {
                    running: _showLargeProgress && !_initialDownloadComplete
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0
                        to: 15
                        duration: 500
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        from: 15
                        to: 0
                        duration: 500
                        easing.type: Easing.InQuad
                    }
                }
            }

        }
    }

}
