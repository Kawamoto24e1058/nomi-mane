import SwiftUI

struct ProfileSetupView: View {
    @AppStorage("user_nickname") var nickname: String = ""
    @AppStorage("payment_pref") var paymentPref: String = "P" // P: PayPay, B: Bank, C: Cash
    @AppStorage("setup_completed") var setupCompleted: Bool = false
    
    @State private var inputName: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("初期セットアップ")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.themeTextPrimary)
                    
                    Text("飲み会をスムーズにするために\nプロフィールを登録しましょう")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.themeTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 24) {
                    // ① 名前
                    VStack(alignment: .leading, spacing: 10) {
                        Label("お名前 (表示名)", systemImage: "person.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeTextSecondary)
                        
                        TextField("例: たろう", text: $inputName)
                            .font(.system(size: 18, weight: .bold))
                            .padding(16)
                            .background(Color.themeSecondaryBackground)
                            .cornerRadius(12)
                            .foregroundColor(.themeTextPrimary)
                    }
                    
                    // ② 支払い方法の希望
                    VStack(alignment: .leading, spacing: 10) {
                        Label("希望の支払い方法", systemImage: "creditcard.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeTextSecondary)
                        
                        HStack(spacing: 12) {
                            PaymentOptionButton(title: "PayPay", code: "P", icon: "p.square.fill", selectedCode: $paymentPref, color: .themeAccentRed)
                            PaymentOptionButton(title: "銀行/ことら", code: "B", icon: "building.columns.fill", selectedCode: $paymentPref, color: .blue)
                            PaymentOptionButton(title: "現金", code: "C", icon: "banknote.fill", selectedCode: $paymentPref, color: .green)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    nickname = inputName
                    setupCompleted = true
                    dismiss()
                }) {
                    Text("はじめる")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PremiumButtonStyle(variant: .solid))
                .disabled(inputName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(inputName.isEmpty ? 0.5 : 1.0)
            }
        }
        .appBackground()
        .onAppear {
            inputName = nickname
        }
    }
}

struct PaymentOptionButton: View {
    let title: String
    let code: String
    let icon: String
    @Binding var selectedCode: String
    let color: Color
    
    var body: some View {
        Button(action: { selectedCode = code }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedCode == code ? color : Color.themeSecondaryBackground)
            .foregroundColor(selectedCode == code ? .white : .themeTextSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: selectedCode == code ? 0 : 1)
            )
        }
    }
}

#Preview {
    ProfileSetupView()
}
