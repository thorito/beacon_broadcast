import Flutter
import UIKit
import CoreLocation
import CoreBluetooth

public class SwiftBeaconBroadcastPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var locationManager: CLLocationManager?
    private var bluetoothManager: CBCentralManager?
    private var beacon = Beacon()
    private var eventSink: FlutterEventSink?
    private var permissionResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftBeaconBroadcastPlugin()

        let channel = FlutterMethodChannel(
            name: "pl.pszklarska.beaconbroadcast/beacon_state",
            binaryMessenger: registrar.messenger())

        let beaconEventChannel = FlutterEventChannel(
            name: "pl.pszklarska.beaconbroadcast/beacon_events",
            binaryMessenger: registrar.messenger())
        beaconEventChannel.setStreamHandler(instance)
        instance.registerBeaconListener()

        registrar.addMethodCallDelegate(instance, channel: channel)

        // Setup managers
        instance.setupLocationManager()
        instance.setupBluetoothManager()
    }

    public func onListen(
        withArguments arguments: Any?,
        eventSink: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    func registerBeaconListener() {
        beacon.onAdvertisingStateChanged = { isAdvertising in
            if (self.eventSink != nil) {
                self.eventSink!(isAdvertising)
            }
        }
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "start":
            startBeacon(call, result)
        case "stop":
            stopBeacon(call, result)
        case "isAdvertising":
            isAdvertising(call, result)
        case "isTransmissionSupported":
            isTransmissionSupported(call, result)
        case "checkPermissionStatus":
            checkPermissionStatus(result: result)
        case "requestPermissions":
            requestPermissions(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func setupBluetoothManager() {
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func isAdvertising(
        _ call: FlutterMethodCall,
        _ result: @escaping FlutterResult
    ) {
        result(beacon.isAdvertising())
    }

    private func isTransmissionSupported(
        _ call: FlutterMethodCall,
        _ result: @escaping FlutterResult
    ) {
        result(0)
    }

    private func checkPermissionStatus(result: @escaping FlutterResult) {
        let locationStatus = getLocationPermissionStatus()
        let bluetoothStatus = getBluetoothPermissionStatus()

        let permissionStatus: [String: String] = [
            "location": locationStatus,
            "bluetooth": bluetoothStatus,
            "bluetoothConnect": getBluetoothConnectPermissionStatus(),
            "bluetoothAdvertise": getBluetoothAdvertisePermissionStatus(),
        ]

        result(permissionStatus)
    }

    private func getLocationPermissionStatus() -> String {
        let authorizationStatus: CLAuthorizationStatus

        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        switch authorizationStatus {
        case .authorizedAlways:
            return "AUTHORIZED_ALWAYS"
        case .authorizedWhenInUse:
            return "AUTHORIZED_WHEN_IN_USE"
        case .denied:
            return "DENIED"
        case .restricted:
            return "RESTRICTED"
        case .notDetermined:
            return "NOT_DETERMINED"
        @unknown default:
            return "NOT_DETERMINED"
        }
    }

    private func getBluetoothPermissionStatus() -> String {
        guard let bluetoothManager = bluetoothManager else {
            return "NOT_DETERMINED"
        }

        switch bluetoothManager.state {
        case .poweredOn:
            return "AUTHORIZED"
        case .poweredOff:
            return "POWERED_OFF"
        case .unauthorized:
            return "DENIED"
        case .unsupported:
            return "UNSUPPORTED"
        case .resetting:
            return "RESETTING"
        case .unknown:
            return "UNKNOWN"
        @unknown default:
            return "UNKNOWN"
        }
    }

    private func getBluetoothConnectPermissionStatus() -> String {
        if #available(iOS 13.1, *) {
            switch CBCentralManager.authorization {
            case .allowedAlways:
                return "AUTHORIZED"
            case .denied:
                return "DENIED"
            case .restricted:
                return "RESTRICTED"
            case .notDetermined:
                return "NOT_DETERMINED"
            @unknown default:
                return "NOT_DETERMINED"
            }
        } else {
            return getBluetoothPermissionStatus()
        }
    }

    private func getBluetoothAdvertisePermissionStatus() -> String {
        if #available(iOS 13.1, *) {
            switch CBPeripheralManager.authorization {
            case .allowedAlways:
                return "AUTHORIZED"
            case .denied:
                return "DENIED"
            case .restricted:
                return "RESTRICTED"
            case .notDetermined:
                return "NOT_DETERMINED"
            @unknown default:
                return "NOT_DETERMINED"
            }
        } else {
            return "NOT_DETERMINED"
        }
    }

    private func requestPermissions(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(false)
            return
        }

        // Store the result callback for later use
        permissionResult = result

        let locationStatus = getLocationPermissionStatus()

        switch locationStatus {
        case "NOT_DETERMINED":
            locationManager.requestAlwaysAuthorization()
        case "AUTHORIZED_WHEN_IN_USE":
            locationManager.requestAlwaysAuthorization()
        case "AUTHORIZED_ALWAYS":
            checkAndRequestBluetoothPermissions(result: result)
        case "DENIED", "RESTRICTED":
            result(false)
        default:
            result(false)
        }
    }

    private func checkAndRequestBluetoothPermissions(result: @escaping FlutterResult) {
        let bluetoothStatus = getBluetoothPermissionStatus()

        switch bluetoothStatus {
        case "AUTHORIZED":
            result(true)
        case "POWERED_OFF":
            result(true)
        case "DENIED", "RESTRICTED", "UNSUPPORTED":
            result(false)
        case "NOT_DETERMINED", "UNKNOWN", "RESETTING":
            requestBluetoothPermissionsIfNeeded(result: result)
        default:
            result(false)
        }
    }

    private func requestBluetoothPermissionsIfNeeded(result: @escaping FlutterResult) {
        if #available(iOS 13.1, *) {
            let connectStatus = CBCentralManager.authorization
            if connectStatus == .notDetermined {
                let tempManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    result(true)
                }
                return
            }
        }

        if #available(iOS 13.1, *) {
            if CBPeripheralManager.authorization == .notDetermined {
                let tempPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: false])

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    result(true)
                }
                return
            }
        }

        result(true)
    }

    private func startBeacon(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(false)
            return
        }

        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            result(false)
            return
        }

        guard let bluetoothManager = bluetoothManager,
              bluetoothManager.state == .poweredOn else {
            result(false)
            return
        }

        guard let map = call.arguments as? Dictionary<String, Any>,
              let uuid = map["uuid"] as? String,
              let identifier = map["identifier"] as? String else {
            result(false)
            return
        }

        let majorId = map["majorId"] as? NSNumber
        let minorId = map["minorId"] as? NSNumber
        let transmissionPower = map["transmissionPower"] as? NSNumber
        let layout = map["layout"] as? String

        let beaconData = BeaconData(
            uuid: uuid,
            majorId: majorId,
            minorId: minorId,
            transmissionPower: transmissionPower,
            identifier: identifier,
            layout: layout
        )

        beacon.start(beaconData: beaconData)
        result(nil)
    }

    private func stopBeacon(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        beacon.stop()
        result(nil)
    }
}

// MARK: - CLLocationManagerDelegate
extension SwiftBeaconBroadcastPlugin: CLLocationManagerDelegate {
    public func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        // Handle permission changes
        if let result = permissionResult {
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                result(true)
            case .denied, .restricted:
                result(false)
            case .notDetermined:
                // Still waiting for user response
                return
            @unknown default:
                result(false)
            }
            permissionResult = nil
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension SwiftBeaconBroadcastPlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle Bluetooth state changes
        // This method is required by CBCentralManagerDelegate
    }

    // Optional methods can be added here if needed
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Handle discovered peripherals if needed
    }
}

// MARK: - CBPeripheralManagerDelegate
extension SwiftBeaconBroadcastPlugin: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // Handle peripheral manager state changes
        // This method is required by CBPeripheralManagerDelegate
    }

    // Optional methods can be added here if needed
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        // Handle advertising start/stop events if needed
    }
}
