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
import MapGlobals 1.0
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
                savefiledialog.createObject(mainWindow).open()
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

            Column {
                id:         fileOpenColumn
                width:      parent.width
                spacing:    20

                QGCLabel { 
                    text:   qsTr("Path: %1").arg(_mobileShortPath) 
                    color:  "white"
                    font.pointSize: ScreenTools.smallFontPointSize
                    font.bold: true
                }

                Rectangle {
                    width:          parent.width
                    height:         Math.max(50, fileListColumn.height)
                    color:          "transparent"
                    border.color:   Qt.rgba(255, 255, 255, 0.15)
                    border.width:   1
                    radius:         8
                    clip:           true
                    
                    Column {
                        id:             fileListColumn
                        width:          parent.width
                        spacing:        0

                        Repeater {
                            id:     fileRepeater
                            model:  controller.getFiles(folder, _rgExtensions)

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
                                        var strippedFileName = modelData.split(".")[0]
                                        _appSettings.username=strippedFileName;
                                        console.log("strippedFileName",strippedFileName)

                                        mobileFileOpenDialog.close()
                                        _root.acceptedForLoad(controller.fullyQualifiedFilename(folder, modelData))
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
                                                fileRepeater.model = controller.getFiles(folder, _rgExtensions)
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

                    Text {
                        anchors.centerIn: parent
                        text:       qsTr("No files")
                        color:      "white"
                        font.pixelSize: 14
                        font.bold: true
                        visible:    fileRepeater.model.length === 0
                    }
                }
            }
        }
    }

    Component {
        id: savefiledialog

        QGCPopupDialog {
            id: popup
            title: qsTr("Save Options")
            closeOnClickOutside: true


            buttons: Dialog.NoToAll | Dialog.Save

            onAccepted: {
                var strippedFileName1 = _appSettings.username
                if (strippedFileName1 == "") {
                    mobileFileSaveDialog.preventClose = true
                    return
                }
                _root.acceptedForSave(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))
                popup.visible = false
            }

            // onSaveAsNewAccepted: {
            //     customdialogedit.createObject(mainWindow).open()
            //     popup.visible = false
            //     }

            onRejected: {
                customdialogedit.createObject(mainWindow).open()
                popup.visible = false
            }

            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelWidth
                QGCLabel {
                    text:               qsTr("Click “Save As” to save the file with a new name. Click “Save” to save the file with the existing name.")
                    Layout.fillWidth:   true
                    color:              "white"
                    font.family:        "Outfit"
                    font.pointSize:     ScreenTools.defaultFontPointSize
                    horizontalAlignment: Text.AlignHCenter
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


                            // if (filenameTextField.text == "") {
                            //     mobileFileSaveDialog.preventClose = true
                            //     return
                            // }
                            // if (!replaceMessage.visible) {
                            //     if (controller.fileExists(controller.fullyQualifiedFilename(folder, filenameTextField.text, _rgExtensions))) {
                            //         replaceMessage.visible = true
                            //         mobileFileSaveDialog.preventClose = true
                            //         return
                            //     }
                            // }
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
                radius: 12
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#5a3c7d" }
                    GradientStop { position: 1.0; color: "#2d1c42" }
                }
                border.color: "#4a2c6d"
                border.width: 1
                clip: true
            }

            contentItem: ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height * 0.28
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
                    color:              "white"
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
                            color:          "white"
                            font.bold:      true
                            font.pointSize: 11
                            font.family:    "Outfit"
                        }

                        TextField {
                            id:             nameField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            placeholderText: qsTr("Enter your project name")
                            placeholderTextColor: "#999999"
                            font.pointSize: 10
                            color:          "black"
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding:    10
                            background: Rectangle {
                                radius:         2
                                color:          "white"
                            }
                        }
                    }
                }

                // Separator 2
                Rectangle {
                    Layout.fillWidth: true
                    height:             1
                    color:              "white"
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
                                    radius:     height / 2
                                    color:      "#3a1f57"
                                    border.color: "#4a2c6d"
                                    border.width: 1
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
                            color: "white"
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
                                    if(QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Agri"){
                                        if (nameField.text.length < 3 ) {
                                                mobileFileSaveDialog.preventClose = true
                                                return
                                            }
                                        let concatenatedText = nameField.text.substring(0, 10);
                                        _appSettings.username = concatenatedText;
                                        _root.acceptedForSave(controller.fullyQualifiedFilename(folder, concatenatedText, _rgExtensions))
                                    } else if (QGroundControl.loadGlobalSetting("loadpage","loadpage")==="Mapping"){
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
                                    radius:     height / 2
                                    color:      "#4a2c6d"
                                    border.color: "#5a3c7d"
                                    border.width: 1
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
