import Foundation
import CoreBluetooth
import Combine

enum PaymentStatus: String {
    case unpaid = "0"
    case paypay = "P"
    case cash = "C"
    case bank = "B"
    case completed = "K"
    
    var icon: String {
        switch self {
        case .unpaid: return "circle"
        case .paypay: return "creditcard.fill"
        case .cash: return "banknote.fill"
        case .bank: return "building.columns.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .unpaid: return "gray"
        case .paypay: return "blue"
        case .cash: return "green"
        case .bank: return "purple"
        case .completed: return "red"
        }
    }
}

struct Member: Identifiable, Equatable {
    let id: String // Currenty just the name for uniqueness
    let name: String
    var status: PaymentStatus
    var actualFee: Int?
    var prefPayment: String // P, B, C
}

class HostScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var checkedInMembers: [Member] = []
    @Published var bluetoothState: CBManagerState = .unknown
    
    private var centralManager: CBCentralManager?
    private let serviceUUID = CBUUID(string: "A67E4256-65F9-4674-884A-B6A316E2B1A7")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager?.state == .poweredOn else { return }
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("Host is scanning for check-in signals...")
    }
    
    func stopScanning() {
        centralManager?.stopScan()
    }
    
    func updateMemberStatus(name: String, status: PaymentStatus, fee: Int? = nil) {
        if let index = checkedInMembers.firstIndex(where: { $0.name == name }) {
            checkedInMembers[index].status = status
            if let fee = fee {
                checkedInMembers[index].actualFee = fee
            }
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        if central.state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            // Format: "Name|Status|PayPref"
            let parts = advertisedName.split(separator: "|", omittingEmptySubsequences: false)
            let name = String(parts[0])
            let statusCode = parts.count > 1 ? String(parts[1]) : "0"
            let payPref = parts.count > 2 ? String(parts[2]) : "P"
            
            let status = PaymentStatus(rawValue: statusCode) ?? .unpaid
            
            DispatchQueue.main.async {
                if let index = self.checkedInMembers.firstIndex(where: { $0.name == name }) {
                    // Update if status changed (and not manually marked as completed unless the remote says so?)
                    // For now, let the remote update unless it's locally marked completed which takes priority?
                    if self.checkedInMembers[index].status != .completed {
                        self.checkedInMembers[index].status = status
                    }
                    self.checkedInMembers[index].prefPayment = payPref
                } else {
                    let newMember = Member(
                        id: name,
                        name: name,
                        status: status,
                        prefPayment: payPref
                    )
                    self.checkedInMembers.append(newMember)
                    print("Discovered member: \(name) with status \(status), pref: \(payPref)")
                }
            }
        }
    }
}
