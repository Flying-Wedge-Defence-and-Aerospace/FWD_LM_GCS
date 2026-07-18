#pragma once

#include <QObject>
#include <QStringList>

class IconProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList iconNames READ iconNames CONSTANT)

public:
    explicit IconProvider(QObject* parent = nullptr);

    QStringList iconNames() const;

private:
    QStringList _iconNames;
};
