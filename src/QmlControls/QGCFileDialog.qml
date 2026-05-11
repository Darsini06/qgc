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

    signal acceptedForLoad(string file)
    signal acceptedForSave(string file)
    signal acceptedCloudPlan(var planData)
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

            property bool showAllFiles: true


            property var  fullFileList: []
            property var  displayList: []


            property var  cloudPlansList: []
            property bool loading: false

            function refreshFiles() {
                loading = true
                var localFiles = controller.getFiles(folder, _rgExtensions)
                var combinedList = []

                for (var j = 0; j < localFiles.length; j++) {
                    var lName = localFiles[j]
                    var bName = lName.split(".")[0]
                    combinedList.push({
                        displayName: lName,
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
                                var dName = cName
                                if (!dName.endsWith(".plan")) dName += ".plan"

                                var cBaseName = cName.replace(".plan", "")
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

                                    onClicked: {
                                        mobileFileOpenDialog.close()

                                        var strippedFileName = modelData.baseName
                                        _appSettings.username = strippedFileName

                                        if (modelData.isLocal) {
                                            _root.acceptedForLoad(controller.fullyQualifiedFilename(folder, modelData.displayName))
                                        } else if (modelData.isCloud) {
                                            var planData = null
                                            for (var i = 0; i < mobileFileOpenDialog.cloudPlansList.length; i++) {
                                                var cName = mobileFileOpenDialog.cloudPlansList[i].plan_name
                                                var cBaseName = cName.replace(".plan", "")
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
                                            hamburgerMenu.fileToDelete = controller.fullyQualifiedFilename(folder, modelData.displayName)
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

                        // See More Button
                        Rectangle {
                            width:  parent.width
                            height: 40
                            color:  "#f5f5f5"
                            visible: mobileFileOpenDialog.displayList.length > 4

                            QGCLabel {
                                anchors.centerIn: parent
                                text: qsTr("See More...")
                                color: "#4a2c6d"
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    mobileFileOpenDialog.close()
                                    MapGlobals.jumpToFileList = true
                                    mainWindow.logfiles()
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
                customdialogedit.createObject(mainWindow).open()
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
                            var strippedFileName1 = userName
                            if (strippedFileName1 != "") {
                                _root.acceptedForSave(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))
                                popup.visible = false
                            }
                        }
                    }
                }

                // Custom Cloud Save Button
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.85
                    height: 95
                    radius: 10
                    color: "transparent"
                    border.color: "black"
                    border.width: 1.5

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 30
                        spacing: 6
                        QGCLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("Cloud Save + Local Save")
                            color: "black"
                            font.bold: true
                            font.pointSize: 13
                        }
                        QGCLabel {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("(save in cloud only in another phone you can see your plans)")
                            color: "#444"
                            font.pointSize: 10
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var strippedFileName1 = userName
                            if (strippedFileName1 != "") {
                                _root.acceptedForSave(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))
                                MapGlobals.requestCloudSync()
                                popup.visible = false
                            }
                        }
                    }
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
            id:             customDialog
            modal:          true
            dim:            true
            closePolicy:    Popup.NoAutoClose
            anchors.centerIn: parent
            width:          ScreenTools.defaultFontPixelWidth * 38
            height:         ScreenTools.defaultFontPixelHeight * 11
            padding:        0

            background: Rectangle {
                radius: 20
                color: "white"
                border.width: 0
                clip: true
            }

            contentItem: ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.28
                    color: "#262626"
                    radius: 20
                    // Top rounded corners only
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.radius
                        color: parent.color
                        visible: parent.radius > 0
                    }

                    Text {
                        text:               qsTr("Set Ground Name")
                        font.bold:          true
                        color:              "white"
                        font.pointSize:     14
                        anchors.centerIn:    parent
                        font.family:        "Outfit"
                    }
                }

                // Separator 1
                Rectangle {
                    Layout.fillWidth: true
                    height:             1
                    color:              "black"
                    opacity:            0.15
                }

                // Content Area
                Item {
                    Layout.fillWidth:   true
                    Layout.fillHeight:  true

                    RowLayout {
                        anchors {
                            left:           parent.left
                            right:          parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin:     25
                            rightMargin:    25
                        }
                        spacing:          15

                        Text {
                            text:           qsTr("Project Name:")
                            color:          "black"
                            font.bold:      true
                            font.pointSize: 11
                            font.family:    "Outfit"
                        }

                        TextField {
                            id:             nameField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            placeholderText: qsTr("Enter your project name")
                            placeholderTextColor: "#888888"
                            font.pointSize: 11
                            color:          "black"
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding:    15
                            background: Rectangle {
                                radius:         10
                                color:          "#FFFFFF"
                                border.color:   nameField.activeFocus ? "#262626" : "#DDE1EA"
                                border.width:   nameField.activeFocus ? 2 : 1
                            }
                        }
                    }
                }

                // Separator 2
                Rectangle {
                    Layout.fillWidth: true
                    height:             1
                    color:              "black"
                    opacity:            0.15
                }

                // Buttons Area
                Item {
                    Layout.fillWidth:   true
                    Layout.preferredHeight: parent.height * 0.32
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Cancel Column
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Button {
                                id:             cancelBtn
                                anchors.centerIn: parent
                                width: 125
                                height: 36
                                onClicked: {
                                    customDialog.visible = false
                                }

                                background: Rectangle {
                                    radius:     12
                                    color:      cancelBtn.pressed ? "#C0392B" : (cancelBtn.hovered ? "#E74C3C" : "#E74C3C")
                                    border.width: 0
                                }

                                contentItem: Text {
                                    text:               qsTr("Cancel")
                                    color:              "white"
                                    font.bold:          true
                                    font.pointSize:     12
                                    font.family:        "Outfit"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment:   Text.AlignVCenter
                                }
                            }
                        }

                        // Vertical Separator
                        Rectangle {
                            Layout.fillHeight: true
                            width: 1
                            color: "black"
                            opacity: 0.15
                            Layout.topMargin: 10
                            Layout.bottomMargin: 10
                        }

                        // Confirm Column
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Button {
                                id:             confirmBtn
                                anchors.centerIn: parent
                                width: 125
                                height: 36
                                onClicked: {

                                    MapGlobals.setGridLines(false)

                                    if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                                        if (nameField.text.length < 3 ) {
                                            mobileFileSaveDialog.preventClose = true
                                            return
                                        }
                                        let concatenatedText = nameField.text.substring(0, 10);
                                        _appSettings.username = concatenatedText;
                                        _root.acceptedForSave(controller.fullyQualifiedFilename(folder, concatenatedText, _rgExtensions))
                                    } else if ((QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping" || QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Military")){
                                        if (nameField.text.length < 3 ) {
                                            mobileFileSaveDialog.preventClose = true
                                            return
                                        }
                                        let concatenatedText = nameField.text.substring(0, 10);
                                        _appSettings.username = concatenatedText;
                                        _root.acceptedForSave(controller.fullyQualifiedFilename(folder, concatenatedText, _rgExtensions))
                                    }
                                    customDialog.visible = false
                                }
                                background: Rectangle {
                                    radius:     12
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#262626" }
                                        GradientStop { position: 1.0; color: "#262626" }
                                    }
                                    border.width: 0
                                    opacity: confirmBtn.pressed ? 0.8 : 1.0
                                }
                                contentItem: Text {
                                    text:               qsTr("Confirm")
                                    color:              "white"
                                    font.bold:          true
                                    font.pointSize:     12
                                    font.family:        "Outfit"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment:   Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

