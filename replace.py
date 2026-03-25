import codecs

file_path = "d:/QT/QGC/src/FlightMap/Widgets/PhotoVideoControl.qml"

new_ui = """                Column {
                    spacing: 0
                    width:  35 * ScreenTools.defaultFontPixelWidth

                    Rectangle {
                        width:          parent.width
                        height:         settingsCol.height
                        color:          "transparent"
                        border.color:   "#E2E8F0"
                        border.width:   1
                        radius:         8
                        clip:           true

                        Column {
                            id:         settingsCol
                            width:      parent.width
                            spacing:    0

                            // 1. Camera
                            Rectangle {
                                width: parent.width; height: 50; visible: _multipleMavlinkCameras
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Camera"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: _cameraManager.cameraLabels
                                        currentIndex: _cameraManager.currentCamera
                                        onActivated: (index) => { _cameraManager.currentCamera = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 2. Video Stream
                            Rectangle {
                                width: parent.width; height: 50; visible: _multipleMavlinkCameraStreams
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Video Stream"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: _camera.streamLabels
                                        currentIndex: _camera.currentStream
                                        onActivated: (index) => { _camera.currentStream = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 3. Thermal View Mode
                            Rectangle {
                                width: parent.width; height: 50; visible: _camera.thermalStreamInstance
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Thermal View Mode"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: [ qsTr("Off"), qsTr("Blend"), qsTr("Full"), qsTr("Picture In Picture") ]
                                        currentIndex: _camera.thermalMode
                                        onActivated: (index) => { _camera.thermalMode = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 4. Blend Opacity
                            Rectangle {
                                width: parent.width; height: 50; visible: _camera.thermalStreamInstance && _camera.thermalMode === MavlinkCameraControl.THERMAL_BLEND
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Blend Opacity"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCSlider {
                                        Layout.preferredWidth: 150
                                        to: 100; from: 0; live: true; value: _camera.thermalOpacity
                                        onValueChanged: _camera.thermalOpacity = value
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 5. Active Settings Repeater
                            Repeater {
                                model: _camera.activeSettings
                                Rectangle {
                                    width: parent.width; height: 50
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 15
                                        property var    _fact:      _camera.getFact(modelData)
                                        property bool   _isBool:    _fact.typeIsBool
                                        property bool   _isCombo:   !_isBool && _fact.enumStrings.length > 0
                                        property bool   _isSlider:  _fact && !isNaN(_fact.increment)
                                        property bool   _isEdit:    !_isBool && !_isSlider && _fact.enumStrings.length < 1

                                        QGCLabel { text: parent._fact ? parent._fact.shortDescription : ""; Layout.fillWidth: true; color: "#2C3E50"; font.bold: true; elide: Text.ElideRight }

                                        FactComboBox {
                                            Layout.preferredWidth: 150; sizeToContents: true; fact: parent._fact; indexModel: false; visible: parent._isCombo
                                        }
                                        FactTextField {
                                            Layout.preferredWidth: 150; fact: parent._fact; visible: parent._isEdit
                                        }
                                        QGCSlider {
                                            Layout.preferredWidth: 150; to: parent._fact.max; from: parent._fact.min; stepSize: parent._fact.increment; visible: parent._isSlider; live: false
                                            property bool initialized: false
                                            onValueChanged: { if (initialized) parent._fact.value = value }
                                            Component.onCompleted: { value = parent._fact.value; initialized = true }
                                        }
                                        QGCSwitch {
                                            checked: parent._fact ? parent._fact.value : false; visible: parent._isBool
                                            onClicked: parent._fact.value = checked ? 1 : 0
                                        }
                                    }
                                    Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                                }
                            }

                            // 6. Photo Mode
                            Rectangle {
                                width: parent.width; height: 50; visible: _camera.capturesPhotos
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Photo Mode"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCComboBox {
                                        Layout.preferredWidth: 150
                                        model: [ qsTr("Single"), qsTr("Time Lapse") ]
                                        currentIndex: _camera.photoCaptureMode
                                        onActivated: (index) => { _camera.photoCaptureMode = index }
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 7. Photo Interval
                            Rectangle {
                                width: parent.width; height: 50; visible: _camera.capturesPhotos && _camera.photoCaptureMode === MavlinkCameraControl.PHOTO_CAPTURE_TIMELAPSE
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Photo Interval (sec)"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCSlider {
                                        Layout.preferredWidth: 150
                                        to: 60; from: 1; stepSize: 1; live: true; value: _camera.photoLapse; displayValue: true
                                        onValueChanged: _camera.photoLapse = value
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 8. Video Grid Lines
                            Rectangle {
                                width: parent.width; height: 50; visible: _camera.hasVideoStream
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Video Grid Lines"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCSwitch {
                                        checked: _videoSettings.gridLines.rawValue
                                        onClicked: _videoSettings.gridLines.rawValue = checked ? 1 : 0
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 9. Video Screen Fit
                            Rectangle {
                                width: parent.width; height: 50; visible: _camera.hasVideoStream
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Video Screen Fit"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    FactComboBox {
                                        Layout.preferredWidth: 150
                                        fact: _videoSettings.videoFit
                                        indexModel: false
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom }
                            }

                            // 10. Reset Camera Defaults
                            Rectangle {
                                width: parent.width; height: 50
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Reset Camera Defaults"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCButton {
                                        text: qsTr("Reset")
                                        Layout.preferredWidth: 100
                                        onClicked: resetPrompt.open()
                                    }
                                }
                                MessageDialog {
                                    id: resetPrompt
                                    title: qsTr("Reset Camera to Factory Settings")
                                    text: qsTr("Confirm resetting all settings?")
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes) { _camera.resetSettings(); resetPrompt.close() }
                                        else resetPrompt.close()
                                    }
                                }
                                Rectangle { width: parent.width; height: 1; color: "#E2E8F0"; anchors.bottom: parent.bottom; visible: _cameraStorageSupported }
                            }

                            // 11. Storage Format
                            Rectangle {
                                width: parent.width; height: 50; visible: _cameraStorageSupported
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    QGCLabel { text: qsTr("Storage"); Layout.fillWidth: true; color: "#2C3E50"; font.bold: true }
                                    QGCButton {
                                        text: qsTr("Format")
                                        Layout.preferredWidth: 100
                                        onClicked: formatPrompt.open()
                                    }
                                }
                                MessageDialog {
                                    id: formatPrompt
                                    title: qsTr("Format Camera Storage")
                                    text: qsTr("Confirm erasing all files?")
                                    buttons: MessageDialog.Yes | MessageDialog.No
                                    onButtonClicked: function (button, role) {
                                        if (button === MessageDialog.Yes) { _camera.formatCard(); formatPrompt.close() }
                                        else formatPrompt.close()
                                    }
                                }
                            }
                        }
                    }
                }"""

with codecs.open(file_path, 'r', 'utf-8') as f:
    lines = f.readlines()

output_lines = []
in_settings = False
for i, line in enumerate(lines):
    if "ColumnLayout {" in line and i == 327:
        in_settings = True
        output_lines.append(new_ui + "\n")
    elif "            }" in line and i == 584:
        in_settings = False
    elif not in_settings:
        output_lines.append(line)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.writelines(output_lines)
print("SUCCESS")
