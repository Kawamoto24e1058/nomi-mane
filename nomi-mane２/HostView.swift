import SwiftUI
import CoreBluetooth

struct HostView: View {
    @StateObject private var beaconTransmitter = BeaconTransmitter()
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: beaconTransmitter.isAdvertising ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(beaconTransmitter.isAdvertising ? .green : .gray)
            
            Text("幹事モード（iBeacon発信）")
                .font(.headline)
            
            Text(beaconTransmitter.isAdvertising ? "発信中" : "停止中")
                .font(.subheadline)
                .foregroundStyle(beaconTransmitter.isAdvertising ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("UUID: 7827AA20-2884-428A-A3F0-9E64F976226D")
                Text("Major: 1")
                Text("Minor: 1")
            }
            .font(.caption)
            .monospaced()
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            Button(action: {
                if beaconTransmitter.isAdvertising {
                    beaconTransmitter.stopAdvertising()
                } else {
                    beaconTransmitter.startAdvertising()
                }
            }) {
                Text(beaconTransmitter.isAdvertising ? "発信を停止" : "発信を開始")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(beaconTransmitter.isAdvertising ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(beaconTransmitter.bluetoothState != .poweredOn)
            
            if beaconTransmitter.bluetoothState != .poweredOn {
                Text("Bluetoothが無効です")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("幹事になる")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HostView()
    }
}
