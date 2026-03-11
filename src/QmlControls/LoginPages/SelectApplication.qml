import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: selectAppRoot
    anchors.fill: parent
    property color app_color: "#4a2c6d"
    property color accent_color: "#4a2c6d"
    
    signal backClicked()
    signal appSelected()

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 60

    Rectangle {
        anchors.fill: parent
        color: "#F8F9FD"

        /* ================= PREMIUM HEADER ================= */
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(70, parent.height * 0.1)
            color: app_color
            z: 10

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.darker(app_color, 1.1) }
                    GradientStop { position: 1.0; color: app_color }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: backMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(255, 255, 255, 0.1)
                    QGCColoredImage {
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                        width: 20; height: 20; color: "white"
                        anchors.centerIn: parent
                    }
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectAppRoot.backClicked()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Select Mission Profile"
                    font.pointSize: ScreenTools.mediumFontPointSize
                    font.bold: true; color: "white"
                    font.family: "Outfit"
                }
            }
        }

        /* ================= CENTERED ADAPTABLE CONTENT ================= */
        Item {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            ColumnLayout {
                id: contentColumn
                width: Math.min(isSmallScreen ? parent.width - 40 : 900, parent.width - 40)
                anchors.centerIn: parent
                spacing: 40

                property int selectedIndex: -1
                property var buttonModel: [
                    { label: "Camera", image: "qrc:/qmlimages/NewImages/camerabg.png" },
                    { label: "Agri", image: "qrc:/qmlimages/NewImages/agribg.png" },
                    { label: "Mapping", image: "qrc:/qmlimages/NewImages/mapbg.png" }
                ]

                Component.onCompleted: {
                    var saved = QGroundControl.loadGlobalSetting("loadpage", "Camera").trim()
                    for (var i = 0; i < buttonModel.length; i++) {
                        if (buttonModel[i].label === saved) {
                            selectedIndex = i
                            break
                        }
                    }
                }

                // Grid Layout
                GridLayout {
                    id: cardsGrid
                    Layout.fillWidth: true
                    columns: isSmallScreen ? 1 : 3
                    columnSpacing: 25
                    rowSpacing: 25

                    Repeater {
                        model: contentColumn.buttonModel
                        
                        Rectangle {
                            id: cardContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: isSmallScreen ? 120 : 260
                            radius: 16
                            color: "white"
                            border.color: contentColumn.selectedIndex === index ? accent_color : "#E2E8F0"
                            border.width: contentColumn.selectedIndex === index ? 3 : 1
                            clip: true

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: contentColumn.selectedIndex === index ? Qt.rgba(74, 44, 109, 0.2) : Qt.rgba(0,0,0,0.05)
                                shadowBlur: 0.8
                                shadowVerticalOffset: 4
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Image { 
                                        anchors.fill: parent
                                        source: modelData.image
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                    
                                    // Selection Indicator (Checkmark Badge)
                                    Rectangle {
                                        width: 28; height: 28; radius: 14
                                        color: accent_color
                                        anchors.top: parent.top; anchors.right: parent.right
                                        anchors.margins: 10
                                        visible: contentColumn.selectedIndex === index
                                        z: 10
                                        QGCColoredImage {
                                            source: "qrc:/InstrumentValueIcons/checkmark.svg"
                                            width: 14; height: 14; color: "white"
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    color: "white"
                                    Text {
                                        text: modelData.label
                                        anchors.centerIn: parent
                                        font.pointSize: ScreenTools.mediumFontPointSize
                                        font.bold: true
                                        color: contentColumn.selectedIndex === index ? accent_color : "#333333"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: contentColumn.selectedIndex = index
                            }
                        }
                    }
                }

                // Action Button
                Button {
                    id: activateBtn
                    text: "CONFIRM"
                    Layout.preferredWidth: isSmallScreen ? parent.width : 300
                    Layout.preferredHeight: 50
                    Layout.alignment: Qt.AlignHCenter
                    enabled: contentColumn.selectedIndex !== -1
                    
                    background: Rectangle { 
                        radius: 25
                        color: parent.enabled ? (parent.pressed ? Qt.darker(accent_color, 1.1) : accent_color) : "#D1D5DB"
                    }
                    
                    contentItem: Text { 
                        text: activateBtn.text; color: "white"; font.bold: true; font.pointSize: ScreenTools.defaultFontPointSize
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter 
                    }

                    onClicked: {
                        QGroundControl.saveGlobalSetting("loadpage", contentColumn.buttonModel[contentColumn.selectedIndex].label)
                        if (MapGlobals.rootWindow) MapGlobals.rootWindow.showToastMessage(contentColumn.buttonModel[contentColumn.selectedIndex].label + " Mode Selected")
                        selectAppRoot.appSelected()
                    }
                }
            }
        }
    }
}
