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

  property string rpcCompletedStatus: ""

  ListModel {
    id: sessionModel
  }

  // Connect to new session signal
  Connections {
      target: mainWindow
      onNewSessionAdded: {
          console.log("New session added, refreshing...");
          loadSessions();
          //loadSessionStatistics();
      }
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

      loadSessions();

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
    console.log("onCurrentViewChanged")

    displayName = QGroundControl.loadGlobalSetting("name", "")
    userName = QGroundControl.loadGlobalSetting("username", "")
    userEmail = QGroundControl.loadGlobalSetting("email", "")

    if (currentView === "reports") {
      console.log("Switched to Reports view")
      loadSessions()
    }

  }

  function loadSessions() {
      console.log("Loading drone sessions...");
      sessionModel.clear();

      mainWindow.getAllSessions(function(sessions) {
          if (sessions.length === 0) {
              console.log("No drone sessions found");
              return;
          }

          for (var i = 0; i < sessions.length; i++) {
              var session = sessions[i];
              sessionModel.append({
                  id: session.id,
                  date: session.date,
                  start: session.start_time,
                  end: session.end_time,
                  duration: session.duration || 0,
                  createdAt: session.created_at
              });
          }

          console.log("Loaded", sessions.length, "sessions into model");
      });
  }

  function loadUserDataFromMain() {
    mainWindow.loadUserData(userName, function(userData) {
      if (userData) {
        // Set your profile screen properties
        name_from_db = userData.displayname || "";
        mobileNo_from_db = userData.mobile_number || "";
        email_from_db = userData.email || "";
        profilescreen.rpcCompletedStatus = userData.rpc_completed || "";

        console.log("Data retrieved - Name:", name_from_db,
                    "Email:", email_from_db,
                    "Mobile:", mobileNo_from_db);
      } else {
        console.log("No user data received");
        // Clear the fields if no data
        name_from_db = "";
        mobileNo_from_db = "";
        email_from_db = "";
        profilescreen.rpcCompletedStatus = "";
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
                      text: "Profile Name"
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
                          color: profilescreen.rpcCompletedStatus === "Yes" ? "#1b1c3e" : "transparent"

                          MouseArea {
                            anchors.fill: parent
                            onClicked: profilescreen.rpcCompletedStatus = "Yes"
                          }
                        }

                        Text {
                          text: "Yes"
                          font.pixelSize: 14
                          color: "#333333"
                          anchors.verticalCenter: parent.verticalCenter

                          MouseArea {
                            anchors.fill: parent
                            onClicked: profilescreen.rpcCompletedStatus = "Yes"
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
                          color: profilescreen.rpcCompletedStatus === "No" ? "#1b1c3e" : "transparent"

                          MouseArea {
                            anchors.fill: parent
                            onClicked: profilescreen.rpcCompletedStatus = "No"
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

                      var _rpcCompleted =  profilescreen.rpcCompletedStatus === "Yes" ? 1 : 0;

                      mainWindow.updateUser(userName,_username.text, namefield.text, emailField.text,mobileField.text,_rpcCompleted, function(result) {
                        if (result) {

                          QGroundControl.saveGlobalSetting("username", _username.text);
                          QGroundControl.saveGlobalSetting("name", namefield.text);
                          QGroundControl.saveGlobalSetting("email", emailField.text);

                          mainWindow.showToastMessage("Updated successfully!");

                          currentView = "profile";
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
              id: sessions
              source: "/qmlimages/NewImages/profile.png"
              width: 25
              height: 25
              fillMode: Image.PreserveAspectFit
              color: "white"
            }

            Text {
              text: "Session"
              font.pointSize: 18
              color: "white"
              font.bold: true
            }

            Item {
              Layout.fillWidth: true
            }
          }
        }

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
              radius: 8
              border.color: "#e0e0e0"
              border.width: 1

              ColumnLayout {
                  anchors.fill: parent
                  spacing: 0

                  // Header
                  Rectangle {
                      Layout.fillWidth: true
                      height: 50
                      color: "#f8f9fa"
                      radius: 8

                      Row {
                          anchors.fill: parent
                          anchors.leftMargin: 20
                          anchors.rightMargin: 20
                          spacing: 15

                          Text {
                              text: "Date"
                              font.pixelSize: 14
                              font.bold: true
                              color: "#2c3e50"
                              width: parent.width * 0.3
                              anchors.verticalCenter: parent.verticalCenter
                          }

                          Text {
                              text: "Start Time"
                              font.pixelSize: 14
                              font.bold: true
                              color: "#2c3e50"
                              width: parent.width * 0.3
                              anchors.verticalCenter: parent.verticalCenter
                          }

                          Text {
                              text: "End Time"
                              font.pixelSize: 14
                              font.bold: true
                              color: "#2c3e50"
                              width: parent.width * 0.3
                              anchors.verticalCenter: parent.verticalCenter
                          }
                      }
                  }

                  // List Content
                  ScrollView {
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      clip: true
                      contentWidth: availableWidth
                      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                      ListView {
                          id: listView
                          width: parent.width
                          model: sessionModel
                          spacing: 8
                          boundsBehavior: Flickable.StopAtBounds

                          delegate: Rectangle {
                              width: listView.width
                              height: 60
                              color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                              radius: 6

                              Row {
                                  anchors.fill: parent
                                  anchors.leftMargin: 20
                                  anchors.rightMargin: 20
                                  spacing: 15

                                  // Date Column
                                  Text {
                                      text: model.date || "2023-12-07"
                                      font.pixelSize: 14
                                      color: "#2c3e50"
                                      width: parent.width * 0.3
                                      anchors.verticalCenter: parent.verticalCenter
                                      elide: Text.ElideRight
                                  }

                                  // Start Time Column
                                  Text {
                                      text: model.start_time || "09:30 AM"
                                      font.pixelSize: 14
                                      color: "#2c3e50"
                                      width: parent.width * 0.3
                                      anchors.verticalCenter: parent.verticalCenter
                                      elide: Text.ElideRight
                                  }

                                  // End Time Column
                                  Text {
                                      text: model.end_time || "11:45 AM"
                                      font.pixelSize: 14
                                      color: "#2c3e50"
                                      width: parent.width * 0.3
                                      anchors.verticalCenter: parent.verticalCenter
                                      elide: Text.ElideRight
                                  }
                              }

                              // Separator line
                              Rectangle {
                                  anchors.bottom: parent.bottom
                                  width: parent.width
                                  height: 1
                                  color: "#e0e0e0"
                                  opacity: 0.5
                              }
                          }

                          // Empty state
                          Label {
                              anchors.centerIn: parent
                              text: "No sessions recorded yet"
                              font.pixelSize: 16
                              color: "#7f8c8d"
                              visible: listView.count === 0
                          }
                      }
                  }
              }
          }

        }
      }

    }

    // Feedback Screen
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
              id: feedback
              source: "/qmlimages/NewImages/profile.png"
              width: 25
              height: 25
              fillMode: Image.PreserveAspectFit
              color: "white"
            }

            Text {
              text: "Feedback"
              font.pointSize: 18
              color: "white"
              font.bold: true
            }

            Item {
              Layout.fillWidth: true
            }
          }
        }

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
                implicitHeight: _formColumn.implicitHeight + 15 // Add padding

                Column {
                  id: _formColumn
                  width: parent.width
                  spacing: 10
                  anchors.centerIn: parent

                  //Mobile Number
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
                      border.width: feed_mobile.activeFocus ? 2 : 1
                      border.color: feed_mobile.activeFocus ? "#3498db" : "#dcdde1"

                      TextField {
                        id: feed_mobile
                        anchors.fill: parent
                        anchors.margins: 5
                        placeholderText: "Enter mobile number"
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhDigitsOnly

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
                      border.width: feed_email.activeFocus ? 2 : 1
                      border.color: feed_email.activeFocus ? "#3498db" : "#dcdde1"

                      TextField {
                        id: feed_email
                        anchors.fill: parent
                        anchors.margins: 5
                        placeholderText: "Enter your email"
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        verticalAlignment: TextInput.AlignVCenter
                        inputMethodHints: Qt.ImhEmailCharactersOnly

                      }
                    }
                  }

                  // Feedback Field
                  Column {
                    width: parent.width
                    spacing: 5

                    Text {
                      text: "Feedback"
                      font.pixelSize: 14
                      font.bold: true
                      color: "#2c3e50"
                      leftPadding: 5
                    }

                    Rectangle {
                      width: parent.width
                      height: 100
                      radius: 8
                      color: "white"
                      border.width: feedbackArea.activeFocus ? 2 : 1
                      border.color: feedbackArea.activeFocus ? "#3498db" : "#dcdde1"

                      TextArea {
                        id: feedbackArea
                        anchors {
                          left: parent.left
                          right: parent.right
                          top: parent.top
                          bottom: parent.bottom
                          margins: 5
                        }
                        placeholderText: "Enter your feedback here..."
                        font.pixelSize: 14
                        color: "#2c3e50"
                        background: null
                        selectByMouse: true
                        wrapMode: TextArea.Wrap
                        verticalAlignment: TextEdit.AlignTop
                      }
                    }

                  }


                  // Update Button
                  Button {
                    text: "Send"
                    width: parent.width * 0.3
                    height: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {

                      if (feedbackArea.text === "") {
                        mainWindow.showToastMessage("Enter your valuable feedback");
                        return;
                      }

                      var mobile = feed_mobile.text.trim();
                      var email = feed_email.text.trim();
                      var comments = feedbackArea.text.trim();


                      mainWindow.insertFeedback(
                            userName, // assuming userName is available in ProfileScreen
                            mobile,
                            email,
                            comments,
                            function(result) {
                              if (result) {

                                mainWindow.showToastMessage("Feedback sent successfully!");

                                currentView = "profile";

                                feed_mobile.text = "";
                                feed_email.text = "";
                                feedbackArea.text = "";

                              } else {
                                console.log(" Failed to send feedback");
                                mainWindow.showToastMessage("Failed to send feedback. Please try again.");
                              }
                            }
                            );
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


