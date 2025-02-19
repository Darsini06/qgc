#include "bluetooth_class.h"
#include <QBluetoothPermission>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QCoreApplication>
#include <QDebug>

MyClass::MyClass(QObject *parent) : QObject(parent) {}

void MyClass::requestBluetoothPermission() {
#ifdef Q_OS_ANDROID
    QBluetoothPermission permission;

    switch (qApp->checkPermission(permission)) {
    case Qt::PermissionStatus::Granted:
        qDebug() << "Bluetooth permission already granted.";
        emit bluetoothStatusChanged(true);
        break;

    case Qt::PermissionStatus::Undetermined:
        qApp->requestPermission(permission, this, [this](const QPermission &perm) {
            bool granted = (perm.status() == Qt::PermissionStatus::Granted);
            qDebug() << (granted ? "Bluetooth permission granted." : "Bluetooth permission denied.");
            emit bluetoothStatusChanged(granted);
        });
        break;

    default:
        qDebug() << "Bluetooth permission denied.";
        emit bluetoothStatusChanged(false);
        break;
    }
#else
    qDebug() << "Bluetooth permission check not supported on this platform.";
    emit bluetoothStatusChanged(true); // Assuming desktop platforms don't need permission
#endif
}
