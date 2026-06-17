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
    property string documentUrl: ""
    property bool hasDocument: false
    property string documentName: ""

    signal backClicked()

    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 60

    // Use backendUrl from MapGlobals
    readonly property string apiBaseUrl: {
        var url = MapGlobals.backendUrl
        if (url.endsWith("/api")) {
            return url.substring(0, url.length - 4)
        }
        return url
    }
    readonly property string documentType: "privacy"

    Component.onCompleted: {
        fetchDocument()
    }

    function fetchDocument() {
        loading = true
        var xhr = new XMLHttpRequest()
        xhr.open("GET", MapGlobals.backendUrl + "/document/" + documentType, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.success && response.document) {
                            privacyRoot.hasDocument = true
                            privacyRoot.documentName = response.document.fileName || "Document"
                            var filePath = response.document.filePath
                            if (filePath.startsWith("uploads/")) {
                                filePath = filePath.substring(8)
                            }
                            privacyRoot.documentUrl = apiBaseUrl + "/uploads/" + encodeURIComponent(filePath)
                            console.log("Privacy document found:", privacyRoot.documentUrl)
                        } else {
                            privacyRoot.hasDocument = false
                            privacyRoot.documentUrl = ""
                        }
                    } catch (e) {
                        console.error("Error parsing privacy document response:", e)
                        privacyRoot.hasDocument = false
                        privacyRoot.documentUrl = ""
                    }
                } else if (xhr.status === 404) {
                    privacyRoot.hasDocument = false
                    privacyRoot.documentUrl = ""
                    console.log("No privacy document found")
                } else {
                    console.error("Error fetching privacy document:", xhr.status, xhr.statusText)
                    privacyRoot.hasDocument = false
                    privacyRoot.documentUrl = ""
                }
                privacyRoot.loading = false
            }
        }
        xhr.onerror = function() {
            console.error("Network error fetching privacy document")
            privacyRoot.hasDocument = false
            privacyRoot.documentUrl = ""
            privacyRoot.loading = false
        }
        xhr.send()
    }

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
                        GradientStop { position: 0.0; color: sidebar_color }
                        GradientStop { position: 1.0; color: "#1A1A1A" }
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
                        source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
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

                    Item { Layout.fillHeight: true }

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
                            text: privacyRoot.hasDocument ?
                                "Our privacy policy document is available for review." :
                                "No privacy policy document has been uploaded yet."
                            font.family: "Outfit"
                            font.pointSize: 12
                            color: Qt.rgba(255,255,255,0.6)
                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                        }
                    }

                    Item { Layout.fillHeight: true }

                    QGCColoredImage {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 120
                        source: "qrc:/qmlimages/NewImages/privacy_policy_black.svg"
                        color: "white"
                        opacity: 0.15
                    }

                    Item { Layout.preferredHeight: 40 }
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
                            source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                            width: 24
                            height: 24
                            color: text_primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: privacyRoot.backClicked()
                            }
                        }

                        Text {
                            text: "Privacy Policy"
                            font.family: "Outfit"
                            font.bold: true
                            font.pointSize: ScreenTools.mediumFontPointSize
                            color: text_primary
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.topMargin: isSmallScreen ? 70 : 0

                    function getPdfHtml(pdfUrl) {
                        var html = "<html><head>";
                        html += "<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no' />";
                        html += "<script src='https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.14.305/pdf.min.js'></script>";
                        html += "<style>body { margin: 0; background: #e5e7eb; } canvas { margin: 10px auto; display: block; max-width: 100%; height: auto; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }</style>";
                        html += "</head><body>";
                        html += "<div id='pdf-container' style='width:100%;'></div>";
                        html += "<script>";
                        html += "pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.14.305/pdf.worker.min.js';";
                        html += "var loadingTask = pdfjsLib.getDocument({ url: '" + pdfUrl + "', disableRange: true, disableStream: true });";
                        html += "loadingTask.promise.then(function(pdf) {";
                        html += "  var container = document.getElementById('pdf-container');";
                        html += "  for (var i = 1; i <= pdf.numPages; i++) {";
                        html += "    pdf.getPage(i).then(function(page) {";
                        html += "      var viewport = page.getViewport({scale: 1.5});";
                        html += "      var canvas = document.createElement('canvas');";
                        html += "      canvas.height = viewport.height;";
                        html += "      canvas.width = viewport.width;";
                        html += "      container.appendChild(canvas);";
                        html += "      page.render({canvasContext: canvas.getContext('2d'), viewport: viewport});";
                        html += "    });";
                        html += "  }";
                        html += "}).catch(function(err) {";
                        html += "  document.getElementById('pdf-container').innerHTML = '<div style=\"padding:20px;color:red;text-align:center;\">Error loading PDF: ' + err.message + '</div>';";
                        html += "});";
                        html += "</script></body></html>";
                        return "data:text/html;charset=utf-8," + encodeURIComponent(html);
                    }

                    WebView {
                        id: webView
                        anchors.fill: parent
                        visible: !privacyRoot.loading && privacyRoot.hasDocument && privacyRoot.documentUrl !== ""

                        url: privacyRoot.documentUrl !== "" ? parent.getPdfHtml(privacyRoot.documentUrl) : ""

                        onLoadingChanged: function(loadRequest) {
                            if (loadRequest.status === WebView.LoadStartedStatus) {
                                privacyRoot.loading = true
                                console.log("WebView: Loading started")
                            } else if (loadRequest.status === WebView.LoadSucceededStatus) {
                                privacyRoot.loading = false
                                console.log("WebView: Load succeeded")
                            } else if (loadRequest.status === WebView.LoadFailedStatus) {
                                privacyRoot.loading = false
                                console.error("WebView: Load failed")
                            }
                        }
                    }

                    // Show message when no document is available
                    Rectangle {
                        anchors.fill: parent
                        visible: !privacyRoot.loading && !privacyRoot.hasDocument
                        color: "white"

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 20

                            Text {
                                text: "📄"
                                font.pointSize: 60
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "No Privacy Policy Document Uploaded"
                                font.family: "Outfit"
                                font.pointSize: 18
                                font.bold: true
                                color: "#374151"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Please upload a privacy policy document from the admin panel."
                                font.family: "Outfit"
                                font.pointSize: 12
                                color: "#6B7280"
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                Layout.maximumWidth: 400
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Loading indicator
                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        visible: privacyRoot.loading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 20

                            BusyIndicator {
                                Layout.alignment: Qt.AlignHCenter
                                running: true
                            }

                            Text {
                                text: "Loading document..."
                                color: "#6B7280"
                                font.family: "Outfit"
                                font.pointSize: 12
                            }
                        }
                    }
                }
            }
        }
    }
}
