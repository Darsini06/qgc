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
    //property var loginLoader
    //property var newscreen
    property var modeBtn1

    property string login: ""


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
        var db = MapGlobals.getDatabase();
        db.transaction(function(tx) {
            try {
                // Calculate duration in minutes
                var duration = calculateDuration(startTime, endTime);

                // Insert session with duration
                var rs = tx.executeSql(
                            "INSERT INTO drone_sessions(date, start_time, end_time, duration) VALUES(?, ?, ?, ?)",
                            [date, startTime, endTime, duration]
                            );

                if (rs.rowsAffected > 0) {
                    console.log("Session saved - ID:", rs.insertId,
                                "Date:", date,
                                "Start:", startTime,
                                "End:", endTime,
                                "Duration:", duration, "minutes");
                    sessionSaved = true;
                    newSessionAdded(); // Emit signal to notify other components
                }

            } catch (error) {
                console.error("Error saving drone session:", error);
            }
        });
    }

    function insertFeedback(username, mobile_number, email, comments, callback) {
        console.log("MapGlobals.insertFeedback()")
        var db = getDatabase();
        db.transaction(function(tx) {
            try {

                console.log("=== ALL FEEDBACK BEFORE INSERT ===");
                var beforeInsert = tx.executeSql("SELECT * FROM feedback ORDER BY id");
                printFeedbackTable(beforeInsert, "BEFORE INSERT");

                // Insert new feedback
                var rs = tx.executeSql(
                            "INSERT INTO feedback (username, mobile_number, email, comments) VALUES (?, ?, ?, ?)",
                            [username, mobile_number, email, comments]
                            );

                if (rs.rowsAffected > 0) {
                    console.log("Feedback inserted successfully");

                    // Print all data AFTER insert
                    console.log("=== ALL FEEDBACK AFTER INSERT ===");
                    var afterInsert = tx.executeSql("SELECT * FROM feedback ORDER BY id");
                    printFeedbackTable(afterInsert, "AFTER INSERT");

                    if (callback) {
                        callback(true);
                    }
                } else {
                    console.log("Feedback insertion failed");
                    if (callback) {
                        callback(false);
                    }
                }

            } catch (error) {
                console.error("Error inserting feedback:", error);
                if (callback) {
                    callback(false);
                }
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

    function registerUser(username, displayname, email, password, confirmpassword, callback) {
        console.log("MapGlobals.registerUser()")
        var db = getDatabase();
        var result = false;

        db.transaction(function(tx) {
            // Print input values
            console.log("=== USER REGISTRATION ATTEMPT ===");
            console.log("Username:", username);
            console.log("Display Name:", displayname);
            console.log("Email:", email);
            // Consider not logging passwords in production for security
            console.log("Password length:", password.length);
            console.log("Confirm Password length:", confirmpassword.length);

            // First check if username already exists
            var usernameCheck = tx.executeSql(
                        "SELECT id FROM users WHERE username = ?",
                        [username]
                        );

            if (usernameCheck.rows.length > 0) {
                console.log("Registration failed - username already exists");
                rootWindow.showToastMessage("Username already exists", true);
                if (callback) callback(false);
                return;
            }

            // Check if email already exists
            var emailCheck = tx.executeSql(
                        "SELECT id FROM users WHERE email = ?",
                        [email]
                        );

            if (emailCheck.rows.length > 0) {
                console.log("Registration failed - email already exists");
                rootWindow.showToastMessage("Email already registered", true);
                if (callback) callback(false);
                return;
            }

            var rs = tx.executeSql(
                        "INSERT INTO users(username, displayname, email, password) VALUES(?, ?, ?, ?)",
                        [username, displayname, email, password]
                        );

            if (rs.rowsAffected > 0) {
                console.log("Registration successful!");
                console.log("Rows affected:", rs.rowsAffected);
                console.log("Inserted ID:", rs.insertId);

                // Fetch and print the inserted record
                var selectRs = tx.executeSql(
                            "SELECT * FROM users WHERE id = ?",
                            [rs.insertId]
                            );

                if (selectRs.rows.length > 0) {
                    var insertedUser = selectRs.rows.item(0);
                    console.log("Inserted user details:");
                    console.log("ID:", insertedUser.id);
                    console.log("Username:", insertedUser.username);
                    console.log("Display Name:", insertedUser.displayname);
                    console.log("Email:", insertedUser.email);
                    console.log("RPC Completed:", insertedUser.rpc_completed);
                    console.log("Created At:", insertedUser.created_at);
                }

                result = true;
            } else {
                console.log("Registration failed - no rows affected");
                result = false;
            }

            console.log("=== REGISTRATION COMPLETED ===");

            if (callback) {
                callback(result);
            }
        });
    }

    //Reset Password
    function resetPassword(username, newPass, callback) {
        console.log("MapGlobals.resetPassword()")
        var db = getDatabase();
        db.transaction(function(tx) {  // 'tx' is the transaction object, not 'db'
            // Check if username exists
            var checkRs = tx.executeSql("SELECT * FROM users WHERE username = ?", [username]);

            var result = {success: false, message: ""};

            if (checkRs.rows.length > 0) {
                // Update password
                var updateRs = tx.executeSql("UPDATE users SET password = ? WHERE username = ?", [newPass, username]);

                if (updateRs.rowsAffected > 0) {
                    result.success = true;
                    result.message = "Password reset successfully!";
                } else {
                    result.message = "Failed to reset password. Please try again.";
                }
            } else {
                result.message = "Incorrect Username";
            }

            // Call the callback with the result
            if (callback) {
                callback(result);
            }
        });
    }

    function updateUser(old_userName, new_username, newDisplayname, newEmail, mobile_no, _rpcCompleted, callback) {
        console.log("MapGlobals.updateUser()")
        var db = getDatabase();
        db.transaction(function(tx) {
            // Print all data BEFORE update
            console.log("=== ALL USERS BEFORE UPDATE ===");
            var beforeUpdate = tx.executeSql("SELECT * FROM users");
            for (var i = 0; i < beforeUpdate.rows.length; i++) {
                var user = beforeUpdate.rows.item(i);
                console.log("User", i + 1, "- ID:", user.id,
                            "Username:", user.username,
                            "Name:", user.displayname,
                            "Email:", user.email,
                            "Mobile:", user.mobile_number || "NULL",
                            "RPC:", user.rpc_completed);
            }

            // Perform the update
            var rs = tx.executeSql(
                        "UPDATE users SET username = ?, displayname = ?, email = ?, mobile_number = ?, rpc_completed = ? WHERE username = ?",
                        [new_username, newDisplayname, newEmail, mobile_no, _rpcCompleted, old_userName]
                        );

            if (rs.rowsAffected > 0) {
                console.log("User updated successfully");
                console.log("Rows affected:", rs.rowsAffected);

                // Print all data AFTER update
                console.log("=== ALL USERS AFTER UPDATE ===");
                var afterUpdate = tx.executeSql("SELECT * FROM users");

                for (var j = 0; j < afterUpdate.rows.length; j++) {
                    var updatedUser = afterUpdate.rows.item(j);
                    console.log("User", j + 1, "- ID:", updatedUser.id,
                                "Username:", updatedUser.username,
                                "Name:", updatedUser.displayname,
                                "Email:", updatedUser.email,
                                "Mobile:", updatedUser.mobile_number || "NULL",
                                "RPC:", updatedUser.rpc_completed);
                }

                if (callback) {
                    callback(true);
                }

            } else {

                console.log("User not found or update failed");

                if (callback) {
                    callback(false);
                }
            }
        });
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
    //             rootWindow.newscreen();
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
        var db = getDatabase();
        var result = false;
        var isEmail = userInput.indexOf("@") !== -1;

        db.transaction(function(tx) {

            var rsUser;

            if (isEmail) {
                // Check email
                rsUser = tx.executeSql(
                            "SELECT * FROM users WHERE email = ?",
                            [userInput]
                            );

                if (rsUser.rows.length === 0) {
                    rootWindow.showToastMessage("Incorrect Email");
                    callback(false);
                    return;
                }

                // Email exists → check password
                rsUser = tx.executeSql(
                            "SELECT * FROM users WHERE email = ? AND password = ?",
                            [userInput, password]
                            );

            } else {
                // Check username
                rsUser = tx.executeSql(
                            "SELECT * FROM users WHERE username = ?",
                            [userInput]
                            );

                if (rsUser.rows.length === 0) {
                    rootWindow.showToastMessage("Incorrect Username");
                    callback(false);
                    return;
                }

                // Username exists → check password
                rsUser = tx.executeSql(
                            "SELECT * FROM users WHERE username = ? AND password = ?",
                            [userInput, password]
                            );
            }

            // Final password validation
            if (rsUser.rows.length > 0) {
                console.log("Login Success");
                result = true;
                //loginLoader.visible = false;
                rootWindow.newscreen();
                rootWindow.showToastMessage("Login Successfully");
                login="login"
                QGroundControl.saveBoolGlobalSetting("login", true)
            } else {
                rootWindow.showToastMessage("Incorrect password");
                result = false;
            }

            callback(result);
        });
    }





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
            rootWindow.newscreen();
            QGroundControl.saveBoolGlobalSetting("login", true)
            modeBtn1.visible = false

        } else {
            console.log("profile method MapGLobals inside the Else")
            //loginLoader.visible = true;
            //newscreen.visible = false
            rootWindow.openWelcomeScreen();

            console.log("Invalid Credentials");
            QGroundControl.saveBoolGlobalSetting("login", false)
            console.log("map globals login else")
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
