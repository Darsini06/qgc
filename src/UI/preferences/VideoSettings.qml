import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools

SettingsPage {
    id: root

    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _videoManager:              QGroundControl.videoManager
    property var    _videoSettings:             _settingsManager.videoSettings
    property string _videoSource:               _videoSettings.videoSource.rawValue
    property bool   _isGST:                     _videoManager.gstreamerEnabled
    property bool   _isStreamSource:            _videoManager.isStreamSource
    property bool   _isUDP264:                  _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:                  _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                    _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                     _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:                  _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:     _videoManager.autoStreamConfigured
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 30
    property bool   _requiresUDPPort:           _isUDP264 || _isUDP265 || _isMPEGTS

    property bool   _isNarrow:                  width < ScreenTools.defaultFontPixelWidth * 110
    property real   _innerMargin:               ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 2 : ScreenTools.defaultFontPixelWidth * 8
    property real   _maxContentWidth:           ScreenTools.defaultFontPixelWidth * 90
    property real   _contentWidth:              Math.min(width - (_innerMargin * 2), _maxContentWidth)

    ColumnLayout {
        id:                 contentLayout
        width:              _contentWidth
        spacing:            _isNarrow ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 1.5
        Layout.alignment:   Qt.AlignHCenter

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.3
            visible:          _videoSettings.videoSource.visible
        }

        // Source Dropdown
        RowLayout {
            Layout.fillWidth: true
            visible: _videoSettings.videoSource.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Source")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactComboBox {
                id: videoSourceCombo
                fact: _videoSettings.videoSource
                indexModel: false
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }

                onPressedChanged: {
                    if (pressed) {
                        popup.width = Math.max(width, ScreenTools.defaultFontPixelWidth * 40)
                        popup.x = width - popup.width
                    }
                }
            }
        }

        // RTSP URL
        RowLayout {
            Layout.fillWidth: true
            visible: _isRTSP && _videoSettings.rtspUrl.visible
            spacing: 20

            QGCLabel {
                text: qsTr("RTSP URL")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactTextField {
                fact: _videoSettings.rtspUrl
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }
            }
        }

        // TCP URL
        RowLayout {
            Layout.fillWidth: true
            visible: _isTCP && _videoSettings.tcpUrl.visible
            spacing: 20

            QGCLabel {
                text: qsTr("TCP URL")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactTextField {
                fact: _videoSettings.tcpUrl
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }
            }
        }

        // UDP Port
        RowLayout {
            Layout.fillWidth: true
            visible: _requiresUDPPort && _videoSettings.udpPort.visible
            spacing: 20

            QGCLabel {
                text: qsTr("UDP Port")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactTextField {
                fact: _videoSettings.udpPort
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }
            }
        }

        // Aspect Ratio
        RowLayout {
            Layout.fillWidth: true
            visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Aspect Ratio")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactTextField {
                fact: _videoSettings.aspectRatio
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }
            }
        }

        // Stop recording when disarmed
        RowLayout {
            Layout.fillWidth: true
            visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.disableWhenDisarmed.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Stop recording when disarmed")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillWidth: true }

            OnOffToggle {
                checked: _videoSettings.disableWhenDisarmed.rawValue
                onToggled: (val) => _videoSettings.disableWhenDisarmed.rawValue = val
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Low Latency Mode
        RowLayout {
            Layout.fillWidth: true
            visible: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.lowLatencyMode.visible && _isGST
            spacing: 20

            QGCLabel {
                text: qsTr("Low Latency Mode")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillWidth: true }

            OnOffToggle {
                checked: _videoSettings.lowLatencyMode.rawValue
                onToggled: (val) => _videoSettings.lowLatencyMode.rawValue = val
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Video decode priority
        RowLayout {
            Layout.fillWidth: true
            visible: _videoSettings.forceVideoDecoder.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Video decode priority")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactComboBox {
                fact: _videoSettings.forceVideoDecoder
                indexModel: false
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }

                onPressedChanged: {
                    if (pressed) {
                        popup.width = Math.max(width, ScreenTools.defaultFontPixelWidth * 40)
                        popup.x = width - popup.width
                    }
                }
            }
        }

        // Record File Format
        RowLayout {
            Layout.fillWidth: true
            visible: _videoSettings.recordingFormat.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Record File Format")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactComboBox {
                fact: _videoSettings.recordingFormat
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }

                onPressedChanged: {
                    if (pressed) {
                        popup.width = Math.max(width, ScreenTools.defaultFontPixelWidth * 40)
                        popup.x = width - popup.width
                    }
                }
            }
        }

        // Auto-Delete Saved Recordings
        RowLayout {
            Layout.fillWidth: true
            visible: _videoSettings.enableStorageLimit.visible
            spacing: 20

            QGCLabel {
                text: qsTr("Auto-Delete Saved Recordings")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillWidth: true }

            OnOffToggle {
                checked: _videoSettings.enableStorageLimit.rawValue
                onToggled: (val) => _videoSettings.enableStorageLimit.rawValue = val
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Max Storage Usage
        RowLayout {
            Layout.fillWidth: true
            visible: _videoSettings.maxVideoSize.visible
            enabled: _videoSettings.enableStorageLimit.rawValue
            opacity: enabled ? 1.0 : 0.5
            spacing: 20

            QGCLabel {
                text: qsTr("Max Storage Usage")
                color: "black"
                font.bold: true
                Layout.preferredWidth: 220
                Layout.alignment: Qt.AlignVCenter
            }

            FactTextField {
                fact: _videoSettings.maxVideoSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 15
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    color: "white"
                    border.color: "#808080"
                    border.width: 1
                    radius: 12
                }
            }

            QGCLabel {
                text: "MB"
                color: "black"
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        // Bottom Spacer
        Item {
            Layout.preferredHeight: 20
        }
    }
}
