/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtCore/QVariantList>

class YoloDetectionController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString modelPath READ modelPath WRITE setModelPath NOTIFY modelPathChanged)
    Q_PROPERTY(QString labelsPath READ labelsPath WRITE setLabelsPath NOTIFY labelsPathChanged)
    Q_PROPERTY(bool modelReady READ modelReady NOTIFY modelReadyChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QVariantList detections READ detections NOTIFY detectionsChanged)

public:
    explicit YoloDetectionController(QObject* parent = nullptr);

    QString modelPath() const { return _modelPath; }
    QString labelsPath() const { return _labelsPath; }
    bool modelReady() const { return _modelReady; }
    QString statusText() const { return _statusText; }
    QVariantList detections() const { return _detections; }

    void setModelPath(const QString& modelPath);
    void setLabelsPath(const QString& labelsPath);

    Q_INVOKABLE void reloadModel();
    Q_INVOKABLE void detectImage(const QString& imagePath);

signals:
    void modelPathChanged();
    void labelsPathChanged();
    void modelReadyChanged();
    void statusTextChanged();
    void detectionsChanged();

private:
    void _setModelReady(bool ready);
    void _setStatusText(const QString& statusText);
    void _setDetections(const QVariantList& detections);
    QString _defaultModelPath() const;
    QString _defaultLabelsPath() const;

    QString _modelPath;
    QString _labelsPath;
    bool _modelReady = false;
    QString _statusText;
    QVariantList _detections;
};
