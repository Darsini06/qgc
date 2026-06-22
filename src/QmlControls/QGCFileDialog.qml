import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.platform as Labs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controllers
import Qt.labs.settings 1.0
import MapGlobals
/// This control is meant to be a direct replacement for the standard Qml FileDialog control.
/// It differs for mobile builds which uses a completely custom file picker.
Item {
    id:         _root
    visible:    false

    property string folder              // Due to Qt bug with file url parsing this must be an absolute path
    property var    nameFilters:    []  // Important: Only name filters with simple wildcarding like *.foo are supported.
    property string title
    property bool   selectFolder:   false
    property string defaultSuffix:  ""
    property var planViewRef: null   // Reference back to PlanView

    signal acceptedForLoad(string file)
    signal acceptedForSave(string file)
    signal acceptedCloudPlan(var planData)
    signal acceptedForOverwrite(string fallbackFile)
    signal rejected
    property var    _appSettings:                       QGroundControl.settingsManager.appSettings

    function openForLoad() {
        _openForLoad = true
        if (_mobileDlg && folder.length !== 0) {
            mobileFileOpenDialogComponent.createObject(mainWindow).open()
        } else if (selectFolder) {
            fullFolderDialog.open()
        } else {
            fullFileDialog.fileMode = FileDialog.OpenFile
            fullFileDialog.open()
        }
    }

    function openForSave() {
        _openForLoad = false
        if (_mobileDlg && folder.length !== 0) {


            if(MapGlobals.save==="save1"){
                //savefiledialog.createObject(mainWindow).open()
                savefiledialog.createObject(mainWindow, {
                                                userName: _appSettings.username
                                            }).open()

            }else{
                //mobileFileSaveDialogComponent.createObject(mainWindow).open()
                var strippedFileName1=_appSettings.username
                if (strippedFileName1 == "") {
                    mobileFileSaveDialog.preventClose = true
                    return
                }
                // if (!replaceMessage.visible) {
                //     if (controller.fileExists(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))) {
                //         replaceMessage.visible = true
                //         mobileFileSaveDialog.preventClose = true
                //         return
                //     }
                // }
                _root.acceptedForSave(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))
            }



        } else {
            fullFileDialog.fileMode = FileDialog.SaveFile
            fullFileDialog.open()
        }
    }

    function close() {
        fullFileDialog.close()
    }

    property bool   _openForLoad:   true
    property real   _margins:       ScreenTools.defaultFontPixelHeight / 2
    property bool   _mobileDlg:     QGroundControl.corePlugin.options.useMobileFileDialog
    property var    _rgExtensions
    property string _mobileShortPath

    Component.onCompleted: {
        _setupFileExtensions()
        _updateMobileShortPath()
        console.log('local data ',_appSettings.username)
    }

    onFolderChanged:        _updateMobileShortPath()
    onNameFiltersChanged:   _setupFileExtensions()

    function _updateMobileShortPath() {
        if (ScreenTools.isMobile) {
            _mobileShortPath = controller.fullFolderPathToShortMobilePath(folder);
        }
    }

    function _setupFileExtensions() {
        _rgExtensions = [ ]
        if (!_root.nameFilters || _root.nameFilters.length === 0) {
            return
        }
        for (var i=0; i<_root.nameFilters.length; i++) {
            var filter = _root.nameFilters[i]
            var regExp = /^.*\((.*)\)$/
            var result = regExp.exec(filter)
            if (result.length === 2) {
                filter = result[1]
            }
            var rgFilters = filter.split(" ")
            for (var j=0; j<rgFilters.length; j++) {
                if (!_mobileDlg || (rgFilters[j] !== "*" && rgFilters[j] !== "*.*")) {
                    _rgExtensions.push(rgFilters[j])
                }
            }
        }
    }

    QGCFileDialogController { id: controller }
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    FileDialog {
        id:             fullFileDialog
        currentFolder:  "file:///" + _root.folder
        nameFilters:    _root.nameFilters ? _root.nameFilters : []
        title:          _root.title
        defaultSuffix:  _root.defaultSuffix

        onAccepted: {
            var fullPath = controller.urlToLocalFile(selectedFile)
            if (fileMode == FileDialog.OpenFile) {
                _root.acceptedForLoad(fullPath)
            } else {
                _root.acceptedForSave(fullPath)
            }
        }
        onRejected: _root.rejected()
    }

    Labs.FolderDialog {
        id:             fullFolderDialog
        currentFolder:  "file:///" + _root.folder
        title:          _root.title

        onAccepted: _root.acceptedForLoad(controller.urlToLocalFile(folder))
        onRejected: _root.rejected()
    }
    Component {
        id: mobileFileOpenDialogComponent

        QGCPopupDialog {
            id:         mobileFileOpenDialog
            title:      _root.title
            buttons:    Dialog.Cancel
            maxPopupHeight: mainWindow.height * 0.65 // Shorter height to avoid touching the top navbar

            property bool showAllFiles: true


            property var  fullFileList: []
            property var  displayList: []


            property var  cloudPlansList: []
            property bool loading: false

            function refreshFiles() {
                loading = true
                var localFiles = controller.getFiles(folder, _rgExtensions)
                var userName = QGroundControl.loadGlobalSetting("username", "Guest")
                var combinedList = []

                for (var j = 0; j < localFiles.length; j++) {

                    var lName = localFiles[j]

                    if (!lName.startsWith(userName + "_"))
                        continue;
                    var bName = lName.split(".")[0]
                    combinedList.push({
                                          displayName: bName + ".plan",
                                          actualName: lName,
                                          baseName: bName,
                                          isLocal: true,
                                          isCloud: false
                                      })
                }

                if (_root.hasOwnProperty("planFiles") && _root.planFiles) {
                    var userName = QGroundControl.loadGlobalSetting("username", "Guest")
                    if (userName !== "Guest" && userName !== "") {
                        MapGlobals.fetchCloudPlans(userName, function(plans) {
                            cloudPlansList = plans || []
                            var deduplicatedList = []

                            // First, add all cloud plans
                            for (var i = 0; i < cloudPlansList.length; i++) {
                                var cName = cloudPlansList[i].plan_name
                                var cBaseName = cName.split(".")[0]
                                var dName = cBaseName + ".plan"

                                deduplicatedList.push({
                                                          displayName: dName,
                                                          actualName:  cName, // Store the original name for deletion/loading
                                                          baseName:    cBaseName,
                                                          isLocal:     false,
                                                          isCloud:     true
                                                      })
                            }

                            // Then, add local plans ONLY if they are not already in the cloud list
                            for (var j = 0; j < combinedList.length; j++) {
                                var localBase = combinedList[j].baseName.toLowerCase()
                                var found = false
                                for (var k = 0; k < deduplicatedList.length; k++) {
                                    if (deduplicatedList[k].baseName.toLowerCase() === localBase) {
                                        found = true
                                        break
                                    }
                                }
                                if (!found) {
                                    deduplicatedList.push(combinedList[j])
                                }
                            }

                            fullFileList = deduplicatedList
                            displayList = fullFileList
                            loading = false
                        })
                        return
                    }
                }

                fullFileList = combinedList
                displayList = fullFileList
                loading = false
            }

            Component.onCompleted: refreshFiles()

            Column {
                id:         fileOpenColumn
                width:      parent.width
                spacing:    15

                // Redundant 'Select Plan File' label removed as the popup already has a title.


                Rectangle {
                    width:          parent.width
                    height:         Math.max(120, fileListColumn.height)
                    color:          "transparent"
                    border.color:   Qt.rgba(0, 0, 0, 0.1)
                    border.width:   1
                    radius:         8
                    clip:           true

                    BusyIndicator {
                        anchors.centerIn: parent
                        visible:          mobileFileOpenDialog.loading
                    }

                    Column {
                        id:             fileListColumn
                        width:          parent.width
                        spacing:        0
                        visible:        !mobileFileOpenDialog.loading

                        Repeater {
                            id:     fileRepeater
                            // Show only first 4 files
                            model:  mobileFileOpenDialog.displayList.slice(0, 4)

                            Item {
                                width: parent.width
                                height: fileButton.height

                                FileButton {
                                    id:             fileButton
                                    anchors.fill:   parent
                                    text:           modelData.displayName
                                    border.width:   0
                                    radius:         0
                                    showDownloadButton: false

                                    onClicked: {
                                        mobileFileOpenDialog.close()

                                        var strippedFileName = modelData.baseName


                                        if (modelData.isLocal) {
                                            _root.acceptedForLoad(controller.fullyQualifiedFilename(folder, modelData.actualName))
                                        } else if (modelData.isCloud) {
                                            var planData = null
                                            for (var i = 0; i < mobileFileOpenDialog.cloudPlansList.length; i++) {
                                                var cName = mobileFileOpenDialog.cloudPlansList[i].plan_name
                                                var cBaseName = cName.split(".")[0]
                                                if (cBaseName === strippedFileName) {
                                                    planData = mobileFileOpenDialog.cloudPlansList[i].plan_data
                                                    break
                                                }
                                            }
                                            if (planData) {
                                                _root.acceptedCloudPlan(planData)
                                            }
                                        }
                                    }

                                    onHamburgerClicked: {
                                        if (modelData.isLocal) {
                                            highlight = true
                                            hamburgerMenu.fileToDelete = controller.fullyQualifiedFilename(folder, modelData.actualName)
                                            hamburgerMenu.popup()
                                        } else {
                                            // Cloud plan deletion
                                            mainWindow.showMessageDialog(qsTr("Delete Cloud Plan"),
                                                                         qsTr("Are you sure you want to permanently delete '%1' from the cloud? This cannot be undone.").arg(modelData.displayName),
                                                                         Dialog.Yes | Dialog.Cancel,
                                                                         function() {
                                                                             // Use modelData.actualName to ensure we match the backend's mission_name
                                                                             MapGlobals.deleteCloudPlan(modelData.actualName, function(success) {
                                                                                 if (success) {
                                                                                     mainWindow.showToastMessage(qsTr("Plan deleted successfully"))
                                                                                     mobileFileOpenDialog.refreshFiles() // Refresh the list
                                                                                 } else {
                                                                                     mainWindow.showToastMessage(qsTr("Failed to delete plan from cloud"))
                                                                                 }
                                                                             })
                                                                         }
                                                                         )
                                        }
                                    }

                                    QGCMenu {
                                        id: hamburgerMenu

                                        property string fileToDelete

                                        onAboutToHide: fileButton.highlight = false

                                        QGCMenuItem {
                                            text:           qsTr("Delete")
                                            onTriggered: {
                                                controller.deleteFile(hamburgerMenu.fileToDelete)
                                                mobileFileOpenDialog.refreshFiles()
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Qt.rgba(0, 0, 0, 0.05)
                                    anchors.bottom: parent.bottom
                                    visible: index < fileRepeater.count - 1
                                }
                            }
                        }
                        // See More link
                        Rectangle {
                            width:  parent.width
                            height: 40
                            color:  "transparent"
                            visible: mobileFileOpenDialog.displayList.length > 4

                            QGCLabel {
                                anchors.centerIn: parent
                                text: qsTr("See More")
                                color: "#007AFF" // Modern link color
                                font.bold: true
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    MapGlobals.jumpToFileList = true
                                    if (MapGlobals.rootWindow) {
                                        MapGlobals.rootWindow.logfiles_screen()
                                    }
                                    mobileFileOpenDialog.close()
                                }
                            }
                        }

                    }

                    Text {
                        anchors.centerIn: parent
                        text:       qsTr("No plans found")
                        color:      "black"
                        font.pixelSize: 14
                        font.bold: true
                        visible:    !mobileFileOpenDialog.loading && fileRepeater.model.length === 0
                    }
                }

                // Removed 'See More' and 'Show Less' UI as all files are now displayed by default.
            }

        }
    }

    Component {
        id: savefiledialog

        QGCPopupDialog {
            id: popup
            title: qsTr("Save Options")
            closeOnClickOutside: true
            property string userName: ""

            // Remove default buttons to use our custom ones
            buttons: Dialog.NoButton

            onAccepted: {
                var strippedFileName1 = userName
                if (strippedFileName1 != "") {
                    _root.acceptedForSave(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))
                    popup.visible = false
                }
            }

            onRejected: {
                popup.visible = false
            }

            Column {
                id: saveOptionsColumn
                spacing: 20
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                QGCLabel {
                    width: parent.width
                    text:               qsTr("Choose how you want to save:")
                    color:              "black"
                    font.family:        "Outfit"
                    font.pointSize:     14
                    font.bold:          true
                    horizontalAlignment: Text.AlignHCenter
                }

                // Custom Save As Button
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.85
                    height: 55
                    radius: 10
                    color: "transparent"
                    border.color: "black"
                    border.width: 1.5

                    QGCLabel {
                        anchors.centerIn: parent
                        text: qsTr("Save As (New File)")
                        color: "black"
                        font.bold: true
                        font.pointSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            customdialogedit.createObject(mainWindow).open()
                            popup.visible = false
                        }
                    }
                }

                // Custom Save Button
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.85
                    height: 55
                    radius: 10
                    color: "transparent"
                    border.color: "black"
                    border.width: 1.5

                    QGCLabel {
                        anchors.centerIn: parent
                        text: qsTr("Save (Overwrite)")
                        color: "black"
                        font.bold: true
                        font.pointSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {

                            // Update latest fence/circle values
                            //MapGlobals.setGridLines(false)

                            var fallback = controller.fullyQualifiedFilename(
                                        folder,
                                        userName !== "" ? userName : "Guest",
                                        _rgExtensions)

                            // ADD THIS - Save fence data before saving the file
                            if (planViewRef && planViewRef.saveFenceBeforeSave) {
                                planViewRef.saveFenceBeforeSave(fallback)
                            }

                            _root.acceptedForSave(fallback)
                            popup.visible = false
                        }
                    }
                }
                // ← Bottom spacer
                  Item {
                      width: parent.width
                      height: 20
                  }
            }
        }
    }

    Component {
        id: mobileFileSaveDialogComponent

        QGCPopupDialog {
            id:         mobileFileSaveDialog
            title:      _root.title
            buttons:    Dialog.Cancel | Dialog.Ok

            onAccepted: {
                if (filenameTextField.text == "") {
                    mobileFileSaveDialog.preventClose = true
                    return
                }
                if (!replaceMessage.visible) {
                    if (controller.fileExists(controller.fullyQualifiedFilename(folder, filenameTextField.text, _rgExtensions))) {
                        replaceMessage.visible = true
                        mobileFileSaveDialog.preventClose = true
                        return
                    }
                }
                _root.acceptedForSave(controller.fullyQualifiedFilename(folder, filenameTextField.text, _rgExtensions))
            }
            onRejected:{
                mainWindow.filename()
            }

            Column {
                id:         fileSaveColumn
                width:      parent.width
                spacing:    ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("New file name:") }

                    QGCTextField {
                        id:                 filenameTextField
                        Layout.fillWidth:   true
                        text:_appSettings.username
                    }
                }

                QGCLabel {
                    id:             replaceMessage
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    wrapMode:       Text.WordWrap
                    text:           qsTr("The file %1 exists. Click Save again to replace it.").arg(filenameTextField.text)
                    visible:        false
                    color:          qgcPal.warningText
                }

                SectionHeader {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    text:           qsTr("Save to existing file:")
                }

                Rectangle {
                    width:          parent.width
                    height:         Math.max(50, fileSaveList.height)
                    color:          "transparent"
                    border.color:   Qt.rgba(255, 255, 255, 0.15)
                    border.width:   1
                    radius:         8
                    clip:           true

                    Column {
                        id: fileSaveList
                        width: parent.width
                        spacing: 0

                        Repeater {
                            id:     fileRepeater
                            model:  controller.getFiles(folder, [ _rgExtensions ])

                            Item {
                                width: parent.width
                                height: fileButton.height

                                FileButton {
                                    id:             fileButton
                                    anchors.fill:   parent
                                    text:           modelData
                                    border.width:   0
                                    radius:         0

                                    onClicked: {
                                        mobileFileSaveDialog.close()
                                        _root.acceptedForSave(controller.fullyQualifiedFilename(folder, modelData))
                                    }

                                    onHamburgerClicked: {
                                        highlight = true
                                        hamburgerMenu.fileToDelete = controller.fullyQualifiedFilename(folder, modelData)
                                        hamburgerMenu.popup()
                                    }

                                    QGCMenu {
                                        id: hamburgerMenu

                                        property string fileToDelete

                                        onAboutToHide: fileButton.highlight = false

                                        QGCMenuItem {
                                            text:           qsTr("Delete")
                                            onTriggered: {
                                                controller.deleteFile(hamburgerMenu.fileToDelete)
                                                fileRepeater.model = controller.getFiles(folder, [ _rgExtensions ])
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Qt.rgba(255, 255, 255, 0.1)
                                    anchors.bottom: parent.bottom
                                    visible: index < fileRepeater.count - 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: filename

        QGCPopupDialog {
            id:         mobileFileSaveDialog
            title:      _root.title
            buttons:    Dialog.Cancel | Dialog.Ok

            onAccepted: {
                if (filenameTextField.text.length < 3 || filenameTextField1.text.length < 3 || filenameTextField2.text.length < 3) {
                    mobileFileSaveDialog.preventClose = true
                    return
                }

                let concatenatedText = filenameTextField.text.substring(0, 3) +
                    filenameTextField1.text.substring(0, 3) +
                    filenameTextField2.text.substring(0, 3);


                _appSettings.username = concatenatedText;
                console.log(concatenatedText);

                _root.acceptedForSave(controller.fullyQualifiedFilename(folder, concatenatedText, _rgExtensions))

            }

            onRejected:{
                mainWindow.filename()
            }

            Column {
                id:         fileSaveColumn
                width:      parent.width
                spacing:    ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("File name:") }

                    QGCTextField {
                        id:                 filenameTextField
                        Layout.fillWidth:   true
                        onTextChanged:      replaceMessage.visible = false
                    }
                }

                RowLayout {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("Mobile Number:") }

                    QGCTextField {
                        id:                 filenameTextField1
                        Layout.fillWidth:   true
                        validator:          RegularExpressionValidator { regularExpression: /^[0-9]{0,10}$/ }
                        inputMethodHints:   Qt.ImhDigitsOnly
                        onTextChanged:      replaceMessage.visible = false
                    }
                }

                RowLayout {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    spacing:        ScreenTools.defaultFontPixelWidth

                    QGCLabel { text: qsTr("Ground name:") }

                    QGCTextField {
                        id:                 filenameTextField2
                        Layout.fillWidth:   true
                        onTextChanged:      replaceMessage.visible = false
                    }
                }

            }
        }
    }



    Component {
        id: customdialogedit

        Dialog {
            id: customDialog

            modal: true
            dim: false
            closePolicy: Popup.NoAutoClose

            anchors.centerIn: parent

            width: ScreenTools.defaultFontPixelWidth * 38
            height: ScreenTools.defaultFontPixelHeight * 12

            padding: 0

            onOpened: {
                MapGlobals.editdialog = "editdialog"
            }

            onClosed: {
                MapGlobals.editdialog = "editdialog1"
            }
            // ================= BACKGROUND =================
            background: Rectangle {
                radius: 24
                // Slightly more transparent background for all set ground dialogs
                color: "#22000000"
                border.color: "#33FFFFFF"
                border.width: 1
                clip: true
            }
            // ================= MAIN CONTENT =================
            contentItem: ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ================= HEADER =================
                Item {
                    id: headerContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.30
                    clip: true

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height + radius

                        radius: 24
                        color: "#000000"
                    }

                    // ===== ICON =====
                    Image {
                        source: "qrc:/qmlimages/NewImages/ground_name.png"

                        width: 170
                        height: 170

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: -120

                        fillMode: Image.PreserveAspectFit
                    }

                    // ===== TITLE =====
                    Text {
                        text: qsTr("Set Ground Name")

                        color: "white"

                        font.bold: true
                        font.pointSize: 15
                        font.family: "Outfit"

                        anchors.centerIn: parent
                    }

                    // ===== CLOSE SYMBOL =====
                    Item {
                        width: 30; height: 30
                        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                        
                        Item {
                            anchors.centerIn: parent
                            width: 14; height: 14
                            Rectangle {
                                width: 18; height: 2
                                color: "white"
                                anchors.centerIn: parent
                                rotation: 45
                                antialiasing: true
                            }
                            Rectangle {
                                width: 18; height: 2
                                color: "white"
                                anchors.centerIn: parent
                                rotation: -45
                                antialiasing: true
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: customDialog.close()
                        }
                    }
                }

                // ================= CONTENT AREA =================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20

                        spacing: 15

                        // ===== LIMIT WARNING =====
                        Text {
                            id: limitText
                            visible: nameField.text.length >= 12
                            text: qsTr("Only 12 characters allowed")

                            anchors.horizontalCenter: parent.horizontalCenter

                            color: "#B71C1C"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "Outfit"

                            style: Text.Outline
                            styleColor: "white"
                        }

                        // ===== INPUT ROW =====
                        RowLayout {
                            width: parent.width

                            spacing: 15

                            Text {
                                text: qsTr("Project Name:")

                                color: "white"

                                font.bold: true
                                font.pointSize: 13
                                font.family: "Outfit"
                            }

                            // ===== TEXT FIELD =====
                            TextField {
                                id: nameField

                                Layout.fillWidth: true
                                Layout.preferredHeight: 44

                                maximumLength: 12

                                validator: RegularExpressionValidator {
                                    regularExpression: /^[A-Za-z0-9]*$/
                                }

                                placeholderText: qsTr("Enter your project name")
                                placeholderTextColor: "#666666"

                                color: "#111111"

                                font.pointSize: 13
                                font.family: "Outfit"

                                leftPadding: 15

                                verticalAlignment: TextInput.AlignVCenter

                                background: Rectangle {
                                    radius: 12

                                    color: "#EAEAEA"

                                    border.color: nameField.activeFocus
                                                  ? "#555555"
                                                  : "#BBBBBB"

                                    border.width: 1.3
                                }
                            }
                        }
                    }
                }

                // ================= BUTTON AREA =================
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.30

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 25
                        anchors.rightMargin: 25

                        spacing: 25

                        // ===== CANCEL BUTTON =====
                        Button {
                            id: cancelBtn

                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            onClicked: {
                                customDialog.close()
                            }

                            background: Rectangle {
                                radius: 14

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#E57373" }
                                    GradientStop { position: 1.0; color: "#D84343" }
                                }
                            }

                            contentItem: Text {
                                text: qsTr("Cancel")

                                color: "white"

                                font.bold: true
                                font.pointSize: 12
                                font.family: "Outfit"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // ===== CONFIRM BUTTON =====
                        Button {
                            id: confirmBtn

                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            onClicked: {

                                if (nameField.text.length < 3) {
                                    return
                                }

                                let concatenatedText = nameField.text

                                _appSettings.username = concatenatedText

                                _root.acceptedForSave(
                                    controller.fullyQualifiedFilename(
                                        folder,
                                        concatenatedText,
                                        _rgExtensions))

                                customDialog.close()
                            }

                            background: Rectangle {
                                radius: 14

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#66BB6A" }
                                    GradientStop { position: 1.0; color: "#43A047" }
                                }
                            }

                            contentItem: Text {
                                text: qsTr("Confirm")

                                color: "white"

                                font.bold: true
                                font.pointSize: 12
                                font.family: "Outfit"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }


}
