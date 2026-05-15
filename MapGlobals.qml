pragma Singleton

import QtQuick
import QGroundControl
import QGroundControl.Controls
import QtPositioning
import QGroundControl.QGCPositionManager

import QtQuick.LocalStorage


QtObject {
    property real mapRotation: 0
    property int recenterInterval: 10000 // Default 10 seconds
    property bool forceRecenter: false
    property string editdialog: "editdialog1"
    property var activeFlightMap: null  // Add global map reference
    property var gcsPosition: QGroundControl.qgcPositionManager.gcsPosition

    property string comefrom: "Plan"
    property string edit: "edit1"
    property string save: "save1"
    property real altitude: 30.5
    property string mapPolygon:" "

    property string time: "00:00:00"

    property string mark_with: "Mark_With_Manual"

    property string acres: ""

    property string appType: ""

    property string kmlPath: ""
    property string waypoint: "waypoint"

    property string currentView_profile: "profile"

    property bool share_edit_visibility : false
    property bool isReviewMode: false
    property bool showMissionItems: false
    property bool showEntryArrows: false   // true only while Rotate Entry Point is active
    property bool jumpToFileList: false
    property bool circleAddMode: false
    property int  squareCornerStep: -1
    property var  tempCorners: []
    property var  lastButtonPressTime: 0

    signal newSessionAdded()
    signal requestCloudSync()
    signal loadLocalPlan(string path)
    signal loadCloudPlan(var data)

    // Grid lines setting for Map Items
    property bool gridLines: QGroundControl.loadBoolGlobalSetting("gridLines", true)
    property real gridLineWidth: parseFloat(QGroundControl.loadGlobalSetting("gridLineWidth", "5"))
    property color gridColor: QGroundControl.loadGlobalSetting("gridColor", "#011F05")
    property color obstacleColor: QGroundControl.loadGlobalSetting("obstacleColor", "#F1C40F")
    property real obstacleLineWidth: parseFloat(QGroundControl.loadGlobalSetting("obstacleLineWidth", "2"))
    property real obstacleOpacity: parseFloat(QGroundControl.loadGlobalSetting("obstacleOpacity", "0.2"))

    function setGridLines(value) {
        gridLines = value
        QGroundControl.saveBoolGlobalSetting("gridLines", value)
        console.log("gridLines" , value)
    }

    function setGridLineWidth(value) {
        gridLineWidth = value
        QGroundControl.saveGlobalSetting("gridLineWidth", value.toString())
        console.log("gridLineWidth", value)
    }

    function setGridColor(value) {
        gridColor = value
        QGroundControl.saveGlobalSetting("gridColor", value.toString())
        console.log("gridColor", value)
    }

    function setObstacleColor(value) {
        obstacleColor = value
        QGroundControl.saveGlobalSetting("obstacleColor", value.toString())
        console.log("obstacleColor", value)
    }

    function setObstacleLineWidth(value) {
        obstacleLineWidth = value
        QGroundControl.saveGlobalSetting("obstacleLineWidth", value.toString())
        console.log("obstacleLineWidth", value)
    }

    function setObstacleOpacity(value) {
        obstacleOpacity = value
        QGroundControl.saveGlobalSetting("obstacleOpacity", value.toString())
        console.log("obstacleOpacity", value)
    }

    //MainRootWindow reference variables.
    property var rootWindow

    property var modeBtn1

    property string login: ""
    property string userName: QGroundControl.loadGlobalSetting("username", "Guest")
    property string userEmail: QGroundControl.loadGlobalSetting("email", "")
    property string displayName: QGroundControl.loadGlobalSetting("name", "")
    property string backendUrl: "https://qgc-backend-215243751192.asia-south1.run.app/api" // MUST NOT use localhost


    function recenterMap() {
        console.log("MapGlobals.recenterMap()")
        if (activeFlightMap && gcsPosition.isValid) {
            activeFlightMap.center = gcsPosition
            activeFlightMap.zoomLevel = 19
        }else {
            rootWindow.showToastMessage("GPS Not Set");
        }
    }

    function getDatabase() {
        console.log("MapGlobals.getDatabase")
        return LocalStorage.openDatabaseSync("QGCUserDB", "1.0", "User DB", 1000000);
    }

    function initDB() {
        console.log("MapGlobals.initDB()")
        var db = getDatabase();
        db.transaction(function(tx) {
            try {

                // Users table - simplified
                tx.executeSql("CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, displayname TEXT NOT NULL, email TEXT UNIQUE NOT NULL, password TEXT NOT NULL, mobile_number TEXT, rpc_completed INTEGER DEFAULT 0, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");

                // Drone sessions table - simplified
                tx.executeSql("CREATE TABLE IF NOT EXISTS drone_sessions(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, start_time TEXT NOT NULL, end_time TEXT NOT NULL, duration INTEGER)");


                //feedback table
                tx.executeSql("CREATE TABLE IF NOT EXISTS feedback (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, mobile_number TEXT, email TEXT, comments TEXT)");

                // Fences table
                tx.executeSql("CREATE TABLE IF NOT EXISTS fences (plan_path TEXT PRIMARY KEY, lat REAL, lon REAL, radius REAL)");

                console.log("Database and tables created successfully");

            } catch (error) {
                console.error("Error creating database:", error);
            }
        });
    }

    //saveDroneSession
    function saveDroneSession(date, startTime, endTime, sessionType = "Connection") {
        console.log("MapGlobals.saveDroneSession() - Type:", sessionType)
        var duration = calculateDuration(startTime, endTime);
        var data = {
            "username": QGroundControl.loadGlobalSetting("username", "Guest"),
            "date": date,
            "start_time": startTime,
            "end_time": endTime,
            "duration": duration,
            "session_type": sessionType
        };

        // --- Local Persistence ---
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                tx.executeSql(
                    "INSERT INTO drone_sessions (date, start_time, end_time, duration) VALUES (?, ?, ?, ?)",
                    [date, startTime, endTime, duration]
                );
                console.log("Session saved locally to SQLite");
                newSessionAdded(); // Notify listeners (like LogFiles.qml) to refresh
            } catch (error) {
                console.error("Error saving session locally:", error);
            }
        });

        // --- Remote Persistence ---
        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/sessions");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    console.log("Session saved successfully to backend:", xhr.responseText);
                    if (rootWindow) {
                        rootWindow.sessionSaved = true;
                    }
                } else {
                    console.error("Error saving session to backend:", xhr.responseText);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function saveMissionLog(missionName, planData, controller) {
        console.log("MapGlobals.saveMissionLog()", missionName);
        var currentUserName = QGroundControl.loadGlobalSetting("username", "Guest");
        if (currentUserName === "Guest" || !currentUserName) {
            console.error("No user logged in, mission logged as Guest or omitted");
        }

        if (!controller) {
            console.error("No controller provided to saveMissionLog");
            return;
        }

        var visualItems = controller.missionController.visualItems;
        var coords = [];
        for (var i = 0; i < visualItems.count; i++) {
            var item = visualItems.get(i);
            if (item.coordinate && item.coordinate.latitude !== undefined && item.coordinate.latitude !== 0) {
                coords.push([item.coordinate.longitude, item.coordinate.latitude]);
            }
        }

        var name = missionName.toString().split('/').pop().split('\\').pop();

        var data = {
            "username": currentUserName,
            "mission_name": name,
            "plan_data": typeof planData === 'string' ? JSON.parse(planData) : planData,
            "geometry": {
                "type": coords.length === 1 ? "Point" : (coords.length > 1 ? "LineString" : "Point"),
                "coordinates": coords.length === 1 ? coords[0] : (coords.length > 1 ? coords : [0,0])
            },
            "date": new Date().toISOString()
        };

        var postXhr = new XMLHttpRequest();
        postXhr.open("POST", backendUrl + "/missions");
        postXhr.setRequestHeader("Content-Type", "application/json");
        postXhr.onreadystatechange = function() {
            if (postXhr.readyState === XMLHttpRequest.DONE) {
                console.log("Mission log save response:", postXhr.status, postXhr.responseText);
            }
        };

        // Send DELETE first to prevent the backend from creating a duplicate (+1)
        var deleteXhr = new XMLHttpRequest();
        deleteXhr.open("DELETE", backendUrl + "/missions/by-name/" + encodeURIComponent(name));
        deleteXhr.onreadystatechange = function() {
            if (deleteXhr.readyState === XMLHttpRequest.DONE) {
                console.log("Mission log pre-save delete response:", deleteXhr.status);
                postXhr.send(JSON.stringify(data));
            }
        };
        deleteXhr.send();
    }

    function deleteMissionLog(missionName) {
        console.log("MapGlobals.deleteMissionLog()", missionName);
        var name = missionName.toString().split('/').pop().split('\\').pop();

        var xhr = new XMLHttpRequest();
        xhr.open("DELETE", backendUrl + "/missions/by-name/" + encodeURIComponent(name));
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Mission log delete response:", xhr.status, xhr.responseText);
            }
        };
        xhr.send();
    }

    function getMissionsFromCloud(username, callback) {
        console.log("MapGlobals.getMissionsFromCloud() for:", username);
        if (!username || username === "Guest") {
            if (callback) callback([]);
            return;
        }

        var xhr = new XMLHttpRequest();
        xhr.open("GET", backendUrl + "/missions?username=" + encodeURIComponent(username));
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var missions = JSON.parse(xhr.responseText);
                        console.log("Found", missions.length, "missions in cloud");
                        if (callback) callback(missions);
                    } catch (e) {
                        console.error("Error parsing cloud missions:", e);
                        if (callback) callback([]);
                    }
                } else {
                    console.error("Error fetching cloud missions:", xhr.status, xhr.responseText);
                    if (callback) callback([]);
                }
            }
        };
        xhr.send();
    }

    function insertFeedback(username, mobile_number, email, comments, callback) {
        console.log("MapGlobals.insertFeedback()")
        var data = {
            "username": username,
            "mobile_number": mobile_number,
            "email": email,
            "comments": comments
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/feedback");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    console.log("Feedback submitted successfully");
                    if (callback) callback(true);
                } else {
                    console.error("Feedback submission failed:", xhr.responseText);
                    if (callback) callback(false);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function normalizePath(path) {
        if (!path) return ""
        var s = path.toString()
        // Extract just the filename and clean it of URI encoding
        var parts = s.split(/[\/\\]/)
        var filename = parts[parts.length - 1]
        filename = decodeURIComponent(filename)
        console.log("MapGlobals.normalizePath() -> Clean Filename:", filename)
        return filename
    }

    function saveFence(planPath, lat, lon, radius) {
        var cleanPath = normalizePath(planPath)
        console.log("MapGlobals.saveFence() normalized path:", cleanPath)
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                tx.executeSql(
                    "INSERT OR REPLACE INTO fences (plan_path, lat, lon, radius) VALUES (?, ?, ?, ?)",
                    [cleanPath, lat, lon, radius]
                );
                console.log("Fence saved to database for:", cleanPath);
            } catch (error) {
                console.error("Error saving fence to database:", error);
            }
        });
    }

    function getFence(planPath, callback) {
        var cleanPath = normalizePath(planPath)
        console.log("MapGlobals.getFence() normalized path:", cleanPath)
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                var rs = tx.executeSql("SELECT * FROM fences WHERE plan_path = ?", [cleanPath]);
                if (rs.rows.length > 0) {
                    console.log("Fence found for:", cleanPath);
                    callback(rs.rows.item(0));
                } else {
                    console.log("No fence found for:", cleanPath);
                    callback(null);
                }
            } catch (error) {
                console.error("Error retrieving fence from database:", error);
                callback(null);
            }
        });
    }

    //calculate the duration from startsession to end session
    function calculateDuration(startTime, endTime) {
        console.log("MapGlobals.calculateDuration()")
        try {
            // Parse times (format: "HH:mm:ss")
            var startParts = startTime.split(':');
            var endParts = endTime.split(':');

            var startTotalSeconds = parseInt(startParts[0]) * 3600 +
                    parseInt(startParts[1]) * 60 +
                    parseInt(startParts[2] || 0);

            var endTotalSeconds = parseInt(endParts[0]) * 3600 +
                    parseInt(endParts[1]) * 60 +
                    parseInt(endParts[2] || 0);

            var durationSeconds = endTotalSeconds - startTotalSeconds;

            if (durationSeconds < 0) {
                // Handle(session spans midnight)
                durationSeconds += 24 * 3600;
            }

            return Math.round(durationSeconds / 60); // Convert to minutes

        } catch (e) {
            console.error("Error calculating duration:", e);
            return 0;
        }
    }

    function getAllSessions(callback) {
        console.log("MapGlobals.getAllSessions()")
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                var rs = tx.executeSql("SELECT * FROM drone_sessions ORDER BY date DESC, start_time DESC");
                var sessions = [];

                console.log("Found", rs.rows.length, "drone sessions in database");

                for (var i = 0; i < rs.rows.length; i++) {
                    sessions.push(rs.rows.item(i));
                }

                if (callback) {
                    callback(sessions);
                }

            } catch (error) {
                console.error("Error retrieving sessions:", error);
                if (callback) {
                    callback([]);
                }
            }
        });
    }

    function sendOTP(email, callback) {
        console.log("MapGlobals.sendOTP() - Requesting OTP for:", email);
        var data = { "email": email };
        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/send-otp");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    if (rootWindow) rootWindow.showToastMessage(response.message || "OTP sent successfully");
                    if (callback) callback(true);
                } else {
                    var errorMsg = "Failed to send OTP";
                    try {
                        var errorResp = JSON.parse(xhr.responseText);
                        errorMsg = errorResp.message || errorMsg;
                    } catch (e) {}
                    if (rootWindow) rootWindow.showToastMessage(errorMsg);
                    if (callback) callback(false);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function verifyOTP(email, otp, callback) {
        console.log("MapGlobals.verifyOTP() - Verifying OTP for:", email);
        var data = { "email": email, "otp": otp };
        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/verify-otp");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    // if (rootWindow) rootWindow.showToastMessage(response.message || "OTP verified successfully");
                    if (callback) callback(true);
                } else {
                    var errorMsg = "Verification failed";
                    try {
                        var errorResp = JSON.parse(xhr.responseText);
                        errorMsg = errorResp.message || errorMsg;
                    } catch (e) {}
                    if (rootWindow) rootWindow.showToastMessage(errorMsg);
                    if (callback) callback(false);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function logParameterActivity(username, email, activity = "Accessed Parameters") {
        console.log("MapGlobals.logParameterActivity() - Logging activity for:", username);
        var data = {
            "username": username,
            "email": email,
            "activity": activity
        };
        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/parameter-activity");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    console.log("Parameter activity logged successfully");
                } else {
                    console.error("Failed to log parameter activity:", xhr.responseText);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function registerUser(username, displayname, email, password, confirmpassword, otp, callback) {
        console.log("MapGlobals.registerUser() - Attempting registration for:", username);
        console.log("Backend URL:", backendUrl + "/register");

        var data = {
            "username": username,
            "displayname": displayname,
            "email": email,
            "password": password,
            "otp": otp
        };

        var xhr = new XMLHttpRequest();

        xhr.onreadystatechange = function() {
            var statusString = "N/A";
            try {
                if (xhr.readyState >= 2) statusString = xhr.status;
            } catch (e) {
                // Ignore invalid state errors during intermediate ready states
            }

            console.log("XHR State Change:", xhr.readyState, "Status:", statusString);

            if (xhr.readyState === XMLHttpRequest.DONE) {
                var currentStatus = 0;
                try {
                    currentStatus = xhr.status;
                } catch (e) {
                    console.error("Critical error accessing XHR status at DONE state");
                }

                if (currentStatus === 200 || currentStatus === 201) {
                    console.log("Registration successful response received");
                    console.log("Response:", xhr.responseText);
                    var responseData = null;
                    try {
                        responseData = JSON.parse(xhr.responseText);
                    } catch (e) {
                        console.error("Error parsing registration response:");
                    }
                    if (responseData && responseData.user) {
                        var user = responseData.user;
                        var db = getDatabase();
                        db.transaction(function(tx) {
                            tx.executeSql(
                                        "INSERT OR REPLACE INTO users (username, displayname, email, password, mobile_number, rpc_completed) VALUES (?, ?, ?, ?, ?, ?)",
                                        [user.username, user.displayname, user.email, user.password, user.mobile_number || "", user.rpc_completed || 0]
                                        );
                        });
                    }
                    if (callback) callback(true, responseData);
                } else {
                    console.error("Registration failed. Status:", currentStatus, "Response:", xhr.responseText);
                    var message = "Registration Failed";
                    if (currentStatus === 0) {
                        message = "Cannot connect to server at " + backendUrl + ". Check your network.";
                    } else if (xhr.responseText) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            message = response.message || message;
                        } catch (e) {
                            console.error("Error parsing error response:", e);
                            message = "Server error (Invalid JSON response)";
                        }
                    }
                    if (rootWindow) {
                        rootWindow.showToastMessage(message);
                    } else {
                        console.error("rootWindow is NULL, cannot show toast:", message);
                    }
                    if (callback) callback(false, null);
                }
            }
        }

        xhr.open("POST", backendUrl + "/register");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 60000;

        xhr.ontimeout = function() {
            console.error("Registration request timed out for:", backendUrl);
            if (rootWindow) rootWindow.showToastMessage("Connection timed out. Backend might be spinning up.", true);
            if (callback) callback(false);
        };

        xhr.onerror = function() {
            console.error("Networking error occurred during registration. Possible causes: Firewall, server down, or different WiFi.");
            if (rootWindow) rootWindow.showToastMessage("Network error. Ensure device can ping " + backendUrl, true);
            if (callback) callback(false);
        };

        console.log("Sending data:", JSON.stringify(data));
        xhr.send(JSON.stringify(data));
    }

    //Reset Password
    function resetPassword(username, newPass, callback) {
        console.log("MapGlobals.resetPassword() - Username:", username);

        var data = {
            "username": username,
            "password": newPass
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/reset-password");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 60000;

        xhr.ontimeout = function() {
            console.error("Reset password timed out");
            if (rootWindow) rootWindow.showToastMessage("Reset password timed out. Backend might be spinning up.", true);
            if (callback) callback({success: false, message: "Connection timed out"});
        };

        xhr.onerror = function() {
            console.error("Network error during reset password");
            if (rootWindow) rootWindow.showToastMessage("Network error", true);
            if (callback) callback({success: false, message: "Network error"});
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log("Password reset on backend successfully");

                    // Now update local DB if user exists
                    var db = getDatabase();
                    db.transaction(function(tx) {
                        var rs = tx.executeSql("UPDATE users SET password = ? WHERE username = ?", [newPass, username]);
                        if (rs.rowsAffected > 0) {
                            console.log("Local password updated as well");
                        }
                    });

                    if (callback) callback({success: true, message: "Password reset successfully!"});
                } else {
                    console.error("Failed to reset password on backend:", xhr.responseText);
                    var message = "Failed to reset password";
                    try {
                        var response = JSON.parse(xhr.responseText);
                        message = response.message || message;
                    } catch (e) {}
                    if (callback) callback({success: false, message: message});
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function updateUser(old_userName, new_username, newDisplayname, newEmail, mobile_no, _rpcCompleted, callback) {
        console.log("MapGlobals.updateUser() - From:", old_userName, "To:", new_username);

        var data = {
            "old_username": old_userName,
            "username": new_username,
            "displayname": newDisplayname,
            "email": newEmail,
            "mobile_number": mobile_no,
            "rpc_completed": _rpcCompleted
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/update-user");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 60000;

        xhr.ontimeout = function() {
            console.error("Update user timed out");
            if (rootWindow) rootWindow.showToastMessage("Update timed out. Backend might be spinning up.", true);
            if (callback) callback(false);
        };

        xhr.onerror = function() {
            console.error("Network error during update user");
            if (rootWindow) rootWindow.showToastMessage("Network error during update", true);
            if (callback) callback(false);
        };

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    console.log("Profile updated on backend successfully");

                    // Now update local DB
                    var db = getDatabase();
                    db.transaction(function(tx) {
                        var rs = tx.executeSql(
                                    "UPDATE users SET username = ?, displayname = ?, email = ?, mobile_number = ?, rpc_completed = ? WHERE username = ?",
                                    [new_username, newDisplayname, newEmail, mobile_no, _rpcCompleted, old_userName]
                                    );
                        if (rs.rowsAffected > 0) {
                            console.log("Local user database updated successfully");
                        }
                    });

                    if (callback) callback(true);
                } else {
                    console.error("Failed to update profile on backend. Status:", xhr.status, "Response:", xhr.responseText);
                    var message = "Failed to update profile on server";
                    try {
                        var response = JSON.parse(xhr.responseText);
                        message = response.message || message;
                    } catch (e) {}
                    if (rootWindow) rootWindow.showToastMessage(message);
                    if (callback) callback(false);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function deleteUser(username) {
        console.log("MapGlobals.deleteUser()")
        var db = getDatabase();
        db.transaction(function(tx) {
            var rs = tx.executeSql(
                        "DELETE FROM users WHERE username = ?",
                        [username]
                        );
            if (rs.rowsAffected > 0) {
                console.log("User deleted");
                rootWindow.showToastMessage("User deleted");
            } else {
                console.log("User not found");
                rootWindow.showToastMessage("User not found");
            }
        });
    }

    function validateNotEmpty(field, fieldName, focusField) {
        console.log("MapGlobals.validateNotEmpty()")
        if (field.trim() === "") {
            rootWindow.showToastMessage(`Please enter your ${fieldName}`);
            if (focusField) focusField.focus = true;
            return false;
        }
        return true;
    }

    function validateUsername(username, focusField, isUpdate = false) {
        console.log("MapGlobals.validateUsername()")
        if (!validateNotEmpty(username, "username", focusField)) return false;

        if (username.length < 3) {
            rootWindow.showToastMessage("Username must be at least 3 characters long");
            if (focusField) focusField.focus = true;
            return false;
        }

        if (!/^[a-zA-Z0-9_]+$/.test(username)) {
            rootWindow.showToastMessage("Username can only contain letters, numbers, and underscores");
            if (focusField) focusField.focus = true;
            return false;
        }

        // For account creation, you might want to check if username already exists
        if (!isUpdate) {
            // Simulate checking if username exists
            if (username === "existinguser") {
                rootWindow.showToastMessage("Username already taken");
                if (focusField) focusField.focus = true;
                return false;
            }
        }

        return true;
    }

    function validateDisplayName(displayName, focusField) {
        console.log("MapGlobals.validateDisplayName()")
        if (!validateNotEmpty(displayName, "display name", focusField)) return false;

        if (displayName.length < 2) {
            rootWindow.showToastMessage("Display name must be at least 2 characters long");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    function validateEmail(email, focusField, isUpdate = false) {
        console.log("MapGlobals.validateEmail()")
        if (!validateNotEmpty(email, "email address", focusField)) return false;

        // Comprehensive email validation regex
        var emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

        if (!emailRegex.test(email)) {
            rootWindow.showToastMessage("Please enter a valid email address");
            if (focusField) focusField.focus = true;
            return false;
        }

        // For account creation, you might want to check if email already exists
        if (!isUpdate) {
            // Simulate checking if email exists
            if (email === "existing@example.com") {
                rootWindow.showToastMessage("Email already registered");
                if (focusField) focusField.focus = true;
                return false;
            }
        }

        return true;
    }

    function validatePassword(password, focusField, isUpdate = false) {

        console.log("MapGlobals.validatePassword()")
        // For update, password is optional (only validate if provided)
        if (isUpdate && password === "") return true;

        if (!validateNotEmpty(password, "password", focusField)) return false;

        if (password.length < 8) {
            rootWindow.showToastMessage("Password must be at least 8 characters long");
            if (focusField) focusField.focus = true;
            return false;
        }

        // Check for password strength
        var hasUpperCase = /[A-Z]/.test(password);
        var hasLowerCase = /[a-z]/.test(password);
        var hasNumbers = /[0-9]/.test(password);
        var hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

        var strengthScore = (hasUpperCase ? 1 : 0) + (hasLowerCase ? 1 : 0) +
                (hasNumbers ? 1 : 0) + (hasSpecialChar ? 1 : 0);

        if (strengthScore < 3) {
            rootWindow.showToastMessage("Password should include uppercase, lowercase, numbers, and special characters");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    function validateConfirmPassword(password, confirmPassword, focusField, isUpdate = false) {
        console.log("MapGlobals.validateConfirmPassword()")
        // For update, confirm password is only required if password is provided
        if (isUpdate && password === "" && confirmPassword === "") return true;

        if (!validateNotEmpty(confirmPassword, "password confirmation", focusField)) return false;

        if (password !== confirmPassword) {
            rootWindow.showToastMessage("Passwords don't match");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    function validateMobileNumber(mobile, focusField) {
        console.log("MapGlobals.validateMobileNumber()")
        if (!validateNotEmpty(mobile, "mobile number", focusField)) return false;

        // Basic mobile number validation
        var mobileRegex = /^[\+]?[1-9][\d]{0,15}$/;
        var cleanedMobile = mobile.replace(/[-\s\(\)]/g, '');

        if (!mobileRegex.test(cleanedMobile)) {
            rootWindow.showToastMessage("Please enter a valid mobile number");
            if (focusField) focusField.focus = true;
            return false;
        }

        return true;
    }

    // function loginUserFunc(username, password,callback) {
    //     var db = getDatabase();
    //     var result = false;

    //     db.transaction(function(tx) {
    //         var rs = tx.executeSql("SELECT * FROM users WHERE username=? AND password=?", [username, password]);
    //         console.log("inserted=========",rs)
    //         if (rs.rows.length > 0) {
    //             console.log("Login Success");
    //             result = true;
    //             //loginLoader.visible = false;
    //             rootWindow.homescreen();
    //             rootWindow.showToastMessage("Login Successfully");
    //             login="login"
    //             QGroundControl.saveBoolGlobalSetting("login", true)

    //         } else {
    //             result = false;
    //             console.log("Invalid Credentials");
    //             rootWindow.showToastMessage("Incorrect username or password");
    //         }

    //         if (callback) {
    //             callback(result);
    //         }

    //     });
    // }


    function loginUserFunc(userInput, password, callback) {
        console.log("MapGlobals.loginUserFunc() - Authenticating for:", userInput);
        console.log("Backend URL:", backendUrl + "/login");

        var data = {
            "userInput": userInput,
            "password": password
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/login");
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.timeout = 60000;

        xhr.ontimeout = function() {
            console.error("Login request timed out");
            if (rootWindow) rootWindow.showToastMessage("Login timed out. Backend might be spinning up.", true);
            if (callback) callback(false);
        };

        xhr.onerror = function() {
            console.error("Networking error during login");
            if (rootWindow) rootWindow.showToastMessage("Network error", true);
            if (callback) callback(false);
        };

        xhr.onreadystatechange = function() {
            var statusString = "N/A";
            try {
                if (xhr.readyState >= 2) statusString = xhr.status;
            } catch (e) { }

            console.log("XHR State Change (Login):", xhr.readyState, "Status:", statusString);

            if (xhr.readyState === XMLHttpRequest.DONE) {
                var currentStatus = 0;
                try { currentStatus = xhr.status; } catch (e) { }

                if (currentStatus === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        console.log("Login Success response received");

                        var user = response.user;

                        QGroundControl.saveGlobalSetting("username", user.username);
                        QGroundControl.saveGlobalSetting("email", user.email);
                        QGroundControl.saveGlobalSetting("name", user.displayname);
                        QGroundControl.saveBoolGlobalSetting("login", true);
                        userName = user.username;
                        userEmail = user.email;
                        displayName = user.displayname;

                        // Sync to local SQLite
                        var db = getDatabase();
                        db.transaction(function(tx) {
                            tx.executeSql(
                                        "INSERT OR REPLACE INTO users (username, displayname, email, password, mobile_number, rpc_completed) VALUES (?, ?, ?, ?, ?, ?)",
                                        [user.username, user.displayname, user.email, user.password, user.mobile_number || "", user.rpc_completed || 0]
                                        );
                        });

                        if (rootWindow) {
                            rootWindow.homescreen();
                            rootWindow.showToastMessage("Login Successfully");
                        } else {
                            console.error("MapGlobals: rootWindow is null, cannot navigate to homescreen");
                        }
                        login = "login";

                        if (callback) callback(true);

                        // After successful login, sync sessions
                        fetchCloudSessions(user.email);

                    } catch (e) {
                        console.error("Error parsing login response:", e);
                        if (rootWindow) rootWindow.showToastMessage("Error processing login response");
                        if (callback) callback(false);
                    }
                } else {
                    console.error("Login Failed. Status:", currentStatus, "Response:", xhr.responseText);
                    var message = "Incorrect username or password";
                    if (currentStatus === 0) {
                        message = "Cannot connect to server at " + backendUrl;
                    } else if (xhr.responseText) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            message = response.message || message;
                        } catch (e) {
                            console.error("Error parsing error response:", e);
                        }
                    }
                    if (rootWindow) rootWindow.showToastMessage(message);
                    if (callback) callback(false);
                }
            }
        }

        console.log("Sending Login Data:", JSON.stringify(data));
        xhr.send(JSON.stringify(data));
    }


    // if (rsUser.rows.length > 0) {
    //     console.log("Login Success");
    //     result = true;
    //     //loginLoader.visible = false;
    //     rootWindow.homescreen();
    //     rootWindow.showToastMessage("Login Successfully");
    //     login="login"
    //     QGroundControl.saveBoolGlobalSetting("login", true)





    // } else {
    //     rootWindow.showToastMessage("Incorrect password");
    //     result = false;
    // }

    // callback(result);


    function loadUserData(username, callback) {
        console.log("Loading user data for:", username);

        if (username !== "") {
            var db = getDatabase();
            db.transaction(function(tx) {
                var selectRs = tx.executeSql(
                            "SELECT * FROM users WHERE username = ?",
                            [username]
                            );

                var result = null;
                if (selectRs.rows.length > 0) {
                    result = selectRs.rows.item(0);
                    console.log("User data found:", result);
                    console.log("In MainrootWindow rpc_completed:", result.rpc_completed)
                } else {
                    console.log("No user found with username:", username);
                }

                // Call the callback with the result
                if (callback) {
                    callback(result);
                }
            });
        } else {
            if (callback) {
                callback(null);
            }
        }
    }

    function profile() {


        console.log("profile method MapGLobals")

        var loginpage= QGroundControl.loadBoolGlobalSetting("login",false)

        if(loginpage===true) {
            console.log("profile method MapGLobals inside the IF")
            //loginLoader.visible = false;
            rootWindow.homescreen();
            QGroundControl.saveBoolGlobalSetting("login", true)
            modeBtn1.visible = false

            // Sync sessions on startup if logged in
            var userEmail = QGroundControl.loadGlobalSetting("email", "");
            if (userEmail !== "") {
                fetchCloudSessions(userEmail);
            }

        } else {
            console.log("profile method MapGLobals inside the Else")
            //loginLoader.visible = true;
            //homescreen.visible = false
            rootWindow.openWelcomeScreen();
            QGroundControl.saveBoolGlobalSetting("login", false);
        }
    }

    // Just print the feedback table
    function printFeedbackTable(resultSet, label) {
        console.log("MapGlobals.printFeedbackTable()")
        console.log("ID | Username | Mobile | Email | Comments");
        console.log("------------------------------------------");

        if (resultSet.rows.length === 0) {
            console.log("No feedback records found");
        } else {
            for (var i = 0; i < resultSet.rows.length; i++) {
                var feedback = resultSet.rows.item(i);
                // Truncate long comments for better readability
                var truncatedComments = feedback.comments.length > 30 ?
                            feedback.comments.substring(0, 30) + "..." :
                            feedback.comments;

                console.log(feedback.id + " | " +
                            (feedback.username || "NULL") + " | " +
                            (feedback.mobile_number || "NULL") + " | " +
                            (feedback.email || "NULL") + " | " +
                            truncatedComments);
            }
        }
        console.log("------------------------------------------");
    }

    // Just print the Session table
    function printSessionTable() {
        console.log("MapGlobals.printSessionTable()")
        var db = getDatabase();
        db.transaction(function(tx) {
            try {
                var resultSet = tx.executeSql("SELECT * FROM drone_sessions ORDER BY id");

                console.log("ID | date | start_time | end_time | duration");
                console.log("------------------------------------------");

                if (resultSet.rows.length === 0) {
                    console.log("No Session records found");
                } else {
                    for (var i = 0; i < resultSet.rows.length; i++) {
                        var session = resultSet.rows.item(i);
                        console.log(
                                    session.id + " | " +
                                    (session.date || "NULL") + " | " +
                                    (session.start_time || "NULL") + " | " +
                                    (session.end_time || "NULL") + " | " +
                                    (session.duration || "NULL")
                                    );
                    }
                }

                console.log("------------------------------------------");

            } catch (error) {
                console.error("Error reading drone session:", error);
            }
        });
    }

    Component.onCompleted: {
        userName = QGroundControl.loadGlobalSetting("username", "Guest")
        console.log("MapGlobals initialized. Current user:", userName)
    }

    // Cloud Plan Synchronization
    function savePlanToCloud(planName, planContent, callback) {
        var email = QGroundControl.loadGlobalSetting("email", "");
        var username = QGroundControl.loadGlobalSetting("username", "Guest");

        if (email === "") {
            console.error("Cannot save to cloud: User not logged in");
            if (callback) callback(false);
            return;
        }

        console.log("MapGlobals.savePlanToCloud() - Plan:", planName);

        var data = {
            "username": username,
            "email": email,
            "plan_name": planName,
            "plan_data": planContent
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/plans");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    console.log("Plan synced to cloud successfully");
                    if (callback) callback(true);
                } else {
                    console.error("Failed to sync plan to cloud:", xhr.responseText);
                    if (callback) callback(false);
                }
            }
        }
        xhr.send(JSON.stringify(data));
    }

    function fetchCloudPlans(userIdentifier, callback) {
        var username = QGroundControl.loadGlobalSetting("username", "Guest");
        
        if (!username || username === "" || username === "Guest") {
            console.error("Cannot fetch from cloud: No valid username provided");
            if (callback) callback([]);
            return;
        }

        console.log("MapGlobals.fetchCloudPlans() - Requesting plans for username:", username);

        var xhr = new XMLHttpRequest();
        // Based on DB explorer, missions are stored in the 'missions' collection
        xhr.open("GET", backendUrl + "/missions?username=" + encodeURIComponent(username));
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var responseData = JSON.parse(xhr.responseText);
                        var rawPlans = [];
                        
                        if (Array.isArray(responseData)) {
                            rawPlans = responseData;
                        } else if (responseData.missions && Array.isArray(responseData.missions)) {
                            rawPlans = responseData.missions;
                        }

                        console.log("Found", rawPlans.length, "raw missions in cloud");

                        var uniquePlans = {};
                        for (var i = 0; i < rawPlans.length; i++) {
                            var p = rawPlans[i];
                            // Database uses 'mission_name' and 'plan_data'
                            var name = p.mission_name || p.plan_name || p.name || ("Untitled_" + i);
                            var data = p.plan_data || p.data;
                            
                            if (data) {
                                uniquePlans[name] = {
                                    plan_name: name,
                                    plan_data: data
                                };
                            }
                        }

                        var plans = Object.values(uniquePlans);
                        console.log("Successfully processed", plans.length, "plans");
                        if (callback) callback(plans);
                    } catch (e) {
                        console.error("Error parsing cloud missions response:", e);
                        if (callback) callback([]);
                    }
                } else {
                    console.error("Failed to fetch cloud missions. Status:", xhr.status, "Response:", xhr.responseText);
                    if (callback) callback([]);
                }
            }
        }
        xhr.send();
    }
    function deleteCloudPlan(planName, callback) {
        console.log("MapGlobals.deleteCloudPlan() - Deleting:", planName);
        var xhr = new XMLHttpRequest();
        xhr.open("DELETE", backendUrl + "/missions/by-name/" + encodeURIComponent(planName));
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 204) {
                    console.log("Plan deleted from cloud successfully");
                    if (callback) callback(true);
                } else {
                    console.error("Failed to delete plan from cloud:", xhr.responseText);
                    if (callback) callback(false);
                }
            }
        };
        xhr.send();
    }
    function fetchCloudSessions(email) {
        console.log("MapGlobals.fetchCloudSessions() for:", email);
        var xhr = new XMLHttpRequest();
        xhr.open("GET", backendUrl + "/sessions?email=" + encodeURIComponent(email));
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var sessions = JSON.parse(xhr.responseText);
                        console.log("Fetched", sessions.length, "sessions from cloud");

                        var db = getDatabase();
                        db.transaction(function(tx) {
                            for (var i = 0; i < sessions.length; i++) {
                                var s = sessions[i];
                                // Check if session already exists by date/time to avoid duplicates
                                tx.executeSql(
                                    "INSERT INTO drone_sessions (date, start_time, end_time, duration) " +
                                    "SELECT ?, ?, ?, ? WHERE NOT EXISTS (" +
                                    "SELECT 1 FROM drone_sessions WHERE date = ? AND start_time = ? AND end_time = ?" +
                                    ")",
                                    [s.date, s.start_time, s.end_time, s.duration, s.date, s.start_time, s.end_time]
                                );
                            }
                        });
                        newSessionAdded(); // Refresh UI
                    } catch (e) {
                        console.error("Error parsing cloud sessions:", e);
                    }
                }
            }
        }
        xhr.send();
    }
}
