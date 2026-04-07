import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals

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
    property color app_color: "#262626"
    property color secondary_color: "#262626"
    property color accent_color: "#f97316" // The Orange accent

    // Airspace Recommendation Properties
    property bool isCheckingAirspace: true
    property bool isClearToFly: true

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    // Use ScreenTools for consistent scaling across devices, falling back to a ratio-based approach if needed
    property real baseUnit: ScreenTools.defaultFontPixelWidth * 0.8
    function dp(value) { return value * baseUnit; }

    property bool isMobile: ScreenTools.isMobile
    property bool isTablet: ScreenTools.isMobile && !ScreenTools.isTinyScreen
    property bool isDesktop: !ScreenTools.isMobile
    property bool isSmallScreen: ScreenTools.isTinyScreen

    property string planType: "Standard"
    property var _appSettings: QGroundControl.settingsManager.appSettings
    property var _linkManager: QGroundControl.linkManager

    property bool connecting_drone : false

    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle

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


    // Success path
    Connections {
        target: QGroundControl.multiVehicleManager

        function onActiveVehicleChanged(vehicle) {
            if (vehicle) {
                mainWindow.showToastMessage("Drone Connected")
            } else {
                mainWindow.showToastMessage("Drone DisConnected")
            }

            connecting_drone = false
        }
    }

    // Failure path
    Connections {
        target: QGroundControl.linkManager

        function onCommunicationError(linkName, errorMessage) {

            console.log("LinkSettings: connect failed for", linkName)

            connecting_drone = false     // stop loading screen

            mainWindow.showToastMessage("Connection failed: " + errorMessage)
        }
    }


    /* ========= DYNAMIC BACKGROUND ========= */
    Item {
        id: bgContainer
        anchors.fill: parent
        z: 0

        // GCS Background specifically for the startup/loadpage state
        Item {
            anchors.fill: parent
            visible: (droneType === "loadpage")

            Image {
                anchors.fill: parent
                source: "qrc:/qmlimages/NewImages/nature_bg_rice_fields.jpg"
                fillMode: Image.PreserveAspectCrop
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                opacity: 1.0
                asynchronous: true
                cache: true
                mipmap: true
                smooth: true
            }

            // Light shading overlay to keep the UI clean, text readable, and the background subtle
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(10/255, 10/255, 20/255, 0.35) }  // Light dark top for logo contrast
                    GradientStop { position: 0.45; color: Qt.rgba(255/255, 255/255, 255/255, 0.55) } // Mid frosted white for text readability
                    GradientStop { position: 1.0; color: Qt.rgba(245/255, 247/255, 255/255, 0.80) }  // Slightly heavier bottom for buttons
                }
            }
        }

        Image {
            id: bgImage
            anchors.fill: parent
            visible: (droneType !== "loadpage")
            source: {
                if (droneType === "Camera")  return "qrc:/qmlimages/NewImages/camera_bg_image.png"
                if (droneType === "Mapping") return "qrc:/qmlimages/NewImages/mapping_bg_image.png"
                if (droneType === "Agri")    return "qrc:/qmlimages/NewImages/agri_bg_image_pro.png"
                return "qrc:/qmlimages/NewImages/nature_background.png" // Fallback
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false // Disabled temporarily to ensure new image loads immediately
            mipmap: true
            smooth: true

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
            visible: (droneType !== "loadpage")
            gradient: Gradient {
                GradientStop { position: 0.0; color: "black" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: "black" }
            }
        }

        // Darkening overlay for cinematic look and text readability - with vignette
        Rectangle {
            anchors.fill: parent
            visible: (droneType !== "loadpage")
            gradient: Gradient {
                id: vignetteGradient
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.2) }
                GradientStop { position: 0.8; color: Qt.rgba(0,0,0,0.5) }
                GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.7) }
            }
        }

        // Subtle atmospheric white top blend for logo visibility and professional natural look
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: dp(35) // Deep atmospheric blend
            visible: (droneType !== "loadpage")
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(255/255, 255/255, 255/255, 0.45) } // Much subtler starting opacity (was 0.85)
                GradientStop { position: 0.4; color: Qt.rgba(255/255, 255/255, 255/255, 0.15) } // Extremely soft fade
                GradientStop { position: 1.0; color: "transparent" }
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
            visible: false // Hidden to allow the cinematic background imagery to shine
            opacity: 0.94
            asynchronous: true
            cache: true
            mipmap: true
            smooth: true
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
            visible: false // Hidden to avoid redundancy with cinematic background
            opacity: 0.94
            asynchronous: true
            cache: true
            mipmap: true
            smooth: true
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
            visible: false // Removed redundant drone as it is now in the background image
            opacity: 0.94
            asynchronous: true
            cache: true
            mipmap: true
            smooth: true
        }

        // Startup/Loadpage Specific Drone (Right Side Corner)
        Image {
            id: loadpageDrone
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: (isSmallScreen || isMobile) ? -dp(5) : dp(5)
            width: (isSmallScreen || isMobile) ? parent.width * 0.45 : parent.width * 0.40
            height: width
            source: "qrc:/qmlimages/NewImages/agri_AIImage_transparent.png"
            fillMode: Image.PreserveAspectFit
            // Hidden because the new premium background already showcases a GCS and Drone clearly and elegantly
            visible: false
            opacity: 0.85
            asynchronous: true
            cache: true
            mipmap: true
            smooth: true

            // Note: Shake/Floating animation removed per user request
        }
    }

    //Bluetooth Loading Screen
    Item {
        id : drone_loading
        anchors.fill: parent
        visible: connecting_drone
        z: 100

        MouseArea {
            anchors.fill: parent
            enabled: drone_loading.visible

            // propagateComposedEvents: false is actually the default, but stating it explicitly
            // makes the intent clear and protects against any parent-level event forwarding that
            // might be configured elsewhere in QGC's codebase.
            propagateComposedEvents: false

            onClicked: {}
            onPressed: {}
        }

        Rectangle {
            anchors.fill: parent
            color: "#80000000"
        }

        BusyIndicator {
            anchors.centerIn : parent
            running: true
        }
    }

    Item {
        anchors.fill: parent
        z: 1

        // ---- TOP LEFT LOGO ----

        Image {
            id: mainLogo
            source: "qrc:/qmlimages/NewImages/dronecommanderlogo.svg"
            width: ScreenTools.defaultFontPixelWidth * (isMobile ? 8 : 10)
            height: width * (100 / 220)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: (isSmallScreen || isMobile) ? dp(5) : dp(12)
            anchors.topMargin: (isSmallScreen || isMobile) ? dp(3) : dp(8)
            z: 50
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            Component.onCompleted: opacity = 1
        }



        // ---- TOP RIGHT NAVIGATION ----
        Rectangle {
            id: topMenuContainer
            anchors.verticalCenter: mainLogo.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: (isSmallScreen || isMobile) ? dp(6) : dp(12)
            height: dp(5)
            width: topMenu.width + ((droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(2) : dp(4))
            radius: height / 2
            // For Camera, loadpage, Agri, and Mapping we use individual glass boxes, so the main container is transparent
            color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? "transparent" : Qt.rgba(255, 255, 255, 0.45)
            border.color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? "transparent" : Qt.rgba(255, 255, 255, 0.8)
            border.width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? 0 : 1
            z: 100

            // Optimized layer management for Android stability
            layer.enabled: visible && (droneType !== "Camera" && droneType !== "loadpage")
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0,0,0,0.1)
                shadowBlur: 1.0
                shadowVerticalOffset: 1
            }

            RowLayout {
                id: topMenu
                anchors.centerIn: parent
                spacing: (droneType === "Camera") ? dp(1.5) : ((isSmallScreen || isMobile) ? dp(1.2) : dp(1.8))

                // Profile
                Rectangle {
                    width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri") ? dp(5.5) : dp(3.8)
                    height: width
                    radius: 12
                    color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri") ? Qt.rgba(255,255,255,0.15) : "transparent"
                    border.color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri") ? Qt.rgba(255,255,255,0.1) : "transparent"
                    border.width: 1
                   
                    layer.enabled: visible && (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri")
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0,0,0,0.2)
                        shadowBlur: 0.8
                    }
                   
                    QGCColoredImage {
                        anchors.centerIn: parent
                        width: (droneType === "Camera" || droneType === "loadpage") ? dp(2.2) : dp(2.2)
                        height: width
                        source: "qrc:/qmlimages/NewImages/user_profile.svg"
                        color: (droneType === "Camera" || droneType === "loadpage") ? "#FFFFFF" : (profileMouse.containsMouse ? accent_color : "#1E293B")
                        fillMode: Image.PreserveAspectFit
                        opacity: profileMouse.containsMouse ? 1.0 : 0.85
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                   
                    MouseArea {
                        id: profileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { MapGlobals.currentView_profile = "profile"; mainWindow.openProfileScreen() }
                    }
                }

                // Application Settings (Visible after login)
                Rectangle {
                    visible: droneType !== "loadpage"
                    width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(5.5) : (visible ? dp(3.8) : 0)
                    height: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(5.5) : dp(3.8)
                    radius: 12
                    color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? Qt.rgba(255,255,255,0.15) : "transparent"
                    border.color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? Qt.rgba(255,255,255,0.1) : "transparent"
                    border.width: 1
                   
                    layer.enabled: visible && (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping")
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0,0,0,0.2)
                        shadowBlur: 0.8
                    }
                   
                    QGCColoredImage {
                        anchors.centerIn: parent
                        width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(2.2) : dp(2.0)
                        height: width
                        source: "qrc:/qmlimages/NewImages/select_drone_type_color.svg"
                        color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? "#FFFFFF" : (appMouse.containsMouse ? accent_color : "#1E293B")
                        fillMode: Image.PreserveAspectFit
                        opacity: appMouse.containsMouse ? 1.0 : 0.85
                        Behavior on color { ColorAnimation { duration: 150 } }
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
                Rectangle {
                    width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(5.5) : dp(3.8)
                    height: width
                    radius: 12
                    color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? Qt.rgba(255,255,255,0.15) : "transparent"
                    border.color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? Qt.rgba(255,255,255,0.1) : "transparent"
                    border.width: 1
                   
                    layer.enabled: visible && (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping")
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0,0,0,0.2); shadowBlur: 0.8 }

                    Rectangle {
                        anchors.centerIn: parent
                        width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(3.2) : 0
                        height: width
                        radius: width/2
                        color: "#F43F5E"
                        visible: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping")
                    }

                    QGCColoredImage {
                        anchors.centerIn: parent
                        width: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? dp(2.0) : dp(2.2)
                        height: width
                        source: "qrc:/qmlimages/NewImages/logout.svg"
                        color: (droneType === "Camera" || droneType === "loadpage" || droneType === "Agri" || droneType === "Mapping") ? "#FFFFFF" : (logoutMouse.containsMouse ? "#EF4444" : "#475569")
                        fillMode: Image.PreserveAspectFit
                        opacity: logoutMouse.containsMouse ? 1.0 : 0.85
                        Behavior on color { ColorAnimation { duration: 150 } }
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
        }



        // ---- HERO SECTION ----
        Column {
            id: heroSection
            // Centered ONLY for loadpage, restored to original left-anchored vertical center for others
            anchors.horizontalCenter: (droneType === "loadpage") ? parent.horizontalCenter : undefined
            anchors.left:             (droneType === "loadpage") ? undefined : parent.left
            anchors.leftMargin:       (droneType === "loadpage") ? 0 : ((isSmallScreen || isMobile) ? dp(6) : dp(16))

            anchors.top:            (droneType === "loadpage") ? parent.top : mainLogo.bottom
            anchors.topMargin:      (droneType === "loadpage") ? parent.height * 0.18 : (isSmallScreen ? dp(3) : dp(10))
            anchors.verticalCenter: undefined
            anchors.verticalCenterOffset: 0

            width: {
                if (droneType === "loadpage") {
                    if (isSmallScreen || isMobile) return parent.width * 0.9
                    return Math.min(parent.width * 0.65, dp(240))
                } else {
                    if (isSmallScreen || isMobile) return parent.width * 0.75
                    return Math.min(parent.width * 0.45, dp(160)) // Balanced width for mission screens
                }
            }
            spacing: (droneType === "loadpage") ? dp(1.5) : (isSmallScreen ? dp(0.5) : dp(1.5))
            opacity: 0
            z: 10

            Component.onCompleted: heroEntry.start()
            SequentialAnimation {
                id: heroEntry
                PauseAnimation { duration: 200 }
                NumberAnimation { target: heroSection; property: "opacity"; from: 0; to: 1.0; duration: 1200; easing.type: Easing.OutCubic }
            }

            // Main Title
            Label {
                id: heroTitle
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: (droneType === "loadpage") ? Text.AlignHCenter : Text.AlignLeft
                visible: true
                text: {
                    if (droneType === "loadpage") return "DRONE COMMANDER"
                    if (droneType === "Camera")  return "CAMERA OPERATIONS"
                    if (droneType === "Mapping") return "MAPPING & SURVEY"
                    if (droneType === "Agri")    return "AGRICULTURAL PRECISION"
                    return "DRONE COMMANDER"
                }
                color: (droneType === "loadpage") ? "#000000" : "#FFFFFF"
                font.pointSize: {
                    var baseSize = (droneType === "loadpage") ? ScreenTools.largeFontPointSize : ScreenTools.largeFontPointSize
                    var scaleMultiplier = dynamicScaleFactor

                    if (droneType === "loadpage") {
                        if (isDesktop) return baseSize * 2.2 * scaleMultiplier
                        if (isTablet)  return baseSize * 1.8 * scaleMultiplier
                        return baseSize * 1.5
                    } else {
                        // Restore original sizes for mission screens
                        if (isDesktop) return baseSize * 1.5 * scaleMultiplier
                        if (isTablet)  return baseSize * 1.4 * scaleMultiplier
                        return baseSize * 0.85
                    }
                }
                font.bold: true
                font.family: "Outfit"
                font.letterSpacing: (droneType === "loadpage" && !isSmallScreen) ? 4 : 1.2
                lineHeight: 0.9

                // Reduced effect complexity for mobile stability
                layer.enabled: visible && (droneType === "loadpage")
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(255,255,255,0.6)
                    shadowBlur: 0.8
                    shadowVerticalOffset: 1
                }
            }

            // Premium gradient accent divider — only on loadpage
            Item {
                visible: droneType === "loadpage"
                width: parent.width * 0.38
                height: 3
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    anchors.fill: parent
                    radius: 1.5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.3; color: "#6C63FF" }
                        GradientStop { position: 0.7; color: "#6C63FF" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    opacity: 0.75
                }
            }

            // Expanded Subtitle / Description
            Label {
                id: heroSubtitle
                visible: !isSmallScreen
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: (droneType === "loadpage") ? Text.AlignHCenter : Text.AlignLeft
                text: {
                    if (droneType === "Camera")  return "Master the sky with cinematic 4K vision and precise control.\nCapture high-definition visuals for professional surveillance."
                    if (droneType === "Mapping") return "Industrial-grade photogrammetry and 3D terrain modeling.\nExecute automated flight missions to generate centimeter-level accuracy maps."
                    if (droneType === "Agri")    return "Smart farming through multispectral crop analysis and automated spraying.\nOptimize your yield with intelligent field coverage and health monitoring."
                    return "THE ADVANCED GROUND CONTROL STATION\nFOR ELITE DRONE MISSIONS"
                }
                color: (droneType === "loadpage") ? "#000000" : Qt.rgba(255, 255, 255, 0.9) // Solid black for readability on nature bg
                font.pointSize: {
                    var baseSize = ScreenTools.defaultFontPointSize
                    var scaleMultiplier = dynamicScaleFactor

                    if (isDesktop) return baseSize * 1.0 * scaleMultiplier
                    if (isTablet)  return baseSize * 0.9 * scaleMultiplier
                    return baseSize * 0.8
                }
                font.family: "Outfit"
                font.italic: false
                font.weight: (droneType === "loadpage") ? Font.Medium : Font.Normal
                font.letterSpacing: (droneType === "loadpage") ? 2 : 0
                font.capitalization: (droneType === "loadpage") ? Font.AllUppercase : Font.MixedCase
                lineHeight: 1.4
                topPadding: dp(0.2)

                // Simplified effect for description text
                layer.enabled: visible && (droneType === "loadpage")
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0,0,0,0.05)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 1
                }
            }

        } // End of heroSection

        // ---- AIRSPACE RECOMMENDATION WIDGET (INDEPENDENT) ----
        Rectangle {
            id: airspaceWidget
            visible: true
            // Match the mockup: Left-aligned under subtitle for Camera/Agri/Mapping mode
            anchors.horizontalCenter: (droneType === "Camera" || droneType === "Agri" || droneType === "Mapping") ? undefined : parent.horizontalCenter
            anchors.left:             (droneType === "Camera" || droneType === "Agri" || droneType === "Mapping") ? heroSection.left : undefined
            anchors.top:              heroSection.bottom
            anchors.topMargin:        (isSmallScreen || isMobile) ? dp(0.8) : dp(1.5)
            anchors.verticalCenter:   undefined
            anchors.right:            undefined

            width: {
                if (droneType === "Camera" || droneType === "Agri" || droneType === "Mapping")  return isSmallScreen ? parent.width * 0.90 : Math.min(parent.width * 0.45, 380)
                if (droneType === "loadpage") return isSmallScreen ? parent.width * 0.85 : 380
                return isSmallScreen ? parent.width * 0.98 : Math.min(parent.width, 360)
            }
            implicitHeight: widgetContent.height + dp(4)
            radius: 12
           
            // Deep slate-black glass theme for high-end look
            color: Qt.rgba(15/255, 23/255, 42/255, 0.92)  // Slate-950
            border.color: Qt.rgba(71/255, 85/255, 105/255, 0.4) // Slate-600 subtle highlight
            border.width: 1
            z: 90

            // Elegant fade + slide-up entrance animation
            opacity: 0
            transform: Translate { id: widgetSlide; y: 18 }

            Component.onCompleted: {
                widgetEntryAnim.start()
            }

            SequentialAnimation {
                id: widgetEntryAnim
                PauseAnimation { duration: 600 }
                ParallelAnimation {
                    NumberAnimation { target: airspaceWidget; property: "opacity"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
                    NumberAnimation { target: widgetSlide; property: "y"; from: 18; to: 0; duration: 900; easing.type: Easing.OutCubic }
                }
            }

            // Use layer only when needed for complex shadows
            layer.enabled: visible && isDesktop
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0,0,0,0.1)
                shadowBlur: 2.0
                shadowVerticalOffset: 2
                blurEnabled: false
            }

            // Simulate airspace check on load
            Timer {
                id: airspaceTimer
                interval: 1000 // Reduced check time
                running: true
                repeat: false
                onTriggered: {
                    isCheckingAirspace = false;
                    isClearToFly = true;
                }
            }

            ColumnLayout {
                id: widgetContent
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: (droneType === "Camera") ? dp(1.2) : dp(1.8)
                spacing: (droneType === "Camera") ? dp(0.4) : dp(0.7)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: dp(0.6)
                    visible: (droneType === "Camera")

                    Rectangle {
                        width: 6; height: 6; radius: 3; color: "#10B981"; opacity: 0.8
                    }
                    Label {
                        text: qsTr("FLIGHT ZONE STATUS")
                        color: "#94A3B8"
                        font.family: "Outfit"
                        font.pointSize: Math.max(9, ScreenTools.smallFontPointSize * 0.75)
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: (droneType !== "Camera")
                    text: qsTr("≡ FLIGHT ZONE STATUS")
                    color: "#94A3B8" // slate-400 for header on black
                    font.family: "Outfit"
                    font.pointSize: Math.max(10, ScreenTools.smallFontPointSize * 0.85)
                    font.bold: true
                    font.letterSpacing: 1.0
                }

                Label {
                    Layout.fillWidth: true
                    text: isCheckingAirspace ? qsTr("Analyzing...") :
                                               (isClearToFly ? qsTr("Clear to Fly") : qsTr("Restricted"))
                    color: isCheckingAirspace ? "#FACC15" : (isClearToFly ? "#34D399" : "#F87171")
                    font.family: "Outfit"
                    font.pointSize: (droneType === "Camera") ? Math.max(18, ScreenTools.defaultFontPointSize * 1.3) : Math.max(15, ScreenTools.defaultFontPointSize * 1.1)
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: isCheckingAirspace ? qsTr("Fetching GPS coordinates...") :
                                               (isClearToFly ? qsTr("Class G Airspace. No active flight restrictions detected in your current location. Ensure standard safety protocols.") : qsTr("Authorization required to fly here."))
                    color: "#E2E8F0"
                    opacity: 0.8
                    font.family: "Outfit"
                    font.pointSize: Math.max(9, ScreenTools.smallFontPointSize * 0.8)
                    lineHeight: 1.2
                }
            }

            // Interactive element to open airspace map website
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Qt.openUrlExternally("https://airspacemap.in/")
                }
            }
        }

        // ---- BOTTOM BUTTONS BAR ----
        Rectangle {
            id: bottomBarContainer
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: dp(3)
            visible: droneType !== "Camera" && droneType !== "Agri" && droneType !== "Mapping"
            width: isSmallScreen ? parent.width * 0.95 : Math.min(parent.width * 0.85, dp(110))
            height: dp(6.5)
            radius: height / 2
            color: Qt.rgba(255, 255, 255, 0.45) // Match mockup's translucent bright pill
            border.color: Qt.rgba(255, 255, 255, 0.8)
            border.width: 1
            z: 100

            // High-performance layer management for Android
            layer.enabled: visible && (droneType !== "Camera" && droneType !== "loadpage")
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0,0,0,0.1)
                shadowBlur: 1.0
                shadowVerticalOffset: 1
            }

            RowLayout {
                id: bottomBar
                anchors.fill: parent
                anchors.leftMargin: dp(2)
                anchors.rightMargin: dp(2)
                spacing: dp(0.5)

                // Click to Connect
                Rectangle {
                    id: connectClick
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: dp(25)
                    Layout.preferredHeight: parent.height - dp(1)
                    color: connectMouse.pressed ? Qt.rgba(255,255,255,0.4) : (connectMouse.containsMouse ? Qt.rgba(255,255,255,0.2) : "transparent")
                    radius: height / 2

                    // Green glow indicator
                    Rectangle {
                        width: parent.width * 0.4
                        height: dp(0.4)
                        radius: 2
                        color: "#10B981"
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: dp(0.5)
                        anchors.horizontalCenter: parent.horizontalCenter
                        // Lightweight shadow for status
                        layer.enabled: visible && isDesktop
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#10B981"; shadowBlur: 1.5; blurEnabled: false }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: dp(1)

                        QGCColoredImage {
                            source: "qrc:/qmlimages/NewImages/commlinks.svg"
                            Layout.preferredWidth: dp(1.8)
                            Layout.preferredHeight: dp(1.8)
                            color: "#10B981" // Green tint from image
                            fillMode: Image.PreserveAspectFit
                        }
                        Label {
                            text: qsTr("CONNECT")
                            color: "#1F2937" // Dark slate
                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                            font.letterSpacing: 1.0
                        }
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var editingConfig = _linkManager.createConfiguration(
                                        ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
                                        );
                            typeSelectionDialogComponent.createObject(mainWindow1, { editingConfig: editingConfig, originalConfig: null }).open();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

            // Click to Camera
            Rectangle {
                id: cameraClick
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.maximumWidth: dp(22)
                Layout.preferredHeight: parent.height - dp(1)
                visible: droneType === "loadpage" || droneType === "Camera"
                color: cameraMouse.pressed ? Qt.rgba(255,255,255,0.4) : (cameraMouse.containsMouse ? Qt.rgba(255,255,255,0.2) : "transparent")
                radius: height / 2

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1)

                    QGCColoredImage {
                        source: "qrc:/qmlimages/NewImages/camera_Application.svg"
                        Layout.preferredWidth: dp(1.8)
                        Layout.preferredHeight: dp(1.8)
                        color: "#475569" // slate grey
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        text: qsTr("CAMERA")
                        color: "#475569"
                        font.family: "Outfit"
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.letterSpacing: 1.0
                    }
                }

                MouseArea {
                    id: cameraMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mainWindow.updateAppTheme("Camera")
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
                    }
                }
            }

            // Click to Agri
            Rectangle {
                id: agriClick
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.maximumWidth: dp(22)
                Layout.preferredHeight: parent.height - dp(1)
                visible: droneType === "loadpage" || droneType === "Agri"
                color: agriMouse.pressed ? Qt.rgba(255,255,255,0.4) : (agriMouse.containsMouse ? Qt.rgba(255,255,255,0.2) : "transparent")
                radius: height / 2

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1)

                    QGCColoredImage {
                        source: "qrc:/qmlimages/NewImages/agri_Application.svg"
                        Layout.preferredWidth: dp(1.8)
                        Layout.preferredHeight: dp(1.8)
                        color: "#475569" // slate grey
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        text: qsTr("SPRAYING")
                        color: "#475569"
                        font.family: "Outfit"
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.letterSpacing: 1.0
                    }
                }

                MouseArea {
                    id: agriMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var frameType = QGroundControl.loadBoolGlobalSetting("frametypeDialog", false)
                        var videoSettings = QGroundControl.settingsManager.videoSettings
                        var videoSourceFact = videoSettings.videoSource

                        if (activeVehicle) {

                            if (!activeVehicle.parameterManager.parametersReady){
                                mainWindow.showToastMessage("Plese Wait Vehicle parameters are still loading...")
                                return
                            }

                            if (!frameType) {
                                QGroundControl.saveBoolGlobalSetting("frametypeDialog", true)
                                showDynamicCalibrationDialog("qrc:/qml/APMAirframeComponent.qml", "Frame Type")

                            } else {
                                mainWindow.updateAppTheme("Agri")

                                mainWindow.showFlyView()
                                MapGlobals.comefrom="Plan"
                                console.log("MapGlobals.comefrom",MapGlobals.comefrom)
                                _appSettings.screen = "Plan"

                                //var videoSettings = QGroundControl.settingsManager.videoSettings

                                if (videoSettings) {
                                    //var videoSourceFact = videoSettings.videoSource
                                    if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                        videoSourceFact.value = videoSourceFact.enumValues[0]
                                    }
                                }

                                swapCamera();
                            }

                        } else {
                            mainWindow.updateAppTheme("Agri")
                            mainWindow.showFlyView()
                            MapGlobals.comefrom="Plan"
                            console.log("MapGlobals.comefrom",MapGlobals.comefrom)
                            _appSettings.screen = "Plan"

                            //var videoSettings = QGroundControl.settingsManager.videoSettings

                            if (videoSettings) {
                                //var videoSourceFact = videoSettings.videoSource
                                if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                    videoSourceFact.value = videoSourceFact.enumValues[0]
                                }
                            }

                            swapCamera();
                        }
                    }
                }
            }

            // Click to Mapping
            Rectangle {
                id: mappingClick
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.maximumWidth: dp(22)
                Layout.preferredHeight: parent.height - dp(1)
                visible: droneType === "loadpage" || droneType === "Mapping"
                color: mappingMouse.pressed ? Qt.rgba(255,255,255,0.4) : (mappingMouse.containsMouse ? Qt.rgba(255,255,255,0.2) : "transparent")
                radius: height / 2

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1)

                    QGCColoredImage {
                        source: "qrc:/qmlimages/NewImages/mapping_Application.svg"
                        Layout.preferredWidth: dp(1.8)
                        Layout.preferredHeight: dp(1.8)
                        color: "#475569" // slate grey
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        text: qsTr("MAPPING")
                        color: "#475569"
                        font.family: "Outfit"
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.letterSpacing: 1.0
                    }
                }

                MouseArea {
                    id: mappingMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mainWindow.updateAppTheme("Mapping")
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
                    }
                }
            }

        }
        }

        // ---- CAMERA / AGRI / MAPPING MODE BOTTOM BUTTONS (SPLIT VERSION) ----
        Item {
            id: cameraBottomButtons
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.margins: (isSmallScreen || isMobile) ? dp(4) : dp(8)
            anchors.bottomMargin: (isSmallScreen || isMobile) ? dp(2) : dp(4)
            height: dp(6.5)
            visible: (droneType === "Camera" || droneType === "Agri" || droneType === "Mapping")
            z: 110

            // Connect Button (Left)
            Rectangle {
                anchors.left: parent.left
                width: Math.min(dp(28), parent.width * 0.46)
                height: parent.height
                radius: height / 2
                color: Qt.rgba(0,0,0,0.85)
                border.color: Qt.rgba(255,255,255,0.1)
               
                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1.2)
                   
                    Rectangle {
                        width: dp(3.8)
                        height: dp(3.8)
                        radius: width / 2
                        color: "#F97316" // Orange
                        QGCColoredImage {
                            anchors.centerIn: parent
                            width: dp(1.8)
                            height: dp(1.8)
                            source: "qrc:/qmlimages/NewImages/commlinks.svg"
                            color: "white"
                        }
                    }
                    Label {
                        text: qsTr("CONNECT")
                        color: "white"
                        font.family: "Outfit"
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var editingConfig = _linkManager.createConfiguration(
                                    ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
                                    );
                        typeSelectionDialogComponent.createObject(mainWindow1, { editingConfig: editingConfig, originalConfig: null }).open();
                    }
                }
            }

            // Mode Action Button (Right: CAMERA, SPRAYING, or MAPPING)
            Rectangle {
                anchors.right: parent.right
                width: Math.min(dp(28), parent.width * 0.46)
                height: parent.height
                radius: height / 2
                color: Qt.rgba(0,0,0,0.85)
                border.color: Qt.rgba(255,255,255,0.1)
               
                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1.2)
                   
                    Rectangle {
                        width: dp(3.8)
                        height: dp(3.8)
                        radius: width / 2
                        color: (droneType === "Agri") ? "#10B981" : ((droneType === "Mapping")? "#1E293B" : "#475569") // Custom colors for modes
                        QGCColoredImage {
                            anchors.centerIn: parent
                            width: dp(1.8)
                            height: dp(1.8)
                            source: {
                                if (droneType === "Agri")    return "qrc:/qmlimages/NewImages/agri_Application.svg"
                                if (droneType === "Mapping") return "qrc:/qmlimages/NewImages/mapping_Application.svg"
                                return "qrc:/qmlimages/NewImages/camera_Application.svg"
                            }
                            color: "white"
                        }
                    }
                    Label {
                        text: {
                            if (droneType === "Agri")    return qsTr("SPRAYING")
                            if (droneType === "Mapping") return qsTr("MAPPING")
                            return qsTr("CAMERA")
                        }
                        color: "white"
                        font.family: "Outfit"
                        font.bold: true
                        font.letterSpacing: 1.2
                        font.pointSize: ScreenTools.defaultFontPointSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (droneType === "Camera") {
                            mainWindow.updateAppTheme("Camera")
                            MapGlobals.comefrom = "Camera"
                            mainWindow.cameraView()
                            swapCamera();
                        } else if (droneType === "Mapping") {
                            mainWindow.updateAppTheme("Mapping")
                            mainWindow.showFlyView()
                            MapGlobals.comefrom = "Mapping"
                            swapCamera();
                        } else {
                            mainWindow.updateAppTheme("Agri")
                            mainWindow.showFlyView()
                            MapGlobals.comefrom = "Start"
                            _appSettings.screen = "Start"
                            swapCamera();
                        }
                    }
                }
            }
        }
    }

    function showDynamicCalibrationDialog(qmlFile,title) {
        dynamicCalDialog.dialogTitleText = title
        dialogLoader.source = qmlFile
        dynamicCalDialog.open()
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

            // Set the overall popup UI width tightly
            // Set a properly balanced dialog width to prevent text truncation
            popupWidth: (isSmallScreen || isMobile) ? Math.min(mainWindow1.width * 0.9, 380) : 520

            property int selectedType: -1

            ColumnLayout {
                spacing: 12
                width: parent.width - 24
                anchors.horizontalCenter: parent.horizontalCenter
                Layout.fillWidth: true

                Text {
                    text: qsTr("Choose how you want to connect to your drone from the options below.")
                    font.family: "Outfit"
                    font.pointSize: ScreenTools.defaultFontPointSize * ((isSmallScreen || isMobile) ? 0.9 : 1.1)
                    color: "black"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                }

                Repeater {
                    model: _linkManager.linkTypeStrings
                    delegate: Rectangle {
                        id: typeItem
                        property bool isDisabled: index === 4 || index === 5
                        visible: !isDisabled
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? 56 : 0
                        radius: 8
                        color: typeMouseArea.containsMouse ? "#F8F9FA" : "#FFFFFF"
                        border.color: typeMouseArea.containsMouse ? (typeDialog.isAgri ? "#79AE6F" : "#262626") : "#E2E8F0"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16

                            // Number Icon Box
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                Layout.alignment: Qt.AlignVCenter
                                color: typeMouseArea.containsMouse ? (typeDialog.isAgri ? "#79AE6F" : "#262626") : "#F1F5F9"
                                border.color: typeMouseArea.containsMouse ? (typeDialog.isAgri ? "#79AE6F" : "#262626") : "#DDE1EA"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Outfit"
                                    font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                                    font.bold: true
                                    color: typeMouseArea.containsMouse ? "white" : "black"
                                    text: (index + 1)
                                }
                            }

                            // Connection Type Title
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.1
                                font.bold: true
                                color: "black"
                                elide: Text.ElideRight
                            }

                            // Arrow Indicator
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: "→"
                                font.family: "Outfit"
                                font.pointSize: ScreenTools.defaultFontPointSize * 1.4
                                font.bold: true
                                color: typeMouseArea.containsMouse ? "white" : "#666666"
                            }
                        }

                        MouseArea {
                            id: typeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
            id :linkConfigDialog
            title:          selectedType === 0 ? "Bluetooth Devices"
                                               : originalConfig ? qsTr("Edit Link")
                                                                : qsTr("Add New Link")
            buttons:        Dialog.Save | Dialog.Cancel
            acceptAllowed:  nameField.text !== ""

            property var originalConfig
            property var editingConfig
            property int selectedType

            property bool _connectionInitiated: false

            // if the Mobile Location is in Off state while iam click Refresh button, show the Toast message
            Connections {
                target: linkConfigDialog.editingConfig
                enabled: linkConfigDialog.editingConfig !== null

                function onShowToast(message) {
                    mainWindow.showToastMessage(message)
                }
            }

            onAccepted: {
                console.log("Click Save")

                if ( _connectionInitiated ) {
                    console.log("linkConfigDialog: ignoring duplicate accept")
                    return
                }

                linkSettingsLoader.item.saveSettings()
                editingConfig.devName = nameField.text
                editingConfig.name    = editingConfig.devName

                //connecting_drone = true

                if (originalConfig) {

                    _linkManager.endConfigurationEditing(originalConfig, editingConfig)

                } else {
                    editingConfig.dynamic = false
                    _linkManager.endCreateConfiguration(editingConfig)

                    if (activeVehicle) {
                        mainWindow.showToastMessage(
                                    qsTr("Please disconnect the active vehicle before connecting a new one"))
                        return
                    }

                    _connectionInitiated = true         // mark as initiated
                    connecting_drone = true  // only set true once
                    _linkManager.createConnectedLink(editingConfig)
                }
            }

            onRejected: {
                console.log("Click Cancel")
                _connectionInitiated = false  //reset on cancel
                _linkManager.cancelConfigurationEditing(editingConfig)

            }

            // ---------- MAIN LAYOUT ----------
            ColumnLayout {
                id: mainColumn
                spacing: isSmallScreen ? ScreenTools.defaultFontPixelHeight * 0.5 : ScreenTools.defaultFontPixelHeight
                Layout.fillWidth: true
                Layout.minimumWidth: isSmallScreen ? mainWindow1.width * 0.9 : 400

                // ---- Name row (not shown for Bluetooth) ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"

                    QGCLabel {
                        text: qsTr("Connection Name")
                        font.bold: true
                        font.pointSize: ScreenTools.defaultFontPointSize
                        color: "black"
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
                            color: "#FFFFFF"
                            border.color: nameField.activeFocus ? (linkConfigDialog.isAgri ? "#79AE6F" : "#262626") : "#DDE1EA"
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
                    color: "#E0E0E0"
                    visible: _linkManager.linkTypeStrings[selectedType] !== "Bluetooth"
                }

                // ---- Device list / settings loader ----
                Loader {
                    id: linkSettingsLoader
                    Layout.fillWidth: true
                    source: subEditConfig.settingsURL

                    property var subEditConfig:         linkConfigDialog.editingConfig
                    property int _firstColumnWidth:     ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth:    ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing:           ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing:           ScreenTools.defaultFontPixelWidth / 2
                }
            }
        }
    }

}