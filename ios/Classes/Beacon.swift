//
//  Beacon.swift
//
//  Created by Paulina Szklarska on 23/01/2019.
//  Copyright © 2019 Paulina Szklarska. All rights reserved.
//  Updated by Victor Villar on 29/05/2025

import Foundation
import CoreBluetooth
import CoreLocation

class Beacon : NSObject, CBPeripheralManagerDelegate {

    var peripheralManager: CBPeripheralManager!
    var beaconPeripheralData: NSDictionary!
    var onAdvertisingStateChanged: ((Bool) -> Void)?

    var shouldStartAdvertise: Bool = false

    func start(beaconData: BeaconData) {
        guard let proximityUUID = UUID(uuidString: beaconData.uuid) else {
            print("Error: UUID invalid - \(beaconData.uuid)")
            return
        }

        let major = beaconData.majorId?.uint16Value ?? 0
        let minor = beaconData.minorId?.uint16Value ?? 0
        let beaconID = beaconData.identifier

        let beaconConstraint = CLBeaconIdentityConstraint(
            uuid: proximityUUID,
            major: major,
            minor: minor
        )

        let region = CLBeaconRegion(
            beaconIdentityConstraint: beaconConstraint,
            identifier: beaconID
        )

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        beaconPeripheralData = region.peripheralData(withMeasuredPower: beaconData.transmissionPower)
        shouldStartAdvertise = true
    }

    func stop() {
        if (peripheralManager != nil) {
            peripheralManager.stopAdvertising()
            onAdvertisingStateChanged!(false)
        }
    }

    func isAdvertising() -> Bool {
        if (peripheralManager == nil) {
            return false
        }
        return peripheralManager.isAdvertising
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        onAdvertisingStateChanged!(peripheral.isAdvertising)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheral.state == .poweredOn && shouldStartAdvertise) {
            peripheralManager.startAdvertising(((beaconPeripheralData as NSDictionary) as! [String : Any]))
            shouldStartAdvertise = false
        }
    }

}

class BeaconData {
    var uuid: String
    var majorId: NSNumber?
    var minorId: NSNumber?
    var transmissionPower: NSNumber?
    var identifier: String
    let layout: String?

    init(uuid: String, majorId:NSNumber?, minorId: NSNumber?, transmissionPower: NSNumber?, identifier: String, layout: String? = nil) {
        self.uuid = uuid
        self.majorId = majorId
        self.minorId = minorId
        self.transmissionPower = transmissionPower
        self.identifier = identifier
        self.layout = layout
    }
}
