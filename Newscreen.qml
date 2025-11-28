import QtQuick 2.15
import QtQuick.Controls 2.15
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

    property string droneType: "loadpage"

    onVisibleChanged : {
        if (visible) {
            console.log("NewScreen onVisibleChanged");
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

    function camera(){
        camera.visible=true
        agri.visible=false
        mapping.visible=false
        vtol.visible=false
        cameraicon.visible=true
        agriicon.visible=false
        mappingicon.visible=false
        vtolicon.visible=false
        droneAnim1.visible=false
    }

    function agri(){
        camera.visible=false
        agri.visible=true
        mapping.visible=false
        vtol.visible=false
        cameraicon.visible=false
        agriicon.visible=true
        mappingicon.visible=false
        vtolicon.visible=false
        droneAnim1.visible=false
    }

    function mapping(){
        camera.visible=false
        agri.visible=false
        mapping.visible=true
        vtol.visible=false
        cameraicon.visible=false
        agriicon.visible=false
        mappingicon.visible=true
        vtolicon.visible=false
        droneAnim1.visible=false
    }

    function vtol(){
        camera.visible=false
        agri.visible=false
        mapping.visible=false
        vtol.visible=true
        cameraicon.visible=false
        agriicon.visible=false
        mappingicon.visible=false
        vtolicon.visible=true
        droneAnim1.visible=false
    }


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
            z: 0
            color: "#1b1c3e"
        }

        //---- Curved Gradient Background ----
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
            z: 1

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

            // Label { text: "ABOUT"; color: "white"; font.pixelSize: 15;font.bold: true }
            // Label { text: "CONTACT"; color: "white"; font.pixelSize: 15;font.bold: true }

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

        Row {
            id: mainRow
            z: 5
            anchors.fill: parent
            anchors.margins: 40
            spacing: 20

            // LEFT SIDE
            Column {
                id: leftSide
                width: parent.width * 0.55
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                Label {
                    text: "TIME TO FLY"
                    color: "white"
                    font.pointSize:  ScreenTools.largeFontPointSize * 1.2
                    font.bold: true
                }

                Label {
                    width: parent.width * 0.9
                    wrapMode: Text.WordWrap
                    text: "Flying a drone is like holding a piece of freedom in your hands. The view from above always tells a story the ground can’t."
                    color: "lightgray"
                    font.pointSize:  ScreenTools.mediumFontPointSize
                }
            }

            // RIGHT SIDE
            Item {
                id: rightSide
                width: parent.width * 0.45
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Item {
                    id: lottieWrapper
                    anchors.centerIn: parent
                    width: rightSide.width
                    height: width
                    scale: 0.3
                    visible: droneType === "loadpage"

                    LottieAnimation {
                        id: droneAnim
                        source: "qrc:/qmlimages/NewImages/droneManFly.json"
                        autoPlay: true
                        loops: Animation.Infinite

                        anchors.centerIn: parent
                    }
                }

                // ---- Drone Image Placeholder ----
                Image {
                    id:cameraicon
                    source: "/qmlimages/NewImages/cameradrone.svg" // Replace with real image
                    visible: droneType ==="Camera"?true:false
                    anchors.centerIn: parent
                    width: parent.width * 0.4
                    height: parent.height * 0.4
                    fillMode: Image.PreserveAspectFit
                }

                Image {
                    id: mappingicon
                    source: "/qmlimages/NewImages/survey.png" // Replace with real image
                    visible: droneType ==="Mapping"?true:false
                    anchors.centerIn: parent
                    width: parent.width * 0.4
                    height: parent.height * 0.4
                    fillMode: Image.PreserveAspectFit
                }

                Image {
                    id: vtolicon
                    source: "/qmlimages/NewImages/vtol.png" // Replace with real image
                    anchors.centerIn: parent
                    width: parent.width * 0.4
                    height: parent.height * 0.4
                    fillMode: Image.PreserveAspectFit
                    visible: droneType ==="VTOL"?true:false
                }

                Image {
                    id:agriicon
                    source: "/qmlimages/NewImages/agri.png" // Replace with real image
                    anchors.centerIn: parent
                    width: parent.width * 0.4
                    height: parent.height * 0.4
                    fillMode: Image.PreserveAspectFit
                    visible: droneType ==="Agri"?true:false
                }
            }
        }

    }

    property string planType: "Standard"
    property var _appSettings: QGroundControl.settingsManager.appSettings

    property var _linkManager: QGroundControl.linkManager

    Rectangle {
        color: "transparent"
        anchors.fill: parent

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: 20
            spacing: 20

            //  Button {
            //      id : connectbtn
            //      text: " Connect "
            //      Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
            //      Layout.bottomMargin: parent.height * 0.1
            //      implicitWidth: parent.width * 0.1

            //      //Layout.preferredWidth: parent.width * 0.13
            //      //Layout.leftMargin: 10
            //      //font.bold: true
            //      //font.pixelSize: 16


            //      contentItem: Item {
            //          anchors.fill: parent

            //          // clip: true

            //          Row {
            //              anchors.centerIn: parent
            //              //anchors.margins: 20
            //              spacing: 3

            //              Text {
            //                  text: connectbtn.text
            //                  font.pointSize: ScreenTools.defaultFontPointSize
            //                  font.weight: Font.Medium
            //                  color: "white"
            //                  verticalAlignment: Text.AlignVCenter
            //              }

            //              QGCColoredImage {
            //                  source: "/qmlimages/NewImages/commlinks.svg"
            //                  fillMode: Image.PreserveAspectFit
            //                  width: 20
            //                  height: 20
            //              }
            //          }
            //      }

            //      background: Rectangle {
            //          color: "#1b1c3e" // Blue color (iOS-style button)
            //          radius: 20 // Curved button
            //          border.color: "#005BBB" // Border color
            //          border.width: 2
            //      }

            //      onClicked: {
            //          //QGroundControl.saveGlobalSetting("loadpage", "loadpage")

            //          var editingConfig = _linkManager.createConfiguration(
            //                      ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
            //                      );

            //          typeSelectionDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open();

            //      }

            //  }

            Button {
                id: connectbtn
                text: "Connect"
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.13
                implicitHeight: 30

                contentItem: Item {
                    anchors.fill: parent
                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: connectbtn.text
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.weight: Font.Medium
                            color: "white"
                            verticalAlignment: Text.AlignVCenter

                        }

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/commlinks.svg"
                            width: 15
                            height: 15
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                }


                background: Rectangle {
                    color: "#1b1c3e"
                    radius: 20
                    border.color: "#005BBB"
                    border.width: 2
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
                    anchors.fill: parent
                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: camera.text
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.weight: Font.Medium
                            color: "white"
                            verticalAlignment: Text.AlignVCenter

                        }

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/camera_Application.svg"
                            width: 15
                            height: 15
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                }

                background: Rectangle {
                    color: "#1b1c3e"  // Blue color (iOS-style button)
                    radius: 20  // Curved button
                    border.color: "#005BBB"  // Border color
                    border.width: 2
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
                    anchors.fill: parent
                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: agri.text
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.weight: Font.Medium
                            color: "white"
                            verticalAlignment: Text.AlignVCenter

                        }

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/agri_Application.svg"
                            width: 15
                            height: 15
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                }

                background: Rectangle {
                    color: "#1b1c3e" // Blue color (iOS-style button)
                    radius: 20 // Curved button
                    border.color: "#005BBB" // Border color
                    border.width: 2
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
                    anchors.fill: parent
                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: mapping.text
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.weight: Font.Medium
                            color: "white"
                            verticalAlignment: Text.AlignVCenter

                        }

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/mapping_Application.svg"
                            width: 15
                            height: 15
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                }

                background: Rectangle {
                    color: "#1b1c3e" // Blue color (iOS-style button)
                    radius: 20 // Curved button
                    border.color: "#005BBB" // Border color
                    border.width: 2
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

            Button {
                id:vtol
                text: "VTOL"
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.preferredWidth: parent.width * 0.13
                implicitHeight: 30
                visible: droneType ==="loadpage"?true:droneType ==="VTOL"?true:false

                contentItem: Item {
                    anchors.fill: parent
                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: vtol.text
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.weight: Font.Medium
                            color: "white"
                            verticalAlignment: Text.AlignVCenter

                        }

                        QGCColoredImage {
                            source: "/qmlimages/NewImages/VTOL_application.svg"
                            width: 15
                            height: 15
                            fillMode: Image.PreserveAspectFit
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                }

                background: Rectangle {
                    color: "#1b1c3e" // Blue color (iOS-style button)
                    radius: 20 // Curved button
                    border.color: "#005BBB" // Border color
                    border.width: 2
                }

                onClicked: {
                    QGroundControl.saveGlobalSetting("loadpage", "VTOL")
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
                    // camera.visible=false
                    // agri.visible=false
                    // mapping.visible=false
                    // vtol.visible=true
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
                    QGroundControl.saveGlobalSetting("loadpage", "loadpage")
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

        // First Dialog – Type Selection Only

        Component {
            id: typeSelectionDialogComponent

            QGCPopupDialog {
                id: typeDialog
                title: qsTr("Select Link Type")
                buttons: false
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
    }
}
