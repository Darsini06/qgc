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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Controllers

/// Base view control for all Setup pages
Item {
    id:             setupView
    enabled:        !_disableDueToArmed && !_disableDueToFlying

    property alias  pageComponent:          pageLoader.sourceComponent
    property string pageName:               vehicleComponent ? vehicleComponent.name : ""
    property string pageDescription:        vehicleComponent ? vehicleComponent.description : ""
    property real   availableWidth:         width - pageLoader.x
    property real   availableHeight:        height - pageLoader.y
    property bool   showAdvanced:           false
    property alias  advanced:               advancedCheckBox.checked

    property bool   _vehicleIsRover:        globals.activeVehicle ? globals.activeVehicle.rover : false
    property bool   _vehicleArmed:          globals.activeVehicle ? globals.activeVehicle.armed : false
    property bool   _vehicleFlying:         globals.activeVehicle ? globals.activeVehicle.flying : false
    property bool   _disableDueToArmed:     vehicleComponent ? (!vehicleComponent.allowSetupWhileArmed && _vehicleArmed) : false
    // FIXME: The _vehicleIsRover checkl is a hack to work around https://github.com/PX4/Firmware/issues/10969
    property bool   _disableDueToFlying:    vehicleComponent ? (!_vehicleIsRover && !vehicleComponent.allowSetupWhileFlying && _vehicleFlying) : false
    property string _disableReason:         _disableDueToArmed ? qsTr("armed") : qsTr("flying")
    property real   _margins:               ScreenTools.defaultFontPixelHeight * 0.5
    property string _pageTitle:             qsTr("%1 Setup").arg(pageName)

    Component.onCompleted: {
        if(pageLoader.item && pageLoader.item.setupPageCompleted) {
            pageLoader.item.setupPageCompleted()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            z: -10
            color: "#1b1c3e"
        }
        // ---- Curved Gradient Background ----
        Canvas {
            anchors.fill: parent
            z: -1
            opacity: 0.95
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                // 🎨 Create diagonal gradient
                var gradient = ctx.createLinearGradient(0, 0, width, height)
                gradient.addColorStop(0, "#14163C")
                gradient.addColorStop(1, "#6A85FB")
                ctx.fillStyle = gradient

                // 🌀 Create a curved path from top-left to bottom-right
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.quadraticCurveTo(width * 0.4, height * 0.1, width, height * 0.9)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
            }
        }

        Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: parent.width * 0.5
                height: parent.height * 0.9
                radius: width * 0.5
                rotation: 30
                opacity: 0.95
                anchors.rightMargin: 1//-width * 0.25
                anchors.bottomMargin: 1//-height * 0.2
                z: -1

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#14163C" } // Deep indigo
                    GradientStop { position: 1.0; color: "#6A85FB" } // Blue gradient
                }
            }


        QGCFlickable {
            anchors.fill:   parent
            contentWidth:   Math.max(availableWidth, pageLoader.x + pageLoader.item.width)
            contentHeight:  Math.max(availableHeight, pageLoader.y + pageLoader.item.height)
            clip:           true

            RowLayout {
                id:                 headingRow
                width:              availableWidth
                spacing:            _margins
                layoutDirection:    Qt.RightToLeft
                visible:            showAdvanced || (pageDescription !== "" && !ScreenTools.isShortScreen)

                QGCCheckBox {
                    id:         advancedCheckBox
                    text:       qsTr("Advanced")
                    visible:    showAdvanced
                }

                ColumnLayout {
                    spacing:            _margins
                    Layout.fillWidth:   true

                    QGCLabel {
                        Layout.fillWidth:   true
                        font.pointSize:     ScreenTools.largeFontPointSize
                        text:               !setupView.enabled ? _pageTitle + "<font color=\"red\">" + qsTr(" (Disabled while the vehicle is %1)").arg(_disableReason) + "</font>" : _pageTitle
                        visible:            !ScreenTools.isShortScreen
                    }

                    QGCLabel {
                        Layout.fillWidth:   true
                        wrapMode:           Text.WordWrap
                        text:               pageDescription
                        visible:            pageDescription !== "" && !ScreenTools.isShortScreen
                    }
                }
            }

            Loader {
                id:                 pageLoader
                anchors.topMargin:  _margins
                anchors.top:        headingRow.bottom
            }

            // Overlay to display when vehicle is armed and this setup page needs
            // to be disabled
            Rectangle {
                visible:            !setupView.enabled
                anchors.fill:       parent
                color:              "black"
                opacity:            0.5
            }
        }

      }

}
