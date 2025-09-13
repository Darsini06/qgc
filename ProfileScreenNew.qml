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
  property string currentView: "profile" // options: main, accountUpdate, userGuide, record, reports, feedback, settings

  property string userName: ""
  property string displayName: ""
  property string userEmail: ""
  property string name_from_db: ""
  property string mobileNo_from_db: ""
  property string email_from_db: ""


  property string selectedImage: ""

  ListModel {
    id: sessionModel
  }

  Component.onCompleted: {
    console.log("onCompleted");

    if (userName !== "") {
      userName = QGroundControl.loadGlobalSetting("username", "")
      loadUserDataFromMain();
    }
  }

  onVisibleChanged: {

    if (visible) {

      console.log("onVisibleChanged");

      displayName = QGroundControl.loadGlobalSetting("name", "")
      userName = QGroundControl.loadGlobalSetting("username", "")
      userEmail = QGroundControl.loadGlobalSetting("email", "")

      if (userName !== "") {
        console.log("onVisibleUserName : ",userName);
        loadUserDataFromMain();
      }
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


  function loadUserDataFromMain() {
    mainWindow.loadUserData(userName, function(userData) {
      if (userData) {
        // Set your profile screen properties
        name_from_db = userData.displayname || "";
        mobileNo_from_db = userData.mobile_number || "";
        email_from_db = userData.email || "";

        console.log("Data retrieved - Name:", name_from_db,
                    "Email:", email_from_db,
                    "Mobile:", mobileNo_from_db);
      } else {
        console.log("No user data received");
        // Clear the fields if no data
        name_from_db = "";
        mobileNo_from_db = "";
        email_from_db = "";
      }
    });
  }

  StackLayout {
    anchors.fill: parent
    currentIndex: {
      if (currentView === "profile") return 0
      else if (currentView === "accountUpdate") return 1
      else if (currentView === "reports") return 2
      else if (currentView === "feedback") return 3
      else if (currentView === "privacy_policy") return 6
      else if (currentView === "terms&conditions") return 7
      else return 0
    }

    //Profile Screen
    Item {
      ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Profile screen header
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: parent.height * 0.15
          color: "#1b1c3e"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 10

            QGCColoredImage {
              source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
              fillMode: Image.PreserveAspectFit
              width: 25
              height: 25
              color: "white"

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  mainWindow.profileScreen1(false)
                  currentView = "main"
                }
              }
            }

            Item {
              Layout.fillWidth: true
            }

            QGCColoredImage {
              id: homeIcon
              source: "/qmlimages/NewImages/profile.png"
              width: 25
              height: 25
              fillMode: Image.PreserveAspectFit
              color: "white"
            }

            Text {
              text: "Profile"
              font.pointSize: 18
              color: "white"
              font.bold: true
            }

            Item {
              Layout.fillWidth: true
            }
          }
        }

        // Profile content area
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.leftMargin: 20
          Layout.rightMargin: 20
          Layout.bottomMargin: 20
          spacing: 20

          // First Card - Profile Info & Stats
          Rectangle {
            Layout.preferredWidth: parent.width * 0.45
            Layout.fillHeight: true
            color: "white"
            radius: 5
            border.color: "#e0e0e0"
            border.width: 1

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 20
              spacing: 10
              clip: true

              // Profile Image
              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 80
                height: 80
                radius: 40
                color: "#f0f0f0"

                QGCColoredImage {
                  anchors.centerIn: parent
                  source: "/qmlimages/NewImages/profile.png"
                  width: 40
                  height: 40
                  fillMode: Image.PreserveAspectFit
                  color: "#666666"
                }
              }

              // Name
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: displayName || "Anonymous"
                font.pointSize: 16
                font.bold: true
                color: "#333333"
              }

              // Email
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: userEmail || "user@example.com"
                font.pointSize: 12
                color: "#666666"
              }
              // Stats Section
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Hours Flown
                RowLayout {
                  spacing: 10
                  QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/time.svg"
                    width: 20
                    height: 20
                    color: "#2c3e50"
                  }
                  Text {
                    text: "Total Hours Flown"
                    font.pointSize: 12
                    color: "#666666"
                    Layout.fillWidth: true
                  }
                  Text {
                    text: "127.5 hrs"
                    font.pointSize: 12
                    font.bold: true
                    color: "#2c3e50"
                  }
                }

                // Missions Completed
                RowLayout {
                  spacing: 10
                  QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/checkmark.svg"
                    width: 20
                    height: 20
                    color: "#2c3e50"
                  }
                  Text {
                    text: "Missions Completed"
                    font.pointSize: 12
                    color: "#666666"
                    Layout.fillWidth: true
                  }
                  Text {
                    text: "45"
                    font.pointSize: 12
                    font.bold: true
                    color: "#2c3e50"
                  }
                }

                // Distance Covered
                RowLayout {
                  spacing: 10
                  QGCColoredImage {
                    source: "qrc:/InstrumentValueIcons/travel-walk.svg"
                    width: 20
                    height: 20
                    color: "#2c3e50"
                  }
                  Text {
                    text: "Distance Covered"
                    font.pointSize: 12
                    color: "#666666"
                    Layout.fillWidth: true
                  }
                  Text {
                    text: "256 km"
                    font.pointSize: 12
                    font.bold: true
                    color: "#2c3e50"
                  }
                }
              }
            }
          }

          // Second Card - Menu List
          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 5
            border.color: "#e0e0e0"
            border.width: 1

            ColumnLayout
            {
              anchors.fill: parent
              anchors.margins: 10
              spacing: 0
              clip: true

              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                model: ListModel {
                  ListElement { icon: "/qmlimages/NewImages/accountUpdate.png"; name: " Account Update "; screen: "accountUpdate" }
                  ListElement { icon: "/qmlimages/NewImages/reports.png"; name: " Privacy Policy "; screen: "privacy_policy" }
                  ListElement { icon: "/qmlimages/NewImages/feedback.png"; name: "Terms & Conditions"; screen: "terms&conditions" }
                  ListElement { icon: "/qmlimages/NewImages/feedback.png"; name: "Feedback"; screen: "feedback" }
                  ListElement { icon: "/qmlimages/NewImages/feedback.png"; name: "Reports"; screen: "reports" }
                  ListElement { icon: "/qmlimages/NewImages/settings.png"; name: "Logout"; screen: "logout" }
                }


                delegate: Rectangle {
                  width: ListView.view.width
                  height: 50
                  color: "transparent"

                  RowLayout {
                    anchors.fill: parent
                    spacing: 15

                    QGCColoredImage {
                      source: model.icon
                      width: 20
                      height: 20
                      color: "black"
                    }

                    Text {
                      text: model.name
                      font.pointSize: 14
                      color: "#333333"
                      Layout.fillWidth: true
                    }
                  }

                  Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#eeeeee"
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (model.screen === "logout") {
                        logoutdialog.createObject(mainWindow).open()
                      } else {
                        currentView = model.screen // This updates StackLayout.currentIndex
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

    // Account Update Screen
    Rectangle {
      color: "white"

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: parent.height * 0.15
          color: "#1b1c3e"

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 10

            QGCColoredImage {
              source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
              fillMode: Image.PreserveAspectFit
              width: 25
              height: 25
              color: "white"

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  //mainWindow.profileScreen1(false)
                  currentView = "profile"
                }
              }
            }

            Item {
              Layout.fillWidth: true
            }

            QGCColoredImage {
              id: accountUpdate
              source: "/qmlimages/NewImages/profile.png"
              width: 25
              height: 25
              fillMode: Image.PreserveAspectFit
              color: "white"
            }

            Text {
              text: "Account Update"
              font.pointSize: 18
              color: "white"
              font.bold: true
            }

            Item {
              Layout.fillWidth: true
            }
          }
        }

        // Account Update content area
        RowLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.leftMargin: 10
          Layout.rightMargin: 10
          Layout.bottomMargin: 10
          Layout.topMargin: 10
          spacing: 10

          // First Card - Profile Info & Stats
          Rectangle {
            Layout.preferredWidth: parent.width * 0.4
            Layout.fillHeight: true
            color: "white"
            radius: 5
            border.color: "#e0e0e0"
            border.width: 1

            Column {
              anchors.fill: parent
              anchors.margins: 20
              spacing: 10

              Item {
                width: 150
                height: 150
                anchors.horizontalCenter: parent.horizontalCenter

                LottieAnimation {
                  id: droneAnim
                  anchors.centerIn: parent
                  source: "qrc:/qmlimages/NewImages/droneManFly.json"
                  autoPlay: true
                  loops: Animation.Infinite
                  scale: 0.3
                  onStatusChanged: console.log("Lottie Status:", status)
                }
              }

              Text {
                text: "A drone is an unmanned aerial vehicle (UAV), an aircraft without a pilot on board, that can be controlled remotely or fly autonomously."
                wrapMode: Text.WordWrap
                font.pixelSize: 14 // Reduced size for better fit
                color: "black" // Changed from white to black for visibility
                horizontalAlignment: Text.AlignHCenter
                width: parent.width - 40 // Add some margin
              }
            }
          }

          // Second Card - Form
          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 5
            border.color: "#e0e0e0"
            border.width: 1

            ScrollView {
              anchors.fill: parent
              anchors.margins: 10
              clip: true
              contentWidth: availableWidth
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

              Item {
                width: parent.width
                implicitHeight: formColumn.implicitHeight + 15 // Add padding

                Column {
                  id: formColumn
                  width: parent.width
                  spacing: 10
                  anchors.centerIn: parent

                  // Name Field
                  Column {
                    width: parent.width
                    spacing: 5

                    Text {
                      text: "Profi Name"
                      font.pixelSize: 14
                      font.bold: true
                      color: "#2c3e50"
                      leftPadding: 5
                    }

                    Rectangle {
                      width: parent.width
                      height: 40
                      radius: 8
                      color: "white"
                      border.width: namefield.activeFocus ? 2 : 1
                      border.color: namefield.activeFocus ? "#3498db" : "#dcdde1"

                      TextField {
                        id: namefield
                        anchors.fill: parent
                        anchors.margins: 5
                        placeholderText: "Enter your name"
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        text: name_from_db

                        validator: RegularExpressionValidator {
                          regularExpression: /^[a-zA-Z\s]*$/
                        }
                      }
                    }
                  }

                  // username Field
                  Column {
                    width: parent.width
                    spacing: 5

                    Text {
                      text: "Username"
                      font.pixelSize: 14
                      font.bold: true
                      color: "#2c3e50"
                      leftPadding: 5
                    }

                    Rectangle {
                      width: parent.width
                      height: 40
                      radius: 8
                      color: "white"
                      border.width: _username.activeFocus ? 2 : 1
                      border.color: _username.activeFocus ? "#3498db" : "#dcdde1"

                      TextField {
                        id: _username
                        anchors.fill: parent
                        anchors.margins: 5
                        placeholderText: "Enter your username"
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        text: userName

                        validator: RegularExpressionValidator {
                          regularExpression: /^[a-zA-Z\s]*$/
                        }
                      }
                    }
                  }


                  // Email Field
                  Column {
                    width: parent.width
                    spacing: 5

                    Text {
                      text: "Email"
                      font.pixelSize: 14
                      font.bold: true
                      color: "#2c3e50"
                      leftPadding: 5
                    }

                    Rectangle {
                      width: parent.width
                      height: 40
                      radius: 8
                      color: "white"
                      border.width: emailField.activeFocus ? 2 : 1
                      border.color: emailField.activeFocus ? "#3498db" : "#dcdde1"

                      TextField {
                        id: emailField
                        anchors.fill: parent
                        anchors.margins: 5
                        placeholderText: "Enter your email"
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                        text: email_from_db
                      }
                    }
                  }

                  // Mobile Number Field
                  Column {
                    width: parent.width
                    spacing: 5

                    Text {
                      text: "Mobile Number"
                      font.pixelSize: 14
                      font.bold: true
                      color: "#2c3e50"
                      leftPadding: 5
                    }

                    Rectangle {
                      width: parent.width
                      height: 40
                      radius: 8
                      color: "white"
                      border.width: mobileField.activeFocus ? 2 : 1
                      border.color: mobileField.activeFocus ? "#3498db" : "#dcdde1"

                      TextField {
                        id: mobileField
                        anchors.fill: parent
                        anchors.margins: 5
                        placeholderText: "Enter mobile number"
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: mobileNo_from_db
                      }
                    }
                  }

                  // RPC Completion Question
                  Column {
                    width: parent.width * 0.95
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                      text: "Have you completed the RPC?"
                      font.pixelSize: 14

                      color: "#333333"
                    }

                    Row {
                      spacing: 30
                      //anchors.horizontalCenter: parent.horizontalCenter

                      // Yes Radio Button
                      Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                          width: 15
                          height: 15
                          radius: 10
                          border.width: 2
                          border.color: "#1b1c3e"
                          color: rpcCompleted.checked === "Yes" ? "#1b1c3e" : "transparent"

                          MouseArea {
                            anchors.fill: parent
                            onClicked: rpcCompleted.checked = "Yes"
                          }
                        }

                        Text {
                          text: "Yes"
                          font.pixelSize: 14
                          color: "#333333"
                          anchors.verticalCenter: parent.verticalCenter

                          MouseArea {
                            anchors.fill: parent
                            onClicked: rpcCompleted.checked = "Yes"
                          }
                        }
                      }

                      // No Radio Button
                      Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                          width: 15
                          height: 15
                          radius: 10
                          border.width: 2
                          border.color: "#1b1c3e"
                          color: rpcCompleted.checked === "No" ? "#1b1c3e" : "transparent"

                          MouseArea {
                            anchors.fill: parent
                            onClicked: rpcCompleted.checked = "No"
                          }
                        }

                        Text {
                          text: "No"
                          font.pixelSize: 14
                          color: "#333333"
                          anchors.verticalCenter: parent.verticalCenter

                          MouseArea {
                            anchors.fill: parent
                            onClicked: rpcCompleted.checked = "No"
                          }
                        }
                      }
                    }
                  }

                  PropertyAnimation {
                    id: rpcCompleted
                    property string checked: ""
                  }

                  // Update Button
                  Button {
                    text: "Update"
                    width: parent.width * 0.3
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                      if (!mainWindow.validateUsername(_username.text,_username)) return;
                      if (!mainWindow.validateDisplayName(namefield.text,namefield)) return;
                      if (!mainWindow.validateEmail(emailField.text,emailField)) return;

                      var _rpcCompleted = rpcCompleted.checked === "Yes" ? 1 : 0;

                      mainWindow.updateUser(userName,_username.text, namefield.text, emailField.text,mobileField.text,_rpcCompleted, function(result) {
                          if (result) {

                              mainWindow.showToastMessage("Updated successfully!");

                              currentView = "profile";

                              QGroundControl.saveGlobalSetting("username", _username.text);
                              QGroundControl.saveGlobalSetting("name", namefield.text);
                              QGroundControl.saveGlobalSetting("email", emailField.text);

                          }
                      });
                    }

                    background: Rectangle {
                      radius: 5
                      color: parent.pressed ? "#218838" : "#28a745"
                    }

                    contentItem: Text {
                      text: parent.text
                      color: "white"
                      font.pixelSize: 14
                      font.bold: true
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }
                  }

                  Item { height: 10 } // Spacer
                }
              }
            }
          } //SecondCaed

        }
      }
    }

    // Reports Screen
    Rectangle {
      color: "#b1b3fc"

      Component.onCompleted: {
        console.log("Reports Component.onCompleted")
        loadSessions()
      }

      ColumnLayout {
        anchors.fill: parent
        spacing: 10
        anchors.margins: 20

        Text {
          text: "Drone Flying Logs"
          font.pixelSize: 22
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: 20 } // Spacer

        ListView {
          id: listView
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: sessionModel
          spacing: 10

          delegate: Rectangle {
            width: listView.width
            height: 60
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
                anchors.verticalCenter: parent.verticalCenter

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

          ScrollBar.vertical: ScrollBar { }
        }
      }
    }

    // Feedback Screen
    Rectangle {
      color: "#b1b3fc"
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Title
        Text {
          text: "Feedback Form"
          font.pointSize: 22
          font.bold: true
          Layout.alignment: Qt.AlignHCenter
        }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          ColumnLayout {
            width: parent.width
            spacing: 20

            TextField {
              id: phoneField
              placeholderText: "Phone Number"
              inputMethodHints: Qt.ImhDigitsOnly
              Layout.fillWidth: true
            }

            TextField {
              id: emailField_feedback
              placeholderText: "Email Address"
              inputMethodHints: Qt.ImhEmailCharactersOnly
              Layout.fillWidth: true
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 150
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
              Layout.alignment: Qt.AlignHCenter
            }

            // Clickable image box
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 150
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

        // Send Button
        Button {
          id: sendButton
          text: "Send Feedback"
          Layout.fillWidth: true
          Layout.preferredHeight: 50
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
      }
    }

    FileDialog {
      id: imageDialog
      title: "Choose Image"
      nameFilters: ["*.png", "*.jpg", "*.jpeg"]
      onAccepted: {
        if (imageDialog.currentFile !== "") {
          selectedImage = imageDialog.currentFile
          console.log("Selected image path:", selectedImage)
        } else {
          console.warn("No image selected.")
        }
      }
    }
  }

  Component {
    id: logoutdialog

    QGCPopupDialog {
      id: popup
      title: qsTr("Logout")

      buttons: Dialog.Yes | Dialog.No

      onAccepted: {
        QGroundControl.saveBoolGlobalSetting("login", false)
        popup.visible = false
        mainWindow.profile()


      }
      onRejected: {
        popup.visible = false
      }

      ColumnLayout {
        spacing: ScreenTools.defaultFontPixelWidth
        QGCLabel {
          text: qsTr("Are you sure you want to logout?")
          Layout.fillWidth: true
        }
      }
    }
  }

}







// // Content Area
// ScrollView {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//     clip: true

//     // Fix horizontal scrolling
//     contentWidth: availableWidth
//     ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

//     Item {
//         width: parent.width
//         implicitHeight: contentColumn.implicitHeight

//         Column {
//             id: contentColumn
//             width: parent.width
//             spacing: 15
//             anchors.centerIn: parent


//             // Name Field
//             Rectangle {
//                 width: contentColumn.width * 0.5
//                 height: 50
//                 radius: 5
//                 color: "white"
//                 border.width: namefield.activeFocus ? 2 : 1
//                 border.color: namefield.activeFocus ? "#007acc" : "#cccccc"
//                 anchors.horizontalCenter: parent.horizontalCenter

//                 TextField {
//                     id: namefield
//                     anchors.fill: parent
//                     anchors.margins: 10
//                     placeholderText: "Enter your name"
//                     font.pixelSize: 16
//                     font.family: "Arial"
//                     color: "black"
//                     background: null
//                     selectByMouse: true
//                     verticalAlignment: TextInput.AlignVCenter

//                     validator: RegularExpressionValidator {
//                         regularExpression: /^[a-zA-Z\s]*$/
//                     }
//                 }
//             }

//             // Email Field
//             Rectangle {
//                 width: contentColumn.width * 0.5
//                 height: 50
//                 radius: 5
//                 color: "white"
//                 border.width: emailField.activeFocus ? 2 : 1
//                 border.color: emailField.activeFocus ? "#007acc" : "#cccccc"
//                 anchors.horizontalCenter: parent.horizontalCenter

//                 TextField {
//                     id: emailField
//                     anchors.fill: parent
//                     anchors.margins: 10
//                     placeholderText: "Enter your email"
//                     font.pixelSize: 16
//                     font.family: "Arial"
//                     color: "black"
//                     background: null
//                     selectByMouse: true
//                     verticalAlignment: TextInput.AlignVCenter
//                     inputMethodHints: Qt.ImhEmailCharactersOnly
//                 }
//             }

//             // Password Field
//             Rectangle {
//                 width: contentColumn.width * 0.5
//                 height: 50
//                 radius: 5
//                 color: "white"
//                 border.width: passwordField.activeFocus ? 2 : 1
//                 border.color: passwordField.activeFocus ? "#007acc" : "#cccccc"
//                 anchors.horizontalCenter: parent.horizontalCenter

//                 TextField {
//                     id: passwordField
//                     anchors.fill: parent
//                     anchors.margins: 10
//                     placeholderText: "Enter your password"
//                     font.pixelSize: 16
//                     font.family: "Arial"
//                     color: "black"
//                     background: null
//                     selectByMouse: true
//                     verticalAlignment: TextInput.AlignVCenter
//                     echoMode: TextInput.Password
//                 }
//             }

//             // Mobile Number Field
//             Rectangle {
//                 width: contentColumn.width * 0.5
//                 height: 50
//                 radius: 5
//                 color: "white"
//                 border.width: mobileField.activeFocus ? 2 : 1
//                 border.color: mobileField.activeFocus ? "#007acc" : "#cccccc"
//                 anchors.horizontalCenter: parent.horizontalCenter

//                 TextField {
//                     id: mobileField
//                     anchors.fill: parent
//                     anchors.margins: 10
//                     placeholderText: "Enter mobile number"
//                     font.pixelSize: 16
//                     font.family: "Arial"
//                     color: "black"
//                     background: null
//                     selectByMouse: true
//                     verticalAlignment: TextInput.AlignVCenter
//                     inputMethodHints: Qt.ImhDigitsOnly
//                 }
//             }

//             // Certificate Upload Section
//             Column {
//                 spacing: 10
//                 anchors.horizontalCenter: parent.horizontalCenter

//                 Button {
//                     text: "Choose File"
//                     width: contentColumn.width * 0.3
//                     height: 40
//                     onClicked: {
//                         console.log("Upload Certificate Clicked")
//                     }

//                     background: Rectangle {
//                         radius: 5
//                         color: parent.pressed ? "#0056b3" : "#007acc"
//                     }

//                     contentItem: Text {
//                         text: parent.text
//                         color: "white"
//                         font.pixelSize: 14
//                         horizontalAlignment: Text.AlignHCenter
//                         verticalAlignment: Text.AlignVCenter
//                     }
//                 }
//             }

//             // Update Button
//             Button {
//                 text: "Update"
//                 width: contentColumn.width * 0.3
//                 height: 45
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 onClicked: {
//                     console.log("Update Clicked")
//                 }

//                 background: Rectangle {
//                     radius: 5
//                     color: parent.pressed ? "#218838" : "#28a745"
//                 }

//                 contentItem: Text {
//                     text: parent.text
//                     color: "white"
//                     font.pixelSize: 16
//                     font.bold: true
//                     horizontalAlignment: Text.AlignHCenter
//                     verticalAlignment: Text.AlignVCenter
//                 }
//             }

//             Item { height: 20 } // Spacer
//         }
//     }
// }


