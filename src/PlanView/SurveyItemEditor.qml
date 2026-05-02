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
    readonly property color _colorBgSecondary:   "#444444"
    readonly property color _colorBgTertiary:    "#333333"
    readonly property color _colorBorder:        "#555555"
    readonly property color _colorAccent:        "#666666"
    readonly property color _colorAccentLight:   "#777777"
    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#ffffff"
    readonly property color _colorPlaceholder:   "#ffffff"
    readonly property color _colorSuccess:       "#2ECC71"
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

            // ─── Angle (full volume-slider style) ─────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          _margin * 0.5

                QGCLabel {
                    text:           qsTr("Angle")
                    color:          _colorTextSecondary
                    font.pointSize: ScreenTools.smallFontPointSize
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing:          _margin / 1.5

                    // − button
                    Rectangle {
                        Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                        Layout.preferredWidth:  Layout.preferredHeight
                        radius:       4
                        color:        minusAngleArea.pressed ? _colorAccent : (minusAngleArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                        border.color: minusAngleArea.containsMouse ? _colorAccent : _colorBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text:  "−"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.bold: true
                            color: _colorTextPrimary
                        }

                        MouseArea {
                            id:          minusAngleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                var v = missionItem.gridAngle.value - 1
                                if (v < 0) v = 359
                                missionItem.gridAngle.value = v
                            }
                        }
                    }

                    // Value box
                    FactTextField {
                        id:                  angleField
                        Layout.fillWidth:    true
                        Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                        Layout.alignment:    Qt.AlignVCenter
                        fact:                missionItem.gridAngle
                        showUnits:           true
                        color:               _colorTextPrimary
                        placeholderText:     ""
                        horizontalAlignment: Qt.AlignHCenter

                        background: Rectangle {
                            color:        angleField.activeFocus ? _colorBgTertiary : _colorBgSecondary
                            border.color: angleField.activeFocus ? _colorAccent : _colorBorder
                            border.width: angleField.activeFocus ? 2 : 1
                            radius:       4
                        }
                    }

                    // + button
                    Rectangle {
                        Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                        Layout.preferredWidth:  Layout.preferredHeight
                        radius:       4
                        color:        plusAngleArea.pressed ? _colorAccent : (plusAngleArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                        border.color: plusAngleArea.containsMouse ? _colorAccent : _colorBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text:  "+"
                            font.pointSize: ScreenTools.mediumFontPointSize
                            font.bold: true
                            color: _colorTextPrimary
                        }

                        MouseArea {
                            id:           plusAngleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                var v = missionItem.gridAngle.value + 1
                                if (v > 359) v = 0
                                missionItem.gridAngle.value = v
                            }
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
                    
                    QGCLabel {
                        text:           qsTr("Indentation / Turnaround dist")
                        color:          _colorTextSecondary
                        font.pointSize: ScreenTools.smallFontPointSize
                        font.bold:      true
                    }

                    // --- Corner Adjustment Mode Selection ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing:          4
                        
                        Repeater {
                            model: [
                                { label: qsTr("Both"),   mode: 0 },
                                { label: qsTr("Entry"),  mode: 1 },
                                { label: qsTr("Exit"),   mode: 2 }
                            ]
                            
                            delegate: Rectangle {
                                Layout.fillWidth:  true
                                Layout.preferredHeight: 28
                                radius:            14
                                color:             missionItem.adjustmentMode === modelData.mode ? _colorAccent : _colorBgTertiary
                                border.color:      missionItem.adjustmentMode === modelData.mode ? _colorAccent : _colorBorder
                                border.width:      1
                                opacity:           parent.enabled ? 1.0 : 0.5
                                
                                QGCLabel {
                                    anchors.centerIn: parent
                                    text:             modelData.label
                                    font.pointSize:   ScreenTools.smallFontPointSize
                                    font.bold:        true
                                    color:            missionItem.adjustmentMode === modelData.mode ? "white" : _colorTextPrimary
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked:    missionItem.adjustmentMode = modelData.mode
                                }
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent:  _volumeSlider
                        property var targetFact: missionItem.turnAroundDistance
                        onTargetFactChanged: if (item) item.fact = targetFact
                        onLoaded:            if (item) item.fact = targetFact
                    }
                    
                    // --- Boundary Indentation (Margin) ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing:          _margin
                        
                        QGCLabel {
                            text:           qsTr("Boundary Indentation")
                            color:          _colorTextSecondary
                            font.pointSize: ScreenTools.smallFontPointSize
                            font.bold:      true
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 0
                            
                            // Pill-style control
                            Rectangle {
                                width:  160
                                height: 36
                                radius: 18
                                color:  _colorBgTertiary
                                border.color: _colorBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    spacing: 0

                                    // Minus Button
                                    Rectangle {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 32
                                        radius: 16
                                        color: _indMinusArea.pressed ? _colorAccent : "transparent"
                                        QGCLabel { anchors.centerIn: parent; text: "−"; font.bold: true; color: _colorTextPrimary }
                                        MouseArea {
                                            id: _indMinusArea; anchors.fill: parent
                                            onClicked: missionItem.boundaryIndentation = missionItem.boundaryIndentation - 0.5
                                        }
                                    }

                                    // Value Display
                                    QGCLabel {
                                        Layout.fillWidth: true
                                        text:             missionItem.boundaryIndentation.toFixed(1) + "m"
                                        color:            _colorTextPrimary
                                        font.bold:        true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Plus Button
                                    Rectangle {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 32
                                        radius: 16
                                        color: _indPlusArea.pressed ? _colorAccent : "transparent"
                                        QGCLabel { anchors.centerIn: parent; text: "+"; font.bold: true; color: _colorTextPrimary }
                                        MouseArea {
                                            id: _indPlusArea; anchors.fill: parent
                                            onClicked: missionItem.boundaryIndentation = missionItem.boundaryIndentation + 0.5
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- Obstacle Clearance (Indent) ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing:          _margin
                        
                        QGCLabel {
                            text:           qsTr("Obstacle Margin")
                            color:          _colorTextSecondary
                            font.pointSize: ScreenTools.smallFontPointSize
                            font.bold:      true
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 0
                            
                            // Pill-style control
                            Rectangle {
                                width:  160
                                height: 36
                                radius: 18
                                color:  _colorBgTertiary
                                border.color: _colorBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    spacing: 0

                                    // Minus Button
                                    Rectangle {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 32
                                        radius: 16
                                        color: _obsMinusArea.pressed ? _colorAccent : "transparent"
                                        QGCLabel { anchors.centerIn: parent; text: "−"; font.bold: true; color: _colorTextPrimary }
                                        MouseArea {
                                            id: _obsMinusArea; anchors.fill: parent
                                            onClicked: missionItem.obstacleIndentation = missionItem.obstacleIndentation - 0.5
                                        }
                                    }

                                    // Value Display
                                    QGCLabel {
                                        Layout.fillWidth: true
                                        text:             missionItem.obstacleIndentation.toFixed(1) + "m"
                                        color:            _colorTextPrimary
                                        font.bold:        true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Plus Button
                                    Rectangle {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 32
                                        radius: 16
                                        color: _obsPlusArea.pressed ? _colorAccent : "transparent"
                                        QGCLabel { anchors.centerIn: parent; text: "+"; font.bold: true; color: _colorTextPrimary }
                                        MouseArea {
                                            id: _obsPlusArea; anchors.fill: parent
                                            onClicked: missionItem.obstacleIndentation = missionItem.obstacleIndentation + 0.5
                                        }
                                    }
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
                    font.pointSize: ScreenTools.smallFontPointSize
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
                                QGCLabel { text: qsTr("Line Width"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
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
                                QGCLabel { text: qsTr("Spacing"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
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
                            QGCLabel { text: qsTr("Grid Color"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
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
                    font.pointSize: ScreenTools.smallFontPointSize
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
                            QGCLabel { text: qsTr("Border Width"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
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
                            QGCLabel { text: qsTr("Interior Opacity"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
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
                            QGCLabel { text: qsTr("Obstacle Color"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
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

