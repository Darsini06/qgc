import QtQuick 2.15

import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette
import QGroundControl.FlightMap
import QGroundControl.Vehicle
import QGroundControl.Controllers
import MapGlobals 1.0


Item {
    anchors.fill: parent

    property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    RadioComponentController {
        id: controller
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: flickable.width
            contentHeight: scrollContent.implicitHeight
            interactive: true

            // // Optional vertical scrollbar
            // ScrollBar.vertical: ScrollBar {
            //     policy: ScrollBar.AsNeeded
            // }

            Column {
                id: scrollContent
                width: flickable.width
                spacing: 20

                MouseArea {
                    width: parent.width
                    height: 40
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activeVehicle) {
                            console.log("device connected")
                            mainWindow.sideDrawer1("RadioComponent.qml")
                        } else {
                            console.log("device not connected")
                            mainWindow.close_dialog_showToast("Device not connected")
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: "RC Calibration"
                            color: "black"
                            Layout.fillWidth: true
                        }
                        Label {
                            text: ">"
                            color: "black"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }

                MouseArea {
                    width: parent.width
                    height: 40
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (activeVehicle) {
                            console.log("Channel Set Clicked")
                            mainWindow.sideDrawer1("qrc:/qml/SettingsPanel/ChannelSet.qml")
                        } else {
                            console.log("device not connected")
                            mainWindow.close_dialog_showToast("Device not connected")
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: "Channel set"
                            color: "black"
                            Layout.fillWidth: true
                        }
                        Label {
                            text: ">"
                            color: "black"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }

            //     RowLayout {
            //         spacing: 10
            //         Label {
            //             text: "SBUS Switch"
            //             color: "black"
            //             Layout.fillWidth: true
            //         }
            //         ComboBox {
            //             model: ["SBUS", "PPM"]
            //         }
            //     }

            //     Label {
            //         text: "Please turn off the SBUS signal after attention"
            //         color: "grey"
            //         wrapMode: Text.Wrap
            //     }

            //     Label {
            //         text: "Fail-Safe"
            //         color: "black"
            //         font.pixelSize: 18
            //     }

            //     RowLayout {
            //         spacing: 10
            //         RadioButton { text: "Back" }
            //         RadioButton { text: "Land" }
            //         RadioButton { text: "Hang" }
            //         RadioButton { text: "Hang-Land" }
            //     }

            //     Label {
            //         text: "Fail-Safe Continue"
            //         color: "black"
            //     }

            //     Switch {
            //         checked: false
            //     }

            //     Button {
            //         text: "Read"
            //         Layout.alignment: Qt.AlignHCenter
            //     }

            }
        }
    }
}




// Item {
//     // width: parent.width
//     // height: parent.height
//     anchors.fill: parent

//     property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

//     RadioComponentController {
//         id:             controller
//     }

//     ColumnLayout {
//         anchors.fill: parent
//         anchors.margins: 20
//         spacing: 20

//         Flickable {
//             id: flickable
//             Layout.fillWidth: true
//             Layout.fillHeight: true
//             clip: true
//             contentWidth: parent.width
//             contentHeight: scrollContent.implicitHeight
//             interactive: true

//             Column  {
//                 id: scrollContent
//                 width: parent.width
//                 spacing: 20
//                 //width: parent.width //ScrollView.viewport.width

//                 MouseArea {
//                     width: parent.true
//                     height: 40   // Or any suitable height
//                     hoverEnabled: true
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: {
//                         if(activeVehicle){
//                             console.log("device connected")
//                             mainWindow.sideDrawer1("RadioComponent.qml")
//                         }else{
//                             console.log("device not connected")
//                             mainWindow.showToast("Device not connected")
//                         }
//                     }
//                     RowLayout {
//                                             anchors.fill: parent
//                                             spacing: 10

//                                             Label {
//                                                 text: "RC Calibration"
//                                                 color: "black"
//                                                 Layout.fillWidth: true
//                                             }
//                                             Label {
//                                                 text: ">"
//                                                 color: "black"
//                                                 font.pixelSize: 18
//                                                 font.bold: true
//                                             }
//                                         }


//                 }

//                 MouseArea {
//                     width: parent.width
//                     height: 40   // Or any suitable height
//                     hoverEnabled: true
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: {
//                         if(activeVehicle){
//                             console.log("Channel Set Clicked")
//                             mainWindow.sideDrawer1("qrc:/qml/SettingsPanel/ChannelSet.qml")
//                         }else{
//                             console.log("device not connected")
//                             mainWindow.showToast("Device not connected")
//                         }
//                     }

//                     RowLayout {
//                         anchors.fill: parent  // Important to fill MouseArea fully
//                         spacing: 10

//                         Label {
//                             text: "Channel set"
//                             color: "black"
//                             Layout.fillWidth: true
//                         }
//                         Label {
//                             text: ">"
//                             color: "black"
//                             font.pixelSize: 18
//                             font.bold: true
//                         }
//                     }
//                 }

//                 RowLayout {
//                     spacing: 10
//                     Label {
//                         text: "SBUS Switch"
//                         color: "black"
//                         Layout.fillWidth: true
//                     }
//                     ComboBox {
//                         model: ["SBUS", "PPM"]
//                     }
//                 }

//                 Label {
//                     text: "Please turn off the SBUS signal after attention"
//                     color: "grey"
//                     wrapMode: Text.Wrap
//                 }

//                 Label {
//                     text: "Fail-Safe"
//                     color: "black"
//                     font.pixelSize: 18
//                 }

//                 RowLayout {
//                     spacing: 10
//                     RadioButton { text: "Back" }
//                     RadioButton { text: "Land" }
//                     RadioButton { text: "Hang" }
//                     RadioButton { text: "Hang-Land" }
//                 }

//                 Label {
//                     text: "Fail-Safe Continue"
//                     color: "black"
//                 }

//                 Switch {
//                     checked: false
//                 }

//                 Button {
//                     text: "Read"
//                     Layout.alignment: Qt.AlignHCenter
//                 }
//             }
//         }
//     }


// }


