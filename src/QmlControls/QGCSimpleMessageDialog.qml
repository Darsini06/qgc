/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.ScreenTools

QGCPopupDialog {
    property alias  text:           label.text
    property var    acceptFunction: null        // Mainly used by MainRootWindow.showMessage to specify accept function in call

    onAccepted: {
        if (acceptFunction) {
            acceptFunction()
        }
    }

    ColumnLayout {
        width:      parent.width
        spacing:    0

        QGCLabel {
            id:                     label
            Layout.fillWidth:       true
            Layout.leftMargin:      ScreenTools.defaultFontPixelWidth
            Layout.rightMargin:     ScreenTools.defaultFontPixelWidth
            Layout.topMargin:       ScreenTools.defaultFontPixelHeight * 0.5
            Layout.bottomMargin:    ScreenTools.defaultFontPixelHeight * 0.5
            wrapMode:               Text.WordWrap
            horizontalAlignment:    Text.AlignLeft
            color:                  "black"
        }
    }
}
