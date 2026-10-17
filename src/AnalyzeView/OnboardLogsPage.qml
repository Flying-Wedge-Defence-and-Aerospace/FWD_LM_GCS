/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick              2.3
import QtQuick.Controls     1.2
import QtQuick.Dialogs      1.2
import QtQuick.Layouts      1.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

AnalyzePage {
    id:                 onboardLogsPage
    pageComponent:      pageComponent
    pageDescription:    qsTr("Onboard Logs allows you to download binary log files stored on the vehicle. Click Refresh to get list of available logs.")

    // Persistent log download controller owned by the QGCToolbox
    readonly property var logController:            QGroundControl.logDownloadController
    // Google Drive upload manager (may be inert until credentials are configured)
    readonly property var driveManager:             QGroundControl.googleDriveManager

    readonly property color _accent:                "#3B82F6"
    readonly property real  _margin:                ScreenTools.defaultFontPixelWidth
    readonly property real  _minCardWidth:          ScreenTools.defaultFontPixelWidth * 17

    property int _selectedCount: 0

    QGCPalette { id: palette; colorGroupEnabled: enabled }

    Component.onCompleted: _recountSelection()

    Connections {
        target: logController
        onSelectionChanged: onboardLogsPage._recountSelection()
        onModelChanged:     onboardLogsPage._recountSelection()
        onAutoDownloadFinished: {
            onboardLogsPage._recountSelection()
            if (downloaded > 0 || failed > 0) {
                var msg = qsTr("Automatic log download complete: %1 downloaded, %2 failed, %3 skipped.").arg(downloaded).arg(failed).arg(skipped)
                mainWindow.showMessageDialog(qsTr("Automatic Log Download"), msg)
            }
        }
    }

    Connections {
        target: logController.model
        onCountChanged: onboardLogsPage._recountSelection()
    }

    function _recountSelection() {
        var n = 0
        if (logController && logController.model) {
            for (var i = 0; i < logController.model.count; i++) {
                var o = logController.model.get(i)
                if (o && o.selected) {
                    n++
                }
            }
        }
        _selectedCount = n
    }

    function _busy() {
        return logController.requestingList || logController.downloadingLogs
    }

    function _dateText(o) {
        if (!o) {
            return ""
        }
        if (o.received && o.time && o.time.getFullYear() >= 2010) {
            return o.time.toLocaleString(undefined, "short")
        }
        return qsTr("Date Unknown")
    }

    function _statusText(o) {
        return o && o.status ? o.status : ""
    }

    function _statusColor(o) {
        if (!o) {
            return palette.button
        }
        var s = o.status ? o.status.toString().toLowerCase() : ""
        if (s.indexOf("fail") >= 0 || s.indexOf("error") >= 0) {
            return palette.colorRed
        }
        if (s.indexOf("/s") >= 0) {
            return _accent
        }
        if (s.indexOf("pending") >= 0) {
            return palette.colorOrange
        }
        return palette.colorGreen
    }

    function _actionEnabled(action) {
        if (action === "cancel") {
            return logController.requestingList || logController.downloadingLogs
        }
        if (_busy()) {
            return false
        }
        switch (action) {
        case "refresh":  return true
        case "download": return _selectedCount > 0
        case "erase":    return logController.model.count > 0
        }
        return false
    }

    function _actionTriggered(action) {
        switch (action) {
        case "refresh":  _refresh();  break
        case "download": _download(); break
        case "erase":    _erase();    break
        case "cancel":   logController.cancel(); break
        }
    }

    function _refresh() {
        if (!QGroundControl.multiVehicleManager.activeVehicle || QGroundControl.multiVehicleManager.activeVehicle.isOfflineEditingVehicle) {
            mainWindow.showMessageDialog(qsTr("Log Refresh"), qsTr("You must be connected to a vehicle in order to download logs."))
        } else {
            logController.refresh()
        }
    }

    function _download() {
        if (!QGroundControl.multiVehicleManager.activeVehicle || QGroundControl.multiVehicleManager.activeVehicle.isOfflineEditingVehicle) {
            mainWindow.showMessageDialog(qsTr("Download and Upload"), qsTr("You must be connected to a vehicle in order to download logs."))
            return
        }
        if (!driveManager.linked) {
            mainWindow.showMessageDialog(qsTr("Upload to Google Drive"),
                qsTr("Google Drive is still initializing—try again in a moment."))
            return
        }
        // Download the selected logs to the default directory; each completed
        // download is then auto-uploaded to Google Drive.
        logController.download()
    }

    function _erase() {
        mainWindow.showMessageDialog(qsTr("Delete All Log Files"),
                                     qsTr("All log files will be erased permanently. Is this really what you want?"),
                                     StandardButton.Yes | StandardButton.No,
                                     function() { logController.eraseAll() })
    }

    Component {
        id: pageComponent

        ColumnLayout {
            width:  availableWidth
            height: availableHeight
            spacing: _margin

            //-----------------------------------------------------------------
            // Toolbar
            Rectangle {
                Layout.fillWidth:   true
                implicitHeight:     toolbarRow.implicitHeight + _margin * 2
                radius:             10
                color:              palette.windowShade

                RowLayout {
                    id:                 toolbarRow
                    anchors.fill:       parent
                    anchors.margins:    _margin
                    spacing:            _margin

                    QGCLabel {
                        text:               qsTr("Onboard Logs")
                        font.bold:          true
                        font.pointSize:     ScreenTools.defaultFontPointSize + 2
                    }

                    QGCLabel {
                        text:               logController.model.count === 1 ? qsTr("1 log on vehicle")
                                                                           : qsTr("%1 logs on vehicle").arg(logController.model.count)
                        color:              palette.buttonText
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: _margin

                        Repeater {
                    model: [
                        { label: qsTr("Refresh"),  action: "refresh"  },
                        { label: qsTr("Download and Upload"), action: "download" },
                        { label: qsTr("Erase All"),action: "erase"    },
                        { label: qsTr("Cancel"),   action: "cancel"   }
                    ]

                            delegate: Rectangle {
                                id:                     actionButton
                                property bool _enabled: onboardLogsPage._actionEnabled(modelData.action)
                                property bool _primary: modelData.action === "download"

                                width:              actionLabel.implicitWidth + _margin * 2.4
                                height:             actionLabel.implicitHeight + _margin * 1.6
                                radius:             height / 2
                                opacity:            _enabled ? 1.0 : 0.4
                                color:              _primary
                                                        ? (actionMouse.pressed ? Qt.darker(onboardLogsPage._accent, 1.2) : onboardLogsPage._accent)
                                                        : (actionMouse.pressed ? palette.windowShadeDark : palette.windowShade)
                                border.width:       _primary ? 0 : 1
                                border.color:       palette.button

                                QGCLabel {
                                    id:                 actionLabel
                                    anchors.centerIn:   parent
                                    text:               modelData.label
                                    color:              actionButton._primary ? "white" : palette.buttonText
                                }

                                MouseArea {
                                    id:                 actionMouse
                                    anchors.fill:       parent
                                    enabled:            actionButton._enabled
                                    onClicked:          onboardLogsPage._actionTriggered(modelData.action)
                                }
                            }
                        }
                    // No sign-in chrome: authentication uses the provisioned refresh token.
                }
                }
            }

            //-----------------------------------------------------------------
            // Auto download banner
            Rectangle {
                Layout.fillWidth:   true
                visible:            logController.autoDownloadActive
                implicitHeight:     bannerLabel.implicitHeight + _margin
                radius:             8
                color:              palette.alertBackground

                QGCLabel {
                    id:                 bannerLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Automatically downloading new onboard logs...")
                    color:              palette.warningText
                }
            }

            //-----------------------------------------------------------------
            // Google Drive upload banner
            Rectangle {
                Layout.fillWidth:   true
                visible:            driveManager.uploading || driveManager.pendingCount > 0
                implicitHeight:     driveBannerLabel.implicitHeight + _margin
                radius:             8
                color:              palette.alertBackground

                QGCLabel {
                    id:                 driveBannerLabel
                    anchors.centerIn:   parent
                    text:               driveManager.pendingCount > 1
                                            ? qsTr("Uploading logs to Google Drive... (%1 queued)").arg(driveManager.pendingCount)
                                            : qsTr("Uploading log to Google Drive...")
                    color:              palette.warningText
                }
            }

            //-----------------------------------------------------------------
            // Log cards / empty state
            Item {
                Layout.fillWidth:   true
                Layout.fillHeight:  true

                ListView {
                    id:                 cardList
                    anchors.fill:       parent
                    clip:               true
                    visible:            logController.model.count > 0
                    model:              logController.model
                    orientation:        ListView.Vertical
                    spacing:            _margin
                    delegate:           logCard
                }

                Column {
                    anchors.centerIn:   parent
                    spacing:            _margin
                    visible:            logController.model.count === 0

                    QGCLabel {
                        anchors.horizontalCenter:   parent.horizontalCenter
                        text:       logController.requestingList ? qsTr("Requesting log list...")
                                                                 : qsTr("No onboard logs")
                        font.bold:  true
                    }

                    QGCLabel {
                        anchors.horizontalCenter:   parent.horizontalCenter
                        visible:                    !logController.requestingList
                        text:                       qsTr("Connect a vehicle and click Refresh.")
                        color:                      palette.buttonText
                    }
                }
            }
        }
    }

    Component {
        id: logCard

        Rectangle {
            id:                 card
            width:              ListView.view.width - _margin * 2
            height:             _minCardWidth * 0.66
            radius:             10
            color:              _selected ? Qt.rgba(_accent.r, _accent.g, _accent.b, 0.15) : palette.windowShade
            border.width:       (_selected || cardMouse.containsMouse) ? 2 : 1
            border.color:       (_selected || cardMouse.containsMouse) ? _accent : palette.button

            readonly property var  entry:      logController.model.get(index)
            readonly property bool _selected:  entry ? entry.selected : false

            MouseArea {
                id:                 cardMouse
                anchors.fill:       parent
                hoverEnabled:       true
                onClicked: {
                    if (card.entry) {
                        card.entry.selected = !card.entry.selected
                        onboardLogsPage._recountSelection()
                    }
                }
            }

            ColumnLayout {
                anchors.fill:       parent
                anchors.margins:    _margin
                spacing:            _margin * 0.5

                RowLayout {
                    Layout.fillWidth:   true
                    spacing:            _margin * 0.6

                    // Selection indicator
                    Rectangle {
                        width:          selectLabel.implicitHeight + _margin * 0.6
                        height:         width
                        radius:         width / 2
                        color:          card._selected ? _accent : "transparent"
                        border.width:   1
                        border.color:   card._selected ? _accent : palette.button

                        QGCLabel {
                            id:                 selectLabel
                            anchors.centerIn:   parent
                            text:               "\u2713"
                            visible:            card._selected
                            color:              "white"
                            font.bold:          true
                        }
                    }

                    // Id badge
                    Rectangle {
                        radius:             height / 2
                        color:              _accent
                        implicitWidth:      idLabel.implicitWidth + _margin * 1.4
                        implicitHeight:     idLabel.implicitHeight + _margin * 0.7

                        QGCLabel {
                            id:                 idLabel
                            anchors.centerIn:   parent
                            text:               card.entry ? ("#" + card.entry.id) : ""
                            color:              "white"
                            font.bold:          true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Status pill
                    Rectangle {
                        radius:             height / 2
                        color:              onboardLogsPage._statusColor(card.entry)
                        implicitWidth:      statusLabel.implicitWidth + _margin * 1.4
                        implicitHeight:     statusLabel.implicitHeight + _margin * 0.7

                        QGCLabel {
                            id:                 statusLabel
                            anchors.centerIn:   parent
                            text:               onboardLogsPage._statusText(card.entry)
                            color:              "white"
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               onboardLogsPage._dateText(card.entry)
                    elide:              Text.ElideRight
                    font.bold:          true
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               card.entry ? card.entry.sizeStr : ""
                    color:              palette.buttonText
                }
            }
        }
    }
}
