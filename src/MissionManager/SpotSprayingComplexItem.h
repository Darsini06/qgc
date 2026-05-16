#pragma once

#include "ComplexMissionItem.h"
#include "QmlObjectListModel.h"
#include "FactMetaData.h"
#include "SettingsFact.h"
#include <QMap>
#include <QGeoCoordinate>
#include <QObject>

class SpotSprayingPoint : public QObject
{
    Q_OBJECT
public:
    SpotSprayingPoint(const QGeoCoordinate& coord = QGeoCoordinate(), QObject* parent = nullptr);

    Q_PROPERTY(QGeoCoordinate coordinate READ coordinate WRITE setCoordinate NOTIFY coordinateChanged)
    Q_PROPERTY(double altitude READ altitude WRITE setAltitude NOTIFY altitudeChanged)
    Q_PROPERTY(double speed READ speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(double pwm READ pwm WRITE setPwm NOTIFY pwmChanged)
    Q_PROPERTY(double duration READ duration WRITE setDuration NOTIFY durationChanged)

    QGeoCoordinate coordinate() const { return _coordinate; }
    void setCoordinate(const QGeoCoordinate& coord) { if(_coordinate != coord) { _coordinate = coord; emit coordinateChanged(); } }

    double altitude() const { return _altitude; }
    void setAltitude(double v) { if(_altitude != v) { _altitude = v; emit altitudeChanged(); } }

    double speed() const { return _speed; }
    void setSpeed(double v) { if(_speed != v) { _speed = v; emit speedChanged(); } }

    double pwm() const { return _pwm; }
    void setPwm(double v) { if(_pwm != v) { _pwm = v; emit pwmChanged(); } }

    double duration() const { return _duration; }
    void setDuration(double v) { if(_duration != v) { _duration = v; emit durationChanged(); } }

signals:
    void coordinateChanged();
    void altitudeChanged();
    void speedChanged();
    void pwmChanged();
    void durationChanged();

private:
    QGeoCoordinate _coordinate;
    double _altitude = 50.0;
    double _speed = 5.0;
    double _pwm = 1500.0;
    double _duration = 0.1;
};

class SpotSprayingComplexItem : public ComplexMissionItem
{
    Q_OBJECT

public:
    SpotSprayingComplexItem(PlanMasterController* masterController, bool flyView, const QString& kmlOrShpFile = QString(), QObject* parent = nullptr);
    ~SpotSprayingComplexItem();
    
    Q_PROPERTY(QmlObjectListModel* points READ points CONSTANT)

    QmlObjectListModel* points() { return &_points; }
    
    Q_INVOKABLE QObject* createPoint(const QGeoCoordinate& coord);

    // Overrides from ComplexMissionItem
    QString             patternName         (void) const final { return name; }
    double              minAMSLAltitude     (void) const final { return 0.0; }
    double              maxAMSLAltitude     (void) const final { return 0.0; }
    double              complexDistance     (void) const final { return 0.0; }
    double              amslEntryAlt        (void) const final { return 0.0; }
    double              amslExitAlt         (void) const final { return 0.0; }
    void                setCoordinate       (const QGeoCoordinate& coord) final { Q_UNUSED(coord); }
    int                 lastSequenceNumber  (void) const final;
    bool                load                (const QJsonObject& complexObject, int sequenceNumber, QString& errorString) final;
    double              greatestDistanceTo  (const QGeoCoordinate &other) const final;
    QString             mapVisualQML        (void) const final { return QStringLiteral("SpotSprayingMapVisual.qml"); }
    QString             editorQML           (void) const { return QStringLiteral("SpotSprayingEditor.qml"); }
    bool                dirty               (void) const final { return _dirty; }
    bool                isSimpleItem        (void) const final { return false; }
    bool                isStandaloneCoordinate(void) const final { return false; }
    bool                specifiesCoordinate (void) const final { return true; }
    bool                specifiesAltitudeOnly(void) const final { return false; }
    QString             commandDescription  (void) const final { return tr("Spot Spraying"); }
    QString             commandName         (void) const final { return tr("Spot Spraying"); }
    QString             abbreviation        (void) const final { return tr("Spray"); }
    QGeoCoordinate      coordinate          (void) const final;
    QGeoCoordinate      exitCoordinate      (void) const final;
    int                 sequenceNumber      (void) const final { return _sequenceNumber; }
    double              specifiedFlightSpeed(void) final { return std::numeric_limits<double>::quiet_NaN(); }
    double              specifiedGimbalYaw  (void) final { return std::numeric_limits<double>::quiet_NaN(); }
    double              specifiedGimbalPitch(void) final { return std::numeric_limits<double>::quiet_NaN(); }
    void                appendMissionItems  (QList<MissionItem*>& items, QObject* missionItemParent) final;
    void                setSequenceNumber   (int sequenceNumber) final;
    bool                coordinateHasRelativeAltitude(void) const { return true; }
    bool                exitCoordinateHasRelativeAltitude(void) const { return true; }
    bool                exitCoordinateSameAsEntry(void) const final { return true; }
    void                setDirty            (bool dirty) final;
    void                applyNewAltitude    (double newAltitude) final;
    double              additionalTimeDelay (void) const final { return 0; }
    ReadyForSaveState   readyForSaveState   (void) const final;
    void                save                (QJsonArray&  missionItems) final;

    static const QString name;

private slots:
    void _updatePoints();

private:
    QMap<QString, FactMetaData*> _metaDataMap;
    int _sequenceNumber;
    bool _dirty;
    QmlObjectListModel _points;
};
