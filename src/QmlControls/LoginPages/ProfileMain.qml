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
    id: profileMainRoot
    anchors.fill: parent

    property string displayName: ""
    property string userEmail: ""
    property string totalDurationFormatted: "0h 0m"
    property int missionsCompleted: 0
    property color app_color: "#262626"
    property color accent_color: "#262626"
    property color surface_color: "#ffffff"
    property color bg_color: "#f8f9fa"

    signal menuItemSelected(string screenName)
    signal backClicked()

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 100

    RowLayout {
        anchors.fill: parent
        spacing: 0

        /* ================= LEFT SIDE (Static, Centered, Background Image) ================= */
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.45
            // Background Charcoal Color
            color: "#1A1A1A"
            clip: true

            // Back Arrow Navigation
            Rectangle {
                id: backBtn
                width: 44; height: 44; radius: 12
                color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(255, 255, 255, 0.1)
                border.color: Qt.rgba(255, 255, 255, 0.2)
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: parent.top; anchors.topMargin: 20
                z: 20
                
                QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    width: 24; height: 24; color: "white"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: profileMainRoot.backClicked()
                }
            }

            // Centered Profile Content
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 60
                spacing: 35

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 100; height: 100; radius: 50 // Reduced Size
                        color: "white"
                        border.color: accent_color
                        border.width: 3
                        Image { // Removed Animation (Standard Image)
                            anchors.fill: parent
                            anchors.margins: 4
                            source: "qrc:/qmlimages/NewImages/report_gif.gif"
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                    Column {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: displayName || "Commander"
                            color: "white"; font.bold: true
                            font.pointSize: ScreenTools.mediumFontPointSize // Slightly reduced
                            font.family: "Outfit"
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: userEmail || "contact@aviatricks.com"
                            color: Qt.rgba(255, 255, 255, 0.7)
                            font.pointSize: ScreenTools.smallFontPointSize
                            font.family: "Outfit"
                        }
                    }
                }

                // Mission Stats Section (Reduced Containers)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "MISSION STATS"
                        color: Qt.rgba(255, 255, 255, 0.5)
                        font.pointSize: 8; font.bold: true; font.letterSpacing: 1.2
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Rectangle {
                            Layout.fillWidth: true; height: 75; radius: 15; color: "white" // Reduced Height
                            Column {
                                anchors.centerIn: parent
                                Text { text: "AIR TIME"; color: "#94a3b8"; font.pointSize: 6.5; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: totalDurationFormatted; color: "#1e293b"; font.pointSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 75; radius: 15; color: "white" // Reduced Height
                            Column {
                                anchors.centerIn: parent
                                Text { text: "MISSIONS"; color: "#94a3b8"; font.pointSize: 6.5; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: missionsCompleted.toString(); color: "#1e293b"; font.pointSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }
                }
            }
        }

        /* ================= RIGHT SIDE (Scrollable Settings Menu) ================= */
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: bg_color

            Flickable {
                anchors.fill: parent
                contentHeight: rightContentColumn.height + 100
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: rightContentColumn
                    width: parent.width - 80
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 50
                    spacing: 30

                    Text {
                        text: "SETTINGS & PREFERENCES"
                        color: "#94a3b8"
                        font.pointSize: 9; font.bold: true; font.letterSpacing: 1.2
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: [
                                { "id": "accountUpdate", "name": "Account Settings", "icon": "qrc:/qmlimages/NewImages/accountUpdate_black.svg" },
                                { "id": "reports", "name": "Mission History", "icon": "qrc:/qmlimages/NewImages/report_color.svg" },
                                { "id": "logfiles","name": "Log Files", "desc": "View logs and performance of previous flights",
                                    "icon": "qrc:/qmlimages/NewImages/report_color.svg", "color": "#475569" },
                                { "id": "drone", "name": "Operation Mode", "icon": "qrc:/qmlimages/NewImages/select_drone_type_color.svg" },
                                { "id": "feedback", "name": "Submit Feedback", "icon": "qrc:/qmlimages/NewImages/feedback_color.svg" },
                                { "id": "privacy_policy", "name": "Privacy Policy", "icon": "qrc:/qmlimages/NewImages/privacy_policy_black.svg" },
                                { "id": "terms&conditions", "name": "Terms & Conditions", "icon": "qrc:/qmlimages/NewImages/terms_condition_black.svg" },
                                { "id": "logout", "name": "Sign Out", "icon": "qrc:/qmlimages/NewImages/signIn.svg", "isWarning": true }
                            ]

                            Rectangle {
                                Layout.fillWidth: true; height: 68; radius: 14
                                color: mouseItem.containsMouse ? "white" : "transparent"
                                border.color: mouseItem.containsMouse ? "#f1f5f9" : "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 20; spacing: 20
                                    Rectangle {
                                        width: 44; height: 44; radius: 10; color: "#f1f5f9"
                                        QGCColoredImage {
                                            anchors.centerIn: parent
                                            source: modelData.icon; width: 22; height: 22
                                            color: modelData.isWarning ? "#ef4444" : "#475569"
                                        }
                                    }
                                    Text {
                                        text: modelData.name
                                        color: modelData.isWarning ? "#ef4444" : "#1e293b"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.weight: Font.DemiBold; font.family: "Outfit"
                                    }
                                    Item { Layout.fillWidth: true }
                                    QGCColoredImage {
                                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                                        width: 16; height: 16; color: "#cbd5e1"
                                        rotation: 180; visible: !modelData.isWarning
                                    }
                                }

                                MouseArea {
                                    id: mouseItem
                                    anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: profileMainRoot.menuItemSelected(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        var p = parent
        while (p) {
            if (p.flickableDirection !== undefined) {
                p.interactive = false
                break
            }
            p = p.parent
        }
    }
}
