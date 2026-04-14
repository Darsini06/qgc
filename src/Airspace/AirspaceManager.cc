/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AirspaceManager.h"
#include "QGCToolbox.h"
#include "QGCApplication.h"
#include "SettingsManager.h"

#include <QNetworkRequest>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QtConcurrent>
#include <QFuture>

//-----------------------------------------------------------------------------
// AirspaceZone Implementation
//-----------------------------------------------------------------------------

AirspaceZone::AirspaceZone(QObject* parent)
    : QObject(parent)
    , _zoneType(AirspaceZoneType::GreenZone)
    , _fillOpacity(0.3)
    , _borderWidth(2)
    , _minAltitude(0.0)
    , _maxAltitude(10000.0)
    , _isActive(true)
{
    _updateStyling();
}

QString AirspaceZone::zoneTypeString() const
{
    switch (_zoneType) {
        case AirspaceZoneType::RedZone:        return "red";
        case AirspaceZoneType::YellowZone:     return "yellow";
        case AirspaceZoneType::InnerYellow:    return "inneryellow";
        case AirspaceZoneType::OuterYellow:    return "outeryellow";
        case AirspaceZoneType::GreenZone:      return "green";
        case AirspaceZoneType::MilitaryZone:   return "military";
        case AirspaceZoneType::Airport:        return "airport";
        case AirspaceZoneType::CTR:            return "ctr";
        case AirspaceZoneType::RunwayApproach: return "runway";
        case AirspaceZoneType::Temporary:      return "temporary";
        case AirspaceZoneType::Boundary:       return "boundary";
        case AirspaceZoneType::Others:         return "others";
        case AirspaceZoneType::StateBorder:    return "states";
        case AirspaceZoneType::Helipad:        return "helipad";
        default:                               return "unknown";
    }
}

void AirspaceZone::setZoneType(AirspaceZoneType type)
{
    _zoneType = type;
    _updateStyling();
}

void AirspaceZone::setCoordinates(const QVariantList& coords)
{
    _coordinates = coords;
    _polygon = QGeoPolygon();

    // Convert QVariantList to QGeoPolygon
    for (const QVariant& coordVar : coords) {
        QVariantList coordList = coordVar.toList();
        if (coordList.size() >= 2) {
            double lon = coordList[0].toDouble();
            double lat = coordList[1].toDouble();
            QGeoCoordinate coord(lat, lon);
            if (coord.isValid()) {
                _polygon.addCoordinate(coord);
            }
        }
    }

    _calculateIconPosition();
}

void AirspaceZone::setProperties(const QJsonObject& props)
{
    if (props.contains("name")) {
        _name = props["name"].toString();
    }
    if (props.contains("description")) {
        _description = props["description"].toString();
    }
    if (props.contains("minAltitude")) {
        _minAltitude = props["minAltitude"].toDouble();
    }
    if (props.contains("maxAltitude")) {
        _maxAltitude = props["maxAltitude"].toDouble();
    }
    if (props.contains("active")) {
        _isActive = props["active"].toBool();
    }

    // Parse zone type
    QString typeStr;
    if (props.contains("zoneType")) {
        typeStr = props["zoneType"].toString().toLower();
    } else if (props.contains("type")) {
        typeStr = props["type"].toString().toLower();
    }

    if (!typeStr.isEmpty()) {
        if (typeStr == "red" || typeStr == "prohibited" || typeStr == "abandoned" || typeStr == "permanent_red_zone") {
            setZoneType(AirspaceZoneType::RedZone);
        } else if (typeStr == "boundary") {
            setZoneType(AirspaceZoneType::Boundary);
        } else if (typeStr == "inneryellow" || typeStr == "inner-yellow" || typeStr == "inner_yellow") {
            setZoneType(AirspaceZoneType::InnerYellow);
        } else if (typeStr == "outeryellow" || typeStr == "outer-yellow" || typeStr == "outer_yellow") {
            setZoneType(AirspaceZoneType::OuterYellow);
        } else if (typeStr == "yellow" || typeStr == "restricted") {
            setZoneType(AirspaceZoneType::YellowZone);
        } else if (typeStr == "military" || typeStr == "naval") {
            setZoneType(AirspaceZoneType::MilitaryZone);
        } else if (typeStr == "airport" || typeStr == "domestic") {
            setZoneType(AirspaceZoneType::Airport);
        } else if (typeStr == "ctr") {
            setZoneType(AirspaceZoneType::CTR);
        } else if (typeStr == "runway" || typeStr == "approach" || typeStr == "runwayapproach") {
            setZoneType(AirspaceZoneType::RunwayApproach);
        } else if (typeStr == "temporary" || typeStr == "notam" || typeStr == "temporary_red_zone" || typeStr == "temp-red" || typeStr == "temp_red") {
            setZoneType(AirspaceZoneType::Temporary);
        } else if (typeStr == "others" || typeStr == "government" || typeStr == "option") {
            setZoneType(AirspaceZoneType::Others);
        } else if (typeStr == "states" || typeStr == "state_border" || typeStr == "stateborder") {
            setZoneType(AirspaceZoneType::StateBorder);
        } else if (typeStr == "helipad") {
            setZoneType(AirspaceZoneType::Helipad);
        } else {
            setZoneType(AirspaceZoneType::GreenZone);
        }
    } else {
        setZoneType(AirspaceZoneType::GreenZone);
    }
}

void AirspaceZone::_updateStyling()
{
    switch (_zoneType) {
        case AirspaceZoneType::RedZone:
            _fillColor = "#ff0505";
            _borderColor = "#ff0505";
            _fillOpacity = 0.6;
            _borderWidth = 3;
            break;
        case AirspaceZoneType::YellowZone:
        case AirspaceZoneType::InnerYellow:
            _fillColor = "#d48a00";
            _borderColor = "#d48a00";
            _fillOpacity = 0.5;
            _borderWidth = 2;
            break;
        case AirspaceZoneType::OuterYellow:
            _fillColor = "#b89b00";
            _borderColor = "#b89b00";
            _fillOpacity = 0.4;
            _borderWidth = 2;
            break;
        case AirspaceZoneType::MilitaryZone:
            _fillColor = "#ff0505";   // Military follows red zone color
            _borderColor = "#ff0505";
            _fillOpacity = 0.6;
            _borderWidth = 3;
            break;
        case AirspaceZoneType::Airport:
            _fillColor = "#008a00";   // Airport base is green
            _borderColor = "#008a00";
            _fillOpacity = 0.25;
            _borderWidth = 1;
            break;
        case AirspaceZoneType::CTR:
            _fillColor = "#9370DB";
            _borderColor = "#4B0082";
            _fillOpacity = 0.25;
            _borderWidth = 2;
            break;
        case AirspaceZoneType::RunwayApproach:
            _fillColor = "#f76363";
            _borderColor = "#f76363";
            _fillOpacity = 0.4;
            _borderWidth = 2;
            break;
        case AirspaceZoneType::Temporary:
            _fillColor = "#ff0707";
            _borderColor = "#ff0707";
            _fillOpacity = 0.6;
            _borderWidth = 3;
            break;
        case AirspaceZoneType::Boundary:
            _fillColor = "#d61e1e";
            _borderColor = "#d61e1e";
            _fillOpacity = 0.85;
            _borderWidth = 3;
            break;
        case AirspaceZoneType::Others:
            _fillColor = "#607d8b";   // Blue-grey consistent with comment
            _borderColor = "#607d8b";
            _fillOpacity = 0.2;
            _borderWidth = 2;
            break;
        case AirspaceZoneType::StateBorder:
            _fillColor = "#008a00";   // Aligned with web-app green restriction
            _borderColor = "#008a00";
            _fillOpacity = 0.3;
            _borderWidth = 2;
            break;
        case AirspaceZoneType::Helipad:
            _fillColor = "#cc0000";   // Strong red for helipads
            _borderColor = "#cc0000";
            _fillOpacity = 0.6;
            _borderWidth = 3;
            break;
        case AirspaceZoneType::GreenZone:
        default:
            _fillColor = "#008a00";
            _borderColor = "#008a00";
            _fillOpacity = 0.25;
            _borderWidth = 1;
            break;
    }
}

void AirspaceZone::_calculateIconPosition()
{
    if (_polygon.size() > 0) {
        // Calculate centroid
        double latSum = 0.0;
        double lonSum = 0.0;
        int count = _polygon.size();

        for (const QGeoCoordinate& coord : _polygon.perimeter()) {
            latSum += coord.latitude();
            lonSum += coord.longitude();
        }

        _iconPosition = QGeoCoordinate(latSum / count, lonSum / count);
    }
}

bool AirspaceZone::containsCoordinate(const QGeoCoordinate& coord) const
{
    return _polygon.contains(coord);
}

bool AirspaceZone::intersectsPath(const QList<QGeoCoordinate>& path) const
{
    for (const QGeoCoordinate& coord : path) {
        if (containsCoordinate(coord)) {
            return true;
        }
    }
    return false;
}

QVariant AirspaceZone::path() const
{
    QVariantList list;
    for (const QGeoCoordinate& coord : _polygon.perimeter()) {
        list.append(QVariant::fromValue(coord));
    }
    return QVariant::fromValue(list);
}

//-----------------------------------------------------------------------------
// AirspaceManager Implementation
//-----------------------------------------------------------------------------

AirspaceManager::AirspaceManager(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
    , _networkManager(new QNetworkAccessManager(this))
    , _isLoading(false)
    , _offlineModeEnabled(false)
    , _serverUrl("https://airspace-map-backend-592407489838.asia-south1.run.app/api/facilities")
    , _showAirspace(true)
    , _showLabels(true)
    , _showIcons(true)
    , _autoRefreshTimer(new QTimer(this))
{
    qDebug() << "AirspaceManager initialized with URL:" << _serverUrl;
}

AirspaceManager::~AirspaceManager()
{
    qDeleteAll(_zones);
    _zones.clear();

    if (_cacheDatabase.isOpen()) {
        _cacheDatabase.close();
    }
}

void AirspaceManager::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);

    _initializeDatabase();

    // Setup auto-refresh timer
    _autoRefreshTimer->setInterval(AUTO_REFRESH_INTERVAL_MS);
    connect(_autoRefreshTimer, &QTimer::timeout, this, &AirspaceManager::_autoRefreshTimeout);
    _autoRefreshTimer->start();
}

void AirspaceManager::setOfflineModeEnabled(bool enabled)
{
    if (_offlineModeEnabled != enabled) {
        _offlineModeEnabled = enabled;
        emit offlineModeEnabledChanged();
    }
}

void AirspaceManager::setServerUrl(const QString& url)
{
    if (_serverUrl != url) {
        _serverUrl = url;
        emit serverUrlChanged();
    }
}

void AirspaceManager::setShowAirspace(bool show)
{
    if (_showAirspace != show) {
        _showAirspace = show;
        emit showAirspaceChanged();
    }
}

void AirspaceManager::setShowLabels(bool show)
{
    if (_showLabels != show) {
        _showLabels = show;
        emit showLabelsChanged();
    }
}

void AirspaceManager::setShowIcons(bool show)
{
    if (_showIcons != show) {
        _showIcons = show;
        emit showIconsChanged();
    }
}

void AirspaceManager::fetchAirspaceData(double minLat, double minLon, double maxLat, double maxLon)
{
    QString bbox = _createBboxString(minLat, minLon, maxLat, maxLon);
    _currentBbox = bbox;

    // Try cache first if offline mode or as fallback
    if (_offlineModeEnabled) {
        qDebug() << "AirspaceManager: Loading from cache (offline mode)";
        QList<AirspaceZone*> cachedZones = _loadFromCache(bbox);
        if (!cachedZones.isEmpty()) {
            // Merge cached zones
            int addedCount = 0;
            for (AirspaceZone* cachedZone : cachedZones) {
                bool isDuplicate = false;
                for (AirspaceZone* existingZone : _zones) {
                    if (existingZone->name() == cachedZone->name() && 
                        existingZone->zoneType() == cachedZone->zoneType()) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (isDuplicate) {
                    delete cachedZone;
                } else {
                    _zones.append(cachedZone);
                    addedCount++;
                }
            }
            if (addedCount > 0) {
                _updateZonesVariantList();
            }
            return;
        }
    }

    // Fetch from server
    _fetchFromServer(bbox);
}

void AirspaceManager::refreshAirspaceData()
{
    if (!_currentBbox.isEmpty()) {
        _fetchFromServer(_currentBbox);
    }
}

void AirspaceManager::_fetchFromServer(const QString& bbox)
{
    _setIsLoading(true);
    _setErrorMessage("");

    QUrl url(_serverUrl);
    QUrlQuery query;
    if (!bbox.isEmpty()) {
        query.addQueryItem("bbox", bbox);
    }
    query.addQueryItem("all", "true");
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");

    QNetworkReply* reply = _networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, &AirspaceManager::_handleNetworkReply);
    connect(reply, QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::errorOccurred),
            this, &AirspaceManager::_handleNetworkError);

    qInfo() << "AirspaceManager: Fetching from" << url.toString();
}

void AirspaceManager::_handleNetworkReply()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    reply->deleteLater();
    _setIsLoading(false);

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        
        // Offset parsing to background thread to prevent UI hang
        QtConcurrent::run([this, data] {
            QJsonParseError parseError;
            QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
            
            if (parseError.error != QJsonParseError::NoError) {
                QString errorMsg = QString("JSON parse error: %1").arg(parseError.errorString());
                QMetaObject::invokeMethod(this, [this, errorMsg] { _setErrorMessage(errorMsg); });
                return;
            }
            
            // Re-dispatch the heavy processing to the main thread in a way that doesn't block it entirely
            // Or better: pass the parsed document to a processing function
            QMetaObject::invokeMethod(this, [this, doc] {
                _processParsedJson(doc);
            });
        });
    } else {
        QString errorMsg = QString("Network error: %1").arg(reply->errorString());
        _setErrorMessage(errorMsg);
        qWarning() << "AirspaceManager:" << errorMsg;

        // Fallback to cache
        if (!_offlineModeEnabled && !_currentBbox.isEmpty()) {
            qDebug() << "AirspaceManager: Falling back to cache";
            QList<AirspaceZone*> cachedZones = _loadFromCache(_currentBbox);
            if (!cachedZones.isEmpty()) {
                int addedCount = 0;
                for (AirspaceZone* cachedZone : cachedZones) {
                    bool isDuplicate = false;
                    for (AirspaceZone* existingZone : _zones) {
                        if (existingZone->name() == cachedZone->name()) {
                            isDuplicate = true;
                            break;
                        }
                    }
                    if (isDuplicate) {
                        delete cachedZone;
                    } else {
                        _zones.append(cachedZone);
                        addedCount++;
                    }
                }
                if (addedCount > 0) {
                    _updateZonesVariantList();
                }
            }
        }
    }
}

void AirspaceManager::_handleNetworkError(QNetworkReply::NetworkError error)
{
    qWarning() << "AirspaceManager: Network error code:" << error;
}

void AirspaceManager::_parseGeoJsonResponse(const QByteArray& data)
{
    // Now done in the background in _handleNetworkReply
    Q_UNUSED(data);
}

void AirspaceManager::_processParsedJson(const QJsonDocument& doc)
{
    QJsonArray features;
    if (doc.isArray()) {
        features = doc.array();
    } else {
        QJsonObject rootObj = doc.object();
        QString type = rootObj["type"].toString();
        
        if (type == "FeatureCollection") {
            features = rootObj["features"].toArray();
        } else if (type == "Feature") {
            features.append(rootObj);
        } else if (rootObj.contains("data") && rootObj["data"].isArray()) {
            features = rootObj["data"].toArray();
        } else if (rootObj.contains("facilities") && rootObj["facilities"].isArray()) {
            features = rootObj["facilities"].toArray();
        } else if (rootObj.contains("_id") && rootObj.contains("geometry")) {
            features.append(rootObj);
        } else {
            return;
        }
    }

    QList<AirspaceZone*> newZones;
    for (const QJsonValue& featureVal : features) {
        QJsonObject featureObj = featureVal.toObject();
        bool foundSubZones = false;

        QJsonObject zonesContainer;
        if (featureObj.contains("finalZones") && featureObj["finalZones"].isObject()) {
            zonesContainer = featureObj["finalZones"].toObject();
        } else if (featureObj.contains("zones") && featureObj["zones"].isObject()) {
            zonesContainer = featureObj["zones"].toObject();
        }

        QJsonObject parentGeometry;
        if (featureObj.contains("geometry")) parentGeometry = featureObj["geometry"].toObject();
        else if (featureObj.contains("geojson")) parentGeometry = featureObj["geojson"].toObject();
        
        bool parentIsPoint = !parentGeometry.isEmpty() && parentGeometry["type"].toString() == "Point";

        if (!zonesContainer.isEmpty()) {
            for (auto it = zonesContainer.begin(); it != zonesContainer.end(); ++it) {
                QJsonObject subObj = it.value().toObject();
                if (subObj.isEmpty()) continue;

                QJsonObject featureToParse;
                bool isRadiusZone = false;

                if (subObj.contains("geometry") || subObj.contains("geojson")) {
                    featureToParse = subObj;
                } else if (subObj.contains("type") && 
                          (subObj["type"].toString() == "Polygon" || subObj["type"].toString() == "MultiPolygon")) {
                    featureToParse["geometry"] = subObj;
                } else if (subObj.contains("radius") && parentIsPoint) {
                    featureToParse["geometry"] = parentGeometry;
                    featureToParse["properties"] = QJsonObject(); 
                    isRadiusZone = true;
                } else {
                    continue;
                }

                if (!featureToParse.contains("properties") || isRadiusZone) {
                    QJsonObject props = featureToParse.contains("properties") ? featureToParse["properties"].toObject() : QJsonObject();
                    if (!props.contains("name")) {
                        props["name"] = QString("%1 (%2)").arg(featureObj["name"].toString()).arg(it.key());
                    }
                    if (!props.contains("zoneType")) {
                        props["zoneType"] = it.key();
                    }
                    if (isRadiusZone) {
                        props["radius"] = subObj["radius"];
                    }
                    featureToParse["properties"] = props;
                }

                AirspaceZone* zone = _parseGeoJsonFeature(featureToParse);
                if (zone) {
                    newZones.append(zone);
                    foundSubZones = true;
                }
            }
        }

        if (!foundSubZones) {
            AirspaceZone* zone = _parseGeoJsonFeature(featureObj);
            if (zone) {
                newZones.append(zone);
            }
        }
    }

    // High-performance duplicate check using a temporary HashSet
    QSet<QString> existingKeys;
    for (AirspaceZone* z : _zones) {
        existingKeys.insert(z->name() + ":" + z->zoneTypeString());
    }

    int addedCount = 0;
    for (AirspaceZone* newZone : newZones) {
        QString key = newZone->name() + ":" + newZone->zoneTypeString();
        if (existingKeys.contains(key)) {
            delete newZone;
        } else {
            _zones.append(newZone);
            existingKeys.insert(key);
            addedCount++;
        }
    }

    if (addedCount > 0) {
        qInfo() << "AirspaceManager: Added" << addedCount << "new unique zones via Background Thread processing. Total:" << _zones.size();
        _updateZonesVariantList();
        _saveToCache(_zones);
    }
}


AirspaceZone* AirspaceManager::_parseGeoJsonFeature(const QJsonObject& feature)
{
    // Check if it's a GeoJSON Feature or a raw database object
    QJsonObject geometry;
    QJsonObject properties;

    if (feature.contains("type") && feature["type"].toString() == "Feature") {
        geometry = feature["geometry"].toObject();
        properties = feature["properties"].toObject();
    } else if (feature.contains("geometry") || feature.contains("geojson")) {
        // Raw database object
        geometry = feature.contains("geometry") ? feature["geometry"].toObject() : feature["geojson"].toObject();
        
        // Handle potentially nested properties
        if (feature.contains("properties") && feature["properties"].isObject()) {
            properties = feature["properties"].toObject();
            // Merge root items into properties if not already present
            for (auto it = feature.begin(); it != feature.end(); ++it) {
                if (it.key() != "properties" && it.key() != "geometry" && it.key() != "geojson" && !properties.contains(it.key())) {
                    properties.insert(it.key(), it.value());
                }
            }
        } else {
            properties = feature;
        }
    } else {
        return nullptr;
    }

    QString geometryType = geometry["type"].toString();

    // Allow Point type for circle generation
    if (geometryType != "Polygon" && geometryType != "MultiPolygon" && geometryType != "Point") {
        // Only warn for non-empty unexpected types; silently skip null/empty geometry
        // (backend returns many facilities without drawable geometry, e.g. POI markers)
        if (!geometryType.isEmpty()) {
            qWarning() << "AirspaceManager: Skipping unsupported geometry type:" << geometryType;
        }
        return nullptr;
    }

    AirspaceZone* zone = new AirspaceZone(this);

    // Parse properties
    zone->setProperties(properties);

    // Parse coordinates
    QJsonArray coordinates = geometry["coordinates"].toArray();
    QVariantList coordsList;

    if (geometryType == "Point") {
        // Generate Circle Polygon from Point + Radius
        double radiusKm = 0;
        if (properties.contains("radius")) {
             radiusKm = properties["radius"].toDouble();
             zone->setRadius(radiusKm * 1000.0); // Store in meters
        }
        
        if (radiusKm > 0) {
            double lon = 0;
            double lat = 0;
            
            // Handle Coordinates [lon, lat]
            if (coordinates.size() >= 2) {
                 lon = coordinates[0].toDouble();
                 lat = coordinates[1].toDouble();
            }

            QGeoCoordinate center(lat, lon);
            if (center.isValid()) {
                // Optimized linear approximation for circle generation (36 sides)
                // Much faster than atDistanceAndAzimuth for mobile UI
                const double R = 6378137.0; // Earth radius in meters
                static const double deg2rad = M_PI / 180.0;
                static const double rad2deg = 180.0 / M_PI;

                double latRad = lat * deg2rad;
                double deltaLat = (radiusKm * 1000.0 / R) * rad2deg;
                double deltaLon = deltaLat / cos(latRad);

                for (int i = 0; i <= 36; i++) {
                    double angle = i * 10.0 * deg2rad;
                    double vLat = lat + deltaLat * cos(angle);
                    double vLon = lon + deltaLon * sin(angle);
                    
                    QVariantList coord;
                    coord << vLon << vLat;
                    coordsList.append(QVariant(coord));
                }
            }
        }
    } else if (geometryType == "Polygon") {
        // Polygon: coordinates[0] is the outer ring
        QJsonArray ring = coordinates[0].toArray();
        for (const QJsonValue& pointVal : ring) {
            QJsonArray point = pointVal.toArray();
            if (point.size() >= 2) {
                QVariantList coord;
                coord << point[0].toDouble() << point[1].toDouble();
                coordsList.append(QVariant(coord));
            }
        }
    } else if (geometryType == "MultiPolygon") {
        // MultiPolygon: Use first polygon for now
        // TODO: Support multiple polygons
        QJsonArray firstPolygon = coordinates[0].toArray();
        QJsonArray ring = firstPolygon[0].toArray();
        for (const QJsonValue& pointVal : ring) {
            QJsonArray point = pointVal.toArray();
            if (point.size() >= 2) {
                QVariantList coord;
                coord << point[0].toDouble() << point[1].toDouble();
                coordsList.append(QVariant(coord));
            }
        }
    }

    zone->setCoordinates(coordsList);
    return zone;
}

bool AirspaceManager::checkMissionRestrictions(const QVariantList& waypoints, QString& errorMessage)
{
    QList<QGeoCoordinate> path;

    // Convert waypoints to QGeoCoordinate list
    for (const QVariant& wpVar : waypoints) {
        QVariantMap wpMap = wpVar.toMap();
        double lat = wpMap["latitude"].toDouble();
        double lon = wpMap["longitude"].toDouble();
        double alt = wpMap["altitude"].toDouble();
        
        QGeoCoordinate coord(lat, lon, alt);
        if (coord.isValid()) {
            path.append(coord);
        }
    }

    // Check each zone
    for (AirspaceZone* zone : _zones) {
        if (!zone->isActive()) continue;

        if (zone->intersectsPath(path)) {
            // Check altitude constraints
            bool altitudeViolation = false;
            for (const QGeoCoordinate& coord : path) {
                if (zone->containsCoordinate(coord)) {
                    double alt = coord.altitude();
                    if (alt >= zone->minAltitude() && alt <= zone->maxAltitude()) {
                        altitudeViolation = true;
                        break;
                    }
                }
            }

            AirspaceZoneType zType = zone->zoneType();
            bool isBlocking = (zType == AirspaceZoneType::RedZone || 
                               zType == AirspaceZoneType::Boundary || 
                               zType == AirspaceZoneType::Temporary || 
                               zType == AirspaceZoneType::Helipad);

            if (altitudeViolation || isBlocking) {
                if (isBlocking) {
                    errorMessage = QString("Mission blocked: Path intersects prohibited/restricted zone '%1'")
                                       .arg(zone->name());
                    emit missionRestrictionDetected(zone->name(), zone->zoneTypeString(), errorMessage);
                    return false; // Block mission
                } else {
                    // Advisory zones
                    errorMessage = QString("Warning: Path intersects restricted/advisory zone '%1'. Proceed with caution.")
                                       .arg(zone->name());
                    emit missionRestrictionDetected(zone->name(), zone->zoneTypeString(), errorMessage);
                }
            }
        }
    }

    return true; // Mission allowed
}

QVariantList AirspaceManager::getRestrictionsAtCoordinate(double lat, double lon, double altitude)
{
    QVariantList restrictions;
    QGeoCoordinate coord(lat, lon, altitude);

    for (AirspaceZone* zone : _zones) {
        if (zone->containsCoordinate(coord)) {
            QVariantMap restriction;
            restriction["name"] = zone->name();
            restriction["description"] = zone->description();
            
            AirspaceZoneType zType = zone->zoneType();
            if (zType == AirspaceZoneType::RedZone || zType == AirspaceZoneType::Boundary || 
                zType == AirspaceZoneType::Temporary || zType == AirspaceZoneType::Helipad) {
                restriction["type"] = "red";
            } else if (zType == AirspaceZoneType::InnerYellow || zType == AirspaceZoneType::OuterYellow ||
                       zType == AirspaceZoneType::YellowZone || zType == AirspaceZoneType::MilitaryZone) {
                restriction["type"] = "yellow";
            } else {
                restriction["type"] = "none";
            }

            restriction["zoneType"] = zone->zoneTypeString(); // Required by QML
            restriction["minAltitude"] = zone->minAltitude();
            restriction["maxAltitude"] = zone->maxAltitude();
            restriction["borderColor"] = zone->borderColor(); // Added
            restriction["fillColor"] = zone->fillColor();     // Added
            restrictions.append(restriction);
        }
    }

    return restrictions;
}

bool AirspaceManager::isCoordinateInRedZone(const QGeoCoordinate& coord)
{
    for (AirspaceZone* zone : _zones) {
        if (zone->isActive() && zone->containsCoordinate(coord)) {
            AirspaceZoneType zType = zone->zoneType();
            if (zType == AirspaceZoneType::RedZone || 
                zType == AirspaceZoneType::Boundary || 
                zType == AirspaceZoneType::Temporary || 
                zType == AirspaceZoneType::Helipad) {
                return true;
            }
        }
    }
    return false;
}

void AirspaceManager::clearCache()
{
    _clearCacheDatabase();
    _setErrorMessage("");
}

void AirspaceManager::_autoRefreshTimeout()
{
    if (!_currentBbox.isEmpty() && !_offlineModeEnabled) {
        qDebug() << "AirspaceManager: Auto-refreshing airspace data";
        refreshAirspaceData();
    }
}

void AirspaceManager::_initializeDatabase()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    QString dbPath = dataPath + "/" + CACHE_DB_NAME;

    _cacheDatabase = QSqlDatabase::addDatabase("QSQLITE", "airspace_cache");
    _cacheDatabase.setDatabaseName(dbPath);

    if (!_cacheDatabase.open()) {
        qWarning() << "AirspaceManager: Failed to open cache database:" << _cacheDatabase.lastError().text();
        return;
    }

    QSqlQuery query(_cacheDatabase);
    query.exec("CREATE TABLE IF NOT EXISTS airspace_zones ("
               "id INTEGER PRIMARY KEY AUTOINCREMENT,"
               "bbox TEXT NOT NULL,"
               "name TEXT,"
               "zone_type TEXT,"
               "geojson TEXT NOT NULL,"
               "timestamp INTEGER NOT NULL"
               ")");

    query.exec("CREATE INDEX IF NOT EXISTS idx_bbox ON airspace_zones(bbox)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_timestamp ON airspace_zones(timestamp)");

    qDebug() << "AirspaceManager: Cache database initialized at" << dbPath;
}

void AirspaceManager::_saveToCache(const QList<AirspaceZone*>& zones)
{
    if (!_cacheDatabase.isOpen()) return;

    QMutexLocker locker(&_mutex);

    // Use transaction for massive performance boost in batch inserts
    _cacheDatabase.transaction();

    // Delete old entries for this bbox efficiently
    QSqlQuery deleteQuery(_cacheDatabase);
    deleteQuery.prepare("DELETE FROM airspace_zones WHERE bbox = ?");
    deleteQuery.addBindValue(_currentBbox);
    deleteQuery.exec();

    // Insert new entries
    QSqlQuery insertQuery(_cacheDatabase);
    insertQuery.prepare("INSERT INTO airspace_zones (bbox, name, zone_type, geojson, timestamp) "
                        "VALUES (?, ?, ?, ?, ?)");

    qint64 timestamp = QDateTime::currentSecsSinceEpoch();

    for (AirspaceZone* zone : zones) {
        QJsonObject geoJson;
        geoJson["name"] = zone->name();
        geoJson["zoneType"] = zone->zoneTypeString();
        geoJson["coordinates"] = QJsonArray::fromVariantList(zone->coordinates());
        geoJson["minAltitude"] = zone->minAltitude();
        geoJson["maxAltitude"] = zone->maxAltitude();
        geoJson["description"] = zone->description();

        insertQuery.addBindValue(_currentBbox);
        insertQuery.addBindValue(zone->name());
        insertQuery.addBindValue(zone->zoneTypeString());
        insertQuery.addBindValue(QString(QJsonDocument(geoJson).toJson(QJsonDocument::Compact)));
        insertQuery.addBindValue(timestamp);
        insertQuery.exec();
    }

    if (!_cacheDatabase.commit()) {
        qWarning() << "AirspaceManager: Failed to commit cache transaction";
        _cacheDatabase.rollback();
    }

    qDebug() << "AirspaceManager: Saved" << zones.size() << "zones to cache via batch transaction";
}

QList<AirspaceZone*> AirspaceManager::_loadFromCache(const QString& bbox)
{
    QList<AirspaceZone*> zones;

    if (!_cacheDatabase.isOpen()) return zones;

    QMutexLocker locker(&_mutex);

    QSqlQuery query(_cacheDatabase);
    query.prepare("SELECT geojson FROM airspace_zones WHERE bbox = ?");
    query.addBindValue(bbox);

    if (!query.exec()) {
        qWarning() << "AirspaceManager: Cache query failed:" << query.lastError().text();
        return zones;
    }

    while (query.next()) {
        QString geoJsonStr = query.value(0).toString();
        QJsonDocument doc = QJsonDocument::fromJson(geoJsonStr.toUtf8());
        QJsonObject obj = doc.object();

        AirspaceZone* zone = new AirspaceZone(this);
        zone->setName(obj["name"].toString());
        zone->setProperties(obj);
        zone->setCoordinates(obj["coordinates"].toArray().toVariantList());
        zone->setMinAltitude(obj["minAltitude"].toDouble());
        zone->setMaxAltitude(obj["maxAltitude"].toDouble());
        zone->setDescription(obj["description"].toString());

        zones.append(zone);
    }

    qDebug() << "AirspaceManager: Loaded" << zones.size() << "zones from cache";
    return zones;
}

void AirspaceManager::_clearCacheDatabase()
{
    if (!_cacheDatabase.isOpen()) return;

    QMutexLocker locker(&_mutex);
    QSqlQuery query(_cacheDatabase);
    query.exec("DELETE FROM airspace_zones");
    qDebug() << "AirspaceManager: Cache cleared";
}

void AirspaceManager::_setIsLoading(bool loading)
{
    if (_isLoading != loading) {
        _isLoading = loading;
        emit isLoadingChanged();
    }
}

void AirspaceManager::_setErrorMessage(const QString& message)
{
    if (_errorMessage != message) {
        _errorMessage = message;
        emit errorMessageChanged();
    }
}

void AirspaceManager::_updateZonesVariantList()
{
    _zonesVariantList.clear();
    for (AirspaceZone* zone : _zones) {
        _zonesVariantList.append(QVariant::fromValue(zone));
    }
    emit zonesChanged();
}

QString AirspaceManager::_createBboxString(double minLat, double minLon, double maxLat, double maxLon)
{
    return QString("%1,%2,%3,%4").arg(minLon).arg(minLat).arg(maxLon).arg(maxLat);
}
