import Flutter
import UIKit


public class SwiftBeaconBroadcastPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var beacon = Beacon()
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftBeaconBroadcastPlugin()
        
        let channel = FlutterMethodChannel(name: "pl.pszklarska.beaconbroadcast/beacon_state", binaryMessenger: registrar.messenger())
        
        let beaconEventChannel = FlutterEventChannel(name: "pl.pszklarska.beaconbroadcast/beacon_events", binaryMessenger: registrar.messenger())
        beaconEventChannel.setStreamHandler(instance)
        instance.registerBeaconListener()
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }
    
    func registerBeaconListener() {
        beacon.onAdvertisingStateChanged = {isAdvertising in
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startBeacon(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let map = call.arguments as? Dictionary<String, Any> else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }

        guard let uuid = map["uuid"] as? String,
              let majorId = map["majorId"] as? NSNumber,
              let minorId = map["minorId"] as? NSNumber,
              let identifier = map["identifier"] as? String else {
            result(FlutterError(code: "MISSING_ARGUMENTS", message: "Missing required arguments", details: nil))
            return
        }

        let beaconData = BeaconData(
            uuid: uuid,
            majorId: majorId,
            minorId: minorId,
            transmissionPower: map["transmissionPower"] as? NSNumber,
            identifier: identifier
        )

        // Validate UUID format
        guard UUID(uuidString: uuid) != nil else {
            result(FlutterError(code: "INVALID_UUID", message: "UUID invalid: \(uuid)", details: nil))
            return
        }
        
        beacon.start(beaconData: beaconData)
        result(nil)
    }
    
    private func stopBeacon(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        beacon.stop()
        result(nil)
    }
    
    private func isAdvertising(_ call: FlutterMethodCall,
                               _ result: @escaping FlutterResult) {
        result(beacon.isAdvertising())
    }
    
    private func isTransmissionSupported(_ call: FlutterMethodCall,
                               _ result: @escaping FlutterResult) {
        result(0)
    }
}
