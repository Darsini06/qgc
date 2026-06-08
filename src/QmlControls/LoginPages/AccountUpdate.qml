import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals

Item {
    id: accountUpdateRoot
    anchors.fill: parent

    // --- Design Tokens (Consistent with ProfileMain.qml) ---
    property color app_color:       MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#262626"
    property color accent_color:    MapGlobals.rootWindow ? MapGlobals.rootWindow.accent_color : "#4A2C6D"
    property color surface_color:   "#ffffff"
    property color bg_color:        "#f8f9fa"
    property color text_primary:    "#1e293b"
    property color text_muted:      "#64748b"
    property color border_color:    "#e2e8f0"

    property string userName:          ""
    property string displayName:       ""
    property string userEmail:         ""
    property string mobileNo:          ""
    property int    rpcCompletedStatus: -1

    signal backClicked()
    signal updated()

    //readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 50
    //property bool isSmallScreen: ScreenTools.isTinyScreen
    property bool isMobile: ScreenTools.isMobile
    // Phone = 1 col (<600px), Tablet = 2 cols (>=600px)
    property bool isSmallScreen: accountUpdateRoot.width < 600
    readonly property real baseMargin: ScreenTools.defaultFontPixelWidth * 1.5

    // onVisibleChanged: {

    //     if (visible) {
    //         console.log("onVisibleChanged from AccountUpdate.qml")
    //         rpcCompletedStatus = Number(MapGlobals.rpcStatus)

    //         mobileNo =  MapGlobals.mobileNo
    //     }
    // }

    Component.onCompleted: {

        console.log("isMobile in AccountUpdate",ScreenTools.isMobile)

    }

    Rectangle {
        anchors.fill: parent
        color: bg_color

        GridLayout {
            anchors.fill: parent
            columns: isSmallScreen ? 1 : 2
            rowSpacing: 0
            columnSpacing: 0

            /* ================= LEFT SIDE: PROFILE OVERVIEW ================= */
            Rectangle {
                id: sidebar
                Layout.fillHeight: !isSmallScreen
                Layout.preferredHeight: isSmallScreen ? Math.max(300, sidebarColumn.implicitHeight + 60) : -1
                Layout.preferredWidth: isSmallScreen ? -1 : 320
                Layout.fillWidth: isSmallScreen
                color: "#1A1A1A"
                clip: true

                // Back Button
                Rectangle {
                    id: backBtnContainer
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
                        onClicked: accountUpdateRoot.backClicked()
                    }
                }

                ColumnLayout {
                    id: sidebarColumn
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: isSmallScreen ? undefined : parent.verticalCenter
                    anchors.top: isSmallScreen ? backBtnContainer.bottom : undefined
                    anchors.topMargin: isSmallScreen ? 20 : 0
                    width: parent.width - (isSmallScreen ? 40 : 80)
                    spacing: 20

                    // Avatar Section (Reduced & Static)
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 85; height: 85; radius: 42.5
                        color: "#f1f5f9"
                        border.color: accent_color
                        border.width: 2
                        clip: true

                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/qmlimages/NewImages/report_gif.gif" // Using the same source but as Image to avoid animation if it's a multi-frame gif
                            width: 75; height: 75
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        Text {
                            text: displayName ? displayName : ""
                            font.family: "Outfit"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: "white"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: MapGlobals.userEmail || QGroundControl.loadGlobalSetting("email", "")
                            font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; color: Qt.rgba(255, 255, 255, 0.85); Layout.alignment: Qt.AlignHCenter
                            elide: Text.ElideRight; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        }
                        Text {
                            text: userName ? userName : ""
                            font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize * 0.9; color: Qt.rgba(255, 255, 255, 0.4); Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255, 255, 255, 0.12); Layout.topMargin: 4; Layout.bottomMargin: 4 }

                    // Stats / Quick Info
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 14

                        RowLayout {
                            spacing: 12
                            Rectangle { width: 34; height: 34; radius: 10; color: Qt.rgba(255, 255, 255, 0.1); QGCColoredImage { anchors.centerIn: parent; source: "qrc:/InstrumentValueIcons/checkmark.svg"; width: 16; height: 16; color: "white" } }
                            ColumnLayout { spacing: 0; Text { text: qsTr("Email Status"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize * 0.75; color: Qt.rgba(255, 255, 255, 0.6) } Text { text: qsTr("Verified"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: "white" } }
                        }

                        RowLayout {
                            spacing: 12
                            Rectangle { width: 34; height: 34; radius: 10; color: Qt.rgba(255, 255, 255, 0.1); QGCColoredImage { anchors.centerIn: parent; source: "qrc:/InstrumentValueIcons/checkmark.svg"; width: 16; height: 16; color: "white" } }
                            ColumnLayout { spacing: 0; Text { text: qsTr("RPC Badge"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize * 0.75; color: Qt.rgba(255, 255, 255, 0.6) } Text { text: rpcCompletedStatus === 1 ? qsTr("Certified Pilot") : qsTr("Not Certified"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: "white" } }
                        }
                    }

                    Item { Layout.preferredHeight: 12 }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Safe flight operations require updated account info.")
                        font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize * 0.8
                        color: Qt.rgba(255, 255, 255, 0.55); wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            /* ================= RIGHT SIDE: UPDATE FORM ================= */
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"

                Flickable {
                    anchors.fill: parent
                    contentHeight: formColumn.implicitHeight + (isMobile ? 80 : 100)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: formColumn

                           width: parent.width - (isMobile ? 30 : 100)

                           anchors.left: parent.left
                           anchors.leftMargin: isMobile ? 15 : 48
                           anchors.top: parent.top
                           anchors.topMargin: isMobile ? 20 : 50
                           spacing: 20

                        Text {
                            text: qsTr("ACCOUNT INFORMATION")
                            font.family: "Outfit"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: text_primary
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: border_color
                            Layout.bottomMargin: isMobile ? 2 : 10
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: isSmallScreen ? 1 : 2
                            columnSpacing: 20
                            rowSpacing: 20

                            // Full Name
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: qsTr("Full Name")
                                    font.family: "Outfit"
                                    font.pointSize: ScreenTools.smallFontPointSize
                                    font.bold: true
                                    color: text_primary
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 56
                                    radius: 10
                                    color: "#f8fafc"
                                    border.color: nameField.activeFocus ? accent_color : border_color
                                    border.width: nameField.activeFocus ? 2 : 1

                                    // QGCColoredImage {
                                    //     id: nameIcon
                                    //     source: "qrc:/InstrumentValueIcons/contacts.svg"
                                    //width: 22
                                    //height: 22
                                    //     anchors.verticalCenter: parent.verticalCenter
                                    //     anchors.left: parent.left
                                    //anchors.leftMargin: 16
                                    //     color: nameField.activeFocus ? accent_color : text_muted
                                    // }

                                    TextField {
                                        id: nameField
                                        anchors.left: parent.left        // was: nameIcon.right
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 14           // was: 10 (match email field margin)
                                        anchors.rightMargin: 12
                                        text: displayName
                                        background: null
                                        selectByMouse: true
                                        color: text_primary
                                        font.family: "Outfit"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        horizontalAlignment: Qt.AlignLeft
                                        verticalAlignment: Qt.AlignVCenter
                                        placeholderText: qsTr("Enter Full Name")
                                    }
                                }
                            }

                            // Username
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: qsTr("Username"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                                Rectangle {
                                    Layout.fillWidth: true; height: 56; radius: 10; color: "#f8fafc"
                                    border.color: usernameField.activeFocus ? accent_color : border_color
                                    border.width: usernameField.activeFocus ? 2 : 1

                                    // QGCColoredImage {
                                    //     id: userIcon
                                    //     source: "qrc:/qmlimages/NewImages/accountUpdate_black.svg"; width: 22; height: 22
                                    //     anchors.verticalCenter: parent.verticalCenter
                                    //     anchors.left: parent.left; anchors.leftMargin: 16
                                    //     color: usernameField.activeFocus ? accent_color : text_muted
                                    // }

                                    TextField {
                                        id: usernameField
                                        anchors.left: parent.left        // was: nameIcon.right
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 14           // was: 10 (match email field margin)
                                        anchors.rightMargin: 12
                                        text: userName
                                        background: null
                                        selectByMouse: true
                                        color: text_primary
                                        font.family: "Outfit"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        horizontalAlignment: Qt.AlignLeft
                                        verticalAlignment: Qt.AlignVCenter
                                        placeholderText: qsTr("Username")
                                    }
                                }
                            }

                            // Email
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: qsTr("Email Address"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                                Rectangle {
                                    Layout.fillWidth: true; height: 56; radius: 10; color: "#f8fafc"
                                    border.color: emailField.activeFocus ? accent_color : border_color
                                    border.width: emailField.activeFocus ? 2 : 1

                                    /* Email Icon removed for more space */
                                    // Item { id: emailIcon; width: 0; height: 0 }

                                    TextField {
                                        id: emailField
                                        anchors.left: parent.left        // was: nameIcon.right
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 14           // was: 10 (match email field margin)
                                        anchors.rightMargin: 12
                                        text: userEmail
                                        background: null
                                        selectByMouse: true
                                        color: text_primary
                                        font.family: "Outfit"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        //clip: true
                                        //selectionColor: accent_color
                                        //selectedTextColor: "white"
                                        horizontalAlignment: Qt.AlignLeft
                                        verticalAlignment: Qt.AlignVCenter
                                        placeholderText: qsTr("Emailllllll")
                                        //onActiveFocusChanged: if(activeFocus) cursorPosition = 0
                                    }
                                }
                            }

                            // Mobile
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 8
                                Text { text: qsTr("Mobile Number"); font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; color: text_primary }
                                Rectangle {
                                    Layout.fillWidth: true; height: 56; radius: 10; color: "#f8fafc"
                                    border.color: mobileField.activeFocus ? accent_color : border_color
                                    border.width: mobileField.activeFocus ? 2 : 1

                                    // QGCColoredImage {
                                    //     id: phoneIcon
                                    //     source: "qrc:/InstrumentValueIcons/phone-incoming.svg"; width: 22; height: 22
                                    //     anchors.verticalCenter: parent.verticalCenter
                                    //     anchors.left: parent.left; anchors.leftMargin: 16
                                    //     color: mobileField.activeFocus ? accent_color : text_muted
                                    // }

                                    TextField {
                                        id: mobileField
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 14           // was: 10 (match email field margin)
                                        anchors.rightMargin: 12
                                        text: mobileNo
                                        background: null
                                        selectByMouse: true
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        color: text_primary
                                        font.family: "Outfit"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        horizontalAlignment: Qt.AlignLeft
                                        verticalAlignment: Qt.AlignVCenter
                                        placeholderText: qsTr("Mobile No.")
                                    }
                                }
                            }
                        }

                        // RPC Question
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            Layout.topMargin: 8
                            Text { text: qsTr("Have you completed the RPC?")
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.defaultFontPointSize
                                font.bold: true
                                color: text_primary }
                            RowLayout {
                                spacing: 16

                                Repeater {
                                    model: [
                                        { label: qsTr("Yes, Certified"), val: 1 },
                                        { label: qsTr("Not Yet"),        val: 0 }
                                    ]
                                    Rectangle {
                                        Layout.preferredWidth: 160
                                        Layout.preferredHeight: 46
                                        radius: 23
                                        color:        rpcCompletedStatus === modelData.val ? accent_color : "white"
                                        border.color: rpcCompletedStatus === modelData.val ? accent_color : border_color
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text:      modelData.label
                                            color:     rpcCompletedStatus === modelData.val ? "white" : text_primary
                                            font.family: "Outfit"
                                            font.bold: rpcCompletedStatus === modelData.val
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                rpcCompletedStatus = modelData.val
                                                console.log("rpcCompletedStatus : ", modelData.val)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: isMobile ? 20 : 32 }

                        // Update Button
                        Button {
                            id: updateBtn
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 320; Layout.preferredHeight: 56
                            background: Rectangle {
                                radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: updateBtn.pressed ? Qt.darker(app_color, 1.2) : app_color }
                                    GradientStop { position: 1.0; color: updateBtn.pressed ? Qt.darker(app_color, 1.2) : app_color }
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.4); shadowBlur: 0.6; shadowVerticalOffset: 4 }
                            }
                            contentItem: Text { text: qsTr("SAVE CHANGES"); color: "white"; font.family: "Outfit"; font.pointSize: ScreenTools.smallFontPointSize; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.letterSpacing: 1 }
                            onClicked: {
                                if (!MapGlobals.validateUsername(usernameField.text, usernameField)) return;
                                if (!MapGlobals.validateDisplayName(nameField.text, nameField)) return;
                                if (!MapGlobals.validateEmail(emailField.text, emailField)) return;

                                MapGlobals.updateUser(userName, usernameField.text, nameField.text, emailField.text, mobileField.text, rpcCompletedStatus, function(result) {
                                    if (result) {
                                        QGroundControl.saveGlobalSetting("username", usernameField.text);
                                        QGroundControl.saveGlobalSetting("name", nameField.text);
                                        QGroundControl.saveGlobalSetting("email", emailField.text);
                                        QGroundControl.saveGlobalSetting("mobileNo", mobileField.text);

                                        QGroundControl.saveGlobalSetting("rpcStatus",rpcCompletedStatus.toString());

                                        MapGlobals.rpcStatus = rpcCompletedStatus
                                        MapGlobals.userName = usernameField.text
                                        MapGlobals.userEmail = emailField.text
                                        MapGlobals.displayName = nameField.text
                                        MapGlobals.mobileNo = mobileField.text

                                        console.log("mobileNumber",mobileField.text)

                                        console.log("rpcCompletedStatus in save button : ",rpcCompletedStatus)

                                        if (MapGlobals.rootWindow) MapGlobals.rootWindow.showToastMessage(qsTr("Profile updated successfully!"));
                                        accountUpdateRoot.updated();
                                    }
                                });
                            }
                        }
                    }
                }
            }
        }
    }

}
