# QGroundControl Ground Control Station

[![Releases](https://img.shields.io/github/release/mavlink/QGroundControl.svg)](https://github.com/mavlink/QGroundControl/releases)

*QGroundControl* (QGC) is an intuitive and powerful ground control station (GCS) for UAVs.

The primary goal of QGC is ease of use for both first time and professional users.
It provides full flight control and mission planning for any MAVLink enabled drone, and vehicle setup for both PX4 and ArduPilot powered UAVs. Instructions for *using QGroundControl* are provided in the [User Manual](https://docs.qgroundcontrol.com/en/) (you may not need them because the UI is very intuitive!)

All the code is open-source, so you can contribute and evolve it as you want.
The [Developer Guide](https://dev.qgroundcontrol.com/en/) explains how to [build](https://dev.qgroundcontrol.com/en/getting_started/) and extend QGC.


Key Links:
* [Website](http://qgroundcontrol.com) (qgroundcontrol.com)
* [User Manual](https://docs.qgroundcontrol.com/en/)
* [Developer Guide](https://dev.qgroundcontrol.com/en/)
* [Discussion/Support](https://docs.qgroundcontrol.com/en/Support/Support.html)
* [Contributing](https://dev.qgroundcontrol.com/en/contribute/)
* [License](https://github.com/mavlink/qgroundcontrol/blob/master/COPYING.md)

# Building QGroundControl 4.4.0 for Android

This guide explains how to build **QGroundControl 4.4.0** for Android, including the installation of required tools, configuration of paths, and troubleshooting common issues.

## 1. Requirements

Ensure that the following versions are installed on your system:

- **Qt**: 5.15.2
- **JDK**: 20
- **Android SDK**: 35
- **Android NDK**: 21

### Tool Descriptions
- **Qt**: A cross-platform C++ framework used for developing applications with graphical user interfaces (GUIs) across mobile, desktop, and embedded systems.
- **JDK (Java Development Kit)**: Required for the Java-based components of the Android build process.
- **Android SDK (Software Development Kit)**: Provides the necessary tools for developing and testing Android applications.
- **Android NDK (Native Development Kit)**: Required for compiling native code for Android.
- **Gradle**: An automation tool used for managing dependencies and building Android projects.
- **Android Gradle Plugin (AGP)**: A plugin that integrates Gradle with Android Studio and helps in building Android projects.

## 2. Configuring Qt Creator for Android

### Step 1: Open Qt Creator Preferences
1. Launch **Qt Creator**.
   - **macOS**: Click on **Qt Creator > Preferences**.
   - **Windows/Linux**: Click on **Tools > Options**.

### Step 2: Go to the Android Tab
1. In the preferences window, navigate to the **Android** tab.

### Step 3: Set JDK, SDK, and NDK Paths
1. **JDK Location**: Set the path to **JDK 20**:
   - Example path (Windows): `C:\Program Files\Java\jdk-20`
   - Example path (macOS/Linux): `/Library/Java/JavaVirtualMachines/jdk-20.jdk/Contents/Home`
   
2. **SDK Location**: Set the path to the Android SDK:
   - Example path (Windows): `C:\Users\<YourUsername>\AppData\Local\Android\Sdk`
   - Example path (macOS/Linux): `~/Library/Android/sdk`
   
3. **NDK Location**: Set the path to **NDK 21**:
   - Example path: `<SDK_Path>/ndk/21.4.7075529`

### Step 4: Verify Android Kit
1. Ensure that the correct **Android Kit** is selected for your project.
 ![image](https://github.com/user-attachments/assets/0f913b7e-0b49-4673-b47b-156fca1664bc)


## 3. Setting Up `ANDROID_PACKAGE_SOURCE_DIR`

### Step 1: Create `ANDROID_PACKAGE_SOURCE_DIR`
1. Navigate to the build folder:
2. Create a new folder named `ANDROID_PACKAGE_SOURCE_DIR`.

### Step 2: Copy Android Files
1. Locate the `android` folder in the main **QGroundControl** directory:
2. Copy all files from the `android` folder into the newly created `ANDROID_PACKAGE_SOURCE_DIR` folder:

## 4. Building the Project

1. After configuring the paths and copying the Android resources, start the build process in **Qt Creator**.
2. Select the Android kit and click on **Build**.
3. Make sure to select the **Multi-ABI** option. This allows your application to run on multiple Android architectures.
4. Wait for the build process to complete.

## 5. java.lang.NoClassDefFoundError: Could not initialize class org.codehaus.groovy.vmplugin.v7.Java7 Error

### Error
If you encounter a **Java 7** related error, such as:
### Solution
1. **Clone the Configuration Repository**: 
   To resolve this error, clone the following repository which contains the necessary configuration files:https://github.com/KaanCL/QGC-4.4.0-AndroidConfig

2. **Replace Files**:
Copy the contents of the cloned repository into your `android-build` directory:

3. **Rebuild the Project**:
After copying the files, restart the build process in **Qt Creator**.

Following these steps should resolve the Java 7 related errors.
