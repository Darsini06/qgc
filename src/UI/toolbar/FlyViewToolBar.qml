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
    color:  qgcPal.toolbarBackground

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.toolBarColor

    function dropMessageIndicatorTool() {
        toolIndicators.dropMessageIndicatorTool();
    }

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          "black"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }

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
        visible:                _activeVehicle && !_communicationLost && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
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

    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    Rectangle {
        id: statusBar
            width: (60 + 20) * 6 // Adjust width based on icons
            height: parent.height
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: "#222222" // Dark background


        RowLayout {
            anchors.fill: parent
            //spacing: 5

            BatteryIndicator {
                                                id: batteryIndicator
                                                height: 50
                                                width : 50// Fixed height for the indicator
                                                visible: activeVehicle ? true : false
                                              }


            // Battery Icon
            Column {

                Text {
                    visible: activeVehicle ? false : true
                    text: "Battery"
                    font.pixelSize: 14
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Row {
                            spacing: 5
                            QGCColoredImage {
                                visible: activeVehicle ? false : true
                                width: 20
                                height: 20
                                source: "/qmlimages/Battery.svg"
                                color: "white"
                            }
                            Text {
                                visible: activeVehicle ? false : true
                                text: " : N/A"
                                font.pixelSize: 14
                                color: "white"
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
            }




           Rectangle { width: 2; height: 50; color: "gray" } // Separator



            // Satellite Icon
            Column {
                spacing: 2
                Text {
                    text: "Sat"
                    font.pixelSize: 14
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Row {

                           spacing: 5
                           QGCColoredImage {
                               visible: activeVehicle ? false : true
                               width: 20
                               height: 20
                               source: "/qmlimages/Gps.svg"
                               color: "white"
                           }
                           Text {
                               visible: activeVehicle ? false : true
                               text: " : N/A"
                               font.pixelSize: 14
                               color: "white"
                               verticalAlignment: Text.AlignVCenter
                           }
                           GPSIndicator {
                                                               id: gpsindicator
                                                               width:50 // Adjust width as needed
                                                               height: 50                // Fixed height for the indicator
                                                               visible: activeVehicle ? true : false
                                                              }
                       }
            }

            Rectangle { width: 2; height: 50; color: "gray" } // Separator

            // Mode Icon
            Column {
                spacing: 2
                Text {
                    text: "Mode"
                    font.pixelSize: 14
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                            spacing: 5
                            QGCColoredImage {
                                //visible: activeVehicle ? false : true
                                width: 20
                                height: 20
                                source: "/qmlimages/TelemRSSI.svg"
                                color: "white"
                            }
                            Text {
                                //visible: activeVehicle ? false : true
                                text: " : N/A"
                                font.pixelSize: 14
                                color: "white"
                                verticalAlignment: Text.AlignVCenter
                            }

                            // TelemetryRSSIIndicator {
                            //                                     id: telemetryRSSIIndicator
                            //                                     width:80 // Adjust width as needed
                            //                                     height: 50                // Fixed height for the indicator
                            //                                     visible: activeVehicle ? true : false
                            //                                   }

                        }
            }

            Rectangle { width: 2; height: 50; color: "gray" } // Separator

            // Spray Icon
            Column {
                spacing: 2
                Text {

                    text: "Spray"
                    font.pixelSize: 14
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                Row {
                            spacing: 5
                            QGCColoredImage {
                                //visible: activeVehicle ? false : true
                                width: 20
                                height: 20
                                source: "/qmlimages/TelemRSSI.svg"
                                color: "white"
                            }
                            Text {
                                //visible: activeVehicle ? false : true
                                text: " : N/A"
                                font.pixelSize: 14
                                color: "white"
                                verticalAlignment: Text.AlignVCenter
                            }
                            // TelemetryRSSIIndicator {
                            //                                     id: telemetryRSSIIndicator1
                            //                                     width:80 // Adjust width as needed
                            //                                     height: 50                // Fixed height for the indicator
                            //                                     visible: activeVehicle ? true : false
                            //                                   }
                        }
            }

            Rectangle { width: 2; height: 50; color: "gray" } // Separator

            // Radar Icon
            Column {
                spacing: 2
                Row {
                            spacing: 5
                            QGCColoredImage {
                                width: 20
                                height: 20
                                source: "/qmlimages/RC.svg"
                                color: "white"
                            }
                            Text {
                                text: " : N/A"
                                font.pixelSize: 14
                                color: "white"
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                Row {
                            spacing: 5

                            Text {
                                text: "HD : N/A"
                                font.pixelSize: 14
                                color: "white"
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
            }



            Rectangle { width: 2; height: 50; color: "gray" } // Separator


                Row {
                            spacing: 5
                            QGCToolBarButton {
                                                            id: button4
                                                            Layout.preferredHeight: largeProgressBar1.height
                                                            Layout.preferredWidth: 30
                                                            icon.source: "qrc:/InstrumentValueIcons/dots-horizontal-triple.svg"
                                                            icon.width: 20
                                                            icon.height: 20
                                                            logo: true
                                                            onClicked: mainWindow.showToolSelectDialog()
                                                            transform: Rotation {
                                                                            angle: 90    // ✅ Rotate icon by 90 degrees
                                                                            origin.x: button4.width / 2
                                                                            origin.y: button4.height / 2
                                                                        }
                                                        }



}

            // More Options Icon
            // Column {
            //     spacing: 2
            //     // Text {
            //     //     text: "..."
            //     //     font.pixelSize: 14
            //     //     color: "white"
            //     //     horizontalAlignment: Text.AlignHCenter
            //     // }
            //     QGCToolBarButton {
            //                     id: button4
            //                     Layout.preferredHeight: largeProgressBar1.height
            //                     Layout.preferredWidth: 30
            //                     icon.source: "qrc:/InstrumentValueIcons/dots-horizontal-triple.svg"
            //                     icon.width: 20
            //                     icon.height: 20
            //                     logo: true
            //                     onClicked: mainWindow.showToolSelectDialog()
            //                     transform: Rotation {
            //                                     angle: 90    // ✅ Rotate icon by 90 degrees
            //                                     origin.x: button4.width / 2
            //                                     origin.y: button4.height / 2
            //                                 }
            //                 }

            // }
        }
    }


    // Large parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
            color:          qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Downloading")
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }
}
