import QtQuick

import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette


Item {
    id: channels
    anchors.fill: parent

    property real _margins: ScreenTools.defaultFontPixelHeight
    property bool _ch7OptAvailable: controller.parameterExists(-1, "CH7_OPT")
    property int _rcOptionStart: _ch7OptAvailable ? 7 : 6
    property int _rcOptionStop: _ch7OptAvailable ? 12 : 16

    APMFlightModesComponentController {
        id: controller
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: _margins

        Label {
            text: "Channel Set"
            font.pixelSize: 22
            font.bold: true
            color: "black"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
        }

        Flickable {
            id: flickableArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: parent.width
            contentHeight: channelContent.implicitHeight
            clip: true

            Column {
                id: channelContent
                width: parent.width
                spacing: _margins

                Repeater {
                    model: _rcOptionStop - _rcOptionStart + 1

                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth
                        Layout.fillWidth: true

                        property int index: modelData + _rcOptionStart // 1-based channel number (6-16)
                        property Fact nullFact: Fact { }

                        QGCLabel {
                            text: qsTr("CH %1 :").arg(index)
                            color: controller.channelOptionEnabled[modelData + (_ch7OptAvailable ? 1 : 0)] ? "yellow" : "black"
                            Layout.alignment: Qt.AlignLeft
                            Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 7
                        }

                        RCChannelMonitor {
                            Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                            channelIndex: index - 1 // Convert to 0-based (5-15)
                        }

                        FactComboBox {
                            id: optCombo
                            width: ScreenTools.defaultFontPixelWidth * 18
                            fact: controller.getParameterFact(-1, "r.RC" + index + "_OPTION")
                            indexModel: false
                        }
                    }
                }
            }
        }
    }
}
