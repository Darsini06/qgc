import QtQuick
import QtQuick.Controls
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
import QtQuick.Layouts

import QtQuick.Effects

Item {
    id: mainWindow1
    anchors.fill: parent
    // minimumWidth: ScreenTools.isMobile ? ScreenTools.screenWidth : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    // minimumHeight: ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    // visible: true
    property var item1: null    // Required
    property var item2: null    // Optional, may come and go
    property var _fullItem
    property var _pipOrWindowItem

    property string droneType: QGroundControl.loadGlobalSetting("loadpage", "loadpage")
    property color app_color: "#262626"
    property color secondary_color: "#262626"
    property color accent_color: "#f97316" // The Orange accent

    // Airspace Recommendation Properties
    property bool isCheckingAirspace: true
    property bool _airspaceChecked: false
    property bool isClearToFly: true

    property real screenWidth: parent.width
    property real screenHeight: parent.height
    // Use ScreenTools for consistent scaling across devices, falling back to a ratio-based approach if needed
    property real baseUnit: ScreenTools.defaultFontPixelWidth * 0.8
    function dp(value) {
        return value * baseUnit;
    }

    property bool isMobile: ScreenTools.isMobile
    property bool isTablet: ScreenTools.isMobile && !ScreenTools.isTinyScreen
    property bool isDesktop: !ScreenTools.isMobile
    property bool isSmallScreen: ScreenTools.isTinyScreen

    property string planType: "Standard"
    property var _appSettings: QGroundControl.settingsManager.appSettings
    property var _linkManager: QGroundControl.linkManager

    property bool connecting_drone: false
    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    // DYNAMIC SCALING: Professional responsive multiplier
    property real dynamicScaleFactor: {
        var baseWidth = 1200;
        var scale = parent.width / baseWidth;
        if (isSmallScreen)
            return Math.max(0.7, scale * 1.2);
        if (isTablet)
            return Math.max(0.9, scale * 1.1);
        return Math.max(1.0, scale);
    }

    onVisibleChanged: {
        if (visible) {
            console.log("HomeScreen onVisibleChanged");
            droneType = QGroundControl.loadGlobalSetting("loadpage", "loadpage");
            console.log("droneType", droneType);
        }
    }

    function swapCamera() {
        var videoSettings = QGroundControl.settingsManager.videoSettings;
        if (videoSettings) {
            var videoSourceFact = videoSettings.videoSource;
            if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                videoSourceFact.value = videoSourceFact.enumValues[1];
            }
        }
    }

    // Success path
    Connections {
        target: QGroundControl.multiVehicleManager

        function onActiveVehicleChanged(vehicle) {
            if (vehicle) {
                mainWindow.showToastMessage("Drone Connected");
            } else {
                mainWindow.showToastMessage("Drone DisConnected");
            }
            connecting_drone = false;
        }
    }

    // Failure path
    Connections {
        target: QGroundControl.linkManager

        function onCommunicationError(linkName, errorMessage) {
            console.log("LinkSettings: connect failed for", linkName);
            connecting_drone = false;     // stop loading screen

            mainWindow.showToastMessage("Connection failed: " + errorMessage);
        }
    }

    /* ========= DYNAMIC BACKGROUND ========= */
    Item {
        id: bgContainer
        anchors.fill: parent
        z: 0

        // Grey Gradient background removed in favor of professional_landing_bg.png
        Rectangle {
            anchors.fill: parent
            visible: false
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#E0E0E0"
                } // Light grey top
                GradientStop {
                    position: 1.0
                    color: "#EDEEF4"
                } // Standard background grey bottom
            }
        }

        Image {
            id: bgImage
            anchors.fill: parent
            visible: true
            source: {

                if (droneType === "Camera")  return "qrc:/qmlimages/NewImages/camera_bg_image.png"
                if (droneType === "Mapping") return "qrc:/qmlimages/NewImages/mapping_bg_image.png"
                if (droneType === "Agri")    return "qrc:/qmlimages/NewImages/agri_bg_image_pro.png"
                if (droneType === "AI")      return "qrc:/qmlimages/NewImages/ai_bg_image.png"
                return "qrc:/qmlimages/NewImages/nature_bg_rice_fields.jpg" // Nature rice fields background
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            mipmap: true
            smooth: true

            // Subtle pulse to the background for life
            SequentialAnimation on scale {
                loops: Animation.Infinite
                NumberAnimation {
                    from: 1.0
                    to: 1.05
                    duration: 20000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    from: 1.05
                    to: 1.0
                    duration: 20000
                    easing.type: Easing.InOutSine
                }
            }
        }

        // Animated gradient overlay for moving light effect
        Rectangle {
            anchors.fill: parent
            opacity: 0.6
            visible: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "black"
                }
                GradientStop {
                    position: 0.5
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: "black"
                }
            }
        }

        // Darkening overlay for cinematic look and text readability - with vignette
        Rectangle {
            anchors.fill: parent
            visible: true
            gradient: Gradient {
                id: vignetteGradient
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0, 0, 0, 0.2)
                }
                GradientStop {
                    position: 0.8
                    color: Qt.rgba(0, 0, 0, 0.5)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, 0.7)
                }
            }
        }

        // Subtle atmospheric white top blend for logo visibility and professional natural look
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: dp(35) // Deep atmospheric blend
            visible: true
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.45)
                } // Much subtler starting opacity (was 0.85)
                GradientStop {
                    position: 0.4
                    color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.15)
                } // Extremely soft fade
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
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
            visible: false // Hidden to avoid redundancy with professional cinematic background
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
            id: cameraDrone
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
            visible: false // Removed drone per user request to focus on central content
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
        id: drone_loading
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
            anchors.centerIn: parent
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
            anchors.leftMargin: (isSmallScreen || isMobile) ? dp(2) : dp(5)
            anchors.topMargin: (isSmallScreen || isMobile) ? dp(2) : dp(4)
            z: 50
            opacity: 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.OutCubic
                }
            }
            Component.onCompleted: opacity = 1
        }

        Label {
            id: topBrandText
            text: "DRONE COMMANDER"
            // Hide on small mobile screens (phones), show on tablets and desktop
            // Only show the main branding tagline on the primary home state to prevent background ghosting in operational modes
            visible: (droneType === "loadpage") && !isSmallScreen && parent.height > 500
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            // Ensure space is shared between header and content
            anchors.topMargin: {
                if (droneType === "loadpage") {
                    return Math.max(dp(20), parent.height * 0.3);
                } else {
                    return dp(16); // Moved down for more style
                }
            }
            color: (droneType === "loadpage") ? "#262626" : "#FFFFFF"
            font.family: "Outfit"
            font.bold: true
            font.letterSpacing: isTablet || isDesktop ? 8 : 4
            // Use ScreenTools.largeFontPointSize for better resolution independence
            font.pointSize: {
                var baseSize = ScreenTools.largeFontPointSize;
                var scaleMultiplier = dynamicScaleFactor;
                if (droneType === "loadpage") {
                    if (isDesktop)
                        return baseSize * 4.0 * scaleMultiplier;
                    if (isTablet)
                        return baseSize * 3.5 * scaleMultiplier;
                    return baseSize * 1.8; // Mobile stays clean
                } else {
                    if (isDesktop)
                        return baseSize * 2.8 * scaleMultiplier;
                    if (isTablet)
                        return baseSize * 2.4 * scaleMultiplier;
                    return baseSize * 1.3;
                }
            }
            opacity: 0
            z: 5

            // Position and Size Animations
            Behavior on anchors.topMargin {
                NumberAnimation {
                    duration: 800
                    easing.type: Easing.OutBack
                }
            }
            Behavior on font.pointSize {
                NumberAnimation {
                    duration: 600
                }
            }
            Behavior on font.letterSpacing {
                NumberAnimation {
                    duration: 600
                }
            }

            Component.onCompleted: {
                topTextEntry.start();
            }

            SequentialAnimation {
                id: topTextEntry
                PauseAnimation {
                    duration: 200
                }
                NumberAnimation {
                    target: topBrandText
                    property: "opacity"
                    from: 0
                    to: 0.95
                    duration: 1200
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ---- TOP RIGHT NAVIGATION ----
        Row {
            id: topMenu
            anchors.verticalCenter: mainLogo.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: (isSmallScreen || isMobile) ? dp(2) : dp(5)
            spacing: isSmallScreen ? dp(2) : dp(4)
            z: 100

            // Profile
            Item {
                width: dp(6)
                height: dp(6)

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: profileMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(0, 0, 0, 0.05)
                    border.color: profileMouse.containsMouse ? accent_color : Qt.rgba(0, 0, 0, 0.1)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: dp(1.5)
                    Image {
                        Layout.preferredWidth: dp(2.8)
                        Layout.preferredHeight: dp(2.8)
                        source: "qrc:/qmlimages/NewImages/user_profile.svg"
                        fillMode: Image.PreserveAspectFit
                        // Removed colorization to allow original dark icon to show on the white top header
                    }
                    Label {
                        text: qsTr("PROFILE")
                        color: "#262626"
                        visible: false
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
                    onClicked: {
                        MapGlobals.currentView_profile = "profile";
                        mainWindow.openProfileScreen();
                    }
                }
            }

            // Application
            Item {
                width: dp(6)
                height: dp(6)

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: appMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(0, 0, 0, 0.05)
                    border.color: appMouse.containsMouse ? accent_color : Qt.rgba(0, 0, 0, 0.1)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
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
                        color: "#262626"
                        visible: false
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
                    onClicked: {
                        MapGlobals.currentView_profile = "drone";
                        mainWindow.openProfileScreen();
                    }
                }
            }

            // Logout
            Item {
                width: dp(6)
                height: dp(6)

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: logoutMouse.containsMouse ? Qt.rgba(255, 107, 107, 0.2) : Qt.rgba(0, 0, 0, 0.05)
                    border.color: logoutMouse.containsMouse ? "#FF6B6B" : Qt.rgba(0, 0, 0, 0.1)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
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
                        color: logoutMouse.containsMouse ? "#FF6B6B" : "#262626"
                        visible: false
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
                    onClicked: {
                        logoutdialog.createObject(mainWindow).open();
                    }
                }
            }
        }

        // ---- HERO SECTION ----
        Column {
            id: heroSection
            // Conditional positioning: Center for the main tagline, Left for operational modes
            anchors.horizontalCenter: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri" || droneType === "AI") ? undefined : parent.horizontalCenter
            anchors.left: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri" || droneType === "AI") ? parent.left : undefined
            anchors.leftMargin: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri" || droneType === "AI") ? ((isSmallScreen || isMobile) ? dp(4) : 40) : 0

            // Vertically centered alignment
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: (droneType === "loadpage") ? -dp(5) : 0

            width: {
                if (isSmallScreen || isMobile)
                    return parent.width * 0.75; // Wider on mobile to prevent excessive wrapping
                return droneType === "loadpage" ? parent.width * 0.9 : Math.min(parent.width * 0.45, dp(140)); // Reduced width to prevent overlap with background drone
            }
            // Reduced basic spacing between elements
            spacing: isSmallScreen ? dp(0.5) : dp(1.5)
            opacity: 1
            z: 10

            // Main Title
            Label {
                id: heroTitle
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri" || droneType === "AI") ? Text.AlignLeft : Text.AlignHCenter
                visible: droneType !== "loadpage" // Avoid duplicate "DRONE COMMANDER" on homescreen
                text: {

                    if (droneType === "Camera")  return "CAMERA OPERATIONS"
                    if (droneType === "Mapping") return "MAPPING & SURVEY"
                    if (droneType === "Agri")    return "AGRICULTURAL PRECISION"
                    if (droneType === "AI")      return "AI MISSION ASSISTANT"
                    return ""

                }
                color: (droneType === "loadpage") ? "#262626" : "#FFFFFF"
                // Massive size for Drone Commander, slightly larger for others
                font.pointSize: {
                    var baseSize = ScreenTools.largeFontPointSize;
                    var scaleMultiplier = dynamicScaleFactor;
                    if (droneType === "loadpage") {
                        if (isDesktop)
                            return baseSize * 3.5 * scaleMultiplier;
                        if (isTablet)
                            return baseSize * 3.0 * scaleMultiplier;
                        return baseSize * 1.5;
                    } else {
                        if (isDesktop)
                            return baseSize * 1.5 * scaleMultiplier; // Slightly reduced to save vertical space
                        if (isTablet)
                            return baseSize * 1.4 * scaleMultiplier;
                        return baseSize * 0.85;
                    }
                }
                font.bold: true
                font.family: "Outfit"
                font.letterSpacing: (droneType === "loadpage" && !isSmallScreen) ? 4 : 1.2
                lineHeight: 0.9 // Improved from 0.82 to prevent letter clipping

                // Glow/Shadow for text readability
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: (droneType === "loadpage") ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(0, 0, 0, 0.8)
                    shadowBlur: 0.3
                    shadowHorizontalOffset: 2
                    shadowVerticalOffset: 2
                }
            }

            // Expanded Subtitle / Description
            Label {
                id: heroSubtitle
                visible: !isSmallScreen // Hide on small screens to give room for the Flight Zone widget
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: (droneType === "Camera" || droneType === "Mapping" || droneType === "Agri" || droneType === "AI") ? Text.AlignLeft : Text.AlignHCenter
                text: {
                    if (droneType === "Camera")  return "Master the sky with cinematic 4K vision and precise control.\nCapture high-definition visuals for professional surveillance."
                    if (droneType === "Mapping") return "Industrial-grade photogrammetry and 3D terrain modeling.\nExecute automated flight missions to generate centimeter-level accuracy maps."
                    if (droneType === "Agri")    return "Smart farming through multispectral crop analysis and automated spraying.\nOptimize your yield with intelligent field coverage and health monitoring."
                    if (droneType === "AI")      return "Autonomous intelligence and advanced object recognition.\nReal-time mission optimization with neural-link drone coordination."
                    return "THE ADVANCED GROUND CONTROL STATION FOR ELITE DRONE MISSIONS"
                }

                color: (droneType === "loadpage") ? Qt.rgba(0, 0, 0, 0.7) : Qt.rgba(255, 255, 255, 0.9)
                font.pointSize: {
                    var baseSize = ScreenTools.defaultFontPointSize;
                    var scaleMultiplier = dynamicScaleFactor;
                    if (isDesktop)
                        return baseSize * 1.2 * scaleMultiplier;
                    if (isTablet)
                        return baseSize * 1.1 * scaleMultiplier;
                    return baseSize * 0.8; // Mobile
                }
                font.family: "Outfit"
                font.italic: droneType === "loadpage"
                font.bold: false
                lineHeight: 1.3
                topPadding: dp(1) // Reduced top padding to bring description closer to heading

                // Subtitle shadow
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: (droneType === "loadpage") ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.2
                    shadowVerticalOffset: 1
                }
            }


            // ---- AIRSPACE RECOMMENDATION WIDGET (INLINE HERO) ----

            Rectangle {
                id: airspaceWidget
                visible: true // Always show or adapt as needed
                anchors.horizontalCenter: (droneType === "loadpage") ? parent.horizontalCenter : undefined

                // Set width carefully to fit into the column
                width: isSmallScreen ? parent.width * 0.98 : Math.min(parent.width, 360)
                implicitHeight: widgetContent.height + dp(3.5)
                radius: 12
                color: Qt.rgba(15 / 255, 15 / 255, 20 / 255, 0.75) // Dark cinematic glass theme
                border.color: isCheckingAirspace ? Qt.rgba(250 / 255, 204 / 255, 21 / 255, 0.4) : (isClearToFly ? Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.4) : Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.4))
                border.width: 1
                z: 90

                // Add some top margin for clean spacing after title/subtitle
                Item {
                    height: isSmallScreen ? dp(2) : dp(3)
                    width: 1
                }

                // Slide-in animation for a premium feel
                opacity: 0
                transform: Translate {
                    id: widgetSlide
                    y: -20
                }

                Component.onCompleted: {
                    widgetEntryAnim.start()
                }

                SequentialAnimation {
                    id: widgetEntryAnim
                    PauseAnimation {
                        duration: 500
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: airspaceWidget
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 800
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: widgetSlide
                            property: "y"
                            from: -20
                            to: 0
                            duration: 800
                            easing.type: Easing.OutBack
                        }
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 1.0
                    shadowVerticalOffset: 4
                    // Professional glass effect blur for modern aesthetic
                    blurEnabled: false
                    blur: 0.1
                    blurMax: 32
                }

                property bool _airspaceDataAvailable: false

                Timer {
                    id: airspaceCheckTimer
                    interval: 2000
                    running: true
                    repeat: true
                    onTriggered: {
                        // Safe access to global managers
                        var manager = QGroundControl.airspaceManager
                        var posManager = QGroundControl.qgcPositionManager
                        
                        if (!manager || !posManager) return

                        var pos = posManager.gcsPosition
                        if (pos && pos.isValid && (pos.latitude !== 0 || pos.longitude !== 0)) {
                            // Fetch data once for the area if not already done
                            if (!_airspaceDataAvailable) {
                                var range = 0.1 // ~11km range
                                manager.fetchAirspaceData(
                                            pos.latitude - range, pos.longitude - range,
                                            pos.latitude + range, pos.longitude + range
                                            )
                                _airspaceDataAvailable = true
                            }
                            
                            // Update UI properties safely
                            isCheckingAirspace = manager.isLoading
                            isClearToFly = !manager.isCoordinateInRedZone(pos)
                        } else {
                            isCheckingAirspace = true // Keep analyzing state until GPS is found
                        }

                    }
                }

                ColumnLayout {
                    id: widgetContent
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: dp(1.5)
                    anchors.leftMargin: dp(2)
                    anchors.rightMargin: dp(2)
                    anchors.bottomMargin: dp(1.5)
                    spacing: dp(0.8)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: dp(1)

                        // Pulse Inner Dot
                        Rectangle {
                            width: dp(1)
                            height: dp(1)
                            radius: width / 2
                            color: isCheckingAirspace ? "#facc15" : (isClearToFly ? "#4ade80" : "#f87171")

                            SequentialAnimation on opacity {
                                running: isCheckingAirspace
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: 0.1
                                    to: 1.0
                                    duration: 500
                                }
                                NumberAnimation {
                                    from: 1.0
                                    to: 0.1
                                    duration: 500
                                }
                            }

                            layer.enabled: !isCheckingAirspace
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: isClearToFly ? "#4ade80" : "#f87171"
                                shadowBlur: 0.8
                            }
                        }

                        Label {

                            Layout.fillWidth: true
                            text: qsTr("FLIGHT ZONE STATUS")
                            color: "white"
                            font.family: "Outfit"
                            font.pointSize: ScreenTools.smallFontPointSize * 0.85
                            font.bold: true
                            font.letterSpacing: 1.5
                            opacity: 0.8
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: {
                            var pos = QGroundControl.qgcPositionManager.gcsPosition
                            if (!pos || !pos.isValid || (pos.latitude === 0 && pos.longitude === 0)) return qsTr("Waiting for GPS...")
                            return isCheckingAirspace ? qsTr("Analyzing Airspace...") : (isClearToFly ? qsTr("Clear to Fly") : qsTr("Restricted Airspace"))
                        }
                        color: {
                            var pos = QGroundControl.qgcPositionManager.gcsPosition
                            if (!pos || !pos.isValid || (pos.latitude === 0 && pos.longitude === 0)) return "#64748b"
                            return isCheckingAirspace ? "#facc15" : (isClearToFly ? "#4ade80" : "#f87171")
                        }

                        font.family: "Outfit"
                        font.pointSize: ScreenTools.defaultFontPointSize * 1.05
                        font.bold: true

                        Behavior on color {
                            ColorAnimation {
                                duration: 400
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: {
                            var pos = QGroundControl.qgcPositionManager.gcsPosition
                            if (!pos || !pos.isValid || (pos.latitude === 0 && pos.longitude === 0)) return qsTr("Acquiring current location to verify flight regulations in your area.")
                            return isCheckingAirspace ? qsTr("Fetching GPS coordinates and checking local drone flight regulations.") :
                                                        (isClearToFly ? qsTr("Class G Airspace. No active flight restrictions detected in your current location. Ensure standard safety protocols.") : qsTr("Authorization required to fly in this zone. Please check with local aviation authorities before takeoff."))
                        }

                        color: "white"
                        opacity: 0.6
                        font.family: "Outfit"
                        font.pointSize: ScreenTools.smallFontPointSize * 0.85
                        lineHeight: 1.2

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                            }
                        }
                    }
                }

                // Interactive element to open airspace map website
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.openUrlExternally("https://airspacemap.in/");
                    }
                }
            }
        }

        // ---- COMING SOON RIGHT SIDE PANEL (AI MODE) ----
        Item {
            id: comingSoonPanel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: (isSmallScreen || isMobile) ? dp(4) : 60
            width: (isSmallScreen || isMobile) ? parent.width * 0.45 : dp(75)
            height: Math.min(parent.height * 0.65, dp(85))
            visible: droneType === "AI"
            z: 100

            // Entrance animation
            opacity: 0
            transform: Translate { id: panelSlide; x: 40 }
            Component.onCompleted: {
                if (droneType === "AI") panelEntryAnim.start()
            }
            onVisibleChanged: {
                if (visible) panelEntryAnim.start()
            }

            SequentialAnimation {
                id: panelEntryAnim
                PauseAnimation { duration: 300 }
                ParallelAnimation {
                    NumberAnimation { target: comingSoonPanel; property: "opacity"; from: 0; to: 1; duration: 1200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: panelSlide; property: "x"; from: 40; to: 0; duration: 1200; easing.type: Easing.OutBack }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 28
                color: Qt.rgba(0, 0, 0, 0.7) // Increased opacity for better legibility without blur
                border.color: Qt.rgba(255, 255, 255, 0.15)
                border.width: 1

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0,0,0,0.6)
                    shadowBlur: 1.0
                    shadowVerticalOffset: 12
                    blurEnabled: false
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: dp(3.5)
                    spacing: dp(2.5)

                    // Header decoration
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: dp(1.8)

                        Rectangle {
                            width: dp(5.5)
                            height: dp(5.5)
                            radius: 12
                            color: accent_color
                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/select_drone_type_color.svg"
                                width: parent.width * 0.6
                                height: width
                                anchors.centerIn: parent
                                color: "white"
                            }
                        }

                        ColumnLayout {
                            spacing: -2
                            Label {
                                text: "NEXT GENERATION"
                                color: accent_color
                                font.family: "Outfit"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize * 0.75
                                font.letterSpacing: 2.5
                            }
                            Label {
                                text: "MISSION HUB"
                                color: "white"
                                font.family: "Outfit"
                                font.bold: true
                                font.pointSize: ScreenTools.largeFontPointSize * 0.9
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        opacity: 0.15
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: "white" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Autonomous intelligence that thinks ahead. Deploy neural-link drone coordination and real-time tactical analysis."
                        color: "white"
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        font.family: "Outfit"
                        font.pointSize: ScreenTools.defaultFontPointSize * 0.95
                        lineHeight: 1.3
                    }

                    // Feature Grid
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: dp(2)

                        Repeater {
                            model: [
                                { icon: "qrc:/qmlimages/NewImages/camera_Application.svg", title: "Autonomous Swarming", desc: "Multi-drone coordination" },
                                { icon: "qrc:/qmlimages/NewImages/mapping_Application.svg", title: "Neural Terrain AI", desc: "Real-time environment analysis" },
                                { icon: "qrc:/qmlimages/NewImages/agri_Application.svg", title: "Predictive Ops", desc: "Data-driven mission optimization" }
                            ]

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: dp(1.8)

                                Rectangle {
                                    width: dp(4)
                                    height: dp(4)
                                    radius: 8
                                    color: Qt.rgba(255, 255, 255, 0.06)
                                    border.color: Qt.rgba(255, 255, 255, 0.05)
                                    QGCColoredImage {
                                        source: modelData.icon
                                        width: parent.width * 0.6
                                        height: width
                                        anchors.centerIn: parent
                                        color: accent_color
                                    }
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Label {
                                        text: modelData.title
                                        color: "white"
                                        font.family: "Outfit"
                                        font.bold: true
                                        font.pointSize: ScreenTools.defaultFontPointSize * 0.9
                                    }
                                    Label {
                                        text: modelData.desc
                                        color: "white"
                                        opacity: 0.5
                                        font.family: "Outfit"
                                        font.pointSize: ScreenTools.smallFontPointSize * 0.8
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Status Badge
                    Rectangle {
                        Layout.fillWidth: true
                        height: dp(6.5)
                        radius: 14
                        color: Qt.rgba(249/255, 115/255, 22/255, 0.12)
                        border.color: Qt.rgba(249/255, 115/255, 22/255, 0.25)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: dp(1.2)

                            Rectangle {
                                width: dp(1.2)
                                height: dp(1.2)
                                radius: width / 2
                                color: accent_color
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.2; to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 1.0; to: 0.2; duration: 1000; easing.type: Easing.InOutSine }
                                }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: accent_color
                                    shadowBlur: 0.8
                                }
                            }

                            Label {
                                text: "IN DEVELOPMENT: PHASE 2"
                                color: accent_color
                                font.family: "Outfit"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize * 0.85
                                font.letterSpacing: 1.5
                            }
                        }
                    }
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

            // Click to Connect
            Item {
                id: connectClick
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: dp(30)
                Layout.minimumWidth: dp(18)
                Layout.preferredHeight: dp(7)

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: connectMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(0, 0, 0, 0.4)
                    border.color: connectMouse.containsMouse ? accent_color : Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: dp(0.8)
                        spacing: dp(1.5)

                        Rectangle {
                            Layout.preferredWidth: parent.height - dp(1)
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: accent_color

                            Image {
                                source: "qrc:/qmlimages/NewImages/commlinks.svg"
                                width: parent.width * 0.5
                                height: width
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("CONNECT")
                            color: "white"
                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                        }
                    }
                }

                MouseArea {
                    id: connectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var editingConfig = _linkManager.createConfiguration(ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "");
                        typeSelectionDialogComponent.createObject(mainWindow1, {
                                                                      editingConfig: editingConfig,
                                                                      originalConfig: null
                                                                  }).open();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // Click to Camera
            Item {
                id: cameraClick
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: dp(30)
                Layout.minimumWidth: dp(18)
                Layout.preferredHeight: dp(7)
                visible: droneType === "loadpage" || droneType === "Camera"

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: cameraMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(0, 0, 0, 0.4)
                    border.color: cameraMouse.containsMouse ? app_color : Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: dp(0.8)
                        spacing: dp(1.5)

                        Rectangle {
                            Layout.preferredWidth: parent.height - dp(1)
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: "#1a1a1a" // Deep background for icon

                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/camera_Application.svg"
                                width: parent.width * 0.5
                                height: width
                                color: "white"
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("CAMERA")
                            color: "white"
                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                        }
                    }
                }

                MouseArea {
                    id: cameraMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mainWindow.updateAppTheme("Camera");
                        MapGlobals.comefrom = "Camera";
                        mainWindow.cameraView();
                        QGroundControl.saveGlobalSetting("waypoint", "waypoint");
                        var videoSettings = QGroundControl.settingsManager.videoSettings;
                        if (videoSettings) {
                            var videoSourceFact = videoSettings.videoSource;
                            if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                videoSourceFact.value = videoSourceFact.enumValues[0];
                            }
                        }
                        swapCamera();
                    }
                }
            }

            // Click to Agri
            Item {
                id: agriClick
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: dp(30)
                Layout.minimumWidth: dp(18)
                Layout.preferredHeight: dp(7)
                visible: droneType === "loadpage" || droneType === "Agri"

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: agriMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(0, 0, 0, 0.4)
                    border.color: agriMouse.containsMouse ? app_color : Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: dp(0.8)
                        spacing: dp(1.5)

                        Rectangle {
                            Layout.preferredWidth: parent.height - dp(1)
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: "#1a2a1a" // Subtle dark green tint for agri background

                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/agri_Application.svg"
                                width: parent.width * 0.5
                                height: width
                                color: "#45d058" // Professional vibrant green
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("SPRAYING")
                            color: "white"
                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                        }
                    }
                }

                MouseArea {
                    id: agriMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var frameType = QGroundControl.loadBoolGlobalSetting("frametypeDialog", false);
                        var videoSettings = QGroundControl.settingsManager.videoSettings;
                        var videoSourceFact = videoSettings.videoSource;
                        if (activeVehicle) {
                            console.log("Inside the active Vehicle", frameType);
                            if (!activeVehicle.parameterManager.parametersReady) {
                                mainWindow.showToastMessage("Plese Wait Vehicle parameters are still loading...");
                                return;
                            }
                            if (!frameType) {
                                console.log("Frame Dialog Open", frameType);
                                QGroundControl.saveBoolGlobalSetting("frametypeDialog", true);
                                showDynamicCalibrationDialog("qrc:/qml/APMAirframeComponent.qml", "Frame Type");
                            } else {
                                console.log("Frame Dialog not open", frameType);
                                QGroundControl.saveGlobalSetting("loadpage", "Agri");
                                mainWindow.updateAppTheme("Agri");
                                mainWindow.showFlyView();
                                MapGlobals.comefrom = "Plan";
                                console.log("MapGlobals.comefrom", MapGlobals.comefrom);
                                _appSettings.screen = "Plan";

                                //var videoSettings = QGroundControl.settingsManager.videoSettings

                                if (videoSettings) {
                                    //var videoSourceFact = videoSettings.videoSource
                                    if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                        videoSourceFact.value = videoSourceFact.enumValues[0];
                                    }
                                }
                                swapCamera();
                            }
                        } else {
                            mainWindow.updateAppTheme("Agri");
                            mainWindow.showFlyView();
                            MapGlobals.comefrom = "Plan";
                            console.log("MapGlobals.comefrom", MapGlobals.comefrom);
                            _appSettings.screen = "Plan";

                            //var videoSettings = QGroundControl.settingsManager.videoSettings

                            if (videoSettings) {
                                //var videoSourceFact = videoSettings.videoSource
                                if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                    videoSourceFact.value = videoSourceFact.enumValues[0];
                                }
                            }
                            swapCamera();
                        }
                    }
                }
            }

            // Click to Mapping
            Item {
                id: mappingClick
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                Layout.fillWidth: true
                Layout.maximumWidth: dp(30)
                Layout.minimumWidth: dp(18)
                Layout.preferredHeight: dp(7)
                visible: droneType === "loadpage" || droneType === "Mapping"

                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: mappingMouse.pressed ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(0, 0, 0, 0.4)
                    border.color: mappingMouse.containsMouse ? app_color : Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: dp(0.8)
                        spacing: dp(1.5)

                        Rectangle {
                            Layout.preferredWidth: parent.height - dp(1)
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: "#1a1a2a" // Subtle dark blue tint for mapping background

                            QGCColoredImage {
                                source: "qrc:/qmlimages/NewImages/mapping_Application.svg"
                                width: parent.width * 0.5
                                height: width
                                color: "#3b82f6" // Professional vibrant blue
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: qsTr("MAPPING")
                            color: "white"
                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize: ScreenTools.defaultFontPointSize
                        }
                    }
                }

                MouseArea {
                    id: mappingMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mainWindow.updateAppTheme("Mapping");
                        mainWindow.showMapping();
                        MapGlobals.comefrom = "Start";
                        _appSettings.screen = "Start";
                        var videoSettings = QGroundControl.settingsManager.videoSettings;
                        if (videoSettings) {
                            var videoSourceFact = videoSettings.videoSource;
                            if (videoSourceFact && videoSourceFact.enumValues.length > 1) {
                                videoSourceFact.value = videoSourceFact.enumValues[0];
                            }
                        }
                        swapCamera();
                    }
                }
            }
        }
    }

    function showDynamicCalibrationDialog(qmlFile, title) {
        dynamicCalDialog.dialogTitleText = title;
        dialogLoader.source = qmlFile;
        dynamicCalDialog.open();
    }

    // Logout Dialog Component
    Component {
        id: logoutdialog

        QGCPopupDialog {
            id: popup
            title: qsTr("Logout")

            buttons: Dialog.Yes | Dialog.No

            onAccepted: {
                QGroundControl.saveBoolGlobalSetting("login", false);
                QGroundControl.saveGlobalSetting("loadpage", "loadpage");
                popup.visible = false;
                MapGlobals.profile();
            }

            onRejected: {
                popup.visible = false;
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

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

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
                                typeDialog.selectedType = index;
                                typeDialog.close();
                                var editingConfig = _linkManager.createConfiguration(index, "");
                                linkConfigDialogComponent.createObject(mainWindow, {
                                                                           editingConfig: editingConfig,
                                                                           originalConfig: null,
                                                                           selectedType: index
                                                                       }).open();
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
            id: linkConfigDialog
            title: selectedType === 0 ? "Bluetooth Devices" : originalConfig ? qsTr("Edit Link") : qsTr("Add New Link")
            buttons: Dialog.Save | Dialog.Cancel
            acceptAllowed: nameField.text !== ""

            property var originalConfig
            property var editingConfig
            property int selectedType

            property bool _connectionInitiated: false

            // if the Mobile Location is in Off state while iam click Refresh button, show the Toast message
            Connections {
                target: linkConfigDialog.editingConfig
                enabled: linkConfigDialog.editingConfig !== null

                function onShowToast(message) {
                    mainWindow.showToastMessage(message);
                }
            }

            onAccepted: {
                console.log("Click Save");
                if (_connectionInitiated) {
                    console.log("linkConfigDialog: ignoring duplicate accept");
                    return;
                }
                linkSettingsLoader.item.saveSettings();
                editingConfig.devName = nameField.text;
                editingConfig.name = editingConfig.devName;

                //connecting_drone = true

                if (originalConfig) {
                    _linkManager.endConfigurationEditing(originalConfig, editingConfig);
                } else {
                    editingConfig.dynamic = false;
                    _linkManager.endCreateConfiguration(editingConfig);
                    if (activeVehicle) {
                        mainWindow.showToastMessage(qsTr("Please disconnect the active vehicle before connecting a new one"));
                        return;
                    }
                    _connectionInitiated = true;         // mark as initiated
                    connecting_drone = true;  // only set true once
                    _linkManager.createConnectedLink(editingConfig);
                }
            }

            onRejected: {
                console.log("Click Cancel");
                _connectionInitiated = false;  //reset on cancel
                _linkManager.cancelConfigurationEditing(editingConfig);
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
                        id: nameField
                        Layout.fillWidth: true
                        text: editingConfig.devName
                        placeholderText: qsTr("e.g. My Custom Drone Connection")

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
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
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

                    property var subEditConfig: linkConfigDialog.editingConfig
                    property int _firstColumnWidth: ScreenTools.defaultFontPixelWidth * 12
                    property int _secondColumnWidth: ScreenTools.defaultFontPixelWidth * 30
                    property int _rowSpacing: ScreenTools.defaultFontPixelHeight / 2
                    property int _colSpacing: ScreenTools.defaultFontPixelWidth / 2
                }
            }
        }
    }
}
