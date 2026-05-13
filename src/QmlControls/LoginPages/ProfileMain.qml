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
    property string username: ""
    property string totalDurationFormatted: "0h 0m"
    property int missionsCompleted: 0
    property color app_color: "#262626"
    property color accent_color: "#262626"
    property color surface_color: "#ffffff"
    property color bg_color: "#f8f9fa"

    signal menuItemSelected(string screenName)
    signal backClicked()
    onMenuItemSelected: {
        if (screenName === "changePassword") {
            changePasswordDialog.open()
        }
    }
    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 100

    RowLayout {
        anchors.fill: parent
        spacing: 0

        /* ================= LEFT SIDE (Static, Centered, Background Image) ================= */
        Rectangle {
            id: leftPanel
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.45
            color: app_color
            clip: true

            // Background Gradient
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: app_color }
                    GradientStop { position: 1.0; color: "#1A1A1A" }
                }
            }

            // Decorative Accents
            Rectangle {
                width: 400; height: 400; radius: 200; color: Qt.rgba(255,255,255,0.03)
                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: -80
            }

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
                                { "id": "cloudPlans",    "name": "Cloud Plans",      "icon": "qrc:/qmlimages/NewImages/report_color.svg" },
                                { "id": "reports",       "name": "Mission History",  "icon": "qrc:/qmlimages/NewImages/report_color.svg" },
                                { "id": "logfiles",      "name": "Log Files",        "desc": "View logs and performance of previous flights",
                                    "icon": "qrc:/qmlimages/NewImages/report_color.svg", "color": "#475569" },
                                { "id": "drone",         "name": "Operation Mode",   "icon": "qrc:/qmlimages/NewImages/select_drone_type_color.svg" },
                                { "id": "feedback",      "name": "Submit Feedback",  "icon": "qrc:/qmlimages/NewImages/feedback_color.svg" },
                                { "id": "privacy_policy", "name": "Privacy Policy",  "icon": "qrc:/qmlimages/NewImages/privacy_policy_black.svg" },
                                { "id": "terms&conditions", "name": "Terms & Conditions", "icon": "qrc:/qmlimages/NewImages/terms_condition_black.svg" },
                                { "id": "changePassword", "name": "Change Password", "icon": "qrc:/qmlimages/NewImages/privacy_policy_black.svg" },
                                { "id": "logout",         "name": "Sign Out",         "icon": "qrc:/qmlimages/NewImages/signIn.svg", "isWarning": true }
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
                                    onClicked: {
                                        if (modelData.id === "cloudPlans") {
                                            MapGlobals.jumpToFileList = true
                                            profileMainRoot.menuItemSelected("logfiles")
                                        } else {
                                            profileMainRoot.menuItemSelected(modelData.id)
                                        }
                                    }
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
    // Change Password Dialog
    Dialog {
        id: changePasswordDialog
        property bool showOldPass: false
        property bool showNewPass: false
        property bool showConfirmPass: false
        modal: true
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 400) // Small, professional compact size
        padding: 0 // Use custom padding in contentItem to avoid QML bugs

        background: Rectangle {
            color: "white"
            radius: 16
            layer.enabled: true
        }

        // Custom header
        header: Item {
            height: 64

            Rectangle {
                anchors.fill: parent
                color: app_color
                radius: 16

                // Square off bottom corners
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 16
                    color: app_color
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16

                QGCColoredImage {
                    source: "/qmlimages/NewImages/privacy_policy_black.svg"
                    width: 22; height: 22
                    color: "white"
                }

                Text {
                    text: "Change Password"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.weight: Font.Bold
                    font.family: "Outfit"
                    color: "white"
                    Layout.fillWidth: true
                }

                // Close button
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: closeBtnMouse.containsMouse ? Qt.rgba(1,1,1,0.2) : "transparent"

                    Item {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        
                        Rectangle {
                            width: parent.width * 1.414
                            height: Math.max(2, Math.round(ScreenTools.defaultFontPointSize * 0.15))
                            color: "white"
                            anchors.centerIn: parent
                            rotation: 45
                            antialiasing: true
                        }
                        
                        Rectangle {
                            width: parent.width * 1.414
                            height: Math.max(2, Math.round(ScreenTools.defaultFontPointSize * 0.15))
                            color: "white"
                            anchors.centerIn: parent
                            rotation: -45
                            antialiasing: true
                        }
                    }

                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: changePasswordDialog.close()
                    }
                }
            }
        }

        contentItem: Item {
            // Set max height dynamically (up to 80% of screen) to enforce scrolling if content is too large
            property real maxDialogHeight: Overlay.overlay ? Overlay.overlay.height * 0.8 : 500
            implicitHeight: Math.min(scrollContainer.implicitHeight, maxDialogHeight)

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Item {
                    id: scrollContainer
                    width: parent.width
                    implicitHeight: mainLayout.implicitHeight + 48

                    ColumnLayout {
                        id: mainLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 24 // Flawless padding around all edges inside the scroll area
                        spacing: 20

                        // Subtitle
                        Text {
                            text: "Enter your current password and set a new one"
                            font.pointSize: ScreenTools.smallFontPointSize
                            color: "#94a3b8"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        // Old Password
                        ColumnLayout {
                            spacing: 8
                            Layout.fillWidth: true

                            Row {
                                spacing: 4
                                Text {
                                    text: "Current Password"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.DemiBold
                                    color: "#1e293b"
                                }
                                Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "#ef4444" }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 45
                                radius: 8
                                border.color: oldPasswordInput.activeFocus ? app_color : "#e2e8f0"
                                border.width: oldPasswordInput.activeFocus ? 2 : 1
                                color: "#f8fafc"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    TextField {
                                        id: oldPasswordInput
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        echoMode: changePasswordDialog.showOldPass ? TextInput.Normal : TextInput.Password
                                        placeholderText: "Enter current password"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Outfit"
                                        color: "#1e293b"
                                        verticalAlignment: TextInput.AlignVCenter
                                        background: null
                                    }

                                    Button {
                                        width: 32; height: 32
                                        checkable: true
                                        checked: changePasswordDialog.showOldPass
                                        onCheckedChanged: changePasswordDialog.showOldPass = checked
                                        background: Rectangle { radius: 6; color: parent.hovered ? Qt.rgba(0,0,0,0.05) : "transparent" }
                                        contentItem: QGCColoredImage {
                                            anchors.fill: parent; anchors.margins: 6
                                            fillMode: Image.PreserveAspectFit
                                            source: parent.checked ? "/qmlimages/NewImages/password_visible.svg" : "/qmlimages/NewImages/password_hidden.svg"
                                            color: app_color
                                        }
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#f1f5f9"
                        }

                        // New Password
                        ColumnLayout {
                            spacing: 8
                            Layout.fillWidth: true

                            Row {
                                spacing: 4
                                Text {
                                    text: "New Password"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.DemiBold
                                    color: "#1e293b"
                                }
                                Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "#ef4444" }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 45
                                radius: 8
                                border.color: newPasswordInput.activeFocus ? app_color : "#e2e8f0"
                                border.width: newPasswordInput.activeFocus ? 2 : 1
                                color: "#f8fafc"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    TextField {
                                        id: newPasswordInput
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        echoMode: changePasswordDialog.showNewPass ? TextInput.Normal : TextInput.Password
                                        placeholderText: "Min 4 characters"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Outfit"
                                        color: "#1e293b"
                                        verticalAlignment: TextInput.AlignVCenter
                                        background: null
                                    }

                                    Button {
                                        width: 32; height: 32
                                        checkable: true
                                        checked: changePasswordDialog.showNewPass
                                        onCheckedChanged: changePasswordDialog.showNewPass = checked
                                        background: Rectangle { radius: 6; color: parent.hovered ? Qt.rgba(0,0,0,0.05) : "transparent" }
                                        contentItem: QGCColoredImage {
                                            anchors.fill: parent; anchors.margins: 6
                                            fillMode: Image.PreserveAspectFit
                                            source: parent.checked ? "/qmlimages/NewImages/password_visible.svg" : "/qmlimages/NewImages/password_hidden.svg"
                                            color: app_color
                                        }
                                    }
                                }
                            }
                        }

                        // Confirm Password
                        ColumnLayout {
                            spacing: 8
                            Layout.fillWidth: true

                            Row {
                                spacing: 4
                                Text {
                                    text: "Confirm Password"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    font.weight: Font.DemiBold
                                    color: "#1e293b"
                                }
                                Text { text: "*"; font.pointSize: ScreenTools.defaultFontPointSize * 0.8; color: "#ef4444" }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 45
                                radius: 8
                                border.color: confirmPasswordInput.activeFocus ? app_color : "#e2e8f0"
                                border.width: confirmPasswordInput.activeFocus ? 2 : 1
                                color: "#f8fafc"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 6
                                    spacing: 8

                                    TextField {
                                        id: confirmPasswordInput
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        echoMode: changePasswordDialog.showConfirmPass ? TextInput.Normal : TextInput.Password
                                        placeholderText: "Confirm new password"
                                        font.pointSize: ScreenTools.defaultFontPointSize
                                        font.family: "Outfit"
                                        color: "#1e293b"
                                        verticalAlignment: TextInput.AlignVCenter
                                        background: null
                                    }

                                    Button {
                                        width: 32; height: 32
                                        checkable: true
                                        checked: changePasswordDialog.showConfirmPass
                                        onCheckedChanged: changePasswordDialog.showConfirmPass = checked
                                        background: Rectangle { radius: 6; color: parent.hovered ? Qt.rgba(0,0,0,0.05) : "transparent" }
                                        contentItem: QGCColoredImage {
                                            anchors.fill: parent; anchors.margins: 6
                                            fillMode: Image.PreserveAspectFit
                                            source: parent.checked ? "/qmlimages/NewImages/password_visible.svg" : "/qmlimages/NewImages/password_hidden.svg"
                                            color: app_color
                                        }
                                    }
                                }
                            }
                        }

                        // Spacer
                        Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }

                        // Buttons at bottom
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Button {
                                id: cancelBtn
                                Layout.fillWidth: true
                                height: 45
                                text: "Cancel"
                                background: Rectangle {
                                    radius: 8
                                    color: cancelBtn.hovered ? "#e2e8f0" : "#f1f5f9"
                                    border.color: "#e2e8f0"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "#475569"
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.weight: Font.Medium
                                    font.family: "Outfit"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    changePasswordDialog.close()
                                    oldPasswordInput.text = ""
                                    newPasswordInput.text = ""
                                    confirmPasswordInput.text = ""
                                    changePasswordDialog.showOldPass = false
                                    changePasswordDialog.showNewPass = false
                                    changePasswordDialog.showConfirmPass = false
                                }
                            }

                            Button {
                                id: changePwdBtn
                                Layout.fillWidth: true
                                height: 45
                                text: "Save Password"
                                background: Rectangle {
                                    radius: 8
                                    color: changePwdBtn.pressed ? Qt.darker(app_color, 1.15) : (changePwdBtn.hovered ? Qt.lighter(app_color, 1.1) : app_color)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pointSize: ScreenTools.defaultFontPointSize
                                    font.weight: Font.DemiBold
                                    font.family: "Outfit"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    if (oldPasswordInput.text === "") {
                                        showMessage("Enter current password!", "error");
                                        return;
                                    }

                                    if (newPasswordInput.text !== confirmPasswordInput.text) {
                                        showMessage("Passwords do not match!", "error");
                                        return;
                                    }

                                    if (newPasswordInput.text.length < 4) {
                                        showMessage("Min 4 characters required!", "error");
                                        return;
                                    }

                                    changePasswordAPI();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Dim overlay
        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }

    Dialog {
        id: messageDialog
        modal: true
        anchors.centerIn: parent
        width: 320
        padding: 0 // Reset padding for custom margins

        property string messageDialogText: ""

        background: Rectangle {
            color: "white"
            radius: 12
            layer.enabled: true
        }

        contentItem: Item {
            implicitHeight: msgColumn.implicitHeight + 48

            ColumnLayout {
                id: msgColumn
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 24

                Text {
                    text: messageDialog.messageDialogText
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.05
                    font.weight: Font.Medium
                    font.family: "Outfit"
                    color: "#1e293b"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Button {
                    id: msgOkBtn
                    Layout.fillWidth: true
                    height: 45
                    text: "OK"
                    background: Rectangle {
                        radius: 8
                        color: msgOkBtn.pressed ? Qt.darker(app_color, 1.15) : (msgOkBtn.hovered ? Qt.lighter(app_color, 1.1) : app_color)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.DemiBold
                        font.family: "Outfit"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: messageDialog.close()
                }
            }
        }

        // Dim overlay
        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }

    function showMessage(msg, type) {
        messageDialog.messageDialogText = msg
        messageDialog.open()
    }
    function changePasswordAPI() {
        var xhr = new XMLHttpRequest();
        // MapGlobals.backendUrl = "http://192.168.137.1:5000";
        var url = MapGlobals.backendUrl + "/change-password";

        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Response:", xhr.responseText);

                if (xhr.status === 200) {
                    var res = JSON.parse(xhr.responseText);
                    showMessage(res.message, "success");

                    changePasswordDialog.close();

                    oldPasswordInput.text = "";
                    newPasswordInput.text = "";
                    confirmPasswordInput.text = "";
                } else {
                    try {
                        var err = JSON.parse(xhr.responseText);
                        showMessage(err.message || "Error occurred", "error");
                    } catch (e) {
                        showMessage("Server error please try again", "error");
                    }
                }
            }
        };

        xhr.onerror = function() {
            showMessage("Network error", "error");
        };

        xhr.send(JSON.stringify({
            username: QGroundControl.loadGlobalSetting("username", ""),  // ✅ MUST
            oldPassword: oldPasswordInput.text,
            newPassword: newPasswordInput.text
        }));
    }
}
