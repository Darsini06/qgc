import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtWebView 1.1
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals 1.0

Item {
    id: privacyRoot
    anchors.fill: parent
    property color app_color: "#5d179e"
    property bool loading: true
    signal backClicked()

    Rectangle {
        anchors.fill: parent
        color: "white"

        Rectangle {
            id: header
            width: parent.width; height: parent.height * 0.15; color: app_color
            QGCColoredImage {
                source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"
                width: 25; height: 25; color: "white"
                anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: privacyRoot.backClicked() }
            }
            Text { text: "Privacy Policy"; font.pointSize: ScreenTools.mediumFontPointSize; font.bold: true; color: "white"; anchors.centerIn: parent }
        }

        Item {
            anchors.top: header.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            WebView {
                id: webView
                anchors.fill: parent
                url: "https://www.nithra.mobi/privacy.php"
                onLoadingChanged: function(loadRequest) {
                    if (loadRequest.status === WebView.LoadStartedStatus) privacyRoot.loading = true
                    else if (loadRequest.status === WebView.LoadSucceededStatus || loadRequest.status === WebView.LoadFailedStatus) privacyRoot.loading = false
                }
            }
            Rectangle {
                anchors.fill: parent; color: "#00000020"; visible: privacyRoot.loading
                BusyIndicator { anchors.centerIn: parent; running: true; width: 40; height: 40 }
            }
        }
    }
}
