/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SurveyComplexItem.h"
#include "AppSettings.h"
#include "JsonHelper.h"
#include "MissionItem.h"
#include "PlanMasterController.h"
#include "QGCApplication.h"
#include "QGCGeo.h"
#include "QGCLoggingCategory.h"
#include "QGCMapPolygon.h"
#include "QGCQGeoCoordinate.h"
#include "SettingsManager.h"
#include "Vehicle.h"


#include "GeoFenceController.h"
#include "QGC.h"
#include "QGCFenceCircle.h"
#include "QGCFencePolygon.h"
#include <QtCore/QJsonArray>
#include <QtCore/QLineF>
#include <QtGui/QPolygonF>
#include <algorithm>


QGC_LOGGING_CATEGORY(SurveyComplexItemLog, "SurveyComplexItemLog")

const QString SurveyComplexItem::name(SurveyComplexItem::tr("Survey"));

SurveyComplexItem::SurveyComplexItem(PlanMasterController *masterController,
                                     bool flyView, const QString &kmlOrShpFile)
    : TransectStyleComplexItem(masterController, flyView, settingsGroup),
      _metaDataMap(FactMetaData::createMapFromJsonFile(
          QStringLiteral(":/json/Survey.SettingsGroup.json"), this)),
      _gridAngleFact(settingsGroup, _metaDataMap[gridAngleName]),
      _flyAlternateTransectsFact(settingsGroup,
                                 _metaDataMap[flyAlternateTransectsName]),
      _splitConcavePolygonsFact(settingsGroup,
                                _metaDataMap[splitConcavePolygonsName]),
      _entryPoint(EntryLocationTopLeft) {
  _editorQml = "qrc:/qml/SurveyItemEditor.qml";

  if (_controllerVehicle &&
      !(_controllerVehicle->fixedWing() || _controllerVehicle->vtol())) {
    // Only fixed wing flight paths support alternate transects
    _flyAlternateTransectsFact.setRawValue(false);
  }

  // We override the altitude to the mission default
  if (_cameraCalc.isManualCamera() ||
      !_cameraCalc.valueSetIsDistance()->rawValue().toBool()) {
    _cameraCalc.distanceToSurface()->setRawValue(
        qgcApp()
            ->toolbox()
            ->settingsManager()
            ->appSettings()
            ->defaultMissionItemAltitude()
            ->rawValue());
  }

  connect(&_gridAngleFact, &Fact::valueChanged, this,
          &SurveyComplexItem::_setDirty);
  connect(&_flyAlternateTransectsFact, &Fact::valueChanged, this,
          &SurveyComplexItem::_setDirty);
  connect(&_splitConcavePolygonsFact, &Fact::valueChanged, this,
          &SurveyComplexItem::_setDirty);
  connect(this, &SurveyComplexItem::refly90DegreesChanged, this,
          &SurveyComplexItem::_setDirty);

  connect(&_gridAngleFact, &Fact::valueChanged, this,
          &SurveyComplexItem::_rebuildTransects);
  connect(&_flyAlternateTransectsFact, &Fact::valueChanged, this,
          &SurveyComplexItem::_rebuildTransects);
  connect(&_splitConcavePolygonsFact, &Fact::valueChanged, this,
          &SurveyComplexItem::_rebuildTransects);
  connect(this, &SurveyComplexItem::refly90DegreesChanged, this,
          &SurveyComplexItem::_rebuildTransects);

  connect(&_surveyAreaPolygon, &QGCMapPolygon::isValidChanged, this,
          &SurveyComplexItem::_updateWizardMode);
  connect(&_surveyAreaPolygon, &QGCMapPolygon::traceModeChanged, this,
          &SurveyComplexItem::_updateWizardMode);

  if (!kmlOrShpFile.isEmpty()) {
    _surveyAreaPolygon.loadKMLOrSHPFile(kmlOrShpFile);
    _surveyAreaPolygon.setDirty(false);
  }

  // Sync initial indentation values
  _entryIndentation = _turnAroundDistance();
  _exitIndentation = _turnAroundDistance();

  connect(&_turnAroundDistanceFact, &Fact::valueChanged, this,
          [this](QVariant value) {
            double dist = value.toDouble();
            if (_adjustmentMode == 0) {
              _entryIndentation = dist;
              _exitIndentation = dist;
              emit entryIndentationChanged(dist);
              emit exitIndentationChanged(dist);
            } else if (_adjustmentMode == 1) {
              _entryIndentation = dist;
              emit entryIndentationChanged(dist);
            } else if (_adjustmentMode == 2) {
              _exitIndentation = dist;
              emit exitIndentationChanged(dist);
            }
          });

  if (_masterController && _masterController->geoFenceController()) {
    GeoFenceController *fenceController =
        _masterController->geoFenceController();
    connect(fenceController->polygons(), &QmlObjectListModel::countChanged,
            this, &SurveyComplexItem::_rebuildTransects);
    connect(fenceController->circles(), &QmlObjectListModel::countChanged, this,
            &SurveyComplexItem::_rebuildTransects);
    connect(fenceController, &GeoFenceController::dirtyChanged, this,
            &SurveyComplexItem::_rebuildTransects);
  }

  setDirty(false);
}

void SurveyComplexItem::save(QJsonArray &planItems) {
  QJsonObject saveObject;

  _saveCommon(saveObject);
  planItems.append(saveObject);
}

void SurveyComplexItem::savePreset(const QString &name) {
  QJsonObject saveObject;

  _saveCommon(saveObject);
  _savePresetJson(name, saveObject);
}

void SurveyComplexItem::_saveCommon(QJsonObject &saveObject) {
  TransectStyleComplexItem::_save(saveObject);

  saveObject[JsonHelper::jsonVersionKey] = 5;
  saveObject[VisualMissionItem::jsonTypeKey] =
      VisualMissionItem::jsonTypeComplexItemValue;
  saveObject[ComplexMissionItem::jsonComplexItemTypeKey] =
      jsonComplexItemTypeValue;
  saveObject[_jsonGridAngleKey] = _gridAngleFact.rawValue().toDouble();
  saveObject[_jsonFlyAlternateTransectsKey] =
      _flyAlternateTransectsFact.rawValue().toBool();
  saveObject[_jsonSplitConcavePolygonsKey] =
      _splitConcavePolygonsFact.rawValue().toBool();
  saveObject[_jsonEntryPointKey] = _entryPoint;

  // Save local obstacles
  if (!_localExclusionPolygons.isEmpty()) {
    QJsonArray obsArray;
    for (const QPolygonF &poly : _localExclusionPolygons) {
      QJsonObject obsObj;
      obsObj[_jsonLocalObstacleTypeKey] = _jsonLocalObstaclePolygonValue;
      QJsonArray pts;
      for (int i = 0; i < poly.count() - 1; i++) { // Don't save closed point
        QJsonArray pt;
        pt << poly[i].x() << poly[i].y();
        pts.append(pt);
      }
      obsObj[QGCMapPolygon::jsonPolygonKey] = pts;
      obsArray.append(obsObj);
    }
    saveObject[_jsonLocalObstaclesKey] = obsArray;
  }

  // Polygon shape
  _surveyAreaPolygon.saveToJson(saveObject);
}

void SurveyComplexItem::setEntryIndentation(double val) {
  if (!QGC::fuzzyCompare(_entryIndentation, val)) {
    _entryIndentation = val;
    emit entryIndentationChanged(val);
    _rebuildTransects();
  }
}
void SurveyComplexItem::setExitIndentation(double val) {
  if (!QGC::fuzzyCompare(_exitIndentation, val)) {
    _exitIndentation = val;
    emit exitIndentationChanged(val);
    _rebuildTransects();
  }
}
void SurveyComplexItem::setAdjustmentMode(int mode) {
  if (_adjustmentMode != mode) {
    _adjustmentMode = mode;
    emit adjustmentModeChanged(mode);
    if (mode == 1)
      _turnAroundDistanceFact.setRawValue(_entryIndentation);
    else if (mode == 2)
      _turnAroundDistanceFact.setRawValue(_exitIndentation);
  }
}

void SurveyComplexItem::loadPreset(const QString &name) {
  QString errorString;

  QJsonObject presetObject = _loadPresetJson(name);
  if (!_loadV4V5(presetObject, 0, errorString, 5, true /* forPresets */)) {
    qgcApp()->showAppMessage(
        QStringLiteral("Internal Error: Preset load failed. Name: %1 Error: %2")
            .arg(name)
            .arg(errorString));
  }
  _rebuildTransects();
}

void SurveyComplexItem::setMapPolygon(QGCMapPolygon *mapPolygon) {
  qCDebug(SurveyComplexItemLog) << "setMapPolygon" << mapPolygon;
  if (_mapPolygon != mapPolygon) {
    if (_mapPolygon) {
      disconnect(_mapPolygon, &QGCMapPolygon::pathChanged, this,
                 &SurveyComplexItem::_rebuildTransects);
    }
    _mapPolygon = mapPolygon;
    if (_mapPolygon) {
      connect(_mapPolygon, &QGCMapPolygon::pathChanged, this,
              &SurveyComplexItem::_rebuildTransects);
      connect(_mapPolygon, &QGCMapPolygon::centerChanged, this,
              &SurveyComplexItem::_rebuildTransects);
    }
    emit mapPolygonChanged();
    _rebuildTransects();
  }
}

bool SurveyComplexItem::load(const QJsonObject &complexObject,
                             int sequenceNumber, QString &errorString) {
  // We need to pull version first to determine what validation/conversion needs
  // to be performed
  QList<JsonHelper::KeyValidateInfo> versionKeyInfoList = {
      {JsonHelper::jsonVersionKey, QJsonValue::Double, true},
  };
  if (!JsonHelper::validateKeys(complexObject, versionKeyInfoList,
                                errorString)) {
    return false;
  }

  int version = complexObject[JsonHelper::jsonVersionKey].toInt();
  if (version < 2 || version > 5) {
    errorString = tr("Survey items do not support version %1").arg(version);
    return false;
  }

  if (version == 4 || version == 5) {
    if (!_loadV4V5(complexObject, sequenceNumber, errorString, version,
                   false /* forPresets */)) {
      return false;
    }

    _recalcComplexDistance();
    if (_cameraShots == 0) {
      // Shot count was possibly not available from plan file
      _recalcCameraShots();
    }
  } else {
    // Must be v2 or v3
    QJsonObject v3ComplexObject = complexObject;
    if (version == 2) {
      // Convert to v3
      if (v3ComplexObject.contains(VisualMissionItem::jsonTypeKey) &&
          v3ComplexObject[VisualMissionItem::jsonTypeKey].toString() ==
              QStringLiteral("survey")) {
        v3ComplexObject[VisualMissionItem::jsonTypeKey] =
            VisualMissionItem::jsonTypeComplexItemValue;
        v3ComplexObject[ComplexMissionItem::jsonComplexItemTypeKey] =
            jsonComplexItemTypeValue;
      }
    }
    if (!_loadV3(complexObject, sequenceNumber, errorString)) {
      return false;
    }

    // V2/3 doesn't include individual items so we need to rebuild manually
    _rebuildTransects();
  }

  return true;
}

bool SurveyComplexItem::_loadV4V5(const QJsonObject &complexObject,
                                  int sequenceNumber, QString &errorString,
                                  int version, bool forPresets) {
  QList<JsonHelper::KeyValidateInfo> keyInfoList = {
      {VisualMissionItem::jsonTypeKey, QJsonValue::String, true},
      {ComplexMissionItem::jsonComplexItemTypeKey, QJsonValue::String, true},
      {_jsonEntryPointKey, QJsonValue::Double, true},
      {_jsonGridAngleKey, QJsonValue::Double, true},
      {_jsonFlyAlternateTransectsKey, QJsonValue::Bool, false},
  };

  if (version == 5) {
    JsonHelper::KeyValidateInfo jSplitPolygon = {_jsonSplitConcavePolygonsKey,
                                                 QJsonValue::Bool, true};
    keyInfoList.append(jSplitPolygon);
  }

  if (!JsonHelper::validateKeys(complexObject, keyInfoList, errorString)) {
    return false;
  }

  QString itemType = complexObject[VisualMissionItem::jsonTypeKey].toString();
  QString complexType =
      complexObject[ComplexMissionItem::jsonComplexItemTypeKey].toString();
  if (itemType != VisualMissionItem::jsonTypeComplexItemValue ||
      complexType != jsonComplexItemTypeValue) {
    errorString =
        tr("%1 does not support loading this complex mission item type: %2:%3")
            .arg(qgcApp()->applicationName())
            .arg(itemType)
            .arg(complexType);
    return false;
  }

  _ignoreRecalc = !forPresets;

  if (!forPresets) {
    setSequenceNumber(sequenceNumber);

    if (!_surveyAreaPolygon.loadFromJson(complexObject, true /* required */,
                                         errorString)) {
      _surveyAreaPolygon.clear();
      return false;
    }
  }

  if (!TransectStyleComplexItem::_load(complexObject, forPresets,
                                       errorString)) {
    _ignoreRecalc = false;
    return false;
  }

  _gridAngleFact.setRawValue(complexObject[_jsonGridAngleKey].toDouble());
  _flyAlternateTransectsFact.setRawValue(
      complexObject[_jsonFlyAlternateTransectsKey].toBool(false));

  if (version == 5) {
    _splitConcavePolygonsFact.setRawValue(
        complexObject[_jsonSplitConcavePolygonsKey].toBool(true));
  }

  _entryPoint = complexObject[_jsonEntryPointKey].toInt();

  // Load local obstacles
  _localExclusionPolygons.clear();
  if (complexObject.contains(_jsonLocalObstaclesKey)) {
    QJsonArray obsArray = complexObject[_jsonLocalObstaclesKey].toArray();
    for (int i = 0; i < obsArray.count(); i++) {
      QJsonObject obsObj = obsArray[i].toObject();
      QString type = obsObj[_jsonLocalObstacleTypeKey].toString();
      QPolygonF poly;
      if (type == _jsonLocalObstaclePolygonValue) {
        QJsonArray pts = obsObj[QGCMapPolygon::jsonPolygonKey].toArray();
        for (int j = 0; j < pts.count(); j++) {
          QJsonArray pt = pts[j].toArray();
          poly << QPointF(pt[0].toDouble(), pt[1].toDouble());
        }
      } else if (type == _jsonLocalObstacleCircleValue) {
        QPointF center(obsObj["x"].toDouble(), obsObj["y"].toDouble());
        double radius = obsObj["radius"].toDouble();
        for (int j = 0; j < 36; j++) {
          double angle = (360.0 / 36.0) * j * M_PI / 180.0;
          poly << center + QPointF(cos(angle) * radius, sin(angle) * radius);
        }
      }
      if (poly.count() >= 3) {
        if (poly.front() != poly.back())
          poly << poly.front();
        _localExclusionPolygons.append(poly);
      }
    }
  }

  _ignoreRecalc = false;

  return true;
}

bool SurveyComplexItem::_loadV3(const QJsonObject &complexObject,
                                int sequenceNumber, QString &errorString) {
  QList<JsonHelper::KeyValidateInfo> mainKeyInfoList = {
      {VisualMissionItem::jsonTypeKey, QJsonValue::String, true},
      {ComplexMissionItem::jsonComplexItemTypeKey, QJsonValue::String, true},
      {QGCMapPolygon::jsonPolygonKey, QJsonValue::Array, true},
      {_jsonV3GridObjectKey, QJsonValue::Object, true},
      {_jsonV3CameraObjectKey, QJsonValue::Object, false},
      {_jsonV3CameraTriggerDistanceKey, QJsonValue::Double, true},
      {_jsonV3ManualGridKey, QJsonValue::Bool, true},
      {_jsonV3FixedValueIsAltitudeKey, QJsonValue::Bool, true},
      {_jsonV3HoverAndCaptureKey, QJsonValue::Bool, false},
      {_jsonV3Refly90DegreesKey, QJsonValue::Bool, false},
      {_jsonV3CameraTriggerInTurnaroundKey, QJsonValue::Bool,
       false}, // Should really be required, but it was missing from initial
               // code due to bug
  };
  if (!JsonHelper::validateKeys(complexObject, mainKeyInfoList, errorString)) {
    return false;
  }

  QString itemType = complexObject[VisualMissionItem::jsonTypeKey].toString();
  QString complexType =
      complexObject[ComplexMissionItem::jsonComplexItemTypeKey].toString();
  if (itemType != VisualMissionItem::jsonTypeComplexItemValue ||
      complexType != jsonV3ComplexItemTypeValue) {
    errorString =
        tr("%1 does not support loading this complex mission item type: %2:%3")
            .arg(qgcApp()->applicationName())
            .arg(itemType)
            .arg(complexType);
    return false;
  }

  _ignoreRecalc = true;

  setSequenceNumber(sequenceNumber);

  _hoverAndCaptureFact.setRawValue(
      complexObject[_jsonV3HoverAndCaptureKey].toBool(false));
  _refly90DegreesFact.setRawValue(
      complexObject[_jsonV3Refly90DegreesKey].toBool(false));
  _cameraTriggerInTurnAroundFact.setRawValue(
      complexObject[_jsonV3CameraTriggerInTurnaroundKey].toBool(true));

  _cameraCalc.valueSetIsDistance()->setRawValue(
      complexObject[_jsonV3FixedValueIsAltitudeKey].toBool(true));
  _cameraCalc.setDistanceMode(
      complexObject[_jsonV3GridAltitudeRelativeKey].toBool(true)
          ? QGroundControlQmlGlobal::AltitudeModeRelative
          : QGroundControlQmlGlobal::AltitudeModeAbsolute);

  bool manualGrid = complexObject[_jsonV3ManualGridKey].toBool(true);

  QList<JsonHelper::KeyValidateInfo> gridKeyInfoList = {
      {_jsonV3GridAltitudeKey, QJsonValue::Double, true},
      {_jsonV3GridAltitudeRelativeKey, QJsonValue::Bool, true},
      {_jsonV3GridAngleKey, QJsonValue::Double, true},
      {_jsonV3GridSpacingKey, QJsonValue::Double, true},
      {_jsonEntryPointKey, QJsonValue::Double, false},
      {_jsonV3TurnaroundDistKey, QJsonValue::Double, true},
  };
  QJsonObject gridObject = complexObject[_jsonV3GridObjectKey].toObject();
  if (!JsonHelper::validateKeys(gridObject, gridKeyInfoList, errorString)) {
    _ignoreRecalc = false;
    return false;
  }

  _gridAngleFact.setRawValue(gridObject[_jsonV3GridAngleKey].toDouble());

  //_turnAroundDistanceFact.setRawValue
  //(gridObject[_jsonV3TurnaroundDistKey].toDouble());
  _turnAroundDistanceFact.setRawValue(0.0);

  if (gridObject.contains(_jsonEntryPointKey)) {
    _entryPoint = gridObject[_jsonEntryPointKey].toInt();
  } else {
    _entryPoint = EntryLocationTopRight;
  }

  _cameraCalc.distanceToSurface()->setRawValue(
      gridObject[_jsonV3GridAltitudeKey].toDouble());
  _cameraCalc.adjustedFootprintSide()->setRawValue(
      gridObject[_jsonV3GridSpacingKey].toDouble());
  _cameraCalc.adjustedFootprintFrontal()->setRawValue(
      complexObject[_jsonV3CameraTriggerDistanceKey].toDouble());

  if (manualGrid) {
    _cameraCalc.setCameraBrand(CameraCalc::canonicalManualCameraName());
  } else {
    if (!complexObject.contains(_jsonV3CameraObjectKey)) {
      errorString = tr("%1 but %2 object is missing")
                        .arg("manualGrid = false")
                        .arg("camera");
      _ignoreRecalc = false;
      return false;
    }

    QJsonObject cameraObject = complexObject[_jsonV3CameraObjectKey].toObject();

    // Older code had typo on "imageSideOverlap" incorrectly being
    // "imageSizeOverlap"
    QString incorrectImageSideOverlap = "imageSizeOverlap";
    if (cameraObject.contains(incorrectImageSideOverlap)) {
      cameraObject[_jsonV3SideOverlapKey] =
          cameraObject[incorrectImageSideOverlap];
      cameraObject.remove(incorrectImageSideOverlap);
    }

    QList<JsonHelper::KeyValidateInfo> cameraKeyInfoList = {
        {_jsonV3GroundResolutionKey, QJsonValue::Double, true},
        {_jsonV3FrontalOverlapKey, QJsonValue::Double, true},
        {_jsonV3SideOverlapKey, QJsonValue::Double, true},
        {_jsonV3CameraSensorWidthKey, QJsonValue::Double, true},
        {_jsonV3CameraSensorHeightKey, QJsonValue::Double, true},
        {_jsonV3CameraResolutionWidthKey, QJsonValue::Double, true},
        {_jsonV3CameraResolutionHeightKey, QJsonValue::Double, true},
        {_jsonV3CameraFocalLengthKey, QJsonValue::Double, true},
        {_jsonV3CameraNameKey, QJsonValue::String, true},
        {_jsonV3CameraOrientationLandscapeKey, QJsonValue::Bool, true},
        {_jsonV3CameraMinTriggerIntervalKey, QJsonValue::Double, false},
    };
    if (!JsonHelper::validateKeys(cameraObject, cameraKeyInfoList,
                                  errorString)) {
      _ignoreRecalc = false;
      return false;
    }

    _cameraCalc.landscape()->setRawValue(
        cameraObject[_jsonV3CameraOrientationLandscapeKey].toBool(true));
    _cameraCalc.frontalOverlap()->setRawValue(
        cameraObject[_jsonV3FrontalOverlapKey].toInt());
    _cameraCalc.sideOverlap()->setRawValue(
        cameraObject[_jsonV3SideOverlapKey].toInt());
    _cameraCalc.sensorWidth()->setRawValue(
        cameraObject[_jsonV3CameraSensorWidthKey].toDouble());
    _cameraCalc.sensorHeight()->setRawValue(
        cameraObject[_jsonV3CameraSensorHeightKey].toDouble());
    _cameraCalc.focalLength()->setRawValue(
        cameraObject[_jsonV3CameraFocalLengthKey].toDouble());
    _cameraCalc.imageWidth()->setRawValue(
        cameraObject[_jsonV3CameraResolutionWidthKey].toInt());
    _cameraCalc.imageHeight()->setRawValue(
        cameraObject[_jsonV3CameraResolutionHeightKey].toInt());
    _cameraCalc.minTriggerInterval()->setRawValue(
        cameraObject[_jsonV3CameraMinTriggerIntervalKey].toDouble(0));
    _cameraCalc.imageDensity()->setRawValue(
        cameraObject[_jsonV3GroundResolutionKey].toDouble());
    _cameraCalc.fixedOrientation()->setRawValue(false);
    _cameraCalc._setCameraNameFromV3TransectLoad(
        cameraObject[_jsonV3CameraNameKey].toString());
  }

  // Polygon shape
  /// Load a polygon from json
  ///     @param json Json object to load from
  ///     @param required true: no polygon in object will generate error
  ///     @param errorString Error string if return is false
  /// @return true: success, false: failure (errorString set)
  if (!_surveyAreaPolygon.loadFromJson(complexObject, true /* required */,
                                       errorString)) {
    _surveyAreaPolygon.clear();
    _ignoreRecalc = false;
    return false;
  }

  _ignoreRecalc = false;

  return true;
}

/// Reverse the order of the transects. First transect becomes last and so
/// forth.
void SurveyComplexItem::_reverseTransectOrder(
    QList<QList<QGeoCoordinate>> &transects) {
  QList<QList<QGeoCoordinate>> rgReversedTransects;
  for (int i = transects.count() - 1; i >= 0; i--) {
    rgReversedTransects.append(transects[i]);
  }
  transects = rgReversedTransects;
}

/// Reverse the order of all points withing each transect, First point becomes
/// last and so forth.
void SurveyComplexItem::_reverseInternalTransectPoints(
    QList<QList<QGeoCoordinate>> &transects) {
  for (int i = 0; i < transects.count(); i++) {
    QList<QGeoCoordinate> rgReversedCoords;
    QList<QGeoCoordinate> &rgOriginalCoords = transects[i];
    for (int j = rgOriginalCoords.count() - 1; j >= 0; j--) {
      rgReversedCoords.append(rgOriginalCoords[j]);
    }
    transects[i] = rgReversedCoords;
  }
}

/// Reorders the transects such that the first transect is the shortest distance
/// to the specified coordinate and the first point within that transect is the
/// shortest distance to the specified coordinate.
///     @param distanceCoord Coordinate to measure distance against
///     @param transects Transects to test and reorder
void SurveyComplexItem::_optimizeTransectsForShortestDistance(
    const QGeoCoordinate &distanceCoord,
    QList<QList<QGeoCoordinate>> &transects) {
  double rgTransectDistance[4];
  rgTransectDistance[0] = transects.first().first().distanceTo(distanceCoord);
  rgTransectDistance[1] = transects.first().last().distanceTo(distanceCoord);
  rgTransectDistance[2] = transects.last().first().distanceTo(distanceCoord);
  rgTransectDistance[3] = transects.last().last().distanceTo(distanceCoord);

  int shortestIndex = 0;
  double shortestDistance = rgTransectDistance[0];
  for (int i = 1; i < 3; i++) {
    if (rgTransectDistance[i] < shortestDistance) {
      shortestIndex = i;
      shortestDistance = rgTransectDistance[i];
    }
  }

  if (shortestIndex > 1) {
    // We need to reverse the order of segments
    _reverseTransectOrder(transects);
  }
  if (shortestIndex & 1) {
    // We need to reverse the points within each segment
    _reverseInternalTransectPoints(transects);
  }
}

qreal SurveyComplexItem::_ccw(QPointF pt1, QPointF pt2, QPointF pt3) {
  return (pt2.x() - pt1.x()) * (pt3.y() - pt1.y()) -
         (pt2.y() - pt1.y()) * (pt3.x() - pt1.x());
}

qreal SurveyComplexItem::_dp(QPointF pt1, QPointF pt2) {
  return (pt2.x() - pt1.x()) / qSqrt((pt2.x() - pt1.x()) * (pt2.x() - pt1.x()) +
                                     (pt2.y() - pt1.y()) * (pt2.y() - pt1.y()));
}

void SurveyComplexItem::_swapPoints(QList<QPointF> &points, int index1,
                                    int index2) {
  QPointF temp = points[index1];
  points[index1] = points[index2];
  points[index2] = temp;
}

/// Returns true if the current grid angle generates north/south oriented
/// transects
bool SurveyComplexItem::_gridAngleIsNorthSouthTransects() {
  // Grid angle ranges from -360<->360
  double gridAngle = qAbs(_gridAngleFact.rawValue().toDouble());
  return gridAngle < 45.0 || (gridAngle > 360.0 - 45.0) ||
         (gridAngle > 90.0 + 45.0 && gridAngle < 270.0 - 45.0);
}

void SurveyComplexItem::_adjustTransectsToEntryPointLocation(
    QList<QList<QGeoCoordinate>> &transects) {
  if (transects.count() == 0) {
    return;
  }

  bool reversePoints = false;
  bool reverseTransects = false;

  if (_entryPoint == EntryLocationBottomLeft ||
      _entryPoint == EntryLocationBottomRight) {
    reversePoints = true;
  }
  if (_entryPoint == EntryLocationTopRight ||
      _entryPoint == EntryLocationBottomRight) {
    reverseTransects = true;
  }

  if (reversePoints) {
    qCDebug(SurveyComplexItemLog)
        << "_adjustTransectsToEntryPointLocation Reverse Points";
    _reverseInternalTransectPoints(transects);
  }
  if (reverseTransects) {
    qCDebug(SurveyComplexItemLog)
        << "_adjustTransectsToEntryPointLocation Reverse Transects";
    _reverseTransectOrder(transects);
  }

  qCDebug(SurveyComplexItemLog) << "_adjustTransectsToEntryPointLocation "
                                   "Modified entry point:entryLocation"
                                << transects.first().first() << _entryPoint;
}

QPointF SurveyComplexItem::_rotatePoint(const QPointF &point,
                                        const QPointF &origin, double angle) {
  QPointF rotated;
  double radians = (M_PI / 180.0) * -angle;

  rotated.setX(((point.x() - origin.x()) * cos(radians)) -
               ((point.y() - origin.y()) * sin(radians)) + origin.x());
  rotated.setY(((point.x() - origin.x()) * sin(radians)) +
               ((point.y() - origin.y()) * cos(radians)) + origin.y());

  return rotated;
}

void SurveyComplexItem::_intersectLinesWithRect(const QList<QLineF> &lineList,
                                                const QRectF &boundRect,
                                                QList<QLineF> &resultLines) {
  QLineF topLine(boundRect.topLeft(), boundRect.topRight());
  QLineF bottomLine(boundRect.bottomLeft(), boundRect.bottomRight());
  QLineF leftLine(boundRect.topLeft(), boundRect.bottomLeft());
  QLineF rightLine(boundRect.topRight(), boundRect.bottomRight());

  for (int i = 0; i < lineList.count(); i++) {
    QPointF intersectPoint;
    QLineF intersectLine;
    const QLineF &line = lineList[i];

    auto isLineBoundedIntersect =
        [&line, &intersectPoint](const QLineF &linePosition) {
          return line.intersects(linePosition, &intersectPoint) ==
                 QLineF::BoundedIntersection;
        };

    int foundCount = 0;
    if (isLineBoundedIntersect(topLine)) {
      intersectLine.setP1(intersectPoint);
      foundCount++;
    }
    if (isLineBoundedIntersect(rightLine)) {
      if (foundCount == 0) {
        intersectLine.setP1(intersectPoint);
      } else {
        if (foundCount != 1) {
          qWarning() << "Found more than two intersecting points";
        }
        intersectLine.setP2(intersectPoint);
      }
      foundCount++;
    }
    if (isLineBoundedIntersect(bottomLine)) {
      if (foundCount == 0) {
        intersectLine.setP1(intersectPoint);
      } else {
        if (foundCount != 1) {
          qWarning() << "Found more than two intersecting points";
        }
        intersectLine.setP2(intersectPoint);
      }
      foundCount++;
    }
    if (isLineBoundedIntersect(leftLine)) {
      if (foundCount == 0) {
        intersectLine.setP1(intersectPoint);
      } else {
        if (foundCount != 1) {
          qWarning() << "Found more than two intersecting points";
        }
        intersectLine.setP2(intersectPoint);
      }
      foundCount++;
    }

    if (foundCount == 2) {
      resultLines += intersectLine;
    }
  }
}

double SurveyComplexItem::_distanceToSegment(const QPointF &p, const QLineF &line) {
  double l2 = line.length() * line.length();
  if (l2 == 0.0)
    return QLineF(p, line.p1()).length();
  double t = qMax(
      0.0, qMin(1.0, QPointF::dotProduct(p - line.p1(), line.p2() - line.p1()) /
                        l2));
  QPointF projection = line.p1() + t * (line.p2() - line.p1());
  return QLineF(p, projection).length();
}

QList<QPointF> SurveyComplexItem::_getBoundaryPath(const QPolygonF &poly,
                                                   const QPointF &p1,
                                                   const QPointF &p2) {
  if (poly.count() < 3)
    return {p1, p2};

  int i1 = -1, i2 = -1;
  double minD1 = 1e9, minD2 = 1e9;
  for (int i = 0; i < poly.count() - 1; ++i) {
    double d1 = _distanceToSegment(p1, QLineF(poly[i], poly[i + 1]));
    if (d1 < minD1) {
      minD1 = d1;
      i1 = i;
    }
    double d2 = _distanceToSegment(p2, QLineF(poly[i], poly[i + 1]));
    if (d2 < minD2) {
      minD2 = d2;
      i2 = i;
    }
  }

  // If points are on the same edge, detour is not needed unless it's deep inside
  if (i1 == i2 && minD1 < 0.1 && minD2 < 0.1) {
      return {p1, p2};
  }

  if (i1 == -1 || i2 == -1)
    return {p1, p2};

  auto getPath = [&](bool forward) {
    QList<QPointF> path;
    path << p1;
    int curr = i1;
    if (forward) {
      int next = (curr + 1) % (poly.count() - 1);
      while (curr != i2) {
        QPointF vertex = poly[next];
        // Apply a small outward buffer (0.5m)
        QPointF prevPt = poly[curr];
        int nextNext = (next + 1) % (poly.count() - 1);
        QPointF nextPt = poly[nextNext];
        
        QLineF l1(prevPt, vertex);
        QLineF l2(vertex, nextPt);
        QPointF normal = (l1.normalVector().unitVector().p2() - l1.normalVector().unitVector().p1()) +
                         (l2.normalVector().unitVector().p2() - l2.normalVector().unitVector().p1());
        // Note: sum of normals might need normalization and scale
        double normLen = sqrt(normal.x()*normal.x() + normal.y()*normal.y());
        if (normLen > 0.1) {
            vertex += (normal / normLen) * 0.5; // 0.5 meter buffer
        }

        path << vertex;
        curr = next;
        next = nextNext;
      }
    } else {
      while (curr != i2) {
        QPointF vertex = poly[curr];
        // Apply a small outward buffer (0.5m)
        int prev = (curr + 1) % (poly.count() - 1);
        int nextIdx = (curr - 1 + poly.count() - 1) % (poly.count() - 1);
        QPointF prevPt = poly[prev];
        QPointF nextPt = poly[nextIdx];
        
        QLineF l1(prevPt, vertex);
        QLineF l2(vertex, nextPt);
        QPointF normal = (l1.normalVector().unitVector().p2() - l1.normalVector().unitVector().p1()) +
                         (l2.normalVector().unitVector().p2() - l2.normalVector().unitVector().p1());
        double normLen = sqrt(normal.x()*normal.x() + normal.y()*normal.y());
        if (normLen > 0.1) {
            vertex += (normal / normLen) * 0.5; // 0.5 meter buffer
        }

        path << vertex;
        curr = nextIdx;
      }
    }
    path << p2;
    return path;
  };

  QList<QPointF> pathF = getPath(true);
  QList<QPointF> pathB = getPath(false);

  auto pathLen = [](const QList<QPointF> &p) {
    double len = 0;
    for (int i = 0; i < p.count() - 1; ++i)
      len += QLineF(p[i], p[i + 1]).length();
    return len;
  };

  return (pathLen(pathF) < pathLen(pathB)) ? pathF : pathB;
}

void SurveyComplexItem::_intersectLinesWithPolygon(
    const QList<QLineF> &lineList, const QPolygonF &polygon,
    const QList<QPolygonF> &exclusionPolygons,
    QList<QList<QPointF>> &resultPolylines) {
  resultPolylines.clear();

  for (int i = 0; i < lineList.count(); i++) {
    const QLineF &line = lineList[i];
    QList<QPointF> intersections;

    // Helper to add intersections safely
    auto addIntersections = [&](const QPolygonF &poly) {
      if (poly.count() < 3)
        return;
      for (int j = 0; j < poly.count() - 1; j++) {
        QPointF intersectPoint;
        QLineF edge(poly[j], poly[j + 1]);
        if (line.intersects(edge, &intersectPoint) ==
            QLineF::BoundedIntersection) {
          if (!intersections.contains(intersectPoint)) {
            intersections.append(intersectPoint);
          }
        }
      }
    };

    // Intersect with main polygon
    addIntersections(polygon);
    // Intersect with exclusion polygons
    for (const QPolygonF &excl : exclusionPolygons) {
      addIntersections(excl);
    }

    if (intersections.count() < 2)
      continue;

    // Sort intersections along the line (from P1 to P2)
    std::sort(intersections.begin(), intersections.end(),
              [&](const QPointF &a, const QPointF &b) {
                return QLineF(line.p1(), a).length() <
                       QLineF(line.p1(), b).length();
              });

    QList<QPointF> currentPolyline;
    // Check each segment between consecutive intersection points
    for (int j = 0; j < intersections.count() - 1; j++) {
      QPointF p1 = intersections[j];
      QPointF p2 = intersections[j + 1];
      
      // Use multiple points to check for exclusion to be more robust
      QPointF mid = (p1 + p2) / 2.0;
      QPointF p1_eps = p1 + (p2 - p1) * 0.01;
      QPointF p2_eps = p2 + (p1 - p2) * 0.01;

      // Segment is valid if midpoint is inside main polygon...
      bool insideMain = polygon.containsPoint(mid, Qt::WindingFill) || 
                        polygon.containsPoint(p1_eps, Qt::WindingFill) ||
                        polygon.containsPoint(p2_eps, Qt::WindingFill);
      
      if (insideMain) {
        // ...and NOT inside any exclusion polygon
        bool insideExclusion = false;
        const QPolygonF *targetExcl = nullptr;
        for (const QPolygonF &excl : exclusionPolygons) {
          if (excl.containsPoint(mid, Qt::WindingFill) ||
              excl.containsPoint(p1_eps, Qt::WindingFill) ||
              excl.containsPoint(p2_eps, Qt::WindingFill)) {
            insideExclusion = true;
            targetExcl = &excl;
            break;
          }
        }

        if (!insideExclusion) {
          if (currentPolyline.isEmpty())
            currentPolyline << p1;
          currentPolyline << p2;
        } else {
          // Inside exclusion, follow boundary
          QList<QPointF> boundary = _getBoundaryPath(*targetExcl, p1, p2);
          if (currentPolyline.isEmpty())
            currentPolyline << boundary.first();
          for (int k = 1; k < boundary.count(); k++) {
            if (!currentPolyline.contains(boundary[k]))
              currentPolyline << boundary[k];
          }
        }
      } else {
        // Outside main polygon, finish current polyline
        if (!currentPolyline.isEmpty()) {
          if (currentPolyline.count() >= 2)
            resultPolylines.append(currentPolyline);
          currentPolyline.clear();
        }
      }
    }
    if (!currentPolyline.isEmpty() && currentPolyline.count() >= 2) {
      resultPolylines.append(currentPolyline);
    }
  }
}

/// Adjust the line segments such that they are all going the same direction
/// with respect to going from P1->P2
void SurveyComplexItem::_adjustLineDirection(
    const QList<QList<QPointF>> &lineList, QList<QList<QPointF>> &resultLines) {
  qreal firstAngle = 0;
  for (int i = 0; i < lineList.count(); i++) {
    const QList<QPointF> &polyline = lineList[i];
    if (polyline.count() < 2)
      continue;

    QLineF overallLine(polyline.first(), polyline.last());
    if (i == 0) {
      firstAngle = overallLine.angle();
    }

    if (qAbs(overallLine.angle() - firstAngle) > 1.0) {
      QList<QPointF> reversed;
      for (int j = polyline.count() - 1; j >= 0; j--)
        reversed << polyline[j];
      resultLines.append(reversed);
    } else {
      resultLines.append(polyline);
    }
  }
}

double SurveyComplexItem::_clampGridAngle90(double gridAngle) {
  // Clamp grid angle to -90<->90. This prevents transects from being rotated to
  // a reversed order.
  if (gridAngle > 90.0) {
    gridAngle -= 180.0;
  } else if (gridAngle < -90.0) {
    gridAngle += 180;
  }
  return gridAngle;
}

bool SurveyComplexItem::_nextTransectCoord(
    const QList<QGeoCoordinate> &transectPoints, int pointIndex,
    QGeoCoordinate &coord) {
  if (pointIndex > transectPoints.count()) {
    qWarning() << "Bad grid generation";
    return false;
  }

  coord = transectPoints[pointIndex];
  return true;
}

bool SurveyComplexItem::_hasTurnaround(void) const {
  return _turnAroundDistance() != 0;
}

double SurveyComplexItem::_turnaroundDistance(void) const {
  return _turnAroundDistanceFact.rawValue().toDouble();
}

void SurveyComplexItem::_rebuildTransectsPhase1(void) {
  _rebuildTransectsPhase1WorkerSinglePolygon(false /* refly */);
  if (_refly90DegreesFact.rawValue().toBool()) {
    _rebuildTransectsPhase1WorkerSinglePolygon(true /* refly */);
  }
}

void SurveyComplexItem::_rebuildTransectsPhase1WorkerSinglePolygon(bool refly) {
  if (_ignoreRecalc) {
    return;
  }

  // If the transects are getting rebuilt then any previously loaded mission
  // items are now invalid
  if (_loadedMissionItemsParent) {
    _loadedMissionItems.clear();
    _loadedMissionItemsParent->deleteLater();
    _loadedMissionItemsParent = nullptr;
  }

  if (_surveyAreaPolygon.count() < 3) {
    return;
  }

  // Convert polygon to NED

  QList<QPointF> polygonPoints;
  QGeoCoordinate tangentOrigin = _surveyAreaPolygon.pathModel()
                                     .value<QGCQGeoCoordinate *>(0)
                                     ->coordinate();
  qCDebug(SurveyComplexItemLog)
      << "_rebuildTransectsPhase1 Convert polygon to NED - "
         "_surveyAreaPolygon.count():tangentOrigin"
      << _surveyAreaPolygon.count() << tangentOrigin;
  for (int i = 0; i < _surveyAreaPolygon.count(); i++) {
    double y, x, down;
    QGeoCoordinate vertex = _surveyAreaPolygon.pathModel()
                                .value<QGCQGeoCoordinate *>(i)
                                ->coordinate();
    if (i == 0) {
      // This avoids a nan calculation that comes out of convertGeoToNed
      x = y = 0;
    } else {
      QGCGeo::convertGeoToNed(vertex, tangentOrigin, y, x, down);
    }
    polygonPoints += QPointF(x, y);
    qCDebug(SurveyComplexItemLog)
        << "_rebuildTransectsPhase1 vertex:x:y" << vertex
        << polygonPoints.last().x() << polygonPoints.last().y();
  }

  // Generate transects

  double gridAngle = _gridAngleFact.rawValue().toDouble();
  double gridSpacing =
      _cameraCalc.adjustedFootprintSide()->rawValue().toDouble();
  if (gridSpacing < 0.5) {
    // We can't let gridSpacing get too small otherwise we will end up with too
    // many transects. So we limit to 0.5 meter spacing as min and set to huge
    // value which will cause a single transect to be added.
    gridSpacing = 100000;
  }

  gridAngle = _clampGridAngle90(gridAngle);
  gridAngle += refly ? 90 : 0;
  qCDebug(SurveyComplexItemLog)
      << "_rebuildTransectsPhase1 Clamped grid angle" << gridAngle;

  qCDebug(SurveyComplexItemLog)
      << "_rebuildTransectsPhase1 gridSpacing:gridAngle:refly" << gridSpacing
      << gridAngle << refly;

  // Convert polygon to bounding rect

  qCDebug(SurveyComplexItemLog) << "_rebuildTransectsPhase1 Polygon";
  QPolygonF polygon;
  for (int i = 0; i < polygonPoints.count(); i++) {
    qCDebug(SurveyComplexItemLog) << "Vertex" << polygonPoints[i];
    polygon << polygonPoints[i];
  }
  polygon << polygonPoints[0];
  QRectF boundingRect = polygon.boundingRect();
  QPointF boundingCenter = boundingRect.center();
  qCDebug(SurveyComplexItemLog)
      << "Bounding rect" << boundingRect.topLeft().x()
      << boundingRect.topLeft().y() << boundingRect.bottomRight().x()
      << boundingRect.bottomRight().y();

  // Create set of rotated parallel lines within the expanded bounding rect.
  // Make the lines larger than the bounding box to guarantee intersection.

  QList<QLineF> lineList;

  // Transects are generated to be as long as the largest width/height of the
  // bounding rect plus some fudge factor. This way they will always be
  // guaranteed to intersect with a polygon edge no matter what angle they are
  // rotated to. They are initially generated with the transects flowing from
  // west to east and then points within the transect north to south.
  double maxWidth = qMax(boundingRect.width(), boundingRect.height()) + 2000.0;
  double halfWidth = maxWidth / 2.0;
  double transectX = boundingCenter.x() - halfWidth;
  double transectXMax = transectX + maxWidth;
  while (transectX < transectXMax) {
    double transectYTop = boundingCenter.y() - halfWidth;
    double transectYBottom = boundingCenter.y() + halfWidth;

    lineList += QLineF(_rotatePoint(QPointF(transectX, transectYTop),
                                    boundingCenter, gridAngle),
                       _rotatePoint(QPointF(transectX, transectYBottom),
                                    boundingCenter, gridAngle));
    transectX += gridSpacing;
  }

  // Now intersect the lines with the polygon and exclusions
  QList<QPolygonF> exclusionPolygons;
  if (_masterController && _masterController->geoFenceController()) {
    GeoFenceController *fenceController =
        _masterController->geoFenceController();
    // Polygons
    for (int i = 0; i < fenceController->polygons()->count(); i++) {
      QGCFencePolygon *fencePolygon =
          fenceController->polygons()->value<QGCFencePolygon *>(i);
      if (fencePolygon) {
        QPolygonF exclusionPolygon;
        for (int j = 0; j < fencePolygon->count(); j++) {
          double north, east, down;
          QGCGeo::convertGeoToNed(fencePolygon->vertexCoordinate(j),
                                  tangentOrigin, north, east, down);
          exclusionPolygon << QPointF(east, north);
        }
        if (exclusionPolygon.count() > 0) {
          exclusionPolygon << exclusionPolygon.front(); // Close it
          exclusionPolygons.append(exclusionPolygon);
        }
      }
    }
    // Circles
    for (int i = 0; i < fenceController->circles()->count(); i++) {
      QGCFenceCircle *fenceCircle =
          fenceController->circles()->value<QGCFenceCircle *>(i);
      if (fenceCircle) {
        QPolygonF exclusionPolygon;
        QGeoCoordinate center = fenceCircle->center();
        double radius = fenceCircle->radius()->rawValue().toDouble();
        for (int j = 0; j < 36; j++) {
          double angle = (360.0 / 36.0) * j;
          QGeoCoordinate vertex = center.atDistanceAndAzimuth(radius, angle);
          double north, east, down;
          QGCGeo::convertGeoToNed(vertex, tangentOrigin, north, east, down);
          exclusionPolygon << QPointF(east, north);
        }
        if (exclusionPolygon.count() > 0) {
          exclusionPolygon << exclusionPolygon.front(); // Close it
          exclusionPolygons.append(exclusionPolygon);
        }
      }
    }
  }

  if (_mapPolygon && _mapPolygon->count() >= 3) {
    // Check if it's the same as survey area to avoid self-exclusion
    bool sameAsSurvey = (_mapPolygon == &_surveyAreaPolygon);
    if (!sameAsSurvey && _mapPolygon->count() == _surveyAreaPolygon.count()) {
        sameAsSurvey = true;
        for (int i = 0; i < _mapPolygon->count(); i++) {
            if (_mapPolygon->vertexCoordinate(i).distanceTo(_surveyAreaPolygon.vertexCoordinate(i)) > 0.1) {
                sameAsSurvey = false;
                break;
            }
        }
    }

    if (!sameAsSurvey) {
        QPolygonF exclusionPolygon;
        for (int i = 0; i < _mapPolygon->count(); i++) {
          double north, east, down;
          QGeoCoordinate coord = _mapPolygon->vertexCoordinate(i);
          QGCGeo::convertGeoToNed(coord, tangentOrigin, north, east, down);
          exclusionPolygon << QPointF(east, north);
        }
        if (exclusionPolygon.count() >= 3) {
          if (exclusionPolygon.front() != exclusionPolygon.back()) {
              exclusionPolygon << exclusionPolygon.front(); // Close it
          }

          // Verify winding for WindingFill consistency
          double sum = 0;
          for (int i = 0; i < exclusionPolygon.count() - 1; i++) {
            sum += (exclusionPolygon[i + 1].x() - exclusionPolygon[i].x()) *
                   (exclusionPolygon[i + 1].y() + exclusionPolygon[i].y());
          }
          if (sum < 0) {
            // Reverse for clockwise
            QPolygonF reversed;
            for (int i = exclusionPolygon.count() - 1; i >= 0; i--)
              reversed << exclusionPolygon[i];
            exclusionPolygon = reversed;
          }

          exclusionPolygons.append(exclusionPolygon);
        }
    }
  }

  // Add local obstacles from JSON
  for (const QPolygonF &obs : _localExclusionPolygons) {
    exclusionPolygons.append(obs);
  }

  // Now intersect the lines with the polygon
  QList<QList<QPointF>> intersectPolylines;
  qCDebug(SurveyComplexItemLog)
      << "Rebuilding transects. Main polygon vertices:" << polygon.count()
      << "Exclusion polygons:" << exclusionPolygons.count();
  for (int i = 0; i < exclusionPolygons.count(); i++) {
    qCDebug(SurveyComplexItemLog)
        << "Exclusion Polygon" << i
        << "vertices:" << exclusionPolygons[i].count();
    if (exclusionPolygons[i].count() > 0) {
      qCDebug(SurveyComplexItemLog)
          << "First vertex:" << exclusionPolygons[i].front();
    }
  }

#if 1
  _intersectLinesWithPolygon(lineList, polygon, exclusionPolygons,
                             intersectPolylines);
#else
  // This is handy for debugging grid problems, not for release
  for (const QLineF &line : lineList) {
    intersectPolylines.append({line.p1(), line.p2()});
  }
#endif

  // Less than two transects intersected with the polygon:
  //      Create a single transect which goes through the center of the polygon
  //      Intersect it with the polygon
  if (intersectPolylines.count() < 2) {
    _surveyAreaPolygon.center();
    QLineF firstLine = lineList.first();
    QPointF lineCenter = firstLine.pointAt(0.5);
    QPointF centerOffset = boundingCenter - lineCenter;
    firstLine.translate(centerOffset);
    lineList.clear();
    lineList.append(firstLine);
    _intersectLinesWithPolygon(lineList, polygon, exclusionPolygons,
                               intersectPolylines);
  }

  // Make sure all lines are going the same direction. Polygon intersection
  // leads to lines which can be in varied directions depending on the order of
  // the intesecting sides.
  QList<QList<QPointF>> resultPolylines;
  _adjustLineDirection(intersectPolylines, resultPolylines);

  // Convert from NED to Geo
  QList<QList<QGeoCoordinate>> transects;
  for (const QList<QPointF> &polyline : resultPolylines) {
    QList<QGeoCoordinate> transect;
    for (const QPointF &pt : polyline) {
      QGeoCoordinate coord;
      QGCGeo::convertNedToGeo(pt.y(), pt.x(), 0, tangentOrigin, coord);
      transect.append(coord);
    }
    transects.append(transect);
  }

  _adjustTransectsToEntryPointLocation(transects);

  if (refly) {
    _optimizeTransectsForShortestDistance(_transects.last().last().coord,
                                          transects);
  }

  if (_flyAlternateTransectsFact.rawValue().toBool()) {
    QList<QList<QGeoCoordinate>> alternatingTransects;
    for (int i = 0; i < transects.count(); i++) {
      if (!(i & 1)) {
        alternatingTransects.append(transects[i]);
      }
    }
    for (int i = transects.count() - 1; i > 0; i--) {
      if (i & 1) {
        alternatingTransects.append(transects[i]);
      }
    }
    transects = alternatingTransects;
  }

  // Adjust to lawnmower pattern
  bool reverseVertices = false;
  for (int i = 0; i < transects.count(); i++) {
    // We must reverse the vertices for every other transect in order to make a
    // lawnmower pattern
    QList<QGeoCoordinate> transectVertices = transects[i];
    if (reverseVertices) {
      reverseVertices = false;
      QList<QGeoCoordinate> reversedVertices;
      for (int j = transectVertices.count() - 1; j >= 0; j--) {
        reversedVertices.append(transectVertices[j]);
      }
      transectVertices = reversedVertices;
    } else {
      reverseVertices = true;
    }
    transects[i] = transectVertices;
  }

  // Convert to CoordInfo transects and append to _transects
  for (const QList<QGeoCoordinate> &transect : transects) {
    QList<TransectStyleComplexItem::CoordInfo_t> coordInfoTransect;
    TransectStyleComplexItem::CoordInfo_t coordInfo;

    // Handle Entry/Exit points (with optional indentation)
    QGeoCoordinate entryCoord = transect.first();
    QGeoCoordinate exitCoord = transect.last();
    double entryDist = _entryIndentation;
    double exitDist = _exitIndentation;

    if (entryDist < 0) {
      double azimuth = transect[0].azimuthTo(transect[1]);
      entryCoord = transect[0].atDistanceAndAzimuth(-entryDist, azimuth);
    }
    if (exitDist < 0) {
      double azimuth =
          transect.last().azimuthTo(transect[transect.count() - 2]);
      exitCoord = transect.last().atDistanceAndAzimuth(-exitDist, azimuth);
    }

    // Add all points of the transect
    for (int i = 0; i < transect.count(); i++) {
      CoordType type = CoordTypeInterior;
      QGeoCoordinate c = transect[i];
      if (i == 0) {
        type = CoordTypeSurveyEntry;
        c = entryCoord;
      } else if (i == transect.count() - 1) {
        type = CoordTypeSurveyExit;
        c = exitCoord;
      }
      coordInfo = {c, type};
      coordInfoTransect.append(coordInfo);
    }

    // For hover and capture we need points for each camera location within the
    // transect. Note: This currently assumes straight lines between entry and
    // exit for trigger placement, which might need refinement for complex
    // avoidance paths.
    if (triggerCamera() && hoverAndCaptureEnabled()) {
      double transectLength = entryCoord.distanceTo(exitCoord);
      double transectAzimuth = entryCoord.azimuthTo(exitCoord);
      if (triggerDistance() < transectLength) {
        int cInnerHoverPoints =
            static_cast<int>(floor(transectLength / triggerDistance()));
        for (int i = 0; i < cInnerHoverPoints; i++) {
          QGeoCoordinate hoverCoord = entryCoord.atDistanceAndAzimuth(
              triggerDistance() * (i + 1), transectAzimuth);
          TransectStyleComplexItem::CoordInfo_t coordInfo = {
              hoverCoord, CoordTypeInteriorHoverTrigger};
          coordInfoTransect.insert(1 + i, coordInfo);
        }
      }
    }

    // Extend the transect ends for turnaround (only if positive)
    if (entryDist > 0) {
      QGeoCoordinate turnaroundCoord;
      double azimuth = transect[0].azimuthTo(transect[1]);
      turnaroundCoord = transect[0].atDistanceAndAzimuth(-entryDist, azimuth);
      turnaroundCoord.setAltitude(qQNaN());
      TransectStyleComplexItem::CoordInfo_t coordInfo = {turnaroundCoord,
                                                         CoordTypeTurnaround};
      coordInfoTransect.prepend(coordInfo);
    }
    if (exitDist > 0) {
      QGeoCoordinate turnaroundCoord;
      double azimuth =
          transect.last().azimuthTo(transect[transect.count() - 2]);
      turnaroundCoord =
          transect.last().atDistanceAndAzimuth(-exitDist, azimuth);
      turnaroundCoord.setAltitude(qQNaN());
      TransectStyleComplexItem::CoordInfo_t coordInfo = {turnaroundCoord,
                                                         CoordTypeTurnaround};
      coordInfoTransect.append(coordInfo);
    }

    _transects.append(coordInfoTransect);
  }
}

#if 0
    // Splitting polygons is not supported since this code would get stuck in a infinite loop
    // Code is left here in case someone wants to try to resurrect it

void SurveyComplexItem::_rebuildTransectsPhase1WorkerSplitPolygons(bool refly)
{
    if (_ignoreRecalc) {
        return;
    }

    // If the transects are getting rebuilt then any previously loaded mission items are now invalid
    if (_loadedMissionItemsParent) {
        _loadedMissionItems.clear();
        _loadedMissionItemsParent->deleteLater();
        _loadedMissionItemsParent = nullptr;
    }

    if (_surveyAreaPolygon.count() < 3) {
        return;
    }

    // Convert polygon to NED

    QList<QPointF> polygonPoints;
    QGeoCoordinate tangentOrigin = _surveyAreaPolygon.pathModel().value<QGCQGeoCoordinate*>(0)->coordinate();
    qCDebug(SurveyComplexItemLog) << "_rebuildTransectsPhase1 Convert polygon to NED - _surveyAreaPolygon.count():tangentOrigin" << _surveyAreaPolygon.count() << tangentOrigin;
    for (int i=0; i<_surveyAreaPolygon.count(); i++) {
        double y, x, down;
        QGeoCoordinate vertex = _surveyAreaPolygon.pathModel().value<QGCQGeoCoordinate*>(i)->coordinate();
        if (i == 0) {
            // This avoids a nan calculation that comes out of convertGeoToNed
            x = y = 0;
        } else {
            convertGeoToNed(vertex, tangentOrigin, y, x, down);
        }
        polygonPoints += QPointF(x, y);
        qCDebug(SurveyComplexItemLog) << "_rebuildTransectsPhase1 vertex:x:y" << vertex << polygonPoints.last().x() << polygonPoints.last().y();
    }

    // convert into QPolygonF
    QPolygonF polygon;
    for (int i=0; i<polygonPoints.count(); i++) {
        qCDebug(SurveyComplexItemLog) << "Vertex" << polygonPoints[i];
        polygon << polygonPoints[i];
    }

    // Create list of separate polygons
    QList<QPolygonF> polygons{};
    _PolygonDecomposeConvex(polygon, polygons);

    // iterate over polygons
    for (auto p = polygons.begin(); p != polygons.end(); ++p) {
        QPointF* vMatch = nullptr;
        // find matching vertex in previous polygon
        if (p != polygons.begin()) {
            auto pLast = p - 1;
            for (auto& i : *p) {
                for (auto& j : *pLast) {
                   if (i == j) {
                       vMatch = &i;
                       break;
                   }
                   if (vMatch) break;
                }
            }

        }


        // close polygon
        *p << p->front();
        // build transects for this polygon
        // TODO figure out tangent origin
        // TODO improve selection of entry points
//        qCDebug(SurveyComplexItemLog) << "Transects from polynom p " << p;
        _rebuildTransectsFromPolygon(refly, *p, tangentOrigin, vMatch);
    }
}

void SurveyComplexItem::_PolygonDecomposeConvex(const QPolygonF& polygon, QList<QPolygonF>& decomposedPolygons)
{
	// this follows "Mark Keil's Algorithm" https://mpen.ca/406/keil
    int decompSize = std::numeric_limits<int>::max();
    if (polygon.size() < 3) return;
    if (polygon.size() == 3) {
        decomposedPolygons << polygon;
        return;
    }

    QList<QPolygonF> decomposedPolygonsMin{};

    for (auto vertex = polygon.begin(); vertex != polygon.end(); ++vertex)
    {
        // is vertex reflex?
        bool vertexIsReflex = _VertexIsReflex(polygon, vertex);

        if (!vertexIsReflex) continue;

        for (auto vertexOther = polygon.begin(); vertexOther != polygon.end(); ++vertexOther)
        {
            auto vertexBefore = vertex == polygon.begin() ? polygon.end() - 1 : vertex - 1;
            auto vertexAfter = vertex == polygon.end() - 1 ? polygon.begin() : vertex + 1;
            if (vertexOther == vertex) continue;
            if (vertexAfter == vertexOther) continue;
            if (vertexBefore == vertexOther) continue;
            bool canSee = _VertexCanSeeOther(polygon, vertex, vertexOther);
            if (!canSee) continue;

            QPolygonF polyLeft;
            auto v = vertex;
            auto polyLeftContainsReflex = false;
            while ( v != vertexOther) {
                if (v != vertex && _VertexIsReflex(polygon, v)) {
                    polyLeftContainsReflex = true;
                }
                polyLeft << *v;
                ++v;
                if (v == polygon.end()) v = polygon.begin();
            }
            polyLeft << *vertexOther;
            auto polyLeftValid = !(polyLeftContainsReflex && polyLeft.size() == 3);

            QPolygonF polyRight;
            v = vertexOther;
            auto polyRightContainsReflex = false;
            while ( v != vertex) {
                if (v != vertex && _VertexIsReflex(polygon, v)) {
                    polyRightContainsReflex = true;
                }
                polyRight << *v;
                ++v;
                if (v == polygon.end()) v = polygon.begin();
            }
            polyRight << *vertex;
            auto polyRightValid = !(polyRightContainsReflex && polyRight.size() == 3);

            if (!polyLeftValid || ! polyRightValid) {
//                decompSize = std::numeric_limits<int>::max();
                continue;
            }

            // recursion
            QList<QPolygonF> polyLeftDecomposed{};
            _PolygonDecomposeConvex(polyLeft, polyLeftDecomposed);

            QList<QPolygonF> polyRightDecomposed{};
            _PolygonDecomposeConvex(polyRight, polyRightDecomposed);

            // compositon
            auto subSize = polyLeftDecomposed.size() + polyRightDecomposed.size();
            if ((polyLeftContainsReflex && polyLeftDecomposed.size() == 1)
                    || (polyRightContainsReflex && polyRightDecomposed.size() == 1))
            {
                // don't accept polygons that contian reflex vertices and were not split
                subSize = std::numeric_limits<int>::max();
            }
            if (subSize < decompSize) {
                decompSize = subSize;
                decomposedPolygonsMin = polyLeftDecomposed + polyRightDecomposed;
            }
        }

    }

    // assemble output
    if (decomposedPolygonsMin.size() > 0) {
        decomposedPolygons << decomposedPolygonsMin;
    } else {
        decomposedPolygons << polygon;
    }

    return;
}

bool SurveyComplexItem::_VertexCanSeeOther(const QPolygonF& polygon, const QPointF* vertexA, const QPointF* vertexB) {
    if (vertexA == vertexB) return false;
    auto vertexAAfter = vertexA + 1 == polygon.end() ? polygon.begin() : vertexA + 1;
    auto vertexABefore = vertexA == polygon.begin() ? polygon.end() - 1 : vertexA - 1;
    if (vertexAAfter == vertexB) return false;
    if (vertexABefore == vertexB) return false;
//    qCDebug(SurveyComplexItemLog) << "_VertexCanSeeOther false after first checks ";

    bool visible = true;
//    auto diff = *vertexA - *vertexB;
    QLineF lineAB{*vertexA, *vertexB};
    auto distanceAB = lineAB.length();//sqrtf(diff.x() * diff.x() + diff.y()*diff.y());

//    qCDebug(SurveyComplexItemLog) << "_VertexCanSeeOther distanceAB " << distanceAB;
    for (auto vertexC = polygon.begin(); vertexC != polygon.end(); ++vertexC)
    {
        if (vertexC == vertexA) continue;
        if (vertexC == vertexB) continue;
        auto vertexD = vertexC + 1 == polygon.end() ? polygon.begin() : vertexC + 1;
        if (vertexD == vertexA) continue;
        if (vertexD == vertexB) continue;
        QLineF lineCD(*vertexC, *vertexD);
        QPointF intersection{};

        auto intersects = lineAB.intersects(lineCD, &intersection);
        if (intersects == QLineF::IntersectType::BoundedIntersection) {
//            auto diffIntersection = *vertexA - intersection;
//            auto distanceIntersection = sqrtf(diffIntersection.x() * diffIntersection.x() + diffIntersection.y()*diffIntersection.y());
//            qCDebug(SurveyComplexItemLog) << "*vertexA " << *vertexA << "*vertexB " << *vertexB  << " intersection " << intersection;

            QLineF lineIntersection{*vertexA, intersection};
            auto distanceIntersection = lineIntersection.length();//sqrtf(diff.x() * diff.x() + diff.y()*diff.y());
            qCDebug(SurveyComplexItemLog) << "_VertexCanSeeOther distanceIntersection " << distanceIntersection;
            if (distanceIntersection < distanceAB) {
                visible = false;
                break;
            }
        }

    }

    return visible;
}

bool SurveyComplexItem::_VertexIsReflex(const QPolygonF& polygon, QList<QPointF>::const_iterator& vertexIter) {
    auto vertexBefore = vertex == polygon.begin() ? polygon.end() - 1 : vertex - 1;
    auto vertexAfter = vertex == polygon.end() - 1 ? polygon.begin() : vertex + 1;
    auto area = (((vertex->x() - vertexBefore->x())*(vertexAfter->y() - vertexBefore->y()))-((vertexAfter->x() - vertexBefore->x())*(vertex->y() - vertexBefore->y())));
    return area > 0;

}
#endif

void SurveyComplexItem::_rebuildTransectsFromPolygon(
    bool refly, const QPolygonF &polygon, const QGeoCoordinate &tangentOrigin,
    const QPointF *const transitionPoint) {
  // Generate transects

  double gridAngle = _gridAngleFact.rawValue().toDouble();
  double gridSpacing =
      _cameraCalc.adjustedFootprintSide()->rawValue().toDouble();

  gridAngle = _clampGridAngle90(gridAngle);
  gridAngle += refly ? 90 : 0;
  qCDebug(SurveyComplexItemLog)
      << "_rebuildTransectsPhase1 Clamped grid angle" << gridAngle;

  qCDebug(SurveyComplexItemLog)
      << "_rebuildTransectsPhase1 gridSpacing:gridAngle:refly" << gridSpacing
      << gridAngle << refly;

  // Convert polygon to bounding rect

  qCDebug(SurveyComplexItemLog) << "_rebuildTransectsPhase1 Polygon";
  QRectF boundingRect = polygon.boundingRect();
  QPointF boundingCenter = boundingRect.center();
  qCDebug(SurveyComplexItemLog)
      << "Bounding rect" << boundingRect.topLeft().x()
      << boundingRect.topLeft().y() << boundingRect.bottomRight().x()
      << boundingRect.bottomRight().y();

  // Create set of rotated parallel lines within the expanded bounding rect.
  // Make the lines larger than the bounding box to guarantee intersection.

  QList<QLineF> lineList;

  // Transects are generated to be as long as the largest width/height of the
  // bounding rect plus some fudge factor. This way they will always be
  // guaranteed to intersect with a polygon edge no matter what angle they are
  // rotated to. They are initially generated with the transects flowing from
  // west to east and then points within the transect north to south.
  double maxWidth = qMax(boundingRect.width(), boundingRect.height()) + 2000.0;
  double halfWidth = maxWidth / 2.0;
  double transectX = boundingCenter.x() - halfWidth;
  double transectXMax = transectX + maxWidth;
  while (transectX < transectXMax) {
    double transectYTop = boundingCenter.y() - halfWidth;
    double transectYBottom = boundingCenter.y() + halfWidth;

    lineList += QLineF(_rotatePoint(QPointF(transectX, transectYTop),
                                    boundingCenter, gridAngle),
                       _rotatePoint(QPointF(transectX, transectYBottom),
                                    boundingCenter, gridAngle));
    transectX += gridSpacing;
  }

  // Now intersect the lines with the polygon and exclusions
  QList<QPolygonF> exclusionPolygons;
  if (_masterController && _masterController->geoFenceController()) {
    GeoFenceController *fenceController =
        _masterController->geoFenceController();
    for (int i = 0; i < fenceController->polygons()->count(); i++) {
      QGCFencePolygon *fencePolygon =
          fenceController->polygons()->value<QGCFencePolygon *>(i);
      if (fencePolygon) {
        QPolygonF exclusionPolygon;
        for (int j = 0; j < fencePolygon->count(); j++) {
          double north, east, down;
          QGCGeo::convertGeoToNed(fencePolygon->vertexCoordinate(j),
                                  tangentOrigin, north, east, down);
          exclusionPolygon << QPointF(east, north);
        }
        if (exclusionPolygon.count() > 0) {
          exclusionPolygon << exclusionPolygon.front(); // Close it
          exclusionPolygons.append(exclusionPolygon);
        }
      }
    }
    // Circles
    for (int i = 0; i < fenceController->circles()->count(); i++) {
      QGCFenceCircle *fenceCircle =
          fenceController->circles()->value<QGCFenceCircle *>(i);
      if (fenceCircle) {
        QPolygonF exclusionPolygon;
        QGeoCoordinate center = fenceCircle->center();
        double radius = fenceCircle->radius()->rawValue().toDouble();
        for (int j = 0; j < 36; j++) {
          double angle = (360.0 / 36.0) * j;
          QGeoCoordinate vertex = center.atDistanceAndAzimuth(radius, angle);
          double north, east, down;
          QGCGeo::convertGeoToNed(vertex, tangentOrigin, north, east, down);
          exclusionPolygon << QPointF(east, north);
        }
        if (exclusionPolygon.count() > 0) {
          exclusionPolygon << exclusionPolygon.front(); // Close it
          exclusionPolygons.append(exclusionPolygon);
        }
      }
    }
  }

  // Now intersect the lines with the polygon
  QList<QList<QPointF>> intersectPolylines;
#if 1
  _intersectLinesWithPolygon(lineList, polygon, exclusionPolygons,
                             intersectPolylines);
#else
  // This is handy for debugging grid problems, not for release
  for (const QLineF &line : lineList) {
    intersectPolylines.append({line.p1(), line.p2()});
  }
#endif

  // Less than two transects intersected with the polygon:
  //      Create a single transect which goes through the center of the polygon
  //      Intersect it with the polygon
  if (intersectPolylines.count() < 2) {
    _surveyAreaPolygon.center();
    QLineF firstLine = lineList.first();
    QPointF lineCenter = firstLine.pointAt(0.5);
    QPointF centerOffset = boundingCenter - lineCenter;
    firstLine.translate(centerOffset);
    lineList.clear();
    lineList.append(firstLine);
    _intersectLinesWithPolygon(lineList, polygon, exclusionPolygons,
                               intersectPolylines);
  }

  // Make sure all lines are going the same direction. Polygon intersection
  // leads to lines which can be in varied directions depending on the order of
  // the intesecting sides.
  QList<QList<QPointF>> resultPolylines;
  _adjustLineDirection(intersectPolylines, resultPolylines);

  // Convert from NED to Geo
  QList<QList<QGeoCoordinate>> transects;

  if (transitionPoint != nullptr) {
    QList<QGeoCoordinate> transect;
    QGeoCoordinate coord;
    QGCGeo::convertNedToGeo(transitionPoint->y(), transitionPoint->x(), 0,
                            tangentOrigin, coord);
    transect.append(coord);
    transect.append(coord); // TODO
    transects.append(transect);
  }

  for (const QList<QPointF> &polyline : resultPolylines) {
    QList<QGeoCoordinate> transect;
    for (const QPointF &pt : polyline) {
      QGeoCoordinate coord;
      QGCGeo::convertNedToGeo(pt.y(), pt.x(), 0, tangentOrigin, coord);
      transect.append(coord);
    }
    transects.append(transect);
  }

  _adjustTransectsToEntryPointLocation(transects);

  if (refly) {
    _optimizeTransectsForShortestDistance(_transects.last().last().coord,
                                          transects);
  }

  if (_flyAlternateTransectsFact.rawValue().toBool()) {
    QList<QList<QGeoCoordinate>> alternatingTransects;
    for (int i = 0; i < transects.count(); i++) {
      if (!(i & 1)) {
        alternatingTransects.append(transects[i]);
      }
    }
    for (int i = transects.count() - 1; i > 0; i--) {
      if (i & 1) {
        alternatingTransects.append(transects[i]);
      }
    }
    transects = alternatingTransects;
  }

  // Adjust to lawnmower pattern
  bool reverseVertices = false;
  for (int i = 0; i < transects.count(); i++) {
    // We must reverse the vertices for every other transect in order to make a
    // lawnmower pattern
    QList<QGeoCoordinate> transectVertices = transects[i];
    if (reverseVertices) {
      reverseVertices = false;
      QList<QGeoCoordinate> reversedVertices;
      for (int j = transectVertices.count() - 1; j >= 0; j--) {
        reversedVertices.append(transectVertices[j]);
      }
      transectVertices = reversedVertices;
    } else {
      reverseVertices = true;
    }
    transects[i] = transectVertices;
  }

  // Convert to CoordInfo transects and append to _transects
  for (const QList<QGeoCoordinate> &transect : transects) {
    QList<TransectStyleComplexItem::CoordInfo_t> coordInfoTransect;
    TransectStyleComplexItem::CoordInfo_t coordInfo;

    // Handle Entry/Exit points (with optional indentation)
    QGeoCoordinate entryCoord = transect.first();
    QGeoCoordinate exitCoord = transect.last();
    double entryDist = _entryIndentation;
    double exitDist = _exitIndentation;

    if (entryDist < 0) {
      double azimuth = transect[0].azimuthTo(transect[1]);
      entryCoord = transect[0].atDistanceAndAzimuth(-entryDist, azimuth);
    }
    if (exitDist < 0) {
      double azimuth =
          transect.last().azimuthTo(transect[transect.count() - 2]);
      exitCoord = transect.last().atDistanceAndAzimuth(-exitDist, azimuth);
    }

    // Add all points of the transect
    for (int i = 0; i < transect.count(); i++) {
      CoordType type = CoordTypeInterior;
      QGeoCoordinate c = transect[i];
      if (i == 0) {
        type = CoordTypeSurveyEntry;
        c = entryCoord;
      } else if (i == transect.count() - 1) {
        type = CoordTypeSurveyExit;
        c = exitCoord;
      }
      coordInfo = {c, type};
      coordInfoTransect.append(coordInfo);
    }

    // For hover and capture we need points for each camera location within the
    // transect
    if (triggerCamera() && hoverAndCaptureEnabled()) {
      double transectLength = entryCoord.distanceTo(exitCoord);
      double transectAzimuth = entryCoord.azimuthTo(exitCoord);
      if (triggerDistance() < transectLength) {
        int cInnerHoverPoints =
            static_cast<int>(floor(transectLength / triggerDistance()));
        for (int i = 0; i < cInnerHoverPoints; i++) {
          QGeoCoordinate hoverCoord = entryCoord.atDistanceAndAzimuth(
              triggerDistance() * (i + 1), transectAzimuth);
          TransectStyleComplexItem::CoordInfo_t coordInfo = {
              hoverCoord, CoordTypeInteriorHoverTrigger};
          coordInfoTransect.insert(1 + i, coordInfo);
        }
      }
    }

    // Extend the transect ends for turnaround (only if positive)
    if (entryDist > 0) {
      QGeoCoordinate turnaroundCoord;
      double azimuth = transect[0].azimuthTo(transect[1]);
      turnaroundCoord = transect[0].atDistanceAndAzimuth(-entryDist, azimuth);
      turnaroundCoord.setAltitude(qQNaN());
      TransectStyleComplexItem::CoordInfo_t coordInfo = {turnaroundCoord,
                                                         CoordTypeTurnaround};
      coordInfoTransect.prepend(coordInfo);
    }
    if (exitDist > 0) {
      QGeoCoordinate turnaroundCoord;
      double azimuth =
          transect.last().azimuthTo(transect[transect.count() - 2]);
      turnaroundCoord =
          transect.last().atDistanceAndAzimuth(-exitDist, azimuth);
      turnaroundCoord.setAltitude(qQNaN());
      TransectStyleComplexItem::CoordInfo_t coordInfo = {turnaroundCoord,
                                                         CoordTypeTurnaround};
      coordInfoTransect.append(coordInfo);
    }

    _transects.append(coordInfoTransect);
  }
  qCDebug(SurveyComplexItemLog) << "_transects.size() " << _transects.size();
}

void SurveyComplexItem::_recalcCameraShots(void) {
  double triggerDistance = this->triggerDistance();

  if (triggerDistance == 0) {
    _cameraShots = 0;
  } else {
    if (_cameraTriggerInTurnAroundFact.rawValue().toBool()) {
      _cameraShots = qCeil(_complexDistance / triggerDistance);
    } else {
      _cameraShots = 0;

      if (_loadedMissionItemsParent) {
        // We have to do it the hard way based on the mission items themselves
        if (hoverAndCaptureEnabled()) {
          // Count the number of camera triggers in the mission items
          for (const MissionItem *missionItem : _loadedMissionItems) {
            _cameraShots +=
                missionItem->command() == MAV_CMD_IMAGE_START_CAPTURE ? 1 : 0;
          }
        } else {
          bool waitingForTriggerStop = false;
          QGeoCoordinate distanceStartCoord;
          QGeoCoordinate distanceEndCoord;
          for (const MissionItem *missionItem : _loadedMissionItems) {
            if (missionItem->command() == MAV_CMD_NAV_WAYPOINT) {
              if (waitingForTriggerStop) {
                distanceEndCoord = QGeoCoordinate(missionItem->param5(),
                                                  missionItem->param6());
              } else {
                distanceStartCoord = QGeoCoordinate(missionItem->param5(),
                                                    missionItem->param6());
              }
            } else if (missionItem->command() ==
                       MAV_CMD_DO_SET_CAM_TRIGG_DIST) {
              if (missionItem->param1() > 0) {
                // Trigger start
                waitingForTriggerStop = true;
              } else {
                // Trigger stop
                waitingForTriggerStop = false;
                _cameraShots +=
                    qCeil(distanceEndCoord.distanceTo(distanceStartCoord) /
                          triggerDistance);
                distanceStartCoord = QGeoCoordinate();
                distanceEndCoord = QGeoCoordinate();
              }
            }
          }
        }
      } else {
        // We have transects available, calc from those
        for (const QList<TransectStyleComplexItem::CoordInfo_t> &transect :
             _transects) {
          QGeoCoordinate firstCameraCoord, lastCameraCoord;
          if (_hasTurnaround() && !hoverAndCaptureEnabled()) {
            firstCameraCoord = transect[1].coord;
            lastCameraCoord = transect[transect.count() - 2].coord;
          } else {
            firstCameraCoord = transect.first().coord;
            lastCameraCoord = transect.last().coord;
          }
          _cameraShots += qCeil(firstCameraCoord.distanceTo(lastCameraCoord) /
                                triggerDistance);
        }
      }
    }
  }

  emit cameraShotsChanged();
}

SurveyComplexItem::ReadyForSaveState
SurveyComplexItem::readyForSaveState(void) const {
  return TransectStyleComplexItem::readyForSaveState();
}

void SurveyComplexItem::rotateEntryPoint(void) {
  if (_entryPoint == EntryLocationLast) {
    _entryPoint = EntryLocationFirst;
  } else {
    _entryPoint++;
  }

  _rebuildTransects();

  setDirty(true);
}

double SurveyComplexItem::timeBetweenShots(void) {
  return _vehicleSpeed == 0 ? 0 : triggerDistance() / _vehicleSpeed;
}

double SurveyComplexItem::additionalTimeDelay(void) const {
  double hoverTime = 0;

  if (hoverAndCaptureEnabled()) {
    for (const QList<TransectStyleComplexItem::CoordInfo_t> &transect :
         _transects) {
      hoverTime += _hoverAndCaptureDelaySeconds * transect.count();
    }
  }

  return hoverTime;
}

void SurveyComplexItem::_updateWizardMode(void) {
  if (_surveyAreaPolygon.isValid() && !_surveyAreaPolygon.traceMode()) {
    setWizardMode(false);
  }
}
