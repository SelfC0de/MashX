import SwiftUI

// MARK: - AvatarView
struct AvatarView: View {
    let initials: String
    let size: CGFloat
    var isOnline: Bool = false
    var hasStory: Bool = false
    var accentColor: Color = Theme.accentChats

    private var bgColor: Color {
        let palette: [Color] = [
            Theme.accentProfile, Theme.accentChats,
            Theme.accentContacts, Theme.accentGroups,
            Color(hex: "#EC4899"), Color(hex: "#06B6D4")
        ]
        return palette[abs(initials.hashValue) % palette.count]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                if hasStory {
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Theme.accentProfile, Theme.accentChats],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                        .frame(width: size + 5, height: size + 5)
                }
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(bgColor.opacity(0.2))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.28).stroke(bgColor.opacity(0.35), lineWidth: 0.5))
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(bgColor)
            }
            .frame(width: size, height: size)

            if isOnline {
                Circle()
                    .fill(Color(hex: "#10B981"))
                    .frame(width: size * 0.26, height: size * 0.26)
                    .overlay(Circle().stroke(Theme.bg, lineWidth: 1.5))
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - UnreadBadge
struct UnreadBadge: View {
    let count: Int
    var color: Color = Theme.accentChats

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? 5 : 4)
                .padding(.vertical, 2)
                .background(color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - SearchBar
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Поиск"
    var accentColor: Color = Theme.accentChats
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Theme.muted)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(Theme.text)
                .tint(accentColor)
                .focused($focused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.muted)
                }
            } else if focused {
                Button("Отмена") { text = ""; focused = false }
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.card)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(focused ? accentColor.opacity(0.4) : Theme.border, lineWidth: 0.5))
        .animation(.easeInOut(duration: 0.2), value: focused)
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var accent: Color = Theme.accentChats
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? accent : Theme.card)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.clear : Theme.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - SectionHeader
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var accentColor: Color = Theme.accentChats
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.muted)
                .kerning(0.8)
            Spacer()
            if let label = action {
                Button(label, action: onAction ?? {})
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}

// MARK: - AnimatedIcon (bounces on appear)
struct AnimatedIcon: View {
    let name: String
    let size: CGFloat
    let color: Color
    @State private var appeared = false

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .semibold))
            .foregroundColor(color)
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    appeared = true
                }
            }
    }
}

// MARK: - TypingIndicator
struct TypingIndicator: View {
    @State private var phase: Int = 0
    let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.muted)
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: phase)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Theme.card)
        .cornerRadius(4, corners: .topRight)
        .cornerRadius(14, corners: [.topLeft, .bottomLeft, .bottomRight])
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
