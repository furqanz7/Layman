import SwiftUI

enum LaymanTheme {
    static let peach = Color(hex: 0xFFD7BF)
    static let orange = Color(hex: 0xFFB06B)
    static let accent = Color(hex: 0xF07A2A)
    static let backgroundTint = Color(hex: 0xFFF1E7)
    static let backgroundLight = Color(hex: 0xFFF8F1)
    static let cardLight = Color(hex: 0xF7E3D0)
    static let textLight = Color(hex: 0x1F130D)
    static let actionFill = Color(hex: 0x1F130D)
    
    static let backgroundDark = Color(.systemBackground)
    static let cardDark = Color(.secondarySystemBackground)
    static let textDark = Color(.label)
    
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? backgroundDark : backgroundLight
    }
    
    static func card(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? cardDark : cardLight
    }
    
    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textDark : textLight
    }
}

extension Color {
    init(hex: UInt64) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: 1
        )
    }
}
