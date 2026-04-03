/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "BluetoothLink.h"
#include "DeviceInfo.h"
#include "QGCApplication.h"

#include <QBluetoothLocalDevice>
#include <QtBluetooth/QBluetoothDeviceDiscoveryAgent>
#include <QtBluetooth/QBluetoothSocket>
#include <QtBluetooth/QBluetoothServiceInfo>


#include <QTimer>
#include <QtPositioning/QGeoPositionInfoSource>  // For location check

#ifdef Q_OS_IOS
#include <QtBluetooth/QBluetoothServiceDiscoveryAgent>
#else
#include <QtBluetooth/QBluetoothUuid>
#endif

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#endif




// #include <QAndroidJniObject>
// #include <QtAndroid>

BluetoothLink::BluetoothLink(SharedLinkConfigurationPtr& config)
    : LinkInterface(config)
    , _bluetoothConfig(qobject_cast<BluetoothConfiguration*>(config.get()))
{
    qRegisterMetaType<QBluetoothSocket::SocketError>();
    qRegisterMetaType<QBluetoothServiceInfo>();
}

// BluetoothLink::~BluetoothLink()
// {
//     disconnect();
// #ifdef Q_OS_IOS
//     if(_discoveryAgent) {
//         _shutDown = true;
//         _discoveryAgent->stop();
//         _discoveryAgent->deleteLater();
//         _discoveryAgent = nullptr;
//     }
// #endif
// }

BluetoothLink::~BluetoothLink()
{
    // Ensure proper cleanup in destructor
    if(_targetSocket) {
        QObject::disconnect(_targetSocket, nullptr, nullptr, nullptr);
        // Use fully qualified enum
        if(_targetSocket->state() != QBluetoothSocket::SocketState::UnconnectedState) {
            _targetSocket->disconnectFromService();
        }
        _targetSocket->close();
        delete _targetSocket;
        _targetSocket = nullptr;
    }

#ifdef Q_OS_IOS
    if(_discoveryAgent) {
        _shutDown = true;
        _discoveryAgent->stop();
        _discoveryAgent->deleteLater();
        _discoveryAgent = nullptr;
    }
#endif
}

void BluetoothLink::run()
{

}

// void BluetoothLink::_writeBytes(const QByteArray &bytes)
// {
//     if (_targetSocket) {
//         if(_targetSocket->write(bytes) > 0) {
//             emit bytesSent(this, bytes);
//         } else {
//             qWarning() << "Bluetooth write error";
//         }
//     }
// }


void BluetoothLink::_writeBytes(const QByteArray &bytes)
{
    if (_targetSocket && _targetSocket->state() == QBluetoothSocket::SocketState::ConnectedState) {
        qint64 bytesWritten = _targetSocket->write(bytes);
        if(bytesWritten > 0) {
            emit bytesSent(this, bytes);
        } else {
            qWarning() << "Bluetooth write error, bytes written:" << bytesWritten;
        }
    } else {
        qWarning() << "Cannot write - socket not connected. State:" << (_targetSocket ? static_cast<int>(_targetSocket->state()) : -1);
    }
}

void BluetoothLink::readBytes()
{
    if (_targetSocket) {
        while (_targetSocket->bytesAvailable() > 0) {
            QByteArray datagram;
            datagram.resize(_targetSocket->bytesAvailable());
            _targetSocket->read(datagram.data(), datagram.size());
            emit bytesReceived(this, datagram);
        }
    }
}

// void BluetoothLink::disconnect(void)
// {
// #ifdef Q_OS_IOS
//     if(_discoveryAgent) {
//         _shutDown = true;
//         _discoveryAgent->stop();
//         _discoveryAgent->deleteLater();
//         _discoveryAgent = nullptr;
//     }
// #endif
//     if(_targetSocket) {
//         // This prevents stale signals from calling the link after it has been deleted
//         QObject::disconnect(_targetSocket, &QBluetoothSocket::readyRead, this, &BluetoothLink::readBytes);
//         _targetSocket->deleteLater();
//         _targetSocket = nullptr;
//         emit disconnected();
//     }
//     _connectState = false;
// }


void BluetoothLink::disconnect(void)
{
#ifdef Q_OS_IOS
    if(_discoveryAgent) {
        _shutDown = true;
        _discoveryAgent->stop();
        _discoveryAgent->deleteLater();
        _discoveryAgent = nullptr;
    }
#endif

    if(_targetSocket) {
        // Disconnect all signals first
        QObject::disconnect(_targetSocket, nullptr, nullptr, nullptr);

        // Proper socket cleanup - use fully qualified enum
        if(_targetSocket->state() != QBluetoothSocket::SocketState::UnconnectedState) {
            _targetSocket->disconnectFromService();
        }

        // Close and delete immediately
        _targetSocket->close();
        delete _targetSocket;
        _targetSocket = nullptr;

        qDebug() << "Bluetooth socket properly closed";
        emit disconnected();
    }
    _connectState = false;
}


bool BluetoothLink::_connect(void)
{
    qDebug() << "BluetoothLink.cc _connect method";

    // Don't connect if already connected
    if (isConnected()) {
        qWarning() << "BluetoothLink: already connected, ignoring connect call";
        return true;
    }

    return _hardwareConnect();
}

bool BluetoothLink:: _hardwareConnect()
{

    // Prevent multiple simultaneous connect attempts
    if (_isConnecting) {
        qWarning() << "BluetoothLink: connect already in progress, ignoring duplicate call";
        return false;
    }

    _isConnecting = true;

#ifdef Q_OS_IOS
    if (_discoveryAgent) {
        _shutDown = true;
        _discoveryAgent->stop();
        _discoveryAgent->deleteLater();
        _discoveryAgent = nullptr;
    }
    _discoveryAgent = new QBluetoothServiceDiscoveryAgent(this);
    QObject::connect(_discoveryAgent, &QBluetoothServiceDiscoveryAgent::serviceDiscovered,
                     this, &BluetoothLink::serviceDiscovered);
    QObject::connect(_discoveryAgent, &QBluetoothServiceDiscoveryAgent::finished,
                     this, &BluetoothLink::discoveryFinished);
    QObject::connect(_discoveryAgent, &QBluetoothServiceDiscoveryAgent::canceled,
                     this, &BluetoothLink::discoveryFinished);
    _shutDown = false;
    _discoveryAgent->start();

#else

    qDebug() << "BluetoothLink.cc _hardwareConnect";

    QBluetoothLocalDevice localDevice;

    if (localDevice.hostMode() == QBluetoothLocalDevice::HostPoweredOff) {
        qWarning() << "BluetoothLink: Bluetooth is OFF, aborting connect";
        // emit communicationError(_bluetoothConfig->name(),
        //                         tr("Bluetooth is turned OFF. Please enable Bluetooth and try again."));
        //emit disconnected();  // clean up link state
        return false;
    }

    _createSocket();

    // Guard: if socket creation failed for any reason, bail out
    if (!_targetSocket) {
        qWarning() << "BluetoothLink: socket creation failed, aborting connect";
        _isConnecting = false;
        return false;
    }

    _connectAttempt = 0;  // reset retry counter for this connection attempt
    _attemptConnect();    // start first attempt

#endif
    return true;
}

// Add this new method to handle retry logic
void BluetoothLink::_attemptConnect()
{
    const int maxRetries = 2;

    // Critical: check socket is still valid before using it
    // It may have been destroyed if disconnect was called during the delay
    if (!_targetSocket) {
        _isConnecting = false;
        qWarning() << "BluetoothLink: socket is null at connect attempt" << _connectAttempt;
        return;
    }

    if (_connectAttempt >= maxRetries) {
        _isConnecting = false;
        qWarning() << "BluetoothLink: all" << maxRetries << "connect attempts failed";
        emit communicationError(_bluetoothConfig->name(), tr("Bluetooth connect failed after retries"));

        // Critical: emit disconnected so LinkManager._linkDisconnected fires
        // This ensures config->setLink(nullptr) gets called
        emit disconnected();
        return;
    }

    _connectAttempt++;
    qDebug() << "BluetoothLink: connect attempt" << _connectAttempt << "of" << maxRetries;

    // Disconnect errorOccurred temporarily to handle it here for retry logic
    QObject::disconnect(_targetSocket, &QBluetoothSocket::errorOccurred,
                        this, &BluetoothLink::deviceError);

    // Connect a one-shot error handler for retry
    QObject::connect(_targetSocket, &QBluetoothSocket::errorOccurred, this,
                     [this](QBluetoothSocket::SocketError error) {
                         qWarning() << "BluetoothLink: connect error on attempt"
                                    << _connectAttempt << ":" << error;

                         // Disconnect this temporary handler
                         QObject::disconnect(_targetSocket, &QBluetoothSocket::errorOccurred,
                                             this, nullptr);

                         // Reconnect the permanent error handler
                         QObject::connect(_targetSocket, &QBluetoothSocket::errorOccurred,
                                          this, &BluetoothLink::deviceError);

                         // Wait 1 second then retry
                         QTimer::singleShot(1000, this, &BluetoothLink::_attemptConnect);
                     });

    QTimer::singleShot(2500, this, [this]() {
        // Re-check socket validity inside the lambda — 2500ms is a long time
        if (!_targetSocket) {
            qWarning() << "BluetoothLink: socket destroyed before connect lambda ran";
            return;
        }

        // Only attempt if socket is in a connectable state
        if (_targetSocket->state() != QBluetoothSocket::SocketState::UnconnectedState) {
            qWarning() << "BluetoothLink: socket not in UnconnectedState, state ="
                       << _targetSocket->state();
            return;
        }

        qDebug() << "Attempting Bluetooth connect to service after delay... attempt" << _connectAttempt;
        _targetSocket->connectToService(
            QBluetoothAddress(_bluetoothConfig->device().address),
            QBluetoothUuid(QBluetoothUuid::ServiceClassUuid::SerialPort)
            );
    });
}


// void BluetoothLink::_createSocket()
// {
//     if(_targetSocket)
//     {
//         delete _targetSocket;
//         _targetSocket = nullptr;
//     }
//     _targetSocket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol, this);

//     qDebug()<< "BluetoothLink.cc _createSocket : " << _targetSocket ;

//     QObject::connect(_targetSocket, &QBluetoothSocket::connected, this, &BluetoothLink::deviceConnected);

//     QObject::connect(_targetSocket, &QBluetoothSocket::readyRead, this, &BluetoothLink::readBytes);
//     QObject::connect(_targetSocket, &QBluetoothSocket::disconnected, this, &BluetoothLink::deviceDisconnected);

//     QObject::connect(_targetSocket, &QBluetoothSocket::errorOccurred, this, &BluetoothLink::deviceError);
// }

void BluetoothLink::_createSocket()
{
    if (_targetSocket) {
        // Disconnect ALL signals first to prevent callbacks firing during cleanup
        QObject::disconnect(_targetSocket, nullptr, nullptr, nullptr);

        // abort() is synchronous unlike disconnectFromService()
        // Safe to delete immediately after abort()
        _targetSocket->abort();

        //_targetSocket->deleteLater();  // safer than delete — Qt cleans up after event loop

        // Wait for socket to reach unconnected state before deleting
        // This prevents the input stream thread from reading corrupted memory
        if (_targetSocket->state() != QBluetoothSocket::SocketState::UnconnectedState) {
            QEventLoop loop;
            QObject::connect(_targetSocket,
                             &QBluetoothSocket::disconnected,
                             &loop, &QEventLoop::quit);
            QTimer::singleShot(1000, &loop, &QEventLoop::quit); // safety timeout
            loop.exec();
        }

        delete _targetSocket;  // safe to delete now — IO has stopped

        _targetSocket = nullptr;
    }

    _targetSocket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol, this);
    qDebug() << "BluetoothLink.cc _createSocket : " << _targetSocket;

    QObject::connect(_targetSocket, &QBluetoothSocket::connected,
                     this, &BluetoothLink::deviceConnected);
    QObject::connect(_targetSocket, &QBluetoothSocket::readyRead,
                     this, &BluetoothLink::readBytes);
    QObject::connect(_targetSocket, &QBluetoothSocket::disconnected,
                     this, &BluetoothLink::deviceDisconnected);
    QObject::connect(_targetSocket, &QBluetoothSocket::errorOccurred,
                     this, &BluetoothLink::deviceError);
}

#ifdef Q_OS_IOS
void BluetoothLink::serviceDiscovered(const QBluetoothServiceInfo& info)
{
    if(!info.device().name().isEmpty() && !_targetSocket)
    {
        if(_bluetoothConfig->device().uuid == info.device().deviceUuid() && _bluetoothConfig->device().name == info.device().name())
        {
            _createSocket();
            _targetSocket->connectToService(info);
        }
    }
}
#endif

#ifdef Q_OS_IOS
void BluetoothLink::discoveryFinished()
{
    if(_discoveryAgent && !_shutDown)
    {
        _shutDown = true;
        _discoveryAgent->deleteLater();
        _discoveryAgent = nullptr;
        if(!_targetSocket)
        {
            _connectState = false;
            emit communicationError("Could not locate Bluetooth device:", _bluetoothConfig->device().name);
        }
    }
}
#endif

// void BluetoothLink::deviceConnected()
// {
//     _connectState = true;
//     emit connected();
//     qDebug()<< "Bluetooth Connected";
// }

void BluetoothLink::deviceConnected()
{
    if(_targetSocket && _targetSocket->state() == QBluetoothSocket::SocketState::ConnectedState) {
        _isConnecting = false;
        _connectState = true;
        qDebug() << "Bluetooth Connected to device";

        // Save this as the last successfully connected device
        QSettings settings;
        settings.setValue("LastConnectedBluetoothDevice", _bluetoothConfig->name());

        emit connected();
        //qgcApp()->showAppMessage("Bluetooth Connected to device");

    }
}

void BluetoothLink::deviceDisconnected()
{
    _connectState = false;
    qWarning() << "Bluetooth disconnected";
}

// void BluetoothLink::deviceError(QBluetoothSocket::SocketError error)
// {
//     _connectState = false;
//     qWarning() << "Bluetooth error" << error;
//     emit communicationError(tr("Bluetooth Link Error"), _targetSocket->errorString());
// }

void BluetoothLink::deviceError(QBluetoothSocket::SocketError error)
{
    _connectState = false;

    QString errorString;
    switch(error) {
    case QBluetoothSocket::SocketError::UnknownSocketError:
        errorString = "Unknown Socket Error";
        break;
    case QBluetoothSocket::SocketError::HostNotFoundError:
        errorString = "Host Not Found";
        break;
    case QBluetoothSocket::SocketError::ServiceNotFoundError:
        errorString = "Service Not Found";
        break;
    case QBluetoothSocket::SocketError::NetworkError:
        errorString = "Network Error";
        break;
    case QBluetoothSocket::SocketError::UnsupportedProtocolError:
        errorString = "Unsupported Protocol";
        break;
    case QBluetoothSocket::SocketError::MissingPermissionsError:
        errorString = "Missing Bluetooth Permissions";
        break;
    default:
        errorString = QString("Error Code: %1").arg(static_cast<int>(error));
    }

    qWarning() << "Bluetooth error:" << errorString;

    // Clean up the socket on error
    if(_targetSocket) {
        QObject::disconnect(_targetSocket, nullptr, nullptr, nullptr);
        _targetSocket->close();
        _targetSocket->deleteLater();
        _targetSocket = nullptr;
    }

    emit communicationError(tr("Bluetooth Link Error"), errorString);
}

bool BluetoothLink::isConnected() const
{
    return _connectState;
}

//--------------------------------------------------------------------------
//-- BluetoothConfiguration

BluetoothConfiguration::BluetoothConfiguration(const QString & name)
    : LinkConfiguration(name)
    , _deviceDiscover(nullptr)
{

}

BluetoothConfiguration::BluetoothConfiguration(const BluetoothConfiguration * source)
    : LinkConfiguration(source)
    , _deviceDiscover(nullptr)
    , _device(source->device())
{

}

BluetoothConfiguration::~BluetoothConfiguration()
{

    if(_deviceDiscover)
    {
        _deviceDiscover->stop();
        delete _deviceDiscover;
    }
}

QString BluetoothConfiguration::settingsTitle()
{
    if(QGCDeviceInfo::isBluetoothAvailable()) {
        return tr("Bluetooth Link Settings");
    } else {
        return tr("Bluetooth Not Available");
    }
}

void BluetoothConfiguration::copyFrom(const LinkConfiguration *source)
{
    LinkConfiguration::copyFrom(source);
    const BluetoothConfiguration * const usource = qobject_cast<const BluetoothConfiguration*>(source);
    Q_ASSERT(usource != nullptr);
    _device = usource->device();
}

void BluetoothConfiguration::saveSettings(QSettings& settings, const QString& root)
{
    settings.beginGroup(root);
    settings.setValue("deviceName", _device.name);
#ifdef Q_OS_IOS
    settings.setValue("uuid", _device.uuid.toString());
#else
    settings.setValue("address",_device.address);
#endif
    settings.endGroup();
}

void BluetoothConfiguration::loadSettings(QSettings& settings, const QString& root)
{
    settings.beginGroup(root);
    _device.name    = settings.value("deviceName", _device.name).toString();
#ifdef Q_OS_IOS
    QString suuid   = settings.value("uuid", _device.uuid.toString()).toString();
    _device.uuid    = QUuid(suuid);
#else
    _device.address = settings.value("address", _device.address).toString();
#endif
    settings.endGroup();
}

void BluetoothConfiguration::stopScan()
{
    if(_deviceDiscover)
    {
        _deviceDiscover->stop();
        _deviceDiscover->deleteLater();
        _deviceDiscover = nullptr;
        emit scanningChanged();
    }
}

// void BluetoothConfiguration::startScan()
// {

// #ifdef Q_OS_ANDROID
//     // Check Location
//     if (!_isLocationEnabled()) {
//         qDebug() << "Please turn ON Location to scan Bluetooth devices";
//         emit showToast(tr("Please turn ON Location to scan Bluetooth devices"));
//         return;
//     }
// #endif

//     // Check Bluetooth
//     QBluetoothLocalDevice localDevice;

//     if (localDevice.hostMode() == QBluetoothLocalDevice::HostPoweredOff) {
//         qDebug() << "Bluetooth is OFF. Requesting system to turn it ON...";
//         localDevice.powerOn();
//         return;
//     }

//     // Start scan
//     if(!_deviceDiscover) {
//         _deviceDiscover = new QBluetoothDeviceDiscoveryAgent(this);
//         connect(_deviceDiscover, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,  this, &BluetoothConfiguration::deviceDiscovered);
//         connect(_deviceDiscover, &QBluetoothDeviceDiscoveryAgent::finished,          this, &BluetoothConfiguration::doneScanning);
//         emit scanningChanged();
//     } else {
//         _deviceDiscover->stop();
//     }

//     _nameList.clear();
//     _deviceList.clear();
//     emit nameListChanged();
//     _deviceDiscover->start();
// }

void BluetoothConfiguration::startScan()
{
#ifdef Q_OS_ANDROID
    if (!_isLocationEnabled()) {
        qDebug() << "Please turn ON Location to scan Bluetooth devices";
        emit showToast(tr("Please turn ON Location to scan Bluetooth devices"));
        return;
    }
#endif

    QBluetoothLocalDevice localDevice;
    if (localDevice.hostMode() == QBluetoothLocalDevice::HostPoweredOff) {
        qDebug() << "Bluetooth is OFF. Requesting system to turn it ON...";
        localDevice.powerOn();
        return;
    }

    // Always clear lists before new scan
    _nameList.clear();
    _deviceList.clear();
    emit nameListChanged();

    // Recreate discovery agent each scan to avoid stale cache
    if (_deviceDiscover) {
        _deviceDiscover->stop();
        delete _deviceDiscover;
        _deviceDiscover = nullptr;
    }

    _deviceDiscover = new QBluetoothDeviceDiscoveryAgent(this);
    connect(_deviceDiscover, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &BluetoothConfiguration::deviceDiscovered);
    connect(_deviceDiscover, &QBluetoothDeviceDiscoveryAgent::finished,
            this, &BluetoothConfiguration::doneScanning);
    emit scanningChanged();

    _deviceDiscover->start();
}


bool BluetoothConfiguration:: _isLocationEnabled()
{
#ifdef Q_OS_ANDROID
    QJniObject context =
        QJniObject::callStaticObjectMethod(
            "org/qtproject/qt/android/QtNative",
            "getContext",
            "()Landroid/content/Context;");

    if (!context.isValid())
        return false;

    QJniObject locationService =
        context.callObjectMethod(
            "getSystemService",
            "(Ljava/lang/String;)Ljava/lang/Object;",
            QJniObject::fromString("location").object<jstring>());

    if (!locationService.isValid())
        return false;

    jboolean enabled =
        locationService.callMethod<jboolean>(
            "isLocationEnabled",
            "()Z");

    return enabled;
#else
    return true;
#endif
}

bool BluetoothConfiguration::isBluetoothAvailable()
{
    QBluetoothLocalDevice localDevice;
    if (localDevice.hostMode() == QBluetoothLocalDevice::HostPoweredOff) {
        emit showToast(tr("Please turn ON Bluetooth"));
        return false;
    }

#ifdef Q_OS_ANDROID
    if (!_isLocationEnabled()) {
        emit showToast(tr("Please turn ON Location to use Bluetooth"));
        return false;
    }
#endif

    return true;
}



// void BluetoothConfiguration::deviceDiscovered(QBluetoothDeviceInfo info)
// {
//     if(!info.name().isEmpty() && info.isValid())
//     {
// #if 0
//         qDebug() << "Name:           " << info.name();
//         qDebug() << "Address:        " << info.address().toString();
//         qDebug() << "Service Classes:" << info.serviceClasses();
//         QList<QBluetoothUuid> uuids = info.serviceUuids();
//         for (QBluetoothUuid uuid: uuids) {
//             qDebug() << "Service UUID:   " << uuid.toString();
//         }
// #endif
//         BluetoothData data;
//         data.name    = info.name();
// #ifdef Q_OS_IOS
//         data.uuid    = info.deviceUuid();
// #else
//         data.address = info.address().toString();
// #endif
//         if(!_deviceList.contains(data))
//         {
//             _deviceList += data;
//             _nameList   += data.name;
//             emit nameListChanged();
//             return;
//         }
//     }
// }

void BluetoothConfiguration::deviceDiscovered(QBluetoothDeviceInfo info)
{
    if (!info.name().isEmpty() && info.isValid()) {
        BluetoothData data;
        data.name    = info.name().trimmed();  // trim whitespace
#ifdef Q_OS_IOS
        data.uuid    = info.deviceUuid();
#else
        data.address = info.address().toString();
#endif

// Skip devices with empty address on Android
// These are malformed discovery packets
#ifndef Q_OS_IOS
        if (data.address.isEmpty()) {
            return;
        }
#endif

        if (!_deviceList.contains(data)) {
            _deviceList += data;
            _nameList   += data.name;
            emit nameListChanged();
        }
        // Removed the return statement — it was inside the if block anyway,
        // having it there was redundant and confusing
    }
}

void BluetoothConfiguration::doneScanning()
{
    if(_deviceDiscover)
    {
        deleteLater();
        _deviceDiscover = nullptr;
        emit scanningChanged();
    }
}


void BluetoothConfiguration::setDevName(const QString &name)
{
    QString trimmedName = name.trimmed();
    for (const BluetoothData& data : _deviceList) {
        if (data.name == trimmedName) {
            _device = data;
            emit devNameChanged();
#ifndef Q_OS_IOS
            emit addressChanged();
#endif
            return;
        }
    }
}


QString BluetoothConfiguration::address() const
{
#ifdef Q_OS_IOS
    return {};
#else
    return _device.address;
#endif
}
