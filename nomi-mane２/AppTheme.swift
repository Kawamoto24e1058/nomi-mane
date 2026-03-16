import SwiftUI
import CoreBluetooth

extension Color {
    // PayPay-inspired Theme Colors
    static let themeBackground = Color(UIColor.systemBackground)
    static let themeSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let themeAccentRed = Color(red: 1.0, green: 0.1, blue: 0.2) // Vivid Red
    static let themeTextPrimary = Color.primary
    static let themeTextSecondary = Color.secondary
    static let themeDivider = Color(UIColor.separator)
}

struct PremiumButtonStyle: ButtonStyle {
    var variant: Variant = .solid
    var color: Color = .themeAccentRed
    
    enum Variant {
        case outlined
        case solid
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                variant == .solid ? color : Color.clear
            )
            .foregroundColor(variant == .solid ? .white : color)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: variant == .outlined ? 2 : 0)
            )
            .cornerRadius(12)
            .shadow(color: variant == .solid ? color.opacity(0.3) : Color.clear, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func appBackground() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground.ignoresSafeArea())
    }
    
    // PayPay-style "Card"
    func cardStyle() -> some View {
        self.padding(20)
            .background(Color.themeBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}
