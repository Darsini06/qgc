import QtQuick
import QtQuick.Controls

import QGroundControl.Controls
import QGroundControl.Palette

/// Text control used for displaying text of Maps
QGCLabel {
    property var map

    QGCMapPalette {
        id: mapPal; lightColors: map ? map.isSatelliteMap : false
    }

    color:      mapPal.text
    style:      Text.Outline
    styleColor: mapPal.textOutline
}
