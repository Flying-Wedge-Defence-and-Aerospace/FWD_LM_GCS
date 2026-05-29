# FWDGCS v2 — User Manual

**Software Version:** 2.0  
**Document Version:** 1.0  
**Last Updated:** May 2026  
**Prepared by:** FWD Defence Team  

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Requirements](#2-system-requirements)
3. [Installation Guide](#3-installation-guide)
4. [First Launch & Login](#4-first-launch--login)
5. [User Interface Overview](#5-user-interface-overview)
6. [Vehicle Connection](#6-vehicle-connection)
7. [Fly View (Flight Operations)](#7-fly-view-flight-operations)
8. [Video System](#8-video-system)
9. [Mission Planning (Plan View)](#9-mission-planning-plan-view)
10. [Vehicle Setup (Setup View)](#10-vehicle-setup-setup-view)
11. [Application Settings](#11-application-settings)
12. [Safety Parameters](#12-safety-parameters)
13. [Data Persistence & Logs](#13-data-persistence--logs)
14. [Troubleshooting & FAQ](#14-troubleshooting--faq)
15. [Appendix](#15-appendix)

---

## 1. Introduction

### 1.1 About FWDGCS

FWDGCS (FWD Ground Control Station) is a customized version of QGroundControl (QGC) developed by FWD Defence for Navy and maritime unmanned vehicle operations. It is a full-featured ground control station application that enables operators to:

- Monitor real-time telemetry from unmanned vehicles
- View live video streams from onboard cameras
- Plan and execute autonomous missions
- Configure and calibrate vehicle sensors and systems
- Manage safety parameters and failsafe behaviours

FWDGCS communicates with vehicles using the MAVLink protocol, supporting both ArduPilot and PX4 autopilot firmware.

### 1.2 What Makes FWDGCS Different from Standard QGC

FWDGCS extends the standard QGC with the following custom features:

- **Authentication System** — A login/registration gate that secures access to the application
- **Enhanced Video Controls** — Extended video management with custom UI overlays and controls
- **Custom Branding** — FWD Defence visual identity including logo, colour scheme (deep red #700000), and application naming
- **Navy-Specific Configuration** — Pre-configured settings and parameters relevant to maritime operations

### 1.3 Document Scope & Audience

This manual is intended for operators, technicians, and administrators who will use FWDGCS to control and monitor unmanned vehicles. It covers installation, configuration, daily operation, and troubleshooting.

Readers should have basic familiarity with unmanned aircraft/vehicle systems and standard computer操作.

### 1.4 How to Use This Manual

- **New users** should start with Sections 1–5 for setup and familiarization
- **Operators** should focus on Sections 6–8 for flight operations
- **Planners** will find Section 9 most relevant
- **Technicians** should review Sections 10–12 for configuration and calibration
- **Troubleshooting** common issues is covered in Section 14

---

## 2. System Requirements

### 2.1 Supported Operating Systems

| Platform | Version | Architecture |
|----------|---------|-------------|
| Windows | 10 (64-bit) / 11 | x86_64 |
| Ubuntu Linux | 20.04 LTS / 22.04 LTS | x86_64, aarch64 |
| Android | 8.0 (Oreo) or later | arm64-v8a |
| macOS | 10.15 (Catalina) or later | x86_64, arm64 |

### 2.2 Minimum Hardware Specifications

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Processor | Intel Core i5, 2.5 GHz | Intel Core i7, 3.0 GHz |
| RAM | 8 GB | 16 GB |
| Storage | 500 MB free | 10 GB (for logs & offline maps) |
| Graphics | GPU supporting OpenGL 3.3 | Dedicated GPU with video decode |
| Display | 1280 x 720 | 1920 x 1080 or higher |
| Network | Wi-Fi / Ethernet | Wi-Fi + Ethernet |

### 2.3 Supported Vehicles & Autopilots

FWDGCS supports any vehicle running:

| Autopilot Firmware | Versions | Vehicle Types |
|--------------------|----------|---------------|
| ArduPilot (APM) | Copter 4.x, Plane 4.x, Rover 4.x, Sub 4.x | Multicopter, Fixed-wing, VTOL, Rover, Boat, Submarine |
| PX4 Pro | 1.12, 1.13, 1.14 | Multicopter, Fixed-wing, VTOL, Rover, Submarine |

Communication is via the MAVLink protocol (v1 and v2).

### 2.4 Required Drivers & Dependencies

- **GStreamer 1.18.6** — Required for video pipeline processing (included with Android builds)
- **USB-to-Serial Drivers**:
  - FTDI VCP drivers (www.ftdichip.com)
  - Silicon Labs CP210x drivers (www.silabs.com)
- **Radio Telemetry Drivers**:
  - SiK radio (Holybro, 3DR Radio) — USB serial, no special driver needed on Linux
- **Linux udev Rules** — For telemetry radio access without root:
  ```
  SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
  ```

---

## 3. Installation Guide

### 3.1 Windows Installation

1. Download the FWDGCS installer (`FWD_NAVY_GCS-x.x.x-installer.exe`) from the FWD distribution portal
2. Run the installer as Administrator
3. Follow the setup wizard:
   - Accept the license agreement
   - Choose installation directory (default: `C:\Program Files\FWDGCS`)
   - Select components (ensure GStreamer is included for video support)
   - Choose Start Menu folder
4. Click **Install**
5. Launch FWDGCS from the Start Menu or desktop shortcut

**Post-Installation:**
- If video is not working, install GStreamer 1.18.6 runtime separately
- Configure Windows Firewall to allow FWDGCS for MAVLink UDP/TCP ports

### 3.2 Linux Installation

**Option A: AppImage (Recommended)**

1. Download the AppImage: `FWD_NAVY_GCS-x.x.x-x86_64.AppImage`
2. Make it executable:
   ```bash
   chmod +x FWD_NAVY_GCS-x.x.x-x86_64.AppImage
   ```
3. Run:
   ```bash
   ./FWD_NAVY_GCS-x.x.x-x86_64.AppImage
   ```

**Option B: Install from Source (Developers)**

1. Clone the repository:
   ```bash
   git clone https://github.com/fwdefence/FWDGCSv2.git
   cd FWDGCSv2
   git checkout dev/navy-ui-dev
   ```
2. Install build dependencies:
   ```bash
   sudo apt install build-essential qt5-qmake qtbase5-dev qtdeclarative5-dev \
     libqt5opengl5-dev libqt5quick5 libqt5quickcontrols2-5-dev \
     libqt5serialport5-dev libqt5svg5-dev libqt5xmlpatterns5-dev \
     libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
     libsdl2-dev libudev-dev libxkbcommon-dev
   ```
3. Build:
   ```bash
   mkdir build && cd build
   cmake .. -DCMAKE_BUILD_TYPE=Release
   make -j$(nproc)
   ```

**udev Rules for Telemetry Radios:**
```bash
sudo tee /etc/udev/rules.d/99-telemetry.rules << 'EOF'
SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0666"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 3.3 Android Installation

1. Download the APK: `FWD_NAVY_GCS-vx.x.x.apk`
2. On your Android device, enable **Install from Unknown Sources** in Settings > Security
3. Open the APK file and follow the installation prompts
4. Grant required permissions when first launching:
   - **Location** — for GPS data and map display
   - **Storage** — for saving logs and mission files
   - **USB** — for connecting to telemetry radios via USB-OTG

### 3.4 Verifying Your Installation

Launch FWDGCS. The login screen should appear with the FWD branding logo and a red-themed UI. Navigate to **Settings > General** to confirm the version number matches your downloaded version.

### 3.5 Upgrading from a Previous Version

1. Back up your settings and mission files (see Section 13.4)
2. Uninstall the previous version (Windows) or replace the AppImage (Linux)
3. Install the new version following the instructions above
4. Your settings and saved data will be preserved if you did not delete the configuration directory

---

## 4. First Launch & Login

### 4.1 Starting FWDGCS for the First Time

When you launch FWDGCS, the application performs the following sequence:

1. Splash screen with FWD branding is displayed
2. Application initializes MAVLink and video subsystems
3. The **Login Screen** is presented

### 4.2 The Login Screen

The login screen features:

- **FWD Logo** — Displayed prominently at the top
- **Title** — "GROUND CONTROL STATION" with "FWDGCS" subtitle
- **Branding** — Red gradient theme (#700000)
- **Login Form**:
  - Username field
  - Password field
  - "Remember Me" checkbox
  - Login button
- **Register Link** — Toggle to registration form

### 4.3 Login Procedure

1. Enter your **Username** and **Password**
2. Check **Remember Me** if you want the application to retain your credentials on this device
3. Click **Login**
4. On successful authentication, the main application window loads

### 4.4 Registration

If you do not have an account:

1. On the login screen, click the **Register** link to switch to registration mode
2. Fill in the required fields:
   - Full Name
   - Username
   - Email Address
   - Password
   - Confirm Password
3. Click **Register**

> Note: Registration functionality may require server-side setup. Contact your system administrator if registration is unavailable.

### 4.5 Session Management

- Your session remains active until you log out or close the application
- **"Remember Me"** stores a token locally for automatic login on subsequent launches
- Sessions have a configurable timeout period after which re-authentication is required

### 4.6 Logout

To log out:

1. Click the **profile icon** on the main toolbar
2. Select **Log Out**
3. Confirm the action when prompted
4. The application checks for active vehicle connections before logging out
5. You are returned to the login screen

> **Important:** Ensure your vehicle is safely landed and disarmed before logging out, as the connection will be terminated.

### 4.7 Login Troubleshooting

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| "Invalid credentials" | Incorrect username/password | Check credentials, ensure Caps Lock is off |
| "Server unreachable" | Server-side auth is enabled but server is down | Contact administrator; check network connectivity |
| Session expired | Inactivity timeout | Re-enter credentials |
| Account locked | Multiple failed login attempts | Wait 15 minutes or contact administrator |

---

## 5. User Interface Overview

### 5.1 Main Window Layout

The FWDGCS main window is divided into these areas:

```
+------------------------------------------------------------+
| [FWD Logo]  [Views]  [User Info]  [Settings]  [Logout]     |  <- Toolbar
+------------------------------------------------------------+
|                                                            |
|   View Tabs: [Fly] [Plan] [Setup] [Analyze]                |
|                                                            |
|                    Main Content Area                        |
|         (changes based on selected view)                    |
|                                                            |
+------------------------------------------------------------+
| [GPS] [Battery] [RSSI] [Flight Mode] [Armed] [Heartbeat]   |  <- Status Bar
+------------------------------------------------------------+
```

### 5.2 Main Toolbar

The toolbar at the top provides:

- **FWD Logo** — Application branding; click to access About dialog
- **View Selector** — Tabs to switch between Fly, Plan, Setup, and Analyze modes
- **Connection Status** — Indicator showing vehicle link state (connected/disconnected)
- **User Profile** — Current logged-in user display
- **Settings** — Gear icon to access application settings
- **Logout** — Button to end session and return to login screen

The toolbar uses the FWD red colour theme (#700000) with white text.

### 5.3 Status Bar

The status bar at the bottom displays real-time vehicle information:

| Indicator | Description |
|-----------|-------------|
| GPS | Satellite count and fix type (No GPS, 2D, 3D, RTK) |
| Battery | Voltage, current, and remaining percentage |
| RSSI | Telemetry radio signal strength |
| Flight Mode | Current flight mode (Stabilize, Loiter, Auto, RTL, etc.) |
| Armed | Vehicle armed status (Disarmed / Armed) |
| Heartbeat | MAVLink heartbeat indicator (pulsing when connected) |
| Time | Vehicle flight time (elapsed since arming) |

### 5.4 Application Modes

| Mode | Shortcut | Purpose |
|------|----------|---------|
| **Fly** | Ctrl+1 | Real-time flight operations, video feed, and telemetry |
| **Plan** | Ctrl+2 | Create, edit, and upload autonomous missions |
| **Setup** | Ctrl+3 | Vehicle configuration, calibration, and parameter tuning |
| **Analyze** | Ctrl+4 | Review telemetry logs and MAVLink messages |

### 5.5 Keyboard Shortcuts

| Shortcut | Function |
|----------|----------|
| Ctrl+1 | Switch to Fly View |
| Ctrl+2 | Switch to Plan View |
| Ctrl+3 | Switch to Setup View |
| Ctrl+4 | Switch to Analyze View |
| Ctrl+F | Toggle fullscreen |
| Ctrl+Q | Quit application |
| Ctrl+, | Open Settings |
| I | Arm vehicle |
| O | Disarm vehicle |
| Space | Return to Launch (RTL) — requires confirmation |
| R | Record video toggle |
| S | Snapshot / capture screenshot |
| M | Toggle mute |
| +/- | Zoom map in/out |
| F11 | Toggle fullscreen |

---

## 6. Vehicle Connection

### 6.1 Connection Methods

FWDGCS supports multiple connection types:

| Method | Typical Use Case | Speed |
|--------|-----------------|-------|
| Serial (UART) | Telemetry radio (SiK, Holybro, etc.) | 57600–921600 baud |
| USB | Direct connection to autopilot | High |
| UDP | WiFi bridge, companion computer | Network dependant |
| TCP | Remote link, relay server | Network dependant |
| Bluetooth | Short-range, low-bandwidth | Low |

### 6.2 Configuring a New Connection

1. Click the **Connection** button or go to **Settings > MAVLink**
2. Click **Add** to create a new connection
3. Select the **Connection Type**:
   - **Serial**: Port, Baud rate, Data bits, Parity, Stop bits
   - **UDP**: Local port, Target IP, Target port
   - **TCP**: Server address, Port
4. Enter a **Name** for this connection (e.g., "Primary Radio")
5. Click **OK** to save

### 6.3 Connecting to a Vehicle

1. Ensure the vehicle is powered on and within range
2. Connect your telemetry radio or USB cable to the computer
3. Select the configured connection from the connection dropdown
4. Click **Connect**
5. The status indicators will update:
   - Heartbeat icon starts pulsing
   - Battery and GPS data populate
   - Flight mode shows current mode

### 6.4 Connection Status Indicators

| Colour | Meaning |
|--------|---------|
| Green | Connected — heartbeat received within expected interval |
| Yellow | Marginal — intermittent heartbeat, high latency |
| Red | Disconnected — no heartbeat for >5 seconds |

### 6.5 Multiple Vehicle Connections

FWDGCS can connect to multiple vehicles simultaneously:

1. Configure separate connections for each vehicle
2. Connect to each vehicle individually
3. Use the **Vehicle Selector** dropdown in the toolbar to switch between connected vehicles
4. Status bar and displays update for the currently selected vehicle

### 6.6 Disconnecting

1. Ensure the vehicle is landed and disarmed
2. Click **Disconnect** from the connection menu
3. Confirm disconnection if prompted
4. The application retains the connection configuration for future use

---

## 7. Fly View (Flight Operations)

### 7.1 Overview of the Fly View

The Fly View is the primary interface for in-flight operations. It consists of:

- **Primary Flight Display (PFD)** — Artificial horizon, attitude, heading
- **Map Panel** — Vehicle position, waypoints, obstacles
- **Video Panel** — Live camera feed with overlay
- **Telemetry Strip** — Real-time vehicle data
- **Action Buttons** — Arm, Disarm, Takeoff, Land, RTL, Pause

### 7.2 Artificial Horizon / Attitude Indicator

The PFD shows:

- **Pitch** — Indicated by horizon line position (positive = nose up)
- **Roll** — Indicated by horizon line angle
- **Heading** — Compass rose at top, rotates with vehicle yaw
- **Groundspeed** — Digital readout
- **Altitude** — Barometric altitude (relative to takeoff)
- **Vertical Speed** — Climb/descent rate indicator

### 7.3 Telemetry Data Display

The telemetry strip shows these values (configurable):

| Parameter | Unit | Description |
|-----------|------|-------------|
| Altitude | m / ft | Height above home position |
| Groundspeed | m/s / knots | Speed over ground |
| Airspeed | m/s / knots | Speed through air (fixed-wing) |
| Heading | degrees | Compass heading (0–360) |
| Battery Voltage | V | Current battery voltage |
| Battery Current | A | Current draw |
| Battery Remaining | % | Estimated remaining charge |
| GPS Satellites | count | Number of satellites locked |
| GPS HDOP | — | Horizontal dilution of precision |
| Distance to Home | m / ft | Straight-line distance from home |
| Flight Time | HH:MM:SS | Time since arming |
| Link Quality | % | Telemetry radio signal quality |

### 7.4 Map Interaction

In the map panel:

- **Pan** — Click and drag
- **Zoom** — Scroll wheel, pinch (touch), or +/- buttons
- **Centre on Vehicle** — Double-click the vehicle icon or press C
- **Map Layers** — Toggle satellite, street, hybrid, or terrain view
- **Vehicle Trail** — Shows recent path with dots; colour-coded by altitude
- **Waypoints** — Active mission waypoints overlaid on map
- **Geofence** — Restricted area boundary display

### 7.5 In-Flight Controls

The action buttons on the right side of Fly View:

| Button | Action | Safety |
|--------|--------|--------|
| **Arm** | Arms motors | Requires pre-arm checks to pass |
| **Disarm** | Disarms motors | Override with safety switch if needed |
| **Takeoff** | Autonomous takeoff to specified altitude | Confirm altitude first |
| **Land** | Land at current position | Confirm landing area safe |
| **RTL** | Return to Launch / Home | Returns to home and lands |
| **Pause** | Pause mission, hold position | Vehicle loiters in place |
| **Flight Mode** | Dropdown to select flight mode | Set appropriate mode for situation |

### 7.6 Joystick / Gamepad Control

To use a joystick for manual control:

1. Connect your joystick/gamepad via USB
2. Go to **Settings > Joystick**
3. Select your device from the dropdown
4. Calibrate by following the on-screen instructions (centre, min, max for each axis)
5. Map joystick axes to vehicle controls (Roll, Pitch, Yaw, Throttle)
6. Enable joystick control by pressing the **Enable** button or joystick button

---

## 8. Video System

### 8.1 Overview of Video Capabilities

FWDGCS features an enhanced video system built on GStreamer 1.18.6, providing:

- **Live Video Streaming** — View real-time camera feeds from the vehicle
- **Multiple Source Support** — RTSP, UDP, TCP, and local camera devices
- **Video Controls** — Show/hide, resize, fullscreen, screenshot
- **Telemetry Overlays** — Display real-time data on the video feed
- **Recording** — Capture video to local storage

### 8.2 Configuring Video Source

1. Go to **Settings > Video**
2. Configure the video source:
   - **Source Type**: UDP, RTSP, TCP, or local file/device
   - **UDP Port**: Port to listen on (default: 5600)
   - **RTSP URL**: Full RTSP URL (e.g., `rtsp://192.168.1.100:8554/stream`)
   - **UDP Address**: Multicast address if applicable
3. Configure decoding options:
   - **Codec**: H.264, H.265, MPEG-4
   - **Decode Method**: Software or hardware acceleration
4. Click **Apply** to save

The GStreamer pipeline string can be customised for advanced users in the settings.

### 8.3 Video Controls

When a video feed is active, the following controls are available:

| Control | Description |
|---------|-------------|
| **Show/Hide Video** | Toggle the video panel visibility |
| **Resize Video** | Drag the video panel border to resize |
| **Fullscreen Toggle** | Expand video to full screen |
| **Right Menu** | Additional controls panel (hide/show right menu) |
| **Snapshot** | Capture the current video frame as an image |
| **Record** | Start/stop video recording to file |
| **Mute** | Toggle audio if available |

### 8.4 Video Overlays

Overlay information can be displayed on the video feed:

- **Telemetry Data** — Altitude, speed, heading, battery (configurable)
- **Crosshair / Reticle** — Centre aiming marker
- **Artificial Horizon** — Pitch and roll overlay
- **Timestamp** — UTC or local time overlay
- **Vehicle Status** — Flight mode, armed state, GPS status

Overlay settings can be configured in **Settings > Video > Overlay**.

### 8.5 Video Troubleshooting

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| Black screen / no video | Incorrect source configuration | Verify source type, port, and URL are correct |
| Video freezing / stuttering | Network bandwidth insufficient | Reduce resolution; check WiFi signal strength |
| GStreamer pipeline error | Missing codec or plugin | Install required GStreamer plugins (bad, ugly, good) |
| High CPU usage | Software decoding | Enable hardware acceleration if available |
| Audio not working | Audio not in stream or codec unsupported | Check if stream includes audio track |
| No video after connection | Video not started on vehicle side | Ensure camera is powered and video transmitter is active |

### 8.6 GStreamer Pipeline Reference

Default pipeline strings:

**UDP H.264:**
```
udpsrc port=5600 ! application/x-rtp,media=video,encoding-name=H264 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! qtvideosink
```

**RTSP H.264:**
```
rtspsrc location=rtsp://192.168.1.100:8554/stream ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! qtvideosink
```

To debug pipeline issues, enable verbose logging in **Settings > General > Debug > GStreamer Logging**.

---

## 9. Mission Planning (Plan View)

### 9.1 Overview of Plan View

The Plan View provides a complete mission planning workspace. You can create, edit, save, and upload autonomous missions consisting of waypoints and commands.

### 9.2 Creating a New Mission

1. Switch to **Plan View** (Ctrl+2)
2. Click **New Plan** to start fresh
3. Click on the map to place waypoints
4. Each waypoint appears with a numbered marker connected by lines showing the flight path
5. Adjust waypoint properties (altitude, loiter time, actions) in the side panel

### 9.3 Waypoint Types

| Type | Description |
|------|-------------|
| **Waypoint** | Standard navigation point; vehicle flies to this location |
| **Loiter (Unlimited)** | Holds position indefinitely until commanded otherwise |
| **Loiter (Time)** | Holds position for a specified number of seconds |
| **Loiter (Turns)** | Orbits the point for a specified number of circles |
| **Land** | Initiates landing sequence at this location |
| **Takeoff** | Initiates takeoff and climb to specified altitude |
| **Return to Launch** | Vehicle returns to home position and lands |
| **Spline Waypoint** | Smooth curved path between waypoints (not straight lines) |

### 9.4 Advanced Mission Commands

Available from the **Add Command** dropdown:

**Condition Commands:**
- **Condition Delay** — Pause mission for a specified time
- **Condition Distance** — Execute next command when within a specified distance of a point
- **Condition Yaw** — Set target yaw angle

**DO Commands:**
- **Set Servo** — Set a servo channel to a specific PWM value
- **Repeat Servo** — Cycle a servo between two positions
- **Set Relay** — Toggle a relay on/off
- **Set Camera Trigger** — Configure camera shutter triggering
- **Set Gimbal** — Control gimbal pitch and yaw
- **Set ROI** — Set region of interest for camera/gimbal

### 9.5 Geofence

A geofence defines a boundary the vehicle should not cross:

1. Click **Geofence** tab in the Plan View sidebar
2. Click on the map to define polygon vertices
3. Close the polygon by clicking on the first vertex or clicking **Close Polygon**
4. Set the **Action on Breach**:
   - **Report Only** — Log and notify but take no action
   - **RTL** — Return to launch
   - **Land** — Land immediately
   - **Loiter** — Hold position
5. Set **Altitude Limits** (min/max) if needed

### 9.6 Rally Points

Rally points are alternative landing locations:

1. Click **Rally Points** tab
2. Click on the map to place rally points
3. If the primary home position is unavailable during RTL, the vehicle will use the nearest rally point

### 9.7 Saving, Loading, and Exporting Missions

| Action | Method |
|--------|--------|
| **Save** | Ctrl+S or File > Save — saves as .plan file |
| **Save As** | Ctrl+Shift+S or File > Save As — saves with new name |
| **Open** | Ctrl+O or File > Open — loads a saved .plan file |
| **Export as Waypoints** | File > Export > Waypoints — exports as .waypoints text file |
| **Import Waypoints** | File > Import > Waypoints — imports from .waypoints text file |

### 9.8 Uploading Mission to Vehicle

1. Ensure the vehicle is connected and receiving a GPS fix
2. Click **Upload** (right arrow button) in the Plan View toolbar
3. The application sends waypoints to the vehicle
4. Verify the mission was accepted:
   - **Mission Count** on the vehicle updates
   - Click **Download** (left arrow button) to read back the mission from the vehicle for verification
5. Switch to **Fly View** and engage **Auto** mode to execute the mission

---

## 10. Vehicle Setup (Setup View)

### 10.1 Overview of Setup View

The Setup View provides a step-by-step wizard for configuring the vehicle. Each section guides you through essential setup tasks.

### 10.2 Firmware

To check or update firmware:

1. Connect the autopilot via USB
2. Go to **Setup > Firmware**
3. Current firmware version is displayed
4. To update:
   - Select the firmware type (ArduPilot or PX4)
   - Select vehicle type (if applicable)
   - Click **Flash Firmware**
   - The application downloads and installs the latest firmware

### 10.3 Airframe

1. Go to **Setup > Airframe**
2. Browse the airframe list or search by name
3. Select the appropriate airframe for your vehicle
4. Click **Apply and Restart**
5. The vehicle reboots with the new airframe parameters

### 10.4 Sensor Calibration

| Sensor | Procedure |
|--------|-----------|
| **Accelerometer** | Place the vehicle in each of 6 orientations (level, left, right, nose up, nose down, back) as prompted |
| **Magnetometer (Compass)** | Rotate the vehicle slowly through all axes in a figure-8 pattern until calibration completes |
| **Gyroscope** | Place the vehicle on a level, stationary surface and click Calibrate |
| **Level / Horizon** | Place the vehicle in its normal flight attitude on a level surface and calibrate |
| **Airspeed** | Ensure no wind is blowing into the pitot tube, click Calibrate |

### 10.5 Radio Control (RC) Calibration

1. Ensure the RC transmitter is bound to the receiver and powered on
2. Go to **Setup > Radio** 
3. Click **Calibrate**
4. Follow on-screen instructions to move each stick to its extremes
5. Verify channel mapping matches your RC configuration
6. Set **Failsafe** values for each channel (typically throttle low for safety)

### 10.6 Flight Modes

1. Go to **Setup > Flight Modes**
2. Assign flight modes to RC channel positions (typically a 3-position switch)
3. Available modes vary by firmware but commonly include:
   - Stabilize / Manual
   - Altitude Hold
   - Loiter
   - Auto
   - RTL (Return to Launch)
   - Land
   - Sport / Acro
   - Circle
4. Test each switch position to verify the correct mode is set

### 10.7 Power & Battery

1. Go to **Setup > Power**
2. Configure battery parameters:
   - **Battery Monitor** — Enable/disable monitoring
   - **Voltage Divider** — Calibration factor (check your hardware docs)
   - **Amps per Volt** — Current sensor calibration
   - **Battery Capacity** — mAh rating of your battery
3. Set low battery thresholds:
   - **Failsafe Voltage** — Trigger first-stage warning
   - **Critical Voltage** — Trigger immediate landing

### 10.8 Motor Testing

> **WARNING:** Propellers should be removed during motor testing. Ensure the vehicle is secured and no one is near moving parts.

1. Go to **Setup > Motors**
2. Check the safety acknowledgment checkbox
3. Test individual motors using the slider controls
4. Verify motor rotation direction matches the airframe diagram

### 10.9 Safety Configuration

1. Go to **Setup > Safety**
2. Configure arming checks:
   - **Arming Check** — Enable/disable pre-arm validation
   - **USB Connected** — Allow arming when USB is connected (disables for safety)
3. Set failsafe behaviours:
   - **RC Loss** — Action on RC signal loss (Continue, Loiter, RTL, Land)
   - **Telemetry Loss** — Action on GCS heartbeat loss
   - **Low Battery** — Action on low battery threshold
   - **Geofence Breach** — Action on geofence violation

---

## 11. Application Settings

### 11.1 General Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Language | UI language selection | English |
| Units | Metric or Imperial | Metric |
| Map Provider | Map tile source (Google, Bing, Mapbox, OpenStreetMap) | Mapbox |
| Map Type | Satellite, Street, Hybrid, Terrain | Satellite |
| Theme | Application colour theme | Default (FWD Red) |

### 11.2 Video Settings

| Setting | Description |
|---------|-------------|
| Video Source | UDP, RTSP, TCP, or local file/device |
| UDP Port | Listening port for UDP video (default: 5600) |
| RTSP URL | Full URL for RTSP streams |
| Decode Method | Software or hardware accelerated |
| Record Path | Directory for saving recorded video files |
| Snapshot Path | Directory for saving captured frames |
| Overlay Enable | Show telemetry overlay on video |
| Overlay Items | Select which telemetry values to overlay |

### 11.3 MAVLink Settings

| Setting | Description |
|---------|-------------|
| Protocol Version | MAVLink 1 or 2 |
| Forward Endpoint | Forward MAVLink traffic to another IP/port |
| Log Telemetry | Save telemetry to .tlog file (always recommended) |
| Log Path | Directory for telemetry logs |
| Heartbeat Timeout | Seconds before considering vehicle disconnected |

### 11.4 Console / Debug Settings

| Setting | Description |
|---------|-------------|
| Developer Console | Enable debug console (requires restart) |
| Logging Level | Verbosity of log output (Debug, Info, Warn, Error) |
| Save Logs to File | Write logs to disk for troubleshooting |
| GStreamer Logging | Enable verbose GStreamer pipeline logging |

### 11.5 Offline Maps

1. Go to **Settings > Offline Maps**
2. Select the region on the map or enter coordinates
3. Select zoom levels to download (higher zoom = more detail, more storage)
4. Click **Download** 
5. Progress is shown; maps can be used offline once downloaded

---

## 12. Safety Parameters

### 12.1 Overview of Safety Parameters

The Safety Parameters section provides centralised configuration of all failsafe and safety-related settings. These parameters are critical for safe vehicle operation.

### 12.2 Arming Safety Checks

FWDGCS enforces pre-arm checks before allowing motor arming:

| Check | Description |
|-------|-------------|
| GPS Lock | Sufficient satellites and 3D fix |
| Battery Voltage | Voltage within acceptable range |
| Accelerometer | Calibration valid |
| Magnetometer | Calibration valid, no interference |
| Gyroscope | Calibration valid |
| RC Signal | Valid RC signal received |
| Throttle | Throttle at minimum |

To bypass arming checks (authorized personnel only):
- In **Settings > Safety**, disable **Arming Check**
- Or set `ARMING_CHECK = 0` in vehicle parameters

### 12.3 Failsafe Actions

Each failsafe trigger can have one of these actions:

| Action | Behaviour |
|--------|-----------|
| **Continue** | No action; log the event only |
| **Loiter** | Hold current position |
| **RTL** | Return to home and land |
| **Land** | Land immediately at current position |
| **Terminate** | Kill motors immediately (emergency only) |

### 12.4 Failsafe Triggers

| Failsafe | Trigger Condition | Recommended Action |
|----------|-------------------|--------------------|
| **RC Loss** | No RC signal for >5 seconds | RTL or Land |
| **Telemetry Loss** | No GCS heartbeat for >10 seconds | RTL |
| **Low Battery (Stage 1)** | Voltage below failsafe threshold | RTL |
| **Low Battery (Stage 2)** | Voltage below critical threshold | Land |
| **Geofence Breach** | Vehicle crosses geofence boundary | RTL |
| **Altitude Limit** | Vehicle exceeds max altitude | Loiter or RTL |

### 12.5 Return to Launch (RTL) Settings

| Parameter | Description | Recommended |
|-----------|-------------|-------------|
| RTL Altitude | Altitude to climb to before returning | 50–100m above home |
| RTL Climb | Whether to climb to RTL altitude first | Enabled |
| RTL Loiter Time | Time to loiter before landing | 0–30 seconds |
| RTL Descend Rate | Vertical speed during landing descent | 0.5–2 m/s |

### 12.6 Emergency Procedures

| Situation | Action |
|-----------|--------|
| Loss of control | Engage **Kill Switch** (RC or GCS) |
| Flyaway | Engage **RTL** immediately |
| Battery critical | Allow automatic land; do not override |
| Geofence breach | Monitor; vehicle will execute failsafe action |
| Video loss | Continue mission as planned; video is advisory only |

---

## 13. Data Persistence & Logs

### 13.1 Data Storage Locations

| Data Type | Windows | Linux | Android |
|-----------|---------|-------|---------|
| Configuration | `%APPDATA%/FWDGCS/` | `~/.config/FWDGCS/` | App internal storage |
| Telemetry Logs | `%USERPROFILE%/Documents/FWDGCS/Logs/` | `~/Documents/FWDGCS/Logs/` | `Android/data/com.fwdefence.fwdgcs/` |
| Missions | `%USERPROFILE%/Documents/FWDGCS/Missions/` | `~/Documents/FWDGCS/Missions/` | Shared storage/FWDGCS/Missions |
| Screenshots | `%USERPROFILE%/Pictures/FWDGCS/` | `~/Pictures/FWDGCS/` | Shared storage/Pictures/FWDGCS |
| Recordings | `%USERPROFILE%/Videos/FWDGCS/` | `~/Videos/FWDGCS/` | Shared storage/Movies/FWDGCS |

### 13.2 Telemetry Logs

FWDGCS automatically logs all MAVLink telemetry data while connected.

- **Format**: `.tlog` (MAVLink binary telemetry log)
- **Frequency**: One log file per connection session
- **Naming**: `YYYY-MM-DD_HH-MM-SS_vehiclename.tlog`

**Viewing Logs:**
1. Switch to **Analyze View** (Ctrl+4)
2. Click **Open Log** and select a `.tlog` file
3. The log replays telemetry data on the map and instruments
4. Use playback controls (Play, Pause, Speed, Timeline slider)

**Exporting Logs:**
- Logs can be exported to CSV format for external analysis
- Use the **Export** button in Analyze view

### 13.3 Crash Reports

If FWDGCS crashes unexpectedly:
1. A crash report dialog appears on next launch
2. Review the crash details
3. Click **Send Report** to transmit anonymized crash data to FWD for analysis
4. Crash reports help improve stability in future releases

### 13.4 Backup & Restore

**Backup:**
1. Close FWDGCS
2. Copy the configuration directory (see table above) to a safe location
3. Copy the Missions directory if you want to preserve mission files

**Restore:**
1. Close FWDGCS
2. Replace the configuration directory with your backup copy
3. Launch FWDGCS — settings will be restored

---

## 14. Troubleshooting & FAQ

### 14.1 Installation Issues

| Problem | Solution |
|---------|----------|
| Application fails to start | Check system requirements; reinstall; check antivirus logs |
| Missing DLL error (Windows) | Install Visual C++ Redistributable and GStreamer runtime |
| "libGL.so.1 not found" (Linux) | `sudo apt install libgl1-mesa-glx` |
| Permission denied (Linux) | `chmod +x` the AppImage; do not run from `/tmp` |
| APK won't install (Android) | Enable "Install from Unknown Sources" |

### 14.2 Connection Issues

| Problem | Solution |
|---------|----------|
| "No heartbeat received" | Check baud rate; verify autopilot power; check cable |
| Serial port not listed | Install USB-to-serial driver; check udev rules (Linux) |
| Radio not communicating | Verify radio pair; check power; test with another GCS |
| UDP/TCP connection refused | Check IP address and port; disable firewall temporarily |
| Intermittent connection | Check radio range; change channel; reduce interference |

### 14.3 Video Issues

| Problem | Solution |
|---------|----------|
| No video (black screen) | Verify source type/port/URL; check vehicle camera is powered |
| Video freezing | Reduce resolution; check network bandwidth; lower buffer |
| GStreamer errors | Install all GStreamer plugins: `gst-plugins-bad`, `-ugly`, `-good` |
| High CPU usage | Enable hardware decoding; reduce video resolution |
| Video/audio desync | Adjust latency settings in video pipeline |
| No video overlay | Enable overlays in Settings > Video > Overlay |

### 14.4 Login Issues

| Problem | Solution |
|---------|----------|
| Cannot log in | Check username/password; ensure network if server auth is used |
| "Server unreachable" | Contact administrator; check network connection |
| Account locked | Wait 15 minutes; contact administrator to unlock |
| Session expired | Re-enter credentials |
| Register button disabled | Registration is handled by the administrator |

### 14.5 Mission Issues

| Problem | Solution |
|---------|----------|
| Upload failed | Check vehicle is connected and armed/disarmed appropriately |
| Waypoints not accepted | Too many waypoints; invalid command parameters; GPS not ready |
| Mission won't execute | Switch to Auto mode; verify GPS lock; check arming status |
| Geofence breach warning | Check geofence boundaries; adjust if necessary |

### 14.6 General FAQ

**Q: How do I update the autopilot firmware?**
A: Go to **Setup > Firmware**, select the firmware type, and click **Flash Firmware**.

**Q: How do I calibrate the compass?**
A: Go to **Setup > Sensors > Compass** and follow the rotation instructions.

**Q: How do I set up a new vehicle?**
A: Follow the Setup View wizard in order: Firmware > Airframe > Sensors > Radio > Flight Modes > Power > Safety.

**Q: How do I record video?**
A: Ensure a video feed is active, then click the **Record** button in the video controls panel.

**Q: How do I change video source?**
A: Go to **Settings > Video** and configure the source type and parameters.

**Q: How do I log out?**
A: Click the **profile icon** on the toolbar, then select **Log Out**.

**Q: Can I use multiple vehicles at once?**
A: Yes, connect to each vehicle through separate connections and switch between them using the Vehicle Selector.

**Q: How do I get help?**
A: Contact FWD Defence support or your system administrator.

---

## 15. Appendix

### 15.1 Keyboard Shortcuts Reference

| Shortcut | Function |
|----------|----------|
| Ctrl+1 | Fly View |
| Ctrl+2 | Plan View |
| Ctrl+3 | Setup View |
| Ctrl+4 | Analyze View |
| Ctrl+F | Toggle fullscreen |
| Ctrl+N | New plan |
| Ctrl+O | Open plan file |
| Ctrl+S | Save plan |
| Ctrl+Shift+S | Save plan as |
| Ctrl+Q | Quit |
| Ctrl+, | Settings |
| Ctrl++ | Zoom in (map) |
| Ctrl+- | Zoom out (map) |
| I | Arm |
| O | Disarm |
| Space | RTL (with confirmation) |
| R | Toggle recording |
| S | Snapshot |
| M | Mute/unmute |
| F11 | Toggle fullscreen |
| Esc | Exit fullscreen / close dialog |
| Delete | Delete selected waypoint |
| Home | Centre map on vehicle |

### 15.2 MAVLink Message Reference

Common MAVLink messages used by FWDGCS:

| Message | ID | Description |
|---------|-----|-------------|
| HEARTBEAT | 0 | System status and flight mode |
| SYS_STATUS | 1 | Battery voltage, current, errors |
| GPS_RAW_INT | 24 | GPS position, fix type, satellites |
| ATTITUDE | 30 | Roll, pitch, yaw |
| LOCAL_POSITION_NED | 32 | Local position relative to origin |
| GLOBAL_POSITION_INT | 33 | Global position, altitude, heading |
| BATTERY_STATUS | 147 | Detailed battery data |
| VFR_HUD | 74 | Airspeed, groundspeed, altitude, climb |
| SCALED_IMU | 26 | IMU sensor data |
| RC_CHANNELS | 65 | RC input channel values |
| COMMAND_ACK | 77 | Command acknowledgement |
| MISSION_ITEM | 39 | Waypoint/mission item |
| MISSION_COUNT | 44 | Total mission item count |
| STATUSTEXT | 253 | Text messages from vehicle |

### 15.3 Supported File Formats

| Format | Extension | Purpose |
|--------|-----------|---------|
| FWDGCS Plan | `.plan` | Complete mission plan with all settings |
| Waypoints | `.waypoints` | Plain-text waypoint list |
| MAVLink Log | `.tlog` | Binary telemetry log |
| Binary Log | `.bin` | ArduPilot dataflash log |
| ULog | `.ulog` | PX4 binary log |
| Parameter | `.param` | Vehicle parameter export/import |
| Image | `.png`, `.jpg` | Screenshots and snapshots |
| Video | `.mp4`, `.mkv` | Recorded video |

### 15.4 GStreamer Pipeline Reference

**UDP H.264 (default):**
```
udpsrc port=5600 ! application/x-rtp,media=video,encoding-name=H264 ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! qtvideosink
```

**UDP H.265:**
```
udpsrc port=5600 ! application/x-rtp,media=video,encoding-name=H265 ! rtph265depay ! h265parse ! avdec_h265 ! videoconvert ! qtvideosink
```

**RTSP H.264:**
```
rtspsrc location=rtsp://192.168.1.100:8554/stream ! rtph264depay ! h264parse ! avdec_h264 ! videoconvert ! qtvideosink
```

**Local file playback:**
```
filesrc location=/path/to/video.mp4 ! qtdemux ! h264parse ! avdec_h264 ! videoconvert ! qtvideosink
```

### 15.5 Glossary of Terms

| Term | Definition |
|------|------------|
| **AHRS** | Attitude and Heading Reference System — provides orientation data |
| **APM** | ArduPilot Mega — open-source autopilot firmware |
| **ESC** | Electronic Speed Controller — controls motor speed |
| **Failsafe** | Automatic behaviour when a critical parameter exceeds safe limits |
| **GCS** | Ground Control Station |
| **HDOP** | Horizontal Dilution of Precision — measure of GPS accuracy |
| **IMU** | Inertial Measurement Unit — accelerometers and gyroscopes |
| **MAVLink** | Micro Air Vehicle Link — communication protocol |
| **PFD** | Primary Flight Display — attitude and heading instrument |
| **PWM** | Pulse Width Modulation — signal type for servo/ESC control |
| **PX4** | Professional autopilot firmware |
| **RSSI** | Received Signal Strength Indicator |
| **RTK** | Real-Time Kinematic — high-precision GPS |
| **RTL** | Return to Launch |
| **VTOL** | Vertical TakeOff and Landing |

### 15.6 Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | May 2026 | Enhanced video controls; custom login system; FWD branding; safety parameters UI; code cleanup |
| 1.0 | Initial | Navy GCS baseline based on upstream QGC |

### 15.7 Known Issues & Limitations

- Login system currently accepts empty credentials (server-side authentication pending)
- Registration is a stub — user accounts must be created by administrator
- Some video codecs may require additional GStreamer plugins not bundled by default
- Multiple vehicle support is functional but UI switching may exhibit minor latency
- Offline maps require manual download before use

---

*End of Document — FWDGCS v2 User Manual*

*For support, contact: FWD Defence Team*
*Document maintained at: https://github.com/fwdefence/FWDGCSv2*
