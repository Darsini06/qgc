#include "SpotSprayingComplexItem.h"
#include "JsonHelper.h"
#include "MissionController.h"
#include "PlanMasterController.h"
#include "QGCLoggingCategory.h"
#include "QGCApplication.h"
#include "ShapeFileHelper.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include "MissionItem.h"

const QString SpotSprayingComplexItem::name(QStringLiteral("Spot Spraying"));

SpotSprayingPoint::SpotSprayingPoint(const QGeoCoordinate& coord, QObject* parent)
    : QObject(parent)
    , _coordinate(coord)
{
}

SpotSprayingComplexItem::SpotSprayingComplexItem(PlanMasterController* masterController, bool flyView, const QString& kmlOrShpFile, QObject* parent)
    : ComplexMissionItem(masterController, flyView)
    , _sequenceNumber(0)
    , _dirty(false)
{
    _editorQml = QStringLiteral("qrc:/qml/SpotSprayingEditor.qml");
    _points.setParent(this);
    
    if (!kmlOrShpFile.isEmpty()) {
        QList<QGeoCoordinate> coords;
        QString errorString;
        
        // Use ShapeFileHelper to load the coordinates
        ShapeFileHelper::loadPolygonFromFile(kmlOrShpFile, coords, errorString);
        
        for (const QGeoCoordinate& coord : coords) {
            SpotSprayingPoint* p = new SpotSprayingPoint(coord, this);
            _connectPoint(p);
            _points.append(p);
        }
    }
    
    connect(&_points, &QmlObjectListModel::countChanged, this, &SpotSprayingComplexItem::_updatePoints);
}

SpotSprayingComplexItem::~SpotSprayingComplexItem()
{
    _points.clearAndDeleteContents();
}

void SpotSprayingComplexItem::_connectPoint(SpotSprayingPoint* p)
{
    connect(p, &SpotSprayingPoint::coordinateChanged, this, &SpotSprayingComplexItem::_updatePoints);
    connect(p, &SpotSprayingPoint::altitudeChanged,   this, &SpotSprayingComplexItem::_updatePoints);
    connect(p, &SpotSprayingPoint::durationChanged,   this, &SpotSprayingComplexItem::_updatePoints);
    connect(p, &SpotSprayingPoint::sprayChanged,      this, &SpotSprayingComplexItem::_updatePoints);
}

QObject* SpotSprayingComplexItem::createPoint(const QGeoCoordinate& coord)
{
    SpotSprayingPoint* p = new SpotSprayingPoint(coord, this);
    _connectPoint(p);
    _points.append(p);
    return p;
}

void SpotSprayingComplexItem::_updatePoints()
{
    setDirty(true);
    emit coordinateChanged(coordinate());
    emit exitCoordinateChanged(exitCoordinate());
    emit lastSequenceNumberChanged(lastSequenceNumber());
}

int SpotSprayingComplexItem::lastSequenceNumber(void) const
{
    int count = 0;
    for (int i = 0; i < _points.count(); i++) {
        SpotSprayingPoint* p = const_cast<QmlObjectListModel*>(&_points)->value<SpotSprayingPoint*>(i);
        if (p->spray()) {
            count += 4;
        } else {
            count += 1;
        }
    }
    return _sequenceNumber + count - 1;
}

double SpotSprayingComplexItem::greatestDistanceTo(const QGeoCoordinate &other) const
{
    double greatestDist = 0.0;
    for (int i=0; i<_points.count(); i++) {
        SpotSprayingPoint* p = const_cast<QmlObjectListModel*>(&_points)->value<SpotSprayingPoint*>(i);
        double dist = p->coordinate().distanceTo(other);
        if (dist > greatestDist) {
            greatestDist = dist;
        }
    }
    return greatestDist;
}

QGeoCoordinate SpotSprayingComplexItem::coordinate(void) const
{
    if (_points.count() > 0) {
        return const_cast<QmlObjectListModel*>(&_points)->value<SpotSprayingPoint*>(0)->coordinate();
    }
    return QGeoCoordinate();
}

QGeoCoordinate SpotSprayingComplexItem::exitCoordinate(void) const
{
    if (_points.count() > 0) {
        return const_cast<QmlObjectListModel*>(&_points)->value<SpotSprayingPoint*>(_points.count() - 1)->coordinate();
    }
    return QGeoCoordinate();
}

void SpotSprayingComplexItem::appendMissionItems(QList<MissionItem*>& items, QObject* missionItemParent)
{
    int seqNum = _sequenceNumber;
    for (int i=0; i<_points.count(); i++) {
        SpotSprayingPoint* p = _points.value<SpotSprayingPoint*>(i);
        
        // 1. Navigate to point
        MissionItem* item1 = new MissionItem(seqNum++,
                                             MAV_CMD_NAV_WAYPOINT,
                                             MAV_FRAME_GLOBAL_RELATIVE_ALT,
                                             0, // Hold time
                                             0, // Acceptance radius
                                             0, // Pass through
                                             0, // Yaw
                                             p->coordinate().latitude(),
                                             p->coordinate().longitude(),
                                             p->altitude(),
                                             true, // autoContinue
                                             false, // isCurrentItem
                                             missionItemParent);
        items.append(item1);
        
        if (p->spray()) {
            // 2. Turn ON sprayer (e.g., servo 9 to pwm)
            MissionItem* item2 = new MissionItem(seqNum++,
                                                 MAV_CMD_DO_SET_SERVO,
                                                 MAV_FRAME_MISSION,
                                                 9, // Servo number
                                                 p->pwm(), // PWM value
                                                 0, 0, 0, 0, 0,
                                                 true, false, missionItemParent);
            items.append(item2);
            
            // 3. Delay (hover time)
            MissionItem* item3 = new MissionItem(seqNum++,
                                                 MAV_CMD_NAV_DELAY,
                                                 MAV_FRAME_MISSION,
                                                 p->duration() * 60.0, // Delay in seconds (from minutes)
                                                 -1, // Hour
                                                 -1, // Minute
                                                 -1, // Second
                                                 0, 0, 0,
                                                 true, false, missionItemParent);
            items.append(item3);
            
            // 4. Turn OFF sprayer (servo 9 to 1000)
            MissionItem* item4 = new MissionItem(seqNum++,
                                                 MAV_CMD_DO_SET_SERVO,
                                                 MAV_FRAME_MISSION,
                                                 9,
                                                 1000,
                                                 0, 0, 0, 0, 0,
                                                 true, false, missionItemParent);
            items.append(item4);
        }
    }
}

void SpotSprayingComplexItem::setSequenceNumber(int sequenceNumber)
{
    if (_sequenceNumber != sequenceNumber) {
        _sequenceNumber = sequenceNumber;
        emit sequenceNumberChanged(sequenceNumber);
        emit lastSequenceNumberChanged(lastSequenceNumber());
    }
}

void SpotSprayingComplexItem::setDirty(bool dirty)
{
    if (_dirty != dirty) {
        _dirty = dirty;
        emit dirtyChanged(_dirty);
    }
}

void SpotSprayingComplexItem::applyNewAltitude(double newAltitude)
{
    for (int i=0; i<_points.count(); i++) {
        SpotSprayingPoint* p = _points.value<SpotSprayingPoint*>(i);
        p->setAltitude(newAltitude);
    }
}

VisualMissionItem::ReadyForSaveState SpotSprayingComplexItem::readyForSaveState(void) const
{
    return _points.count() > 0 ? ReadyForSave : NotReadyForSaveData;
}

void SpotSprayingComplexItem::save(QJsonArray& missionItems)
{
    QJsonObject complexObject;
    complexObject[VisualMissionItem::jsonTypeKey] = VisualMissionItem::jsonTypeComplexItemValue;
    complexObject[ComplexMissionItem::jsonComplexItemTypeKey] = name;
    
    QJsonArray pointsArray;
    for (int i=0; i<_points.count(); i++) {
        SpotSprayingPoint* p = const_cast<QmlObjectListModel*>(&_points)->value<SpotSprayingPoint*>(i);
        QJsonObject pointObj;
        QJsonValue coordVal;
        JsonHelper::saveGeoCoordinate(p->coordinate(), true, coordVal);
        pointObj["coordinate"] = coordVal;
        pointObj["altitude"] = p->altitude();
        pointObj["speed"] = p->speed();
        pointObj["pwm"] = p->pwm();
        pointObj["duration"] = p->duration();
        pointObj["spray"] = p->spray();
        pointsArray.append(pointObj);
    }
    complexObject["points"] = pointsArray;
    
    missionItems.append(complexObject);
}

bool SpotSprayingComplexItem::load(const QJsonObject& complexObject, int sequenceNumber, QString& errorString)
{
    _points.clearAndDeleteContents();
    setSequenceNumber(sequenceNumber);
    
    if (complexObject.contains("points") && complexObject["points"].isArray()) {
        QJsonArray pointsArray = complexObject["points"].toArray();
        for (const QJsonValue& pointVal : pointsArray) {
            QJsonObject pointObj = pointVal.toObject();
            QGeoCoordinate coord;
            if (pointObj.contains("coordinate") && JsonHelper::loadGeoCoordinate(pointObj["coordinate"], true, coord, errorString)) {
                SpotSprayingPoint* p = new SpotSprayingPoint(coord, this);
                _connectPoint(p);
                if (pointObj.contains("altitude")) p->setAltitude(pointObj["altitude"].toDouble());
                if (pointObj.contains("speed")) p->setSpeed(pointObj["speed"].toDouble());
                if (pointObj.contains("pwm")) p->setPwm(pointObj["pwm"].toDouble());
                if (pointObj.contains("duration")) p->setDuration(pointObj["duration"].toDouble());
                if (pointObj.contains("spray")) p->setSpray(pointObj["spray"].toBool());
                _points.append(p);
            }
        }
    }
    return true;
}
