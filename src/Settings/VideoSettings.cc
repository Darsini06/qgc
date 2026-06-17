/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VideoSettings.h"
#include "QGCApplication.h"
#include "VideoManager.h"

#include <QtQml/QQmlEngine>
#include <QtCore/QVariantList>

#ifndef QGC_DISABLE_UVC
#include <QtMultimedia/QMediaDevices>
#include <QtMultimedia/QCameraDevice>
#endif

namespace {
QString firstUvcCameraDescription()
{
#ifndef QGC_DISABLE_UVC
    const QList<QCameraDevice> videoInputs = QMediaDevices::videoInputs();
    if (!videoInputs.isEmpty()) {
        return videoInputs.first().description();
    }
#endif
    return QString();
}
} // namespace

DECLARE_SETTINGGROUP(Video, "Video")
{
    qmlRegisterUncreatableType<VideoSettings>("QGroundControl.SettingsManager", 1, 0, "VideoSettings", "Reference only");

    // Setup enum values for videoSource settings into meta data
    QVariantList videoSourceList;
    videoSourceList.append(videoSourceRTSP);
    videoSourceList.append(videoSourceUDPH264);
    videoSourceList.append(videoSourceUDPH265);
    videoSourceList.append(videoSourceTCP);
    videoSourceList.append(videoSourceMPEGTS);
    videoSourceList.append(videoSource3DRSolo);
    videoSourceList.append(videoSourceParrotDiscovery);
    videoSourceList.append(videoSourceYuneecMantisG);
    videoSourceList.append(videoSourceHerelinkAirUnit);
    videoSourceList.append(videoSourceHerelinkHotspot);
#ifndef QGC_DISABLE_UVC
    QList<QCameraDevice> videoInputs = QMediaDevices::videoInputs();
    for (const auto& cameraDevice: videoInputs) {
        if (_autoDetectedVideoSource.isEmpty()) {
            _autoDetectedVideoSource = cameraDevice.description();
        }
        videoSourceList.append(cameraDevice.description());
    }
#endif
    if (videoSourceList.count() == 0) {
        _noVideo = true;
        videoSourceList.append(videoSourceNoVideo);
    } else {
        videoSourceList.insert(0, videoDisabled);
    }

    // make translated strings
    QStringList videoSourceCookedList;
    for (const QVariant& videoSource: videoSourceList) {
        videoSourceCookedList.append( VideoSettings::tr(videoSource.toString().toStdString().c_str()) );
    }

    _nameToMetaDataMap[videoSourceName]->setEnumInfo(videoSourceCookedList, videoSourceList);

    const QVariantList removeForceVideoDecodeList{
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
        VideoDecoderOptions::ForceVideoDecoderDirectX3D,
        VideoDecoderOptions::ForceVideoDecoderVideoToolbox,
#elif defined(Q_OS_WIN)
        VideoDecoderOptions::ForceVideoDecoderVAAPI,
        VideoDecoderOptions::ForceVideoDecoderVideoToolbox,
#elif defined(Q_OS_MAC)
        VideoDecoderOptions::ForceVideoDecoderDirectX3D,
        VideoDecoderOptions::ForceVideoDecoderVAAPI,
#elif defined(Q_OS_ANDROID)
        VideoDecoderOptions::ForceVideoDecoderDirectX3D,
        VideoDecoderOptions::ForceVideoDecoderVideoToolbox,
        VideoDecoderOptions::ForceVideoDecoderVAAPI,
        VideoDecoderOptions::ForceVideoDecoderNVIDIA,
#endif
    };

    for(const auto& value : removeForceVideoDecodeList) {
        _nameToMetaDataMap[forceVideoDecoderName]->removeEnumInfo(value);
    }

    // Set default value for videoSource
    _setDefaults();
}

void VideoSettings::_setDefaults()
{
    if (_noVideo) {
        _nameToMetaDataMap[videoSourceName]->setRawDefaultValue(videoSourceNoVideo);
    } else if (!_autoDetectedVideoSource.isEmpty()) {
        _nameToMetaDataMap[videoSourceName]->setRawDefaultValue(_autoDetectedVideoSource);
    } else {
        _nameToMetaDataMap[videoSourceName]->setRawDefaultValue(videoDisabled);
    }
}

DECLARE_SETTINGSFACT(VideoSettings, aspectRatio)
DECLARE_SETTINGSFACT(VideoSettings, videoFit)
DECLARE_SETTINGSFACT(VideoSettings, gridLines)
DECLARE_SETTINGSFACT(VideoSettings, showRecControl)
DECLARE_SETTINGSFACT(VideoSettings, recordingFormat)
DECLARE_SETTINGSFACT(VideoSettings, maxVideoSize)
DECLARE_SETTINGSFACT(VideoSettings, enableStorageLimit)
DECLARE_SETTINGSFACT(VideoSettings, rtspTimeout)
DECLARE_SETTINGSFACT(VideoSettings, streamEnabled)
DECLARE_SETTINGSFACT(VideoSettings, disableWhenDisarmed)
DECLARE_SETTINGSFACT(VideoSettings, lowLatencyMode)
DECLARE_SETTINGSFACT(VideoSettings, cameraIso)
DECLARE_SETTINGSFACT(VideoSettings, cameraShutter)
DECLARE_SETTINGSFACT(VideoSettings, cameraExposure)
DECLARE_SETTINGSFACT(VideoSettings, cameraWhiteBalance)
DECLARE_SETTINGSFACT(VideoSettings, cameraFocusMode)
DECLARE_SETTINGSFACT(VideoSettings, cameraFocusValue)
DECLARE_SETTINGSFACT(VideoSettings, cameraBrightness)
DECLARE_SETTINGSFACT(VideoSettings, cameraContrast)
DECLARE_SETTINGSFACT(VideoSettings, cameraSaturation)
DECLARE_SETTINGSFACT(VideoSettings, cameraSharpness)
DECLARE_SETTINGSFACT(VideoSettings, cameraGamma)
DECLARE_SETTINGSFACT(VideoSettings, cameraColorTemperature)
DECLARE_SETTINGSFACT(VideoSettings, cameraColorProfile)

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, videoSource)
{
    if (!_videoSourceFact) {
        _videoSourceFact = _createSettingsFact(videoSourceName);
        const QString autoDetectedVideoSource = firstUvcCameraDescription();
        //-- Check for sources no longer available
        if(!_videoSourceFact->enumValues().contains(_videoSourceFact->rawValue().toString())) {
            if (!autoDetectedVideoSource.isEmpty()) {
                _videoSourceFact->setRawValue(autoDetectedVideoSource);
            } else if (_noVideo) {
                _videoSourceFact->setRawValue(videoSourceNoVideo);
            } else {
                _videoSourceFact->setRawValue(videoDisabled);
            }
        } else if (_videoSourceFact->rawValue().toString() == videoDisabled && !autoDetectedVideoSource.isEmpty()) {
            _videoSourceFact->setRawValue(autoDetectedVideoSource);
        }
        connect(_videoSourceFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _videoSourceFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, forceVideoDecoder)
{
    if (!_forceVideoDecoderFact) {
        _forceVideoDecoderFact = _createSettingsFact(forceVideoDecoderName);

        _forceVideoDecoderFact->setVisible(
#ifdef QGC_GST_STREAMING
            true
#else
            false
#endif
        );

        connect(_forceVideoDecoderFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _forceVideoDecoderFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, udpPort)
{
    if (!_udpPortFact) {
        _udpPortFact = _createSettingsFact(udpPortName);
        connect(_udpPortFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _udpPortFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, rtspUrl)
{
    if (!_rtspUrlFact) {
        _rtspUrlFact = _createSettingsFact(rtspUrlName);
        connect(_rtspUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _rtspUrlFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, tcpUrl)
{
    if (!_tcpUrlFact) {
        _tcpUrlFact = _createSettingsFact(tcpUrlName);
        connect(_tcpUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _tcpUrlFact;
}

bool VideoSettings::streamConfigured(void)
{
    //-- First, check if it's autoconfigured
    if(qgcApp()->toolbox()->videoManager()->autoStreamConfigured()) {
        qCDebug(VideoManagerLog) << "Stream auto configured";
        return true;
    }
    //-- Check if it's disabled
    QString vSource = videoSource()->rawValue().toString();
    if(vSource == videoSourceNoVideo || vSource == videoDisabled) {
        return false;
    }
    //-- If UDP, check if port is set
    if(vSource == videoSourceUDPH264 || vSource == videoSourceUDPH265) {
        qCDebug(VideoManagerLog) << "Testing configuration for UDP Stream:" << udpPort()->rawValue().toInt();
        //return udpPort()->rawValue().toInt() != 0;
        return true;
    }
    //-- If RTSP, check for URL
    if(vSource == videoSourceRTSP) {
        qCDebug(VideoManagerLog) << "Testing configuration for RTSP Stream:" << rtspUrl()->rawValue().toString();
        return true;//return !rtspUrl()->rawValue().toString().isEmpty();
    }
    //-- If TCP, check for URL
    if(vSource == videoSourceTCP) {
        qCDebug(VideoManagerLog) << "Testing configuration for TCP Stream:" << tcpUrl()->rawValue().toString();
        return true;//return !tcpUrl()->rawValue().toString().isEmpty();
    }
    //-- If MPEG-TS, check if port is set
    if(vSource == videoSourceMPEGTS) {
        qCDebug(VideoManagerLog) << "Testing configuration for MPEG-TS Stream:" << udpPort()->rawValue().toInt();
        return true;//return udpPort()->rawValue().toInt() != 0;
    }
    //-- If Herelink Air unit, good to go
    if(vSource == videoSourceHerelinkAirUnit) {
        qCDebug(VideoManagerLog) << "Stream configured for Herelink Air Unit";
        return true;
    }
    //-- If Herelink Hotspot, good to go
    if(vSource == videoSourceHerelinkHotspot) {
        qCDebug(VideoManagerLog) << "Stream configured for Herelink Hotspot";
        return true;
    }
#ifndef QGC_DISABLE_UVC
    const QList<QCameraDevice> videoInputs = QMediaDevices::videoInputs();
    for (const auto& cameraDevice: videoInputs) {
        if(vSource == cameraDevice.description()) {
            qCDebug(VideoManagerLog) << "Stream configured for UVC";
            return true;
        }
    }
#endif
    return false;
}

void VideoSettings::_configChanged(QVariant)
{
    emit streamConfiguredChanged(streamConfigured());
}
