import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QtQuick.Effects
Item {
    id:     root
    anchors.fill: parent


    property int agriall: QGroundControl.loadGlobalSetting("agriall","0")
    property int agrigimbal: QGroundControl.loadGlobalSetting("agrigimbal","0")
    property int cameragimbal: QGroundControl.loadGlobalSetting("cameragimbal","-1")
    property int cameragimbal1: QGroundControl.loadGlobalSetting("cameragimbal1","-1")
    property int cameragimbal2: QGroundControl.loadGlobalSetting("cameragimbal2","-1")
    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle

    // Calculate card width to show exactly 3 per row with spacing
    readonly property int cardsPerRow: 4
    readonly property int horizontalMargin: 50
    readonly property int columnSpacing: 20
    readonly property int cardWidth: (parent.width *0.98 - horizontalMargin - (columnSpacing * (cardsPerRow - 1))) / cardsPerRow
    readonly property int cardHeight: cardWidth // Keep cards square

    property color app_color: "#301934"


    property var agri: [
        { text: "All", icon: "qrc:/qmlimages/NewImages/all_parameter.svg", color: "#2c3e50" },
        { text: "SPRAY", icon: "qrc:/qmlimages/NewImages/spray_parameter.svg", color: "#8e44ad" }
    ]

    property var agrigimbalModels: [
        { text: "Servo Gimbal", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#3498db" },
        { text: "STorM32", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#9b59b6" },
        { text: "Brushless PWM", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#e74c3c" }
    ]

    property var gimbalModels: [
        { text: "All", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#2c3e50" },
        { text: "Servo Gimbal", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#3498db" },
        { text: "STorM32", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#9b59b6" },
        { text: "Brushless PWM", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#e74c3c" }
    ]

    property var gimbalModels1: [
        { text: "CADDX", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#1abc9c" },
        { text: "Gremsy", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#f39c12" },
        { text: "Xacti", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#d35400" }
    ]

    property var gimbalModels2: [
        { text: "SERVO", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#27ae60" },
        { text: "Relay", icon: "qrc:/qmlimages/NewImages/homeIcon.png", color: "#c0392b" }
    ]

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            z: -10
            color: "white"
        }
        // ---- Curved Gradient Background ----
        // Canvas {
        //     anchors.fill: parent
        //     z: -1
        //     opacity: 0.95
        //     onPaint: {
        //         var ctx = getContext("2d")
        //         ctx.reset()

        //         // 🎨 Create diagonal gradient
        //         var gradient = ctx.createLinearGradient(0, 0, width, height)
        //         gradient.addColorStop(0, "#505050")
        //         gradient.addColorStop(1, "#505050")
        //         ctx.fillStyle = gradient

        //         // 🌀 Create a curved path from top-left to bottom-right
        //         ctx.beginPath()
        //         ctx.moveTo(0, 0)
        //         ctx.quadraticCurveTo(width * 0.4, height * 0.1, width, height * 0.9)
        //         ctx.lineTo(width, height)
        //         ctx.lineTo(0, height)
        //         ctx.closePath()
        //         ctx.fill()
        //     }
        // }

        // Rectangle {
        //     anchors.right: parent.right
        //     anchors.bottom: parent.bottom
        //     width: parent.width * 0.5
        //     height: parent.height * 0.9
        //     radius: width * 0.5
        //     rotation: 30
        //     opacity: 0.95
        //     anchors.rightMargin: 1//-width * 0.25
        //     anchors.bottomMargin: 1//-height * 0.2
        //     z: -1

        //     gradient: Gradient {
        //         GradientStop { position: 0.0; color: "#14163C" } // Deep indigo
        //         GradientStop { position: 1.0; color: "#6A85FB" } // Blue gradient
        //     }
        // }



        QGCFlickable {
            id: mainFlickable
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: columnContent.height
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: columnContent
                width: parent.width
                spacing: 20
                topPadding: 20
                rightPadding: 100

                // Header
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Agri Spraying"
                    color: app_color
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.weight: Font.DemiBold
                    bottomPadding: 20
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"?true:false
                }

                // Grid layout for gimbal models
                Grid {
                    id: gimbalGrids
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"?true:false
                    // Horizontal spacing (between columns)
                    columnSpacing: 30
                    // Vertical spacing (between rows)
                    rowSpacing: 30

                    Repeater {
                        model: agri
                        delegate: agriDelegate
                    }
                }

                // Header
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Select Gimbal Type"
                    color: app_color
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.weight: Font.DemiBold
                    bottomPadding: 20
                    visible: false // Hidden for all modes as per user request (Agri ONLY needs All/SPRAY)
                }

                // Grid layout for gimbal models
                Grid {
                    id: gimbalGridsagri
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: false // Hidden for all modes
                    // Horizontal spacing (between columns)
                    columnSpacing: 30
                    // Vertical spacing (between rows)
                    rowSpacing: 30

                    Repeater {
                        model: agrigimbalModels
                        delegate: agriDelegates
                    }
                }

                // Header
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Select Gimbal Type"
                    color: app_color
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.weight: Font.DemiBold
                    bottomPadding: 20
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"?false:true
                }

                // Grid layout for gimbal models
                Grid {
                    id: gimbalGrid
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"?false:true
                    // Horizontal spacing (between columns)
                    columnSpacing: 30
                    // Vertical spacing (between rows)
                    rowSpacing: 30

                    Repeater {
                        model: gimbalModels
                        delegate: gimbalDelegate
                    }
                }


                // Header
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Select Gimbal with Camera"
                    color: app_color
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.weight: Font.DemiBold
                    bottomPadding: 20
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") !== "Agri"
                }

                // Grid layout for camera gimbals
                Grid {
                    id: gimbalGrid1
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") !== "Agri"
                    // Horizontal spacing (between columns)
                    columnSpacing: 30
                    // Vertical spacing (between rows)
                    rowSpacing: 30

                    Repeater {
                        model: gimbalModels1
                        delegate: gimbalDelegate1
                    }
                }

                // Header
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Select Camera"
                    color: app_color
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.weight: Font.DemiBold
                    bottomPadding: 20
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") !== "Agri"
                }

                // Grid layout for agriall
                Grid {
                    id: gimbalGrid2
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage") !== "Agri"


                    // Horizontal spacing (between columns)
                    columnSpacing: 30
                    // Vertical spacing (between rows)
                    rowSpacing: 30

                    Repeater {
                        model: gimbalModels2
                        delegate: gimbalDelegate2
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: " "
                    color: "white"
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.bold: true
                }
            }
        }
    }

    // Common delegate components
    Component {
        id: agriDelegate

        Item {
            width: cardWidth
            height: cardHeight

            // Main card
            Rectangle {
                id: card
                anchors.fill: parent
                color: "white"//modelData.color
                radius: 10
                border.color: agriall === index ? "#bb86fc" : "#e1bee7"
                border.width: agriall === index ? 3 : 1

                Rectangle {
                    id: shadowSource
                    anchors.fill: parent
                    radius: 10//dp(4)
                    color: "white"
                    visible: false
                    anchors.margins: 2

                }

                MultiEffect {
                    anchors.fill: shadowSource
                    source: shadowSource

                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowHorizontalOffset: 5
                    shadowVerticalOffset: 5
                    shadowColor: app_color   // soft black
                }

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: agriall === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "#bb86fc"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5


                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qmlimages/check.svg"
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                    }
                }

                // Inner shadow effect when selected
                Rectangle {
                    visible: agriall === index
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(1,1,1,0.2)
                    border.width: 2
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    width: parent.width

                    Image {
                        source: modelData.icon
                        width: 40
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: modelData.text
                        color: "#000000"
                        font.bold: true
                        font.pixelSize: ScreenTools.smallFontPixelSize
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Scale animation when selected
            transform: Scale {
                origin.x: card.width/2
                origin.y: card.height/2
                xScale: agriall === index ? 1.03 : 1.0
                yScale: agriall === index ? 1.03 : 1.0
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    agriall = index
                    agrigimbal = -1
                    cameragimbal = -1
                    cameragimbal1 = -1
                    cameragimbal2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", agriall)
                    updateGimbalSelection1(agriall)
                    QGroundControl.saveGlobalSetting("agrigimbal", -1)
                    QGroundControl.saveGlobalSetting("agriall", agriall)
                    QGroundControl.saveGlobalSetting("cameragimbal", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // if (activeVehicle) {
                    //     cameragimbal = index
                    //     cameragimbal1 = -1
                    //     cameragimbal2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", cameragimbal)
                    //     updateGimbalSelection(cameragimbal)
                    //     QGroundControl.saveGlobalSetting("cameragimbal", cameragimbal)
                    //     QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // } else {
                    //     mainWindow.showToast("Device not connected")
                    // }
                }
            }
        }
    }

    // Common delegate components
    Component {
        id: agriDelegates

        Item {
            width: cardWidth
            height: cardHeight

            // Main card
            Rectangle {
                id: card
                anchors.fill: parent
                color: "white"//modelData.color
                radius: 10
                border.color: agrigimbal === index ? "#bb86fc" : "#e1bee7"
                border.width: agrigimbal === index ? 3 : 1

                Rectangle {
                    id: shadowSource
                    anchors.fill: parent
                    radius: 10//dp(4)
                    color: "white"
                    visible: false
                    anchors.margins: 2

                }

                MultiEffect {
                    anchors.fill: shadowSource
                    source: shadowSource

                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowHorizontalOffset: 5
                    shadowVerticalOffset: 5
                    shadowColor: app_color   // soft black
                }

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: agrigimbal === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "#bb86fc"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qmlimages/check.svg"
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                    }
                }

                // Inner shadow effect when selected
                Rectangle {
                    visible: agrigimbal === index
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(1,1,1,0.2)
                    border.width: 2
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Image {
                        source: modelData.icon
                        width: Math.min(parent.width * 0.5, 50)
                        height: Math.min(parent.width * 0.5, 50)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: modelData.text
                        color: "#000000"
                        font.bold: true
                        font.pixelSize: ScreenTools.smallFontPixelSize
                        width: parent.width * 0.9
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Scale animation when selected
            transform: Scale {
                origin.x: card.width/2
                origin.y: card.height/2
                xScale: agrigimbal === index ? 1.03 : 1.0
                yScale: agrigimbal === index ? 1.03 : 1.0
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {

                    agriall = -1
                    agrigimbal = index
                    cameragimbal = 1
                    cameragimbal1 = -1
                    cameragimbal2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", agrigimbal)
                    updateGimbalSelection1(agrigimbal+2)
                    QGroundControl.saveGlobalSetting("agriall", -1)
                    QGroundControl.saveGlobalSetting("agrigimbal", 1)
                    QGroundControl.saveGlobalSetting("cameragimbal", cameragimbal)
                    QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // if (activeVehicle) {
                    //     cameragimbal = index
                    //     cameragimbal1 = -1
                    //     cameragimbal2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", cameragimbal)
                    //     updateGimbalSelection(cameragimbal)
                    //     QGroundControl.saveGlobalSetting("cameragimbal", cameragimbal)
                    //     QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // } else {
                    //     mainWindow.showToast("Device not connected")
                    // }
                }
            }
        }
    }

    // Common delegate components
    Component {
        id: gimbalDelegate

        Item {
            width: cardWidth
            height: cardHeight

            // Main card
            Rectangle {
                id: card
                anchors.fill: parent
                color: "white"//modelData.color
                radius: 10
                border.color: cameragimbal === index ? "#bb86fc" : "#e1bee7"
                border.width: cameragimbal === index ? 3 : 1

                Rectangle {
                    id: shadowSource
                    anchors.fill: parent
                    radius: 10//dp(4)
                    color: "white"
                    visible: false
                    anchors.margins: 2

                }

                MultiEffect {
                    anchors.fill: shadowSource
                    source: shadowSource

                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowHorizontalOffset: 5
                    shadowVerticalOffset: 5
                    shadowColor: app_color   // soft black
                }

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: cameragimbal === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "#bb86fc"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qmlimages/check.svg"
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                    }
                }

                // Inner shadow effect when selected
                Rectangle {
                    visible: cameragimbal === index
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(1,1,1,0.2)
                    border.width: 2
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Image {
                        source: modelData.icon
                        width: Math.min(parent.width * 0.5, 50)
                        height: Math.min(parent.width * 0.5, 50)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: modelData.text
                        color: "#000000"
                        font.bold: true
                        font.pixelSize: ScreenTools.smallFontPixelSize
                        width: parent.width * 0.9
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Scale animation when selected
            transform: Scale {
                origin.x: card.width/2
                origin.y: card.height/2
                xScale: cameragimbal === index ? 1.03 : 1.0
                yScale: cameragimbal === index ? 1.03 : 1.0
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    agriall = -1
                    agrigimbal= -1
                    cameragimbal = index
                    cameragimbal1 = -1
                    cameragimbal2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", cameragimbal)
                    updateGimbalSelection(cameragimbal)
                    QGroundControl.saveGlobalSetting("agriall", -1)
                    QGroundControl.saveGlobalSetting("agrigimbal", agrigimbal)
                    QGroundControl.saveGlobalSetting("cameragimbal", cameragimbal)
                    QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // if (activeVehicle) {
                    //     cameragimbal = index
                    //     cameragimbal1 = -1
                    //     cameragimbal2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", cameragimbal)
                    //     updateGimbalSelection(cameragimbal)
                    //     QGroundControl.saveGlobalSetting("cameragimbal", cameragimbal)
                    //     QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // } else {
                    //     mainWindow.showToast("Device not connected")
                    // }
                }
            }
        }
    }

    Component {
        id: gimbalDelegate1

        Item {
            width: cardWidth
            height: cardHeight

            // Main card
            Rectangle {
                id: card1
                anchors.fill: parent
                color: "white"//modelData.color
                radius: 10
                border.color: cameragimbal1 === index ? "#bb86fc" : "#e1bee7"
                border.width: cameragimbal1 === index ? 3 : 1

                Rectangle {
                    id: shadowSource
                    anchors.fill: parent
                    radius: 10//dp(4)
                    color: "white"
                    visible: false
                    anchors.margins: 2

                }

                MultiEffect {
                    anchors.fill: shadowSource
                    source: shadowSource

                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowHorizontalOffset: 5
                    shadowVerticalOffset: 5
                    shadowColor: app_color   // soft black
                }

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: cameragimbal1 === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "#bb86fc"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qmlimages/check.svg"
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Image {
                        source: modelData.icon
                        width: Math.min(parent.width * 0.5, 50)
                        height: Math.min(parent.width * 0.5, 50)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: modelData.text
                        color: "#000000"
                        font.bold: true
                        font.pixelSize: ScreenTools.smallFontPixelSize
                        width: parent.width * 0.9
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    agriall = -1
                    agrigimbal = -1
                    cameragimbal1 = index
                    cameragimbal = -1
                    cameragimbal2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", cameragimbal1+4)
                    updateGimbalSelection(cameragimbal1+4)
                    QGroundControl.saveGlobalSetting("agriall", -1)
                    QGroundControl.saveGlobalSetting("agrigimbal", agrigimbal)
                    QGroundControl.saveGlobalSetting("cameragimbal", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal1", cameragimbal1)
                    QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // if (activeVehicle) {
                    //     cameragimbal1 = index
                    //     cameragimbal = -1
                    //     cameragimbal2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", cameragimbal1+4)
                    //     updateGimbalSelection(cameragimbal1+4)
                    //     QGroundControl.saveGlobalSetting("cameragimbal", -1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal1", cameragimbal1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal2", -1)
                    // } else {
                    //     mainWindow.showToast("Device not connected")
                    // }
                }
            }
        }
    }

    Component {
        id: gimbalDelegate2

        Item {
            width: cardWidth
            height: cardHeight

            // Main card
            Rectangle {
                id: card2
                anchors.fill: parent
                color: "white"//modelData.color
                radius: 10
                border.color: cameragimbal2 === index ? "#bb86fc" : "#e1bee7"
                border.width: cameragimbal2 === index ? 3 : 1

                Rectangle {
                    id: shadowSource
                    anchors.fill: parent
                    radius: 10//dp(4)
                    color: "white"
                    visible: false
                    anchors.margins: 2

                }

                MultiEffect {
                    anchors.fill: shadowSource
                    source: shadowSource

                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowHorizontalOffset: 5
                    shadowVerticalOffset: 5
                    shadowColor: app_color   // soft black
                }

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: cameragimbal2 === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "#bb86fc"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5

                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qmlimages/check.svg"
                        width: 12
                        height: 12
                        sourceSize: Qt.size(12, 12)
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Image {
                        source: modelData.icon
                        width: Math.min(parent.width * 0.5, 50)
                        height: Math.min(parent.width * 0.5, 50)
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: modelData.text
                        color: "grey"
                        font.bold: true
                        font.pixelSize: ScreenTools.smallFontPixelSize
                        width: parent.width * 0.9
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    agriall = -1
                    agrigimbal = -1
                    cameragimbal2 = index
                    cameragimbal = -1
                    cameragimbal1 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", cameragimbal2+7)
                    updateGimbalSelection(cameragimbal2+7)
                    QGroundControl.saveGlobalSetting("agriall", -1)
                    QGroundControl.saveGlobalSetting("agrigimbal", agrigimbal)
                    QGroundControl.saveGlobalSetting("cameragimbal", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    QGroundControl.saveGlobalSetting("cameragimbal2", cameragimbal2)
                    // if (activeVehicle) {
                    //     cameragimbal2 = index
                    //     cameragimbal = -1
                    //     cameragimbal1 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", cameragimbal2+7)
                    //     updateGimbalSelection(cameragimbal2+7)
                    //     QGroundControl.saveGlobalSetting("cameragimbal", -1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal1", -1)
                    //     QGroundControl.saveGlobalSetting("cameragimbal2", cameragimbal2)
                    // } else {
                    //     mainWindow.showToast("Device not connected")
                    // }
                }
            }
        }
    }

    function updateGimbalSelection(cameragimbal) {
        console.log("selected index", cameragimbal)

        if(activeVehicle){
            switch (cameragimbal) {
            case 0:
                QGroundControl.saveGlobalSetting("tab", "None")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 1:
                QGroundControl.saveGlobalSetting("tab", "Servo Gimbal")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 2:
                QGroundControl.saveGlobalSetting("tab", "STorM32 Gimbal")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 3:
                QGroundControl.saveGlobalSetting("tab", "Brushless PWM Gimbal")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 4:
                QGroundControl.saveGlobalSetting("tab", "CADDX Gimbals")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 5:
                QGroundControl.saveGlobalSetting("tab", "Gremsy Gimbals")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 6:
                QGroundControl.saveGlobalSetting("tab", "Xacti Gimbals")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 7:
                QGroundControl.saveGlobalSetting("tab", "SERVO")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 8:
                QGroundControl.saveGlobalSetting("tab", "Relay")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            }

        }else{
            mainWindow.showToastMessage("Drone Not Connected");
        }


    }


    function updateGimbalSelection1(cameragimbal) {
        console.log("selected index", cameragimbal)

        if(activeVehicle){
            switch (cameragimbal) {
            case 0:
                QGroundControl.saveGlobalSetting("tab", "None")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 1:
                QGroundControl.saveGlobalSetting("tab", "Spray")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 2:
                QGroundControl.saveGlobalSetting("tab", "Servo Gimbal")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 3:
                QGroundControl.saveGlobalSetting("tab", "STorM32 Gimbal")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            case 4:
                QGroundControl.saveGlobalSetting("tab", "Brushless PWM Gimbal")
                mainWindow.sideDrawer1("BasicParametersList.qml")
                break
            }

        }else{
            mainWindow.showToastMessage("Drone Not Connected");
        }


    }


}
