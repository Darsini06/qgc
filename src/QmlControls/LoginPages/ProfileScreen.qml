import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QGroundControl 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Palette 1.0
import MapGlobals

Item {
    id: profilescreen
    anchors.fill: parent

    property string currentView: MapGlobals.currentView_profile || "profile"
    property string userName: QGroundControl.loadGlobalSetting("username", "")
    property string displayName: QGroundControl.loadGlobalSetting("name", "")
    property string userEmail: QGroundControl.loadGlobalSetting("email", "")
    
    property string name_from_db: ""
    property string mobileNo_from_db: ""
    property string email_from_db: ""
    property int rpcCompletedStatus: -1

    property int totalMinutes: 0
    property int missionsCompleted: 0
    property string totalDurationFormatted: "0h 0m"
    property color app_color: "#262626"

    // Load logic
    function loadSessions() {
        MapGlobals.getAllSessions(function(sessions) {
            var total = 0;
            for (var i = 0; i < sessions.length; i++) {
                total += Number(sessions[i].duration || 0);
            }
            totalMinutes = total;
            missionsCompleted = sessions.length;
            var hours = Math.floor(total / 60);
            var minutes = total % 60;
            totalDurationFormatted = hours + "h " + minutes + "m";
        });
    }

    function loadUserData() {
        MapGlobals.loadUserData(userName, function(userData) {
            if (userData) {
                name_from_db = userData.displayname || "";
                mobileNo_from_db = userData.mobile_number || "";
                email_from_db = userData.email || "";
                rpcCompletedStatus = (userData.rpc_completed !== undefined && userData.rpc_completed !== null) ? Number(userData.rpc_completed) : -1;
            }
        });
    }

    Component.onCompleted: {
        loadSessions();
        if (userName !== "") loadUserData();
    }

    onVisibleChanged: {
        if (visible) {
            loadSessions();
            displayName = QGroundControl.loadGlobalSetting("name", "")
            userName = QGroundControl.loadGlobalSetting("username", "")
            userEmail = QGroundControl.loadGlobalSetting("email", "")
            if (userName !== "") loadUserData();
        }
    }

    // Router
    Loader {
        id: pageLoader
        anchors.fill: parent
        source: {
            var pathPrefix = "qrc:/qml/LoginPages/"
            switch (currentView) {
            case "profile":         return pathPrefix + "ProfileMain.qml"
            case "accountUpdate":   return pathPrefix + "AccountUpdate.qml"
            case "feedback":        return pathPrefix + "Feedback.qml"
            case "reports":         return pathPrefix + "ReportScreen.qml"
            case "logfiles":         return pathPrefix + "LogFiles.qml"
            case "drone":           return pathPrefix + "SelectApplication.qml"
            case "privacy_policy":  return pathPrefix + "PrivacyScreen.qml"
            case "terms&conditions": return pathPrefix + "Terms_Condition.qml"
            default:                return pathPrefix + "ProfileMain.qml"
            }
        }

        onLoaded: {
            // Pass data to sub-screens
            if (item.hasOwnProperty("app_color")) item.app_color = profilescreen.app_color
            if (item.hasOwnProperty("userName")) item.userName = profilescreen.userName
            if (item.hasOwnProperty("displayName")) item.displayName = profilescreen.displayName
            if (item.hasOwnProperty("userEmail")) item.userEmail = profilescreen.userEmail
            if (item.hasOwnProperty("totalDurationFormatted")) item.totalDurationFormatted = profilescreen.totalDurationFormatted
            if (item.hasOwnProperty("missionsCompleted")) item.missionsCompleted = profilescreen.missionsCompleted
            
            // For AccountUpdate
            if (item.hasOwnProperty("name_from_db")) item.name_from_db = profilescreen.name_from_db
            if (item.hasOwnProperty("email_from_db")) item.email_from_db = profilescreen.email_from_db
            if (item.hasOwnProperty("mobileNo_from_db")) item.mobileNo_from_db = profilescreen.mobileNo_from_db
            if (item.hasOwnProperty("rpcCompletedStatus")) item.rpcCompletedStatus = profilescreen.rpcCompletedStatus

            // select the App then go to the Homescreen
            if (item && typeof item.appSelected !== "undefined") {
                item.appSelected.connect(function() {
                    if (typeof mainWindow !== "undefined") mainWindow.openHomeScreen();
                    else if (MapGlobals.rootWindow) MapGlobals.rootWindow.openHomeScreen();
                })
            }

            //Handle the BackClick
            if (item && typeof item.backClicked !== "undefined") {
                item.backClicked.connect(function() {
                    if (currentView === "profile") {
                        if (typeof mainWindow !== "undefined") mainWindow.openHomeScreen();
                        else if (MapGlobals.rootWindow) MapGlobals.rootWindow.openHomeScreen();
                    } else {
                        currentView = "profile"
                    }
                })
            }

            // click the MenuItem
            if (item && typeof item.menuItemSelected !== "undefined") {

                item.menuItemSelected.connect(function(screen) {

                    if (screen === "logout") logoutDialog.createObject(profilescreen).open()

                    else if (screen === "accountUpdate") {
                        loadUserData() // Refresh before editing
                        currentView = screen
                    }else if (screen === "logfiles") {
                        currentView = screen
                    }

                    else currentView = screen
                })
            }

            if (currentView === "logfiles") {
                if (item && typeof item.triggerLoad === "function") {
                    item.triggerLoad()
                }
            }

            //Profile Update
            if (item && typeof item.updated !== "undefined") {
                item.updated.connect(function() {
                    loadUserData(); // Refresh data
                    currentView = "profile";
                })
            }
        }
    }

    Component {
        id: logoutDialog
        QGCPopupDialog {
            title: qsTr("Logout")
            buttons: Dialog.Yes | Dialog.No
            onAccepted: {
                QGroundControl.saveBoolGlobalSetting("login", false)
                QGroundControl.saveGlobalSetting("loadpage", "loadpage")
                MapGlobals.profile()
            }
            ColumnLayout {
                QGCLabel { text: qsTr("Are you sure you want to logout?") }
            }
        }
    }
}
