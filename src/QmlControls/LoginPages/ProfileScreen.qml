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
    property string userName: MapGlobals.userName
    property string displayName: MapGlobals.displayName
    property string userEmail: MapGlobals.userEmail
    
    property string mobileNo: MapGlobals.mobileNo
    property int rpcCompletedStatus: -1

    onUserNameChanged: if (pageLoader.item && pageLoader.item.hasOwnProperty("userName")) pageLoader.item.userName = userName
    onUserEmailChanged: if (pageLoader.item && pageLoader.item.hasOwnProperty("userEmail")) pageLoader.item.userEmail = userEmail
    onDisplayNameChanged: if (pageLoader.item && pageLoader.item.hasOwnProperty("displayName")) pageLoader.item.displayName = displayName
    onMobileNoChanged:    if (pageLoader.item && pageLoader.item.hasOwnProperty("mobileNo"))    pageLoader.item.mobileNo    = mobileNo
    onRpcCompletedStatusChanged: if (pageLoader.item && pageLoader.item.hasOwnProperty("rpcCompletedStatus")) pageLoader.item.rpcCompletedStatus = rpcCompletedStatus
    onTotalDurationFormattedChanged: if (pageLoader.item && pageLoader.item.hasOwnProperty("totalDurationFormatted")) pageLoader.item.totalDurationFormatted = totalDurationFormatted
    onMissionsCompletedChanged:      if (pageLoader.item && pageLoader.item.hasOwnProperty("missionsCompleted"))      pageLoader.item.missionsCompleted = missionsCompleted

    property int totalMinutes: 0
    property int missionsCompleted: 0
    property string totalDurationFormatted: "0h 0m"
    property color app_color: "#262626"

    // Load logic
    function loadSessions() {
        console.log("loadSessions()")
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
            rpcCompletedStatus = MapGlobals.rpcStatus   // onRpcCompletedStatusChanged handles the push

            console.log("totalDurationFormatted:", totalDurationFormatted)
            console.log("rpcCompletedStatus:", rpcCompletedStatus)
        });
    }

    function loadUserData(onComplete) {
        MapGlobals.loadUserData(userName, function(userData) {
            if (userData) {

                MapGlobals.displayName = userData.displayname ?? ""

                MapGlobals.userEmail = userData.email ?? ""

                MapGlobals.mobileNo =
                        userData.mobile_number !== undefined &&
                        userData.mobile_number !== null
                        ? userData.mobile_number
                        : ""

                MapGlobals.rpcStatus   = (userData.rpc_completed !== undefined && userData.rpc_completed !== null)
                        ? Number(userData.rpc_completed) : -1

                rpcCompletedStatus = Number(MapGlobals.rpcStatus)
                mobileNo = MapGlobals.mobileNo

                // FORCE update currently loaded page
                if (pageLoader.item) {

                    if (pageLoader.item.hasOwnProperty("rpcCompletedStatus")) {
                        pageLoader.item.rpcCompletedStatus =
                                rpcCompletedStatus
                    }

                    if (pageLoader.item.hasOwnProperty("mobileNo")) {
                        pageLoader.item.mobileNo =
                                mobileNo
                    }
                }

                console.log("loadUserData — rpcStatus:", MapGlobals.rpcStatus, "mobileNo:", MapGlobals.mobileNo)
            }
            if (typeof onComplete === "function") onComplete()
        })
    }

    Component.onCompleted: {
        console.log("isMobile in ProfileScreen",ScreenTools.isMobile)
        console.log("isSmallScreen in ProfileScreen",ScreenTools.isTinyScreen)
        loadSessions()
        if (userName !== "") loadUserData()   // no callback = fine, undefined check handles it
    }

    onVisibleChanged: {
        if (visible) {
            loadSessions();
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
            if (item.hasOwnProperty("app_color"))             item.app_color             = profilescreen.app_color
            if (item.hasOwnProperty("userName"))              item.userName              = profilescreen.userName
            if (item.hasOwnProperty("displayName"))           item.displayName           = profilescreen.displayName
            if (item.hasOwnProperty("userEmail"))             item.userEmail             = profilescreen.userEmail
            if (item.hasOwnProperty("totalDurationFormatted"))item.totalDurationFormatted= profilescreen.totalDurationFormatted
            if (item.hasOwnProperty("missionsCompleted"))     item.missionsCompleted     = profilescreen.missionsCompleted
            if (item.hasOwnProperty("mobileNo"))              item.mobileNo              = profilescreen.mobileNo

            Qt.callLater(function() {

                if (item.hasOwnProperty("rpcCompletedStatus"))
                    item.rpcCompletedStatus =
                            Number(MapGlobals.rpcStatus)

                if (item.hasOwnProperty("mobileNo"))
                    item.mobileNo =
                            MapGlobals.mobileNo
            })

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
                    loadUserData(function() {
                        currentView = "profile"
                    })
                })
            }
        }
    }

    Component {
        id: logoutDialog
        QGCPopupDialog {
            title: qsTr("Sign Out")
            buttons: Dialog.Yes | Dialog.No
            onAccepted: {
                QGroundControl.saveBoolGlobalSetting("login", false)
                MapGlobals.profile()
            }
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel { text: qsTr("Are you sure you want to sign out?") }
            }
        }
    }
}
