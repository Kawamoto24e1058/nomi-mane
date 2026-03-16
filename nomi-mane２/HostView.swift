import SwiftUI
import CoreBluetooth
import UniformTypeIdentifiers

struct HostView: View {
    @StateObject private var beaconTransmitter = BeaconTransmitter()
    @StateObject private var hostScanner = HostScanner()
    
    @AppStorage("payment_url") var profileURL: String = ""
    @AppStorage("bank_info") var savedBankInfo: String = ""
    @State private var feeMemo: String = "1,000円"
    @State private var sessionURL: String = ""
    @State private var bankInfo: String = ""
    
    // 個別金額調整用
    @State private var showingAdjustmentAlert = false
    @State private var showingActionSheet = false
    @State private var selectedMember: Member?
    @State private var adjustmentAmount: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // セッション情報カード
                VStack(spacing: 24) {
                    HStack {
                        Text("開催設定")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themeTextPrimary)
                        Spacer()
                    }
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("会費")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                            TextField("1,000円", text: $feeMemo)
                                .font(.system(size: 18, weight: .bold))
                                .padding()
                                .background(Color.themeSecondaryBackground)
                                .cornerRadius(10)
                                .foregroundColor(.themeTextPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("支払いURL (PayPayなど)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                            
                            HStack(spacing: 12) {
                                TextField("https://paypay.ne.jp/...", text: $sessionURL)
                                    .font(.system(size: 16))
                                    .padding(12)
                                    .background(Color.themeSecondaryBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(.themeTextPrimary)
                                    .keyboardType(.URL)
                                
                                PasteButton(supportedContentTypes: [.text]) { items in
                                    for item in items {
                                        item.loadObject(ofClass: String.self) { string, _ in
                                            if let string = string {
                                                extractAndSetURL(from: string)
                                            }
                                        }
                                    }
                                }
                                .labelStyle(.iconOnly)
                                .tint(.themeAccentRed)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("銀行口座 / ことら送金情報")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    bankInfo = "銀行名：\n支店名：\n種別：普通\n口座番号：\n名義（カナ）："
                                }) {
                                    Text("🏦 口座情報の雛形")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.themeBackground)
                                        .foregroundColor(.themeAccentRed)
                                        .cornerRadius(6)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                                }
                                
                                Button(action: {
                                    bankInfo = "ことら送金（電話番号等）：\n名義（カナ）："
                                }) {
                                    Text("📱 ことら送金の雛形")
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color.themeBackground)
                                        .foregroundColor(.themeAccentRed)
                                        .cornerRadius(6)
                                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                                }
                            }
                            .padding(.bottom, 2)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $bankInfo)
                                    .font(.system(size: 14))
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color.themeSecondaryBackground)
                                    .cornerRadius(8)
                                    .foregroundColor(.themeTextPrimary)
                                
                                if bankInfo.isEmpty {
                                    Text("上のボタンから雛形を入力するか、口座情報をペーストしてください")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            GuideRow(icon: "1.circle.fill", text: "PayPayの「送る・受け取る」をタップ")
                            GuideRow(icon: "2.circle.fill", text: "自分の「マイコード」を表示")
                            GuideRow(icon: "3.circle.fill", text: "「リンクをコピー」を押して戻る")
                        }
                        .padding()
                        .background(Color.themeAccentRed.opacity(0.05))
                        .cornerRadius(12)
                        
                        Button(action: {
                            if let url = URL(string: "paypay://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("PayPayを開く")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButtonStyle(variant: .outlined))
                    }
                }
                .cardStyle()
                
                // ビーコン制御カード
                VStack(spacing: 20) {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: beaconTransmitter.isAdvertising ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                                .foregroundColor(beaconTransmitter.isAdvertising ? .themeAccentRed : .themeTextSecondary)
                            
                            Text(beaconTransmitter.isAdvertising ? "電波発信中" : "待機中")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.themeTextPrimary)
                        }
                        Spacer()
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            if beaconTransmitter.isAdvertising {
                                beaconTransmitter.stopAdvertising()
                            } else {
                                beaconTransmitter.startAdvertising(fee: feeMemo, url: sessionURL, bankInfo: bankInfo)
                                savedBankInfo = bankInfo // 保存
                            }
                        }
                    }) {
                        Text(beaconTransmitter.isAdvertising ? "停止する" : "開始する")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButtonStyle(variant: beaconTransmitter.isAdvertising ? .outlined : .solid))
                    .disabled(beaconTransmitter.bluetoothState != .poweredOn)
                }
                .cardStyle()
                
                .cardStyle()
                
                // 集金状況カード
                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("現在の回収額")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                            HStack(alignment: .bottom, spacing: 4) {
                                Text("\(calculateCollectedAmount())")
                                    .font(.system(size: 36, weight: .black))
                                    .foregroundColor(.themeAccentRed)
                                    .id("collected_\(calculateCollectedAmount())")
                                    .transition(.opacity.combined(with: .offset(y: 5)))
                                Text("円")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.themeTextSecondary)
                                    .padding(.bottom, 6)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("目標総額")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.themeTextSecondary)
                            Text("\(calculateTotalAmount()) 円")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.themeTextPrimary)
                                .id("total_\(calculateTotalAmount())")
                                .transition(.opacity)
                        }
                    }
                }
                .cardStyle()
                
                // 参加者リストセクション
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("参加メンバー")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.themeTextPrimary)
                        Spacer()
                        Text("\(hostScanner.checkedInMembers.count)名")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.themeAccentRed.opacity(0.1))
                            .foregroundColor(.themeAccentRed)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 16)
                    
                    if hostScanner.checkedInMembers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.themeSecondaryBackground)
                            Text("参加者を待機中...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.themeTextSecondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                        .background(Color.themeSecondaryBackground.opacity(0.3))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(hostScanner.checkedInMembers) { member in
                                MemberRow(member: member, globalFee: getGlobalFee()) {
                                    selectedMember = member
                                    showingActionSheet = true
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 80)
            }
            .padding(.vertical, 16)
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("幹事モード")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextSecondary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: generateReportText(), subject: Text("【会計報告】"), message: Text("集計結果を共有します。")) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeAccentRed)
                }
            }
        }
        .onAppear {
            hostScanner.startScanning()
            if sessionURL.isEmpty {
                sessionURL = profileURL
            }
            if bankInfo.isEmpty {
                bankInfo = savedBankInfo
            }
            checkClipboardForPayPayURL()
        }
        .onDisappear {
            hostScanner.stopScanning()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 少し待延させてペーストボードの権限要求との競合を避ける
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkClipboardForPayPayURL()
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("\(selectedMember?.name ?? "") さん"),
                message: Text("支払いを完了にしますか？"),
                buttons: [
                    .default(Text("そのまま完了にする")) {
                        if let member = selectedMember {
                            withAnimation {
                                hostScanner.updateMemberStatus(name: member.name, status: .completed)
                            }
                        }
                    },
                    .default(Text("金額を変更して完了にする")) {
                        if let member = selectedMember {
                            adjustmentAmount = "\(member.actualFee ?? getGlobalFee())"
                            showingAdjustmentAlert = true
                        }
                    },
                    .cancel(Text("キャンセル"))
                ]
            )
        }
        .alert("金額の変更", isPresented: $showingAdjustmentAlert) {
            TextField("金額", text: $adjustmentAmount)
                .keyboardType(.numberPad)
            Button("確定", action: {
                if let member = selectedMember, let fee = Int(adjustmentAmount) {
                    withAnimation {
                        hostScanner.updateMemberStatus(name: member.name, status: .completed, fee: fee)
                    }
                }
            })
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(selectedMember?.name ?? "") さんの支払額を入力してください。")
        }
    }
    
    private func generateReportText() -> String {
        let globalFee = getGlobalFee()
        let collectedAmount = calculateCollectedAmount()
        let members = hostScanner.checkedInMembers
        
        var report = "【会計報告】\n"
        report += "合計回収額: ¥\(collectedAmount)\n"
        report += "--------------------\n"
        
        if members.isEmpty {
            report += "参加者なし"
        } else {
            for member in members {
                let amount = member.actualFee ?? globalFee
                let statusStr = member.status == .completed ? "完了" : "待ち"
                let payMethod = getPaymentMethodName(member.prefPayment)
                report += "・\(member.name): ¥\(amount) (\(payMethod)) - \(statusStr)\n"
            }
        }
        
        return report
    }
    
    private func getPaymentMethodName(_ code: String) -> String {
        switch code {
        case "P": return "PayPay"
        case "B": return "銀行/ことら"
        case "C": return "現金"
        default: return "不明"
        }
    }
    
    private func getGlobalFee() -> Int {
        let amountStr = feeMemo.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return Int(amountStr) ?? 0
    }
    
    private func calculateCollectedMembers() -> Int {
        hostScanner.checkedInMembers.filter { $0.status == .completed }.count
    }
    
    private func calculateCollectedAmount() -> Int {
        let globalFee = getGlobalFee()
        return hostScanner.checkedInMembers
            .filter { $0.status == .completed }
            .reduce(0) { $0 + ($1.actualFee ?? globalFee) }
    }
    
    private func calculateTotalAmount() -> Int {
        let globalFee = getGlobalFee()
        return hostScanner.checkedInMembers.count * globalFee
    }
    
    private func checkClipboardForPayPayURL() {
        guard let clipboardString = UIPasteboard.general.string else { return }
        extractAndSetURL(from: clipboardString)
    }

    private func extractAndSetURL(from text: String) {
        // 正規表現でURLを抽出 (特にPayPayリンクを優先)
        let pattern = "https://(paypay\\.ne\\.jp/qr/|paypay\\.me/)[^\\s\\n]+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let urlRange = Range(match.range, in: text) {
                let extractedURL = String(text[urlRange])
                
                DispatchQueue.main.async {
                    if self.sessionURL != extractedURL {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.sessionURL = extractedURL
                        }
                    }
                }
            }
        }
    }
}

struct GuideRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.themeAccentRed)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextPrimary)
        }
    }
}

struct MemberRow: View {
    let member: Member
    let globalFee: Int
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Circle()
                    .fill(statusColor().opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: member.status.icon)
                            .foregroundColor(statusColor())
                            .font(.system(size: 18))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextPrimary)
                    
                    HStack(spacing: 8) {
                        Text(statusLabel())
                        
                        if let fee = member.actualFee {
                            Text("¥\(fee)")
                                .fontWeight(.black)
                                .foregroundColor(.themeAccentRed)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor())
                }
                
                Spacer()
                
                if member.status != .completed {
                    Text("完了")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.themeAccentRed)
                        .cornerRadius(25)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.themeAccentRed)
                }
            }
            .padding(16)
            .background(Color.themeBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusLabel() -> String {
        switch member.status {
        case .unpaid: return "未払い"
        case .paypay: return "PayPay準備中"
        case .cash: return "現金準備中"
        case .bank: return "銀行振込待ち"
        case .completed: return "支払い完了"
        }
    }
    
    private func statusColor() -> Color {
        switch member.status {
        case .unpaid: return .gray
        case .paypay: return .themeAccentRed
        case .cash: return .green
        case .bank: return .blue
        case .completed: return .themeAccentRed
        }
    }
}

#Preview {
    NavigationStack {
        HostView()
    }
}
