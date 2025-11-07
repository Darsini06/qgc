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

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

RowLayout {
    id: bottomRightLayout

    property bool pipExpanded: false

    onPipExpandedChanged: {
        console.log("=== BOTTOM RIGHT LAYOUT DEBUG ===")
        console.log("BottomRightLayout: pipExpanded changed to:", pipExpanded)
    }

    TelemetryValuesBar {
        id: telemetryBar
        Layout.alignment:   Qt.AlignBottom
        extraWidth:         instrumentPanel.extraValuesWidth
        pipExpanded:        bottomRightLayout.pipExpanded
    }

    // FlyViewInstrumentPanel {
    //     id:         instrumentPanel
    //     visible:    QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
    // }
}
