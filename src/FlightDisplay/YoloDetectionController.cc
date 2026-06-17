/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "YoloDetectionController.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QTextStream>

#include <algorithm>
#include <cmath>

#ifdef QGC_ENABLE_OPENCV_DNN
#include <opencv2/core.hpp>
#include <opencv2/dnn.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#endif

namespace {
constexpr float kConfidenceThreshold = 0.35f;
constexpr float kNmsThreshold = 0.45f;
constexpr int kInputSize = 640;
}

YoloDetectionController::YoloDetectionController(QObject* parent)
    : QObject(parent)
    , _modelPath(_defaultModelPath())
    , _labelsPath(_defaultLabelsPath())
{
    reloadModel();
}

void YoloDetectionController::setModelPath(const QString& modelPath)
{
    if (_modelPath == modelPath) {
        return;
    }
    _modelPath = modelPath;
    emit modelPathChanged();
    reloadModel();
}

void YoloDetectionController::setLabelsPath(const QString& labelsPath)
{
    if (_labelsPath == labelsPath) {
        return;
    }
    _labelsPath = labelsPath;
    emit labelsPathChanged();
    reloadModel();
}

void YoloDetectionController::reloadModel()
{
#ifndef QGC_ENABLE_OPENCV_DNN
    _setModelReady(false);
    _setStatusText(tr("YOLO runtime not built. Enable OpenCV DNN."));
#else
    if (!QFileInfo::exists(_modelPath)) {
        _setModelReady(false);
        _setStatusText(tr("YOLO model missing: %1").arg(QDir::toNativeSeparators(_modelPath)));
        return;
    }

    try {
        cv::dnn::Net net = cv::dnn::readNetFromONNX(_modelPath.toStdString());
        if (net.empty()) {
            _setModelReady(false);
            _setStatusText(tr("Unable to load YOLO model"));
            return;
        }
    } catch (const cv::Exception& e) {
        _setModelReady(false);
        _setStatusText(QString::fromStdString(e.msg));
        return;
    }

    _setModelReady(true);
    _setStatusText(tr("YOLO Detection Active"));
#endif
}

void YoloDetectionController::detectImage(const QString& imagePath)
{
#ifndef QGC_ENABLE_OPENCV_DNN
    Q_UNUSED(imagePath)
    _setDetections({});
    _setStatusText(tr("YOLO runtime not built. Enable OpenCV DNN."));
#else
    if (!_modelReady) {
        _setDetections({});
        return;
    }

    QStringList labels;
    QFile labelsFile(_labelsPath);
    if (labelsFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream stream(&labelsFile);
        while (!stream.atEnd()) {
            const QString label = stream.readLine().trimmed();
            if (!label.isEmpty()) {
                labels.append(label);
            }
        }
    }

    cv::Mat frame = cv::imread(imagePath.toStdString());
    if (frame.empty()) {
        _setStatusText(tr("AI frame grab failed"));
        return;
    }

    cv::dnn::Net net;
    try {
        net = cv::dnn::readNetFromONNX(_modelPath.toStdString());
    } catch (const cv::Exception& e) {
        _setModelReady(false);
        _setDetections({});
        _setStatusText(QString::fromStdString(e.msg));
        return;
    }

    const float scale = std::min(static_cast<float>(kInputSize) / frame.cols, static_cast<float>(kInputSize) / frame.rows);
    const int newW = static_cast<int>(std::round(frame.cols * scale));
    const int newH = static_cast<int>(std::round(frame.rows * scale));
    const int padX = (kInputSize - newW) / 2;
    const int padY = (kInputSize - newH) / 2;

    cv::Mat resized;
    cv::resize(frame, resized, cv::Size(newW, newH));
    cv::Mat input = cv::Mat::zeros(kInputSize, kInputSize, frame.type());
    resized.copyTo(input(cv::Rect(padX, padY, newW, newH)));

    cv::Mat blob = cv::dnn::blobFromImage(input, 1.0 / 255.0, cv::Size(kInputSize, kInputSize), cv::Scalar(), true, false);
    net.setInput(blob);

    std::vector<cv::Mat> outputs;
    try {
        net.forward(outputs, net.getUnconnectedOutLayersNames());
    } catch (const cv::Exception& e) {
        _setStatusText(QString::fromStdString(e.msg));
        _setDetections({});
        return;
    }

    if (outputs.empty()) {
        _setDetections({});
        return;
    }

    cv::Mat output = outputs[0];
    cv::Mat proposals;
    if (output.dims == 3) {
        const int rows = output.size[1];
        const int cols = output.size[2];
        proposals = cv::Mat(rows, cols, CV_32F, output.ptr<float>());
        if (rows < cols) {
            cv::transpose(proposals, proposals);
        }
    } else {
        proposals = output.reshape(1, output.rows);
    }

    std::vector<cv::Rect> boxes;
    std::vector<float> confidences;
    std::vector<int> classIds;

    for (int i = 0; i < proposals.rows; ++i) {
        const float* data = proposals.ptr<float>(i);
        const int attrCount = proposals.cols;
        if (attrCount < 6) {
            continue;
        }

        const bool hasObjectness = labels.isEmpty() ? attrCount > 84 : attrCount == labels.count() + 5;
        const int classOffset = hasObjectness ? 5 : 4;
        const float objectness = hasObjectness ? data[4] : 1.0f;

        int bestClass = -1;
        float bestScore = 0.0f;
        for (int c = classOffset; c < attrCount; ++c) {
            const float score = data[c];
            if (score > bestScore) {
                bestScore = score;
                bestClass = c - classOffset;
            }
        }

        const float confidence = objectness * bestScore;
        if (confidence < kConfidenceThreshold) {
            continue;
        }

        const float cx = (data[0] - padX) / scale;
        const float cy = (data[1] - padY) / scale;
        const float w = data[2] / scale;
        const float h = data[3] / scale;
        const int left = std::max(0, static_cast<int>(cx - w / 2.0f));
        const int top = std::max(0, static_cast<int>(cy - h / 2.0f));
        const int width = std::min(frame.cols - left, static_cast<int>(w));
        const int height = std::min(frame.rows - top, static_cast<int>(h));
        if (width <= 0 || height <= 0) {
            continue;
        }

        boxes.emplace_back(left, top, width, height);
        confidences.emplace_back(confidence);
        classIds.emplace_back(bestClass);
    }

    std::vector<int> indices;
    cv::dnn::NMSBoxes(boxes, confidences, kConfidenceThreshold, kNmsThreshold, indices);

    QVariantList detections;
    for (int idx : indices) {
        const cv::Rect& box = boxes[idx];
        QVariantMap detection;
        detection["x"] = static_cast<double>(box.x) / frame.cols;
        detection["y"] = static_cast<double>(box.y) / frame.rows;
        detection["w"] = static_cast<double>(box.width) / frame.cols;
        detection["h"] = static_cast<double>(box.height) / frame.rows;
        detection["confidence"] = confidences[idx];
        const int classId = classIds[idx];
        detection["label"] = classId >= 0 && classId < labels.count() ? labels[classId] : tr("Object");
        detections.append(detection);
    }

    _setStatusText(detections.isEmpty() ? tr("YOLO Active: no objects") : tr("YOLO Active: %1 object(s)").arg(detections.count()));
    _setDetections(detections);
#endif
}

void YoloDetectionController::_setModelReady(bool ready)
{
    if (_modelReady == ready) {
        return;
    }
    _modelReady = ready;
    emit modelReadyChanged();
}

void YoloDetectionController::_setStatusText(const QString& statusText)
{
    if (_statusText == statusText) {
        return;
    }
    _statusText = statusText;
    emit statusTextChanged();
}

void YoloDetectionController::_setDetections(const QVariantList& detections)
{
    _detections = detections;
    emit detectionsChanged();
}

QString YoloDetectionController::_defaultModelPath() const
{
    const QString appModelPath = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("models/yolo.onnx"));
    if (QFileInfo::exists(appModelPath)) {
        return appModelPath;
    }
#ifdef QGC_AI_MODEL_DIR
    const QString sourceModelPath = QDir(QStringLiteral(QGC_AI_MODEL_DIR)).filePath(QStringLiteral("yolo.onnx"));
    if (QFileInfo::exists(sourceModelPath)) {
        return sourceModelPath;
    }
#endif
    return appModelPath;
}

QString YoloDetectionController::_defaultLabelsPath() const
{
    const QString appLabelsPath = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("models/coco.names"));
    if (QFileInfo::exists(appLabelsPath)) {
        return appLabelsPath;
    }
#ifdef QGC_AI_MODEL_DIR
    const QString sourceLabelsPath = QDir(QStringLiteral(QGC_AI_MODEL_DIR)).filePath(QStringLiteral("coco.names"));
    if (QFileInfo::exists(sourceLabelsPath)) {
        return sourceLabelsPath;
    }
#endif
    return appLabelsPath;
}
