import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Palette
import MapGlobals
import Qt.labs.lottieqt 1.0

Item {
    id: reportsRoot
    anchors.fill: parent

    property color app_color: MapGlobals.rootWindow ? MapGlobals.rootWindow.app_color : "#262626"
    property color sidebar_color: app_color
    property color bg_color: "#F9FAFB"
    property color border_color: "#E5E7EB"
    property color text_primary: "#111827"
    property color text_secondary: "#6B7280"
    
    signal backClicked()

    // Professional Responsiveness
    readonly property bool isSmallScreen: width < ScreenTools.defaultFontPixelWidth * 60
    readonly property real outerPadding: isSmallScreen ? 20 : 60
    readonly property real tableMaxWidth: 900

    property int totalMinutes: 0
    property int missionsCompleted: 0
    property string totalDurationFormatted: "0h 0m"

    ListModel {
        id: sessionModel
    }

    Component.onCompleted: loadSessions()

    function loadSessions() {
        sessionModel.clear();
        MapGlobals.getAllSessions(function(sessions) {
            var total = 0;
            for (var i = 0; i < sessions.length; i++) {
                var session = sessions[i];
                sessionModel.append({
                    id: session.id,
                    date: session.date || "N/A",
                    start_time: session.start_time || "--:--",
                    end_time: session.end_time || "--:--",
                    duration: session.duration || 0
                });
                total += Number(session.duration || 0);
            }
            
            totalMinutes = total;
            missionsCompleted = sessions.length;
            
            var hours = Math.floor(total / 60);
            var minutes = total % 60;
            totalDurationFormatted = hours + "h " + minutes + "m";
        });
    }

    Rectangle {
        anchors.fill: parent
        color: bg_color

        RowLayout {
            anchors.fill: parent
            spacing: 0

            /* ================= PREMIUM SIDEBAR (35%) ================= */
            Rectangle {
                id: sidebar
                Layout.fillHeight: true
                Layout.preferredWidth: isSmallScreen ? 0 : 350
                visible: !isSmallScreen
                color: sidebar_color
                clip: true

                // Background Gradient
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: sidebar_color }
                        GradientStop { position: 1.0; color: "#1A1A1A" }
                    }
                }

                // Decorative Accents
                Rectangle {
                    width: 400; height: 400; radius: 200; color: Qt.rgba(255,255,255,0.03)
                    anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: -80
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 50
                    spacing: 0

                    // Back Arrow
                    Rectangle {
                        width: 44; height: 44; radius: 12
                        color: Qt.rgba(255, 255, 255, 0.08)
                        border.color: Qt.rgba(255, 255, 255, 0.15)
                        QGCColoredImage { source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"; width: 20; height: 20; color: "white"; anchors.centerIn: parent }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: reportsRoot.backClicked() }
                    }

                    Item { Layout.fillHeight: true }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 16
                        Text { text: "Mission History"; font.family: "Outfit"; font.pointSize: 32; font.bold: true; color: "white" }
                        Text { text: "Comprehensive log of your flight deployments, timestamps, and mission cycles."; font.family: "Outfit"; font.pointSize: 12; color: Qt.rgba(255, 255, 255, 0.6); wrapMode: Text.WordWrap; Layout.fillWidth: true; lineHeight: 1.5 }
                    }

                    Item { Layout.fillHeight: true }
                    
                    Item { Layout.preferredHeight: 40 }
                }
            }

            /* ================= DATA CONTENT AREA (65%) ================= */
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"

                // Mobile Navigation Bar
                Rectangle {
                    visible: isSmallScreen; width: parent.width; height: 70; color: "white"
                    anchors.top: parent.top; z: 10
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: border_color }
                    RowLayout { anchors.fill: parent; anchors.margins: 20
                        QGCColoredImage { source: "qrc:/InstrumentValueIcons/arrow-thin-left.svg"; width: 24; height: 24; color: text_primary; MouseArea { anchors.fill: parent; onClicked: reportsRoot.backClicked() } }
                        Text { text: "Mission History"; font.family: "Outfit"; font.bold: true; font.pointSize: ScreenTools.mediumFontPointSize; color: text_primary }
                    }
                }

                Flickable {
                    anchors.fill: parent
                    anchors.topMargin: isSmallScreen ? 70 : 0
                    contentWidth: width; contentHeight: mainCol.height + 100
                    clip: true; boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: mainCol
                        width: Math.min(tableMaxWidth, parent.width - (outerPadding * 2))
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; anchors.topMargin: isSmallScreen ? 30 : 70
                        spacing: 24

                        // Page Title (Desktop Only)
                        ColumnLayout {
                            visible: !isSmallScreen; Layout.fillWidth: true; spacing: 4
                            Text { text: "Mission Session Logs"; font.family: "Outfit"; font.pointSize: 24; font.bold: true; color: text_primary }
                            Text { text: "Detailed records of flight cycles per session."; font.family: "Outfit"; font.pointSize: 11; color: text_secondary }
                        }

                        // THE DATA GRID CARD
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(500, missionsList.contentHeight + 80)
                            color: "white"; radius: 16
                            border.color: border_color; border.width: 1
                            clip: true

                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0,0,0,0.03); shadowBlur: 1.0; shadowVerticalOffset: 4 }

                            ColumnLayout {
                                anchors.fill: parent; spacing: 0

                                // Table Header (Perfect Alignment)
                                Rectangle {
                                    Layout.fillWidth: true; height: 60; color: "#F9FAFB"
                                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: border_color }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 30; anchors.rightMargin: 30; spacing: 0
                                        Text { text: "MISSION DATE"; Layout.preferredWidth: parent.width * 0.45; font.family: "Outfit"; font.bold: true; color: text_secondary; font.pointSize: 9; font.letterSpacing: 0.8 }
                                        Text { text: "START TIME"; Layout.preferredWidth: parent.width * 0.275; font.family: "Outfit"; font.bold: true; color: text_secondary; font.pointSize: 9; font.letterSpacing: 0.8; horizontalAlignment: Text.AlignHCenter }
                                        Text { text: "END TIME"; Layout.preferredWidth: parent.width * 0.275; font.family: "Outfit"; font.bold: true; color: text_secondary; font.pointSize: 9; font.letterSpacing: 0.8; horizontalAlignment: Text.AlignRight }
                                    }
                                }

                                ListView {
                                    id: missionsList
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    model: sessionModel; interactive: false
                                    
                                    delegate: Rectangle {
                                        width: missionsList.width; height: 72
                                        color: index % 2 === 1 ? "#FAFAFC" : "transparent"
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 30; anchors.rightMargin: 30; spacing: 0
                                            
                                            // Date (45%)
                                            RowLayout {
                                                Layout.preferredWidth: parent.width * 0.45; spacing: 14
                                                Rectangle {
                                                    width: 40; height: 40; radius: 10; color: Qt.rgba(0, 0, 0, 0.07)
                                                    QGCColoredImage { source: "qrc:/InstrumentValueIcons/calendar.svg"; width: 18; height: 18; color: app_color; anchors.centerIn: parent }
                                                }
                                                Text { text: model.date; font.family: "Outfit"; font.bold: true; color: text_primary; font.pointSize: 13 }
                                            }

                                            // Start (27.5%) - Centered Alignment
                                            Text { text: model.start_time; Layout.preferredWidth: parent.width * 0.275; horizontalAlignment: Text.AlignHCenter; font.family: "Outfit"; color: text_secondary; font.pointSize: 12; font.bold: true }

                                            // End (27.5%) - Right Alignment
                                            Text { text: model.end_time; Layout.preferredWidth: parent.width * 0.275; horizontalAlignment: Text.AlignRight; font.family: "Outfit"; color: text_secondary; font.pointSize: 12; font.bold: true }
                                        }

                                        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 30; anchors.rightMargin: 30; height: 1; color: border_color; visible: index < missionsList.count - 1 }
                                    }

                                    // Empty State (Perfectly Centered)
                                    ColumnLayout {
                                        anchors.centerIn: parent; visible: missionsList.count === 0; spacing: 16
                                        QGCColoredImage { source: "qrc:/InstrumentValueIcons/info.svg"; width: 60; height: 60; color: "#D1D5DB"; Layout.alignment: Qt.AlignHCenter }
                                        Text { text: "No Mission Records Discovered"; font.family: "Outfit"; font.bold: true; font.pointSize: 14; color: text_secondary; Layout.alignment: Qt.AlignHCenter }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



