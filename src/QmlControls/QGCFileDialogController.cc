/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#include "QGCFileDialogController.h"
#include "QGCLoggingCategory.h"
#include "QGCApplication.h"
#include "SettingsManager.h"
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtGui/QDesktopServices>
#include <QtCore/QUrl>
#ifdef Q_OS_ANDROID
#include <QtCore/QJniObject>
#endif

QGC_LOGGING_CATEGORY(QGCFileDialogControllerLog, "QGCFileDialogControllerLog")

QStringList QGCFileDialogController::getFiles(const QString& path,
                                              const QStringList& nameFilters)
{
    QDir dir(path);
    dir.setNameFilters(nameFilters);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    QFileInfoList fileInfoList = dir.entryInfoList(
        QDir::Files,
        QDir::Time   // 🔥 Sort by last modified time (Newest first)
        );

    QStringList fileList;

    for (const QFileInfo& fileInfo : fileInfoList) {
        fileList << fileInfo.fileName();
    }

    return fileList;   // LIFO (Latest first)
}

bool QGCFileDialogController::fileExists(const QString& filename)
{
    return QFile(filename).exists();
}

QString QGCFileDialogController::fullyQualifiedFilename(const QString& directoryPath, const QString& filename, const QStringList& nameFilters)
{
    QString firstFileExtention;

    // Check that the filename has one of the specified file extensions

    bool extensionFound = true;
    if (nameFilters.count()) {
        extensionFound = false;
        for (const QString& nameFilter: nameFilters) {
            if (nameFilter.startsWith("*.")) {
                QString fileExtension = nameFilter.right(nameFilter.length() - 2);
                if (fileExtension != "*") {
                    if (firstFileExtention.isEmpty()) {
                        firstFileExtention = fileExtension;
                    }
                    if (filename.endsWith(fileExtension)) {
                        extensionFound = true;
                        break;
                    }
                }
            } else if (nameFilter != "*") {
                qCWarning(QGCFileDialogControllerLog) << "unsupported name filter format" << nameFilter;
            }
        }
    }

    // Add the extension if it is missing
    QString filenameWithExtension = filename;
    if (!extensionFound) {
        filenameWithExtension = QStringLiteral("%1.%2").arg(filename).arg(firstFileExtention);
    }

    return directoryPath + QStringLiteral("/") + filenameWithExtension;
}

void QGCFileDialogController::deleteFile(const QString& filename)
{
    QFile::remove(filename);
}

void QGCFileDialogController::saveFile(const QString& filename, const QString& content)
{
    QFile file(filename);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << content;
        file.close();
    } else {
        qCWarning(QGCFileDialogControllerLog) << "Failed to open file for writing:" << filename;
    }
}

QString QGCFileDialogController::saveToDownloads(const QString& filename, const QString& content)
{
    QString saveFolder;

#ifdef Q_OS_ANDROID
    // App has requestLegacyExternalStorage=true and WRITE_EXTERNAL_STORAGE permission
    // Use the standard public Downloads folder directly
    saveFolder = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    // GenericDataLocation on Android gives /storage/emulated/0/Android/data/... or /storage/emulated/0
    // Append "Download" to reach the public Downloads folder
    if (!saveFolder.isEmpty()) {
        int idx = saveFolder.indexOf("/Android/data/");
        if (idx != -1) {
            saveFolder = saveFolder.left(idx) + "/Download";
        } else {
            saveFolder = saveFolder + "/Download";
        }
    } else {
        saveFolder = "/storage/emulated/0/Download";
    }
#else
    saveFolder = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (saveFolder.isEmpty()) {
        saveFolder = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    }
#endif

    QDir dir(saveFolder);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    QString savePath = dir.absoluteFilePath(filename);

    QFile file(savePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << content;
        file.close();
        qCDebug(QGCFileDialogControllerLog) << "Saved file to:" << savePath;

#ifdef Q_OS_ANDROID
        // Notify Android media scanner so the file appears in Downloads/Files apps immediately
        QJniObject jPath = QJniObject::fromString(savePath);
        QJniObject::callStaticMethod<void>(
            "org/mavlink/DCGCS/QGCActivity",
            "mediaScanFile",
            "(Ljava/lang/String;)V",
            jPath.object<jstring>()
        );
#endif

        return savePath;
    } else {
        qCWarning(QGCFileDialogControllerLog) << "Failed to save:" << savePath;
        return QString();
    }
}

QString QGCFileDialogController::fullFolderPathToShortMobilePath(const QString& fullFolderPath)
{
#ifdef __mobile__
    QString defaultSavePath = qgcApp()->toolbox()->settingsManager()->appSettings()->savePath()->rawValueString();
    if (fullFolderPath.startsWith(defaultSavePath)) {
        int lastDirSepIndex = fullFolderPath.lastIndexOf(QStringLiteral("/"));
        return QCoreApplication::applicationName() + QStringLiteral("/") + fullFolderPath.right(fullFolderPath.length() - lastDirSepIndex);
    } else {
        return fullFolderPath;
    }
#else
    qWarning() << "QGCFileDialogController::fullFolderPathToShortMobilePath should only be used in mobile builds";
    return fullFolderPath;
#endif
}

QString QGCFileDialogController::urlToLocalFile(QUrl url)
{
    // For some strange reason on Qt6 running on Linux files returned by FileDialog are not returned as local file urls.
    // Seems to be new behavior with Qt6.
    if (url.isLocalFile()) {
        return url.toLocalFile();
    } else {
        return url.toString();
    }
}
