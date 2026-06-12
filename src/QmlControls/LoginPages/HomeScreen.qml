
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
    property var item1: null    // Required
    property var item2: null    // Optional, may come and go
    property var _fullItem
    property var _pipOrWindowItem


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
            source: "qrc:/qmlimages/NewImages/agri_bg_image_pro.png"
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
            width: ScreenTools.defaultFontPixelWidth * (isMobile ? 6 : 8)
            height: width * (80 / 180)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin:((isSmallScreen || isMobile) ? dp(4) : 40)
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
                        text: qsTr("SIGN OUT")
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

        Column {
            id: heroSection

            // Conditional positioning: Center for the main tagline, Left for operational modes
            anchors.horizontalCenter:  undefined
            anchors.left:  parent.left

            anchors.leftMargin:((isSmallScreen || isMobile) ? dp(4) : 40)

            // Center the whole block in the available vertical space
            anchors.verticalCenter: parent.verticalCenter

            width: {
                if (isSmallScreen || isMobile)
                    return parent.width * 0.75; // Wider on mobile to prevent excessive wrapping
                return Math.min(parent.width * 0.45, dp(140)); // Reduced width to prevent overlap with background drone

            }

            // Reduced basic spacing between elements
            spacing: (isSmallScreen || isMobile) ? dp(0.4) : dp(1)

            // 2. Main Title (Moved inside the column)
            Text {
                id: topBrandText
                text: "DRONE COMMANDER"
                width: parent.width
                horizontalAlignment: Text.AlignLeft //(droneType === "Camera" || droneType === "Mapping" || droneType === "Agri" || droneType === "AI") ? Text.AlignLeft : Text.AlignHCenter
                visible: false //(droneType === "loadpage")
                color: "#262626"
                font.family: "Outfit"
                font.bold: true
                font.letterSpacing: isSmallScreen ? 0 : (isTablet || isDesktop ? 8 : 1.2)
                
                // Automatic fitting logic
                fontSizeMode: Text.HorizontalFit
                minimumPointSize: 6
                font.pointSize: {
                    var baseSize = ScreenTools.largeFontPointSize;
                    if (isDesktop) return baseSize * 4.0;
                    if (isTablet) return baseSize * 3.5;
                    return isSmallScreen ? 18 : 26; // Target sizes, reduced for mobile
                }
                lineHeight: 1.1
            }


            // 3. Mode Title (Original heroTitle, hidden on home page)
            Label {
                id: heroTitle
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                visible: true // Avoid duplicate "DRONE COMMANDER" on homescreen
                text: "AGRICULTURAL PRECISION"
                color: "#FFFFFF"
                // Massive size for Drone Commander, slightly larger for others
                font.pointSize: {
                    var baseSize = ScreenTools.largeFontPointSize;
                    var scaleMultiplier = dynamicScaleFactor;

                    if (isDesktop)
                        return baseSize * 1.5 * scaleMultiplier; // Slightly reduced to save vertical space
                    if (isTablet)
                        return baseSize * 1.4 * scaleMultiplier;
                    return baseSize * 0.85;

                }


                font.bold: true
                font.family: "Outfit"
                font.letterSpacing: (!isSmallScreen) ? 4 : 1.2
                lineHeight: 0.9 // Improved from 0.82 to prevent letter clipping

                // Glow/Shadow for text readability
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.8)
                    shadowBlur: 0.3
                    shadowHorizontalOffset: 2
                    shadowVerticalOffset: 2
                }
            }

            // Expanded Subtitle / Description
            Label {
                id: modeDescription
                visible: !isSmallScreen //(droneType === "loadpage") ? false : !isSmallScreen // Hide on home page as tagline is now used
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                text: "Smart farming through multispectral crop analysis and automated spraying.\nOptimize your yield with intelligent field coverage and health monitoring."


                color:  Qt.rgba(255, 255, 255, 0.9)
                font.pointSize: {
                    var baseSize = ScreenTools.defaultFontPointSize;
                    var scaleMultiplier = dynamicScaleFactor;
                    if (isDesktop)
                        return baseSize * 1.2 * scaleMultiplier;
                    if (isTablet)
                        return baseSize * 1.1 * scaleMultiplier;
                    return baseSize * 0.7; // Even smaller for mobile to save space
                }
                font.family: "Outfit"
                font.bold: false
                lineHeight: 1.2
                bottomPadding: dp(1) // Padding at bottom to space away from the title below

                // Subtitle shadow
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor:  Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.2
                    shadowVerticalOffset: 1
                }
            }
            
            // 4. Flight Zone Status (Moved back into the column for unified centering)
            Rectangle {
                id: airspaceWidget

                visible: true // Always show or adapt as needed
                anchors.horizontalCenter:  undefined

                // Set width carefully to fit into the column
                width: isSmallScreen ? parent.width * 0.98 : Math.min(parent.width, 360)
                implicitHeight: widgetContent.height + dp(3.5)

                radius: 12
                color: Qt.rgba(15 / 255, 15 / 255, 20 / 255, 0.82)
                border.color: isCheckingAirspace ? Qt.rgba(250 / 255, 204 / 255, 21 / 255, 0.5) : (isClearToFly ? Qt.rgba(74 / 255, 222 / 255, 128 / 255, 0.5) : Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.5))
                border.width: 1
                z: 90

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
                            if (!airspaceWidget._airspaceDataAvailable) {
                                var range = 0.1 // ~11km range
                                manager.fetchAirspaceData(
                                            pos.latitude - range, pos.longitude - range,
                                            pos.latitude + range, pos.longitude + range
                                            )
                                airspaceWidget._airspaceDataAvailable = true
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
                    anchors.topMargin: isSmallScreen ? dp(0.5) : dp(1)
                    anchors.leftMargin: dp(2)
                    anchors.rightMargin: dp(2)
                    anchors.bottomMargin: isSmallScreen ? dp(0.5) : dp(1)
                    spacing: (isSmallScreen || isMobile) ? dp(0.4) : dp(1.2)

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
                            font.pointSize: ScreenTools.smallFontPointSize * 0.95
                            font.bold: true
                            font.letterSpacing: 2.0
                            opacity: 0.9
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
                        font.pointSize: ScreenTools.defaultFontPointSize * 1.2
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
                        font.pointSize: ScreenTools.smallFontPointSize * 0.95
                        lineHeight: 1.3

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


        // ---- BOTTOM BUTTONS BAR ----
        RowLayout {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottomMargin: (isSmallScreen || isMobile) ? dp(1.5) : dp(2)
            anchors.leftMargin:((isSmallScreen || isMobile) ? dp(4) : 40)
            anchors.rightMargin: (isSmallScreen || isMobile) ? dp(2) : dp(4)
            spacing: (isSmallScreen || isMobile) ? dp(0.5) : dp(2)

            // Helpful for debugging or ensuring minimum space
            Layout.fillWidth: true

            // Click to Connect
            Item {
                id: connectClick
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                Layout.fillWidth: false
                Layout.maximumWidth: dp(28)
                Layout.preferredWidth: (isSmallScreen || isMobile) ? Math.min(dp(24), parent.width * 0.23) : dp(28)
                Layout.minimumWidth: (isSmallScreen || isMobile) ? dp(10) : dp(18)
                Layout.preferredHeight: (isSmallScreen || isMobile) ? dp(6.5) : dp(7.5)

                property bool _swiped: false
                property real _progress: 0

                Rectangle {
                    id: swipeTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(255, 255, 255, 0.15)
                    border.width: 1
                    clip: true

                    // Fill strip — starts hidden, grows as thumb moves
                    Rectangle {
                        x: 0; y: 0
                        width: Math.max(0, swipeThumb.x - dp(0.5))  // ← only show BEHIND thumb, not under it
                        height: parent.height
                        radius: 0
                        color: connectClick._swiped ? "#2e7d32" : accent_color
                        opacity: 0.85
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Label
                    Label {
                        anchors.left: swipeThumb.right
                        anchors.leftMargin: dp(1.5)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: dp(1)
                        text: connectClick._swiped ? qsTr("CONNECTED") : qsTr("CONNECT   >>>>>")
                        color: "white"
                        font.family: "Outfit"
                        font.bold: true
                        font.pointSize: (isSmallScreen || isMobile) ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                        elide: Text.ElideRight
                        fontSizeMode: Text.Fit
                        minimumPointSize: 6
                        opacity: connectClick._swiped ? 1.0 : Math.max(0, 1 - connectClick._progress * 3)
                    }

                    // Thumb
                    Rectangle {
                        id: swipeThumb
                        width: parent.height - dp(1)
                        height: width
                        radius: width / 2
                        x: dp(0.5)
                        y: dp(0.5)
                        color: connectClick._swiped ? "#388e3c" : accent_color

                        Behavior on x {
                            enabled: !dragHandler.active
                            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                        }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Image {
                            source: connectClick._swiped
                                ? "qrc:/qmlimages/NewImages/check.svg"
                                : "qrc:/qmlimages/NewImages/commlinks.svg"
                            width: parent.width * 0.5
                            height: width
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                        }

                        DragHandler {
                            id: dragHandler
                            xAxis.minimum: dp(0.5)
                            xAxis.maximum: swipeTrack.width - swipeThumb.width - dp(0.5)
                            yAxis.enabled: false
                            onActiveChanged: {
                                if (!active && connectClick._progress < 0.95)
                                    swipeThumb.x = dp(0.5)  // snap back
                            }
                            onTranslationChanged: {
                                var maxX = swipeTrack.width - swipeThumb.width - dp(1)
                                connectClick._progress = Math.min(1, (swipeThumb.x - dp(0.5)) / maxX)
                                if (connectClick._progress >= 0.95 && !connectClick._swiped) {
                                    connectClick._swiped = true
                                    swipeThumb.x = maxX + dp(0.5)
                                    // ---- your original onClicked logic here ----
                                    var editingConfig = _linkManager.createConfiguration(
                                        ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, "")
                                    typeSelectionDialogComponent.createObject(mainWindow1, {
                                        editingConfig: editingConfig,
                                        originalConfig: null
                                    }).open()
                                    // reset after 2 seconds
                                    resetTimer.start()
                                }
                            }
                        }
                    }
                }

                Timer {
                    id: resetTimer
                    interval: 2000
                    onTriggered: {
                        connectClick._swiped = false
                        connectClick._progress = 0
                        swipeThumb.x = dp(0.5)
                    }
                }
            }
            // Flexible spacer to push operational buttons to the right
            Item {
                Layout.fillWidth: true
                // Removed visibility condition to ensure right alignment even on mobile
            }

            // Click to Agri
            Item {
                id: agriClick
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom

                // Layout.fillWidth: true
                // Layout.maximumWidth: dp(30)
                // Layout.minimumWidth: dp(18)
                // Layout.preferredHeight: dp(7)
                // visible:  true

                Layout.fillWidth: false
                Layout.maximumWidth: dp(28)
                Layout.preferredWidth: (isSmallScreen || isMobile) ? Math.min(dp(24), parent.width * 0.23) : dp(28)
                Layout.minimumWidth: (isSmallScreen || isMobile) ? dp(10) : dp(18)
                Layout.preferredHeight: (isSmallScreen || isMobile) ? dp(6.5) : dp(7.5)
                visible: true


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
                            font.pointSize: (isSmallScreen || isMobile) ? ScreenTools.smallFontPointSize : ScreenTools.defaultFontPointSize
                            elide: Text.ElideRight
                            fontSizeMode: Text.Fit
                            minimumPointSize: 6
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
                                //mainWindow.updateAppTheme("Agri");
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
                            //mainWindow.updateAppTheme("Agri");
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
                        title: qsTr("Sign Out")

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
                                text: qsTr("Are you sure you want to sign out?")
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
                        popupWidth: (isSmallScreen || isMobile)
                                    ? Math.min(mainWindow1.width * 0.92, 420)
                                    : 560

                        property int selectedType: -1

                        ColumnLayout {
                            spacing: 2
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
                                    Layout.preferredHeight: visible ? 52 : 0
                                    Layout.bottomMargin: index === (_linkManager.linkTypeStrings.length - 1) ? 20 : 0
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
                                        spacing: 12

                                        // Number Icon Box
                                        Rectangle {
                                            width: 36
                                            height: 36
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
                        acceptAllowed: _linkManager.linkTypeStrings[selectedType] === "Bluetooth"
                                        ? (editingConfig && editingConfig.devName !== "")
                                        : nameField.text !== ""

                        property var originalConfig
                        property var editingConfig
                        property int selectedType

                        property bool _connectionInitiated: false

                        // if the Mobile Location is in Off state while iam click Refresh button, show the Toast message
                        Connections {
                            target: editingConfig
                            enabled: editingConfig !== null

                            function onShowToast(message) {
                                mainWindow.showToastMessage(message);
                            }
                        }

                        onAccepted: {
                            console.log("Click Save");
                            if (_connectionInitiated) {
                                console.log("linkConfigDialog: ignoring duplicate accept");
                                preventClose = true;
                                return;
                            }
                            if (!editingConfig) {
                                preventClose = true;
                                return;
                            }
                            if (_linkManager.linkTypeStrings[selectedType] === "Bluetooth") {
                                editingConfig.stopScan();
                            }
                            if (linkSettingsLoader.item) {
                                linkSettingsLoader.item.saveSettings();
                            }
                            if (_linkManager.linkTypeStrings[selectedType] !== "Bluetooth") {
                                editingConfig.devName = nameField.text;
                            }
                            editingConfig.name = editingConfig.devName;

                            if (originalConfig) {
                                _linkManager.endConfigurationEditing(originalConfig, editingConfig);
                            } else {
                                editingConfig.dynamic = false;
                                if (!_linkManager.endCreateConfiguration(editingConfig)) {
                                    preventClose = true;
                                    return;
                                }
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
                            if (editingConfig && _linkManager.linkTypeStrings[selectedType] === "Bluetooth") {
                                editingConfig.stopScan();
                            }
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
                                source: editingConfig ? editingConfig.settingsURL : ""

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

