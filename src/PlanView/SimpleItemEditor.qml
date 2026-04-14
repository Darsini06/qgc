import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.Palette

// Editor for Simple mission items
Rectangle {
    width:  availableWidth
    height: editorColumn.height + (_margin * 2)
    color:  "transparent"
    radius: _radius

    property real   _panelRadius:   8
    property real   _fieldRadius:   4
    property color  _panelColor:    "#282830"
    property color  _panelBorder:   "#3e3e4a"
    property color  _fieldColor:    "#32323b"
    property color  _fieldBorder:   "#3e3e4a"
    property color  _headingColor:  "#ffffff"
    property color  _labelColor:    "#ffffff"
    property color  _valueColor:    "#ffffff"
    property color  _unitColor:     "#8e8e93"
    property color  _colorAccent:   "#3d3a41ff"

    property bool _specifiesAltitude:       missionItem.specifiesAltitude
    property real _margin:                  ScreenTools.defaultFontPixelHeight / 2
    property real _altRectMargin:           ScreenTools.defaultFontPixelWidth / 2
    property var  _controllerVehicle:       missionItem.masterController.controllerVehicle
    property int  _globalAltMode:           missionItem.masterController.missionController.globalAltitudeMode
    property bool _globalAltModeIsMixed:    _globalAltMode == QGroundControl.AltitudeModeMixed
    property real _radius:                  ScreenTools.defaultFontPixelWidth / 2

    function updateAltitudeModeText() {
        if (missionItem.altitudeMode === QGroundControl.AltitudeModeRelative) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeRelative)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeAbsolute) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeAbsolute)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeCalcAboveTerrain) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeCalcAboveTerrain)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
            altModeLabel.text = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeTerrainFrame)
        } else {
            altModeLabel.text = qsTr("Internal Error")
        }
        missionItem.wizardMode = false
    }

    Component.onCompleted: updateAltitudeModeText()

    Connections {
        target:                 missionItem
        onAltitudeModeChanged:  updateAltitudeModeText()
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Component {
        id: volumeSliderComponent

        RowLayout {
            width: parent ? parent.width : implicitWidth // Fill parent Loader
            spacing: ScreenTools.defaultFontPixelWidth * 0.7
            property var fact: null
            property color trackFillColor: _colorAccent
            property bool showMinusButton: true
            property bool showPlusButton: true

            Rectangle {
                visible: parent.showMinusButton
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth: Layout.preferredHeight
                radius: 4
                color: minusArea.pressed ? _colorAccent : (minusArea.containsMouse ? _fieldColor : _panelColor)
                border.color: minusArea.containsMouse ? _colorAccent : _panelBorder
                border.width: 1

                QGCLabel {
                    anchors.centerIn: parent
                    text: "−"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true
                    color: _headingColor
                }

                MouseArea {
                    id: minusArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1;
                            parent.parent.fact.value -= step;
                        }
                    }
                }
            }

            FactTextField {
                id: factField
                Layout.fillWidth: true
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment: Qt.AlignVCenter
                fact: parent.fact
                showUnits: true
                color: _valueColor
                horizontalAlignment: Qt.AlignHCenter
                background: Rectangle {
                    color: factField.activeFocus ? _fieldColor : _panelColor
                    border.color: factField.activeFocus ? _colorAccent : _panelBorder
                    border.width: factField.activeFocus ? 2 : 1
                    radius: 4
                }
            }

            Rectangle {
                visible: parent.showPlusButton
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth: Layout.preferredHeight
                radius: 4
                color: plusArea.pressed ? _colorAccent : (plusArea.containsMouse ? _fieldColor : _panelColor)
                border.color: plusArea.containsMouse ? _colorAccent : _panelBorder
                border.width: 1

                QGCLabel {
                    anchors.centerIn: parent
                    text: "+"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true
                    color: _headingColor
                }

                MouseArea {
                    id: plusArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (parent.parent.fact) {
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1;
                            parent.parent.fact.value += step;
                        }
                    }
                }
            }
        }
    }

    Column {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin

        QGCLabel {
            width:          parent.width
            wrapMode:       Text.WordWrap
            font.pointSize: ScreenTools.smallFontPointSize
            text:           missionItem.rawEdit ?
                                qsTr("Provides advanced access to all commands/parameters. Be very careful!") :
                                missionItem.commandDescription
            color:          _labelColor
        }

        ColumnLayout {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin
            visible:            missionItem.isTakeoffItem && missionItem.wizardMode // Hack special case for takeoff item

            QGCLabel {
                text:               qsTr("Move '%1' %2 to the %3 location. %4")
                .arg(_controllerVehicle.vtol ? qsTr("T") : qsTr("T"))
                .arg(_controllerVehicle.vtol ? qsTr("Transition Direction") : qsTr("Takeoff"))
                .arg(_controllerVehicle.vtol ? qsTr("desired") : qsTr("climbout"))
                .arg(_controllerVehicle.vtol ? (qsTr("Ensure distance from launch to transition direction is far enough to complete transition.")) : "")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCLabel {
                text:               qsTr("Ensure clear of obstacles and into the wind.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCButton {
                text:               qsTr("Done")
                Layout.fillWidth:   true
                visible:            !initialClickLabel.visible
                onClicked: {
                    missionItem.wizardMode = false
                }
            }

            QGCLabel {
                id:                 initialClickLabel
                text:               missionItem.launchTakeoffAtSameLocation ?
                                        qsTr("Click in map to set planned Takeoff location.") :
                                        qsTr("Click in map to set planned Launch location.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            missionItem.isTakeoffItem && !missionItem.launchCoordinate.isValid
            }
        }

        Column {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _altRectMargin
            visible:            !missionItem.wizardMode

            ColumnLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        0
                visible:        _specifiesAltitude

                QGCLabel {
                    Layout.fillWidth:   true
                    wrapMode:           Text.WordWrap
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               qsTr("Altitude below specifies the approximate altitude of the ground. Normally 0 for landing back at original launch location.")
                    visible:            missionItem.isLandCommand
                }

                MouseArea {
                    Layout.preferredWidth:  childrenRect.width
                    Layout.preferredHeight: childrenRect.height

                    onClicked: {
                        if (_globalAltModeIsMixed) {
                            var removeModes = []
                            var updateFunction = function(altMode){ missionItem.altitudeMode = altMode }
                            if (!_controllerVehicle.supportsTerrainFrame) {
                                removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                            }
                            if (!QGroundControl.corePlugin.options.showMissionAbsoluteAltitude && missionItem.altitudeMode !== QGroundControl.AltitudeModeAbsolute) {
                                removeModes.push(QGroundControl.AltitudeModeAbsolute)
                            }
                            removeModes.push(QGroundControl.AltitudeModeMixed)
                            altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
                        }
                    }

                    RowLayout {
                        spacing: _altRectMargin

                        QGCLabel {
                            Layout.alignment:   Qt.AlignBaseline
                            text:               qsTr("Altitude")
                            font.pointSize:     ScreenTools.smallFontPointSize
                            color:              _labelColor
                        }
                        QGCLabel {
                            id:                 altModeLabel
                            Layout.alignment:   Qt.AlignBaseline
                            visible:            _globalAltMode !== QGroundControl.AltitudeModeRelative
                        }
                        QGCColoredImage {
                            height:     ScreenTools.defaultFontPixelHeight / 2
                            width:      height
                            source:     "/res/DropArrow.svg"
                            color:      _unitColor
                            visible:    _globalAltModeIsMixed
                        }
                    }
                }

                Loader {
                    Layout.fillWidth:   true
                    sourceComponent:    volumeSliderComponent
                    property var targetFact: missionItem.altitude
                    onTargetFactChanged: if (item) item.fact = targetFact
                    onLoaded: {
                        if (item) {
                            item.fact = targetFact
                            item.trackFillColor = _colorAccent
                            item.showMinusButton = true
                            item.showPlusButton = true
                        }
                    }
                }

                QGCLabel {
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               qsTr("Actual AMSL alt sent: %1 %2").arg(missionItem.amslAltAboveTerrain.valueString).arg(missionItem.amslAltAboveTerrain.units)
                    color:              _unitColor
                    visible:            missionItem.altitudeMode === QGroundControl.AltitudeModeCalcAboveTerrain
                }
            }

            ColumnLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        _margin

                Repeater {
                    model: missionItem.comboboxFacts

                    ColumnLayout {
                        Layout.fillWidth:   true
                        spacing:            0

                        QGCLabel {
                            font.pointSize: ScreenTools.smallFontPointSize
                            text:           object.name
                            color:          _labelColor
                            visible:        object.name !== ""
                        }

                        FactComboBox {
                            Layout.fillWidth:   true
                            indexModel:         false
                            model:              object.enumStrings
                            fact:               object
                        }
                    }
                }
            }

            GridLayout {
                anchors.left:   parent.left
                anchors.right:  parent.right
                flow:           GridLayout.TopToBottom
                rows:           missionItem.textFieldFacts.count +
                                missionItem.nanFacts.count +
                                (missionItem.speedSection.available ? 1 : 0)
                columns:        2

                Repeater {
                    model: missionItem.textFieldFacts

                    QGCLabel { text: object.name; color: _labelColor }
                }

                Repeater {
                    model: missionItem.nanFacts

                    QGCCheckBox {
                        text:           object.name
                        checked:        !isNaN(object.rawValue)
                        onClicked:      object.rawValue = checked ? 0 : NaN
                        textColor:      _labelColor
                    }
                }

                QGCCheckBox {
                    id:         flightSpeedCheckbox
                    text:       qsTr("Flight Speed")
                    checked:    missionItem.speedSection.specifyFlightSpeed
                    onClicked:  missionItem.speedSection.specifyFlightSpeed = checked
                    visible:    missionItem.speedSection.available
                    textColor:  _labelColor
                }


                Repeater {
                    model: missionItem.textFieldFacts

                    Loader {
                        Layout.fillWidth:   true
                        sourceComponent:    volumeSliderComponent
                        property var targetFact: object
                        enabled:            !object.readOnly
                        onTargetFactChanged: if (item) item.fact = targetFact
                        onLoaded: {
                            if (item) {
                                item.fact = targetFact
                            }
                        }
                    }
                }

                Repeater {
                    model: missionItem.nanFacts

                    Loader {
                        Layout.fillWidth:   true
                        sourceComponent:    volumeSliderComponent
                        property var targetFact: object
                        enabled:            !isNaN(object.rawValue)
                        onTargetFactChanged: if (item) item.fact = targetFact
                        onLoaded: {
                            if (item) {
                                item.fact = targetFact
                            }
                        }
                    }
                }

                Loader {
                    Layout.fillWidth:   true
                    sourceComponent:    volumeSliderComponent
                    property var targetFact: missionItem.speedSection.flightSpeed
                    enabled:            flightSpeedCheckbox.checked
                    visible:            missionItem.speedSection.available
                    onTargetFactChanged: if (item) item.fact = targetFact
                    onLoaded: {
                        if (item) {
                            item.fact = targetFact
                        }
                    }
                }
            }

            CameraSection {
                checked:    missionItem.cameraSection.settingsSpecified
                visible:    missionItem.cameraSection.available
            }
        }
    }
}
