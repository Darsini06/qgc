/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Templates as T

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controls

T.ComboBox {
    id:             control
    padding:        ScreenTools.comboBoxPadding
    spacing:        ScreenTools.defaultFontPixelWidth
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily
    implicitWidth:  Math.max(background ? background.implicitWidth : 0,
                             contentItem.implicitWidth + leftPadding + rightPadding + padding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             Math.max(contentItem.implicitHeight, indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + text.baselineOffset
    leftPadding:    padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding:   padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width)

    property bool   centeredLabel:  false
    property bool   sizeToContents: false
    property string alternateText:  ""

    property real   _popupWidth
    property bool   _onCompleted:   false
    property bool   _showBorder:    qgcPal.globalTheme === QGCPalette.Light
    property bool   isAgri:         QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri"
    property color  app_color:      isAgri ? "#79AE6F" : "#808080"

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    TextMetrics {
        id:                 textMetrics
        font.family:        control.font.family
        font.pointSize:     control.font.pointSize
    }

    ItemDelegate {
        id:             itemDelegateMetrics
        visible:        false
        font.family:    control.font.family
        font.pointSize: control.font.pointSize
    }

    function _calcPopupWidth() {
        _popupWidth = control.width
        if (_onCompleted && sizeToContents && model) {
            var largestTextWidth = 0
            for (var i = 0; i < model.length; i++){
                textMetrics.text = control.textRole ? (Array.isArray(control.model) ? model[i][control.textRole] : model[control.textRole]) : model[i]
                largestTextWidth = Math.max(textMetrics.width, largestTextWidth)
            }
            _popupWidth = largestTextWidth + itemDelegateMetrics.leftPadding + itemDelegateMetrics.rightPadding
        }
    }

    onModelChanged: _calcPopupWidth()

    Component.onCompleted: {
        _onCompleted = true
        _calcPopupWidth()
    }

    // The items in the popup
    delegate: ItemDelegate {
        width:  _popupWidth
        height: Math.round(popupItemMetrics.height * 1.75)

        property string _text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData

        TextMetrics {
            id:             popupItemMetrics
            font:           control.font
            text:           _text
        }

        contentItem: Text {
            leftPadding:            ScreenTools.defaultFontPixelWidth * 2
            rightPadding:           ScreenTools.defaultFontPixelWidth * 2
            text:                   _text
            font:                   control.font
            color:                  control.currentIndex === index ? "white" : (highlighted ? "white" : qgcPal.buttonText)
            verticalAlignment:      Text.AlignVCenter
            horizontalAlignment:    Text.AlignLeft
        }

        background: Rectangle {
            anchors.fill:           parent
            anchors.leftMargin:     4
            anchors.rightMargin:    4
            anchors.topMargin:      2
            anchors.bottomMargin:   2
            color:                  control.currentIndex === index ? "black" : (highlighted ? "black" : "transparent")
            radius:                 6
        }

        highlighted:                control.highlightedIndex === index
    }

    indicator: QGCColoredImage {
        anchors.rightMargin:    control.padding
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter
        height:                 ScreenTools.defaultFontPixelWidth * 0.8
        width:                  height
        source:                 "/qmlimages/arrow-down.png"
        color:                  qgcPal.text
    }

    // The label of the button
    contentItem: QGCLabel {
        id:                         text
        anchors.verticalCenter:     parent.verticalCenter
        leftPadding:                ScreenTools.defaultFontPixelWidth * 2
        rightPadding:               ScreenTools.defaultFontPixelWidth * 4
        horizontalAlignment:        Text.AlignLeft
        text:                       control.alternateText === "" ? control.currentText : control.alternateText
        font:                       control.font
        color:                      qgcPal.buttonText
        elide:                      Text.ElideRight
    }

    background: Rectangle {
        color:          qgcPal.button
        border.color:   qgcPal.buttonBorder
        border.width:   1
        radius:         12
    }

    popup: T.Popup {
        x:              0
        y:              control.height
        width:          _popupWidth
        height:         Math.min(contentItem.implicitHeight, control.Window.window ? control.Window.window.height - topMargin - bottomMargin : 500)
        topMargin:      ScreenTools.toolbarHeight + ScreenTools.defaultFontPixelHeight
        bottomMargin:   ScreenTools.defaultFontPixelHeight

        contentItem: ListView {
            clip:                   true
            implicitHeight:         contentHeight
            model:                  control.delegateModel
            currentIndex:           control.highlightedIndex
            highlightMoveDuration:  0

            T.ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: qgcPal.windowShade
            radius: 12
            border.color: qgcPal.windowShadeDark
            border.width: 1
        }
    }
}
