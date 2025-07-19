import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools

Item {
    id:     root
    anchors.fill: parent


property int selectedGimbalIndexs: QGroundControl.loadGlobalSetting("cameras","0")
    property int selectedGimbalIndex: QGroundControl.loadGlobalSetting("camera","-1")
    property int selectedGimbalIndex1: QGroundControl.loadGlobalSetting("camera1","-1")
    property int selectedGimbalIndex2: QGroundControl.loadGlobalSetting("camera2","-1")
    property var  activeVehicle:    QGroundControl.multiVehicleManager.activeVehicle

    // Calculate card width to show exactly 3 per row with spacing
    readonly property int cardsPerRow: 4
    readonly property int horizontalMargin: 50
    readonly property int columnSpacing: 20
    readonly property int cardWidth: (parent.width *0.98 - horizontalMargin - (columnSpacing * (cardsPerRow - 1))) / cardsPerRow
    readonly property int cardHeight: cardWidth // Keep cards square


    property var agri: [
        { text: "All", icon: "qrc:/qmlimages/NoGimbal.svg", color: "#2c3e50" },
        { text: "SPARY", icon: "qrc:/qmlimages/CADDX.svg", color: "#8e44ad" }
    ]
    property var agrigimbalModels: [
        { text: "Servo Gimbal", icon: "qrc:/qmlimages/ServoGimbal.svg", color: "#3498db" },
        { text: "STorM32", icon: "qrc:/qmlimages/STorM32Gimbal.svg", color: "#9b59b6" },
        { text: "Brushless PWM", icon: "qrc:/qmlimages/BrushlessGimbal.svg", color: "#e74c3c" }
    ]
    property var gimbalModels: [
        { text: "All", icon: "qrc:/qmlimages/NoGimbal.svg", color: "#2c3e50" },
        { text: "Servo Gimbal", icon: "qrc:/qmlimages/ServoGimbal.svg", color: "#3498db" },
        { text: "STorM32", icon: "qrc:/qmlimages/STorM32Gimbal.svg", color: "#9b59b6" },
        { text: "Brushless PWM", icon: "qrc:/qmlimages/BrushlessGimbal.svg", color: "#e74c3c" }
    ]

    property var gimbalModels1: [
        { text: "CADDX", icon: "qrc:/qmlimages/CADDX.svg", color: "#1abc9c" },
        { text: "Gremsy", icon: "qrc:/qmlimages/Gremsy.svg", color: "#f39c12" },
        { text: "Xacti", icon: "qrc:/qmlimages/Xacti.svg", color: "#d35400" }
    ]

    property var gimbalModels2: [
        { text: "SERVO", icon: "qrc:/qmlimages/CADDX.svg", color: "#27ae60" },
        { text: "Relay", icon: "qrc:/qmlimages/CADDX.svg", color: "#c0392b" }
    ]

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            z: -10
            color: "#1b1c3e"
        }
        // ---- Curved Gradient Background ----
        Canvas {
            anchors.fill: parent
            z: -1
            opacity: 0.95
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                // 🎨 Create diagonal gradient
                var gradient = ctx.createLinearGradient(0, 0, width, height)
                gradient.addColorStop(0, "#14163C")
                gradient.addColorStop(1, "#6A85FB")
                ctx.fillStyle = gradient

                // 🌀 Create a curved path from top-left to bottom-right
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.quadraticCurveTo(width * 0.4, height * 0.1, width, height * 0.9)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: parent.width * 0.7
            height: parent.height * 0.9
            radius: width * 0.5
            rotation: 30
            opacity: 0.95
            anchors.rightMargin: -width * 0.25
            anchors.bottomMargin: -height * 0.2
            z: -1

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#14163C" } // Deep indigo
                GradientStop { position: 1.0; color: "#6A85FB" } // Blue gradient
            }
        }



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
                    text: "Agri Sparying"
                    color: "white"
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.bold: true
                    bottomPadding: 15
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?true:false
                }

                // Grid layout for gimbal models
                Grid {
                    id: gimbalGrids
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?true:false
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
                    color: "white"
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.bold: true
                    bottomPadding: 15
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?true:false
                }

                // Grid layout for gimbal models
                Grid {
                    id: gimbalGridsagri
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?true:false
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
                    color: "white"
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.bold: true
                    bottomPadding: 15
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?false:true
                }

                // Grid layout for gimbal models
                Grid {
                    id: gimbalGrid
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
                    visible: QGroundControl.loadGlobalSetting("loadpage","loadpage")==="agri"?false:true
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
                    text: "Select Gimbal with camera"
                    color: "white"
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5
                    font.bold: true
                }

                // Grid layout for camera gimbals
                Grid {
                    id: gimbalGrid1
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing
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
                    text: "Select camera"
                    color: "white"
                    font.pixelSize: ScreenTools.defaultFontPixelSize * 1.5














                    font.bold: true
                }

                // Grid layout for cameras
                Grid {
                    id: gimbalGrid2
                    width: parent.width - horizontalMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: cardsPerRow
                    spacing: columnSpacing


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
                color: modelData.color
                radius: 10
                border.color: selectedGimbalIndexs === index ? "limegreen" : "transparent"
                border.width: selectedGimbalIndexs === index ? 3 : 0

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: selectedGimbalIndexs === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "limegreen"
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
                    visible: selectedGimbalIndexs === index
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
                        color: "white"
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
                xScale: selectedGimbalIndexs === index ? 1.03 : 1.0
                yScale: selectedGimbalIndexs === index ? 1.03 : 1.0
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedGimbalIndexs = index
                    selectedGimbalIndex = -1
                    selectedGimbalIndex1 = -1
                    selectedGimbalIndex2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", selectedGimbalIndexs)
                    updateGimbalSelection(selectedGimbalIndexs)
                    QGroundControl.saveGlobalSetting("cameras", selectedGimbalIndexs)
                    QGroundControl.saveGlobalSetting("camera", -1)
                    QGroundControl.saveGlobalSetting("camera1", -1)
                    QGroundControl.saveGlobalSetting("camera2", -1)
                    // if (activeVehicle) {
                    //     selectedGimbalIndex = index
                    //     selectedGimbalIndex1 = -1
                    //     selectedGimbalIndex2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", selectedGimbalIndex)
                    //     updateGimbalSelection(selectedGimbalIndex)
                    //     QGroundControl.saveGlobalSetting("camera", selectedGimbalIndex)
                    //     QGroundControl.saveGlobalSetting("camera1", -1)
                    //     QGroundControl.saveGlobalSetting("camera2", -1)
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
                color: modelData.color
                radius: 10
                border.color: selectedGimbalIndex === index ? "limegreen" : "transparent"
                border.width: selectedGimbalIndex === index ? 3 : 0

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: selectedGimbalIndex === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "limegreen"
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
                    visible: selectedGimbalIndex === index
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
                        color: "white"
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
                xScale: selectedGimbalIndex === index ? 1.03 : 1.0
                yScale: selectedGimbalIndex === index ? 1.03 : 1.0
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedGimbalIndexs = -1
                    selectedGimbalIndex = index
                    selectedGimbalIndex1 = -1
                    selectedGimbalIndex2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", selectedGimbalIndex)
                    updateGimbalSelection(selectedGimbalIndex)
                    QGroundControl.saveGlobalSetting("cameras", -1)
                    QGroundControl.saveGlobalSetting("camera", selectedGimbalIndex)
                    QGroundControl.saveGlobalSetting("camera1", -1)
                    QGroundControl.saveGlobalSetting("camera2", -1)
                    // if (activeVehicle) {
                    //     selectedGimbalIndex = index
                    //     selectedGimbalIndex1 = -1
                    //     selectedGimbalIndex2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", selectedGimbalIndex)
                    //     updateGimbalSelection(selectedGimbalIndex)
                    //     QGroundControl.saveGlobalSetting("camera", selectedGimbalIndex)
                    //     QGroundControl.saveGlobalSetting("camera1", -1)
                    //     QGroundControl.saveGlobalSetting("camera2", -1)
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
                color: modelData.color
                radius: 10
                border.color: selectedGimbalIndex === index ? "limegreen" : "transparent"
                border.width: selectedGimbalIndex === index ? 3 : 0

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: selectedGimbalIndex === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "limegreen"
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
                    visible: selectedGimbalIndex === index
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
                        color: "white"
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
                xScale: selectedGimbalIndex === index ? 1.03 : 1.0
                yScale: selectedGimbalIndex === index ? 1.03 : 1.0
                Behavior on xScale { NumberAnimation { duration: 100 } }
                Behavior on yScale { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedGimbalIndexs = -1
                    selectedGimbalIndex = index
                    selectedGimbalIndex1 = -1
                    selectedGimbalIndex2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", selectedGimbalIndex)
                    updateGimbalSelection(selectedGimbalIndex)
                    QGroundControl.saveGlobalSetting("cameras", -1)
                    QGroundControl.saveGlobalSetting("camera", selectedGimbalIndex)
                    QGroundControl.saveGlobalSetting("camera1", -1)
                    QGroundControl.saveGlobalSetting("camera2", -1)
                    // if (activeVehicle) {
                    //     selectedGimbalIndex = index
                    //     selectedGimbalIndex1 = -1
                    //     selectedGimbalIndex2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", selectedGimbalIndex)
                    //     updateGimbalSelection(selectedGimbalIndex)
                    //     QGroundControl.saveGlobalSetting("camera", selectedGimbalIndex)
                    //     QGroundControl.saveGlobalSetting("camera1", -1)
                    //     QGroundControl.saveGlobalSetting("camera2", -1)
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
                color: modelData.color
                radius: 10
                border.color: selectedGimbalIndex1 === index ? "limegreen" : "transparent"
                border.width: selectedGimbalIndex1 === index ? 3 : 0

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: selectedGimbalIndex1 === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "limegreen"
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
                        color: "white"
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
                    selectedGimbalIndexs = -1
                    selectedGimbalIndex1 = index
                    selectedGimbalIndex = -1
                    selectedGimbalIndex2 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", selectedGimbalIndex1+4)
                    updateGimbalSelection(selectedGimbalIndex1+4)
                    QGroundControl.saveGlobalSetting("cameras", -1)
                    QGroundControl.saveGlobalSetting("camera", -1)
                    QGroundControl.saveGlobalSetting("camera1", selectedGimbalIndex1)
                    QGroundControl.saveGlobalSetting("camera2", -1)
                    // if (activeVehicle) {
                    //     selectedGimbalIndex1 = index
                    //     selectedGimbalIndex = -1
                    //     selectedGimbalIndex2 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", selectedGimbalIndex1+4)
                    //     updateGimbalSelection(selectedGimbalIndex1+4)
                    //     QGroundControl.saveGlobalSetting("camera", -1)
                    //     QGroundControl.saveGlobalSetting("camera1", selectedGimbalIndex1)
                    //     QGroundControl.saveGlobalSetting("camera2", -1)
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
                color: modelData.color
                radius: 10
                border.color: selectedGimbalIndex2 === index ? "limegreen" : "transparent"
                border.width: selectedGimbalIndex2 === index ? 3 : 0

                // Selection indicator (top-right corner)
                Rectangle {
                    visible: selectedGimbalIndex2 === index
                    width: 20
                    height: 20
                    radius: 10
                    color: "limegreen"
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
                        color: "white"
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
                    selectedGimbalIndexs = -1
                    selectedGimbalIndex2 = index
                    selectedGimbalIndex = -1
                    selectedGimbalIndex1 = -1
                    QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    console.log("selectedvalue", selectedGimbalIndex2+7)
                    updateGimbalSelection(selectedGimbalIndex2+7)
                    QGroundControl.saveGlobalSetting("cameras", -1)
                    QGroundControl.saveGlobalSetting("camera", -1)
                    QGroundControl.saveGlobalSetting("camera1", -1)
                    QGroundControl.saveGlobalSetting("camera2", selectedGimbalIndex2)
                    // if (activeVehicle) {
                    //     selectedGimbalIndex2 = index
                    //     selectedGimbalIndex = -1
                    //     selectedGimbalIndex1 = -1
                    //     QGroundControl.saveGlobalSetting("selectedGimbal", modelData.text)
                    //     console.log("selectedvalue", selectedGimbalIndex2+7)
                    //     updateGimbalSelection(selectedGimbalIndex2+7)
                    //     QGroundControl.saveGlobalSetting("camera", -1)
                    //     QGroundControl.saveGlobalSetting("camera1", -1)
                    //     QGroundControl.saveGlobalSetting("camera2", selectedGimbalIndex2)
                    // } else {
                    //     mainWindow.showToast("Device not connected")
                    // }
                }
            }
        }
    }

    function updateGimbalSelection(selectedGimbalIndex) {
        console.log("selected index", selectedGimbalIndex)
        switch (selectedGimbalIndex) {
        case 0:
            QGroundControl.saveGlobalSetting("tab", "None")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 1:
            QGroundControl.saveGlobalSetting("tab", "Servo Gimbal")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 2:
            QGroundControl.saveGlobalSetting("tab", "STorM32 Gimbal")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 3:
            QGroundControl.saveGlobalSetting("tab", "Brushless PWM Gimbal")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 4:
            QGroundControl.saveGlobalSetting("tab", "CADDX Gimbals")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 5:
            QGroundControl.saveGlobalSetting("tab", "Gremsy Gimbals")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 6:
            QGroundControl.saveGlobalSetting("tab", "Xacti Gimbals")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 7:
            QGroundControl.saveGlobalSetting("tab", "SERVO")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        case 8:
            QGroundControl.saveGlobalSetting("tab", "Relay")
            mainWindow.sideDrawer1("BasicParamtersList.qml")
            break
        }
    }

}
