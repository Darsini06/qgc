/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "AirspaceRestrictionValidator.h"
#include "AirspaceManager.h"
#include "MissionController.h"
#include "MissionManager.h"
#include "SimpleMissionItem.h"
#include "VisualMissionItem.h"

#include <QDebug>

AirspaceRestrictionValidator::AirspaceRestrictionValidator(QObject* parent)
    : QObject(parent)
    , _airspaceManager(nullptr)
    , _hasRestrictions(false)
    , _blockMissionUpload(false)
{
}

AirspaceRestrictionValidator::AirspaceRestrictionValidator(AirspaceManager* airspaceManager, QObject* parent)
    : QObject(parent)
    , _airspaceManager(airspaceManager)
    , _hasRestrictions(false)
    , _blockMissionUpload(false)
{
}

void AirspaceRestrictionValidator::setAirspaceManager(AirspaceManager* manager)
{
    if (_airspaceManager != manager) {
        _airspaceManager = manager;
        emit airspaceManagerChanged();
    }
}

bool AirspaceRestrictionValidator::validateMission(QObject* missionControllerObj)
{
    clearValidation();

    if (!_airspaceManager) {
        qWarning() << "AirspaceRestrictionValidator: No airspace manager set";
        return true;
    }

    if (!missionControllerObj) {
        qWarning() << "AirspaceRestrictionValidator: Null mission controller";
        return true; // Allow if no controller
    }

    // Try to cast to MissionController
    MissionController* missionController = qobject_cast<MissionController*>(missionControllerObj);
    if (!missionController) {
        qWarning() << "AirspaceRestrictionValidator: Invalid mission controller type";
        return true;
    }

    // Get visual items (waypoints)
    QmlObjectListModel* visualItems = missionController->visualItems();
    if (!visualItems || visualItems->count() == 0) {
        return true; // No waypoints to validate
    }

    // Build waypoint list
    QVariantList waypoints;
    for (int i = 0; i < visualItems->count(); i++) {
        VisualMissionItem* item = qobject_cast<VisualMissionItem*>(visualItems->get(i));
        if (!item) continue;

        QGeoCoordinate coord = item->coordinate();
        if (!coord.isValid()) continue;

        QVariantMap waypoint;
        waypoint["latitude"] = coord.latitude();
        waypoint["longitude"] = coord.longitude();
        waypoint["altitude"] = coord.altitude();
        waypoint["index"] = i;
        waypoints.append(waypoint);
    }

    if (waypoints.isEmpty()) {
        return true;
    }

    // Validate against airspace restrictions
    QString errorMessage;
    bool allowed = _airspaceManager->checkMissionRestrictions(waypoints, errorMessage);

    if (!allowed) {
        _setHasRestrictions(true);
        _setRestrictionMessage(errorMessage);
        _setBlockMissionUpload(true);
        emit validationComplete(false, errorMessage);
        qWarning() << "AirspaceRestrictionValidator: Mission blocked -" << errorMessage;
        return false;
    } else if (!errorMessage.isEmpty()) {
        // Warning but not blocked
        _setHasRestrictions(true);
        _setRestrictionMessage(errorMessage);
        _setBlockMissionUpload(false);
        emit validationComplete(true, errorMessage);
        qDebug() << "AirspaceRestrictionValidator: Mission warning -" << errorMessage;
    }

    return true;
}

bool AirspaceRestrictionValidator::validateWaypoint(double latitude, double longitude, double altitude)
{
    if (!_airspaceManager) {
        return true;
    }

    QVariantList restrictions = _airspaceManager->getRestrictionsAtCoordinate(latitude, longitude, altitude);

    if (restrictions.isEmpty()) {
        return true;
    }

    // Check for blocking restrictions
    for (const QVariant& restrictionVar : restrictions) {
        QVariantMap restriction = restrictionVar.toMap();
        QString zoneType = restriction["type"].toString();

        if (zoneType == "red" || zoneType == "prohibited" || zoneType == "boundary" || zoneType == "temporary" || zoneType == "helipad") {
            QString message = QString("Waypoint in prohibited/restricted zone: %1")
                                  .arg(restriction["name"].toString());
            _setHasRestrictions(true);
            _setRestrictionMessage(message);
            _setBlockMissionUpload(true);
            return false;
        } else if (zoneType == "yellow" || zoneType == "military" || zoneType == "restricted" || 
                   zoneType == "inneryellow" || zoneType == "outeryellow" || zoneType == "others" ||
                   zoneType == "states" || zoneType == "runway") {
            QString message = QString("Waypoint in advisory/restricted zone: %1 - Proceed with caution")
                                  .arg(restriction["name"].toString());
            _setHasRestrictions(true);
            _setRestrictionMessage(message);
            _setBlockMissionUpload(false);
        }
    }

    return true;
}

QVariantList AirspaceRestrictionValidator::getRestrictionsAt(double latitude, double longitude, double altitude)
{
    if (!_airspaceManager) {
        return QVariantList();
    }
    return _airspaceManager->getRestrictionsAtCoordinate(latitude, longitude, altitude);
}

void AirspaceRestrictionValidator::clearValidation()
{
    _setHasRestrictions(false);
    _setRestrictionMessage("");
    _setBlockMissionUpload(false);
}

void AirspaceRestrictionValidator::_setHasRestrictions(bool has)
{
    if (_hasRestrictions != has) {
        _hasRestrictions = has;
        emit hasRestrictionsChanged();
    }
}

void AirspaceRestrictionValidator::_setRestrictionMessage(const QString& message)
{
    if (_restrictionMessage != message) {
        _restrictionMessage = message;
        emit restrictionMessageChanged();
    }
}

void AirspaceRestrictionValidator::_setBlockMissionUpload(bool block)
{
    if (_blockMissionUpload != block) {
        _blockMissionUpload = block;
        emit blockMissionUploadChanged();
    }
}
