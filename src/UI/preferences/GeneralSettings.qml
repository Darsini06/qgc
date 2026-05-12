import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QGroundControl.Controllers
import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette

SettingsPage {

    //General Settings ------------------------------------------------------------------------------------
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath

    //Video Settings ------------------------------------------------------------------------------------
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
    //Telemetry Settings ------------------------------------------------------------------------------------
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("Not Connected")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:   _appSettings.apmStartMavlinkStreams
    //Drone Settings ------------------------------------------------------------------------------------
    property var    _linkManager:               QGroundControl.linkManager
    property var    _autoConnectSettings:       QGroundControl.settingsManager.autoConnectSettings
    property bool   _isNarrow:                  width < ScreenTools.defaultFontPixelWidth * 70
    property real   _innerMargin:               ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth : ScreenTools.defaultFontPixelWidth * 3
    property real   _labelWidth:                _isNarrow ? contentLayout.width : ScreenTools.defaultFontPixelWidth * 45
    property real   _controlWidth:              _isNarrow ? contentLayout.width : ScreenTools.defaultFontPixelWidth * 45
    property real   _maxContentWidth:           ScreenTools.defaultFontPixelWidth * 110
    property real   _contentWidth:              Math.min(width - (_innerMargin * 2), _maxContentWidth)



    ColumnLayout {
        id:                 contentLayout
        width:              _contentWidth
        Layout.preferredWidth: _contentWidth
        Layout.fillWidth:   _isNarrow
        Layout.maximumWidth: _maxContentWidth
        Layout.alignment:   Qt.AlignHCenter
        spacing:            _isNarrow ? ScreenTools.defaultFontPixelHeight / 2 : ScreenTools.defaultFontPixelHeight


        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.3
            visible:          _videoSettings.videoSource.visible
        }

        //Language
        // LabelledFactComboBox {
        //     label:      qsTr("Language")
        //     fact:       _appSettings.qLocaleLanguage
        //     indexModel: false
        //     visible:    _appSettings.qLocaleLanguage.visible
        // }

        // RowLayout {
        //     spacing: 20
        //     visible: _appSettings.qLocaleLanguage.visible
        //     QGCLabel {
        //         text: qsTr("Language")
        //         color: "black"
        //         font.bold: true
        //         Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
        //     }
        //     QGCLabel {
        //         text: "English"
        //         color: "gray"
        //     }
        // }

        // LabelledFactComboBox {
        //     label:      qsTr("Color Scheme")
        //     fact:       _appSettings.indoorPalette
        //     indexModel: false
        //     visible:    _appSettings.indoorPalette.visible
        // }

        // LabelledFactComboBox {
        //     label:       qsTr("Stream GCS Position")
        //     fact:       _appSettings.followTarget
        //     indexModel: false
        //     visible:    _appSettings.followTarget.visible
        // }


        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _appSettings.followTarget.visible

            QGCLabel {
                text:               qsTr("Stream GCS Position")
                color:              "black"
                font.bold:          true
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            FactComboBox {
                id:                     followTargetCombo
                fact:                   _appSettings.followTarget
                indexModel:             false
                sizeToContents:         false
                Layout.fillWidth:       true
                Layout.maximumWidth:    _isNarrow ? 10000 : _controlWidth
                Layout.preferredWidth:  _controlWidth
                Layout.preferredHeight: 40
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                background: Rectangle {
                    color:          "white"
                    border.color:   "#808080"
                    border.width:   1
                    radius:         4
                }
                delegate: ItemDelegate {
                    width:          parent.width
                    contentItem: QGCLabel {
                        text:       modelData
                        color:      (followTargetCombo.currentIndex === index || highlighted) ? "white" : "black"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: ScreenTools.defaultFontPixelWidth * 2
                        rightPadding: ScreenTools.defaultFontPixelWidth * 2
                        wrapMode:   Text.WordWrap
                    }
                    background: Rectangle {
                        color:      (followTargetCombo.currentIndex === index || highlighted) ? "#79AE6F" : "transparent"
                        radius:     12
                        anchors.fill: parent
                        anchors.margins: 2
                    }
                }
            }
        }

        // --- SD Card Save (Tick Style) ---
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _appSettings.androidSaveToSDCard.visible

            QGCLabel {
                text:                   qsTr("Save application data to SD Card")
                color:                  "black"
                font.bold:              true
                Layout.fillWidth:       _isNarrow
                Layout.preferredWidth:  _labelWidth
                wrapMode:               Text.WordWrap
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            Item {
                Layout.preferredWidth:  _isNarrow ? 26 : _controlWidth
                Layout.preferredHeight: 26
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight

                Rectangle {
                    anchors.right:  _isNarrow ? undefined : parent.right
                    anchors.left:   _isNarrow ? parent.left : undefined
                    width:          26
                    height:         26
                    border.color:   _appSettings.androidSaveToSDCard.value != 0 ? "black" : "#CCC"
                    border.width:   2
                    radius:         4
                    color:          "white"

                    QGCColoredImage {
                        anchors.centerIn: parent
                        width:            18
                        height:           18
                        source:           "/qmlimages/checkbox-check.svg"
                        color:            "black"
                        visible:          _appSettings.androidSaveToSDCard.value != 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:    _appSettings.androidSaveToSDCard.value = (_appSettings.androidSaveToSDCard.value == 0 ? 1 : 0)
                    }
                }
            }
        }

        // FactCheckBoxSlider {
        //     Layout.fillWidth: true
        //     text:           qsTr("Mute all audio output")
        //     fact:       _audioMuted
        //     visible:    _audioMuted.visible
        //     property Fact _audioMuted: _appSettings.audioMuted
        // }

        // FactCheckBoxSlider {
        //     Layout.fillWidth: true
        //     text:       qsTr("Save application data to SD Card")
        //     fact:       _androidSaveToSDCard
        //     visible:    _androidSaveToSDCard.visible
        //     property Fact _androidSaveToSDCard: _appSettings.androidSaveToSDCard
        // }

        //Not for Mobile
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _appSavePath.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
                spacing:            0

                QGCLabel { 
                    text: qsTr("Application Load/Save Path")
                    font.bold: true
                    color: "black"
                    Layout.fillWidth: true
                }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:              Text.ElideMiddle
                    color:              "black"
                }
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            QGCButton {
                text:               qsTr("Browse")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:          savePathBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:                 savePathBrowseDialog
                    title:              qsTr("Choose the location to save/load files")
                    folder:             _appSavePath.rawValue
                    selectFolder:       true
                    onAcceptedForLoad:  (file) => _appSavePath.rawValue = file
                }
            }
        }

        // Repeater {
        //     visible:            QGroundControl.settingsManager.unitsSettings.visible

        //     model: [ QGroundControl.settingsManager.unitsSettings.horizontalDistanceUnits,
        //         QGroundControl.settingsManager.unitsSettings.verticalDistanceUnits,
        //         QGroundControl.settingsManager.unitsSettings.areaUnits,
        //         QGroundControl.settingsManager.unitsSettings.speedUnits,
        //         QGroundControl.settingsManager.unitsSettings.temperatureUnits,
        //     ]

        //     LabelledFactComboBox {
        //         label:                  modelData.shortDescription
        //         fact:                   modelData
        //         indexModel:             false
        //     }
        // }

        Repeater {
            visible: _settingsManager.unitsSettings.visible

            model:   [
                _settingsManager.unitsSettings.horizontalDistanceUnits,
                _settingsManager.unitsSettings.verticalDistanceUnits,
                _settingsManager.unitsSettings.areaUnits,
                _settingsManager.unitsSettings.speedUnits,
                _settingsManager.unitsSettings.temperatureUnits
            ]

            GridLayout {
                columns:            _isNarrow ? 1 : 3
                columnSpacing:      10
                rowSpacing:         _isNarrow ? 5 : 0
                Layout.fillWidth:   true
                property var unitFact: modelData

                QGCLabel {
                    text:                   unitFact.shortDescription
                    color:                  "black"
                    font.bold:              true
                    Layout.fillWidth:       _isNarrow
                    Layout.preferredWidth:  _labelWidth
                }

                Item { 
                    Layout.fillWidth: true
                    visible:          !_isNarrow 
                }

                FactComboBox {
                    id:                     unitCombo
                    fact:                   unitFact
                    indexModel:             false
                    sizeToContents:         false
                    Layout.fillWidth:       true
                    Layout.maximumWidth:    _isNarrow ? 10000 : _controlWidth
                    Layout.preferredWidth:  _controlWidth
                    Layout.preferredHeight: 40
                    Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                    background: Rectangle {
                        color:          "white"
                        border.color:   "#808080"
                        border.width:   1
                        radius:         4
                    }
                    delegate: ItemDelegate {
                        width:          parent.width
                        contentItem: QGCLabel {
                            text:       modelData
                            color:      (unitCombo.currentIndex === index || highlighted) ? "white" : "black"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: ScreenTools.defaultFontPixelWidth * 2
                            rightPadding: ScreenTools.defaultFontPixelWidth * 2
                            wrapMode:   Text.WordWrap
                        }
                        background: Rectangle {
                            color:      (unitCombo.currentIndex === index || highlighted) ? "#79AE6F" : "transparent"
                            radius:     12
                            anchors.fill: parent
                            anchors.margins: 2
                        }
                    }
                }
            }
        }

        //Not for Mobile
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _userBrandImageIndoor.visible && _brandImageSettings.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
                spacing:            0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Indoor Image")
                    font.bold:          true
                    color:              "black"
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageIndoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    color:              "black"
                    visible:            _userBrandImageIndoor.valueString.length > 0
                }
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            QGCButton {
                text:               qsTr("Browse")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:          userBrandImageIndoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id:                 userBrandImageIndoorBrowseDialog
                    title:              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageIndoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageIndoor.rawValue = "file:///" + file
                }
            }
        }

        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _userBrandImageOutdoor.visible && _brandImageSettings.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   _isNarrow
                Layout.preferredWidth: _labelWidth
                spacing:            0

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("Outdoor Image")
                    font.bold:          true
                    color:              "black"
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _userBrandImageOutdoor.valueString.replace("file:///", "")
                    elide:              Text.ElideMiddle
                    color:              "black"
                    visible:            _userBrandImageOutdoor.valueString.length > 0
                }
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            QGCButton {
                text:               qsTr("Browse")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:          userBrandImageOutdoorBrowseDialog.openForLoad()

                QGCFileDialog {
                    id :                 userBrandImageOutdoorBrowseDialog
                    title :              qsTr("Choose custom brand image file")
                    folder:             _userBrandImageOutdoor.rawValue.replace("file:///", "")
                    selectFolder:       false
                    onAcceptedForLoad:  (file) => _userBrandImageOutdoor.rawValue = "file:///" + file
                }
            }
        }

        //Not for Mobile
        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            Layout.fillWidth:   true
            visible:            _brandImageSettings.visible && !ScreenTools.isMobile

            QGCLabel {
                text:               qsTr("Reset Images")
                font.bold:          true
                color:              "black"
                Layout.preferredWidth: _labelWidth
                Layout.fillWidth:   _isNarrow
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            QGCButton {
                text:               qsTr("Reset")
                Layout.alignment:   _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                onClicked:  {
                    _userBrandImageIndoor.rawValue = ""
                    _userBrandImageOutdoor.rawValue = ""
                }
            }
        }

        // --- Video Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            //Layout.topMargin: ScreenTools.defaultFontPixelHeight
            //Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.5
        }

        Text {
            Layout.fillWidth: true
            text:             qsTr("Video Settings")
            font.pointSize:   ScreenTools.mediumFontPointSize
            color:            "black"
            font.bold:        true
            horizontalAlignment: Text.AlignLeft
            visible:          _videoSettings.videoSource.visible
        }

        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 0
            visible:            _videoSettings.videoSource.visible
            Layout.fillWidth:   true

            QGCLabel {
                text:                   qsTr("Source")
                color:                  "black"
                font.bold:              true
                Layout.fillWidth:       _isNarrow
                Layout.preferredWidth:  _labelWidth
            }

            Item { 
                Layout.fillWidth: true
                visible:          !_isNarrow 
            }

            FactComboBox {
                id:                     videoCombo
                fact:                   _videoSettings.videoSource
                indexModel:             false
                sizeToContents:         false
                Layout.fillWidth:       true
                Layout.maximumWidth:    _isNarrow ? 10000 : _controlWidth
                Layout.preferredWidth:  _controlWidth
                Layout.preferredHeight: 40
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                background: Rectangle {
                    color:          "white"
                    border.color:   "#808080"
                    border.width:   1
                    radius:         4
                }
                delegate: ItemDelegate {
                    width:          parent.width
                    contentItem: QGCLabel {
                        text:       modelData
                        color:      (videoCombo.currentIndex === index || highlighted) ? "white" : "black"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: ScreenTools.defaultFontPixelWidth * 2
                        rightPadding: ScreenTools.defaultFontPixelWidth * 2
                        wrapMode:   Text.WordWrap
                    }
                    background: Rectangle {
                        color:      (videoCombo.currentIndex === index || highlighted) ? "#79AE6F" : "transparent"
                        radius:     12
                        anchors.fill: parent
                        anchors.margins: 2
                    }
                }
            }
        }

        GridLayout {
            columns:            _isNarrow ? 1 : 3
            columnSpacing:      10
            rowSpacing:         _isNarrow ? 5 : 12
            Layout.fillWidth:   true
            visible:            _isStreamSource && _videoSettings.videoSource.visible

            // RTSP URL
            QGCLabel {
                text:           qsTr("RTSP URL")
                color:          "black"
                font.bold:      true
                Layout.preferredWidth: _labelWidth
                Layout.fillWidth:      _isNarrow
                visible:        _isRTSP && _videoSettings.rtspUrl.visible
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow && _isRTSP && _videoSettings.rtspUrl.visible
            }

            Rectangle {
                Layout.preferredWidth:  _controlWidth
                Layout.preferredHeight: 40
                Layout.fillWidth:       _isNarrow
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                color:                  "white"
                border.color:           "#808080"
                border.width:           1
                radius:                 4
                clip:                   true
                visible:                _isRTSP && _videoSettings.rtspUrl.visible

                FactTextField {
                    anchors.fill:       parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    fact:               _videoSettings.rtspUrl
                    background:         null
                }
            }

            // TCP URL
            QGCLabel {
                text:           qsTr("TCP URL")
                color:          "black"
                font.bold:      true
                Layout.preferredWidth: _labelWidth
                Layout.fillWidth:      _isNarrow
                visible:        _isTCP && _videoSettings.tcpUrl.visible
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow && _isTCP && _videoSettings.tcpUrl.visible
            }

            Rectangle {
                Layout.preferredWidth:  _controlWidth
                Layout.preferredHeight: 40
                Layout.fillWidth:       _isNarrow
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                color:                  "white"
                border.color:           "#808080"
                border.width:           1
                radius:                 4
                clip:                   true
                visible:                _isTCP && _videoSettings.tcpUrl.visible

                FactTextField {
                    anchors.fill:       parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    fact:               _videoSettings.tcpUrl
                    background:         null
                }
            }

            // UDP Port
            QGCLabel {
                text:           qsTr("UDP Port")
                color:          "black"
                font.bold:      true
                Layout.preferredWidth: _labelWidth
                Layout.fillWidth:      _isNarrow
                visible:        _requiresUDPPort && _videoSettings.udpPort.visible
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow && _requiresUDPPort && _videoSettings.udpPort.visible
            }

            Rectangle {
                Layout.preferredWidth:  _controlWidth
                Layout.preferredHeight: 40
                Layout.fillWidth:       _isNarrow
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                color:                  "white"
                border.color:           "#808080"
                border.width:           1
                radius:                 4
                clip:                   true
                visible:                _requiresUDPPort && _videoSettings.udpPort.visible

                FactTextField {
                    anchors.fill:       parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    fact:               _videoSettings.udpPort
                    background:         null
                }
            }

            // Aspect Ratio
            QGCLabel {
                text:           qsTr("Aspect Ratio")
                color:          "black"
                font.bold:      true
                Layout.preferredWidth: _labelWidth
                Layout.fillWidth:      _isNarrow
                visible:        !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
            }

            Item {
                Layout.fillWidth: true
                visible:          !_isNarrow && !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
            }

            Rectangle {
                Layout.preferredWidth:  _controlWidth
                Layout.preferredHeight: 40
                Layout.fillWidth:       _isNarrow
                Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight
                color:                  "white"
                border.color:           "#808080"
                border.width:           1
                radius:                 8
                clip:                   true
                visible:                !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible

                FactTextField {
                    anchors.fill:       parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    fact:               _videoSettings.aspectRatio
                    background:         null
                }
            }
        }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Stop recording when disarmed")
        //     fact:               _videoSettings.disableWhenDisarmed
        //     visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible
        // }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Low Latency Mode")
        //     fact:               _videoSettings.lowLatencyMode
        //     visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible && _isGST
        // }

        ColumnLayout {

            spacing: 12
            Layout.fillWidth: true

        Repeater {
            model: [
                { t: qsTr("Low Latency Mode"), f: _videoSettings.lowLatencyMode, v: !_videoAutoStreamConfig && _isStreamSource && _videoSettings.lowLatencyMode.visible && _isGST, e: true }
            ]

            delegate: GridLayout {
                columns:            _isNarrow ? 1 : 3
                columnSpacing:      10
                rowSpacing:         _isNarrow ? 5 : 0
                visible:            modelData.v
                Layout.fillWidth:   true

                QGCLabel {
                    text:                   modelData.t
                    color:                  "black"
                    font.bold:              true
                    Layout.fillWidth:       _isNarrow
                    Layout.preferredWidth:  _labelWidth
                }

                Item { 
                    Layout.fillWidth: true
                    visible:          !_isNarrow 
                }

                Item {
                    Layout.preferredWidth:  _isNarrow ? 26 : _controlWidth
                    Layout.preferredHeight: 26
                    Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight

                    Rectangle {
                        anchors.right:  _isNarrow ? undefined : parent.right
                        anchors.left:   _isNarrow ? parent.left : undefined
                        width:          26
                        height:         26
                        border.color:   modelData.f.value != 0 ? "black" : "#CCC"
                        border.width:   2
                        radius:         4
                        color:          "white"

                        QGCColoredImage {
                            anchors.centerIn: parent
                            width:            18
                            height:           18
                            source:           "/qmlimages/checkbox-check.svg"
                            color:            "black"
                            visible:          modelData.f.value != 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked:    modelData.f.value = (modelData.f.value == 0 ? 1 : 0)
                        }
                    }
                }
            }
        }
        }


        // --- Logging Section ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#E0E0E0"
            Layout.topMargin: ScreenTools.defaultFontPixelHeight
            //Layout.bottomMargin: ScreenTools.defaultFontPixelHeight * 0.5
        }

        Text {
            Layout.fillWidth: true
            text:             qsTr("Logging")
            font.pixelSize:   ScreenTools.isMobile ? 18 : 22
            color:            "black"
            font.bold:        true
            horizontalAlignment: Text.AlignLeft
            visible:          !_disableAllDataPersistence
        }

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true
            visible: !_disableAllDataPersistence

        Repeater {
            model: [
                { t: qsTr("Save log after each flight"), f: _appSettings.telemetrySave, v: _appSettings.telemetrySave.visible, e: true },
                { t: qsTr("Save logs even if vehicle was not armed"), f: _appSettings.telemetrySaveNotArmed, v: _appSettings.telemetrySaveNotArmed.visible, e: _appSettings.telemetrySave.rawValue },
            ]
            delegate: GridLayout {
                columns:            _isNarrow ? 1 : 3
                columnSpacing:      10
                rowSpacing:         _isNarrow ? 5 : 0
                visible:            modelData.v
                opacity:            modelData.e ? 1 : 0.5
                Layout.fillWidth:   true

                QGCLabel {
                    text:                   modelData.t
                    color:                  "black"
                    font.bold:              true
                    Layout.fillWidth:       _isNarrow
                    Layout.preferredWidth:  _labelWidth
                }

                Item { 
                    Layout.fillWidth: true
                    visible:          !_isNarrow 
                }

                Item {
                    Layout.preferredWidth:  _isNarrow ? 26 : _controlWidth
                    Layout.preferredHeight: 26
                    Layout.alignment:       _isNarrow ? Qt.AlignLeft : Qt.AlignRight

                    Rectangle {
                        anchors.right:  _isNarrow ? undefined : parent.right
                        anchors.left:   _isNarrow ? parent.left : undefined
                        width:          26
                        height:         26
                        border.color:   modelData.f.value != 0 ? "black" : "#CCC"
                        border.width:   2
                        radius:         4
                        color:          "white"

                        QGCColoredImage {
                            anchors.centerIn: parent
                            width:            18
                            height:           18
                            source:           "/qmlimages/checkbox-check.svg"
                            color:            "black"
                            visible:          modelData.f.value != 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled:      modelData.e
                            onClicked:    modelData.f.value = (modelData.f.value == 0 ? 1 : 0)
                        }
                    }
                }
            }
        }
        }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Save log after each flight")
        //     fact:               _telemetrySave
        //     visible:            fact.visible  &&  !_disableAllDataPersistence
        //     property Fact _telemetrySave: _appSettings.telemetrySave
        // }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Save logs even if vehicle was not armed")
        //     fact:               _telemetrySaveNotArmed
        //     visible:            fact.visible   &&  !_disableAllDataPersistence
        //     enabled:            _appSettings.telemetrySave.rawValue
        //     property Fact _telemetrySaveNotArmed: _appSettings.telemetrySaveNotArmed
        // }

        // FactCheckBoxSlider {
        //     Layout.fillWidth:   true
        //     text:               qsTr("Save CSV log of telemetry data")
        //     fact:               _saveCsvTelemetry
        //     visible:            fact.visible   &&  !_disableAllDataPersistence
        //     property Fact _saveCsvTelemetry: _appSettings.saveCsvTelemetry
        // }

        //Link Settings
        LinkSettings {
            Layout.fillWidth: true
        }

        // Bottom Spacer
        Item {
            Layout.preferredHeight: 20
        }
    }
}