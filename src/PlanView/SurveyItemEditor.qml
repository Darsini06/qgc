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
    transectAreaDefinitionHelp:     qsTr("Use the Polygon Tools to create the polygon which outlines your survey area.")
    transectValuesHeaderName:       qsTr("Transects")
    transectValuesComponent:        _transectValuesComponent
    presetsTransectValuesComponent: _transectValuesComponent

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property var    _missionItem:   missionItem

    // Theme palette
    readonly property color _colorBgSecondary:   "#282830"
    readonly property color _colorBgTertiary:    "#32323b"
    readonly property color _colorBorder:        "#3e3e4a"
    readonly property color _colorAccent:        "#301934"
    readonly property color _colorAccentLight:   "#6d3da0"
    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#8e8e93"
    // Placeholder text color — muted grey, NOT white
    readonly property color _colorPlaceholder:   "#5a5a6a"
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
        if (angleSlider) angleSlider.value = bestAngle
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
                        radius:       15
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
                                angleSlider.value = v
                            }
                        }
                    }

                    // Slider
                    Slider {
                        id:               angleSlider
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        from:     0
                        to:       359
                        stepSize: 1
                        live:     true

                        background: Rectangle {
                            x: angleSlider.leftPadding
                            y: angleSlider.topPadding + angleSlider.availableHeight / 2 - height / 2
                            implicitWidth: 100; implicitHeight: 6
                            width: angleSlider.availableWidth; height: implicitHeight
                            radius: 3
                            color: _colorBgTertiary

                            Rectangle {
                                width:  angleSlider.visualPosition * parent.width
                                height: parent.height
                                color:  _colorAccent
                                radius: 3
                            }
                        }

                        handle: Rectangle {
                            x: angleSlider.leftPadding + angleSlider.visualPosition * (angleSlider.availableWidth - width)
                            y: angleSlider.topPadding + angleSlider.availableHeight / 2 - height / 2
                            implicitWidth: 18; implicitHeight: 18
                            radius: 9
                            color:  _colorTextPrimary
                            border.color: _colorAccent
                            border.width: angleSlider.pressed ? 4 : 2
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                        }

                        onValueChanged:        missionItem.gridAngle.value = value
                        Component.onCompleted: value = missionItem.gridAngle.value
                    }

                    // + button
                    Rectangle {
                        Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                        Layout.preferredWidth:  Layout.preferredHeight
                        radius:       15
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
                                angleSlider.value = v
                            }
                        }
                    }

                    // Value box — grey placeholder, NO white placeholder
                    FactTextField {
                        id:                  angleField
                        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 7
                        Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                        Layout.alignment:    Qt.AlignVCenter
                        fact:                missionItem.gridAngle
                        showUnits:           true
                        color:               _colorTextPrimary
                        placeholderText:     ""
                        horizontalAlignment: Qt.AlignHCenter
                        onUpdated:           angleSlider.value = missionItem.gridAngle.value

                        background: Rectangle {
                            color:        angleField.activeFocus ? _colorBgTertiary : _colorBgSecondary
                            border.color: angleField.activeFocus ? _colorAccent : _colorBorder
                            border.width: angleField.activeFocus ? 2 : 1
                            radius:       15
                        }
                    }
                }

                // --- Optimized Alignment Button ---
                Button {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: 32
                    visible:                !_isAgri
                    
                    background: Rectangle {
                        radius: 8
                        color:  parent.pressed ? "#1E1E24" : (parent.hovered ? _colorBgTertiary : _colorBgSecondary)
                        border.color: parent.hovered ? _colorSuccess : _colorBorder
                        border.width: 1
                    }
                    
                    contentItem: RowLayout {
                        spacing: 8
                        anchors.centerIn: parent
                        QGCColoredImage {
                            source: "/resources/InstrumentValueIcons/check.svg"
                            width:  14; height: 14
                            color:  _colorSuccess
                        }
                        QGCLabel {
                            text: qsTr("Smart Path Optimization")
                            font.pixelSize: ScreenTools.smallFontPointSize
                            font.bold: true
                            color: _colorTextPrimary
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

                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder; opacity: 0.5; visible: !forPresets && !_isAgri }

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

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       15
                color:        _minArea.pressed ? _colorAccent : (_minArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: _minArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1

                Text { anchors.centerIn: parent; text: "−"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }

                MouseArea {
                    id: _minArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (parent.parent.fact) { var s = parent.parent.fact.increment ? parent.parent.fact.increment : 1; parent.parent.fact.value -= s } }
                }
            }

            Slider {
                id: _sl; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                from: { if (!parent.fact) return 0; if (isNaN(parent.fact.min) || parent.fact.min < -1000) return 0; return parent.fact.min }
                to:   { if (!parent.fact) return 100; if (isNaN(parent.fact.max) || parent.fact.max > 10000) return (from + 500); return parent.fact.max }
                value: parent.fact ? parent.fact.value : 0
                stepSize: parent.fact ? (parent.fact.increment ? parent.fact.increment : 1) : 1

                background: Rectangle {
                    x: _sl.leftPadding; y: _sl.topPadding + _sl.availableHeight / 2 - height / 2
                    implicitWidth: 100; implicitHeight: 6; width: _sl.availableWidth; height: implicitHeight; radius: 3; color: _colorBgTertiary
                    Rectangle { width: _sl.visualPosition * parent.width; height: parent.height; color: _colorAccent; radius: 3 }
                }
                handle: Rectangle {
                    x: _sl.leftPadding + _sl.visualPosition * (_sl.availableWidth - width)
                    y: _sl.topPadding + _sl.availableHeight / 2 - height / 2
                    implicitWidth: 18; implicitHeight: 18; radius: 9; color: _colorTextPrimary
                    border.color: _colorAccent; border.width: _sl.pressed ? 4 : 2
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }
                onMoved: { if (parent.fact) parent.fact.value = value }
            }

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       15
                color:        _plusArea.pressed ? _colorAccent : (_plusArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: _plusArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1

                Text { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }

                MouseArea {
                    id: _plusArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: { if (parent.parent.fact) { var s = parent.parent.fact.increment ? parent.parent.fact.increment : 1; parent.parent.fact.value += s } }
                }
            }

            FactTextField {
                id: _ftf
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 7
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
                    radius:       15
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
