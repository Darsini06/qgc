import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls

ColumnLayout {
    spacing: _margin
    visible: tabBar.currentIndex === 2

    property var missionItem

    // Theme palette
    readonly property color _colorBgSecondary:   "#282830"
    readonly property color _colorBgTertiary:    "#32323b"
    readonly property color _colorBorder:        "#3e3e4a"
    readonly property color _colorAccent:        "#301934"
    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#8e8e93"

    // ── Volume slider component ───────────────────────────────────────────
    Component {
        id: _sliderComp

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth / 1.5
            property var  fact:    null
            property bool enabled: true

            // − button
            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       15
                color:        _mA.pressed ? _colorAccent : (_mA.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: _mA.containsMouse ? _colorAccent : _colorBorder
                border.width: 1
                opacity:      parent.enabled ? 1.0 : 0.4

                Text { anchors.centerIn: parent; text: "−"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }

                MouseArea {
                    id: _mA; anchors.fill: parent; hoverEnabled: true; enabled: parent.parent.enabled
                    onClicked: { if (parent.parent.parent.fact) { var s = parent.parent.parent.fact.increment ? parent.parent.parent.fact.increment : 0.1; parent.parent.parent.fact.value -= s } }
                }
            }

            // Slider
            Slider {
                id: _sl; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; enabled: parent.enabled

                from: { if (!parent.fact) return 0; if (isNaN(parent.fact.min) || parent.fact.min < -1000) return 0; return parent.fact.min }
                to:   { if (!parent.fact) return 100; if (isNaN(parent.fact.max) || parent.fact.max > 10000) return (from + 50); return parent.fact.max }
                value: parent.fact ? parent.fact.value : 0
                stepSize: parent.fact ? (parent.fact.increment ? parent.fact.increment : 0.1) : 0.1

                background: Rectangle {
                    x: _sl.leftPadding; y: _sl.topPadding + _sl.availableHeight / 2 - height / 2
                    implicitWidth: 100; implicitHeight: 6; width: _sl.availableWidth; height: implicitHeight; radius: 3
                    color: _colorBgTertiary; opacity: _sl.enabled ? 1 : 0.4
                    Rectangle { width: _sl.visualPosition * parent.width; height: parent.height; color: _colorAccent; radius: 3 }
                }
                handle: Rectangle {
                    x: _sl.leftPadding + _sl.visualPosition * (_sl.availableWidth - width)
                    y: _sl.topPadding + _sl.availableHeight / 2 - height / 2
                    implicitWidth: 18; implicitHeight: 18; radius: 9
                    color: _colorTextPrimary; opacity: _sl.enabled ? 1 : 0.4
                    border.color: _colorAccent; border.width: _sl.pressed ? 4 : 2
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }
                onMoved: { if (parent.fact) parent.fact.value = value }
            }

            // + button
            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius:       15
                color:        _pA.pressed ? _colorAccent : (_pA.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: _pA.containsMouse ? _colorAccent : _colorBorder
                border.width: 1
                opacity:      parent.enabled ? 1.0 : 0.4

                Text { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }

                MouseArea {
                    id: _pA; anchors.fill: parent; hoverEnabled: true; enabled: parent.parent.enabled
                    onClicked: { if (parent.parent.parent.fact) { var s = parent.parent.parent.fact.increment ? parent.parent.parent.fact.increment : 0.1; parent.parent.parent.fact.value += s } }
                }
            }

            // Value box
            FactTextField {
                id: _ftf
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 7
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment:       Qt.AlignVCenter
                fact:                   parent.fact
                enabled:                parent.enabled
                showUnits:              true
                color:                  _colorTextPrimary
                placeholderText:        ""
                horizontalAlignment:    Qt.AlignHCenter
                background: Rectangle {
                    color:        _ftf.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: _ftf.activeFocus ? _colorAccent : _colorBorder
                    border.width: _ftf.activeFocus ? 2 : 1
                    radius:       15
                    opacity:      _ftf.enabled ? 1 : 0.4
                }
            }
        }
    }

    // ── Altitude Mode Selector ────────────────────────────────────────────
    QGCLabel {
        text:           qsTr("Altitude Mode")
        color:          _colorTextSecondary
        font.pointSize: ScreenTools.smallFontPointSize
    }

    Rectangle {
        Layout.fillWidth: true
        height:           altModeRow.implicitHeight + (_margin * 2)
        color:            _colorBgSecondary
        radius:           8
        border.color:     _colorBorder
        border.width:     1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                var removeModes = []
                var updateFunction = function(altMode){ missionItem.cameraCalc.distanceMode = altMode }
                // Always remove Mixed mode only — keep Terrain Frame always visible
                removeModes.push(QGroundControl.AltitudeModeMixed)
                altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
            }

            Component { id: altModeDialogComponent; AltModeDialog { } }

            RowLayout {
                id:              altModeRow
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.top:     parent.top
                anchors.margins: _margin
                spacing:         ScreenTools.defaultFontPixelWidth / 2

                QGCLabel {
                    text:  QGroundControl.altitudeModeShortDescription(missionItem.cameraCalc.distanceMode)
                    color: _colorTextPrimary
                    font.bold: true
                }
                QGCColoredImage {
                    height: ScreenTools.defaultFontPixelHeight / 2
                    width:  height
                    source: "/resources/DropArrow.svg"
                    color:  _colorTextSecondary
                }
            }
        }
    }

    // ── Terrain Follow sliders — enabled only in CalcAboveTerrain mode ────
    property bool _terrainEnabled: missionItem.cameraCalc.distanceMode === QGroundControl.AltitudeModeCalcAboveTerrain

    // ── Tolerance ─────────────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing:          _margin * 0.4
        opacity:          _terrainEnabled ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 200 } }

        QGCLabel {
            text:           qsTr("Tolerance")
            color:          _colorTextSecondary
            font.pointSize: ScreenTools.smallFontPointSize
        }

        Loader {
            Layout.fillWidth: true
            sourceComponent:  _sliderComp
            property var targetFact:    missionItem.terrainAdjustTolerance
            property bool targetEnabled: _terrainEnabled
            onTargetFactChanged:    if (item) item.fact    = targetFact
            onTargetEnabledChanged: if (item) item.enabled = targetEnabled
            onLoaded: { if (item) { item.fact = targetFact; item.enabled = targetEnabled } }
        }
    }

    // Divider
    Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder; opacity: 0.5 }

    // ── Max Climb Rate ────────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing:          _margin * 0.4
        opacity:          _terrainEnabled ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 200 } }

        QGCLabel {
            text:           qsTr("Max Climb Rate")
            color:          _colorTextSecondary
            font.pointSize: ScreenTools.smallFontPointSize
        }

        Loader {
            Layout.fillWidth: true
            sourceComponent:  _sliderComp
            property var targetFact:    missionItem.terrainAdjustMaxClimbRate
            property bool targetEnabled: _terrainEnabled
            onTargetFactChanged:    if (item) item.fact    = targetFact
            onTargetEnabledChanged: if (item) item.enabled = targetEnabled
            onLoaded: { if (item) { item.fact = targetFact; item.enabled = targetEnabled } }
        }
    }

    // Divider
    Rectangle { Layout.fillWidth: true; height: 1; color: _colorBorder; opacity: 0.5 }

    // ── Max Descent Rate ──────────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing:          _margin * 0.4
        opacity:          _terrainEnabled ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 200 } }

        QGCLabel {
            text:           qsTr("Max Descent Rate")
            color:          _colorTextSecondary
            font.pointSize: ScreenTools.smallFontPointSize
        }

        Loader {
            Layout.fillWidth: true
            sourceComponent:  _sliderComp
            property var targetFact:    missionItem.terrainAdjustMaxDescentRate
            property bool targetEnabled: _terrainEnabled
            onTargetFactChanged:    if (item) item.fact    = targetFact
            onTargetEnabledChanged: if (item) item.enabled = targetEnabled
            onLoaded: { if (item) { item.fact = targetFact; item.enabled = targetEnabled } }
        }
    }
}
