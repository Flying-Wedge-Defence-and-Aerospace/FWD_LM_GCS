/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "SettingsGroup.h"

class GoogleDriveSettings : public SettingsGroup
{
    Q_OBJECT
public:
    GoogleDriveSettings(QObject* parent = nullptr);
    DEFINE_SETTING_NAME_GROUP()

    DEFINE_SETTINGFACT(enabled)
    DEFINE_SETTINGFACT(autoLogUpload)
    DEFINE_SETTINGFACT(folderName)
    DEFINE_SETTINGFACT(clientId)
    DEFINE_SETTINGFACT(clientSecret)
};
