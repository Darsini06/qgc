import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.LocalStorage 2.0

import Qt.labs.lottieqt 1.0

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: profilescreen
    anchors.fill: parent
    property string currentView: "main" // options: main, accountUpdate, userGuide, record, reports, feedback, settings

    property string userName: ""
    property string userEmail: ""

    property string selectedImage: ""

    ListModel {
        id: sessionModel
    }

    onVisibleChanged: {

        console.log("onVisibleChanged");

        if (visible) {
            userName = QGroundControl.loadGlobalSetting("name", "")
            userEmail = QGroundControl.loadGlobalSetting("email", "")
        }

    }

    onCurrentViewChanged: {
        if (currentView === "reports") {
            console.log("Switched to Reports view")
            loadSessions()
        }
    }

    function getDatabase() {
        return LocalStorage.openDatabaseSync("QGCUserDB", "1.0", "User DB", 1000000);
    }

    function loadSessions() {
        sessionModel.clear();
        var db = getDatabase();
        db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT * FROM drone_sessions ORDER BY id DESC");
            for (var i = 0; i < rs.rows.length; i++) {
                var row = rs.rows.item(i);
                sessionModel.append({
                                        date: row.date,
                                        start: row.start_time,
                                        end: row.end_time
                                    });
            }
            console.log("Datas : ",rs)
        });
    }

    Rectangle {
        anchors.fill: parent
        color: "#1b1c3e"

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            // Header Row
            RowLayout {
                Layout.margins: 20
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 20
                Layout.bottomMargin: 5
                Layout.fillWidth: true
                spacing: 10


                QGCColoredImage {
                    id: homeIcon
                    source: "/qmlimages/Home.svg"
                    width: 30
                    height: 30
                    fillMode: Image.PreserveAspectFit
                    color: "transparent"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mainWindow.profileScreen1(false)
                            currentView = "main"
                        }
                    }
                }

                Text {
                    text: "Profile Screen"
                    font.pointSize: 22
                    color: "white"
                }
            }

            // Main Content Row
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20
                Layout.margins: 20
                Layout.topMargin: 0

                // Left Card
                Rectangle {
                    id: card
                    Layout.preferredWidth: parent.width * 0.56
                    Layout.fillHeight: true
                    color: "#b1b3fc"
                    radius: 12
                    border.color: "black"

                    StackLayout {
                        id: stack
                        anchors.fill: parent
                        anchors.margins: 10
                        clip: true

                        // Main Card Screen
                        Item {
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 15

                                // Profile Header
                                RowLayout {
                                    spacing: 10

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/profileImage.png"
                                        width: 40
                                        height: 40
                                        fillMode: Image.PreserveAspectFit
                                        clip: true
                                        smooth: true
                                        color: "transparent"
                                    }

                                    ColumnLayout {

                                        spacing: 1

                                        Row{

                                            Layout.alignment: Qt.AlignLeft

                                            Text {
                                                text: profileScreen.userName
                                                font.bold: true
                                                font.pointSize: 14
                                            }

                                            QGCColoredImage {
                                                source: "/qmlimages/NewImages/verified.png"
                                                width: 20
                                                height: 20
                                                fillMode: Image.PreserveAspectFit
                                                color: "transparent"
                                            }
                                        }


                                        Text {
                                            text: profileScreen.userEmail
                                            color: "white"
                                            font.pointSize: 14
                                        }
                                    }
                                }

                                // Menu Section
                                Repeater {
                                    model: ListModel {
                                        ListElement { icon: "/qmlimages/NewImages/accountUpdate.png"; label: "Account Update"; screen: "accountUpdate" }
                                        ListElement { icon: "/qmlimages/NewImages/reports.png"; label: "Reports"; screen: "reports" }
                                        ListElement { icon: "/qmlimages/NewImages/feedback.png"; label: "Feedback"; screen: "feedback" }
                                        ListElement { icon: "/qmlimages/NewImages/settings.png"; label: "Settings"; screen: "settings" }
                                    }

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        radius: 5
                                        border.color: "#cccccc"
                                        border.width: 1


                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 10
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter

                                            QGCColoredImage {
                                                source: icon
                                                width: 20
                                                height: 20
                                                fillMode: Image.PreserveAspectFit
                                                color: "transparent"
                                            }

                                            Text {
                                                text: label
                                                font.pointSize: 14
                                                Layout.fillWidth: true
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                currentView = model.screen
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Account Update
                        Rectangle {
                            visible: currentView === "accountUpdate"
                            anchors.fill: parent
                            color: "#b1b3fc"

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                //padding: 20

                                // Title
                                Text {
                                    text: "Account Updation"
                                    font.pixelSize: 22
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                // Profile Image
                                Rectangle {
                                    width: 70
                                    height: 70
                                    radius: 50
                                    color: "#dddddd"
                                    Layout.alignment: Qt.AlignHCenter

                                    QGCColoredImage {
                                        source: "/qmlimages/NewImages/profileImage.png"
                                        width: 70
                                        height: 70
                                        fillMode: Image.PreserveAspectFit
                                        clip: true
                                        smooth: true
                                        color: "transparent"
                                    }
                                }

                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    Item {
                                        width: parent.width

                                        ColumnLayout {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            spacing: 15
                                            //padding: 10

                                            // Name Field
                                            TextField {
                                                Layout.fillWidth: true
                                                placeholderText: "Enter Name"
                                                font.pixelSize: 16
                                            }

                                            // Email Field
                                            TextField {
                                                Layout.fillWidth: true
                                                placeholderText: "Enter Email"
                                                font.pixelSize: 16
                                                inputMethodHints: Qt.ImhEmailCharactersOnly
                                            }

                                            // Password Field
                                            TextField {
                                                Layout.fillWidth: true
                                                placeholderText: "Enter Password"
                                                font.pixelSize: 16
                                                echoMode: TextInput.Password
                                            }

                                            // Mobile Number Field
                                            TextField {
                                                Layout.fillWidth: true
                                                placeholderText: "Enter Mobile Number"
                                                font.pixelSize: 16
                                                inputMethodHints: Qt.ImhDigitsOnly
                                            }

                                            // Certificate Upload Section
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    text: "Upload Certificate:"
                                                    font.pixelSize: 16
                                                }

                                                Button {
                                                    text: "Choose File"
                                                    Layout.preferredWidth: 150
                                                    onClicked: {
                                                        console.log("Upload Certificate Clicked")
                                                    }
                                                }
                                            }

                                            // Update Button
                                            Button {
                                                text: "Update"
                                                Layout.alignment: Qt.AlignHCenter
                                                width: 150
                                                height: 40
                                                onClicked: {
                                                    console.log("Update Clicked")
                                                }
                                            }

                                            Rectangle { height: 30; color: "transparent" }
                                        }
                                    }
                                }

                            }
                        }

                        // Reports
                        Rectangle {
                            visible: currentView === "reports"
                            anchors.fill: parent
                            color: "#b1b3fc"

                            Component.onCompleted: {
                                console.log("Component.onCompleted")
                                loadSessions()
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10
                                //padding: 10

                                Text {
                                    text: "Drone Flying Logs"
                                    font.pixelSize: 22
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Item { height: 20; Layout.fillWidth: true } // Spacer

                                ListView {
                                    id: listView
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: sessionModel
                                    spacing: 10 // this doesn't work on ListView by default, so see below

                                    delegate: Item {
                                        width: listView.width
                                        height: 60 // Adjusted height for spacing
                                        Column {
                                            spacing: 10 // this adds spacing between items
                                            Rectangle {
                                                width: listView.width
                                                height: 50
                                                color: index % 2 === 0 ? "#ffffff" : "#eeeeee"
                                                radius: 4
                                                border.color: "#cccccc"
                                                border.width: 1

                                                Row {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 20
                                                    padding: 10

                                                    Rectangle {
                                                        width: 30
                                                        height: 30
                                                        radius: 15
                                                        color: "#007acc"
                                                        anchors.verticalCenter: parent.verticalCenter

                                                        Text {
                                                            text: index + 1
                                                            anchors.centerIn: parent
                                                            color: "white"
                                                            font.bold: true
                                                        }
                                                    }

                                                    Column {
                                                        spacing: 4

                                                        Text {
                                                            text: "📅 " + date
                                                            font.bold: true
                                                            color: "#333333"
                                                        }

                                                        Row {
                                                            spacing: 20
                                                            Text {
                                                                text: "🔌 Start: " + start
                                                                color: "#444444"
                                                                font.pixelSize: 14
                                                            }
                                                            Text {
                                                                text: "🔌 End: " + end
                                                                color: "#444444"
                                                                font.pixelSize: 14
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ScrollBar.vertical: ScrollBar { }
                                }

                            }
                        }

                        //feedback
                        Rectangle {
                            visible: currentView === "feedback"
                            anchors.fill: parent
                            color: "#b1b3fc"
                            clip: true

                            // Top: Title
                            Text {
                                id: title
                                text: "Feedback Form"
                                font.pointSize: 22
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 20
                            }

                            // Bottom: Send Button
                            Button {
                                id: sendButton
                                text: "Send Feedback"
                                width: parent.width * 0.8
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 20

                                onClicked: {
                                    if (phoneField.text === "" || emailField.text === "" || commentField.text === "") {
                                        mainWindow.showToastMessage("Please fill in all fields.")
                                        return
                                    }
                                    console.log("Phone:", phoneField.text)
                                    console.log("Email:", emailField.text)
                                    console.log("Comment:", commentField.text)
                                    mainWindow.showToastMessage("Feedback sent successfully!")
                                }
                            }

                            // Middle: Scrollable content
                            Flickable {
                                id: flickableArea
                                anchors.top: title.bottom
                                anchors.bottom: sendButton.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 20
                                contentHeight: contentColumn.implicitHeight
                                clip: true

                                Column {
                                    id: contentColumn
                                    width: flickableArea.width
                                    spacing: 20

                                    TextField {
                                        id: phoneField
                                        placeholderText: "Phone Number"
                                        inputMethodHints: Qt.ImhDigitsOnly
                                        width: parent.width
                                    }

                                    TextField {
                                        id: emailField
                                        placeholderText: "Email Address"
                                        inputMethodHints: Qt.ImhEmailCharactersOnly
                                        width: parent.width
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: parent.height * 0.25
                                        radius: 4
                                        border.width: 1
                                        border.color: "#cccccc"

                                        TextArea {
                                            id: commentField
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            wrapMode: TextEdit.Wrap
                                            placeholderText: "Enter your feedback or comments"
                                            font.pointSize: 14
                                            background: null
                                        }
                                    }

                                    Text {
                                        text: "Upload Image"
                                        font.pointSize: 18
                                        font.bold: true
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Clickable image box
                                    Rectangle {
                                        width: parent.width
                                        height: 150
                                        radius: 4
                                        border.color: "gray"
                                        border.width: 1
                                        color: "transparent"

                                        // Conditional: Show image or text
                                        Item {
                                            anchors.fill: parent

                                            // Show image if selected
                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                source: selectedImage
                                                fillMode: Image.PreserveAspectFit
                                                visible: selectedImage !== ""
                                            }

                                            // Show placeholder text if image is not selected
                                            Text {
                                                text: "Select Image"
                                                anchors.centerIn: parent
                                                font.pointSize: 14
                                                color: "#999999"
                                                visible: selectedImage === ""
                                            }

                                            // MouseArea to open FileDialog
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: imageDialog.open()
                                            }
                                        }
                                    }

                                }
                            }

                            FileDialog {
                                id: imageDialog
                                title: "Choose Image"
                                nameFilters: ["*.png", "*.jpg", "*.jpeg"]
                                onAccepted: {
                                    if (imageDialog.currentFile !== "") {
                                        profilescreen.selectedImage = imageDialog.currentFile
                                        console.log("Selected image path:", profilescreen.selectedImage)
                                    } else {
                                        console.warn("No image selected.")
                                    }
                                }
                            }
                        }

                        //Settings
                        Rectangle {
                            visible: currentView === "settings"
                            anchors.fill: parent
                            color: "#b1b3fc"
                            radius: 12

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 30

                                Text {
                                    text: "Settings"
                                    font.bold: true
                                    font.pixelSize: 20
                                    color: "black"
                                    horizontalAlignment: Text.AlignLeft
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.leftMargin: 30
                                    Layout.topMargin: -10
                                }


                                // Scrollable Menu Section
                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    Column {
                                        width: parent.width
                                        spacing: 20

                                        Repeater {
                                            model: ListModel {
                                                ListElement { icon: "/qmlimages/NewImages/accountUpdate.png"; label: " User Guide "; screen: "accountUpdate" }
                                                ListElement { icon: "/qmlimages/NewImages/reports.png"; label: " Privacy Policy "; screen: "reports" }
                                                ListElement { icon: "/qmlimages/NewImages/feedback.png"; label: "Terms & Conditions"; screen: "feedback" }
                                                ListElement { icon: "/qmlimages/NewImages/settings.png"; label: "Logout"; screen: "settings" }
                                            }

                                            delegate: Rectangle {
                                                width: parent.width
                                                height: 40
                                                radius: 6
                                                color: "white"
                                                border.color: "#cccccc"
                                                border.width: 1

                                                Row {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    spacing: 10

                                                    QGCColoredImage {
                                                        source: icon
                                                        width: 20
                                                        height: 20
                                                        fillMode: Image.PreserveAspectFit
                                                        color: "transparent"
                                                    }

                                                    Text {
                                                        text: label
                                                        font.pointSize: 14
                                                        color: "black"
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                }

                                                // MouseArea {
                                                //     anchors.fill: parent
                                                //     cursorShape: Qt.PointingHandCursor
                                                //     onClicked: {
                                                //         currentView = model.screen
                                                //     }
                                                // }
                                            }
                                        }
                                    }
                                }
                            }
                        }


                    }

                    QGCColoredImage {
                        id: backArrow
                        source: "/qmlimages/NewImages/leftArrow.png"
                        width: 35
                        height: 35
                        fillMode: Image.PreserveAspectFit
                        color: "transparent"
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 20
                        visible: currentView !== "main"
                        z: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                currentView = "main"
                            }
                        }
                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        anchors.centerIn: parent
                        spacing: 20
                        width: parent.width * 0.95

                        Item {
                            width: 150
                            height: 150
                            anchors.horizontalCenter: parent.horizontalCenter

                            LottieAnimation {
                                id: droneAnim
                                anchors.centerIn: parent
                                source: "qrc:/qmlimages/NewImages/Droneflying.json"
                                autoPlay: true
                                loops: Animation.Infinite
                                scale: 0.2
                                onStatusChanged: console.log("Lottie Status:", status)
                            }
                        }

                        Text {
                            text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                            wrapMode: Text.WordWrap
                            font.pixelSize: 18
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            //Layout.fillWidth: true
                            width: parent.width
                        }
                    }
                }


            }

        }
    }
}

