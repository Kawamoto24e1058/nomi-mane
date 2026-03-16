import SwiftUI

struct ProfileView: View {
    @AppStorage("user_nickname") var nickname: String = ""
    @AppStorage("payment_url") var paymentURL: String = ""
    
    @State private var inputName: String = ""
    @State private var inputURL: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Text("プロフィール")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.themeTextPrimary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ニックネーム")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                    
                    TextField("例: たろう", text: $inputName)
                        .font(.system(size: 18, weight: .bold))
                        .padding(16)
                        .background(Color.themeSecondaryBackground)
                        .cornerRadius(12)
                        .foregroundColor(.themeTextPrimary)
                        .autocorrectionDisabled()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("支払い用リンク (PayPayなど)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                    
                    TextField("https://paypay.ne.jp/...", text: $inputURL)
                        .font(.system(size: 14))
                        .padding(16)
                        .background(Color.themeSecondaryBackground)
                        .cornerRadius(12)
                        .foregroundColor(.themeTextPrimary)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                nickname = inputName
                paymentURL = inputURL
                dismiss()
            }) {
                Text("保存する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PremiumButtonStyle(variant: .solid))
            .disabled(inputName.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .appBackground()
        .onAppear {
            inputName = nickname
            inputURL = paymentURL
        }
    }
}

#Preview {
    ProfileView()
}
