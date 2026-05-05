import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.FlightMap

TransectStyleComplexItemEditor {
    transectAreaDefinitionComplete: missionItem.surveyAreaPolygon.isValid
    transectAreaDefinitionHelp:     qsTr("Use the Polygon Tools to create the polygon which outlines your Plot area.")
    transectValuesHeaderName:       qsTr("Transects")
    transectValuesComponent:        _transectValuesComponent
    presetsTransectValuesComponent: _transectValuesComponent

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property var    _missionItem:   missionItem

    // Theme palette
    readonly property color _colorBgSecondary:   Qt.rgba(1, 1, 1, 0.08)
    readonly property color _colorBgTertiary:    Qt.rgba(1, 1, 1, 0.14)
    readonly property color _colorBorder:        Qt.rgba(1, 1, 1, 0.28)
    readonly property color _colorAccent:        Qt.rgba(1, 1, 1, 0.25)
    readonly property color _colorAccentLight:   "#777777"
    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#ffffff"
    readonly property color _colorPlaceholder:   "#ffffff"
    readonly property color _colorSuccess:       "#2ECC71"
    property bool   _linkIndentation: true
    property int    _indentSideIndex: 0 // 0:Top, 1:Right, 2:Bottom, 3:Left
    readonly property bool  _isAgri:             QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri"

    function _smartOptimize() {
        if (missionItem.surveyAreaPolygon.count < 3) return
        
        var maxDist = 0
        var bestAngle = 0
        
        // Find the longest edge to align the grid for minimum turns
        for (var i = 0; i < missionItem.surveyAreaPolygon.count; i++) {
            var c1 = missionItem.surveyAreaPolygon.path[i]
            var c2 = missionItem.surveyAreaPolygon.path[(i + 1) % missionItem.surveyAreaPolygon.count]
            var d = c1.distanceTo(c2)
            if (d > maxDist) {
                maxDist = d
                bestAngle = c1.azimuthTo(c2)
            }
        }
        
        // Normalize angle to 0-180 (survey grids are symmetric)
        bestAngle = Math.round(bestAngle) % 180
        if (bestAngle < 0) bestAngle += 180
        
        missionItem.gridAngle.value = bestAngle
    }

    Component {
        id: _transectValuesComponent

        ColumnLayout {
            Layout.fillWidth: true
            spacing:          _margin * 1.5

            // Spacer to prevent navbar overlap
            Item { Layout.fillWidth: true; height: _margin }

            // ─── Angle (full volume-slider style) ─────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          _margin * 0.5

                RowLayout {
                    Layout.fillWidth: true
                    
                    QGCLabel {
                        text:           qsTr("Angle")
                        color:          _colorTextSecondary
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.bold:      true
                    }
                    
                    QGCLabel {
                        Layout.fillWidth: true
                        text:             missionItem.gridAngle.value.toFixed(0) + "°"
                        color:            _colorTextPrimary
                        font.pointSize:   ScreenTools.defaultFontPointSize
                        font.bold:        true
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 359
                    stepSize: 1
                    value: missionItem.gridAngle.value
                    onValueChanged: {
                        if (missionItem.gridAngle.value !== value) {
                            missionItem.gridAngle.value = value
                        }
                    }
                }

                // --- Optimized Alignment Button ---
                Button {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: implicitHeight
                    padding:                8
                    visible:                !_isAgri

                    background: Rectangle {
                        radius: 8
                        color:  parent.pressed ? "#1E1E24" : (parent.hovered ? _colorBgTertiary : _colorBgSecondary)
                        border.color: parent.hovered ? _colorSuccess : _colorBorder
                        border.width: 1
                    }

                    contentItem: RowLayout {
                        spacing: 8
                        QGCColoredImage {
                            source: "/resources/InstrumentValueIcons/check.svg"
                            width:  14; height: 14
                            color:  _colorSuccess
                            Layout.alignment: Qt.AlignVCenter
                        }
                        QGCLabel {
                            text: qsTr("Smart Path Optimization")
                            font.pixelSize: ScreenTools.smallFontPointSize
                            font.bold: true
                            color: _colorTextPrimary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap     // Full words, no truncation
                        }
                    }
                    onClicked: _smartOptimize()
                }

                // --- Indentation / Turnaround Section ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing:          _margin * 0.5

                    // Boundary Indentation enable row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing:          _margin
                        QGCLabel {
                            text:           qsTr("Boundary Indentation")
                            color:          _colorTextSecondary
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.bold:      true
                            Layout.fillWidth: true
                            wrapMode:       Text.WordWrap
                        }
                        QGCCheckBox {
                            id: directionalCheck
                            text:    qsTr("Enable")
                            checked: missionItem.enableDirectionalIndentation
                            onClicked: {
                                missionItem.enableDirectionalIndentation = checked
                                if (!checked) {
                                    missionItem.boundaryIndentation      = 0
                                    missionItem.boundaryIndentationTop    = 0
                                    missionItem.boundaryIndentationBottom = 0
                                    missionItem.boundaryIndentationLeft   = 0
                                    missionItem.boundaryIndentationRight  = 0
                                }
                            }
                        }
                    }

                    // When enabled: field graphic + altitude-style +/-
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible:  missionItem.enableDirectionalIndentation
                        spacing:  ScreenTools.defaultFontPixelHeight

                        // Choose All
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth
                            Rectangle {
                                width: 30; height: 30; radius: 4
                                color: "transparent"; border.color: "black"; border.width: 2
                                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 2; color: _linkIndentation ? "black" : "transparent" }
                                MouseArea { anchors.fill: parent; onClicked: _linkIndentation = !_linkIndentation }
                            }
                            QGCLabel { text: qsTr("Choose all"); color: "black"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true }
                        }

                        // Field graphic (Square image)
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 120; height: 120; color: "#1a1a1a"; border.color: "#444444"; border.width: 1; radius: 8
                            clip: true
                            Row { anchors.centerIn: parent; spacing: 10; Repeater { model: 8; Rectangle { width: 1; height: 100; color: "#444444" } } }
                            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 3; color: (_linkIndentation || _indentSideIndex === 0) ? _colorSuccess : "transparent" }
                            Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: (_linkIndentation || _indentSideIndex === 1) ? _colorSuccess : "transparent" }
                            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 3; color: (_linkIndentation || _indentSideIndex === 2) ? _colorSuccess : "transparent" }
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: (_linkIndentation || _indentSideIndex === 3) ? _colorSuccess : "transparent" }
                        }

                        // Previous / Next
                        RowLayout {
                            Layout.fillWidth: true
                            spacing:          ScreenTools.defaultFontPixelWidth
                            visible:          !_linkIndentation
                            QGCButton { Layout.fillWidth: true; text: qsTr("Previous"); onClicked: _indentSideIndex = (_indentSideIndex + 3) % 4 }
                            QGCButton { Layout.fillWidth: true; text: qsTr("Next");     onClicked: _indentSideIndex = (_indentSideIndex + 1) % 4 }
                        }

                        // Altitude-style +/- for Boundary Indentation
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            QGCLabel { text: qsTr("Boundary Indentation"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelWidth / 1.5
                                // Minus
                                Rectangle {
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    radius: 4
                                    color:  _indBMinus.pressed ? "#000000" : (_indBMinus.containsMouse ? Qt.rgba(0,0,0,0.40) : Qt.rgba(0,0,0,0.40))
                                    border.color: _indBMinus.containsMouse ? "#000000" : "#3e3e4a"
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: "\u2212"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true; color: _colorTextPrimary }
                                    MouseArea {
                                        id: _indBMinus; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            var props = ["boundaryIndentationTop","boundaryIndentationRight","boundaryIndentationBottom","boundaryIndentationLeft"]
                                            if (_linkIndentation) {
                                                missionItem.boundaryIndentationTop    = Math.max(0, missionItem.boundaryIndentationTop    - 0.5)
                                                missionItem.boundaryIndentationBottom = Math.max(0, missionItem.boundaryIndentationBottom - 0.5)
                                                missionItem.boundaryIndentationLeft   = Math.max(0, missionItem.boundaryIndentationLeft   - 0.5)
                                                missionItem.boundaryIndentationRight  = Math.max(0, missionItem.boundaryIndentationRight  - 0.5)
                                            } else {
                                                missionItem[props[_indentSideIndex]] = Math.max(0, missionItem[props[_indentSideIndex]] - 0.5)
                                            }
                                        }
                                    }
                                }
                                // Value box
                                Rectangle {
                                    Layout.fillWidth:       true
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    radius: 4
                                    color:  Qt.rgba(0,0,0,0.40)
                                    border.color: "#3e3e4a"
                                    border.width: 1
                                    QGCLabel {
                                        anchors.centerIn: parent
                                        text: {
                                            var props = ["boundaryIndentationTop","boundaryIndentationRight","boundaryIndentationBottom","boundaryIndentationLeft"]
                                            return missionItem[props[_indentSideIndex]].toFixed(1)
                                        }
                                        color: _colorTextPrimary; font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                // Plus
                                Rectangle {
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    radius: 4
                                    color:  _indBPlus.pressed ? "#000000" : (_indBPlus.containsMouse ? Qt.rgba(0,0,0,0.40) : Qt.rgba(0,0,0,0.40))
                                    border.color: _indBPlus.containsMouse ? "#000000" : "#3e3e4a"
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true; color: _colorTextPrimary }
                                    MouseArea {
                                        id: _indBPlus; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            var props = ["boundaryIndentationTop","boundaryIndentationRight","boundaryIndentationBottom","boundaryIndentationLeft"]
                                            if (_linkIndentation) {
                                                missionItem.boundaryIndentationTop    = Math.min(50.0, missionItem.boundaryIndentationTop    + 0.5)
                                                missionItem.boundaryIndentationBottom = Math.min(50.0, missionItem.boundaryIndentationBottom + 0.5)
                                                missionItem.boundaryIndentationLeft   = Math.min(50.0, missionItem.boundaryIndentationLeft   + 0.5)
                                                missionItem.boundaryIndentationRight  = Math.min(50.0, missionItem.boundaryIndentationRight  + 0.5)
                                            } else {
                                                missionItem[props[_indentSideIndex]] = Math.min(50.0, missionItem[props[_indentSideIndex]] + 0.5)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Obstacle Margin - altitude-style
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            QGCLabel { text: qsTr("Obstacle Margin"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelWidth / 1.5
                                Rectangle {
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    radius: 4
                                    color:  _obsMinus.pressed ? "#000000" : (_obsMinus.containsMouse ? Qt.rgba(0,0,0,0.40) : Qt.rgba(0,0,0,0.40))
                                    border.color: _obsMinus.containsMouse ? "#000000" : "#3e3e4a"
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: "\u2212"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true; color: _colorTextPrimary }
                                    MouseArea { id: _obsMinus; anchors.fill: parent; hoverEnabled: true; onClicked: missionItem.obstacleIndentation = Math.max(0, missionItem.obstacleIndentation - 0.5) }
                                }
                                Rectangle {
                                    Layout.fillWidth:       true
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    radius: 4
                                    color:  Qt.rgba(0,0,0,0.40)
                                    border.color: "#3e3e4a"
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: missionItem.obstacleIndentation.toFixed(1); color: _colorTextPrimary; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                                }
                                Rectangle {
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    radius: 4
                                    color:  _obsPlus.pressed ? "#000000" : (_obsPlus.containsMouse ? Qt.rgba(0,0,0,0.40) : Qt.rgba(0,0,0,0.40))
                                    border.color: _obsPlus.containsMouse ? "#000000" : "#3e3e4a"
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true; color: _colorTextPrimary }
                                    MouseArea { id: _obsPlus; anchors.fill: parent; hoverEnabled: true; onClicked: missionItem.obstacleIndentation = Math.min(50.0, missionItem.obstacleIndentation + 0.5) }
                                }
                            }
                        }
                    }


                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder; opacity: 0.5; visible: !forPresets && !_isAgri }

            // ─── Grid Appearance & Layout ──────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          _margin * 0.8
                visible:          !forPresets && !_isAgri

                QGCLabel {
                    text:           qsTr("Grid Appearance & Layout")
                    color:          _colorTextSecondary
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.bold:      true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           gridVisualsInner.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           8
                    border.color:     _colorBorder
                    border.width:     1

                    ColumnLayout {
                        id:               gridVisualsInner
                        anchors.left:     parent.left
                        anchors.right:    parent.right
                        anchors.top:      parent.top
                        anchors.margins:  _margin
                        spacing:          _margin

                        // Width & Spacing Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing:          _margin

                            // Line Width
                            ColumnLayout {
                                spacing: 4
                                QGCLabel { text: qsTr("Line Width"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                        QGCLabel { anchors.centerIn: parent; text: "−" }
                                        MouseArea { anchors.fill: parent; onClicked: MapGlobals.setGridLineWidth(Math.max(1, MapGlobals.gridLineWidth - 1)) }
                                    }
                                    QGCLabel { text: MapGlobals.gridLineWidth; font.bold: true; width: 20; horizontalAlignment: Text.AlignHCenter }
                                    Rectangle {
                                        width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                        QGCLabel { anchors.centerIn: parent; text: "+" }
                                        MouseArea { anchors.fill: parent; onClicked: MapGlobals.setGridLineWidth(MapGlobals.gridLineWidth + 1) }
                                    }
                                }
                            }

                            // Manual Spacing (if needed)
                            ColumnLayout {
                                spacing: 4
                                QGCLabel { text: qsTr("Spacing"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                                RowLayout {
                                    spacing: 4
                                    Rectangle {
                                        width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                        QGCLabel { anchors.centerIn: parent; text: "−" }
                                        MouseArea { anchors.fill: parent; onClicked: missionItem.cameraCalc.adjustedFootprintSide().setRawValue(Math.max(1, missionItem.cameraCalc.adjustedFootprintSide().rawValue().toDouble() - 1)) }
                                    }
                                    QGCLabel { text: missionItem.cameraCalc.adjustedFootprintSide().rawValue().toFixed(1); font.bold: true; width: 40; horizontalAlignment: Text.AlignHCenter }
                                    Rectangle {
                                        width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                        QGCLabel { anchors.centerIn: parent; text: "+" }
                                        MouseArea { anchors.fill: parent; onClicked: missionItem.cameraCalc.adjustedFootprintSide().setRawValue(missionItem.cameraCalc.adjustedFootprintSide().rawValue().toDouble() + 1) }
                                    }
                                }
                            }
                        }

                        // Color Selection
                        ColumnLayout {
                            spacing: 4
                            QGCLabel { text: qsTr("Grid Color"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                spacing: 10
                                Repeater {
                                    model: ["#0D4D15", "#27AE60", "#F1C40F", "#E67E22", "#E74C3C", "#34495E"]
                                    delegate: Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: modelData
                                        border.color: MapGlobals.gridColor === color ? "white" : "transparent"
                                        border.width: 2
                                        MouseArea { anchors.fill: parent; onClicked: MapGlobals.setGridColor(parent.color) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─── Obstacle Appearance ──────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          _margin * 0.8
                visible:          !forPresets && !_isAgri

                QGCLabel {
                    text:           qsTr("Obstacle Appearance")
                    color:          _colorTextSecondary
                    font.pointSize: ScreenTools.defaultFontPointSize
                    font.bold:      true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           obsVisualsInner.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           8
                    border.color:     _colorBorder
                    border.width:     1

                    ColumnLayout {
                        id:               obsVisualsInner
                        anchors.left:     parent.left
                        anchors.right:    parent.right
                        anchors.top:      parent.top
                        anchors.margins:  _margin
                        spacing:          _margin

                        // Border Width
                        ColumnLayout {
                            spacing: 4
                            QGCLabel { text: qsTr("Border Width"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                spacing: 4
                                Rectangle {
                                    width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                    QGCLabel { anchors.centerIn: parent; text: "−" }
                                    MouseArea { anchors.fill: parent; onClicked: MapGlobals.setObstacleLineWidth(Math.max(0, MapGlobals.obstacleLineWidth - 1)) }
                                }
                                QGCLabel { text: MapGlobals.obstacleLineWidth; font.bold: true; width: 20; horizontalAlignment: Text.AlignHCenter }
                                Rectangle {
                                    width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                    QGCLabel { anchors.centerIn: parent; text: "+" }
                                    MouseArea { anchors.fill: parent; onClicked: MapGlobals.setObstacleLineWidth(MapGlobals.obstacleLineWidth + 1) }
                                }
                            }
                        }

                        // Opacity Control
                        ColumnLayout {
                            spacing: 4
                            QGCLabel { text: qsTr("Interior Opacity"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                spacing: 4
                                Rectangle {
                                    width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                    QGCLabel { anchors.centerIn: parent; text: "−" }
                                    MouseArea { anchors.fill: parent; onClicked: MapGlobals.setObstacleOpacity(Math.max(0, MapGlobals.obstacleOpacity - 0.1)) }
                                }
                                QGCLabel { text: Math.round(MapGlobals.obstacleOpacity * 100) + "%"; font.bold: true; width: 40; horizontalAlignment: Text.AlignHCenter }
                                Rectangle {
                                    width: 30; height: 30; radius: 4; color: _colorBgTertiary; border.color: _colorBorder
                                    QGCLabel { anchors.centerIn: parent; text: "+" }
                                    MouseArea { anchors.fill: parent; onClicked: MapGlobals.setObstacleOpacity(Math.min(1, MapGlobals.obstacleOpacity + 0.1)) }
                                }
                            }
                        }

                        // Color Selection
                        ColumnLayout {
                            spacing: 4
                            QGCLabel { text: qsTr("Obstacle Color"); font.pointSize: ScreenTools.defaultFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                spacing: 10
                                Repeater {
                                    model: ["#F1C40F", "#F39C12", "#E67E22", "#E74C3C", "#C0392B", "#95A5A6"]
                                    delegate: Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: modelData
                                        border.color: MapGlobals.obstacleColor === color ? "white" : "transparent"
                                        border.width: 2
                                        MouseArea { anchors.fill: parent; onClicked: MapGlobals.setObstacleColor(parent.color) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─── Options ComboBox ─────────────────────────────────────────
            // Styled wrapper so the combobox background matches dark theme
            Rectangle {
                Layout.fillWidth: true
                height:           optionsCombo.implicitHeight
                color:            _colorBgSecondary
                radius:           8
                border.color:     _colorBorder
                border.width:     1
                visible:          !forPresets && !_isAgri

                QGCOptionsComboBox {
                    id:               optionsCombo
                    anchors.fill:     parent
                    anchors.margins:  1

                    model: [
                        {
                            text:    qsTr("Hover and capture image"),
                            fact:    missionItem.hoverAndCapture,
                            enabled: missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeRelative || missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeAbsolute,
                            visible: missionItem.hoverAndCaptureAllowed
                        },
                        {
                            text:    qsTr("Refly at 90 deg offset"),
                            fact:    missionItem.refly90Degrees,
                            enabled: missionItem.cameraCalc.distanceMode !== QGroundControl.AltitudeModeCalcAboveTerrain,
                            visible: true
                        },
                        {
                            text:    qsTr("Images in turnarounds"),
                            fact:    missionItem.cameraTriggerInTurnAround,
                            enabled: missionItem.hoverAndCaptureAllowed ? !missionItem.hoverAndCapture.rawValue : true,
                            visible: true
                        },
                        {
                            text:    qsTr("Fly alternate transects"),
                            fact:    missionItem.flyAlternateTransects,
                            enabled: true,
                            visible: _vehicle ? (_vehicle.fixedWing || _vehicle.vtol) : false
                        }
                    ]

                    // Dark-theme override for the combo button
                    background: Rectangle {
                        implicitWidth:  ScreenTools.implicitComboBoxWidth
                        implicitHeight: ScreenTools.implicitComboBoxHeight
                        color:          "transparent"
                        border.width:   0
                    }

                    contentItem: Item {
                        implicitWidth:  labelText2.implicitWidth
                        implicitHeight: labelText2.implicitHeight

                        Text {
                            id:                    labelText2
                            anchors.verticalCenter: parent.verticalCenter
                            text:                  optionsCombo.labelText
                            color:                 _colorTextSecondary   // grey, NOT white
                            font.pointSize:        ScreenTools.defaultFontPointSize
                        }
                    }
                }
            }
        }
    }

    // ── Internal volume slider component ──────────────────────────────────
    Component {
        id: _volumeSlider

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth / 1.5
            property var fact: null

            // − button
            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       4
                color:        _minArea.pressed ? _colorAccent : (_minArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: _minArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1

                QGCLabel { anchors.centerIn: parent; text: "−"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }

                MouseArea {
                    id: _minArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (parent.parent.fact) { var s = parent.parent.fact.increment ? parent.parent.fact.increment : 1; parent.parent.fact.value -= s } }
                }
            }

            // Value box
            FactTextField {
                id: _ftf
                Layout.fillWidth:       true
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment:       Qt.AlignVCenter
                fact:                   parent.fact
                showUnits:              true
                color:                  _colorTextPrimary
                placeholderText:        ""
                horizontalAlignment:    Qt.AlignHCenter
                background: Rectangle {
                    color:        _ftf.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: _ftf.activeFocus ? _colorAccent : _colorBorder
                    border.width: _ftf.activeFocus ? 2 : 1
                    radius:       4
                }
            }

            // + button
            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       4
                color:        _plusArea.pressed ? _colorAccent : (_plusArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: _plusArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1

                QGCLabel { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }

                MouseArea {
                    id: _plusArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (parent.parent.fact) { var s = parent.parent.fact.increment ? parent.parent.fact.increment : 1; parent.parent.fact.value += s } }
                }
            }
        }
    }

    KMLOrSHPFileDialog {
        id:    kmlOrSHPLoadDialog
        title: qsTr("Select Polygon File")

        onAcceptedForLoad: (file) => {
            missionItem.surveyAreaPolygon.loadKMLOrSHPFile(file)
            missionItem.resetState = false
            close()
        }
    }
}

