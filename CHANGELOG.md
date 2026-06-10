## 0.3.5
- Android: Updated to Gradle 8.14, AGP 8.11.1, Kotlin 2.2.20 (built-in), compileSdk 35, minSdk 24
- iOS: Migrated from CocoaPods to Swift Package Manager (SPM)
- iOS: Added UIScene lifecycle support
- iOS: Added Bluetooth and Location usage descriptions to Info.plist
- Example: Added platform-aware permission handling (permission_handler on Android, Info.plist on iOS)
- Example: Improved UI with visual beacon status indicator and mutually exclusive START/STOP buttons

## 0.3.4
Updated dependencies
Check values on start.

## 0.3.3
Updated dependencies

## 0.3.1

Added support for android apps targetting SDK 31 and above

## 0.3.0

Added support for null safety
Added support for nullable identifiers (e.g. for the Eddystone layout)

## 0.2.3

Fixed data fields support on Android

## 0.2.2

Added support for setting data fields on Android
Added support for setting advertisement mode on Android

## 0.2.1

Updated the documentation

## 0.2.0

Added option to set manufacturer and layout for Android. 


## 0.1.2

Updates in the documentation


## 0.1.1

Added method for checking if transmission is supported on the device.


## 0.1.0

First stable version of the app. No major changes


## 0.0.1

Initial version of the library. This version includes:
* starting and stopping beacon advertising
* setting beacon UUID, major id, minor id, transmission power and identifier 
