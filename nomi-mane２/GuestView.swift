import SwiftUI

struct GuestView: View {
    @StateObject private var detector = BeaconDetector()
    
    var body: some View {
        VStack(spacing: 80) {
            Spacer()
            
            if detector.detected {
                SuccessView(fee: detector.receivedFee, paymentURL: detector.receivedURL, detector: detector)
            } else {
                SearchingView()
            }
            
            Spacer()
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("参加者モード")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .onAppear {
            detector.startScanning()
        }
        .onDisappear {
            detector.stopScanning()
        }
    }
}

struct SearchingView: View {
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .stroke(Color.themeAccentRed.opacity(0.1), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .stroke(Color.themeAccentRed.opacity(pulse ? 0.3 : 0.6), lineWidth: 4)
                    .frame(width: pulse ? 80 : 30, height: pulse ? 80 : 30)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
            }
            .onAppear { pulse = true }
            
            VStack(spacing: 12) {
                Text("スキャン中")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.themeTextPrimary)
                
                Text("幹事を探しています...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .cardStyle()
    }
}

struct SuccessView: View {
    let fee: String
    let paymentURL: String
    @ObservedObject var detector: BeaconDetector
    @State private var appeared = false
    @State private var showingBankSheet = false
    @State private var showingCopyAlert = false
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.themeAccentRed)
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0.0)
                
                VStack(spacing: 12) {
                    Text(detector.paymentStatus == "K" ? "支払い完了" : "チェックイン完了")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.themeTextPrimary)
                    
                    Text(detector.paymentStatus == "K" ? "承認されました。お疲れ様でした！" : (fee.isEmpty ? "飲み会を楽しんでください！" : "本日の会費：\(fee)"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    appeared = true
                }
            }
            
            if detector.paymentStatus != "K" {
                VStack(spacing: 16) {
                    // ① PayPayで支払う（赤色・メイン）
                    if !paymentURL.isEmpty {
                        Button(action: {
                            detector.updatePaymentStatus("P")
                            sanitizeAndOpenURL(paymentURL)
                        }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                Text("PayPayで支払う")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButtonStyle(variant: .solid))
                    }
                    
                    // ② 銀行振込・ことらで支払う（青色・サブ）
                    Button(action: {
                        detector.updatePaymentStatus("B")
                        showingBankSheet = true
                    }) {
                        HStack {
                            Image(systemName: "building.columns.fill")
                            Text("銀行振込・ことらで支払う")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .outlined, color: .blue))
                    
                    // ③ 現金で手渡しする（グレーまたは緑色・サブ）
                    Button(action: {
                        detector.updatePaymentStatus("C")
                    }) {
                        HStack {
                            Image(systemName: "banknote.fill")
                            Text(detector.paymentStatus == "C" ? "現金払いリクエスト済み" : "現金で手渡しする")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .outlined, color: .green))
                    .opacity(detector.paymentStatus == "C" ? 0.6 : 1.0)
                }
                .padding(.horizontal, 16)
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingBankSheet) {
            BankInfoSheet(bankInfo: detector.receivedBankInfo)
                .presentationDetents([.medium])
        }
    }
    
    private func sanitizeAndOpenURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("Error: Empty URL string")
            return
        }
        
        var finalURLString = trimmed
        if !finalURLString.hasPrefix("http") && !finalURLString.hasPrefix("paypay://") {
            finalURLString = "https://" + finalURLString
        }
        
        if let url = URL(string: finalURLString) {
            print("Opening URL: \(finalURLString)")
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Failed to open URL: \(finalURLString)")
                }
            }
        } else {
            print("Error: Invalid URL format: \(finalURLString)")
        }
    }
}

struct BankInfoSheet: View {
    let bankInfo: String
    @Environment(\.dismiss) var dismiss
    @State private var showingCopySuccess = false
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
            
            HStack {
                Text("振込先情報")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(bankInfo.isEmpty ? "情報がありません" : bankInfo)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.themeSecondaryBackground)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = bankInfo
                withAnimation {
                    showingCopySuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showingCopySuccess = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: showingCopySuccess ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    Text(showingCopySuccess ? "コピーしました" : "情報をコピーする")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PremiumButtonStyle(variant: .solid, color: .blue))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .appBackground()
    }
}

#Preview {
    NavigationStack {
        GuestView()
    }
}
