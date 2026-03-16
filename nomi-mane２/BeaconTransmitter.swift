import Foundation
import CoreLocation
import CoreBluetooth
import Combine

class BeaconTransmitter: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published var isAdvertising = false
    @Published var bluetoothState: CBManagerState = .unknown
    
    private var peripheralManager: CBPeripheralManager?
    private var beaconUUID: UUID? {
        UUID(uuidString: "7827AA20-2884-428A-A3F0-9E64F976226D")
    }
    private let major: CLBeaconMajorValue = 1
    private let minor: CLBeaconMinorValue = 1
    private let beaconIdentifier = "jp.momoyama-tech.nomi-mane.beacon"
    
    // セッションデータ用のGATTサービス
    private let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-47A8-B9C0-D1E2F3A4B5C6")
    private let feeCharacteristicUUID = CBUUID(string: "11223344-5566-7788-9900-AABBCCDDEEFF")
    private let urlCharacteristicUUID = CBUUID(string: "FFEEDDCC-BBAA-9988-7766-554433221100")
    private let bankInfoCharacteristicUUID = CBUUID(string: "B0B0B0B0-B0B0-40B0-B0B0-B0B0B0B0B0B0")
    
    private var currentFee: String = ""
    private var currentURL: String = ""
    private var currentBankInfo: String = ""
    
    // Preparation for sending profile name
    private var userNickname: String {
        UserDefaults.standard.string(forKey: "user_nickname") ?? "Unknown"
    }
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising(fee: String, url: String, bankInfo: String) {
        guard bluetoothState == .poweredOn else { return }
        
        self.currentFee = fee
        self.currentURL = url
        self.currentBankInfo = bankInfo
        
        // Setup GATT Service
        let feeCharacteristic = CBMutableCharacteristic(
            type: feeCharacteristicUUID,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        
        let urlCharacteristic = CBMutableCharacteristic(
            type: urlCharacteristicUUID,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        let bankCharacteristic = CBMutableCharacteristic(
            type: bankInfoCharacteristicUUID,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        
        service.characteristics = [feeCharacteristic, urlCharacteristic, bankCharacteristic]
        
        peripheralManager?.removeAllServices()
        peripheralManager?.add(service)
        
        // Setup iBeacon Advertisement
        guard let uuid = beaconUUID else {
            print("Invalid Beacon UUID")
            return
        }
        let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: major, minor: minor)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: beaconIdentifier)
        let beaconData = beaconRegion.peripheralData(withMeasuredPower: nil) as? [String: Any]
        
        var advertisementData: [String: Any] = beaconData ?? [:]
        advertisementData[CBAdvertisementDataServiceUUIDsKey] = [serviceUUID]
        advertisementData[CBAdvertisementDataLocalNameKey] = userNickname
        
        peripheralManager?.startAdvertising(advertisementData)
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        isAdvertising = false
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        bluetoothState = peripheral.state
        if peripheral.state != .poweredOn {
            isAdvertising = false
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == feeCharacteristicUUID {
            request.value = currentFee.data(using: .utf8)
            peripheral.respond(to: request, withResult: .success)
        } else if request.characteristic.uuid == urlCharacteristicUUID {
            request.value = currentURL.data(using: .utf8)
            peripheral.respond(to: request, withResult: .success)
        } else if request.characteristic.uuid == bankInfoCharacteristicUUID {
            request.value = currentBankInfo.data(using: .utf8)
            peripheral.respond(to: request, withResult: .success)
        } else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Failed to start advertising: \(error.localizedDescription)")
            isAdvertising = false
        } else {
            print("Successfully started advertising iBeacon & GATT Service")
            isAdvertising = true
        }
    }
}
