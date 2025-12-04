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
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette

Item {
    id: root

    default property alias contentItem: mainLayout.data
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
                width: parent.width * 0.7
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
            contentWidth:   mainLayout.width
            contentHeight:  mainLayout.height
            boundsBehavior: Flickable.OvershootBounds   // SMOOTH FEEL

                flickDeceleration: 100                     // optional - more smooth
                maximumFlickVelocity: 6000                  // optional - faster/smoother

            ColumnLayout {
                id:         mainLayout
                x:          Math.max(0, root.width / 2 - width / 2)
                width:      Math.max(implicitWidth, ScreenTools.defaultFontPixelWidth * 50)
                spacing:    ScreenTools.defaultFontPixelHeight
            }
        }
      }



}
