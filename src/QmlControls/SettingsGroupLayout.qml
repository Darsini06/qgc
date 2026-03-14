import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QtQuick.Effects
ColumnLayout {
    id:             control
    spacing:        _margins / 2
    implicitWidth:  _contentLayout.implicitWidth //+ (_margins * 2)
    implicitHeight: _contentLayout.implicitHeight + (_margins * 2)
    Layout.leftMargin: 100
    Layout.rightMargin: 100


    default property alias contentItem: _contentLayout.data

    property alias contentSpacing: _contentLayout.spacing

    property string heading
    property string headingDescription
    property bool   showDividers:       true
    property bool   showBorder:         true

    property real _margins: ScreenTools.defaultFontPixelHeight / 2


    ColumnLayout {
        Layout.leftMargin:  _margins
        Layout.fillWidth:   true
        spacing:            20
        visible:            heading !== ""
        Layout.topMargin:    20     // 🔼 top padding
        Layout.bottomMargin: 20     // 🔽 bottom padding

        QGCLabel {
            text:           heading
            font.pointSize: ScreenTools.defaultFontPointSize + 1
            font.bold:      true
            color: "#3A3A3A"
        }

        QGCLabel {
            Layout.fillWidth:   true
            text:               headingDescription
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            visible:            headingDescription !== ""
            font.bold:      true
            color: "#4a2c6d"
        }
    }



    Rectangle {
        id:                 outerRect
        Layout.fillWidth:   true
        implicitWidth:      _contentLayout.implicitWidth + (showBorder ? _margins * 2 : 0)
        implicitHeight:     _contentLayout.implicitHeight + (showBorder ? _margins * 2: 0)
        color:              "white"
        //border.color:       QGroundControl.globalPalette.groupBorder
        //border.width:       2//showBorder ? 1 : 0
        //radius:             ScreenTools.defaultFontPixelHeight / 2
        Rectangle {
                            id: shadowSource
                            anchors.fill: parent
                            radius: 10//dp(4)
                            color: "white"
                            visible: false
                            anchors.margins: 2

                        }

        MultiEffect {
            anchors.fill: shadowSource
            source: shadowSource

            shadowEnabled: true
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: -10      // TOP
            shadowColor: "#4a2c6d"
        }
        MultiEffect {
            anchors.fill: shadowSource
            source: shadowSource

            shadowEnabled: true
            shadowBlur: 1.2
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 15       // BOTTOM
            shadowColor: "#4a2c6d"
        }




                        // MultiEffect {
                        //     anchors.fill: shadowSource
                        //     source: shadowSource

                        //     shadowEnabled: true
                        //     shadowBlur: 1.0
                        //     shadowHorizontalOffset: 0
                        //     shadowVerticalOffset: 15//dp(1)
                        //     shadowColor: "#1a237e"   // soft black
                        // }

        Repeater {
            model: showDividers? _contentLayout.children.length : 0

            Rectangle {
                x:                  showBorder ? _margins : 0
                y:                  _contentItem.y + _contentItem.height + _margins + (showBorder ? _margins : 0)
                width:              parent.width - (showBorder ? _margins * 2 : 0)
                height:             1
                color:              QGroundControl.globalPalette.groupBorder
                visible:            _contentItem.visible &&
                                        _contentItem.width !== 0 && _contentItem.height !== 0 &&
                                        index < _contentLayout.children.length - 1

                property var _contentItem: _contentLayout.children[index]
            }
        }









        ColumnLayout {
            id:                 _contentLayout
            x:                  showBorder ? _margins : 0
            y:                  showBorder ? _margins : 0
            width:              parent.width - (showBorder ? _margins * 2 : 0)
            spacing:            _margins * 2
        }
    }
}
