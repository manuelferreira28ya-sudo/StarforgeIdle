import SwiftUI

extension Color {
    static let spaceBlack = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let forgeBlue = Color(red: 0.12, green: 0.28, blue: 0.48)
    static let ionTeal = Color(red: 0.16, green: 0.72, blue: 0.68)
    static let flareGold = Color(red: 1.0, green: 0.72, blue: 0.22)
    static let cometPink = Color(red: 0.9, green: 0.28, blue: 0.44)
    static let panelFill = Color.white.opacity(0.08)
}

struct GamePanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func gamePanel() -> some View {
        modifier(GamePanel())
    }
}

