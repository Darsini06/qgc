import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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


Item {

    id:             profile1
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "#f5f5f5"
        radius: 10
        border.color: "lightgray"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Profile Header
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignLeft

                Image {
                    source: "/qmlimages/NewImages/profileImage.png" // replace with your asset
                    width: 60
                    height: 60
                    fillMode: Image.PreserveAspectFit
                    clip: true
                    smooth: true
                }

                ColumnLayout {
                    spacing: 4
                    Text {
                        text: "Flytutor Technologies"
                        font.bold: true
                        font.pointSize: 14
                    }
                    Text {
                        text: "Owner"
                        color: "gray"
                        font.pointSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Image {
                    source: "/qmlimages/NewImages/goldMedal.png" // replace with your badge image
                    width: 50
                    height: 50
                    fillMode: Image.PreserveAspectFit
                }
            }

            // Menu Section
            Repeater {
                model: ListModel {
                    ListElement { icon: "/qmlimages/NewImages/accountUpdate.png"; label: "Account Update" }
                    ListElement { icon: "/qmlimages/NewImages/userGuide.png"; label: "User Guide" }
                    ListElement { icon: "/qmlimages/NewImages/record.png"; label: "Record" }
                    ListElement { icon: "/qmlimages/NewImages/reports.png"; label: "Reports" }
                    ListElement { icon: "/qmlimages/NewImages/feedback.png"; label: "Feedback" }
                    ListElement { icon: "/qmlimages/NewImages/accountUpdate.png"; label: "Settings" }
                }

                delegate: RowLayout {
                    spacing: 10
                    height: 40
                    width: parent.width

                    Image {
                        source: icon
                        width: 24
                        height: 24
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: label
                        font.pointSize: 12
                        Layout.fillWidth: true
                    }

                    Text {
                        text: ">"
                        font.pointSize: 14
                        color: "gray"
                    }

                    // MouseArea {
                    //     anchors.fill: parent
                    //     onClicked: {
                    //         console.log("Clicked", label)
                    //     }
                    // }
                }
            }
        }
    }
}

