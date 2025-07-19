import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0
import QtQuick.Layouts 1.15
Item {
    id: mainWindow1
    anchors.fill: parent
    // minimumWidth: ScreenTools.isMobile ? ScreenTools.screenWidth : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    // minimumHeight: ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    // visible: true
    property var    item1:                  null    // Required
    property var    item2:                  null    // Optional, may come and go
    property var    _fullItem
    property var    _pipOrWindowItem

    // Component.onCompleted: {
    //     console.log("newscreen pageloaded")
    //     if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="camera"){
    //         mainWindow.showToastMessage("Camera");
    //         MapGlobals.comefrom="Camera"
    //         mainWindow.cameraView()
    //         QGroundControl.saveGlobalSetting("waypoint","waypoint")
    //         console.log("MapGlobals.comefrom",MapGlobals.comefrom)
    //         var videoSettings = QGroundControl.settingsManager.videoSettings
    //                                     if (videoSettings) {
    //                                         var videoSourceFact = videoSettings.videoSource
    //                                         if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
    //                                             videoSourceFact.value = videoSourceFact.enumValues[1]
    //                                         }
    //                                     }
    //     }else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"){
    //         mainWindow.showToastMessage("agri");
    //         mainWindow.showFlyView()
    //         MapGlobals.comefrom="Plan"
    //         console.log("MapGlobals.comefrom",MapGlobals.comefrom)
    //         _appSettings.screen = "Plan"
    //         var videoSettings1 = QGroundControl.settingsManager.videoSettings1
    //         if (videoSettings1) {
    //             var videoSourceFact1 = videoSettings1.videoSource
    //             if (videoSourceFact1 && videoSourceFact1.enumValues.length > 1) {
    //                 videoSourceFact1.value = videoSourceFact1.enumValues[0]
    //             }
    //         }
    //     }
    //     else if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="mapping"){
    //         mainWindow.showToastMessage("mapping");
    //         mainWindow.showFlyView1()
    //         MapGlobals.comefrom="Start"
    //         console.log("MapGlobals.comefrom",MapGlobals.comefrom)
    //         _appSettings.screen = "Start"
    //         var videoSettings2 = QGroundControl.settingsManager.videoSettings2
    //         if (videoSettings2) {
    //             var videoSourceFact2 = videoSettings2.videoSource
    //             if (videoSourceFact2 && videoSourceFact2.enumValues.length > 1) {
    //                 videoSourceFact2.value = videoSourceFact2.enumValues[0]
    //             }
    //         }
    //             }
    // }


    // Image {
    //     anchors.fill: parent
    //     source: "/res/NoVideoBackground.jpg" // Replace with your image path
    //     fillMode: Image.PreserveAspectCrop
    //     z: -1 // Keep it behind everything else
    // }



    Rectangle {
        width: Screen.width
        height: Screen.height
        color: "transparent"  // Dark background
        Rectangle {
            anchors.fill: parent
            z: -10
            color: "#1b1c3e"
        }
        // ---- Curved Gradient Background ----
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: parent.width * 0.7
            height: parent.height * 0.9
            radius: width * 0.5
            rotation: 25
            opacity: 0.9
            anchors.rightMargin: -width * 0.2
            anchors.bottomMargin: -height * 0.2
            z: -1

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1b1c3e" }
                GradientStop { position: 1.0; color: "#7d8df7" }
            }
        }

        // ---- Top Navigation Bar ----
        RowLayout {
            spacing: 40
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 30

            Item {
                width: profileLabel.implicitWidth
                height: profileLabel.implicitHeight

                Label {
                    id: profileLabel
                    text: "PROFILE"
                    color: "white"
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mainWindow.profileScreen1(true)
                    }
                }
            }

            Label { text: "ABOUT"; color: "white"; font.pixelSize: 15;font.bold: true }
            Label { text: "CONTACT"; color: "white"; font.pixelSize: 15;font.bold: true }
            Item {
                width: logout.implicitWidth
                height: logout.implicitHeight

                Label {
                    id: logout
                    text: "LOG OUT"
                    color: "white"
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {

                         logoutdialog.createObject(mainWindow).open()
                    }
                }
            }

        }

        // ---- Title and Description ----
        Column {
            spacing: 20
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 80

            Label {
                text: "TIME TO FLY"
                color: "white"
                font.pixelSize: 30
                font.bold: true
            }



            Label {
                width: 400
                wrapMode: Text.WordWrap
                text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                color: "lightgray"
                font.pixelSize: 16
            }


        }

        // ---- Drone Image Placeholder ----
        Image {
            source: "/qmlimages/NewImages/cameradrone.png" // Replace with real image
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 100
            anchors.bottomMargin: 100
            width: parent.width * 0.30
            height: parent.height * 0.30
            fillMode: Image.PreserveAspectFit
        }

    }


    property string planType: "Standard"
    property var _appSettings: QGroundControl.settingsManager.appSettings




    property var _linkManager: QGroundControl.linkManager

    Rectangle {
        color: "transparent"
        anchors.fill: parent

        // ColumnLayout {
        // anchors.centerIn: parent
        // spacing: 20 // Space between image and text

        // Image {
        // id: droneImage
        // width: 80
        // height: 80
        // //<file alias="NEWIMAGE/Droneimage">src/Newimages/droneImage.png</file>
        // source: "qrc:/InstrumentValueIcons/drone.svg"
        // sourceSize.width: width
        // sourceSize.height: height
        // fillMode: Image.PreserveAspectFit
        // Layout.alignment: Qt.AlignHCenter
        // }


        // Text {
        // text: "Welcome to the new screen!"
        // font.pixelSize: 24
        // Layout.alignment: Qt.AlignHCenter
        // }
        // }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: 20
            spacing: 20


            Button {
                text: " Link "
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.1
                Layout.leftMargin: 10
                //font.bold: true
                font.pixelSize: 16
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white" // Set text color
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    anchors.margins: 20
                }

                background: Rectangle {
                    color: "#1b1c3e" // Blue color (iOS-style button)
                    radius: 20 // Curved button
                    border.color: "#005BBB" // Border color
                    border.width: 2
                }

                onClicked: {
                    // var outputArea
                    // var xhr = new XMLHttpRequest()
                    // xhr.open("GET", "https://jsonplaceholder.typicode.com/posts/1") // Dummy URL
                    // xhr.onreadystatechange = function() {
                    // if (xhr.readyState === XMLHttpRequest.DONE) {
                    // if (xhr.status === 200) {
                    // try {
                    // var response = JSON.parse(xhr.responseText)
                    // outputArea = "Title: " + response.title + "\nBody: " + response.body
                    // console.log("output",outputArea )
                    // } catch(e) {
                    // outputArea = "Error parsing JSON."
                    // console.log("output",outputArea )
                    // }
                    // } else {
                    // outputArea = "HTTP Error: " + xhr.status
                    // console.log("output",outputArea )
                    // }
                    // }
                    // }
                    // xhr.send()


                    // var outputArea


                    // var xhr = new XMLHttpRequest()
                    // xhr.open("POST", "https://jsonplaceholder.typicode.com/posts") // Dummy server
                    // xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8")

                    // var data = {
                    // title: "titleField.text",
                    // body: "bodyField.text",
                    // userId: 1
                    // }

                    // xhr.onreadystatechange = function() {
                    // if (xhr.readyState === XMLHttpRequest.DONE) {
                    // if (xhr.status === 201) {
                    // let response = JSON.parse(xhr.responseText)
                    // outputArea = " Data Sent!\nID: " + response.id + "\nTitle: " + response.title
                    // console.log("outputArea :",outputArea)

                    // } else {
                    // outputArea = " Failed. HTTP Status: " + xhr.status
                    // console.log("outputArea :",outputArea)
                    // }
                    // }
                    // }

                    // xhr.send(JSON.stringify(data))


                    var editingConfig = _linkManager.createConfiguration(
                                ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
                                );

                    linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open();

                }
            }

            Item { Layout.fillWidth: true }



            Button {
                text: "Camera"
                Layout.preferredWidth: parent.width * 0.1  // Fixed width
                Layout.rightMargin: 10
                //font.bold: true
                font.pixelSize: 16
                visible: true///QGroundControl.loadGlobalSetting("loadpage","loadpage")==="loadpage"?true:QGroundControl.loadGlobalSetting("loadpage","loadpage")==="camera"?true:false
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"  // Set text color
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    anchors.margins: 20
                }

                background: Rectangle {
                    color: "#1b1c3e"  // Blue color (iOS-style button)
                    radius: 20  // Curved button
                    border.color: "#005BBB"  // Border color
                    border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "camera")
                    MapGlobals.comefrom="Camera"
                    mainWindow.cameraView()
                    QGroundControl.saveGlobalSetting("waypoint","waypoint")
                    console.log("MapGlobals.comefrom",MapGlobals.comefrom)
                    //_appSettings.screen = "Plan"
                    //pipview.camera()
                    var videoSettings = QGroundControl.settingsManager.videoSettings
                    if (videoSettings) {
                        var videoSourceFact = videoSettings.videoSource
                        if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                            videoSourceFact.value = videoSourceFact.enumValues[1]
                        }
                    }



                }
            }

            Button {
                text: "Agri"
                Layout.preferredWidth: parent.width * 0.1
                Layout.rightMargin: 10
                //font.bold: true
                font.pixelSize: 16
                visible: /true///QGroundControl.loadGlobalSetting("loadpage","loadpage")==="loadpage"?true:QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?true:false
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white" // Set text color
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    anchors.margins: 20
                }

                background: Rectangle {
                    color: "#1b1c3e" // Blue color (iOS-style button)
                    radius: 20 // Curved button
                    border.color: "#005BBB" // Border color
                    border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "agri")
                    mainWindow.showFlyView()
                    MapGlobals.comefrom="Plan"
                    console.log("MapGlobals.comefrom",MapGlobals.comefrom)
                    _appSettings.screen = "Plan"
                    var videoSettings = QGroundControl.settingsManager.videoSettings
                    if (videoSettings) {
                        var videoSourceFact = videoSettings.videoSource
                        if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                            videoSourceFact.value = videoSourceFact.enumValues[0]
                        }
                    }

                }
            }


            Button {
                text: "Mapping"
                Layout.preferredWidth: parent.width * 0.1
                Layout.rightMargin: 10
                //font.bold: true
                font.pixelSize: 16
                visible: /true///QGroundControl.loadGlobalSetting("loadpage","loadpage")==="loadpage"?true:QGroundControl.loadGlobalSetting("loadpage","loadpage")==="mapping"?true:false
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white" // Set text color
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    anchors.margins: 20
                }

                background: Rectangle {
                    color: "#1b1c3e" // Blue color (iOS-style button)
                    radius: 20 // Curved button
                    border.color: "#005BBB" // Border color
                    border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "mapping")
                    mainWindow.showFlyView1()
                    MapGlobals.comefrom="Start"
                    console.log("MapGlobals.comefrom",MapGlobals.comefrom)
                    _appSettings.screen = "Start"
                    var videoSettings = QGroundControl.settingsManager.videoSettings
                    if (videoSettings) {
                        var videoSourceFact = videoSettings.videoSource
                        if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                            videoSourceFact.value = videoSourceFact.enumValues[0]
                        }
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

        Component {
            id: linkDialogComponent

            QGCPopupDialog {
                title:          originalConfig ? qsTr("Edit Link") : qsTr("Add New Link")
                buttons:        Dialog.Save | Dialog.Cancel
                //acceptAllowed:  nameField.text !== ""

                property var originalConfig
                property var editingConfig

                onAccepted: {
                    linkSettingsLoader.item.saveSettings()
                    //editingConfig.name = nameField.text

                    //console.log("Bluetooth Save Button",editingConfig.name)

                    if (originalConfig) {
                        console.log("Bluetooth Save Button Add New Link",originalConfig)
                        _linkManager.endConfigurationEditing(originalConfig, editingConfig)

                        if (editingConfig.link) {
                            editingConfig.link.disconnect()
                            editingConfig.linkChanged()
                        } else {
                            _linkManager.createConnectedLink(editingConfig)

                        }

                    } else {
                        // If it was edited, it's no longer "dynamic"
                        editingConfig.dynamic = false
                        _linkManager.endCreateConfiguration(editingConfig)

                        if (editingConfig.link) {
                            editingConfig.link.disconnect()
                            editingConfig.linkChanged()
                        } else {
                            _linkManager.createConnectedLink(editingConfig)

                        }

                        console.log("Bluetooth Save Button Edit Link",originalConfig)
                    }
                }

                onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    // RowLayout {
                    //     Layout.fillWidth:   true
                    //     spacing:            ScreenTools.defaultFontPixelWidth

                    //     //QGCLabel { text: qsTr(QGroundControl.loadGlobalSetting("bluetooth_name","Name")) }

                    //     QGCLabel { text: qsTr("Name") }

                    //     QGCTextField {
                    //         id:                 nameField
                    //         Layout.fillWidth:   true
                    //         text:               editingConfig.devName
                    //         placeholderText:    qsTr("Enter name")
                    //     }
                    // }

                    // QGCCheckBoxSlider {
                    //     Layout.fillWidth:   true
                    //     text:               qsTr("Automatically Connect on Start")
                    //     checked:            editingConfig.autoConnect
                    //     onCheckedChanged:   editingConfig.autoConnect = checked
                    // }

                    // QGCCheckBoxSlider {
                    //     Layout.fillWidth:   true
                    //     text:               qsTr("High Latency")
                    //     checked:            editingConfig.highLatency
                    //     onCheckedChanged:   editingConfig.highLatency = checked
                    // }

                    LabelledComboBox {
                        label:                  qsTr("Type")
                        enabled:                originalConfig == null
                        model:                  _linkManager.linkTypeStrings
                        Component.onCompleted:  comboBox.currentIndex = editingConfig.linkType

                        onActivated: (index) => {
                                         if (index !== editingConfig.linkType) {
                                             // Save current name
                                             // var name = nameField.text
                                             // Create new link configuration
                                             editingConfig = _linkManager.createConfiguration(index, "")
                                         }
                                     }
                    }

                    Loader {
                        id:     linkSettingsLoader
                        source: subEditConfig.settingsURL

                        property var subEditConfig:         editingConfig
                        property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                        property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                        property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                        property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
                    }
                }
            }
        }
    }


}
