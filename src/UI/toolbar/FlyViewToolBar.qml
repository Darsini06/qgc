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
import QGroundControl.FactSystem
import QGroundControl.FactControls

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight * 0.8
    color:  Qt.rgba(0, 0, 0, 0.40)  // More transparent black toolbar

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.toolBarColor

    property var _sprayEnable:      _activeVehicle ? _activeVehicle.parameterManager.getParameter(-1, "SPRAY_ENABLE") : null
    property var _sprayPumpRate:    _activeVehicle ? _activeVehicle.parameterManager.getParameter(-1, "SPRAY_PUMP_RATE") : null
    property var _sprayPumpMin:     _activeVehicle ? _activeVehicle.parameterManager.getParameter(-1, "SPRAY_PUMP_MIN") : null
    property var _spraySpinner:     _activeVehicle ? _activeVehicle.parameterManager.getParameter(-1, "SPRAY_SPINNER") : null
    property var _spraySpeedMin:    _activeVehicle ? _activeVehicle.parameterManager.getParameter(-1, "SPRAY_SPEED_MIN") : null

    property bool _isAgri:          mainWindow ? mainWindow.droneType === "Agri" : false

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

    /*
    Rectangle {
        anchors.fill: viewButtonRow


        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;                                     color: _mainStatusBGColor }
            GradientStop { position: currentButton1.x + currentButton1.width; color: _mainStatusBGColor }
            GradientStop { position: 1;                                     color: _root.color }
        }
    }
    */

    RowLayout {
        id:                     viewButtonRow
        anchors.left:           parent.left
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   1
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCToolBarButton {
            id:                     currentButton1
            Layout.preferredHeight: viewButtonRow.height
            icon.source:            "qrc:/InstrumentValueIcons/home.svg"
            logo:                   true
            onClicked:              {

                mainWindow.homescreen()
            }
            icon.color:"white"
        }

        MainStatusIndicator {
            id:                     mainStatusIndicator
            Layout.preferredHeight: viewButtonRow.height
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
            leftPadding:        ScreenTools.defaultFontPixelWidth
            rightPadding:       ScreenTools.defaultFontPixelWidth
        }

    }

    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          rightToolsRow.left
        anchors.rightMargin:    4
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

    // Item {
    //     anchors.fill: parent

    //     Rectangle {
    //         id: curvedBackground
    //         anchors {
    //             top: parent.top
    //             // left: parent.left
    //             // right: parent.right
    //             verticalCenter: parent.verticalCenter
    //             horizontalCenter: parent.horizontalCenter
    //             // leftMargin: parent.width * 0.15     // 15% of screen width
    //             // rightMargin: parent.width * 0.15
    //         }

    //         height: parent.height * 0.25            // 25% of available height
    //         width: parent.width * 0.3              // 30% of total width
    //         radius: width / 2                       // keep smooth curve
    //         color: "#7d8df7"
    //         antialiasing: true
    //         clip: true

    //         Rectangle {
    //             anchors.left: parent.left
    //             anchors.right: parent.right
    //             height: parent.height * 0.5
    //             color: "#7d8df7"
    //         }

    //         Item {
    //             anchors {
    //                 fill: parent
    //                 topMargin: parent.height * 0.3
    //                 bottomMargin: parent.height * 0.05
    //             }

    //             Image {
    //                 source: "/qmlimages/NewImages/aviatrickslogo.png"
    //                 anchors.centerIn: parent
    //                 width: parent.width * 5
    //                 height: parent.height * 5
    //                 fillMode: Image.PreserveAspectFit
    //             }
    //         }
    //     }
    // }

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
        id:                      rightToolsRow
        anchors.right:           parent.right
        anchors.rightMargin:     12
        anchors.top:             parent.top
        anchors.bottom:          parent.bottom
        spacing:                 10

        WeatherIndicator {
            id: weatherIndicator
            Layout.alignment: Qt.AlignVCenter
            visible: true
        }

        // ── Thin vertical divider ──
        Rectangle {
            width: 1; height: parent.height * 0.55; color: Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8; Layout.rightMargin: 8
        }

        BatteryIndicator {
            id: batteryIndicator
            height: 40
            width: 45 // Fixed width to ensure it doesn't collapse
            Layout.alignment: Qt.AlignVCenter
            visible: _activeVehicle ? true : false
        }

        // ── Thin vertical divider ──
        Rectangle { 
            width: 1; height: parent.height * 0.55; color: Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8; Layout.rightMargin: 8
            visible: _activeVehicle ? true : false 
        }
        // Satellite / GPS Icon
        Row {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter

            QGCColoredImage {
                visible: _activeVehicle ? false : true
                width: 22
                height: 22
                source: "/qmlimages/NewImages/satellite.svg"
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }

            GPSIndicator {
                id: gpsindicator
                height: 40
                visible: _activeVehicle ? true : false
            }
        }

        // ── Thin vertical divider ──
        Rectangle {
            width:  1
            height: parent.height * 0.55
            color:  Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8; Layout.rightMargin: 8
            visible: _activeVehicle && !_communicationLost
        }

        // ── Flight Mode (Stabilize) ──
        FlightModeIndicator {
            id:               flightModeIndicatorRight
            Layout.alignment: Qt.AlignVCenter
            visible:          _activeVehicle && !_communicationLost
        }

        // ── Thin vertical divider ──
        Rectangle {
            width:  1
            height: parent.height * 0.55
            color:  Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8; Layout.rightMargin: 8
            visible: _isAgri && _activeVehicle
        }

        // ── SPRAY Button ──
        Item {
            id:               sprayButton
            width:            labelCol.width + 10
            height:           parent.height * 0.8
            visible:          _isAgri && _activeVehicle && !_communicationLost
            Layout.alignment: Qt.AlignVCenter

            QGCLabel {
                id:               labelCol
                anchors.centerIn: parent
                text:             qsTr("Spray")
                font.bold:        true
                font.pointSize:   ScreenTools.defaultFontPointSize
                color:            sprayMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.75) : "white"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id:           sprayMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked:    sprayPopup.open()
            }
        }

        // ── Thin vertical divider ──
        Rectangle {
            width:  1
            height: parent.height * 0.55
            color:  Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8; Layout.rightMargin: 8
            visible: _isAgri && _activeVehicle && !_communicationLost
        }

        // ── Pump Rate Status ──
        Item {
            id:               pumpRateStatus
            width:            pumpRow.width + 10
            height:           parent.height * 0.8
            visible:          _isAgri && _activeVehicle && !_communicationLost
            Layout.alignment: Qt.AlignVCenter

            Row {
                id:               pumpRow
                anchors.centerIn: parent
                spacing:          4

                QGCColoredImage {
                    width:            16
                    height:           16
                    source:           "qrc:/qmlimages/NewImages/spray_parameter.svg"
                    color:            pumpMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.75) : "white"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                QGCLabel {
                    text: {
                        var val = _sprayPumpRate ? _sprayPumpRate.rawValue : -1
                        if (val < 0 || val > 100) return "0%"
                        return Math.round(val) + "%"
                    }
                    font.bold:        true
                    font.pointSize:   ScreenTools.defaultFontPointSize
                    color:            pumpMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.75) : "white"
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            MouseArea {
                id:           pumpMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked:    sprayPopup.open()
            }
        }

        // ── Thin vertical divider ──
        Rectangle {
            width:  1
            height: parent.height * 0.55
            color:  Qt.rgba(1, 1, 1, 0.25)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8; Layout.rightMargin: 8
        }

        // ── Settings ──
        Item {
            width: 26
            height: 26
            Layout.alignment: Qt.AlignVCenter

            QGCColoredImage {
                id: settingsIcon
                anchors.fill: parent
                source: "/qmlimages/NewImages/settings.svg"
                color: "white"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: mainWindow.showToolSelectDialog()
            }
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
        height:         ScreenTools.toolbarHeight//_root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          "#301934"//qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    // Professional high-tech parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.fill:   parent
        color:          "#FFFFFF" // High-contrast White Background
        visible:        _showLargeProgress
        z:              100

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide
        property real progress:                  _activeVehicle ? _activeVehicle.loadProgress : 0

        // Background
        Rectangle {
            anchors.fill: parent
            color:        "#FFFFFF"
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: ScreenTools.defaultFontPixelWidth * 2

            // Status Text
            Text {
                text: qsTr("SYNCHRONIZING SYSTEM PARAMETERS")
                color: "#000000"
                font.pointSize: ScreenTools.smallFontPointSize
                font.bold: true
                font.letterSpacing: 2
                opacity: 0.8
            }

            // Percentage
            Text {
                text: Math.round(largeProgressBar.progress * 100) + "%"
                color: "#301934"
                font.pointSize: ScreenTools.smallFontPointSize
                font.bold: true
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 5
            }
        }

        // The sleek progress line at the bottom
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            height:         4
            width:          parent.width * largeProgressBar.progress
            color:          "#301934"
            
            // Removed Behavior on width for performance (prevents UI stutter during heavy parameter load)
        }

        // Removed scanPulse animation to save CPU overhead on mobile during connection phase

        MouseArea {
            anchors.fill: parent
            onClicked: largeProgressBar._userHide = true
        }
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
    // }

    // Spray Settings Popup
    Popup {
        id:             sprayPopup
        x:              sprayButton.mapToItem(_root, 0, 0).x - (width - sprayButton.width)
        y:              _root.height + 5
        width:          340
        padding:        0
        modal:          true
        background: Rectangle {
            color:          Qt.rgba(0, 0, 0, 0.70)
            radius:         8
            border.color:   "white"
            border.width:   1
        }

        ColumnLayout {
            width:      parent.width
            spacing:    0

            // Header
            Rectangle {
                Layout.fillWidth: true
                height:           45
                color:            "#252525"
                radius:           8 

                RowLayout {
                    anchors.fill:       parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    
                    QGCLabel {
                        text:           qsTr("SPRAYING CONTROLS")
                        font.bold:      true
                        font.pointSize: ScreenTools.mediumFontPointSize
                        color:          "white"
                        Layout.fillWidth: true
                    }
                    
                    QGCColoredImage {
                        width:  22
                        height: 22
                        source: "qrc:/qmlimages/NewImages/spray_parameter.svg"
                        color:  "white"
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#333333" }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins:   20
                spacing:          18

                // Master Enable Toggle
                RowLayout {
                    Layout.fillWidth: true
                    QGCLabel { 
                        text:             qsTr("Master System Enable")
                        font.bold:        true
                        Layout.fillWidth: true 
                    }
                    FactCheckBox {
                        fact: _sprayEnable
                    }
                }

                // Pump Rate Control (with slider)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        QGCLabel { text: qsTr("Pump Flow Rate"); color: "white" }
                        QGCLabel { 
                            text: _sprayPumpRate ? _sprayPumpRate.valueString + " %" : "N/A"
                            font.bold: true; color: "white" 
                        }
                    }
                    FactSlider {
                        Layout.fillWidth: true
                        fact:             _sprayPumpRate
                    }
                }

                // Spinner Speed Control
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        QGCLabel { text: qsTr("Granule Spinner Speed"); color: "white" }
                        QGCLabel { 
                            text: _spraySpinner ? _spraySpinner.valueString + " ms" : "N/A"
                            font.bold: true; color: "white" 
                        }
                    }
                    FactTextField {
                        Layout.fillWidth: true
                        fact:             _spraySpinner
                        showUnits:        true
                    }
                }

                // Advanced Thresholds
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        QGCLabel { text: qsTr("Min Pump %"); font.pointSize: ScreenTools.smallFontPointSize; color: "white" }
                        FactTextField {
                            Layout.fillWidth: true
                            fact:             _sprayPumpMin
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        QGCLabel { text: qsTr("Min Speed (m/s)"); font.pointSize: ScreenTools.smallFontPointSize; color: "white" }
                        FactTextField {
                            Layout.fillWidth: true
                            fact:             _spraySpeedMin
                        }
                    }
                }

                QGCButton {
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: 10
                    text:             qsTr("CLOSE")
                    onClicked:        sprayPopup.close()
                    primary:          true
                }
            }
        }
    }
}
