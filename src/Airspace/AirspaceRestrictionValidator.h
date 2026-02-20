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

class AirspaceManager;
class MissionController;
class PlanMasterController;

/**
 * @brief Validates mission plans against airspace restrictions
 * 
 * This class integrates with QGC's mission planning system to:
 * - Check waypoints against restricted zones
 * - Block mission upload for red zones
 * - Warn for yellow/military zones
 * - Provide detailed violation information
 */
class AirspaceRestrictionValidator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasRestrictions READ hasRestrictions NOTIFY hasRestrictionsChanged)
    Q_PROPERTY(QString restrictionMessage READ restrictionMessage NOTIFY restrictionMessageChanged)
    Q_PROPERTY(bool blockMissionUpload READ blockMissionUpload NOTIFY blockMissionUploadChanged)

public:
    explicit AirspaceRestrictionValidator(AirspaceManager* airspaceManager, QObject* parent = nullptr);
    ~AirspaceRestrictionValidator() override = default;

    bool hasRestrictions() const { return _hasRestrictions; }
    QString restrictionMessage() const { return _restrictionMessage; }
    bool blockMissionUpload() const { return _blockMissionUpload; }

    /**
     * @brief Validate a mission plan
     * @param missionController The mission controller to validate
     * @return true if mission is allowed, false if blocked
     */
    Q_INVOKABLE bool validateMission(QObject* missionController);

    /**
     * @brief Validate a single waypoint
     * @param latitude Waypoint latitude
     * @param longitude Waypoint longitude
     * @param altitude Waypoint altitude (meters)
     * @return true if waypoint is allowed, false if in restricted zone
     */
    Q_INVOKABLE bool validateWaypoint(double latitude, double longitude, double altitude);

    /**
     * @brief Get restriction details at a coordinate
     * @param latitude Coordinate latitude
     * @param longitude Coordinate longitude
     * @param altitude Altitude (meters)
     * @return List of restrictions at this location
     */
    Q_INVOKABLE QVariantList getRestrictionsAt(double latitude, double longitude, double altitude);

    /**
     * @brief Clear current validation state
     */
    Q_INVOKABLE void clearValidation();

signals:
    void hasRestrictionsChanged();
    void restrictionMessageChanged();
    void blockMissionUploadChanged();
    void validationComplete(bool allowed, QString message);
    void waypointRestrictionDetected(int waypointIndex, QString zoneName, QString zoneType);

private:
    void _setHasRestrictions(bool has);
    void _setRestrictionMessage(const QString& message);
    void _setBlockMissionUpload(bool block);

    AirspaceManager* _airspaceManager;
    bool _hasRestrictions;
    QString _restrictionMessage;
    bool _blockMissionUpload;
};
