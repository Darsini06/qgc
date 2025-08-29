// KmlLoader.qml
import QtQuick 2.15
import QtQuick.Dialogs 1.3
import QGroundControl 1.0
import QGroundControl.Controls 1.0

Item {
    id: kmlLoader

    property alias title: fileDialog.title
    property alias nameFilters: fileDialog.nameFilters

    signal fileLoaded(string filePath)
    signal loadCancelled()

    function open() {
        fileDialog.open()
    }

    FileDialog {
        id: fileDialog
        title: "Select KML File"
        nameFilters: [ "KML files (*.kml)" ]

        onAccepted: {
            var filePath = fileDialog.file.toString()
            // Handle Android content URI
            if (filePath.startsWith("content://")) {
                // Use QGroundControl's file handling utilities
                var localPath = QGroundControl.fileManager.getLocalFilePath(filePath)
                if (localPath !== "") {
                    kmlLoader.fileLoaded(localPath)
                } else {
                    console.log("Failed to resolve content URI:", filePath)
                    kmlLoader.loadCancelled()
                }
            } else {
                // Remove "file://" prefix if present
                if (filePath.startsWith("file://")) {
                    filePath = filePath.substring(7)
                }
                kmlLoader.fileLoaded(filePath)
            }
        }

        onRejected: {
            kmlLoader.loadCancelled()
        }
    }

}
