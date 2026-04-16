import SwiftUI

func onlineStatusText(isOnline: Bool, lastSeenAt: String?, offlineMode: Bool = false) -> String {
    if isOnline && !offlineMode { return "онлайн" }
    guard let str = lastSeenAt, !str.isEmpty, let date = parseISODate(str) else { return "оффлайн" }

    let diff = Date().timeIntervalSince(date)
    if diff < 60 { return "оффлайн" }

    let mins   = Int(diff / 60)
    let hours  = Int(diff / 3600)
    let days   = Int(diff / 86400)
    let weeks  = Int(diff / 604800)
    let months = Int(diff / 2592000)

    if mins  < 60 { return "был(а) \(mins) \(plural(mins,  "минуту","минуты","минут")) назад" }
    if hours < 24 { return "был(а) \(hours) \(plural(hours, "час","часа","часов")) назад" }
    if days  < 7  { return "был(а) \(days) \(plural(days,  "день","дня","дней")) назад" }
    if weeks < 5  { return "был(а) \(weeks) \(plural(weeks, "неделю","недели","недель")) назад" }
    return          "был(а) \(months) \(plural(months, "месяц","месяца","месяцев")) назад"
}

func onlineStatusColor(isOnline: Bool, offlineMode: Bool = false) -> Color {
    isOnline && !offlineMode ? Color(hex: "#10B981") : Theme.muted
}

private func plural(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
    let m10 = n % 10, m100 = n % 100
    if m10 == 1 && m100 != 11 { return one }
    if (2...4).contains(m10) && !(12...14).contains(m100) { return few }
    return many
}

private func parseISODate(_ str: String) -> Date? {
    let fmts = ["yyyy-MM-dd'T'HH:mm:ssZ","yyyy-MM-dd HH:mm:ss","yyyy-MM-dd'T'HH:mm:ss.SSSZ"]
    for fmt in fmts {
        let f = DateFormatter()
        f.dateFormat = fmt
        f.locale = Locale(identifier: "en_US_POSIX")
        if let d = f.date(from: str) { return d }
    }
    return nil
}

// MARK: - UserAvatarView
struct UserAvatarView: View {
    let avatarURL: String
    let initials: String
    let size: CGFloat
    var isOnline: Bool = false
    var accentColor: Color? = nil

    private var color: Color {
        if let c = accentColor { return c }
        let palette: [Color] = [Theme.accentProfile, Theme.accentChats, Theme.accentContacts, Theme.accentGroups, Color(hex: "#EC4899"), Color(hex: "#06B6D4")]
        return palette[abs(initials.hashValue) % palette.count]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: size, height: size)
                                .clipShape(RoundedRectangle(cornerRadius: size * 0.28))
                        default:
                            fallbackView
                        }
                    }
                } else {
                    fallbackView
                }
            }
            .frame(width: size, height: size)

            if isOnline {
                Circle()
                    .fill(Color(hex: "#10B981"))
                    .frame(width: size * 0.27, height: size * 0.27)
                    .overlay(Circle().stroke(Theme.bg, lineWidth: 1.5))
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var fallbackView: some View {
        RoundedRectangle(cornerRadius: size * 0.28)
            .fill(color.opacity(0.18))
            .overlay(RoundedRectangle(cornerRadius: size * 0.28).stroke(color.opacity(0.35), lineWidth: 0.5))
            .frame(width: size, height: size)
            .overlay(Text(initials).font(.system(size: size * 0.36, weight: .bold)).foregroundColor(color))
    }
}
