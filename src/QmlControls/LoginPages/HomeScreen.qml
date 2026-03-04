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
    property color app_color: "#4a2c6d"
    property color secondary_color: "#7c4dff"
    property color accent_color: "#f97316" // The Orange accent



    property real screenWidth: parent.width
    property real screenHeight: parent.height
    // Use ScreenTools for consistent scaling across devices, falling back to a ratio-based approach if needed
    property real baseUnit: ScreenTools.defaultFontPixelWidth * 0.8
    function dp(value) { return value * baseUnit; }

    property bool isMobile: ScreenTools.isMobile
    property bool isTablet: ScreenTools.isMobile && !ScreenTools.isTinyScreen
    property bool isDesktop: !ScreenTools.isMobile
    property bool isSmallScreen: ScreenTools.isTinyScreen

    // DYNAMIC SCALING: Professional responsive multiplier
    property real dynamicScaleFactor: {
        var baseWidth = 1200
        var scale = parent.width / baseWidth
        if (isSmallScreen) return Math.max(0.7, scale * 1.2)
        if (isTablet)      return Math.max(0.9, scale * 1.1)
        return Math.max(1.0, scale)
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

    /* ========= DYNAMIC BACKGROUND ========= */
    Item {
        id: bgContainer
        anchors.fill: parent
        z: 0

        Image {
            id: bgImage
            anchors.fill: parent
            source: {
                if (droneType === "Camera")  return "qrc:/qmlimages/NewImages/agri_bg_image5.png"
                if (droneType === "Mapping") return "qrc:/qmlimages/NewImages/agri_bg_image5.png"
                if (droneType === "Agri")    return "qrc:/qmlimages/NewImages/agri_bg_image5.png"
                return "qrc:/qmlimages/NewImages/nature_background.png" // Fallback
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            mipmap: true

            // Subtle pulse to the background for life
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.05; duration: 20000; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.05; to: 1.0; duration: 20000; easing.type: Easing.InOutSine }
            }
        }

        // Animated gradient overlay for moving light effect
        Rectangle {
            anchors.fill: parent
            opacity: 0.6
            gradient: Gradient {
                GradientStop { position: 0.0; color: "black" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        // Darkening overlay for cinematic look and text readability - with vignette
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                id: vignetteGradient
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.2) }
                GradientStop { position: 0.8; color: Qt.rgba(0,0,0,0.5) }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.7) }
            }
        }

        // Layered Agri Drone for theme
        Image {
            id: agriDrone
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: (isSmallScreen || isMobile) ? dp(1) : 40
            width: (isSmallScreen || isMobile) ? parent.width * 0.35 : parent.width * 0.45
            height: width
            source: "qrc:/qmlimages/NewImages/agri_AIImage_transparent.png"
            fillMode: Image.PreserveAspectFit
            visible: droneType === "Agri"
            opacity: 0.94
            asynchronous: true
            cache: true
            mipmap: true
        }

         Image {
            id: showMappingDrone
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: (isSmallScreen || isMobile) ? dp(1) : 40
            width: (isSmallScreen || isMobile) ? parent.width * 0.35 : parent.width * 0.45
            height: width
            source: "qrc:/qmlimages/NewImages/mapping_AIImage.png"
            fillMode: Image.PreserveAspectFit
            visible: droneType === "Mapping"
            opacity: 0.94
            asynchronous: true
            cache: true
            mipmap: true
        }

        Image {
            id:cameraDrone
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: (isSmallScreen || isMobile) ? -dp(8) : 0
            width: (isSmallScreen || isMobile) ? parent.width * 0.50 : parent.width * 0.70
            height: width
            source: "qrc:/qmlimages/NewImages/cameraDrone_png.png"
            fillMode: Image.PreserveAspectFit
            visible: droneType === "Camera"
            opacity: 0.94
            asynchronous: true
            cache: true
            mipmap: true
        }
    }

    Item {
        anchors.fill: parent
        z: 1

        // ---- TOP LEFT LOGO ----
        Image {
            source: "qrc:/qmlimages/NewImages/aviatrickslogo.svg"
            width: Math.min(parent.width * 0.20, dp(140))
            height: dp(5.5)
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: isSmallScreen ? dp(5) : 30
            anchors.topMargin: isSmallScreen ? dp(5) : 30
            z: 5
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
            Component.onCompleted: opacity = 1
        }

        Label {
            id: topBrandText
            text: "DRONE COMMANDER"
            // Hide on small mobile screens (phones), show on tablets and desktop
            visible: (droneType === "loadpage" || parent.height > 500) && !isSmallScreen
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            // Ensure space is shared between header and content
            anchors.topMargin: {
                if (droneType === "loadpage") {
                    return Math.max(dp(20), parent.height * 0.3)
                } else {
                    return dp(16) // Moved down for more style
                }
            }
            color: "#FFFFFF"
            font.family: "Outfit"
            font.bold: true
            font.letterSpacing: isTablet || isDesktop ? 8 : 4
            // Use ScreenTools.largeFontPointSize for better resolution independence
            font.pointSize: {
                var baseSize = ScreenTools.largeFontPointSize
                var scaleMultiplier = dynamicScaleFactor
                
                if (droneType === "loadpage") {
                    if (isDesktop) return baseSize * 4.0 * scaleMultiplier
                    if (isTablet)  return baseSize * 3.5 * scaleMultiplier
                    return baseSize * 1.8 // Mobile stays clean
                } else {
                    if (isDesktop) return baseSize * 2.8 * scaleMultiplier
                    if (isTablet)  return baseSize * 2.4 * scaleMultiplier
                    return baseSize * 1.3
                }
            }
            opacity: 0
            z: 5

            // Position and Size Animations
            Behavior on anchors.topMargin { NumberAnimation { duration: 800; easing.type: Easing.OutBack } }
            Behavior on font.pointSize { NumberAnimation { duration: 600 } }
            Behavior on font.letterSpacing { NumberAnimation { duration: 600 } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0,0,0,0.8)
                shadowBlur: 0.4
                shadowVerticalOffset: 2
                blurEnabled: true
                blur: 0.1
                blurMax: 32
            }

            Component.onCompleted: {
                topTextEntry.start()
            }

            SequentialAnimation {
                id: topTextEntry
                PauseAnimation { duration: 200 }
                NumberAnimation { target: topBrandText; property: "opacity"; from: 0; to: 0.95; duration: 1200; easing.type: Easing.OutCubic }
            }
        }

        // ---- TOP RIGHT NAVIGATION ----
        Row {
            id: topMenu
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: isSmallScreen ? dp(4) : 40
            anchors.rightMargin: isSmallScreen ? dp(4) : 40
            spacing: isSmallScreen ? dp(2) : dp(4)
            z: 100

            // Profile
            Item {
                width: isSmallScreen ? dp(6) : dp(16)
                height: dp(6)
                
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: profileMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    border.color: profileMouse.containsMouse ? accent_color : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1.5)
                    Image {
                        Layout.preferredWidth: dp(2.8)
                        Layout.preferredHeight: dp(2.8)
                        source: "qrc:/qmlimages/NewImages/user_profile.svg"
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        text: qsTr("PROFILE")
                        color: "white"
                        visible: !isSmallScreen
                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                        font.bold: true
                        font.family: "Outfit"
                    }
                }

                MouseArea {
                    id: profileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { MapGlobals.currentView_profile = "profile"; mainWindow.openProfileScreen() }
                }
            }

            // Application
            Item {
                width: isSmallScreen ? dp(6) : dp(20)
                height: dp(6)
                
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: appMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    border.color: appMouse.containsMouse ? accent_color : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1.5)
                    Image {
                        Layout.preferredWidth: dp(2.8)
                        Layout.preferredHeight: dp(2.8)
                        source: "qrc:/qmlimages/NewImages/select_drone_type_color.svg"
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        text: qsTr("APPLICATION")
                        color: "white"
                        visible: !isSmallScreen
                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                        font.bold: true
                        font.family: "Outfit"
                    }
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { MapGlobals.currentView_profile = "drone"; mainWindow.openProfileScreen() }
                }
            }

            // Logout
            Item {
                width: isSmallScreen ? dp(6) : dp(16)
                height: dp(6)
                
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: logoutMouse.containsMouse ? Qt.rgba(255, 107, 107, 0.2) : Qt.rgba(255, 255, 255, 0.08)
                    border.color: logoutMouse.containsMouse ? "#FF6B6B" : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1.5)
                    Image {
                        Layout.preferredWidth: dp(2.8)
                        Layout.preferredHeight: dp(2.8)
                        source: "qrc:/qmlimages/NewImages/logout_color.svg"
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        text: qsTr("LOGOUT")
                        color: logoutMouse.containsMouse ? "#FF6B6B" : "white"
                        visible: !isSmallScreen
                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                        font.bold: true
                        font.family: "Outfit"
                    }
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { logoutdialog.createObject(mainWindow).open() }
                }
            }
        }

        // ---- HERO SECTION ----
        Column {
            id: heroSection
            // Conditional positioning: Center for the main tagline, Left for operational modes
            anchors.horizontalCenter: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri") ? undefined : parent.horizontalCenter
            anchors.left: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri") ? parent.left : undefined
            anchors.leftMargin: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri") ? ((isSmallScreen || isMobile) ? dp(5) : dp(15)) : 0
            anchors.verticalCenter: parent.verticalCenter
            
            width: {
                if (isSmallScreen || isMobile) return parent.width * 0.55 // Increased slightly to accommodate larger font
                return droneType === "loadpage" ? parent.width * 0.9 : Math.min(parent.width * 0.55, dp(160))
            }
            spacing: isSmallScreen ? dp(1) : dp(3)
            opacity: 1 
            z: 10

            // Main Title
            Label {
                id: heroTitle
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri") ? Text.AlignLeft : Text.AlignHCenter
                visible: droneType !== "loadpage" // Avoid duplicate "DRONE COMMANDER" on homescreen
                text: {
                    if (droneType === "Camera")  return "CAMERA OPERATIONS"
                    if (droneType === "Mapping") return "MAPPING & SURVEY"
                    if (droneType === "Agri")    return "AGRICULTURAL PRECISION"
                    return ""
                }
                color: "#FFFFFF"
                // Massive size for Drone Commander, slightly larger for others
                font.pointSize: {
                    var baseSize = ScreenTools.largeFontPointSize
                    var scaleMultiplier = dynamicScaleFactor
                    
                    if (droneType === "loadpage") {
                        if (isDesktop) return baseSize * 3.5 * scaleMultiplier
                        if (isTablet)  return baseSize * 3.0 * scaleMultiplier
                        return baseSize * 1.5
                    } else {
                        if (isDesktop) return baseSize * 1.8 * scaleMultiplier
                        if (isTablet)  return baseSize * 1.6 * scaleMultiplier
                        return baseSize * 0.95
                    }
                }
                font.bold: true
                font.family: "Outfit"
                font.letterSpacing: (droneType === "loadpage" && !isSmallScreen) ? 4 : 1.5
                lineHeight: 0.82

                // Glow/Shadow for text readability
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0,0,0,0.8)
                    shadowBlur: 0.3
                    shadowHorizontalOffset: 2
                    shadowVerticalOffset: 2
                }
            }

            // Expanded Subtitle / Description
            Label {
                id: heroSubtitle
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri") ? Text.AlignLeft : Text.AlignHCenter
                text: {
                    if (droneType === "Camera")  return "Master the sky with cinematic 4K streaming and precise gimbal control.\nCapture high-definition visuals for professional surveillance."
                    if (droneType === "Mapping") return "Industrial-grade photogrammetry and 3D terrain modeling.\nExecute automated flight missions to generate centimeter-level accuracy maps."
                    if (droneType === "Agri")    return "Smart farming through multispectral crop analysis and automated spraying.\nOptimize your yield with intelligent field coverage and health monitoring."
                    return "THE ADVANCED GROUND CONTROL STATION FOR ELITE DRONE MISSIONS"
                }
                color: Qt.rgba(255, 255, 255, 0.9)
                font.pointSize: {
                    var baseSize = ScreenTools.defaultFontPointSize
                    var scaleMultiplier = dynamicScaleFactor
                    
                    if (isDesktop) return baseSize * 1.2 * scaleMultiplier
                    if (isTablet)  return baseSize * 1.1 * scaleMultiplier
                    return baseSize * 0.8 // Mobile
                }
                font.family: "Outfit"
                font.italic: droneType === "loadpage"
                font.bold: false
                lineHeight: 1.3
                topPadding: dp(3)

                // Subtitle shadow
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0,0,0,0.6)
                    shadowBlur: 0.2
                    shadowVerticalOffset: 1
                }
            }
        }

        // ---- BOTTOM BUTTONS BAR ----
        RowLayout {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: dp(2)
            anchors.leftMargin: dp(4)
            anchors.rightMargin: dp(4)
            spacing: Math.min(dp(2), parent.width * 0.02)
            
            // Helpful for debugging or ensuring minimum space
            Layout.fillWidth: true

            // Cinematic Swipe to Connect Button
            Item {
                id: connectSwipe
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: dp(30)
                Layout.minimumWidth: dp(18)
                Layout.preferredHeight: dp(7)

                // Track
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1

                    // Directional Arrows
                    Row {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: dp(4)
                        spacing: dp(2)
                        opacity: 0.3
                        Repeater {
                            model: 3
                            Label { text: ">"; color: "white"; font.bold: true; font.pointSize: 10 }
                        }
                    }

                    // Glow background for the track
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        opacity: 0.1
                        border.color: accent_color
                        border.width: 2
                        visible: swipeMouse.pressed
                    }
                }

                // Drag Handle
                Rectangle {
                    id: swipeHandle
                    width: parent.height - dp(2)
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: dp(1)
                    color: accent_color

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: accent_color
                        shadowBlur: 0.8
                    }

                    Image {
                        source: "qrc:/qmlimages/NewImages/commlinks.svg"
                        width: parent.width * 0.5
                        height: width
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }

                    Behavior on x {
                        enabled: !swipeMouse.pressed
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }
                }

                MouseArea {
                    id: swipeMouse
                    anchors.fill: parent
                    drag.target: swipeHandle
                    drag.axis: Drag.XAxis
                    drag.minimumX: dp(1)
                    drag.maximumX: parent.width - swipeHandle.width - dp(1)

                    onReleased: {
                        if (swipeHandle.x >= drag.maximumX - dp(2)) {
                            var editingConfig = _linkManager.createConfiguration(
                                ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
                            );
                            typeSelectionDialogComponent.createObject(mainWindow1, { editingConfig: editingConfig, originalConfig: null }).open();
                            swipeHandle.x = drag.minimumX
                        } else {
                            swipeHandle.x = drag.minimumX
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Swipe to Camera
            Item {
                id: cameraSwipe
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: isSmallScreen ? dp(22) : dp(30)
                Layout.minimumWidth: dp(14)
                Layout.preferredHeight: isSmallScreen ? dp(6) : dp(7)
                visible: droneType === "loadpage" || droneType === "Camera"

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: dp(4)
                        spacing: dp(2)
                        opacity: 0.3
                        Repeater {
                            model: 3
                            Label { text: ">"; color: "white"; font.bold: true; font.pointSize: 10 }
                        }
                    }
                }

                Rectangle {
                    id: cameraHandle
                    width: parent.height - dp(2)
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: dp(1)
                    color: app_color

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: app_color
                        shadowBlur: 0.8
                    }

                    Image {
                        source: "qrc:/qmlimages/NewImages/camera_Application.svg"
                        width: parent.width * 0.5
                        height: width
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }

                    Behavior on x {
                        enabled: !cameraMouse.pressed
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }
                }

                MouseArea {
                    id: cameraMouse
                    anchors.fill: parent
                    drag.target: cameraHandle
                    drag.axis: Drag.XAxis
                    drag.minimumX: dp(1)
                    drag.maximumX: parent.width - cameraHandle.width - dp(1)

                    onReleased: {
                        if (cameraHandle.x >= drag.maximumX - dp(2)) {
                            QGroundControl.saveGlobalSetting("loadpage", "Camera")
                            MapGlobals.comefrom = "Camera"
                            mainWindow.cameraView()
                            QGroundControl.saveGlobalSetting("waypoint","waypoint")
                            var videoSettings = QGroundControl.settingsManager.videoSettings
                            if (videoSettings) {
                                var videoSourceFact = videoSettings.videoSource
                                if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                    videoSourceFact.value = videoSourceFact.enumValues[0]
                                }
                            }
                            swapCamera();
                            cameraHandle.x = drag.minimumX
                        } else {
                            cameraHandle.x = drag.minimumX
                        }
                    }
                }
            }

            // Swipe to Agri
            Item {
                id: agriSwipe
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: isSmallScreen ? dp(22) : dp(30)
                Layout.minimumWidth: isSmallScreen ? dp(14) : dp(18)
                Layout.preferredHeight: isSmallScreen ? dp(6) : dp(7)
                visible: droneType === "loadpage" || droneType === "Agri"

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: dp(4)
                        spacing: dp(2)
                        opacity: 0.3
                        Repeater {
                            model: 3
                            Label { text: ">"; color: "white"; font.bold: true; font.pointSize: 10 }
                        }
                    }
                }

                Rectangle {
                    id: agriHandle
                    width: parent.height - dp(2)
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: dp(1)
                    color: app_color

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: app_color
                        shadowBlur: 0.8
                    }

                    Image {
                        source: "qrc:/qmlimages/NewImages/agri_Application.svg"
                        width: parent.width * 0.5
                        height: width
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }

                    Behavior on x {
                        enabled: !agriMouse.pressed
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }
                }

                MouseArea {
                    id: agriMouse
                    anchors.fill: parent
                    drag.target: agriHandle
                    drag.axis: Drag.XAxis
                    drag.minimumX: dp(1)
                    drag.maximumX: parent.width - agriHandle.width - dp(1)

                    onReleased: {
                        if (agriHandle.x >= drag.maximumX - dp(2)) {
                            QGroundControl.saveGlobalSetting("loadpage", "Agri")
                            mainWindow.showFlyView()
                            MapGlobals.comefrom = "Plan"
                            _appSettings.screen = "Plan"
                            var videoSettings = QGroundControl.settingsManager.videoSettings
                            if (videoSettings) {
                                var videoSourceFact = videoSettings.videoSource
                                if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                    videoSourceFact.value = videoSourceFact.enumValues[0]
                                }
                            }
                            swapCamera();
                            agriHandle.x = drag.minimumX
                        } else {
                            agriHandle.x = drag.minimumX
                        }
                    }
                }
            }

            // Swipe to Mapping
            Item {
                id: mappingSwipe
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: isSmallScreen ? dp(22) : dp(30)
                Layout.minimumWidth: dp(14)
                Layout.preferredHeight: isSmallScreen ? dp(6) : dp(7)
                visible: droneType === "loadpage" || droneType === "Mapping"

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: dp(4)
                        spacing: dp(2)
                        opacity: 0.3
                        Repeater {
                            model: 3
                            Label { text: ">"; color: "white"; font.bold: true; font.pointSize: 10 }
                        }
                    }
                }

                Rectangle {
                    id: mappingHandle
                    width: parent.height - dp(2)
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: dp(1)
                    color: app_color

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: app_color
                        shadowBlur: 0.8
                    }

                    Image {
                        source: "qrc:/qmlimages/NewImages/mapping_Application.svg"
                        width: parent.width * 0.5
                        height: width
                        anchors.centerIn: parent
                        fillMode: Image.PreserveAspectFit
                    }

                    Behavior on x {
                        enabled: !mappingMouse.pressed
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }
                }

                MouseArea {
                    id: mappingMouse
                    anchors.fill: parent
                    drag.target: mappingHandle
                    drag.axis: Drag.XAxis
                    drag.minimumX: dp(1)
                    drag.maximumX: parent.width - mappingHandle.width - dp(1)

                    onReleased: {
                        if (mappingHandle.x >= drag.maximumX - dp(2)) {
                            QGroundControl.saveGlobalSetting("loadpage", "Mapping")
                            mainWindow.showMapping()
                            MapGlobals.comefrom = "Start"
                            _appSettings.screen = "Start"
                            var videoSettings = QGroundControl.settingsManager.videoSettings
                            if (videoSettings) {
                                var videoSourceFact = videoSettings.videoSource
                                if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                    videoSourceFact.value = videoSourceFact.enumValues[0]
                                }
                            }
                            swapCamera();
                            mappingHandle.x = drag.minimumX
                        } else {
                            mappingHandle.x = drag.minimumX
                        }
                    }
                }
            }
        }
    }

    // Logout Dialog Component
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
            title: qsTr("Select Connection Type")
            buttons: 0
            showButtons: false
            closeOnClickOutside: true

            property int selectedType: -1

            ColumnLayout {
                spacing: 16
                Layout.fillWidth: true
                Layout.minimumWidth: 420
                Layout.margins: 20

                Text {
                    text: qsTr("Choose how you want to connect to your drone from the options below.")
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.95
                    color: "black"
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    Layout.bottomMargin: 10
                }

                Repeater {
                    model: _linkManager.linkTypeStrings
                    delegate: Rectangle {
                        id: typeItem
                        property bool isDisabled: index === 4 || index === 5 
                        Layout.fillWidth: true
                        height: 70
                        radius: 12
                        color: isDisabled ? "#E0E0E0" : (typeMouseArea.containsMouse ? Qt.rgba(249/255, 115/255, 22/255, 0.1) : "#F8F9FA")
                        border.color: isDisabled ? "#D1D5DB" : (typeMouseArea.containsMouse ? accent_color : "#E5E7EB")
                        border.width: 1
                        opacity: isDisabled ? 0.5 : 1.0
                        Behavior on color { ColorAnimation { duration: 250 } }
                        Behavior on border.color { ColorAnimation { duration: 250 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 20

                            // Number / Icon Box
                            Rectangle {
                                width: 42
                                height: 42
                                radius: 10
                                color: isDisabled ? "#D1D5DB" : (typeMouseArea.containsMouse && !isDisabled ? accent_color : "#E5E7EB")
                                border.color: typeMouseArea.containsMouse && !isDisabled ? Qt.lighter(accent_color, 1.2) : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 250 } }

                                Text {
                                    anchors.centerIn: parent
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.2
                                    font.bold: true
                                    color: isDisabled ? "gray" : (typeMouseArea.containsMouse && !isDisabled ? "white" : "black")
                                    opacity: typeMouseArea.containsMouse && !isDisabled ? 1.0 : 0.8
                                    text: (index + 1)
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Connection Type Title
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.3
                                font.weight: Font.DemiBold
                                color: isDisabled ? "gray" : "black"
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }

                            // Arrow Indicator
                            Text {
                                text: "→"
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.8
                                font.bold: true
                                color: typeMouseArea.containsMouse && !isDisabled ? accent_color : "transparent"
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                        }

                        MouseArea {
                            id: typeMouseArea
                            anchors.fill: parent
                            hoverEnabled: !isDisabled
                            enabled: !isDisabled
                            cursorShape: isDisabled ? Qt.ForbiddenCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (isDisabled) return;
                                typeDialog.selectedType = index
                                typeDialog.close()
                                var editingConfig = _linkManager.createConfiguration(index, "")
                                linkConfigDialogComponent.createObject(mainWindow, {
                                                                           editingConfig: editingConfig,
                                                                           originalConfig: null,
                                                                           selectedType: index
                                                                       }).open()
                            }
                        }
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
                spacing: ScreenTools.defaultFontPixelHeight
                Layout.fillWidth: true
                Layout.minimumWidth: 400

                // ---- Name row (not shown for Bluetooth) ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"

                    QGCLabel { 
                        text: qsTr("Connection Name") 
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                        color: "black" // Enforce black color
                    }

                    TextField {
                        id:               nameField
                        Layout.fillWidth: true
                        text:             editingConfig.devName
                        placeholderText:  qsTr("e.g. My Custom Drone Connection")
                        
                        font.pointSize: ScreenTools.defaultFontPointSize
                        color: "black"
                        leftPadding: 16
                        rightPadding: 16
                        
                        background: Rectangle {
                            radius: 8
                            color: nameField.activeFocus ? "white" : "#F9FAFB"
                            border.color: nameField.activeFocus ? accent_color : "#D1D5DB"
                            border.width: nameField.activeFocus ? 2 : 1
                            implicitHeight: 44
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                // Divider line if not Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#E5E7EB"
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"
                }

                // ---- Device list / settings loader ----
                Loader {
                    id: linkSettingsLoader
                    Layout.fillWidth: true
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
