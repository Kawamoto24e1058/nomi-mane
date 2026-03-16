import Foundation
import CoreLocation
import CoreBluetooth
import Combine
import SwiftUI

class BeaconDetector: NSObject, ObservableObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var detected = false
    @Published var isSearching = false
    @Published var receivedFee: String = ""
    @Published var receivedURL: String = ""
    @Published var receivedBankInfo: String = ""
    @Published var paymentStatus: String = "0" // 0: Unpaid, P: PayPay, C: Cash, B: Bank, K: Completed
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var discoveredPeripheral: CBPeripheral?
    
    private var beaconUUID: UUID? {
        UUID(uuidString: "7827AA20-2884-428A-A3F0-9E64F976226D")
    }
    private let beaconIdentifier = "jp.momoyama-tech.nomi-mane.beacon"
    
    // GATT Service for Session Data
    private let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-47A8-B9C0-D1E2F3A4B5C6")
    private let feeCharacteristicUUID = CBUUID(string: "11223344-5566-7788-9900-AABBCCDDEEFF")
    private let urlCharacteristicUUID = CBUUID(string: "FFEEDDCC-BBAA-9988-7766-554433221100")
    private let bankInfoCharacteristicUUID = CBUUID(string: "B0B0B0B0-B0B0-40B0-B0B0-B0B0B0B0B0B0")
    
    // Check-in Signal (Advertising to Host)
    private let checkInServiceUUID = CBUUID(string: "A67E4256-65F9-4674-884A-B6A316E2B1A7")
    
    // Preparation for receiving or matching profile name
    private var userNickname: String {
        UserDefaults.standard.string(forKey: "user_nickname") ?? "Unknown"
    }
    
    @AppStorage("payment_pref") private var paymentPref: String = "P"
    
    override init() {
        super.init()
        locationManager.delegate = self
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        isSearching = true
        detected = false
        receivedFee = ""
        receivedURL = ""
        receivedBankInfo = ""
        paymentStatus = "0"
        
        // Request permissions
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            startRanging()
        }
    }
    
    func stopScanning() {
        guard let uuid = beaconUUID else { return }
        let constraint = CLBeaconIdentityConstraint(uuid: uuid)
        locationManager.stopRangingBeacons(satisfying: constraint)
        isSearching = false
        peripheralManager?.stopAdvertising()
        centralManager?.stopScan()
        if let peripheral = discoveredPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    private func startRanging() {
        guard let uuid = beaconUUID else {
            print("Invalid Beacon UUID")
            return
        }
        let constraint = CLBeaconIdentityConstraint(uuid: uuid)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: beaconIdentifier)
        
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: constraint)
    }
    
    // MARK: - Advertisement Logic (To Host)
    
    private func startAdvertisingProfile() {
        guard peripheralManager?.state == .poweredOn else { return }
        
        // Send format: "Nickname|Status|PayPref"
        let advertisedName = "\(userNickname)|\(paymentStatus)|\(paymentPref)"
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [checkInServiceUUID],
            CBAdvertisementDataLocalNameKey: advertisedName
        ]
        
        peripheralManager?.stopAdvertising()
        peripheralManager?.startAdvertising(advertisementData)
        print("Advertising: \(advertisedName)")
    }
    
    func updatePaymentStatus(_ status: String) {
        DispatchQueue.main.async {
            self.paymentStatus = status
            if self.detected {
                self.startAdvertisingProfile()
            }
        }
    }
    
    // MARK: - Scanning Logic (From Host)
    
    private func startScanningForHostData() {
        guard centralManager?.state == .poweredOn else { return }
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            startRanging()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        if !beacons.isEmpty && !detected {
            DispatchQueue.main.async {
                self.detected = true
                self.isSearching = false
                self.startAdvertisingProfile()
                self.startScanningForHostData()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && detected {
            startScanningForHostData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripheral = peripheral
        central.connect(peripheral, options: nil)
        central.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) {
            peripheral.discoverCharacteristics([feeCharacteristicUUID, urlCharacteristicUUID, bankInfoCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, let value = String(data: data, encoding: .utf8) else { return }
        
        DispatchQueue.main.async {
            if characteristic.uuid == self.feeCharacteristicUUID {
                self.receivedFee = value
            } else if characteristic.uuid == self.urlCharacteristicUUID {
                self.receivedURL = value
            } else if characteristic.uuid == self.bankInfoCharacteristicUUID {
                self.receivedBankInfo = value
            }
            
            // 全てのGATT情報が取得できたら切断（URLは必須、銀行情報は任意の場合もあるが基本的に揃うまで待つ）
            if !self.receivedFee.isEmpty && !self.receivedURL.isEmpty && !self.receivedBankInfo.isEmpty {
                self.centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn && detected {
            startAdvertisingProfile()
        }
    }
}
