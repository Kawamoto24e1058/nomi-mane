import Foundation
import CoreLocation
import Combine

class BeaconDetector: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isCheckedIn = false
    @Published var isSearching = false
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private let beaconUUID = UUID(uuidString: "7827AA20-2884-428A-A3F0-9E64F976226D")!
    private let beaconIdentifier = "jp.momoyama-tech.nomi-mane.beacon"
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func startScanning() {
        isSearching = true
        // Request permissions
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            startRanging()
        }
    }
    
    func stopScanning() {
        let constraint = CLBeaconIdentityConstraint(uuid: beaconUUID)
        locationManager.stopRangingBeacons(satisfying: constraint)
        isSearching = false
    }
    
    private func startRanging() {
        let constraint = CLBeaconIdentityConstraint(uuid: beaconUUID)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: beaconIdentifier)
        
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: constraint)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            startRanging()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        // Filter beacons that are near or immediate
        let relevantBeacons = beacons.filter { beacon in
            beacon.proximity == .immediate || beacon.proximity == .near
        }
        
        if !relevantBeacons.isEmpty {
            DispatchQueue.main.async {
                self.isCheckedIn = true
                self.isSearching = false
                self.stopScanning()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}
