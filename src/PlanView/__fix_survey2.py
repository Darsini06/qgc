import sys

with open('SurveyItemEditor.qml', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Keep lines 1-144 (index 0..143) and after the section (index 292..)
before = lines[:144]   # lines 1-144
after  = lines[292:]   # from the closing brace of the section onwards

new_section = '''                // --- Indentation / Turnaround Section ---
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
                            font.pointSize: ScreenTools.smallFontPointSize
                            font.bold:      true
                            Layout.fillWidth: true
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
                                width: 20; height: 20; radius: 10
                                color: "transparent"; border.color: _colorSuccess; border.width: 1.5
                                Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: _linkIndentation ? _colorSuccess : "transparent" }
                                MouseArea { anchors.fill: parent; onClicked: _linkIndentation = !_linkIndentation }
                            }
                            QGCLabel { text: qsTr("Choose all"); color: _colorSuccess; font.pointSize: ScreenTools.defaultFontPointSize }
                        }

                        // Field graphic
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 160; height: 100; color: "#1a1a1a"; border.color: "#444444"; border.width: 1; radius: 4
                            Row { anchors.centerIn: parent; spacing: 8; Repeater { model: 10; Rectangle { width: 1; height: 60; color: "#444444" } } }
                            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 3; color: (_linkIndentation || _indentSideIndex === 0) ? _colorSuccess : "transparent" }
                            Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: (_linkIndentation || _indentSideIndex === 1) ? _colorSuccess : "transparent" }
                            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 3; color: (_linkIndentation || _indentSideIndex === 2) ? _colorSuccess : "transparent" }
                            Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; color: (_linkIndentation || _indentSideIndex === 3) ? _colorSuccess : "transparent" }
                            Repeater { model: 4; Rectangle { width: 6; height: 6; radius: 3; color: "#3498db"; x: (index % 2 === 0) ? -3 : parent.width - 3; y: (index < 2) ? -3 : parent.height - 3 } }
                        }

                        // Altitude-style +/- for Boundary Indentation
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            QGCLabel { text: qsTr("Boundary Indentation"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelWidth / 1.5
                                // Minus
                                Rectangle {
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    radius: 4
                                    color:  _indBMinus.pressed ? _colorAccent : (_indBMinus.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                                    border.color: _indBMinus.containsMouse ? _colorAccent : _colorBorder
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: "\\u2212"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }
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
                                // Value box (fills width like Altitude)
                                Rectangle {
                                    Layout.fillWidth:       true
                                    Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                    radius: 4
                                    color:  _colorBgSecondary
                                    border.color: _colorBorder
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
                                    color:  _indBPlus.pressed ? _colorAccent : (_indBPlus.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                                    border.color: _indBPlus.containsMouse ? _colorAccent : _colorBorder
                                    border.width: 1
                                    QGCLabel { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }
                                    MouseArea {
                                        id: _indBPlus; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            var props = ["boundaryIndentationTop","boundaryIndentationRight","boundaryIndentationBottom","boundaryIndentationLeft"]
                                            if (_linkIndentation) {
                                                missionItem.boundaryIndentationTop    = Math.min(10.0, missionItem.boundaryIndentationTop    + 0.5)
                                                missionItem.boundaryIndentationBottom = Math.min(10.0, missionItem.boundaryIndentationBottom + 0.5)
                                                missionItem.boundaryIndentationLeft   = Math.min(10.0, missionItem.boundaryIndentationLeft   + 0.5)
                                                missionItem.boundaryIndentationRight  = Math.min(10.0, missionItem.boundaryIndentationRight  + 0.5)
                                            } else {
                                                missionItem[props[_indentSideIndex]] = Math.min(10.0, missionItem[props[_indentSideIndex]] + 0.5)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Previous / Next
                        RowLayout {
                            Layout.fillWidth: true
                            spacing:          ScreenTools.defaultFontPixelWidth
                            visible:          !_linkIndentation
                            QGCButton { Layout.fillWidth: true; text: qsTr("Previous"); onClicked: _indentSideIndex = (_indentSideIndex + 3) % 4 }
                            QGCButton { Layout.fillWidth: true; text: qsTr("Next");     onClicked: _indentSideIndex = (_indentSideIndex + 1) % 4 }
                        }
                    }

                    // Obstacle Margin - altitude-style
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        QGCLabel { text: qsTr("Obstacle Margin"); font.pointSize: ScreenTools.smallFontPointSize; color: _colorTextSecondary }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth / 1.5
                            Rectangle {
                                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                Layout.preferredWidth:  Layout.preferredHeight
                                radius: 4
                                color:  _obsMinus.pressed ? _colorAccent : (_obsMinus.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                                border.color: _obsMinus.containsMouse ? _colorAccent : _colorBorder
                                border.width: 1
                                QGCLabel { anchors.centerIn: parent; text: "\\u2212"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }
                                MouseArea { id: _obsMinus; anchors.fill: parent; hoverEnabled: true; onClicked: missionItem.obstacleIndentation = Math.max(0, missionItem.obstacleIndentation - 0.5) }
                            }
                            Rectangle {
                                Layout.fillWidth:       true
                                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                radius: 4
                                color:  _colorBgSecondary
                                border.color: _colorBorder
                                border.width: 1
                                QGCLabel { anchors.centerIn: parent; text: missionItem.obstacleIndentation.toFixed(1); color: _colorTextPrimary; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                            }
                            Rectangle {
                                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                                Layout.preferredWidth:  Layout.preferredHeight
                                radius: 4
                                color:  _obsPlus.pressed ? _colorAccent : (_obsPlus.containsMouse ? _colorBgTertiary : _colorBgSecondary)
                                border.color: _obsPlus.containsMouse ? _colorAccent : _colorBorder
                                border.width: 1
                                QGCLabel { anchors.centerIn: parent; text: "+"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: _colorTextPrimary }
                                MouseArea { id: _obsPlus; anchors.fill: parent; hoverEnabled: true; onClicked: missionItem.obstacleIndentation = Math.min(5.0, missionItem.obstacleIndentation + 0.5) }
                            }
                        }
                    }
                }
'''

result = before + [new_section] + after

with open('SurveyItemEditor.qml', 'w', encoding='utf-8') as f:
    f.writelines(result)

print(f"Done. Total lines: {len(result)}")
