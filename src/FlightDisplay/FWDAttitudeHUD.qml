/****************************************************************************
 *
 * FWD HUD — new implementation based on hud.html reference.
 * Standalone file; not wired into the existing UI yet.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Layouts          1.12
import QtQuick.Dialogs          1.3

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Vehicle       1.0

Item {
    id: root
    width: 359
    height: 389

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property real _roll:      (_activeVehicle && _activeVehicle.roll) ? _activeVehicle.roll.rawValue : 0
    property real _pitch:     (_activeVehicle && _activeVehicle.pitch) ? _activeVehicle.pitch.rawValue : 0
    property real _speed:     (_activeVehicle && _activeVehicle.groundSpeed) ? _activeVehicle.groundSpeed.rawValue : 0
    property real _alt:       (_activeVehicle && _activeVehicle.altitudeRelative) ? _activeVehicle.altitudeRelative.rawValue : 0
    property real _heading:   (_activeVehicle && _activeVehicle.heading) ? _activeVehicle.heading.rawValue : 0
    on_HeadingChanged: compassCanvas.requestPaint()
    on_RollChanged: rollCanvas.requestPaint()
    property real _speedSet:  (_activeVehicle && _activeVehicle.airSpeed) ? _activeVehicle.airSpeed.rawValue : 0
    property real _altSet:    (_activeVehicle && _activeVehicle.altitudeRelative) ? _activeVehicle.altitudeRelative.rawValue : 0
    on_SpeedChanged: speedTapeCanvas.requestPaint()
    on_AltChanged: altTapeCanvas.requestPaint()
    property string _mode:    _activeVehicle ? _activeVehicle.flightMode : "N/A"
    property int    _sats:    (_activeVehicle && _activeVehicle.gps && _activeVehicle.gps.satellitesVisible) ? _activeVehicle.gps.satellitesVisible.rawValue : 0
    property real   _battery: (_activeVehicle && _activeVehicle.batteries && _activeVehicle.batteries.count > 0) ? _activeVehicle.batteries.get(0).percentRemaining.rawValue : 0
    property bool   _armed:   _activeVehicle ? _activeVehicle.armed : false

    // EKF / estimator health (from VehicleEstimatorStatusFactGroup)
    property var  _est:         (_activeVehicle && _activeVehicle.estimatorStatus) ? _activeVehicle.estimatorStatus : null
    property bool _ekfAvailable: _est ? _est.telemetryAvailable : false
    property bool _ekfError:    _ekfAvailable && (
                                    _est.gpsGlitch.rawValue ||
                                    _est.accelError.rawValue ||
                                    !_est.goodAttitudeEstimate.rawValue ||
                                    _est.velRatio.rawValue      > 1.0 ||
                                    _est.horizPosRatio.rawValue > 1.0 ||
                                    _est.vertPosRatio.rawValue  > 1.0 ||
                                    _est.magRatio.rawValue      > 1.0 ||
                                    _est.tasRatio.rawValue      > 1.0)
    property bool _ekfWarn:     _ekfAvailable && !_ekfError && (
                                    !_est.goodHorizVelEstimate.rawValue ||
                                    !_est.goodVertVelEstimate.rawValue ||
                                    !_est.goodHorizPosRelEstimate.rawValue ||
                                    _est.velRatio.rawValue      > 0.7 ||
                                    _est.horizPosRatio.rawValue > 0.7 ||
                                    _est.vertPosRatio.rawValue  > 0.7 ||
                                    _est.magRatio.rawValue      > 0.7 ||
                                    _est.tasRatio.rawValue      > 0.7)

    Rectangle { anchors.fill: parent; color: "#000" }

    Rectangle {
        id: panel
        x: 3; y: 8; width: 353; height: 370
        radius: 3
        color: "#CC000000"
        border.color: "#0e1d2e"
        border.width: 1.5
        clip: true

        // Drag handle: grab anywhere on the panel background to move the HUD
        MouseArea {
            anchors.fill: parent
            z: -1
            drag.target: root.parent
            drag.axis: Drag.XAndYAxis
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        // Attitude world
        Item {
            id: world
            anchors.fill: parent
            transform: [
                Translate { y: _pitch * 3.8 },
                Rotation { origin.x: 180; origin.y: 185; angle: -_roll }
            ]
            Rectangle { x: -500; y: -700; width: 1360; height: 885
                gradient: Gradient { GradientStop { position: 0.0; color: "#1c3270" } GradientStop { position: 1.0; color: "#47a0c0" } } }
            Rectangle { x: -500; y: 185; width: 1360; height: 900
                gradient: Gradient { GradientStop { position: 0.0; color: "#0a9448" } GradientStop { position: 1.0; color: "#007f37" } } }
            Rectangle { x: -500; y: 183; width: 1360; height: 3; color: "#e8ffff" }
            Repeater {
                model: [-40,-30,-20,-10,10,20,30,40]
                delegate: Item {
                    property real p: modelData
                    property real yy: 185 - p * 3.8
                    property real x1: (Math.abs(p)/10)%2===0 ? 110 : 133
                    property real lineW: (Math.abs(p)/10)%2===0 ? 140 : 95
                    Rectangle {
                        x: x1
                        y: yy - 1
                        width: lineW
                        height: 2
                        color: p > 0 ? "#eef3ff" : "#d4ffcc"
                    }
                    Text {
                        x: x1 - 34
                        y: yy - 9
                        width: 30
                        height: 18
                        text: p
                        color: p > 0 ? "#e4ecff" : "#c9f7c9"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // Aircraft reference (classic HUD symbol)
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var cx = 180, cy = 185;

                function drawSymbol(color, lw, dotR) {
                    ctx.strokeStyle = color;
                    ctx.fillStyle   = color;
                    ctx.lineWidth   = lw;
                    ctx.lineCap     = "round";
                    ctx.lineJoin    = "round";

                    ctx.beginPath();
                    // left wing + end tick
                    ctx.moveTo(cx - 62, cy);        ctx.lineTo(cx - 13, cy);
                    ctx.moveTo(cx - 62, cy);        ctx.lineTo(cx - 62, cy + 7);
                    // right wing + end tick
                    ctx.moveTo(cx + 62, cy);        ctx.lineTo(cx + 13, cy);
                    ctx.moveTo(cx + 62, cy);        ctx.lineTo(cx + 62, cy + 7);
                    // nose chevron
                    ctx.moveTo(cx - 15, cy + 13);
                    ctx.lineTo(cx,      cy);
                    ctx.lineTo(cx + 15, cy + 13);
                    ctx.stroke();

                    // center dot
                    ctx.beginPath();
                    ctx.arc(cx, cy, dotR, 0, Math.PI * 2);
                    ctx.fill();
                }

                // dark outline for contrast over sky/ground
                drawSymbol("#001018", 6.5, 3.6);
                // main symbol
                drawSymbol("#eaf4ff", 3.0, 2.6);
            }
        }

        // Roll arc (scale + rotating pointer)
        Canvas {
            id: rollCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var ARC_CX = 180, ARC_CY = 200, RR = 148, KROLL = 0.89;
                var toRad = function(d) { return d * Math.PI / 180; };
                var pt = function(deg, r) {
                    var a = deg * KROLL * Math.PI / 180;
                    return [ARC_CX + r * Math.sin(a), ARC_CY - r * Math.cos(a)];
                };

                var startAng = toRad(-90 - 45 * KROLL);
                var endAng   = toRad(-90 + 45 * KROLL);

                // arc
                ctx.strokeStyle = "#e4eaff";
                ctx.lineWidth = 2.0;
                ctx.beginPath();
                ctx.arc(ARC_CX, ARC_CY, RR, startAng, endAng, false);
                ctx.stroke();

                // endpoint ticks
                var p1 = pt(-45, RR);
                var ax1 = p1[0], ay1 = p1[1];
                var p2 = pt(45, RR);
                var ax2 = p2[0], ay2 = p2[1];

                // Occlude pitch marks above the roll arc with a sky-matching gradient
                var grad = ctx.createLinearGradient(0, -700, 0, 185);
                grad.addColorStop(0.0, "#1c3270");
                grad.addColorStop(1.0, "#47a0c0");
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(ax2, ay2);
                ctx.arc(ARC_CX, ARC_CY, RR, endAng, startAng, true);
                ctx.lineTo(0, ay1);
                ctx.closePath();
                ctx.fillStyle = grad;
                ctx.fill();

                ctx.strokeStyle = "#e4eaff";
                ctx.lineWidth = 2.0;
                ctx.beginPath();
                ctx.moveTo(ax1 - 6, ay1 - 6); ctx.lineTo(ax1, ay1);
                ctx.moveTo(ax2 + 6, ay2 - 6); ctx.lineTo(ax2, ay2);
                ctx.stroke();

                // ticks + labels
                var marks = [-45, -30, -20, -10, 0, 10, 20, 30, 45];
                for (var i = 0; i < marks.length; i++) {
                    var d = marks[i];
                    if (Math.abs(d) !== 45) {
                        var isLong = (d === 0 || Math.abs(d) === 30 || Math.abs(d) === 20);
                        var tickLen = isLong ? 9 : 6;
                        var ts = pt(d, RR);
                        var tx1 = ts[0], ty1 = ts[1];
                        var te = pt(d, RR + tickLen);
                        var tx2 = te[0], ty2 = te[1];
                        ctx.strokeStyle = "#e4eaff";
                        ctx.lineWidth = 1.4;
                        ctx.beginPath();
                        ctx.moveTo(tx1, ty1);
                        ctx.lineTo(tx2, ty2);
                        ctx.stroke();
                    }
                    var lab = pt(d, RR + 19);
                    var lx = lab[0], ly = lab[1];
                    ctx.fillStyle = (d === 0) ? "#5df2e4" : "#c3c9e6";
                    ctx.font = (d === 0 ? "bold 10px" : "9px") + " sans-serif";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(d, lx, ly);
                }

                // rotating pointer
                ctx.save();
                ctx.translate(ARC_CX, ARC_CY);
                ctx.rotate(_roll * KROLL * Math.PI / 180);
                ctx.translate(-ARC_CX, -ARC_CY);

                ctx.fillStyle = "#6fd4ff";
                ctx.strokeStyle = "#ffffff";
                ctx.lineWidth = 0.7;
                ctx.beginPath();
                ctx.moveTo(180, 47);
                ctx.lineTo(171, 62);
                ctx.lineTo(180, 58);
                ctx.lineTo(189, 62);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                ctx.restore();
            }
            Component.onCompleted: requestPaint()
        }

        // Left tape (speed)
        // Airspeed / ground speed readouts (top-left, above the airspeed bar)
        Text { x:15; y:38; width:90; height:14; text: "AS " + ((_activeVehicle && _activeVehicle.airSpeed) ? _activeVehicle.airSpeed.rawValue.toFixed(1) : "0.0"); color:"#e9eefc"; font.pixelSize: 12; font.bold:true; horizontalAlignment: Text.AlignLeft }
        Text { x:15; y:53; width:90; height:14; text: "GS " + ((_activeVehicle && _activeVehicle.groundSpeed) ? _activeVehicle.groundSpeed.rawValue.toFixed(1) : "0.0"); color:"#e9eefc"; font.pixelSize: 12; font.bold:true; horizontalAlignment: Text.AlignLeft }
        Rectangle { x:15; y:74; width:34; height:220; radius:2; color: "#33294a"; border.color:"#2ecb6b"; border.width:1 }
        Canvas {
            id: speedTapeCanvas
            x:15; y:74; width:34; height:220
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0,0,width,height);
                var value = _speed;
                var lo = Math.floor(value-30), hi = Math.ceil(value+30);
                var TAPE_CY = 110; var TAPE_PX = 4.37;
                for (var v=lo; v<=hi; v++) {
                    var y = TAPE_CY - (v-value)*TAPE_PX;
                    if (y < 4 || y > 216) continue;
                    if (v % 10 === 0) {
                        ctx.strokeStyle = "#f2f0ff"; ctx.lineWidth = 1.6;
                        ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(11,y); ctx.stroke();
                        ctx.fillStyle = "#f2f0ff"; ctx.font = "14px sans-serif"; ctx.textAlign="center";
                        ctx.fillText(v, 17, y+5);
                    } else if (v % 2 === 0) {
                        var isLong = (v % 5 === 0);
                        ctx.strokeStyle = "#f2f0ff"; ctx.globalAlpha = 0.85; ctx.lineWidth = 1;
                        ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(isLong?7:4,y); ctx.stroke();
                        ctx.globalAlpha = 1.0;
                    }
                }
            }
            Component.onCompleted: requestPaint()
        }
        Rectangle { x:22; y:176; width:43; height:18; radius:4; gradient: Gradient{GradientStop{position:0;color:"#22c9ac"}GradientStop{position:1;color:"#0a7a6c"}} border.color:"#5be0c8"; border.width:1 }
        Text { x:28; y:176; width:30; height:18; text: Math.round(_speed); color:"#fff"; font.pixelSize: 16; font.bold:true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Rectangle { x:6.5; y:176.5; width:22; height:17; radius:5; color:"#3f3858"; border.color:"#2ecb6b"; border.width:1.4 }
        Text { x:6.5; y:176.5; width:22; height:17; text: Math.round(_speedSet); color:"#fff"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

        // Right tape (altitude)
        Rectangle { x:312; y:74; width:34; height:220; radius:2; color: "#33294a"; border.color:"#2ecb6b"; border.width:1 }
        Canvas {
            id: altTapeCanvas
            x:312; y:74; width:34; height:220
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0,0,width,height);
                var value = _alt;
                var lo = Math.floor(value-30), hi = Math.ceil(value+30);
                var TAPE_CY = 110; var TAPE_PX = 4.37;
                for (var v=lo; v<=hi; v++) {
                    var y = TAPE_CY - (v-value)*TAPE_PX;
                    if (y < 4 || y > 216) continue;
                    if (v % 10 === 0) {
                        ctx.strokeStyle = "#f2f0ff"; ctx.lineWidth = 1.6;
                        ctx.beginPath(); ctx.moveTo(23,y); ctx.lineTo(34,y); ctx.stroke();
                        ctx.fillStyle = "#f2f0ff"; ctx.font = "14px sans-serif"; ctx.textAlign="center";
                        ctx.fillText(v, 17, y+5);
                    } else if (v % 2 === 0) {
                        var isLong = (v % 5 === 0);
                        ctx.strokeStyle = "#f2f0ff"; ctx.globalAlpha = 0.85; ctx.lineWidth = 1;
                        ctx.beginPath(); ctx.moveTo(isLong?27:30,y); ctx.lineTo(34,y); ctx.stroke();
                        ctx.globalAlpha = 1.0;
                    }
                }
            }
            Component.onCompleted: requestPaint()
        }
        Rectangle { x:296; y:176; width:44; height:18; radius:4; gradient: Gradient{GradientStop{position:0;color:"#54b4d2"}GradientStop{position:1;color:"#1d5f8c"}} border.color:"#7fcbe6"; border.width:1 }
        Text { x:300; y:176; width:36; height:18; text: Math.round(_alt); color:"#fff"; font.pixelSize: 16; font.bold:true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Rectangle { x:335; y:176.5; width:22; height:17; radius:5; color:"#3f3858"; border.color:"#7fa6c0"; border.width:1.4 }
        Text { x:335; y:176.5; width:22; height:17; text: Math.round(_altSet); color:"#fff"; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

        // Top-left badges
        Rectangle { x:145; y:4; width:70; height:20; radius:6; color:"#441d20"; border.color:"#d4202a"; border.width:1.8 }
        Text { x:145; y:4; width:70; height:20; text: _armed ? "ARMED" : "DISARMED"; color:"#f4e8ea"; font.pixelSize: 10; font.bold: true; font.family: ScreenTools.fixedFontFamily; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Rectangle {
            x:10; y:6; width:29; height:17; radius:5
            color:       !_ekfAvailable ? "#22303a" : (_ekfError ? "#4a1315" : (_ekfWarn ? "#4a4224" : "#0d3b2c"))
            border.color: !_ekfAvailable ? "#7a8894" : (_ekfError ? "#d4202a" : (_ekfWarn ? "#e6d51d" : "#21d070"))
            border.width: 1.8
        }
        Text {
            x:10; y:6; width:29; height:17
            text: _ekfError ? "EKF!" : "EKF"
            color: !_ekfAvailable ? "#c8d0d8" : (_ekfError ? "#ffdadd" : (_ekfWarn ? "#fffbe6" : "#f0fff6"))
            font.pixelSize: 8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Top-right sats + RTK
        Rectangle { x:270.5; y:20.5; width:25; height:25; radius:12.5; color:"#1b2a60"; opacity:0.55 }
        Text { x:270.5; y:20.5; width:25; height:25; text: _sats; color:"#fff"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        Rectangle { x:307.5; y:12.5; width:39; height:39; radius:19.5; color:"transparent"; border.color:"#d800e0"; border.width:4.5 }
        Text { x:307.5; y:18; width:39; height:14; text: "RTK"; color:"#fff"; font.pixelSize: 8; horizontalAlignment: Text.AlignHCenter }
        Text { x:307.5; y:32; width:39; height:14; text: "Fixed"; color:"#fff"; font.pixelSize: 8; horizontalAlignment: Text.AlignHCenter }

        // Right info boxes
        Rectangle { x:262.5; y:210.5; width:39; height:23; radius:4; color:"#103636"; border.color:"#1ccfdc"; border.width:1.4 }
        Rectangle { x:262.5; y:238.5; width:39; height:23; radius:4; color:"#103636"; border.color:"#1ccfdc"; border.width:1.4 }
        Rectangle { x:262.5; y:266.5; width:39; height:23; radius:4; color:"#103636"; border.color:"#1ccfdc"; border.width:1.4 }
        Text { x:262.5; y:212; width:39; height:10; text: "HDG"; color:"#e9eefc"; font.pixelSize: 6; horizontalAlignment: Text.AlignHCenter }
        Text { x:262.5; y:223; width:39; height:12; text: Math.round(_heading); color:"#e9eefc"; font.pixelSize: 10; font.bold:true; horizontalAlignment: Text.AlignHCenter }
        Text { x:262.5; y:240; width:39; height:10; text: "PITCH"; color:"#e9eefc"; font.pixelSize: 6; horizontalAlignment: Text.AlignHCenter }
        Text { x:262.5; y:251; width:39; height:12; text: Math.round(_pitch); color:"#e9eefc"; font.pixelSize: 10; font.bold:true; horizontalAlignment: Text.AlignHCenter }
        Text { x:262.5; y:268; width:39; height:10; text: "ROLL"; color:"#e9eefc"; font.pixelSize: 6; horizontalAlignment: Text.AlignHCenter }
        Text { x:262.5; y:279; width:39; height:12; text: Math.round(_roll); color:"#e9eefc"; font.pixelSize: 10; font.bold:true; horizontalAlignment: Text.AlignHCenter }

        // Heading readout
        // (heading value is drawn inside the compass canvas below)

        // Extra telemetry readouts (status cluster)
        // (VIBE and COMMS moved below the altitude indicator)
        // Mode box
        Rectangle { x:124.5; y:297.5; width:112; height:18; radius:5; gradient: Gradient{GradientStop{position:0;color:"#202f47"}GradientStop{position:1;color:"#121c2e"}} border.color:"#1d9bd0"; border.width:1.6 }
        Text { x:124.5; y:297.5; width:112; height:18; text: _mode; color:"#fff"; font.pixelSize: 13; font.bold:true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

        // GPS / battery readouts (below airspeed bar, above heading indicator)
        Text { x:15; y:304; width:90; height:12; text: "GPS " + _sats + " SAT"; color:"#e9eefc"; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignLeft }
        Text { x:15; y:316; width:90; height:12; text: "BAT " + ((_activeVehicle && _activeVehicle.batteries && _activeVehicle.batteries.count > 0) ? _activeVehicle.batteries.get(0).voltage.rawValue.toFixed(2) : "0.00") + "V"; color:"#e9eefc"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignLeft }

        // VIBE / COMMS readouts (below altitude bar, above heading indicator)
        Item {
            x:262.5; y:304; width:90; height:12
            Text { anchors.fill: parent; text: "VIBE " + ((_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.clipCount1) ? _activeVehicle.vibration.clipCount1.rawValue : 0); color:"#e9eefc"; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: vibeDialogComponent.createObject(mainWindow).open()
            }
        }
        Text { x:262.5; y:316; width:90; height:12; text: "COMMS " + (_activeVehicle ? _activeVehicle.rcRSSI : 0) + "%"; color:"#e9eefc"; font.pixelSize: 9; font.bold: true; horizontalAlignment: Text.AlignLeft }

        // Compass strip (clean horizontal heading tape)
        Canvas {
            id: compassCanvas
            x:11.5; y:320; width:330; height:48
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0,0,width,height);

                var hdg = _heading;
                var cx  = width / 2;
                var bandTop   = 18;
                var bandH     = 26;
                var pxPerDeg  = 2.2;

                var rr = function(x, y, w, h, r) {
                    ctx.beginPath();
                    ctx.moveTo(x + r, y);
                    ctx.lineTo(x + w - r, y);
                    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
                    ctx.lineTo(x + w, y + h - r);
                    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
                    ctx.lineTo(x + r, y + h);
                    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
                    ctx.lineTo(x, y + r);
                    ctx.quadraticCurveTo(x, y, x + r, y);
                    ctx.closePath();
                };

                // band background
                rr(2, bandTop, width - 4, bandH, 5);
                ctx.fillStyle = "#0b0a1c";
                ctx.fill();
                ctx.strokeStyle = "#26304a";
                ctx.lineWidth = 1;
                ctx.stroke();

                // subtle highlight behind the current heading
                ctx.fillStyle = "rgba(111,212,255,0.10)";
                ctx.fillRect(cx - 17, bandTop + 1, 34, bandH - 2);

                // ticks + labels
                var start = Math.floor((hdg - 130) / 5) * 5;
                for (var v = start; v <= hdg + 130; v += 5) {
                    var delta = v - hdg;
                    var x = cx + delta * pxPerDeg;
                    if (x < 8 || x > width - 8) continue;
                    var n = ((v % 360) + 360) % 360;
                    var major = (n % 30 === 0);
                    var mid   = (n % 10 === 0);
                    var tickH = major ? 9 : (mid ? 6 : 3);
                    ctx.strokeStyle = major ? "#e9eefc" : (mid ? "#9aa2c2" : "#5d648a");
                    ctx.lineWidth = major ? 1.5 : 1;
                    ctx.beginPath();
                    ctx.moveTo(x, bandTop + bandH - 2);
                    ctx.lineTo(x, bandTop + bandH - 2 - tickH);
                    ctx.stroke();

                    if (major) {
                        var card = (n === 0 ? "N" : (n === 90 ? "E" : (n === 180 ? "S" : (n === 270 ? "W" : null))));
                        ctx.fillStyle = card ? "#5df2e4" : "#c3c9e6";
                        ctx.font = (card ? "bold 10px" : "9px") + " sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText(card || n, x, bandTop + 10);
                    }
                }

                // center pointer (downward triangle)
                ctx.fillStyle = "#6fd4ff";
                ctx.strokeStyle = "#ffffff";
                ctx.lineWidth = 0.7;
                ctx.beginPath();
                ctx.moveTo(cx - 6, bandTop - 8);
                ctx.lineTo(cx + 6, bandTop - 8);
                ctx.lineTo(cx, bandTop - 1);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                // center line
                ctx.strokeStyle = "#6fd4ff";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(cx, bandTop);
                ctx.lineTo(cx, bandTop + bandH);
                ctx.stroke();

                // heading value box (attached to the top of the strip)
                var boxW = 76, boxH = 15;
                var boxX = cx - boxW / 2;
                var boxY = 2;
                ctx.fillStyle = "#1a2a3a";
                ctx.strokeStyle = "#5df2e4";
                ctx.lineWidth = 1.2;
                var r = 4;
                ctx.beginPath();
                ctx.moveTo(boxX + r, boxY);
                ctx.lineTo(boxX + boxW - r, boxY);
                ctx.quadraticCurveTo(boxX + boxW, boxY, boxX + boxW, boxY + r);
                ctx.lineTo(boxX + boxW, boxY + boxH - r);
                ctx.quadraticCurveTo(boxX + boxW, boxY + boxH, boxX + boxW - r, boxY + boxH);
                ctx.lineTo(boxX + r, boxY + boxH);
                ctx.quadraticCurveTo(boxX, boxY + boxH, boxX, boxY + boxH - r);
                ctx.lineTo(boxX, boxY + r);
                ctx.quadraticCurveTo(boxX, boxY, boxX + r, boxY);
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                ctx.fillStyle = "#ffffff";
                ctx.font = "bold 10px sans-serif";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText("HDG " + Math.round(_heading) + "\u00b0", cx, boxY + boxH / 2);
            }
            Component.onCompleted: requestPaint()
        }
    }
    Component {
        id: vibeDialogComponent
        QGCPopupDialog {
            title: qsTr("Vibration")
            buttons: StandardButton.Close
            ColumnLayout {
                spacing: ScreenTools.defaultFontPixelHeight / 2
                // Vibration bars (X, Y, Z)
                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth * 2
                    Layout.preferredHeight: 220
                    Layout.minimumHeight: 220
                    Layout.fillHeight: true
                    Repeater {
                        model: [
                            { label: "X", val: (_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.xAxis) ? _activeVehicle.vibration.xAxis.rawValue : 0 },
                            { label: "Y", val: (_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.yAxis) ? _activeVehicle.vibration.yAxis.rawValue : 0 },
                            { label: "Z", val: (_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.zAxis) ? _activeVehicle.vibration.zAxis.rawValue : 0 }
                        ]
                        delegate: ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignBottom
                            // Fixed-size outlined box with a colored level fill inside
                            Rectangle {
                                id: vibeBox
                                width: ScreenTools.defaultFontPixelWidth * 10
                                height: 200
                                color: "transparent"
                                border.color: "#ffffff"
                                border.width: 2
                                Layout.alignment: Qt.AlignHCenter
                                Rectangle {
                                    anchors.left:   parent.left
                                    anchors.right:  parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 3
                                    height: (parent.height - 6) * Math.max(0, Math.min(1, modelData.val / 60))
                                    color: modelData.val > 30 ? "#d4202a" : (modelData.val > 15 ? "#e6d51d" : "#21d070")
                                }
                            }
                            QGCLabel {
                                text: modelData.label + ": " + modelData.val.toFixed(2)
                                horizontalAlignment: Text.AlignHCenter
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
                // Clipping counts
                QGCLabel { text: qsTr("Primary (Clip1): %1").arg((_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.clipCount1) ? _activeVehicle.vibration.clipCount1.rawValue : 0) }
                QGCLabel { text: qsTr("Secondary (Clip2): %1").arg((_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.clipCount2) ? _activeVehicle.vibration.clipCount2.rawValue : 0) }
                QGCLabel { text: qsTr("Tertiary (Clip3): %1").arg((_activeVehicle && _activeVehicle.vibration && _activeVehicle.vibration.clipCount3) ? _activeVehicle.vibration.clipCount3.rawValue : 0) }

            }
        }
    }
}
