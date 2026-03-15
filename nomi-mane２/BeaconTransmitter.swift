import Foundation
import CoreLocation
import CoreBluetooth
import Combine

class BeaconTransmitter: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published var isAdvertising = false
    @Published var bluetoothState: CBManagerState = .unknown
    
    private var peripheralManager: CBPeripheralManager?
    private let beaconUUID = UUID(uuidString: "7827AA20-2884-428A-A3F0-9E64F976226D")!
    private let major: CLBeaconMajorValue = 1
    private let minor: CLBeaconMinorValue = 1
    private let beaconIdentifier = "jp.momoyama-tech.nomi-mane.beacon"
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising() {
        guard bluetoothState == .poweredOn else { return }
        
        let constraint = CLBeaconIdentityConstraint(uuid: beaconUUID, major: major, minor: minor)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: beaconIdentifier)
        let peripheralData = beaconRegion.peripheralData(withMeasuredPower: nil) as? [String: Any]
        
        peripheralManager?.startAdvertising(peripheralData)
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        isAdvertising = false
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        bluetoothState = peripheral.state
        if peripheral.state != .poweredOn {
            isAdvertising = false
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Failed to start advertising: \(error.localizedDescription)")
            isAdvertising = false
        } else {
            print("Successfully started advertising iBeacon")
            isAdvertising = true
        }
    }
}
