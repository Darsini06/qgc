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
    id: termsRoot
    anchors.fill: parent

    property color app_color:       MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#262626"
    property color sidebar_color:   app_color
    property color bg_color:        "#F9FAFB"
    property color border_color:    "#E5E7EB"
    property color text_primary:    "#111827"
    property color text_secondary:  "#6B7280"

    property bool loading: true

    // Change this URL later with your actual PDF
    property string termsUrl: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"

    signal backClicked()

 readonly property bool isSmallScreen: width < 800

    Rectangle {
        anchors.fill: parent
        color: bg_color

        RowLayout {
            anchors.fill: parent
            spacing: 0

            /* ================= SIDEBAR ================= */

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
                        GradientStop { position: 0.0; color: sidebar_color }
                        GradientStop { position: 1.0; color: "#1A1A1A" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    spacing: 0

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 12

                        color: Qt.rgba(255,255,255,0.08)
                        border.color: Qt.rgba(255,255,255,0.15)

                        QGCColoredImage {
                            anchors.centerIn: parent
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 20
                            height: 20
                            color: "white"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: termsRoot.backClicked()
                        }
                    }

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Text {
                            text: "Terms & Conditions"
                            font.family: "Outfit"
                            font.pointSize: 32
                            font.bold: true
                            color: "white"
                        }

                        Text {
                            text: "Please review the terms of service and usage guidelines for the Drone Commander GCS platform."
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            color: Qt.rgba(255,255,255,0.6)
                        }
                    }

                    Item { Layout.fillHeight: true }

                    QGCColoredImage {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        source: "qrc:/qmlimages/NewImages/terms_condition_black.svg"
                        color: "white"
                        opacity: 0.15
                    }

                    Item { Layout.preferredHeight: 40 }
                }
            }
            /* ================= CONTENT AREA ================= */

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: parent.width * 0.55

                color: "white"

                WebView {
                    id: webView
                    anchors.fill: parent

                    url: "https://aviatricks.in/terms-and-conditions?embed=true"

                    onLoadingChanged: function(loadRequest) {
                        if (loadRequest.status === WebView.LoadStartedStatus)
                            termsRoot.loading = true
                        else if (loadRequest.status === WebView.LoadSucceededStatus ||
                                 loadRequest.status === WebView.LoadFailedStatus)
                            termsRoot.loading = false
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    visible: termsRoot.loading

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: true
                    }
                }
            }
        }
    }
}
