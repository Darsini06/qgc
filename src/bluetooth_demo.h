#ifndef BLUETOOTH_DEMO_H
#define BLUETOOTH_DEMO_H

#include <QObject>

class Bluetooth_demo : public QObject
{
    Q_OBJECT
public:
    explicit Bluetooth_demo(QObject *parent = nullptr);

signals:
};

#endif // BLUETOOTH_DEMO_H
