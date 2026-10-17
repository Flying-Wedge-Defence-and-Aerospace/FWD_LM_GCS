/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "GoogleDriveSettings.h"

#include <QQmlEngine>
#include <QtQml>

DECLARE_SETTINGGROUP(GoogleDrive, "GoogleDrive")
{
    qmlRegisterUncreatableType<GoogleDriveSettings>("QGroundControl.SettingsManager", 1, 0, "GoogleDriveSettings", "Reference only");
}

DECLARE_SETTINGSFACT(GoogleDriveSettings, enabled)
DECLARE_SETTINGSFACT(GoogleDriveSettings, autoLogUpload)
DECLARE_SETTINGSFACT(GoogleDriveSettings, folderName)
DECLARE_SETTINGSFACT(GoogleDriveSettings, clientId)
DECLARE_SETTINGSFACT(GoogleDriveSettings, clientSecret)
