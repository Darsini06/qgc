import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0
import Qt.labs.lottieqt 1.0

Item {
    id: feedbackRoot
    anchors.fill: parent

    property string userName: QGroundControl.loadGlobalSetting("username", "")
    property color app_color: "#4a2c6d"
    property color accent_color: "#7c4dff"
    property color sidebar_color: "#2d1b4d"
    property color bg_color: "#FFFFFF"
    property color input_bg: "#F9FAFB"
    property color border_color: "#E5E7EB"
    property color text_primary: "#111827"
    property color text_secondary: "#4B5563"

    signal backClicked()

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 80

    Rectangle {
        anchors.fill: parent
        color: bg_color

        RowLayout {
            anchors.fill: parent
            spacing: 0

            /* ================= SIDEBAR (40%) ================= */
            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: isSmallScreen ? 0 : parent.width * 0.38
                visible: !isSmallScreen
                color: sidebar_color
                clip: true

                // Background Gradient Detail
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: sidebar_color }
                        GradientStop { position: 1.0; color: Qt.darker(sidebar_color, 1.2) }
                    }
                }

                // Decorative Circles for 'Classy' feel
                Rectangle {
                    width: 300; height: 300; radius: 150
                    color: Qt.rgba(1,1,1,0.03)
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    anchors.margins: -100
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    spacing: 30

                    // Back Arrow (Premium)
                    Rectangle {
                        width: 44; height: 44; radius: 12
                        color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                        border.color: Qt.rgba(255, 255, 255, 0.2)
                        
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 22; height: 22; color: "white"
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: feedbackRoot.backClicked()
                        }
                    }

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Text {
                            text: "Feedback"
                            font.family: "Outfit"
                            font.pointSize: 32
                            font.bold: true
                            color: "white"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Help us shape the future of flight. Your insights drive our continuous improvement."
                            font.family: "Outfit"
                            font.pointSize: ScreenTools.defaultFontPointSize
                            color: Qt.rgba(255, 255, 255, 0.7)
                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                        }
                    }

                    Item {
                        Layout.preferredHeight: 100
                        Layout.fillWidth: true
                        LottieAnimation {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/qmlimages/NewImages/feedback_1.json"
                            autoPlay: true; loops: Animation.Infinite
                            width: 120; height: 120
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            /* ================= FORM AREA (60%) ================= */
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"

                // Mobile Header (only visible on small screens)
                Rectangle {
                    visible: isSmallScreen
                    width: parent.width; height: 70
                    color: "transparent"
                    anchors.top: parent.top
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        QGCColoredImage {
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 24; height: 24; color: text_primary
                            MouseArea { anchors.fill: parent; onClicked: feedbackRoot.backClicked() }
                        }
                        Text { text: "Feedback"; font.family: "Outfit"; font.bold: true; font.pointSize: ScreenTools.mediumFontPointSize; color: text_primary }
                    }
                }

                Flickable {
                    id: formFlickable
                    anchors.fill: parent
                    anchors.topMargin: isSmallScreen ? 70 : 0
                    contentWidth: width
                    contentHeight: formContainer.height + (isSmallScreen ? 40 : 100)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: formContainer
                        width: Math.min(500, parent.width - 60)
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: isSmallScreen ? 20 : 80
                        spacing: 40

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "Get in Touch"
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.mediumFontPointSize
                                font.bold: true
                                color: text_primary
                            }
                            Text {
                                text: "Please fill out the form below."
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.smallFontPointSize
                                color: text_secondary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 24

                            // Contact Number
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: "Contact Number"; font.family: "Outfit"; font.bold: true; color: text_primary; font.pointSize: ScreenTools.smallFontPointSize * 0.9 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 50; radius: 8
                                    color: input_bg; border.color: feed_mobile.activeFocus ? app_color : border_color
                                    border.width: feed_mobile.activeFocus ? 2 : 1
                                    TextField {
                                        id: feed_mobile; anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                        font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize
                                        placeholderText: "Enter your contact number"; color: text_primary; background: null
                                    }
                                }
                            }

                            // Email
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: "Email Address"; font.family: "Outfit"; font.bold: true; color: text_primary; font.pointSize: ScreenTools.smallFontPointSize * 0.9 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 50; radius: 8
                                    color: input_bg; border.color: feed_email.activeFocus ? app_color : border_color
                                    border.width: feed_email.activeFocus ? 2 : 1
                                    TextField {
                                        id: feed_email; anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                        font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize
                                        placeholderText: "Enter your email"; color: text_primary; background: null
                                    }
                                }
                            }

                            // Feedback
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: "Message"; font.family: "Outfit"; font.bold: true; color: text_primary; font.pointSize: ScreenTools.smallFontPointSize * 0.9 }
                                Rectangle {
                                    Layout.fillWidth: true; height: 160; radius: 8
                                    color: input_bg; border.color: feedbackArea.activeFocus ? app_color : border_color
                                    border.width: feedbackArea.activeFocus ? 2 : 1
                                    TextArea {
                                        id: feedbackArea; anchors.fill: parent; anchors.margins: 12
                                        font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize
                                        placeholderText: "How can we help you?"; wrapMode: TextArea.Wrap; color: text_primary; background: null
                                    }
                                }
                            }
                        }

                        Button {
                            id: submitBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            
                            contentItem: Text {
                                text: "Submit Feedback"
                                font.family: "Outfit"; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize
                                color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: 8
                                color: submitBtn.pressed ? Qt.darker(app_color, 1.1) : (submitBtn.hovered ? Qt.lighter(app_color, 1.1) : app_color)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: submitBtn.hovered
                                    shadowColor: Qt.rgba(74, 44, 109, 0.3)
                                    shadowBlur: 0.6
                                    shadowVerticalOffset: 4
                                }
                            }

                            onClicked: {
                                if (feedbackArea.text === "") {
                                    if (MapGlobals.rootWindow) MapGlobals.rootWindow.showToastMessage("Please enter your message")
                                    return
                                }
                                MapGlobals.insertFeedback(
                                    userName,
                                    feed_mobile.text,
                                    feed_email.text,
                                    feedbackArea.text,
                                    function(ok) {
                                        if (ok) {
                                            if (MapGlobals.rootWindow) MapGlobals.rootWindow.showToastMessage("Feedback sent successfully!")
                                            feedbackRoot.backClicked()
                                        } else {
                                            if (MapGlobals.rootWindow) MapGlobals.rootWindow.showToastMessage("Failed to send feedback")
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}



