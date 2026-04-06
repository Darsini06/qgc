import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls

QGCFlickable {
    id:             root
    contentHeight:  geoFenceEditorRect.height
    clip:           true

    property var    myGeoFenceController
    property var    flightMap

    readonly property real  _editFieldWidth:    Math.min(width - _margin * 2, ScreenTools.defaultFontPixelWidth * 15)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth * 1.5
    readonly property real  _radius:            8

    // UI Colors - Modern Glassmorphic Dark Theme
    readonly property color _colorBgPrimary:    "transparent"
    readonly property color _colorBgSecondary:  "#282830"
    readonly property color _colorBgTertiary:   "#32323b"
    readonly property color _colorBorder:       "#3e3e4a"
    readonly property color _colorAccent:       "#471880" // Modern Deep PurpleAccent
    readonly property color _colorAccentDark:   "#471880ff"
    readonly property color _colorTextPrimary:  "#ffffff"
    readonly property color _colorTextSecondary:"#8e8e93"
    readonly property color _colorDanger:       "#FF453A"
    readonly property color _colorDangerDark:   "#C42B2B"
    readonly property bool  isAgri:             QGroundControl.loadGlobalSetting("loadpage", "loadpage") === "Agri"
    readonly property color _agriGreen:        "#79AE6F"

    Component {
        id: volumeSliderComponent

        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth / 1.5
            property var fact: null

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth: Layout.preferredHeight
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
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1;
                            parent.parent.fact.value -= step;
                        }
                    }
                }
            }

            Slider {
                id: factSlider
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                
                from: {
                    if (!parent.fact) return 0;
                    if (isNaN(parent.fact.min) || parent.fact.min < -1000) return 0;
                    return parent.fact.min;
                }
                to: {
                    if (!parent.fact) return 100;
                    if (isNaN(parent.fact.max) || parent.fact.max > 1000) return (from + 200);
                    return parent.fact.max;
                }
                value: parent.fact ? parent.fact.value : 0
                stepSize: parent.fact ? (parent.fact.increment ? parent.fact.increment : 1) : 1
                
                background: Rectangle {
                    x: factSlider.leftPadding
                    y: factSlider.topPadding + factSlider.availableHeight / 2 - height / 2
                    implicitWidth: 100
                    implicitHeight: 6
                    width: factSlider.availableWidth
                    height: implicitHeight
                    radius: 3
                    color: _colorBgTertiary
                    
                    Rectangle {
                        width: factSlider.visualPosition * parent.width
                        height: parent.height
                        color: _colorAccent
                        radius: 3
                    }
                }
                
                handle: Rectangle {
                    x: factSlider.leftPadding + factSlider.visualPosition * (factSlider.availableWidth - width)
                    y: factSlider.topPadding + factSlider.availableHeight / 2 - height / 2
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: _colorTextPrimary
                    border.color: _colorAccent
                    border.width: factSlider.pressed ? 4 : 2
                    
                    Behavior on border.width { NumberAnimation { duration: 150 } }
                }
                
                onMoved: {
                    if (parent.fact) parent.fact.value = value;
                }
            }

            Rectangle {
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.preferredWidth: Layout.preferredHeight
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
                            var step = parent.parent.fact.increment ? parent.parent.fact.increment : 1;
                            parent.parent.fact.value += step;
                        }
                    }
                }
            }

            FactTextField {
                id: factField
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8
                Layout.preferredHeight: ScreenTools.implicitTextFieldHeight * 1.2
                Layout.alignment: Qt.AlignVCenter
                fact: parent.fact
                showUnits: true
                color: _colorTextPrimary
                horizontalAlignment: Qt.AlignHCenter
                background: Rectangle {
                    color: factField.activeFocus ? _colorBgTertiary : _colorBgSecondary
                    border.color: factField.activeFocus ? _colorAccent : _colorBorder
                    border.width: factField.activeFocus ? 2 : 1
                    radius: 15
                }
            }
        }
    }

    Rectangle {
        id:             geoFenceEditorRect
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         geoFenceItems.y + geoFenceItems.height + _margin
        radius:         _radius
        color:          _colorBgPrimary
        border.color:   _colorBorder
        border.width:   1

        QGCLabel {
            id:                 geoFenceLabel
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.top:        parent.top
            text:               qsTr("GeoFence Settings")
            color:              _colorTextPrimary
            font.bold:          true
            font.pointSize:     ScreenTools.mediumFontPointSize
            anchors.leftMargin: _margin
        }

        Rectangle {
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        geoFenceLabel.bottom
            anchors.topMargin:  _margin / 2
            height:             1
            color:              _colorBorder
            opacity:            0.5
        }

        Rectangle {
            id:                 geoFenceItems
            anchors.margins:    _margin
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.top:        geoFenceLabel.bottom
            anchors.topMargin:  _margin
            height:             fenceColumn.y + fenceColumn.height + _margin
            color:              "transparent"
            radius:             _radius

            Column {
                id:                 fenceColumn
                anchors.margins:    _margin
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margin * 1.2

                QGCLabel {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    wrapMode:           Text.WordWrap
                    color:              _colorTextSecondary
                    font.pointSize:     myGeoFenceController.supported ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                    text:               myGeoFenceController.supported ?
                                            qsTr("GeoFencing allows you to set a virtual fence around the area you want to fly in.") :
                                            qsTr("This vehicle does not support GeoFence.")
                }

                Column {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    spacing:            _margin
                    visible:            myGeoFenceController.supported

                    Repeater {
                        model: myGeoFenceController.params

                        Item {
                            width:  fenceColumn.width
                            height: textField.height

                            property bool showCombo: modelData.enumStrings.length > 0

                            QGCLabel {
                                id:                 textFieldLabel
                                anchors.baseline:   textField.baseline
                                color:              _colorTextPrimary
                                font.bold:          true
                                text:               myGeoFenceController.paramLabels[index]
                            }

                            Loader {
                                id:             textField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                visible:        !parent.showCombo
                                sourceComponent: volumeSliderComponent
                                property var targetFact: modelData
                                onTargetFactChanged: if (item) item.fact = targetFact
                                onLoaded: if (item) item.fact = targetFact
                            }

                            FactComboBox {
                                id:             comboField
                                anchors.right:  parent.right
                                width:          _editFieldWidth
                                indexModel:     false
                                fact:           showCombo ? modelData : _nullFact
                                visible:        parent.showCombo

                                property var _nullFact: Fact { }
                            }
                        }
                    }

                    // --- INSERT GEOFENCE SECTION ---
                    Rectangle {
                        id:             insertSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         40
                        color:          _colorBgSecondary
                        radius:         _radius
                        border.color:   _colorBorder
                        border.width:   1
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Add New GeoFence")
                            color: _colorTextPrimary
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: _margin

                        Button {
                            Layout.fillWidth:   true
                            height: 40
                            background: Rectangle {
                                radius: _radius
                                color: parent.pressed ? (isAgri ? Qt.darker(_agriGreen, 1.2) : _colorAccentDark) : (parent.hovered ? (isAgri ? Qt.lighter(_agriGreen, 1.1) : Qt.lighter(_colorAccent, 1.1)) : (isAgri ? _agriGreen : _colorAccent))
                            }
                            contentItem: Text {
                                text: qsTr("Inclusion Poly")
                                color: "white"
                                font.bold: true
                                font.pointSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                                var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false)
                                var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false)
                                myGeoFenceController.addInclusionPolygon(topLeftCoord, bottomRightCoord)
                            }
                        }

                        Button {
                            Layout.fillWidth:   true
                            height: 40
                            background: Rectangle {
                                radius: _radius
                                color: parent.pressed ? (isAgri ? Qt.darker(_agriGreen, 1.2) : _colorAccentDark) : (parent.hovered ? (isAgri ? Qt.lighter(_agriGreen, 1.1) : Qt.lighter(_colorAccent, 1.1)) : (isAgri ? _agriGreen : _colorAccent))
                            }
                            contentItem: Text {
                                text: qsTr("Obstacle Poly")
                                color: "white"
                                font.bold: true
                                font.pointSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                                var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false)
                                var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false)
                                myGeoFenceController.addExclusionPolygon(topLeftCoord, bottomRightCoord)
                            }
                        }
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: _margin

                        Button {
                            Layout.fillWidth:   true
                            height: 40
                            background: Rectangle {
                                radius: _radius
                                color: parent.pressed ? (isAgri ? Qt.darker(_agriGreen, 1.2) : _colorAccentDark) : (parent.hovered ? (isAgri ? Qt.lighter(_agriGreen, 1.1) : Qt.lighter(_colorAccent, 1.1)) : (isAgri ? _agriGreen : _colorAccent))
                            }
                            contentItem: Text {
                                text: qsTr("Inclusion Circle")
                                color: "white"
                                font.bold: true
                                font.pointSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                                var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false)
                                var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false)
                                myGeoFenceController.addInclusionCircle(topLeftCoord, bottomRightCoord)
                            }
                        }

                        Button {
                            Layout.fillWidth:   true
                            height: 40
                            background: Rectangle {
                                radius: _radius
                                color: parent.pressed ? (isAgri ? Qt.darker(_agriGreen, 1.2) : _colorAccentDark) : (parent.hovered ? (isAgri ? Qt.lighter(_agriGreen, 1.1) : Qt.lighter(_colorAccent, 1.1)) : (isAgri ? _agriGreen : _colorAccent))
                            }
                            contentItem: Text {
                                text: qsTr("Obstacle Circle")
                                color: "white"
                                font.bold: true
                                font.pointSize: 10
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                var rect = Qt.rect(flightMap.centerViewport.x, flightMap.centerViewport.y, flightMap.centerViewport.width, flightMap.centerViewport.height)
                                var topLeftCoord = flightMap.toCoordinate(Qt.point(rect.x, rect.y), false)
                                var bottomRightCoord = flightMap.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height), false)
                                myGeoFenceController.addExclusionCircle(topLeftCoord, bottomRightCoord)
                            }
                        }
                    }

                    // --- POLYGON SECTION ---
                    Rectangle {
                        id:             polygonSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         40
                        color:          _colorBgSecondary
                        radius:         _radius
                        border.color:   _colorBorder
                        border.width:   1
                        
                        property bool checked: true
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.checked = !parent.checked
                        }
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Polygon Fences")
                            color: _colorTextPrimary
                            font.bold: true
                        }
                        
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.checked ? "▼" : "▶"
                            color: _colorTextSecondary
                            font.pointSize: 10
                        }
                    }

                    QGCLabel {
                        text:       qsTr("No polygon fences added.")
                        color:      _colorTextSecondary
                        font.italic: true
                        visible:    polygonSection.checked && myGeoFenceController.polygons.count === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    ColumnLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing:            8
                        visible:            polygonSection.checked && myGeoFenceController.polygons.count > 0

                        Repeater {
                            model: myGeoFenceController.polygons
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: polyCol.height + (_margin * 2)
                                color: _colorBgSecondary
                                radius: _radius
                                border.color: _colorBorder
                                border.width: 1
                                
                                ColumnLayout {
                                    id: polyCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: _margin
                                    spacing: 12
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 15
                                        
                                        QGCCheckBox {
                                            text: qsTr("Include")
                                            checked: object.inclusion
                                            onClicked: object.inclusion = checked
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        
                                        QGCRadioButton {
                                            text: qsTr("Edit Mode")
                                            checked: object.interactive
                                            onClicked: {
                                                myGeoFenceController.clearAllInteractive()
                                                object.interactive = checked
                                            }
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Item { Layout.fillWidth: true }

                                        Button {
                                            height: 30
                                            width: 60
                                            background: Rectangle {
                                                radius: 15
                                                color: parent.pressed ? Qt.rgba(255, 69, 58, 0.2) : "transparent"
                                                border.color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorTextSecondary)
                                                border.width: 1
                                            }
                                            contentItem: Text {
                                                text: qsTr("Delete")
                                                color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorTextSecondary)
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            onClicked: myGeoFenceController.deletePolygon(index)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- CIRCULAR FENCE SECTION ---
                    Rectangle {
                        id:             circleSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         40
                        color:          _colorBgSecondary
                        radius:         _radius
                        border.color:   _colorBorder
                        border.width:   1
                        
                        property bool checked: true
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.checked = !parent.checked
                        }
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Circular Fences")
                            color: _colorTextPrimary
                            font.bold: true
                        }
                        
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.checked ? "▼" : "▶"
                            color: _colorTextSecondary
                            font.pointSize: 10
                        }
                    }

                    QGCLabel {
                        text:       qsTr("No circular fences added.")
                        color:      _colorTextSecondary
                        font.italic: true
                        visible:    circleSection.checked && myGeoFenceController.circles.count === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    ColumnLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing:            12
                        visible:            circleSection.checked && myGeoFenceController.circles.count > 0

                        Repeater {
                            model: myGeoFenceController.circles
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: circleCol.height + (_margin * 2)
                                color: _colorBgSecondary
                                radius: _radius
                                border.color: _colorBorder
                                border.width: 1
                                
                                ColumnLayout {
                                    id: circleCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: _margin
                                    spacing: 12
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 15
                                        
                                        QGCCheckBox {
                                            text: qsTr("Include")
                                            checked: object.inclusion
                                            onClicked: object.inclusion = checked
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                        
                                        QGCRadioButton {
                                            text: qsTr("Edit Mode")
                                            checked: object.interactive
                                            onClicked: {
                                                myGeoFenceController.clearAllInteractive()
                                                object.interactive = checked
                                            }
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Item { Layout.fillWidth: true }

                                        Button {
                                            height: 30
                                            width: 60
                                            background: Rectangle {
                                                radius: 15
                                                color: parent.pressed ? Qt.rgba(255, 69, 58, 0.2) : "transparent"
                                                border.color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorTextSecondary)
                                                border.width: 1
                                            }
                                            contentItem: Text {
                                                text: qsTr("Delete")
                                                color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorTextSecondary)
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            onClicked: myGeoFenceController.deleteCircle(index)
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10
                                        
                                        QGCLabel {
                                            text: qsTr("Radius:")
                                            color: _colorTextPrimary
                                            font.bold: true
                                        }
                                        Loader {
                                            Layout.fillWidth: true
                                            sourceComponent: volumeSliderComponent
                                            property var targetFact: object.radius
                                            onTargetFactChanged: if (item) item.fact = targetFact
                                            onLoaded: if (item) item.fact = targetFact
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- BREACH RETURN SECTION ---
                    Rectangle {
                        id:             breachReturnSection
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height:         40
                        color:          _colorBgSecondary
                        radius:         _radius
                        border.color:   _colorBorder
                        border.width:   1
                        
                        property bool checked: true
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.checked = !parent.checked
                        }
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Breach Return Point")
                            color: _colorTextPrimary
                            font.bold: true
                        }
                        
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: _margin
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.checked ? "▼" : "▶"
                            color: _colorTextSecondary
                            font.pointSize: 10
                        }
                    }

                    Button {
                        height: 40
                        background: Rectangle {
                            radius: _radius
                            color: parent.pressed ? _colorAccentDark : (parent.hovered ? Qt.lighter(_colorAccent, 1.1) : _colorAccent)
                        }
                        contentItem: Text {
                            text: qsTr("Add Breach Return Point")
                            color: "white"
                            font.bold: true
                            font.pointSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        visible:            breachReturnSection.checked && !myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right

                        onClicked: myGeoFenceController.breachReturnPoint = flightMap.center
                    }

                    Button {
                        height: 40
                        background: Rectangle {
                            radius: _radius
                            color: "transparent"
                            border.color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorBorder)
                            border.width: 1
                        }
                        contentItem: Text {
                            text: qsTr("Remove Breach Return Point")
                            color: parent.pressed ? _colorDangerDark : (parent.hovered ? _colorDanger : _colorTextPrimary)
                            font.bold: true
                            font.pointSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        visible:            breachReturnSection.checked && myGeoFenceController.breachReturnPoint.isValid
                        anchors.left:       parent.left
                        anchors.right:      parent.right

                        onClicked: myGeoFenceController.breachReturnPoint = QtPositioning.coordinate()
                    }

                    ColumnLayout {
                        anchors.left:       parent.left
                        anchors.right:      parent.right
                        spacing:            _margin
                        visible:            breachReturnSection.checked && myGeoFenceController.breachReturnPoint.isValid

                        QGCLabel {
                            text: qsTr("Altitude:")
                            color: _colorTextPrimary
                            font.bold: true
                        }

                        Loader {
                            Layout.fillWidth:   true
                            sourceComponent:    volumeSliderComponent
                            property var targetFact: myGeoFenceController.breachReturnAltitude
                            onTargetFactChanged: if (item) item.fact = targetFact
                            onLoaded: if (item) item.fact = targetFact
                        }
                    }
                }
            }
        }
    }
}
