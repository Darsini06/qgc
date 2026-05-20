#include "SpotSprayingComplexItem.h"
#include "JsonHelper.h"
#include "MissionController.h"
#include "PlanMasterController.h"
#include "QGCLoggingCategory.h"
#include "QGCApplication.h"
#include "ShapeFileHelper.h"
#include "KMLHelper.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include "MissionItem.h"
#include <QFile>
#include <QtXml/QDomDocument>
#include <QtXml/QDomNodeList>

const QString SpotSprayingComplexItem::name = SpotSprayingComplexItem::tr("Spot Spraying");

SpotSprayingPoint::SpotSprayingPoint(const QGeoCoordinate& coord, QObject* parent)
    : QObject(parent)
    , _coordinate(coord)
{
    if (coord.isValid() && !qIsNaN(coord.altitude())) {
        _altitude = coord.altitude();
    }
}

static void findNodesByTagName(const QDomNode& parentNode, const QString& targetTagName, QList<QDomElement>& matchingElements)
{
    QDomNodeList children = parentNode.childNodes();
    for (int i = 0; i < children.count(); i++) {
        QDomNode child = children.item(i);
        if (child.isElement()) {
            QDomElement el = child.toElement();
            QString tag = el.tagName();
            int colonIndex = tag.indexOf(':');
            if (colonIndex != -1) {
                tag = tag.mid(colonIndex + 1);
            }
            if (tag.compare(targetTagName, Qt::CaseInsensitive) == 0) {
                matchingElements.append(el);
            }
            findNodesByTagName(el, targetTagName, matchingElements);
        }
    }
}

static QDomElement findChildElement(const QDomElement& parentEl, const QString& targetTagName)
{
    QDomNodeList children = parentEl.childNodes();
    for (int i = 0; i < children.count(); i++) {
        QDomNode child = children.item(i);
        if (child.isElement()) {
            QDomElement el = child.toElement();
            QString tag = el.tagName();
            int colonIndex = tag.indexOf(':');
            if (colonIndex != -1) {
                tag = tag.mid(colonIndex + 1);
            }
            if (tag.compare(targetTagName, Qt::CaseInsensitive) == 0) {
                return el;
            }
        }
    }
    return QDomElement();
}

static QDomElement findDescendantElement(const QDomElement& parentEl, const QStringList& path)
{
    if (path.isEmpty()) return QDomElement();
    QDomElement current = findChildElement(parentEl, path[0]);
    for (int i = 1; i < path.count(); ++i) {
        if (current.isNull()) break;
        current = findChildElement(current, path[i]);
    }
    return current;
}

SpotSprayingComplexItem::SpotSprayingComplexItem(PlanMasterController* masterController, bool flyView, const QString& kmlOrShpFile, QObject* parent)
    : ComplexMissionItem(masterController, flyView)
    , _sequenceNumber(0)
    , _dirty(false)
{
    _points.setParent(this);
    _editorQml = "qrc:/qml/SpotSprayingEditor.qml";
    
    if (!kmlOrShpFile.isEmpty()) {
        QList<QGeoCoordinate> coords;
        
        QString loadError;
        QDomDocument doc = KMLHelper::_loadFile(kmlOrShpFile, loadError);
        if (loadError.isEmpty() && !doc.isNull()) {
            // 1. Try to load all Point coordinates
            QList<QDomElement> pointNodes;
            findNodesByTagName(doc, "Point", pointNodes);
            if (pointNodes.count() > 0) {
                for (const QDomElement& pointEl : pointNodes) {
                    QDomElement coordinatesNode = findChildElement(pointEl, "coordinates");
                    if (!coordinatesNode.isNull()) {
                        QString coordStr = coordinatesNode.text().simplified();
                        QStringList tuples = coordStr.split(" ", Qt::SkipEmptyParts);
                        for (const QString& tuple : tuples) {
                            QStringList parts = tuple.split(",");
                            if (parts.count() >= 2) {
                                QGeoCoordinate coord;
                                coord.setLongitude(parts[0].toDouble());
                                coord.setLatitude(parts[1].toDouble());
                                if (parts.count() >= 3) {
                                    coord.setAltitude(parts[2].toDouble());
                                }
                                coords.append(coord);
                            }
                        }
                    }
                }
            }
            
            // 2. If no points found, try Polygon outer boundary coordinates
            if (coords.isEmpty()) {
                QList<QDomElement> polyNodes;
                findNodesByTagName(doc, "Polygon", polyNodes);
                if (polyNodes.count() > 0) {
                    QDomElement coordinatesNode = findDescendantElement(polyNodes[0], QStringList() << "outerBoundaryIs" << "LinearRing" << "coordinates");
                    if (!coordinatesNode.isNull()) {
                        QString coordinatesString = coordinatesNode.text().simplified();
                        QStringList rgCoordinateStrings = coordinatesString.split(" ", Qt::SkipEmptyParts);
                        for (const QString& coordinateString : rgCoordinateStrings) {
                            QStringList rgValueStrings = coordinateString.split(",");
                            if (rgValueStrings.count() >= 2) {
                                QGeoCoordinate coord;
                                coord.setLongitude(rgValueStrings[0].toDouble());
                                coord.setLatitude(rgValueStrings[1].toDouble());
                                if (rgValueStrings.count() >= 3) {
                                    coord.setAltitude(rgValueStrings[2].toDouble());
                                }
                                coords.append(coord);
                            }
                        }
                    }
                }
            }

            // 3. If still empty, try LineString polyline coordinates
            if (coords.isEmpty()) {
                QList<QDomElement> lineNodes;
                findNodesByTagName(doc, "LineString", lineNodes);
                if (lineNodes.count() > 0) {
                    QDomElement coordinatesNode = findChildElement(lineNodes[0], "coordinates");
                    if (!coordinatesNode.isNull()) {
                        QString coordinatesString = coordinatesNode.text().simplified();
                        QStringList rgCoordinateStrings = coordinatesString.split(" ", Qt::SkipEmptyParts);
                        for (const QString& coordinateString : rgCoordinateStrings) {
                            QStringList rgValueStrings = coordinateString.split(",");
                            if (rgValueStrings.count() >= 2) {
                                QGeoCoordinate coord;
                                coord.setLongitude(rgValueStrings[0].toDouble());
                                coord.setLatitude(rgValueStrings[1].toDouble());
                                if (rgValueStrings.count() >= 3) {
                                    coord.setAltitude(rgValueStrings[2].toDouble());
                                }
                                coords.append(coord);
                            }
                        }
                    }
                }
            }
        }

        // Fallback to ShapeFileHelper if our direct XML parser didn't load any points (e.g. if it's a shapefile instead of KML)
        if (coords.isEmpty()) {
            QString errorString;
            ShapeFileHelper::loadPolygonFromFile(kmlOrShpFile, coords, errorString);
        }
        
        for (const QGeoCoordinate& coord : coords) {
            _points.append(new SpotSprayingPoint(coord, this));
        }
    }
    
    connect(&_points, &QmlObjectListModel::countChanged, this, &SpotSprayingComplexItem::_updatePoints);
}

SpotSprayingComplexItem::~SpotSprayingComplexItem()
{
    _points.clearAndDeleteContents();
}

QObject* SpotSprayingComplexItem::createPoint(const QGeoCoordinate& coord)
{
    SpotSprayingPoint* p = new SpotSprayingPoint(coord, this);
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
    // Each point uses 4 commands: NAV_WAYPOINT, SET_SERVO, NAV_DELAY, SET_SERVO
    return _sequenceNumber + (_points.count() * 4) - 1;
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

ComplexMissionItem::ReadyForSaveState SpotSprayingComplexItem::readyForSaveState(void) const
{
    return _points.count() > 0 ? ReadyForSave : NotReadyForSaveData;
}

void SpotSprayingComplexItem::save(QJsonArray& missionItems)
{
    QJsonObject complexObject;
    complexObject["version"] = 1;
    complexObject["type"] = name;
    
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
                if (pointObj.contains("altitude")) p->setAltitude(pointObj["altitude"].toDouble());
                if (pointObj.contains("speed")) p->setSpeed(pointObj["speed"].toDouble());
                if (pointObj.contains("pwm")) p->setPwm(pointObj["pwm"].toDouble());
                if (pointObj.contains("duration")) p->setDuration(pointObj["duration"].toDouble());
                _points.append(p);
            }
        }
    }
    return true;
}
