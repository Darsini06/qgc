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
    property string documentUrl: ""
    property bool hasDocument: false
    property string documentName: ""

    signal backClicked()

    readonly property bool isSmallScreen: width < 800

    // Use backendUrl from MapGlobals
    readonly property string apiBaseUrl: {
        var url = MapGlobals.backendUrl
        if (url.endsWith("/api")) {
            return url.substring(0, url.length - 4)
        }
        return url
    }
    readonly property string documentType: "terms"

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
                            termsRoot.hasDocument = true
                            termsRoot.documentName = response.document.fileName || "Document"
                            var filePath = response.document.filePath
                            if (filePath.startsWith("uploads/")) {
                                filePath = filePath.substring(8)
                            }
                            termsRoot.documentUrl = apiBaseUrl + "/uploads/" + encodeURIComponent(filePath)
                            console.log("Terms document found:", termsRoot.documentUrl)
                        } else {
                            termsRoot.hasDocument = false
                            termsRoot.documentUrl = ""
                        }
                    } catch (e) {
                        console.error("Error parsing terms document response:", e)
                        termsRoot.hasDocument = false
                        termsRoot.documentUrl = ""
                    }
                } else if (xhr.status === 404) {
                    termsRoot.hasDocument = false
                    termsRoot.documentUrl = ""
                    console.log("No terms document found")
                } else {
                    console.error("Error fetching terms document:", xhr.status, xhr.statusText)
                    termsRoot.hasDocument = false
                    termsRoot.documentUrl = ""
                }
                termsRoot.loading = false
            }
        }
        xhr.onerror = function() {
            console.error("Network error fetching terms document")
            termsRoot.hasDocument = false
            termsRoot.documentUrl = ""
            termsRoot.loading = false
        }
        xhr.send()
    }

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
                            text: termsRoot.hasDocument ?
                                "Our terms and conditions document is available for review." :
                                "No terms and conditions document has been uploaded yet."
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
                    visible: !termsRoot.loading && termsRoot.hasDocument && termsRoot.documentUrl !== ""

                    url: termsRoot.documentUrl !== "" ? parent.getPdfHtml(termsRoot.documentUrl) : ""

                    onLoadingChanged: function(loadRequest) {
                        if (loadRequest.status === WebView.LoadStartedStatus) {
                            termsRoot.loading = true
                            console.log("WebView: Loading started")
                        } else if (loadRequest.status === WebView.LoadSucceededStatus) {
                            termsRoot.loading = false
                            console.log("WebView: Load succeeded")
                        } else if (loadRequest.status === WebView.LoadFailedStatus) {
                            termsRoot.loading = false
                            console.error("WebView: Load failed")
                        }
                    }
                }

                // Show message when no document is available
                Rectangle {
                    anchors.fill: parent
                    visible: !termsRoot.loading && !termsRoot.hasDocument
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
                            text: "No Terms & Conditions Document Uploaded"
                            font.family: "Outfit"
                            font.pointSize: 18
                            font.bold: true
                            color: "#374151"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Please upload a terms and conditions document from the admin panel."
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
                    visible: termsRoot.loading

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
