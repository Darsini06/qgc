/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "KMLHelper.h"

#include <QtCore/QFile>

#ifdef Q_OS_ANDROID
#include <QtCore/QJniEnvironment>
#include <QtCore/QJniObject>
#endif

QDomDocument KMLHelper::_loadFile(const QString& kmlFile, QString& errorString)
{
    QFile file(kmlFile);

    errorString.clear();

    QByteArray fileData;
    bool usingJni = false;

#ifdef Q_OS_ANDROID
    if (kmlFile.startsWith("content://")) {
        usingJni = true;
        QJniEnvironment env;
        // Use the Activity context which is more likely to hold the URI permission
        QJniObject activity = QJniObject::callStaticObjectMethod("org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");
        if (activity.isValid()) {
            QJniObject contentResolver = activity.callObjectMethod("getContentResolver", "()Landroid/content/ContentResolver;");
            if (contentResolver.isValid()) {
                QJniObject uriString = QJniObject::fromString(kmlFile);
                QJniObject uri = QJniObject::callStaticObjectMethod("android/net/Uri", "parse", "(Ljava/lang/String;)Landroid/net/Uri;", uriString.object<jstring>());
                if (uri.isValid()) {
                    // Try openInputStream first
                    QJniObject inputStream = contentResolver.callObjectMethod("openInputStream", "(Landroid/net/Uri;)Ljava/io/InputStream;", uri.object());
                    
                    if (!inputStream.isValid()) {
                        // Fallback to openFileDescriptor if openInputStream fails
                        QJniObject pfd = contentResolver.callObjectMethod("openFileDescriptor", "(Landroid/net/Uri;Ljava/lang/String;)Landroid/os/ParcelFileDescriptor;", uri.object(), QJniObject::fromString("r").object<jstring>());
                        if (pfd.isValid()) {
                            inputStream = QJniObject("android/os/ParcelFileDescriptor$AutoCloseInputStream", "(Landroid/os/ParcelFileDescriptor;)V", pfd.object());
                        }
                    }

                    if (inputStream.isValid()) {
                        // Read in chunks to be safe with large files
                        jbyteArray javaArray = env->NewByteArray(8192);
                        int bytesRead = 0;
                        while ((bytesRead = inputStream.callMethod<jint>("read", "([B)I", javaArray)) > 0) {
                            jbyte* bytes = env->GetByteArrayElements(javaArray, nullptr);
                            fileData.append(reinterpret_cast<char*>(bytes), bytesRead);
                            env->ReleaseByteArrayElements(javaArray, bytes, JNI_ABORT);
                        }
                        env->DeleteLocalRef(javaArray);
                        inputStream.callMethod<void>("close");
                    }
                }
            }
        }
        
        if (fileData.isEmpty()) {
            errorString = QString(_errorPrefix).arg(tr("Android Permission Denied or File Empty: %1. Please try moving the file to the QGroundControl/Missions folder if this persists.").arg(kmlFile));
            return QDomDocument();
        }
    }
#endif

    if (!usingJni) {
        QFile file(kmlFile);
        if (!file.open(QIODevice::ReadOnly)) {
            errorString = QString(_errorPrefix).arg(tr("Unable to open file: %1 error: $%2").arg(kmlFile).arg(file.errorString()));
            return QDomDocument();
        }
        fileData = file.readAll();
    }

    QDomDocument doc;
    QString errorMessage;
    int errorLine;
    if (!doc.setContent(fileData, &errorMessage, &errorLine)) {
        errorString = QString(_errorPrefix).arg(tr("Unable to parse KML file: %1 error: %2 line: %3").arg(kmlFile).arg(errorMessage).arg(errorLine));
        return QDomDocument();
    }

    return doc;
}

ShapeFileHelper::ShapeType KMLHelper::determineShapeType(const QString& kmlFile, QString& errorString)
{
    QDomDocument domDocument = KMLHelper::_loadFile(kmlFile, errorString);
    if (!errorString.isEmpty()) {
        return ShapeFileHelper::Error;
    }

    QDomNodeList rgNodes = domDocument.elementsByTagName("Polygon");
    if (rgNodes.count()) {
        return ShapeFileHelper::Polygon;
    }

    rgNodes = domDocument.elementsByTagName("LineString");
    if (rgNodes.count()) {
        return ShapeFileHelper::Polyline;
    }

    rgNodes = domDocument.elementsByTagName("Point");
    if (rgNodes.count()) {
        return ShapeFileHelper::Polygon;
    }

    errorString = QString(_errorPrefix).arg(tr("No supported type found in KML file."));
    return ShapeFileHelper::Error;
}

bool KMLHelper::loadPolygonFromFile(const QString& kmlFile, QList<QGeoCoordinate>& vertices, QString& errorString)
{
    errorString.clear();
    vertices.clear();

    QDomDocument domDocument = KMLHelper::_loadFile(kmlFile, errorString);
    if (!errorString.isEmpty()) {
        return false;
    }

    QDomNodeList rgNodes = domDocument.elementsByTagName("Polygon");
    QList<QGeoCoordinate> rgCoords;

    if (rgNodes.count() == 0) {
        QDomNodeList pointNodes = domDocument.elementsByTagName("Point");
        if (pointNodes.count() == 0) {
            errorString = QString(_errorPrefix).arg(tr("Unable to find Polygon or Point node in KML"));
            return false;
        }

        for (int i = 0; i < pointNodes.count(); i++) {
            QDomNode coordinatesNode = pointNodes.item(i).namedItem("coordinates");
            if (coordinatesNode.isNull()) continue;

            QString coordinateString = coordinatesNode.toElement().text().simplified();
            QStringList rgValueStrings = coordinateString.split(",");
            if (rgValueStrings.count() >= 2) {
                QGeoCoordinate coord;
                coord.setLongitude(rgValueStrings[0].toDouble());
                coord.setLatitude(rgValueStrings[1].toDouble());
                rgCoords.append(coord);
            }
        }

        if (rgCoords.isEmpty()) {
            errorString = QString(_errorPrefix).arg(tr("Internal error: Unable to find valid coordinates in Point nodes"));
            return false;
        }
    } else {
        QDomNode coordinatesNode = rgNodes.item(0).namedItem("outerBoundaryIs").namedItem("LinearRing").namedItem("coordinates");
        if (coordinatesNode.isNull()) {
            errorString = QString(_errorPrefix).arg(tr("Internal error: Unable to find coordinates node in KML"));
            return false;
        }

        QString coordinatesString = coordinatesNode.toElement().text().simplified();
        QStringList rgCoordinateStrings = coordinatesString.split(" ");

        for (int i=0; i<rgCoordinateStrings.count()-1; i++) {
            QString coordinateString = rgCoordinateStrings[i];

            QStringList rgValueStrings = coordinateString.split(",");

            QGeoCoordinate coord;
            coord.setLongitude(rgValueStrings[0].toDouble());
            coord.setLatitude(rgValueStrings[1].toDouble());

            rgCoords.append(coord);
        }
    }

    // Determine winding, reverse if needed. QGC wants clockwise winding
    double sum = 0;
    for (int i=0; i<rgCoords.count(); i++) {
        QGeoCoordinate coord1 = rgCoords[i];
        QGeoCoordinate coord2 = (i == rgCoords.count() - 1) ? rgCoords[0] : rgCoords[i+1];

        sum += (coord2.longitude() - coord1.longitude()) * (coord2.latitude() + coord1.latitude());
    }
    bool reverse = sum < 0.0;
    if (reverse) {
        QList<QGeoCoordinate> rgReversed;

        for (int i=0; i<rgCoords.count(); i++) {
            rgReversed.prepend(rgCoords[i]);
        }
        rgCoords = rgReversed;
    }

    vertices = rgCoords;

    return true;
}

bool KMLHelper::loadPolylineFromFile(const QString& kmlFile, QList<QGeoCoordinate>& coords, QString& errorString)
{
    errorString.clear();
    coords.clear();

    QDomDocument domDocument = KMLHelper::_loadFile(kmlFile, errorString);
    if (!errorString.isEmpty()) {
        return false;
    }

    QDomNodeList rgNodes = domDocument.elementsByTagName("LineString");
    if (rgNodes.count() == 0) {
        errorString = QString(_errorPrefix).arg(tr("Unable to find LineString node in KML"));
        return false;
    }

    QDomNode coordinatesNode = rgNodes.item(0).namedItem("coordinates");
    if (coordinatesNode.isNull()) {
        errorString = QString(_errorPrefix).arg(tr("Internal error: Unable to find coordinates node in KML"));
        return false;
    }

    QString coordinatesString = coordinatesNode.toElement().text().simplified();
    QStringList rgCoordinateStrings = coordinatesString.split(" ");

    QList<QGeoCoordinate> rgCoords;
    for (int i=0; i<rgCoordinateStrings.count()-1; i++) {
        QString coordinateString = rgCoordinateStrings[i];

        QStringList rgValueStrings = coordinateString.split(",");

        QGeoCoordinate coord;
        coord.setLongitude(rgValueStrings[0].toDouble());
        coord.setLatitude(rgValueStrings[1].toDouble());

        rgCoords.append(coord);
    }

    coords = rgCoords;

    return true;
}
