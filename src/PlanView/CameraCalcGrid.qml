import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

// Camera calculator "Grid" section for mission item editors
Column {
    spacing: _margin

    property var    cameraCalc
    property bool   vehicleFlightIsFrontal:         true
    property string distanceToSurfaceLabel
    property string frontalDistanceLabel
    property string sideDistanceLabel

    property real   _margin:            ScreenTools.defaultFontPixelWidth / 2
    property real   _fieldWidth:        ScreenTools.defaultFontPixelWidth * 10.5
    property var    _cameraList:        [ ]
    property var    _vehicle:           QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property var    _vehicleCameraList: _vehicle ? _vehicle.staticCameraList : []
    property bool   _cameraComboFilled: false

    readonly property int _gridTypeManual:       0
    readonly property int _gridTypeCustomCamera: 1
    readonly property int _gridTypeCamera:       2

    // ── Shared theme colors ───────────────────────────────────────────────
    readonly property color _colorBgSecondary:   Qt.rgba(0, 0, 0, 0.40)
    readonly property color _colorBgTertiary:    Qt.rgba(0, 0, 0, 0.40)
    readonly property color _colorBorder:        "#3e3e4a"
    readonly property color _colorAccent:        "#000000"
    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#ffffff"

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // ── Reusable volume-slider component ──────────────────────────────────
    Component {
        id: volumeSliderComponent

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth / 1.5
            property var  fact:    null
            property bool enabled: true

            // − button
            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       4
                color:        minusArea.pressed ? _colorAccent : (minusArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: minusArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1
                opacity:      parent.enabled ? 1.0 : 0.4

                QGCLabel {
                    anchors.centerIn: parent
                    text: "−"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true
                    color: _colorTextPrimary
                }

                MouseArea {
                    id: minusArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled:      parent.parent.enabled
                    onClicked: {
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1
                            parent.parent.fact.value -= step
                        }
                    }
                }
            }

            // Value box (no placeholder text)
            FactTextField {
                id: factField
                Layout.fillWidth:       true
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment:       Qt.AlignVCenter
                fact:                   parent.fact
                showUnits:              true
                enabled:                parent.enabled
                color:                  _colorTextPrimary
                placeholderText:        ""
                horizontalAlignment:    Qt.AlignHCenter
                background: Rectangle {
                    color:        factField.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: factField.activeFocus ? _colorAccent : _colorBorder
                    border.width: factField.activeFocus ? 2 : 1
                    radius:       4
                    opacity:      factField.enabled ? 1.0 : 0.4
                }
            }

            // + button
            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       4
                color:        plusArea.pressed ? _colorAccent : (plusArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: plusArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1
                opacity:      parent.enabled ? 1.0 : 0.4

                QGCLabel {
                    anchors.centerIn: parent
                    text: "+"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true
                    color: _colorTextPrimary
                }

                MouseArea {
                    id: plusArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled:      parent.parent.enabled
                    onClicked: {
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1
                            parent.parent.fact.value += step
                        }
                    }
                }
            }
        }
    }

    // ── Camera-spec UI (overlap etc.) ─────────────────────────────────────
    Column {
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        _margin
        visible:        !cameraCalc.isManualCamera

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        _margin
            Item { Layout.fillWidth: true }
            QGCLabel {
                Layout.preferredWidth: _root._fieldWidth
                text: qsTr("Front Lap")
                color: _colorTextPrimary
            }
            QGCLabel {
                Layout.preferredWidth: _root._fieldWidth
                text: qsTr("Side Lap")
                color: _colorTextPrimary
            }
        }

        RowLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            spacing:        _margin
            QGCLabel {
                text: qsTr("Overlap")
                Layout.fillWidth: true
                color: _colorTextPrimary
            }
            FactTextField {
                Layout.preferredWidth: _root._fieldWidth
                fact: cameraCalc.frontalOverlap
                color: _colorTextPrimary
                placeholderText: ""
                background: Rectangle {
                    color:        parent.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: parent.activeFocus ? _colorAccent : _colorBorder
                    border.width: parent.activeFocus ? 2 : 1
                    radius:       4
                }
            }
            FactTextField {
                Layout.preferredWidth: _root._fieldWidth
                fact: cameraCalc.sideOverlap
                color: _colorTextPrimary
                placeholderText: ""
                background: Rectangle {
                    color:        parent.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: parent.activeFocus ? _colorAccent : _colorBorder
                    border.width: parent.activeFocus ? 2 : 1
                    radius:       4
                }
            }
        }

        QGCLabel {
            wrapMode:   Text.WordWrap
            text:       qsTr("Select one:")
            width:      parent.width
            color:      _colorTextSecondary
        }

        GridLayout {
            anchors.left:   parent.left
            anchors.right:  parent.right
            columnSpacing:  _margin
            rowSpacing:     _margin
            columns:        2

            QGCRadioButton {
                id:          fixedDistanceRadio
                leftPadding: 0
                text:        distanceToSurfaceLabel
                checked:     !!cameraCalc.valueSetIsDistance.value
                onClicked:   cameraCalc.valueSetIsDistance.value = 1
            }

            AltitudeFactTextField {
                fact:         cameraCalc.distanceToSurface
                altitudeMode: cameraCalc.distanceMode
                enabled:      fixedDistanceRadio.checked
                Layout.fillWidth: true
                placeholderText: ""
                color: _colorTextPrimary
                background: Rectangle {
                    color:        parent.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: parent.activeFocus ? _colorAccent : _colorBorder
                    border.width: parent.activeFocus ? 2 : 1
                    radius:       4
                    opacity: parent.enabled ? 1.0 : 0.4
                }
            }

            QGCRadioButton {
                id:          fixedImageDensityRadio
                leftPadding: 0
                text:        qsTr("Grnd Res")
                checked:     !cameraCalc.valueSetIsDistance.value
                onClicked:   cameraCalc.valueSetIsDistance.value = 0
            }

            FactTextField {
                fact:             cameraCalc.imageDensity
                enabled:          fixedImageDensityRadio.checked
                Layout.fillWidth: true
                placeholderText:  ""
                color: _colorTextPrimary
                background: Rectangle {
                    color:        parent.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: parent.activeFocus ? _colorAccent : _colorBorder
                    border.width: parent.activeFocus ? 2 : 1
                    radius:       4
                    opacity: parent.enabled ? 1.0 : 0.4
                }
            }
        }
    } // Column - Camera spec

    // ── Manual camera UI — Altitude / Trigger Dist / Spacing ─────────────
    ColumnLayout {
        anchors.left:   parent.left
        anchors.right:  parent.right
        spacing:        _margin * 1.5
        visible:        cameraCalc.isManualCamera

        // ── Altitude ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing:          _margin * 0.5

            QGCLabel {
                text:  distanceToSurfaceLabel
                color: _colorTextSecondary
                font.pointSize: ScreenTools.mediumFontPointSize
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent:  volumeSliderComponent
                property var targetFact: cameraCalc.distanceToSurface
                onTargetFactChanged: if (item) item.fact = targetFact
                onLoaded:            if (item) item.fact = targetFact
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height:      1
            color:       _colorBorder
            opacity:     0.5
        }

        // ── Trigger Distance ──────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing:          _margin * 0.5

            QGCLabel {
                text:  frontalDistanceLabel
                color: _colorTextSecondary
                font.pointSize: ScreenTools.mediumFontPointSize
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent:  volumeSliderComponent
                property var targetFact: cameraCalc.adjustedFootprintFrontal
                onTargetFactChanged: if (item) item.fact = targetFact
                onLoaded:            if (item) item.fact = targetFact
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height:      1
            color:       _colorBorder
            opacity:     0.5
        }

        // ── Side Spacing ──────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing:          _margin * 0.5

            QGCLabel {
                text:  sideDistanceLabel
                color: _colorTextSecondary
                font.pointSize: ScreenTools.mediumFontPointSize
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent:  volumeSliderComponent
                property var targetFact: cameraCalc.adjustedFootprintSide
                onTargetFactChanged: if (item) item.fact = targetFact
                onLoaded:            if (item) item.fact = targetFact
            }
        }

    } // ColumnLayout - manual camera
} // Column
