import SwiftUI

enum Theme {
    static let bg       = Color(hex: "#0d0d14")
    static let bgSecond = Color(hex: "#0a0a10")
    static let card     = Color(hex: "#13131e")
    static let border   = Color.white.opacity(0.07)
    static let text     = Color(hex: "#f0f0f8")
    static let muted    = Color(hex: "#f0f0f8").opacity(0.45)
    static let dim      = Color(hex: "#f0f0f8").opacity(0.20)
    static let sep      = Color.white.opacity(0.05)

    static let accentProfile  = Color(hex: "#7B5CFA")
    static let accentContacts = Color(hex: "#10B981")
    static let accentChats    = Color(hex: "#3B82F6")
    static let accentGroups   = Color(hex: "#F59E0B")

    // Цвета акцента по индексу (синхронизировано с SettingsView)
    static let accentColors: [Color] = [
        Color(hex: "#7B5CFA"),
        Color(hex: "#3B82F6"),
        Color(hex: "#10B981"),
        Color(hex: "#EC4899"),
        Color(hex: "#F59E0B"),
        Color(hex: "#EF4444"),
    ]

    // Размеры шрифта по индексу
    static let fontSizes: [CGFloat] = [13, 15, 17]
}

// MARK: - ThemeManager
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("accent_index")    var accentIndex: Int = 0
    @AppStorage("font_size_index") var fontSizeIndex: Int = 1
    @AppStorage("language_index")  var languageIndex: Int = 0

    var accent: Color { Theme.accentColors[min(accentIndex, Theme.accentColors.count - 1)] }
    var fontSize: CGFloat { Theme.fontSizes[min(fontSizeIndex, Theme.fontSizes.count - 1)] }

    private init() {}
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xff) / 255
        let g = Double((val >> 8)  & 0xff) / 255
        let b = Double(val         & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Tab: Int, CaseIterable {
    case profile = 0, contacts, chats, groups, settings

    var accent: Color {
        switch self {
        case .profile:  return Theme.accentProfile
        case .contacts: return Theme.accentContacts
        case .chats:    return Theme.accentChats
        case .groups:   return Theme.accentGroups
        case .settings: return Color(hex: "#EC4899")
        }
    }
    var icon: String {
        switch self {
        case .profile:  return "person.crop.circle.fill"
        case .contacts: return "person.2.fill"
        case .chats:    return "bubble.left.and.bubble.right.fill"
        case .groups:   return "person.3.fill"
        case .settings: return "gearshape.fill"
        }
    }
    var label: String {
        switch self {
        case .profile:  return "Профиль"
        case .contacts: return "Контакты"
        case .chats:    return "Чаты"
        case .groups:   return "Группы"
        case .settings: return "Настройки"
        }
    }
}
