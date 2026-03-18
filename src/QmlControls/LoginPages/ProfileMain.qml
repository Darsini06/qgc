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
    property color app_color: "#4a2c6d" 
    property color accent_color: "#7c4dff" 
    property color surface_color: "#ffffff"
    property color bg_color: "#f8f9fa"

    signal menuItemSelected(string screenName)
    signal backClicked()

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 60
    readonly property real baseMargin: ScreenTools.defaultFontPixelWidth * 1.5

    // Background Container
    Rectangle {
        anchors.fill: parent
        color: bg_color

        /* ================= CINEMATIC HEADER ================= */
        Rectangle {
            id: headerContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: isSmallScreen ? 200 : 250
            clip: true
            color: app_color

            // Background Image Overlay for Texture
            Image {
                anchors.fill: parent
                source: "qrc:/qmlimages/NewImages/nature_background.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.25
                asynchronous: true
            }

            // Darker Gradient Mask
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.2) }
                }
            }

            // Back Button (Premium Glass Look)
            Rectangle {
                width: 44; height: 44; radius: 12
                color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(255, 255, 255, 0.08)
                border.color: Qt.rgba(255, 255, 255, 0.2)
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: parent.top; anchors.topMargin: 20
                Behavior on color { ColorAnimation { duration: 200 } }

                QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                    width: 24; height: 24; color: "white"
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: profileMainRoot.backClicked()
                }
            }

            // ID Badge Section
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                // Avatar with Pulse Shadow
                Rectangle {
                    id: avatarContainer
                    Layout.alignment: Qt.AlignHCenter
                    width: isSmallScreen ? 90 : 110
                    height: width
                    radius: width / 2
                    color: "white"
                    border.color: accent_color
                    border.width: 3
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: accent_color
                        shadowBlur: 0.6
                        shadowVerticalOffset: 0
                    }

                    AnimatedImage {
                        anchors.fill: parent
                        anchors.margins: 4
                        source: "qrc:/qmlimages/NewImages/report_gif.gif"
                        fillMode: Image.PreserveAspectCrop
                        playing: true
                    }
                }

                Column {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: displayName || "Commander"
                        color: "white"
                        font.pointSize: isSmallScreen ? ScreenTools.mediumFontPointSize : ScreenTools.largeFontPointSize
                        font.bold: true
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
        }

        /* ================= SCROLLABLE CONTENT ================= */
        Flickable {
            anchors.top: headerContainer.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: -40 // Overlap for depth
            contentHeight: mainColumn.height + 60
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: mainColumn
                width: Math.min(850, parent.width - 40)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                // Dashboard row (Stats)
                RowLayout {
                    width: parent.width
                    spacing: 20

                    Repeater {
                        model: [
                            { label: "AIR TIME", value: totalDurationFormatted, icon: "qrc:/qmlimages/NewImages/total_hours.svg", color: "#6366f1" },
                            { label: "MISSIONS", value: missionsCompleted, icon: "qrc:/qmlimages/NewImages/mission_complete.svg", color: "#f59e0b" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            radius: 16
                            color: "white"
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Qt.rgba(0,0,0,0.05)
                                shadowBlur: 0.8
                                shadowVerticalOffset: 4
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Rectangle {
                                    width: 52; height: 52; radius: 14
                                    color: Qt.rgba(modelData.color === "#6366f1" ? 99/255 : 245/255, modelData.color === "#6366f1" ? 102/255 : 158/255, modelData.color === "#6366f1" ? 241/255 : 11/255, 0.1)
                                    
                                    QGCColoredImage {
                                        anchors.centerIn: parent
                                        source: modelData.icon
                                        width: 28; height: 28; color: modelData.color
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Text { text: modelData.label; font.pointSize: ScreenTools.smallFontPointSize * 0.8; font.bold: true; color: "#94a3b8"; font.letterSpacing: 1.2 }
                                    Text { text: modelData.value.toString(); font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: "#1e293b" }
                                }
                            }
                        }
                    }
                }

                // Menu Section (The "Card")
                Rectangle {
                    width: parent.width
                    height: menuItemsColumn.implicitHeight + 40
                    radius: 20
                    color: "white"
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0,0,0,0.05)
                        shadowBlur: 1.0
                        shadowVerticalOffset: 10
                    }

                    ColumnLayout {
                        id: menuItemsColumn
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 0

                        // Section Title
                        Text {
                            text: "SETTINGS & PREFERENCES"
                            font.pointSize: ScreenTools.smallFontPointSize * 0.85
                            font.bold: true
                            color: "#64748b"
                            font.letterSpacing: 1.5
                            Layout.bottomMargin: 15
                            Layout.leftMargin: 10
                        }

                        Repeater {
                            model: [
                                { "id": "accountUpdate",  "name": "Account Settings", "desc": "Update your credentials and personal info", "icon": "qrc:/qmlimages/NewImages/accountUpdate_black.svg", "color": "#475569" },
                                { "id": "reports",        "name": "Mission History", "desc": "View logs and performance of previous flights", "icon": "qrc:/qmlimages/NewImages/report_color.svg", "color": "#475569" },
                                { "id": "drone",          "name": "Switch Operation Mode", "desc": "Change between Camera, Agri, and Mapping modes", "icon": "qrc:/qmlimages/NewImages/select_drone_type_color.svg", "color": "#475569" },
                                { "id": "feedback",       "name": "Submit Feedback", "desc": "Help us improve by sending your suggestions", "icon": "qrc:/qmlimages/NewImages/feedback_color.svg", "color": "#475569" },
                                { "id": "privacy_policy", "name": "Privacy Policy", "desc": "How we manage and protect your mission data", "icon": "qrc:/qmlimages/NewImages/privacy_policy_black.svg", "color": "#475569" },
                                { "id": "terms&conditions", "name": "Terms & Conditions", "desc": "Review user agreements and flight rules", "icon": "qrc:/qmlimages/NewImages/terms_condition_black.svg", "color": "#475569" },
                                { "id": "logout",         "name": "Sign Out", "desc": "Securely logout from your current session", "icon": "qrc:/qmlimages/NewImages/logout_color.svg", "color": "#ef4444" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 12
                                color: mouseItem.containsMouse ? "#f8fafc" : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    spacing: 16

                                    Rectangle {
                                        width: 42; height: 42; radius: 10
                                        color: "#f1f5f9"
                                        
                                        Image {
                                            anchors.centerIn: parent
                                            source: modelData.icon
                                            width: 22; height: 22
                                            fillMode: Image.PreserveAspectFit
                                            opacity: 0.9
                                            visible: modelData.isPng === true || modelData.icon.indexOf("color") !== -1 || modelData.icon.indexOf("select_drone") !== -1
                                        }

                                        QGCColoredImage {
                                            anchors.centerIn: parent
                                            source: modelData.icon
                                            width: 22; height: 22
                                            color: modelData.color
                                            visible: !parent.children[0].visible
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        Text { text: modelData.name; font.pointSize: ScreenTools.defaultFontPointSize; font.weight: Font.DemiBold; color: modelData.color }
                                        Text { text: modelData.desc; font.pointSize: ScreenTools.smallFontPointSize * 0.85; color: "#94a3b8"; visible: !isSmallScreen }
                                    }

                                    QGCColoredImage {
                                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                                        width: 16; height: 16; color: "#cbd5e1"
                                        rotation: 180
                                        visible: modelData.id !== "logout"
                                    }
                                }

                                MouseArea {
                                    id: mouseItem
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: profileMainRoot.menuItemSelected(modelData.id)
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 68
                                    height: 1
                                    color: "#f1f5f9"
                                    visible: index < 5 // Hide for last item
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
