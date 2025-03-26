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

ApplicationWindow {
    id:             mainWindow
    minimumWidth:   ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true
property string planType: "Standard"
    function showTool(toolTitle, toolSource, toolIcon) {
        toolDrawer.backIcon     =  "/qmlimages/PaperPlane.svg"
        toolDrawer.toolTitle    = toolTitle
        toolDrawer.toolSource   = toolSource
        toolDrawer.toolIcon     = toolIcon
        toolDrawer.visible      = true
    }
    StackView {
            id: stackView
            anchors.fill: parent
            initialItem: firstScreen
        }
    function clearScreen() {
            console.log("Clearing screen...");
            pageLoader.source = ""; // Remove the loaded screen
        }

    Keys.onBackPressed: {
            console.log("Back button pressed!");
            if (pageLoader.source !== "") {
                clearScreen(); // Clear values and go back to the main screen
                event.accepted = true; // Prevent app from closing
            } else {
                Qt.quit(); // Exit the application if no page is loaded
            }
        }
property var _linkManager:          QGroundControl.linkManager
    property alias toolSource:  pageLoader.source
    Rectangle {
        color: "lightgray"
        anchors.fill: parent


        Rectangle {
                    id: topBar
                    color: "#f0f0f0"
                    height: 50
                    width: parent.width
                    anchors.top: parent.top

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Item { Layout.fillWidth: true }  // Pushes profile icon to the right

                        Image {
                            id: profileIcon
                            width: 32
                            height: 32
                            source: "qrc:/InstrumentValueIcons/user.svg"  // Replace with your profile icon path
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {

                                    stackView.push(Qt.createComponent("profilepage.qml"))

                                    // if (pageLoader.status === Loader.Null || pageLoader.status === Loader.Error) {
                                    //                     console.log("Loading MainScreen.qml...");
                                    //     clearScreen();
                                    //     console.log("Profile icon clicked")
                                    //     //profileMenu.open()
                                    //     pageLoader.source = "profilepage.qml";
                                    //                 } else {
                                    //     clearScreen();
                                    //                     console.log("Screen already loaded!");
                                    //                 }

                                }
                            }
                        }

                        // Menu {
                        //     id: profileMenu
                        //     MenuItem { text: "View Profile"; onTriggered: console.log("View Profile clicked") }
                        //     MenuItem { text: "Settings"; onTriggered: console.log("Settings clicked") }
                        //     MenuItem { text: "Logout"; onTriggered: Qt.quit() }
                        // }
                    }
                }

        ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 20  // Space between image and text

                    Image {
                            id: droneImage
                            width: 80
                            height: 80
                            //<file alias="NEWIMAGE/Droneimage">src/Newimages/droneImage.png</file>
                            source: "qrc:/InstrumentValueIcons/drone.svg"
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            Layout.alignment: Qt.AlignHCenter
                        }


                    Text {
                        text: "Welcome to the new screen!"
                        font.pixelSize: 24
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
        RowLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottomMargin: 20
                spacing: 20

        Button {
            text: "  Bluetooth  "
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 40   // Left padding
                        anchors.rightMargin: 40  // Right padding
                        anchors.topMargin: 10    // Top padding
                        anchors.bottomMargin: 10
            font.bold: true
            font.pixelSize: 16
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"  // Set text color
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.leftMargin: 40   // Left padding
                            anchors.rightMargin: 40  // Right padding
                            anchors.topMargin: 10    // Top padding
                            anchors.bottomMargin: 10 // Bottom padding
            }

            background: Rectangle {
                color: "#007AFF"  // Blue color (iOS-style button)
                radius: 20  // Curved button
                border.color: "#005BBB"  // Border color
                border.width: 2
            }

            onClicked: {
                var editingConfig = _linkManager.createConfiguration(
                    ScreenTools.isSerialAvailable ? LinkConfiguration.TypeSerial : LinkConfiguration.TypeUdp, ""
                );
                linkDialogComponent.createObject(mainWindow, { editingConfig: editingConfig, originalConfig: null }).open();
            }
        }


        Item { Layout.fillWidth: true }
        Button {
            text: "  Plan  "
            Layout.rightMargin: 10
            font.bold: true
            font.pixelSize: 16
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"  // Set text color
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.leftMargin: 40   // Left padding
                            anchors.rightMargin: 40  // Right padding
                            anchors.topMargin: 10    // Top padding
                            anchors.bottomMargin: 10 // Bottom padding
            }

            background: Rectangle {
                color: "#007AFF"  // Blue color (iOS-style button)
                radius: 20  // Curved button
                border.color: "#005BBB"  // Border color
                border.width: 2
            }

            onClicked: {
                if (pageLoader.status === Loader.Null || pageLoader.status === Loader.Error) {
                                    console.log("Loading MainScreen.qml...");
                    clearScreen();
                     pageLoader.setSource("MainRootWindow.qml", { planType: "Plan" });
                                } else {
                    clearScreen();
                                    console.log("Screen already loaded!");
                                }
                //showTool(qsTr("Main Screen"), "MainRootWindow.qml", "/res/QGCLogoWhite")            }
        }
        }

        Button {
            text: "  Start  "
            Layout.rightMargin: 40
            font.bold: true
            font.pixelSize: 16
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"  // Set text color
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.leftMargin: 40   // Left padding
                            anchors.rightMargin: 40  // Right padding
                            anchors.topMargin: 10    // Top padding
                            anchors.bottomMargin: 10 // Bottom padding
            }

            background: Rectangle {
                color: "#007AFF"  // Blue color (iOS-style button)
                radius: 20  // Curved button
                border.color: "#005BBB"  // Border color
                border.width: 2
            }

            onClicked: {
                if (pageLoader.status === Loader.Null || pageLoader.status === Loader.Error) {
                                    console.log("Loading MainScreen.qml...");
                    clearScreen();
                                    pageLoader.source = "MainRootWindow.qml";
                                } else {
                    clearScreen();
                                    console.log("Screen already loaded!");
                                }
                //showTool(qsTr("Main Screen"), "MainRootWindow.qml", "/res/QGCLogoWhite")
            }
        }

}

        Loader {
                id: pageLoader
                anchors.left:   parent.left
                anchors.right:  parent.right
                anchors.top:    toolDrawerToolbar.bottom
                anchors.bottom: parent.bottom

                Connections {
                    target:                 pageLoader.item
                    ignoreUnknownSignals:   true
                    onPopout:               toolDrawer.visible = false
                }
            }
        Component {
            id: linkDialogComponent

            QGCPopupDialog {
                title:          originalConfig ? qsTr("Edit Link") : qsTr("Add New Link")
                buttons:        Dialog.Save | Dialog.Cancel
                acceptAllowed:  nameField.text !== ""

                property var originalConfig
                property var editingConfig

                onAccepted: {
                    linkSettingsLoader.item.saveSettings()
                    editingConfig.name = nameField.text
                    if (originalConfig) {
                        _linkManager.endConfigurationEditing(originalConfig, editingConfig)
                    } else {
                        // If it was edited, it's no longer "dynamic"
                        editingConfig.dynamic = false
                        _linkManager.endCreateConfiguration(editingConfig)
                    }
                }

                onRejected: _linkManager.cancelConfigurationEditing(editingConfig)

                ColumnLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    RowLayout {
                        Layout.fillWidth:   true
                        spacing:            ScreenTools.defaultFontPixelWidth

                        QGCLabel { text: qsTr("Name") }
                        QGCTextField {
                            id:                 nameField
                            Layout.fillWidth:   true
                            text:               editingConfig.name
                            placeholderText:    qsTr("Enter name")
                        }
                    }

                    QGCCheckBoxSlider {
                        Layout.fillWidth:   true
                        text:               qsTr("Automatically Connect on Start")
                        checked:            editingConfig.autoConnect
                        onCheckedChanged:   editingConfig.autoConnect = checked
                    }

                    QGCCheckBoxSlider {
                        Layout.fillWidth:   true
                        text:               qsTr("High Latency")
                        checked:            editingConfig.highLatency
                        onCheckedChanged:   editingConfig.highLatency = checked
                    }

                    LabelledComboBox {
                        label:                  qsTr("Type")
                        enabled:                originalConfig == null
                        model:                  _linkManager.linkTypeStrings
                        Component.onCompleted:  comboBox.currentIndex = editingConfig.linkType

                        onActivated: (index) => {
                            if (index !== editingConfig.linkType) {
                                // Save current name
                                var name = nameField.text
                                // Create new link configuration
                                editingConfig = _linkManager.createConfiguration(index, name)
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
