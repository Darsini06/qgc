import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals

Item {
    id: root
    anchors.fill: parent

    // ── Palette ─────────────────────────────────────────────────
    readonly property color brandDark:    "#1A1A1A"
    readonly property color brandPrimary: "#262626"
    property color brandAccent:  MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#4A2C6D"
    readonly property color pageBg:       "#EDEEF4"

    // ── Adaptive sizing helpers ──────────────────────────────────
    readonly property real hPad:      Math.max(16, root.width  * 0.03)
    readonly property real vPad:      Math.max(12, root.height * 0.03)
    readonly property real cardGap:   Math.max(10, root.width  * 0.015)
    readonly property real cardH:     bodyArea.height * 0.62
    readonly property real thumbW:    cardH * 0.58
    readonly property real labelH:    Math.max(44, cardH * 0.22)
    readonly property real btnH:      Math.max(40, root.height* 0.065)
    readonly property real btnW:      Math.max(160, root.width * 0.22)
    readonly property real r:         12

    signal backClicked()
    signal appSelected()

    property int selectedIndex: -1

    readonly property var appModel: [
        { label: "Camera",  desc: "Aerial photography & video",    image: "qrc:/qmlimages/NewImages/camerabg.png", color: "#F39C12" },
        { label: "Agri",    desc: "Precision agriculture & spray", image: "qrc:/qmlimages/NewImages/agribg.png",   color: "#79AE6F" },
        { label: "Mapping", desc: "3-D mapping & surveying",       image: "qrc:/qmlimages/NewImages/mapbg.png",    color: "#4F9DDF" },
        { label: "AI",      desc: "Intelligent autonomous missions",image: "qrc:/qmlimages/NewImages/ai_bg_image.png",color: "#8E44AD" },
        { label: "Military",desc: "Tactical & recon missions",      image: "qrc:/qmlimages/NewImages/military.png", color: "#2C3E50" }
    ]

    Component.onCompleted: {
        var saved = QGroundControl.loadGlobalSetting("loadpage", "Camera").trim()
        for (var i = 0; i < appModel.length; i++) {
            if (appModel[i].label === saved) { selectedIndex = i; break }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: pageBg
    }

    Rectangle {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Math.max(56, root.height * 0.11)
        z: 10
        color: "#262626"

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: brandAccent   }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: hPad
            width: header.height * 0.45
            height: width
            radius: 8
            color: backMa.containsMouse ? Qt.rgba(1,1,1,0.20) : Qt.rgba(1,1,1,0.09)
            Behavior on color { ColorAnimation { duration: 140 } }

            QGCColoredImage {
                source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                width: parent.width * 0.55
                height: width
                color: "white"
                anchors.centerIn: parent
            }
            MouseArea {
                id: backMa; anchors.fill: parent
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.backClicked()
            }
        }

        Text {
            anchors.centerIn: parent
            text: "Mission Profile"
            font { family: "Outfit"; pointSize: ScreenTools.mediumFontPointSize * 1.1; bold: true }
            color: "white"
        }
    }

    Item {
        id: bodyArea
        anchors {
            top: header.bottom
            left: parent.left; right: parent.right; bottom: parent.bottom
        }

        Column {
            anchors.centerIn: parent
            width: bodyArea.width - hPad * 2
            spacing: vPad

            Flickable {
                id: cardFlick
                width: parent.width
                height: root.cardH
                contentWidth: cardRow.width
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: cardRow
                    height: parent.height
                    spacing: root.cardGap
                    padding: 4

                    Repeater {
                        model: root.appModel

                        Rectangle {
                            id: card
                            // Show roughly 3.5 cards to provide a clear scrolling hint
                            width: (cardFlick.width - root.cardGap * 3) / 3.5
                            height: cardRow.height - 8
                            radius: root.r
                            clip: true

                            readonly property bool isSelected: root.selectedIndex === index

                            color: cardMa.containsMouse ? modelData.color : "white"
                            border.color: isSelected ? brandAccent : (cardMa.containsMouse ? "transparent" : "#DDE1EA")
                            border.width: isSelected ? 3 : 1

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: isSelected || cardMa.containsMouse ? Qt.rgba(0,0,0,0.2) : Qt.rgba(0,0,0,0.08)
                                shadowBlur: 0.8
                                shadowVerticalOffset: isSelected || cardMa.containsMouse ? 6 : 2
                            }

                            Rectangle {
                                id: imgBox
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: card.height - labelStrip.height
                                clip: true
                                color: "transparent"
                                radius: root.r

                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                    height: root.r
                                    color: parent.color
                                }

                                Image {
                                    anchors.fill: parent
                                    source: modelData.image
                                    fillMode: Image.PreserveAspectCrop
                                    opacity: cardMa.containsMouse ? 0.7 : 0.9
                                }

                                Rectangle {
                                    visible: isSelected
                                    width: 24; height: 24; radius: 6
                                    color: brandAccent
                                    anchors { top: parent.top; right: parent.right; margins: 8 }
                                    QGCColoredImage {
                                        source: "qrc:/InstrumentValueIcons/checkmark.svg"
                                        width: 14; height: 14; color: "white"
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Rectangle {
                                id: labelStrip
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: root.labelH
                                radius: root.r
                                color: cardMa.containsMouse ? "transparent" : (isSelected ? Qt.rgba(0,0,0,0.05) : "white")

                                Rectangle {
                                    anchors { top: parent.top; left: parent.left; right: parent.right }
                                    height: root.r
                                    color: parent.color
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font { family: "Outfit"; pointSize: ScreenTools.defaultFontPointSize; bold: true }
                                    color: cardMa.containsMouse ? "white" : (isSelected ? brandPrimary : "#1E1E2E")
                                }
                            }

                            MouseArea {
                                id: cardMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedIndex = index
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#D8DCE6" }

            RowLayout {
                width: parent.width
                spacing: 12

                Row {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: hintText.verticalCenter
                        color: root.selectedIndex === -1 ? "#C8CDD8" : brandAccent
                    }
                    Text {
                        id: hintText
                        text: root.selectedIndex === -1 ? "No profile selected" : "Selected:  " + root.appModel[root.selectedIndex].label
                        font { family: "Outfit"; pointSize: ScreenTools.defaultFontPointSize }
                        color: root.selectedIndex === -1 ? "#AAB0BE" : brandPrimary
                    }
                }

                Rectangle {
                    Layout.preferredWidth:  root.btnW
                    Layout.preferredHeight: root.btnH
                    radius: 10
                    color: root.selectedIndex === -1 ? "#C8CDD8" : (cMa.containsMouse ? brandAccent : brandPrimary)

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: root.selectedIndex === -1 ? "Select a Profile" : "Confirm Selection"
                            font { family: "Outfit"; pointSize: ScreenTools.defaultFontPointSize; bold: true }
                            color: "white"
                        }
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-right.svg"
                            width: 16; height: 16; color: "white"
                            visible: root.selectedIndex !== -1
                        }
                    }

                    MouseArea {
                        id: cMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.selectedIndex !== -1
                        onClicked: {
                            var sel = root.appModel[root.selectedIndex]
                            QGroundControl.saveGlobalSetting("loadpage", sel.label)
                            if (MapGlobals.rootWindow)
                                MapGlobals.rootWindow.showToastMessage(sel.label + " Mode Selected")
                            root.appSelected()
                        }
                    }
                }
            }
        }
    }
}
