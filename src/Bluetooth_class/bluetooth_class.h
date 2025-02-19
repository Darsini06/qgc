#ifndef BLUETOOTH_CLASS_H
#define BLUETOOTH_CLASS_H

#include <QObject>
#include <QPermission>

class MyClass : public QObject {
    Q_OBJECT
public:
    explicit MyClass(QObject *parent = nullptr); // Constructor
    Q_INVOKABLE void requestBluetoothPermission(); // Call from QML

signals:
    void bluetoothStatusChanged(bool granted);
};

#endif // BLUETOOTH_CLASS_H
