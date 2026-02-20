pragma Singleton

import QtQuick
import QGroundControl
import QGroundControl.Controls
import QtPositioning
import QGroundControl.QGCPositionManager

import QtQuick.LocalStorage 2.0


QtObject {
    property real mapRotation: 0
    property int recenterInterval: 10000 // Default 10 seconds
    property bool forceRecenter: false
    property var activeFlightMap: null  // Add global map reference
    property var gcsPosition: QGroundControl.qgcPositionManager.gcsPosition

    property string comefrom: "Plan"
    property string edit: "edit1"
    property string save: "save1"
    property real altitude: 0
    property string mapPolygon:" "

    property string time: "00:00:00"

    property string mark_with: "Mark_With_Manual"

    property string acres: ""

    property string appType: ""

    property string kmlPath: ""
    property string waypoint: "waypoint"

    property string currentView_profile: "profile"

    property bool share_edit_visibility : false

    signal newSessionAdded()

    //MainRootWindow reference variables.
    property var rootWindow

    property var modeBtn1

    property string login: ""
    property string backendUrl: "https://qgc-backend.onrender.com/api"
    // property string backendUrl: "http://localhost:5000/api"


    function recenterMap() {
        console.log("MapGlobals.recenterMap()")
        if (activeFlightMap && gcsPosition.isValid) {
            activeFlightMap.center = gcsPosition
            activeFlightMap.zoomLevel = 15
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
                tx.executeSql("CREATE TABLE IF NOT EXISTS users(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    displayname TEXT NOT NULL,
                    email TEXT UNIQUE NOT NULL,
                    password TEXT NOT NULL,
                    mobile_number TEXT,
                    rpc_completed INTEGER DEFAULT 0,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )");


                // Drone sessions table - simplified
                tx.executeSql("CREATE TABLE IF NOT EXISTS drone_sessions(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    date TEXT NOT NULL,
                    start_time TEXT NOT NULL,
                    end_time TEXT NOT NULL,
                    duration INTEGER
                )");


                //feedback table
                tx.executeSql("CREATE TABLE IF NOT EXISTS feedback (
                               id INTEGER PRIMARY KEY AUTOINCREMENT,
                               username TEXT,
                               mobile_number TEXT,
                               email TEXT,
                               comments TEXT
                           )");

                console.log("Database and tables created successfully");

            } catch (error) {
                console.error("Error creating database:", error);
            }
        });
    }

    //saveDroneSession
    function saveDroneSession(date, startTime, endTime) {
        console.log("MapGlobals.saveDroneSession()")
        var duration = calculateDuration(startTime, endTime);
        var data = {
            "username": QGroundControl.loadGlobalSetting("username", "Guest"),
            "date": date,
            "start_time": startTime,
            "end_time": endTime,
            "duration": duration
        };

        var xhr = new XMLHttpRequest();
        xhr.open("POST", backendUrl + "/sessions");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    console.log("Session saved successfully:", xhr.responseText);
                    sessionSaved = true;
                    newSessionAdded();
                } else {
                    console.error("Error saving session:", xhr.responseText);
                }
            }
        }
        xhr.send(JSON.stringify(data));
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

    function registerUser(username, displayname, email, password, confirmpassword, callback) {
        console.log("MapGlobals.registerUser() - Attempting registration for:", username);
        console.log("Backend URL:", backendUrl + "/register");

        var data = {
            "username": username,
            "displayname": displayname,
            "email": email,
            "password": password
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

                        // Sync to local SQLite
                        var db = getDatabase();
                        db.transaction(function(tx) {
                            tx.executeSql(
                                "INSERT OR REPLACE INTO users (username, displayname, email, password, mobile_number, rpc_completed) VALUES (?, ?, ?, ?, ?, ?)",
                                [user.username, user.displayname, user.email, user.password, user.mobile_number || "", user.rpc_completed || 0]
                            );
                        });

                    if (rootWindow) {
                        rootWindow.newscreen();
                rootWindow.showToastMessage("Login Successfully");
                    } else {
                        console.error("MapGlobals: rootWindow is null, cannot navigate to newscreen");
                    }
                        login = "login";

                        if (callback) callback(true);
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


}
