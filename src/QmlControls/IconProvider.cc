#include "IconProvider.h"
#include <QDir>

IconProvider::IconProvider(QObject* parent)
    : QObject(parent)
{
    // SAME mechanism QGC uses in FactValueGrid
    QDir iconDir(":/InstrumentValueIcons");
    _iconNames = iconDir.entryList(QStringList() << "*.svg", QDir::Files);
}

QStringList IconProvider::iconNames() const
{
    return _iconNames;
}
