import SwiftUI

struct GuestView: View {
    @StateObject private var detector = BeaconDetector()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if detector.isCheckedIn {
                SuccessView()
            } else {
                SearchingView()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("参加する")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            detector.startScanning()
        }
        .onDisappear {
            detector.stopScanning()
        }
    }
}

struct SearchingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("幹事を探しています...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("幹事の端末に近づいてください")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct SuccessView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .transition(.scale)
            
            Text("チェックインが完了しました！")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("飲み会を楽しんでください！")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        GuestView()
    }
}
