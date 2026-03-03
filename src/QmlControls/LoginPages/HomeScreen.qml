import QtQuick
import QtQuick.Controls
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QGroundControl
import Qt.labs.lottieqt 1.0
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals
import QtQuick.Layouts

import QtQuick.Effects

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

    property string droneType: QGroundControl.loadGlobalSetting("loadpage","loadpage");

    property color app_color: "#5d179e"

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    property real scaleRatio: Math.min(screenWidth / 400, screenHeight / 800)
    property real baseUnit: 8 * scaleRatio


    function dp(value) {
        return value * baseUnit;
    }

    onVisibleChanged : {
        if (visible) {
            console.log("HomeScreen onVisibleChanged");
            droneType = QGroundControl.loadGlobalSetting("loadpage","loadpage");
            console.log("droneType",droneType);
        }
    }


    function swapCamera(){
        var videoSettings = QGroundControl.settingsManager.videoSettings
        if (videoSettings) {
            var videoSourceFact = videoSettings.videoSource
            if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                videoSourceFact.value = videoSourceFact.enumValues[1]
            }
        }
    }

    /* ========= BACKGROUND IMAGE ========= */
    Image {
        id: bgImage
        anchors.fill: parent
        source: "qrc:/qmlimages/NewImages/background_home.png"
        fillMode: Image.PreserveAspectCrop
        z: 0
    }

    Item {
        anchors.fill: parent
        z: 1

        // ---- Top Navigation Bar ----
        Item {
            width: parent.width
            height: 50
            anchors.top: parent.top
            anchors.topMargin: 20

            // LEFT IMAGE (pinned left)
            // QGCColoredImage {
            //     source: "/qmlimages/NewImages/aviatrickslogo.svg"
            //     width: parent.width * 0.3
            //     height: 30
            //     fillMode: Image.PreserveAspectFit
            //     color: "transparent"

            //     anchors.left: parent.left
            //     anchors.leftMargin: 20
            //     anchors.verticalCenter: parent.verticalCenter
            // }

            // CENTERED LABELS GROUP
            Rectangle {
                id: tabBar

                width: contentRow.width + dp(10)
                height: contentRow.height + dp(5)

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: dp(2)
                radius: 25
                color: "transparent"
                border.width: 1
                border.color: app_color
                clip: true

                Row {
                    id: contentRow
                    spacing: dp(10)
                    anchors.centerIn: parent

                    Item {
                        width: profileLabel.implicitWidth
                        height: profileLabel.implicitHeight

                        Label {
                            id: profileLabel
                            text: "PROFILE"
                            color: "black"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                MapGlobals.currentView_profile = "profile"
                                mainWindow.openProfileScreen()
                            }
                        }
                    }

                    Item {
                        width: select_type.implicitWidth
                        height: select_type.implicitHeight

                        Label {
                            id: select_type
                            text: "APPLICATION"
                            color: "black"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                MapGlobals.currentView_profile = "drone"
                                mainWindow.openProfileScreen()
                                //logoutdialog.createObject(mainWindow).open()
                            }
                        }
                    }

                    Item {
                        width: logout.implicitWidth
                        height: logout.implicitHeight

                        Label {
                            id: logout
                            text: "LOGOUT"
                            color: "black"
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

            }


        }

        Row {
            id: mainRow
            width: parent.width - 60  // accounting for margins
            height: parent.height - 60
            anchors.centerIn: parent
            spacing: 20

            // LEFT SIDE
            Column {
                id: leftSide
                width: mainRow.width * 0.55
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                QGCColoredImage {
                    source: "/qmlimages/NewImages/aviatrickslogo.svg"
                    width: parent.width * 0.35
                    height: 35
                    fillMode: Image.PreserveAspectFit
                    color: "transparent"
                }

                Label {
                    width: parent.width * 0.9
                    wrapMode: Text.WordWrap
                    text: "Flying a drone is like holding a piece of freedom in your hands. The view from above always tells a story the ground can't."
                    color: "gray"
                    font.pointSize: ScreenTools.mediumFontPointSize
                }
            }

            // RIGHT SIDE
            Item {
                id: rightSide
                width: mainRow.width * 0.4
                height: mainRow.height * 0.6
                anchors.verticalCenter: parent.verticalCenter
                clip: false  // IMPORTANT: allow shadow outside

                onVisibleChanged: console.log("rightSide visible:", visible, "droneType:", droneType)

                // ---- SHADOW SOURCE ----
                Rectangle {
                    id: shadowSource
                    anchors.fill: card
                    radius: 8
                    color: "white"
                    visible: false
                }

                // ---- REAL ELEVATION ----
                MultiEffect {
                    anchors.fill: shadowSource
                    source: shadowSource
                    shadowEnabled: true
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: dp(2)
                    shadowBlur: 1.5
                    shadowColor: "#40000000"
                }

                // ---- CARD ----
                Rectangle {
                    id: card
                    anchors.fill: parent
                    radius: 8
                    color: "white"

                    // Enable layer to make clip respect the radius
                    layer.enabled: true
                    layer.smooth: true
                    clip: true

                    // Background Image (always present)
                    Image {
                        id: backgroundImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        mipmap: true
                        visible: droneType !== "loadpage"

                        source:
                            droneType === "Camera"  ? "qrc:/qmlimages/NewImages/drone_pilot_AiImage.jpg" :
                            droneType === "Mapping" ? "qrc:/qmlimages/NewImages/drone_expert_AiImage.jpg" :
                                                      "qrc:/qmlimages/NewImages/inspect_AiImage.jpg"

                        onStatusChanged: {
                            console.log("Image status:", status, source)
                            if (status === Image.Error) console.log("ERROR loading image")
                            if (status === Image.Ready) console.log("Image loaded OK")
                        }
                    }

                    // Lottie overlay
                    Item {
                        id: lottieWrapper
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        visible: droneType === "loadpage"
                        z: 30

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: dp(2)
                            radius: dp(4)
                            clip: true
                            color: "transparent"

                            LottieAnimation {
                                anchors.centerIn: parent
                                source: "qrc:/qmlimages/NewImages/droneManFly.json"
                                autoPlay: true
                                loops: Animation.Infinite
                                scale: 0.35
                                frameRate: 24
                            }
                        }
                    }
                }

            }
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: 20
            anchors.leftMargin: 30
            anchors.rightMargin: 30
            spacing: 20

            Button {
                id: connectbtn
                text: "Connect"
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.13
                implicitHeight: 30

                contentItem: Item {
                    anchors.centerIn: parent

                    Text {
                        text: connectbtn.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.Medium
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Row {
                    //     anchors.centerIn: parent
                    //     spacing: 6

                    //     Text {
                    //         text: connectbtn.text
                    //         font.pointSize: ScreenTools.defaultFontPointSize
                    //         font.weight: Font.Medium
                    //         color: "white"
                    //         verticalAlignment: Text.AlignVCenter
                    //     }

                    //     QGCColoredImage {
                    //         source: "/qmlimages/NewImages/commlinks.svg"
                    //         width: 15
                    //         height: 15
                    //         fillMode: Image.PreserveAspectFit
                    //         anchors.verticalCenter: parent.verticalCenter
                    //     }
                    // }

                }


                background: Rectangle {
                    color: app_color
                    radius: 6
                    //border.color: "#005BBB"
                    //border.width: 2
                }

                onClicked: {
                    //QGroundControl.saveGlobalSetting("loadpage", "loadpage")

                    var editingConfig = _linkManager.createConfiguration(
                                ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
                                );

                    typeSelectionDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open();

                }

            }


            Item { Layout.fillWidth: true }


            Button {
                id:camera
                text: "Camera"
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.13
                implicitHeight: 30
                visible: droneType==="loadpage" ? true : droneType==="Camera" ? true : false

                contentItem: Item {
                    anchors.centerIn: parent

                    Text {
                        text: camera.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.Medium
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter

                    }

                    // Row {
                    //     anchors.centerIn: parent
                    //     spacing: 6

                    //     Text {
                    //         text: camera.text
                    //         font.pointSize: ScreenTools.defaultFontPointSize
                    //         font.weight: Font.Medium
                    //         color: "white"
                    //         verticalAlignment: Text.AlignVCenter

                    //     }

                    //     QGCColoredImage {
                    //         source: "/qmlimages/NewImages/camera_Application.svg"
                    //         width: 15
                    //         height: 15
                    //         fillMode: Image.PreserveAspectFit
                    //         anchors.verticalCenter: parent.verticalCenter
                    //     }
                    // }

                }

                background: Rectangle {
                    color: app_color
                    radius: 6
                    //border.color: "#005BBB"
                    //border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "Camera")
                    MapGlobals.comefrom = "Camera"
                    mainWindow.cameraView()
                    QGroundControl.saveGlobalSetting("waypoint","waypoint")
                    console.log("MapGlobals.comefrom",MapGlobals.comefrom)
                    //_appSettings.screen = "Plan"
                    //pipview.camera()

                    var videoSettings = QGroundControl.settingsManager.videoSettings

                    if (videoSettings) {
                        var videoSourceFact = videoSettings.videoSource
                        if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                            videoSourceFact.value = videoSourceFact.enumValues[0]
                        }
                    }

                    swapCamera();
                    // camera.visible=true
                    // agri.visible=false
                    // mapping.visible=false
                    // vtol.visible=false
                }
            }

            Button {
                id:agri
                text: "Agri"
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.13
                implicitHeight: 30
                visible: droneType==="loadpage" ? true : droneType==="Agri"? true : false

                contentItem: Item {
                    anchors.centerIn: parent

                    Text {
                        text: agri.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.Medium
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter

                    }

                    //      Row {
                    //          anchors.centerIn: parent
                    //          spacing: 6

                    //          Text {
                    //              text: agri.text
                    //              font.pointSize: ScreenTools.defaultFontPointSize
                    //              font.weight: Font.Medium
                    //              color: "white"
                    //              verticalAlignment: Text.AlignVCenter

                    //          }

                    //          QGCColoredImage {
                    //              source: "/qmlimages/NewImages/agri_Application.svg"
                    //              width: 15
                    //              height: 15
                    //              fillMode: Image.PreserveAspectFit
                    //              anchors.verticalCenter: parent.verticalCenter
                    //          }
                    //      }

                }

                background: Rectangle {
                    color: app_color
                    radius: 6
                    //border.color: "#005BBB"
                    //border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "Agri")
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

                    swapCamera();
                    // camera.visible=false
                    // agri.visible=true
                    // mapping.visible=false
                    // vtol.visible=false

                }
            }

            Button {
                id:mapping
                text: "Mapping"
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.13
                implicitHeight: 30
                visible: droneType==="loadpage"?true:droneType==="Mapping"?true:false

                contentItem: Item {
                    anchors.centerIn: parent

                    Text {
                        text: mapping.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.weight: Font.Medium
                        color: "white"
                        verticalAlignment: Text.AlignVCenter
                        anchors.horizontalCenter: parent.horizontalCenter

                    }

                    // Row {
                    //     anchors.centerIn: parent
                    //     spacing: 6

                    //     Text {
                    //         text: mapping.text
                    //         font.pointSize: ScreenTools.defaultFontPointSize
                    //         font.weight: Font.Medium
                    //         color: "white"
                    //         verticalAlignment: Text.AlignVCenter

                    //     }

                    //     QGCColoredImage {
                    //         source: "/qmlimages/NewImages/mapping_Application.svg"
                    //         width: 15
                    //         height: 15
                    //         fillMode: Image.PreserveAspectFit
                    //         anchors.verticalCenter: parent.verticalCenter
                    //     }
                    // }

                }

                background: Rectangle {
                    color: app_color
                    radius: 6
                    //border.color: "#005BBB"
                    //border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "Mapping")
                    mainWindow.showMapping()
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

                    swapCamera();

                    // camera.visible=false
                    // agri.visible=false
                    // mapping.visible=true
                    // vtol.visible=false
                }
            }

            // Button {
            //     id:vtol
            //     text: "VTOL"
            //     Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
            //     Layout.preferredWidth: parent.width * 0.13
            //     implicitHeight: 30
            //     visible: droneType ==="loadpage"?true:droneType ==="VTOL"?true:false

            //     contentItem: Item {
            //         anchors.fill: parent
            //         Row {
            //             anchors.centerIn: parent
            //             spacing: 6

            //             Text {
            //                 text: vtol.text
            //                 font.pointSize: ScreenTools.defaultFontPointSize
            //                 font.weight: Font.Medium
            //                 color: "white"
            //                 verticalAlignment: Text.AlignVCenter

            //             }

            //             QGCColoredImage {
            //                 source: "/qmlimages/NewImages/VTOL_application.svg"
            //                 width: 15
            //                 height: 15
            //                 fillMode: Image.PreserveAspectFit
            //                 color: "white"
            //                 anchors.verticalCenter: parent.verticalCenter
            //             }
            //         }

            //     }

            //     background: Rectangle {
            //         color: "#1b1c3e" // Blue color (iOS-style button)
            //         radius: 20 // Curved button
            //         border.color: "#005BBB" // Border color
            //         border.width: 2
            //     }

            //     onClicked: {
            //         QGroundControl.saveGlobalSetting("loadpage", "VTOL")
            //         mainWindow.showFlyView1()
            //         MapGlobals.comefrom="Start"
            //         console.log("MapGlobals.comefrom",MapGlobals.comefrom)
            //         _appSettings.screen = "Start"
            //         var videoSettings = QGroundControl.settingsManager.videoSettings
            //         if (videoSettings) {
            //             var videoSourceFact = videoSettings.videoSource
            //             if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
            //                 videoSourceFact.value = videoSourceFact.enumValues[0]
            //             }
            //         }
            //         // camera.visible=false
            //         // agri.visible=false
            //         // mapping.visible=false
            //         // vtol.visible=true
            //     }
            // }

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
                QGroundControl.saveGlobalSetting("loadpage", "loadpage")
                popup.visible = false
                MapGlobals.profile()
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

    // First Dialog – Type Selection Only

    Component {
        id: typeSelectionDialogComponent

        QGCPopupDialog {
            id: typeDialog
            title: qsTr("Select Link Type")
            buttons: 0
            showButtons: false
            //close icon condition
            closeOnClickOutside: true

            property int selectedType: -1

            ColumnLayout {
                spacing: 15                     // we’ll control spacing ourselves
                Layout.fillWidth: true

                Repeater {
                    model: _linkManager.linkTypeStrings
                    delegate: RowLayout {
                        Layout.fillWidth: true        // row spans full width
                        spacing: 20

                        Rectangle {
                            width: 25
                            height: 25
                            radius: width/2
                            color: "#7F56D9"

                            Text {
                                anchors.centerIn: parent
                                font.pixelSize: 14
                                color: "white"
                                text: index + 1
                            }
                        }

                        //Item { Layout.fillWidth: true }

                        // clickable text
                        Text {
                            text: modelData
                            //Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 16
                            color: "black"   // adjust to your theme

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    typeDialog.selectedType = index
                                    typeDialog.close()
                                    var editingConfig = _linkManager.createConfiguration(index, "")
                                    linkConfigDialogComponent.createObject(mainWindow, {
                                                                               editingConfig: editingConfig,
                                                                               originalConfig: null,
                                                                               selectedType: index
                                                                           }).open()
                                }
                                // hoverEnabled: true
                                // onEntered: parent.color = "blue"   // optional hover effect
                                // onExited:  parent.color = "green"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // // full-width divider
                        // Rectangle {
                        //     Layout.fillWidth: true
                        //     height: 1
                        //     color: "#aaaaaa"  // divider colour
                        // }
                    }
                }
            }
        }
    }

    // Second Dialog - Configuration (without type dropdown)
    Component {
        id: linkConfigDialogComponent

        QGCPopupDialog {
            title:          selectedType === 3 ? "Bluetooth Devices"
                                               : originalConfig ? qsTr("Edit Link")
                                                                : qsTr("Add New Link")
            buttons:        Dialog.Save | Dialog.Cancel
            acceptAllowed:  nameField.text !== ""

            property var originalConfig
            property var editingConfig
            property int selectedType

            Connections {
                target: editingConfig
                enabled: editingConfig !== null

                function onShowToast(message) {
                    mainWindow.showToastMessage(message)
                }
            }

            onAccepted: {
                linkSettingsLoader.item.saveSettings()
                editingConfig.devName = nameField.text
                editingConfig.name    = editingConfig.devName

                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)
                    _linkManager.createConnectedLink(editingConfig)
                }
            }

            onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

            // ---------- MAIN LAYOUT ----------
            ColumnLayout {
                id: mainColumn
                spacing: ScreenTools.defaultFontPixelHeight / 2
                Layout.fillWidth: true


                // ---- Name row (not shown for Bluetooth) ----
                RowLayout {
                    Layout.fillWidth: true    // row stretches full width
                    spacing: ScreenTools.defaultFontPixelWidth
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"

                    QGCLabel { text: qsTr("Name") }

                    QGCTextField {
                        id:               nameField
                        Layout.fillWidth: true   // text field grows to take remaining width
                        text:             editingConfig.devName
                        placeholderText:  qsTr("Enter name")
                    }
                }

                // ---- Device list / settings loader ----
                Loader {
                    id: linkSettingsLoader
                    Layout.fillWidth: true        // << ensures it spans the whole dialog
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

    property string planType: "Standard"
    property var _appSettings: QGroundControl.settingsManager.appSettings

    property var _linkManager: QGroundControl.linkManager


}
