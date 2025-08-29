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
                customdialog.createObject(mainWindow).open()
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
                width:      40 * ScreenTools.defaultFontPixelWidth
                spacing:    ScreenTools.defaultFontPixelHeight / 2

                QGCLabel { text: qsTr("Path: %1").arg(_mobileShortPath) }

                Repeater {
                    id:     fileRepeater
                    model:  controller.getFiles(folder, _rgExtensions)

                    FileButton {
                        id:             fileButton
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           modelData

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
                }

                QGCLabel {
                    text:       qsTr("No files")
                    visible:    fileRepeater.model.length === 0
                }
            }
        }
    }

    Component{
        id: customdialog



    Item {
        id: saveOptionsDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 600
        height: 200

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#80ffffff"
            border.color: "#ccccff"
            border.width: 2

            Column {
                anchors.centerIn: parent
                spacing: 20
                anchors.margins: 20

                // Centered Title
                Label {
                    text: qsTr("Save Options")
                    font.bold: true
                    font.pointSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                // Buttons Row
                Row {
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Button {
                        text: qsTr("Save with existing name")
                        height: 34
                        font.bold: true
                        background: Rectangle {
                            radius: 20
                            color: "#ccccff"
                        }
                        onClicked: {
                            //saveOptionsDialog.close()
                            saveOptionsDialog.visible=false;
                            var strippedFileName1 = _appSettings.username
                            if (strippedFileName1 == "") {
                                mobileFileSaveDialog.preventClose = true
                                return
                            }
                            _root.acceptedForSave(controller.fullyQualifiedFilename(folder, strippedFileName1, _rgExtensions))
                        }
                    }

                    Button {
                        text: qsTr("Save as new file")
                        height: 34
                        font.bold: true
                        background: Rectangle {
                            radius: 20
                            color: "#ccccff"
                        }
                        onClicked: {
                            //saveOptionsDialog.close()
                            saveOptionsDialog.visible=false;
                            customdialog1.createObject(mainWindow).open()
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
                width:      40 * ScreenTools.defaultFontPixelWidth
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

                Repeater {
                    id:     fileRepeater
                    model:  controller.getFiles(folder, [ _rgExtensions ])

                    FileButton {
                        id:             fileButton
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        text:           modelData

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
                        width:      40 * ScreenTools.defaultFontPixelWidth
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

    Component{
        id: customdialog1


        Item {
               id: customDialogItem
               anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 400
                        height: 300
                radius: 10
                color: "#80ffffff"
                border.color: "#ccccff"
                border.width: 2

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // Title
                    Label {
                        text: qsTr("Set Ground Name1")
                        font.bold: true
                        font.pointSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        width: parent.width
                    }

                    // Name Field
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label { text: qsTr("Name :"); Layout.preferredWidth: 80;font.bold: true
                        font.pointSize: 14}
                        TextField {
                            id: filenameTextField
                            Layout.fillWidth: true
                        }
                    }

                    // Phone Number Field
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label { text: qsTr("Ph No:"); Layout.preferredWidth: 80;font.bold: true
                        font.pointSize: 14}
                        TextField {
                            id: filenameTextField1
                            Layout.fillWidth: true
                            validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,10}$/ }
                            inputMethodHints: Qt.ImhDigitsOnly
                        }
                    }

                    // Ground Name Field
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Label { text: qsTr("Ground Name:"); Layout.preferredWidth: 80;font.bold: true
                        font.pointSize: 14}
                        TextField {
                            id: filenameTextField2
                            Layout.fillWidth: true
                        }
                    }

                    // Buttons
                    Row {
                        spacing: 30
                        anchors.horizontalCenter: parent.horizontalCenter

                        Button {
                            text: "Cancel"
                            width: 100
                            height: 34
                            font.bold: true
                            background: Rectangle {
                                radius: 20
                                color: "#ccccff"
                            }
                            onClicked: {
                                //customdialog.visible = false;
                                customDialogItem.visible=false;
                            }

                        }

                        Button {
                            text: "Confirm"
                            width: 100
                            height: 34
                            font.bold: true
                            background: Rectangle {
                                radius: 20
                                color: "#ccccff"
                            }
                            onClicked: {
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
                        }
                    }


                }
            }
        }
}
    }

}
