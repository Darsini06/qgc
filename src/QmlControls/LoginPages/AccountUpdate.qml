import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: accountUpdateRoot
    anchors.fill: parent

    // --- Design Tokens (Consistent with ProfileMain.qml) ---
    property color app_color:       "#4a2c6d" 
    property color accent_color:    "#4a2c6d" 
    property color surface_color:   "#ffffff"
    property color bg_color:        "#f8f9fa"
    property color text_primary:    "#1e293b"
    property color text_muted:      "#64748b"
    property color border_color:    "#e2e8f0"

    property string userName: QGroundControl.loadGlobalSetting("username", "")
    property string name_from_db: ""
    property string email_from_db: ""
    property string mobileNo_from_db: ""
    property int rpcCompletedStatus: -1

    signal backClicked()
    signal updated()

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 60
    readonly property real baseMargin: ScreenTools.defaultFontPixelWidth * 1.5

    Rectangle {
        anchors.fill: parent
        color: bg_color

        /* ================= CINEMATIC HEADER ================= */
        Rectangle {
            id: headerContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: isSmallScreen ? 150 : 180
            clip: true
            color: app_color
            z: 10

            // Background Texture
            Image {
                anchors.fill: parent
                source: "qrc:/qmlimages/NewImages/nature_background.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.2
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.6) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Back Button (Consistent with ProfileMain)
            Rectangle {
                id: backBtnContainer
                width: 44; height: 44; radius: 12
                color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(255, 255, 255, 0.08)
                border.color: Qt.rgba(255, 255, 255, 0.2)
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: parent.top; anchors.topMargin: 20
                z: 20
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
                    onClicked: accountUpdateRoot.backClicked()
                }
            }

            // Header Content
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 40
                spacing: 4

                Text {
                    text: "Account Settings"
                    color: "white"
                    font.family: "Outfit"
                    font.pointSize: ScreenTools.largeFontPointSize
                    font.bold: true
                }
                Text {
                    text: "Manage your personal information and flight credentials"
                    color: Qt.rgba(255, 255, 255, 0.7)
                    font.family: "Outfit"
                    font.pointSize: ScreenTools.smallFontPointSize
                    visible: !isSmallScreen
                }
            }
        }

        /* ================= SCROLLABLE CONTENT ================= */
        Flickable {
            anchors.top: headerContainer.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: -40 
            contentHeight: mainColumn.height + 80
            clip: true
            z: 20
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: mainColumn
                width: parent.width
                spacing: 32

                Item { Layout.preferredHeight: 1 }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(650, parent.width - 40)
                    Layout.preferredHeight: formColumn.implicitHeight + (isSmallScreen ? 40 : 80)
                    radius: 24
                    color: "white"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0,0,0,0.06)
                        shadowBlur: 1.0
                        shadowVerticalOffset: 12
                    }

                    ColumnLayout {
                        id: formColumn
                        anchors.fill: parent
                        anchors.margins: isSmallScreen ? 24 : 48
                        spacing: 24

                        Text {
                            text: "PERSONAL INFORMATION"
                            font.family: "Outfit"
                            font.pointSize: ScreenTools.smallFontPointSize * 0.85
                            font.bold: true
                            color: text_muted
                            font.letterSpacing: 1.5
                            Layout.bottomMargin: 4
                        }

                        // Full Name
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "Full Name"; font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: 12; color: nameField.activeFocus ? "white" : "#f8fafc"
                                border.color: nameField.activeFocus ? accent_color : border_color
                                border.width: nameField.activeFocus ? 2 : 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    QGCColoredImage { source: "qrc:/InstrumentValueIcons/contacts.svg"; width: 20; height: 20; color: nameField.activeFocus ? accent_color : text_muted }
                                    TextField { id: nameField; Layout.fillWidth: true; text: name_from_db; background: null; selectByMouse: true; color: text_primary; font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize; verticalAlignment: TextInput.AlignVCenter; placeholderText: "Enter Full Name" }
                                }
                            }
                        }

                        // Username
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "Username"; font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: 12; color: usernameField.activeFocus ? "white" : "#f8fafc"
                                border.color: usernameField.activeFocus ? accent_color : border_color
                                border.width: usernameField.activeFocus ? 2 : 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    QGCColoredImage { source: "qrc:/qmlimages/NewImages/accountUpdate_black.svg"; width: 20; height: 20; color: usernameField.activeFocus ? accent_color : text_muted }
                                    TextField { id: usernameField; Layout.fillWidth: true; text: userName; background: null; selectByMouse: true; color: text_primary; font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize; verticalAlignment: TextInput.AlignVCenter; placeholderText: "Username" }
                                }
                            }
                        }

                        // Email
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "Email Address"; font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: 12; color: emailField.activeFocus ? "white" : "#f8fafc"
                                border.color: emailField.activeFocus ? accent_color : border_color
                                border.width: emailField.activeFocus ? 2 : 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    QGCColoredImage { source: "qrc:/InstrumentValueIcons/paper-plane.svg"; width: 20; height: 20; color: emailField.activeFocus ? accent_color : text_muted }
                                    TextField { id: emailField; Layout.fillWidth: true; text: email_from_db; background: null; selectByMouse: true; color: text_primary; font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize; verticalAlignment: TextInput.AlignVCenter; placeholderText: "Email" }
                                }
                            }
                        }

                        // Mobile
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "Mobile Number"; font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                            Rectangle {
                                Layout.fillWidth: true; height: 52; radius: 12; color: mobileField.activeFocus ? "white" : "#f8fafc"
                                border.color: mobileField.activeFocus ? accent_color : border_color
                                border.width: mobileField.activeFocus ? 2 : 1
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    QGCColoredImage { source: "qrc:/InstrumentValueIcons/phone-incoming.svg"; width: 20; height: 20; color: mobileField.activeFocus ? accent_color : text_muted }
                                    TextField { id: mobileField; Layout.fillWidth: true; text: mobileNo_from_db; background: null; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly; color: text_primary; font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize; verticalAlignment: TextInput.AlignVCenter; placeholderText: "Mobile No." }
                                }
                            }
                        }

                        // RPC Question
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 14; Layout.topMargin: 8
                            Text { text: "Have you completed the RPC?"; font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true; color: text_primary }
                            RowLayout {
                                spacing: 16
                                Repeater {
                                    model: [{label: "Yes, Certified", val: 1}, {label: "Not Yet", val: 0}]
                                    Rectangle {
                                        Layout.preferredWidth: isSmallScreen ? 140 : 160; Layout.preferredHeight: 46; radius: 23
                                        color: rpcCompletedStatus === modelData.val ? accent_color : "#f1f5f9"
                                        border.color: rpcCompletedStatus === modelData.val ? accent_color : "#e2e8f0"
                                        border.width: 1
                                        Text { anchors.centerIn: parent; text: modelData.label; color: rpcCompletedStatus === modelData.val ? "white" : text_primary; font.family: "Outfit"; font.bold: rpcCompletedStatus === modelData.val }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rpcCompletedStatus = modelData.val }
                                    }
                                }
                            }
                        }

                            Item { Layout.preferredHeight: 16 }

                            // Update Button
                            Button {
                                id: updateBtn
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 280; Layout.preferredHeight: 56
                                background: Rectangle {
                                    radius: 28
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: updateBtn.pressed ? app_color : accent_color }
                                        GradientStop { position: 1.0; color: updateBtn.pressed ? accent_color : "#9c27b0" }
                                    }
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: Qt.rgba(124/255, 77/255, 255/255, 0.4)
                                        shadowBlur: 0.6; shadowVerticalOffset: 6
                                    }
                                }

                                contentItem: RowLayout {
                                    spacing: 12
                                    Item { Layout.fillWidth: true }
                                    QGCColoredImage { source: "qrc:/InstrumentValueIcons/publish.svg"; width: 20; height: 20; color: "white" }
                                    Text {
                                        text: "Save & Synchronize"
                                        color: "white"; font.family: "Outfit"; font.pointSize: ScreenTools.defaultFontPointSize; font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                onClicked: {
                                    if (!MapGlobals.validateUsername(usernameField.text, usernameField)) return;
                                    if (!MapGlobals.validateDisplayName(nameField.text, nameField)) return;
                                    if (!MapGlobals.validateEmail(emailField.text, emailField)) return;

                                    MapGlobals.updateUser(userName, usernameField.text, nameField.text, emailField.text, mobileField.text, rpcCompletedStatus, function(result) {
                                        if (result) {
                                            QGroundControl.saveGlobalSetting("username", usernameField.text);
                                            QGroundControl.saveGlobalSetting("name", nameField.text);
                                            QGroundControl.saveGlobalSetting("email", emailField.text);
                                            if (MapGlobals.rootWindow) MapGlobals.rootWindow.showToastMessage("Profile updated successfully!");
                                            accountUpdateRoot.updated();
                                        }
                                    });
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 40 } // Bottom padding
                }
            }
        }
    }

