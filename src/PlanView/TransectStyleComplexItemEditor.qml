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

import MapGlobals 1.0

Rectangle {
    id:         _root
    height:     childrenRect.y + childrenRect.height + _margin
    width:      availableWidth
    color:      "#1e1e24"
    radius:     _radius

    property bool   transectAreaDefinitionComplete: true
    property string transectAreaDefinitionHelp:     _internalError
    property string transectValuesHeaderName:       _internalError
    property var    transectValuesComponent:        undefined
    property var    presetsTransectValuesComponent: undefined

    readonly property string _internalError: "Internal Error"

    property var    _missionItem:               missionItem
    property real   _margin:                    ScreenTools.defaultFontPixelWidth / 2
    property real   _fieldWidth:                ScreenTools.defaultFontPixelWidth * 10.5
    property var    _vehicle:                   QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle : QGroundControl.multiVehicleManager.offlineEditingVehicle
    property real   _cameraMinTriggerInterval:  _missionItem.cameraCalc.minTriggerInterval.rawValue
    property string _doneAdjusting:             qsTr("Done")
    property bool   _presetsAvailable:          _missionItem.presetNames.length !== 0

    // --- Theme Colors (matching GeoFence / MissionStart) ---
    readonly property color _colorBgPrimary:     "#1e1e24"
    readonly property color _colorBgSecondary:   "#282830"
    readonly property color _colorBgTertiary:    "#32323b"
    readonly property color _colorBorder:        "#3e3e4a"
    readonly property color _colorAccent:        "#301934"
    readonly property color _colorAccentLight:   "#6d3da0"
    readonly property color _colorTextPrimary:   "#ffffff"
    readonly property color _colorTextSecondary: "#8e8e93"
    readonly property color _colorDanger:        "#FF453A"
    readonly property color _colorDangerDark:    "#C42B2B"
    readonly property real  _radius:             8

    Component.onCompleted: {
        MapGlobals.acres = QGroundControl.unitsConversion.squareMetersToAppSettingsAreaUnits(missionItem.coveredArea).toFixed(2) + " " + QGroundControl.unitsConversion.appSettingsAreaUnitsString
    }

    function polygonCaptureStarted() {
        _missionItem.clearPolygon()
    }

    function polygonCaptureFinished(coordinates) {
        for (var i=0; i<coordinates.length; i++) {
            _missionItem.addPolygonCoordinate(coordinates[i])
        }
    }

    function polygonAdjustVertex(vertexIndex, vertexCoordinate) {
        _missionItem.adjustPolygonCoordinate(vertexIndex, vertexCoordinate)
    }

    function polygonAdjustStarted() { }
    function polygonAdjustFinished() { }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // --- Volume Slider Component (matches GeoFence style) ---
    Component {
        id: volumeSliderComponent

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth / 1.5
            property var fact: null

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius: 15
                color: minusArea.pressed ? _colorAccent : (minusArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: minusArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1

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
                    onClicked: {
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1
                            parent.parent.fact.value -= step
                        }
                    }
                }
            }

            Slider {
                id: factSlider
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                from: {
                    if (!parent.fact) return 0
                    if (isNaN(parent.fact.min) || parent.fact.min < -1000) return 0
                    return parent.fact.min
                }
                to: {
                    if (!parent.fact) return 100
                    if (isNaN(parent.fact.max) || parent.fact.max > 1000) return (from + 200)
                    return parent.fact.max
                }
                value:    parent.fact ? parent.fact.value : 0
                stepSize: parent.fact ? (parent.fact.increment ? parent.fact.increment : 1) : 1

                background: Rectangle {
                    x: factSlider.leftPadding
                    y: factSlider.topPadding + factSlider.availableHeight / 2 - height / 2
                    implicitWidth:  100
                    implicitHeight: 6
                    width:  factSlider.availableWidth
                    height: implicitHeight
                    radius: 3
                    color:  _colorBgTertiary

                    Rectangle {
                        width:  factSlider.visualPosition * parent.width
                        height: parent.height
                        color:  _colorAccent
                        radius: 3
                    }
                }

                handle: Rectangle {
                    x: factSlider.leftPadding + factSlider.visualPosition * (factSlider.availableWidth - width)
                    y: factSlider.topPadding + factSlider.availableHeight / 2 - height / 2
                    implicitWidth:  18
                    implicitHeight: 18
                    radius: 9
                    color:  _colorTextPrimary
                    border.color: _colorAccent
                    border.width: factSlider.pressed ? 4 : 2

                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }

                onMoved: {
                    if (parent.fact) parent.fact.value = value
                }
            }

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth:  Layout.preferredHeight
                radius: 15
                color: plusArea.pressed ? _colorAccent : (plusArea.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                border.color: plusArea.containsMouse ? _colorAccent : _colorBorder
                border.width: 1

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
                    onClicked: {
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1
                            parent.parent.fact.value += step
                        }
                    }
                }
            }

            FactTextField {
                id: factField
                Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 8
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment: Qt.AlignVCenter
                fact: parent.fact
                showUnits: true
                color: _colorTextPrimary
                placeholderText: ""
                horizontalAlignment: Qt.AlignHCenter
                background: Rectangle {
                    color:        factField.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: factField.activeFocus ? _colorAccent : _colorBorder
                    border.width: factField.activeFocus ? 2 : 1
                    radius: 15
                }
            }
        }
    }

    ColumnLayout {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.right:      parent.right

        QGCLabel {
            id:                     transectAreaDefinitionCompleteLabel
            Layout.fillWidth:       true
            wrapMode:               Text.WordWrap
            horizontalAlignment:    Text.AlignHCenter
            text:                   transectAreaDefinitionHelp
            color:                  _colorTextSecondary
            visible:                !transectAreaDefinitionComplete || _missionItem.wizardMode
        }

        ColumnLayout {
            Layout.fillWidth:   true
            spacing:            _margin
            visible:            transectAreaDefinitionComplete && !_missionItem.wizardMode

            TransectStyleComplexItemTabBar {
                id:                 tabBar
                Layout.fillWidth:   true
            }

            // ─── Grid tab ───────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          _margin
                visible:          tabBar.currentIndex === 0

                QGCLabel {
                    Layout.fillWidth: true
                    text:    qsTr("WARNING: Photo interval is below minimum interval (%1 secs) supported by camera.").arg(_cameraMinTriggerInterval.toFixed(1))
                    wrapMode: Text.WordWrap
                    color:   _colorDanger
                    visible: _missionItem.cameraShots > 0 && _cameraMinTriggerInterval !== 0 && _cameraMinTriggerInterval > _missionItem.timeBetweenShots
                }

                // Camera Calc Panel
                Rectangle {
                    Layout.fillWidth: true
                    height:   cameraCalcGridLoader.height + (_margin * 2)
                    color:    _colorBgSecondary
                    radius:   _radius
                    border.color: _colorBorder
                    border.width: 1

                    CameraCalcGrid {
                        id: cameraCalcGridLoader
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        anchors.top:    parent.top
                        anchors.margins: _margin
                        cameraCalc:         _missionItem.cameraCalc
                        vehicleFlightIsFrontal: true
                        distanceToSurfaceLabel: qsTr("Altitude")
                        frontalDistanceLabel:   qsTr("Trigger Dist")
                        sideDistanceLabel:      qsTr("Spacing")
                    }
                }

                // Transect Values Section
                Rectangle {
                    Layout.fillWidth: true
                    height:           transectSectionHeader.height
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1

                    SectionHeader {
                        id:    transectSectionHeader
                        width: parent.width
                        text:  transectValuesHeaderName
                        color: _colorTextPrimary

                        background: Rectangle {
                            color:        "transparent"
                            radius:       _radius
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           transectValuesLoader.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1
                    visible:          transectSectionHeader.checked

                    Loader {
                        id:           transectValuesLoader
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _margin
                        sourceComponent: transectValuesComponent

                        property bool forPresets: false
                    }
                }

                // Rotate Entry Point Button
                Button {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    height:           36
                    visible:          transectSectionHeader.checked

                    background: Rectangle {
                        radius: _radius
                        color: parent.pressed ? "#3d235c" : (parent.hovered ? Qt.lighter(_colorAccent, 1.15) : _colorAccent)
                        border.color: _colorAccentLight
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent

                        QGCColoredImage {
                            source:  "/resources/InstrumentValueIcons/refresh.svg"
                            height:  ScreenTools.defaultFontPixelHeight * 1.1
                            width:   height
                            color:   _colorTextPrimary
                            mipmap:  true
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            visible: true
                        }

                        Text {
                            text: qsTr("Rotate Entry Point")
                            color: _colorTextPrimary
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    onClicked: _missionItem.rotateEntryPoint()
                }

                // Statistics Section
                Rectangle {
                    Layout.fillWidth: true
                    height:           statsSectionHeader.height
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1

                    SectionHeader {
                        id:    statsSectionHeader
                        width: parent.width
                        text:  qsTr("Statistics")
                        color: _colorTextPrimary
                        background: Rectangle { color: "transparent"; radius: _radius }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           statsContent.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1
                    visible:          statsSectionHeader.checked

                    TransectStyleComplexItemStats {
                        id:              statsContent
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _margin
                    }
                }
            } // Grid Column

            // ─── Camera Tab ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height:           cameraCalcCamera.implicitHeight + (_margin * 2)
                color:            _colorBgSecondary
                radius:           _radius
                border.color:     _colorBorder
                border.width:     1
                visible:          tabBar.currentIndex === 1

                CameraCalcCamera {
                    id: cameraCalcCamera
                    anchors.left:    parent.left
                    anchors.right:   parent.right
                    anchors.top:     parent.top
                    anchors.margins: _margin
                    cameraCalc:      _missionItem.cameraCalc
                }
            }

            // ─── Terrain Tab ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height:           terrainFollow.implicitHeight + (_margin * 2)
                color:            _colorBgSecondary
                radius:           _radius
                border.color:     _colorBorder
                border.width:     1
                visible:          tabBar.currentIndex === 2

                TransectStyleComplexItemTerrainFollow {
                    id:          terrainFollow
                    anchors.left:    parent.left
                    anchors.right:   parent.right
                    anchors.top:     parent.top
                    anchors.margins: _margin
                    spacing:     _margin
                    missionItem: _missionItem
                }
            }

            // ─── Presets Tab ────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          _margin
                visible:          tabBar.currentIndex === 3

                Rectangle {
                    Layout.fillWidth: true
                    height:           presetsInnerCol.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1

                    ColumnLayout {
                        id:              presetsInnerCol
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _margin
                        spacing:         _margin

                        QGCLabel {
                            Layout.fillWidth: true
                            text:    qsTr("Presets")
                            color:   _colorTextPrimary
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        QGCComboBox {
                            id:              presetCombo
                            Layout.fillWidth: true
                            model:           _missionItem.presetNames

                            background: Rectangle {
                                implicitWidth:  ScreenTools.implicitComboBoxWidth
                                implicitHeight: ScreenTools.implicitComboBoxHeight
                                color:          _colorBgTertiary
                                radius:         8
                                border.color:   _colorBorder
                                border.width:   1
                            }

                            contentItem: Text {
                                leftPadding:  ScreenTools.defaultFontPixelWidth
                                text:         presetCombo.displayText
                                color:        _colorTextPrimary
                                font.pointSize: ScreenTools.defaultFontPointSize
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Button {
                                Layout.fillWidth: true
                                height: 36
                                enabled: _missionItem.presetNames.length != 0
                                background: Rectangle {
                                    radius: _radius
                                    color: parent.pressed ? "#3d235c" : (parent.hovered ? Qt.lighter(_colorAccent, 1.15) : _colorAccent)
                                    border.color: _colorAccentLight; border.width: 1
                                }
                                contentItem: Text {
                                    text: qsTr("Apply Preset")
                                    color: _colorTextPrimary; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: _missionItem.loadPreset(presetCombo.textAt(presetCombo.currentIndex))
                            }

                            Button {
                                Layout.fillWidth: true
                                height: 36
                                enabled: _missionItem.presetNames.length != 0
                                background: Rectangle {
                                    radius: _radius
                                    color: "transparent"
                                    border.color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorBorder)
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: qsTr("Delete Preset")
                                    color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorTextPrimary)
                                    font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: deletePresetDialog.createObject(mainWindow, { presetName: presetCombo.textAt(presetCombo.currentIndex) }).open()

                                Component {
                                    id: deletePresetDialog

                                    QGCSimpleMessageDialog {
                                        title:   qsTr("Delete Preset")
                                        text:    qsTr("Are you sure you want to delete '%1' preset?").arg(presetName)
                                        buttons: Dialog.Yes | Dialog.No

                                        property string presetName

                                        onAccepted: { _missionItem.deletePreset(presetName) }
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    height: 36
                    background: Rectangle {
                        radius: _radius
                        color: parent.pressed ? "#3d235c" : (parent.hovered ? Qt.lighter(_colorAccent, 1.15) : _colorAccent)
                        border.color: _colorAccentLight; border.width: 1
                    }
                    contentItem: Text {
                        text: qsTr("Save Settings As New Preset")
                        color: _colorTextPrimary; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: savePresetDialog.createObject(mainWindow).open()
                }

                // Presets Transect Values
                Rectangle {
                    Layout.fillWidth: true
                    height:           presetsTransectHeader.height
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1
                    visible:          !!presetsTransectValuesComponent

                    SectionHeader {
                        id:    presetsTransectHeader
                        width: parent.width
                        text:  transectValuesHeaderName
                        color: _colorTextPrimary
                        background: Rectangle { color: "transparent"; radius: _radius }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           presetsTransectLoader.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1
                    visible:          presetsTransectHeader.checked && !!presetsTransectValuesComponent

                    Loader {
                        id:              presetsTransectLoader
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _margin
                        sourceComponent: presetsTransectValuesComponent

                        property bool forPresets: true
                    }
                }

                // Stats section in presets tab
                Rectangle {
                    Layout.fillWidth: true
                    height:           presetsStatsHeader.height
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1

                    SectionHeader {
                        id:    presetsStatsHeader
                        width: parent.width
                        text:  qsTr("Statistics")
                        color: _colorTextPrimary
                        background: Rectangle { color: "transparent"; radius: _radius }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:           presetsStats.implicitHeight + (_margin * 2)
                    color:            _colorBgSecondary
                    radius:           _radius
                    border.color:     _colorBorder
                    border.width:     1
                    visible:          presetsStatsHeader.checked

                    TransectStyleComplexItemStats {
                        id:              presetsStats
                        anchors.left:    parent.left
                        anchors.right:   parent.right
                        anchors.top:     parent.top
                        anchors.margins: _margin
                    }
                }
            } // Presets Column
        } // Top level Column

        Component {
            id: savePresetDialog

            QGCPopupDialog {
                id:      popupDialog
                title:   qsTr("Save Preset")
                buttons: Dialog.Save | Dialog.Cancel

                onAccepted: {
                    if (presetNameField.text != "") {
                        _missionItem.savePreset(presetNameField.text.trim())
                    } else {
                        preventClose = true
                    }
                }

                ColumnLayout {
                    width:   ScreenTools.defaultFontPixelWidth * 30
                    spacing: ScreenTools.defaultFontPixelHeight

                    QGCLabel {
                        Layout.fillWidth: true
                        text:    qsTr("Save the current settings as a named preset.")
                        wrapMode: Text.WordWrap
                    }

                    QGCLabel {
                        text: qsTr("Preset Name")
                    }

                    QGCTextField {
                        id:               presetNameField
                        Layout.fillWidth: true
                        placeholderText:  qsTr("Enter preset name")

                        Component.onCompleted: validateText(presetNameField.text)
                        onTextChanged:         validateText(text)

                        function validateText(text) {
                            if (text.trim() === "") {
                                nameError.text = qsTr("Preset name cannot be blank.")
                                popupDialog.acceptButtonEnabled = false
                            } else if (text.includes("/")) {
                                nameError.text = qsTr("Preset name cannot include the \"/\" character.")
                                popupDialog.acceptButtonEnabled = false
                            } else {
                                nameError.text = ""
                                popupDialog.acceptButtonEnabled = true
                            }
                        }
                    }

                    QGCLabel {
                        id:               nameError
                        Layout.fillWidth: true
                        wrapMode:         Text.WordWrap
                        color:            QGroundControl.globalPalette.warningText
                        visible:          text !== ""
                    }
                }
            }
        }
    }
}
