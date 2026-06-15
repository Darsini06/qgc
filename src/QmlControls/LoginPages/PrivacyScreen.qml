import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import QtWebView 1.1

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: privacyRoot
    anchors.fill: parent

    property color app_color:       MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#262626"
    property color sidebar_color:   app_color
    property color bg_color:        "#F9FAFB"
    property color border_color:    "#E5E7EB"
    property color text_primary:    "#111827"
    property color text_secondary:  "#6B7280"

    property bool loading: true

    // Sample PDF URL
    property string privacyUrl:
       "https://aviatricks.in/privacy-policy?embed=true"

    signal backClicked()

    readonly property bool isSmallScreen:
        width < ScreenTools.defaultFontPixelWidth * 60

    Rectangle {
        anchors.fill: parent
        color: bg_color

        RowLayout {
            anchors.fill: parent
            spacing: 0

            /* ================= LEFT SIDEBAR ================= */

            Rectangle {
                id: sidebar

                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.45

                visible: !isSmallScreen
                color: sidebar_color
                clip: true

                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: sidebar_color
                        }

                        GradientStop {
                            position: 1.0
                            color: "#1A1A1A"
                        }
                    }
                }

                Rectangle {
                    width: 400
                    height: 400
                    radius: 200

                    color: Qt.rgba(255,255,255,0.03)

                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: -80
                }

                Rectangle {
                    width: 44
                    height: 44
                    radius: 12

                    anchors.top: parent.top
                    anchors.left: parent.left

                    anchors.topMargin: 20
                    anchors.leftMargin: 20

                    color: Qt.rgba(255,255,255,0.08)
                    border.color: Qt.rgba(255,255,255,0.15)

                    QGCColoredImage {
                        anchors.centerIn: parent

                        source:
                            "qrc:/InstrumentValueIcons/arrow-thin-left.svg"

                        width: 20
                        height: 20
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: privacyRoot.backClicked()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    anchors.topMargin: 100

                    spacing: 0

                    Item {
                        Layout.fillHeight: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Text {
                            text: "Privacy Policy"

                            font.family: "Outfit"
                            font.pointSize: 32
                            font.bold: true

                            color: "white"
                        }

                        Text {
                            Layout.fillWidth: true

                            text:
                                "Read our privacy practices and understand how your information is collected, stored, and protected."

                            font.family: "Outfit"
                            font.pointSize: 12

                            color: Qt.rgba(255,255,255,0.6)

                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    QGCColoredImage {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120

                        source:
                            "qrc:/qmlimages/NewImages/privacy_policy_black.svg"

                        color: "white"
                        opacity: 0.15
                    }

                    Item {
                        Layout.preferredHeight: 40
                    }
                }
            }

            /* ================= RIGHT CONTENT ================= */

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "white"

                Rectangle {
                    visible: isSmallScreen

                    width: parent.width
                    height: 70

                    color: "white"

                    anchors.top: parent.top
                    z: 10

                    Rectangle {
                        anchors.bottom: parent.bottom

                        width: parent.width
                        height: 1

                        color: border_color
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20

                        QGCColoredImage {
                            source:
                                "qrc:/InstrumentValueIcons/arrow-thin-left.svg"

                            width: 24
                            height: 24

                            color: text_primary

                            MouseArea {
                                anchors.fill: parent

                                onClicked:
                                    privacyRoot.backClicked()
                            }
                        }

                        Text {
                            text: "Privacy Policy"

                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize:
                                ScreenTools.mediumFontPointSize

                            color: text_primary
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.topMargin: isSmallScreen ? 70 : 0

                    WebView {
                        id: webView

                        anchors.fill: parent

                        visible: !privacyRoot.loading

                        url: privacyUrl

                        onLoadingChanged: function(loadRequest) {

                            if (loadRequest.status
                                    === WebView.LoadStartedStatus) {
                                privacyRoot.loading = true
                            }

                            else if (loadRequest.status
                                     === WebView.LoadSucceededStatus
                                     || loadRequest.status
                                     === WebView.LoadFailedStatus) {
                                privacyRoot.loading = false
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent

                        color: "white"

                        visible: privacyRoot.loading

                        BusyIndicator {
                            anchors.centerIn: parent
                            running: true
                        }
                    }
                }
            }
        }
    }
}
