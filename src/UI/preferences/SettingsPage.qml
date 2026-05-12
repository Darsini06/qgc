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
    property color backgroundColor: "#F8F9FA"

    Rectangle {
        anchors.fill: parent
        color:        backgroundColor

        // --- Subtle Branding Gradient ---
        Rectangle {
            anchors.fill: parent
            z: -1
            opacity: 0.05
            gradient: Gradient {
                GradientStop { position: 0.0; color: typeof app_color !== "undefined" ? app_color : "#4A2C6D" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        QGCFlickable {
            anchors.fill:           parent
            contentWidth:           parent.width
            contentHeight:          mainLayout.height + (ScreenTools.defaultFontPixelHeight * 4)
            flickableDirection:     Flickable.VerticalFlick
            clip:                   true

            ColumnLayout {
                id:                 mainLayout
                width:              parent.width - (ScreenTools.defaultFontPixelWidth * 4)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top:        parent.top
                anchors.topMargin:  ScreenTools.defaultFontPixelHeight * 2
                spacing:            ScreenTools.defaultFontPixelHeight * 1.5
            }
        }
    }








}
