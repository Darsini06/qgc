/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QGeoCoordinate>
#include <QGeoPolygon>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantList>
#include <QTimer>
#include <QSqlDatabase>
#include <QMutex>

class QGCToolbox;
class AirspaceRestriction;
class AirspaceZone;

/**
 * @brief Airspace Zone Types
 */
enum class AirspaceZoneType {
    RedZone,        // Prohibited - No flight allowed
    YellowZone,     // Restricted - Warning required
    GreenZone,      // Permitted - Free flight
    MilitaryZone,   // Military restricted area
    Airport,        // Airport area
    InnerYellow,    // Inner restricted warning zone
    OuterYellow,    // Outer restricted warning zone
    CTR,            // Control Zone
    RunwayApproach, // Runway approach path
    Temporary       // Temporary restriction (NOTAM)
};

/**
 * @brief Represents a single airspace zone
 */
class AirspaceZone : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString zoneType READ zoneTypeString CONSTANT)
    Q_PROPERTY(QVariantList coordinates READ coordinates CONSTANT)
    Q_PROPERTY(QString fillColor READ fillColor CONSTANT)
    Q_PROPERTY(QString borderColor READ borderColor CONSTANT)
    Q_PROPERTY(double fillOpacity READ fillOpacity CONSTANT)
    Q_PROPERTY(int borderWidth READ borderWidth CONSTANT)
    Q_PROPERTY(double minAltitude READ minAltitude CONSTANT)
    Q_PROPERTY(double maxAltitude READ maxAltitude CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(bool isActive READ isActive CONSTANT)
    Q_PROPERTY(QGeoCoordinate iconPosition READ iconPosition CONSTANT)
    Q_PROPERTY(double radius READ radius CONSTANT)
    Q_PROPERTY(QVariant path READ path CONSTANT)

public:
    explicit AirspaceZone(QObject* parent = nullptr);
    ~AirspaceZone() override = default;

    // Getters
    QString name() const { return _name; }
    AirspaceZoneType zoneType() const { return _zoneType; }
    QString zoneTypeString() const;
    QVariantList coordinates() const { return _coordinates; }
    QGeoPolygon polygon() const { return _polygon; }
    QString fillColor() const { return _fillColor; }
    QString borderColor() const { return _borderColor; }
    double fillOpacity() const { return _fillOpacity; }
    int borderWidth() const { return _borderWidth; }
    double minAltitude() const { return _minAltitude; }
    double maxAltitude() const { return _maxAltitude; }
    QString description() const { return _description; }
    bool isActive() const { return _isActive; }
    QGeoCoordinate iconPosition() const { return _iconPosition; }
    double radius() const { return _radius; }
    QVariant path() const;

    // Setters
    void setName(const QString& name) { _name = name; }
    void setZoneType(AirspaceZoneType type);
    void setCoordinates(const QVariantList& coords);
    void setMinAltitude(double alt) { _minAltitude = alt; }
    void setMaxAltitude(double alt) { _maxAltitude = alt; }
    void setDescription(const QString& desc) { _description = desc; }
    void setIsActive(bool active) { _isActive = active; }
    void setRadius(double r) { _radius = r; }
    void setProperties(const QJsonObject& props);

    // Utility methods
    bool containsCoordinate(const QGeoCoordinate& coord) const;
    bool intersectsPath(const QList<QGeoCoordinate>& path) const;

private:
    void _updateStyling();
    void _calculateIconPosition();

    QString _name;
    AirspaceZoneType _zoneType;
    QVariantList _coordinates;  // For QML
    QGeoPolygon _polygon;       // For C++ calculations
    QString _fillColor;
    QString _borderColor;
    double _fillOpacity;
    int _borderWidth;
    double _minAltitude;
    double _maxAltitude;
    QString _description;
    bool _isActive;
    QGeoCoordinate _iconPosition;
    double _radius = 0.0;
};

/**
 * @brief Manages airspace data fetching, caching, and rendering
 */
class AirspaceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList zones READ zones NOTIFY zonesChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool offlineModeEnabled READ offlineModeEnabled WRITE setOfflineModeEnabled NOTIFY offlineModeEnabledChanged)
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(bool showAirspace READ showAirspace WRITE setShowAirspace NOTIFY showAirspaceChanged)
    Q_PROPERTY(bool showLabels READ showLabels WRITE setShowLabels NOTIFY showLabelsChanged)
    Q_PROPERTY(bool showIcons READ showIcons WRITE setShowIcons NOTIFY showIconsChanged)

public:
    explicit AirspaceManager(QGCToolbox* toolbox, QObject* parent = nullptr);
    ~AirspaceManager() override;

    // Property getters
    QVariantList zones() const { return _zonesVariantList; }
    bool isLoading() const { return _isLoading; }
    QString errorMessage() const { return _errorMessage; }
    bool offlineModeEnabled() const { return _offlineModeEnabled; }
    QString serverUrl() const { return _serverUrl; }
    bool showAirspace() const { return _showAirspace; }
    bool showLabels() const { return _showLabels; }
    bool showIcons() const { return _showIcons; }

    // Property setters
    void setOfflineModeEnabled(bool enabled);
    void setServerUrl(const QString& url);
    void setShowAirspace(bool show);
    void setShowLabels(bool show);
    void setShowIcons(bool show);

    // Public methods
    Q_INVOKABLE void fetchAirspaceData(double minLat, double minLon, double maxLat, double maxLon);
    Q_INVOKABLE void refreshAirspaceData();
    Q_INVOKABLE bool checkMissionRestrictions(const QVariantList& waypoints, QString& errorMessage);
    Q_INVOKABLE QVariantList getRestrictionsAtCoordinate(double lat, double lon, double altitude);
    Q_INVOKABLE void clearCache();

signals:
    void zonesChanged();
    void isLoadingChanged();
    void errorMessageChanged();
    void offlineModeEnabledChanged();
    void serverUrlChanged();
    void showAirspaceChanged();
    void showLabelsChanged();
    void showIconsChanged();
    void missionRestrictionDetected(QString zoneName, QString zoneType, QString message);

private slots:
    void _handleNetworkReply();
    void _handleNetworkError(QNetworkReply::NetworkError error);
    void _autoRefreshTimeout();

private:
    // Network methods
    void _fetchFromServer(const QString& bbox);
    void _parseGeoJsonResponse(const QByteArray& data);
    AirspaceZone* _parseGeoJsonFeature(const QJsonObject& feature);

    // Database methods
    void _initializeDatabase();
    void _saveToCache(const QList<AirspaceZone*>& zones);
    QList<AirspaceZone*> _loadFromCache(const QString& bbox);
    void _clearCacheDatabase();

    // Utility methods
    void _setIsLoading(bool loading);
    void _setErrorMessage(const QString& message);
    void _updateZonesVariantList();
    QString _createBboxString(double minLat, double minLon, double maxLat, double maxLon);

    QGCToolbox* _toolbox;
    QNetworkAccessManager* _networkManager;
    QList<AirspaceZone*> _zones;
    QVariantList _zonesVariantList;
    bool _isLoading;
    QString _errorMessage;
    bool _offlineModeEnabled;
    QString _serverUrl;
    bool _showAirspace;
    bool _showLabels;
    bool _showIcons;
    QString _currentBbox;
    QTimer* _autoRefreshTimer;
    QSqlDatabase _cacheDatabase;
    QMutex _mutex;

    static constexpr int AUTO_REFRESH_INTERVAL_MS = 300000; // 5 minutes
    static constexpr const char* CACHE_DB_NAME = "airspace_cache.db";
};
