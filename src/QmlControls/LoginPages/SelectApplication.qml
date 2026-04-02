import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: root
    anchors.fill: parent

    // ── Palette ─────────────────────────────────────────────────
    readonly property color brandDark:    "#1A1A1A"
    readonly property color brandPrimary: "#262626"
    readonly property color brandAccent:  "#262626"
    readonly property color pageBg:       "#EDEEF4"

    // ── Adaptive sizing helpers ──────────────────────────────────
    // Everything is derived from the actual pixel dimensions of this item
    readonly property real hPad:      Math.max(16, root.width  * 0.03)
    readonly property real vPad:      Math.max(12, root.height * 0.03)
    readonly property real cardGap:   Math.max(10, root.width  * 0.015)
    readonly property real cardH:     bodyArea.height * 0.62          // cards occupy 62 % of body
    readonly property real thumbW:    cardH * 0.58                    // square-ish left thumbnail
    readonly property real labelH:    Math.max(44, cardH * 0.22)      // bottom label strip
    readonly property real btnH:      Math.max(40, root.height* 0.065)
    readonly property real btnW:      Math.max(160, root.width * 0.22)
    readonly property real r:         12                              // universal corner radius

    signal backClicked()
    signal appSelected()

    property int selectedIndex: -1

    readonly property var appModel: [
        { label: "Camera",  desc: "Aerial photography & video",    image: "qrc:/qmlimages/NewImages/camerabg.png" },
        { label: "Agri",    desc: "Precision agriculture & spray", image: "qrc:/qmlimages/NewImages/agribg.png"   },
        { label: "Mapping", desc: "3-D mapping & surveying",       image: "qrc:/qmlimages/NewImages/mapbg.png"    }
    ]

    Component.onCompleted: {
        var saved = QGroundControl.loadGlobalSetting("loadpage", "Camera").trim()
        for (var i = 0; i < appModel.length; i++) {
            if (appModel[i].label === saved) { selectedIndex = i; break }
        }
    }

    // ════════════════════════════════════════════════════════════
    //  BACKGROUND
    // ════════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: pageBg
    }

    // ════════════════════════════════════════════════════════════
    //  HEADER
    // ════════════════════════════════════════════════════════════
    Rectangle {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Math.max(56, root.height * 0.11)
        z: 10
        color: "#262626" // Faded black

        // Glowing accent underline
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

        // Back button (small square)
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

        // Title perfectly centered
        Text {
            anchors.centerIn: parent
            text: "Mission Profile"
            font {
                family: "Outfit"
                pointSize: ScreenTools.mediumFontPointSize * 1.1
                bold: true
            }
            color: "white"
        }
    }

    // ════════════════════════════════════════════════════════════
    //  BODY  — fills everything below the header
    // ════════════════════════════════════════════════════════════
    Item {
        id: bodyArea
        anchors {
            top: header.bottom
            left: parent.left; right: parent.right; bottom: parent.bottom
        }

        // ── centred column ────────────────────────────────────────
        Column {
            anchors.centerIn: parent
            width: bodyArea.width - hPad * 2
            spacing: vPad

            // ── HORIZONTAL CARDS ───────────────────────────────────
            Row {
                id: cardRow
                width: parent.width
                height: root.cardH
                spacing: root.cardGap

                Repeater {
                    model: root.appModel

                    // ── Single card (vertical layout: image top, label bottom) ──
                    Rectangle {
                        id: card
                        width: (cardRow.width - cardRow.spacing * (root.appModel.length - 1))
                               / root.appModel.length
                        height: cardRow.height
                        radius: root.r
                        clip: true

                        readonly property bool isSelected: root.selectedIndex === index

                        color: "white"
                        border.color: isSelected ? brandAccent : "#DDE1EA"
                        border.width: isSelected ? 3 : 1

                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Behavior on border.width  { NumberAnimation  { duration: 180 } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: isSelected
                                         ? Qt.rgba(44,44,44,0.25)
                                         : Qt.rgba(0,0,0,0.08)
                            shadowBlur: 0.85
                            shadowVerticalOffset: isSelected ? 8 : 3
                        }

                        // ── Image fills top portion ───────────────
                        Rectangle {
                            id: imgBox
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: card.height - labelStrip.height
                            clip: true
                            color: brandDark
                            // top-left / top-right rounded, bottom flat
                            radius: root.r

                            // flatten bottom corners
                            Rectangle {
                                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                height: root.r
                                color: parent.color
                            }

                            Image {
                                anchors.fill: parent
                                source: modelData.image
                                fillMode: Image.PreserveAspectCrop
                                opacity: 0.9
                            }

                            // ── Check badge (top-right) ───────────
                            Rectangle {
                                visible: isSelected
                                width: Math.max(22, card.width * 0.12)
                                height: width; radius: 6
                                color: brandAccent
                                anchors { top: parent.top; right: parent.right; margins: 10 }
                                z: 5

                                QGCColoredImage {
                                    source: "qrc:/InstrumentValueIcons/checkmark.svg"
                                    width: parent.width * 0.55
                                    height: width
                                    color: "white"
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        // ── Label strip at bottom ──────────────────
                        Rectangle {
                            id: labelStrip
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: root.labelH
                            radius: root.r
                            color: isSelected ? Qt.rgba(44,44,44,0.05) : "white"
                            Behavior on color { ColorAnimation { duration: 180 } }

                            // flatten top corners
                            Rectangle {
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: root.r
                                color: parent.color
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font {
                                    family: "Outfit"
                                    pointSize: ScreenTools.defaultFontPointSize
                                    bold: true
                                }
                                color: isSelected ? brandPrimary : "#1E1E2E"
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedIndex = index
                        }
                    }
                }
            }

            // ── Divider ──────────────────────────────────────────
            Rectangle {
                width: parent.width; height: 1; color: "#D8DCE6"
            }

            // ── Bottom bar: hint + confirm ───────────────────────
            RowLayout {
                width: parent.width
                spacing: 12

                // Selection hint
                Row {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: hintText.verticalCenter
                        color: root.selectedIndex === -1 ? "#C8CDD8" : brandAccent
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                    Text {
                        id: hintText
                        text: root.selectedIndex === -1
                              ? "No profile selected"
                              : "Selected:  " + root.appModel[root.selectedIndex].label
                        font { family: "Outfit"; pointSize: ScreenTools.defaultFontPointSize }
                        color: root.selectedIndex === -1 ? "#AAB0BE" : brandPrimary
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }

                // Confirm button
                Rectangle {
                    Layout.preferredWidth:  root.btnW
                    Layout.preferredHeight: root.btnH
                    radius: 10
                    color: {
                        if (root.selectedIndex === -1) return "#C8CDD8"
                        if (cMa.pressed)               return Qt.darker(brandPrimary, 1.18)
                        if (cMa.containsMouse)         return brandAccent
                        return brandPrimary
                    }
                    Behavior on color { ColorAnimation { duration: 160 } }

                    // Arrow icon + text
                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: root.selectedIndex === -1 ? "Select a Profile" : "Confirm Selection"
                            font {
                                family: "Outfit"
                                pointSize: ScreenTools.defaultFontPointSize
                                bold: true
                            }
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-right.svg"
                            width: ScreenTools.defaultFontPixelHeight
                            height: width
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
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
