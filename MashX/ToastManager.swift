import SwiftUI

enum ToastStyle { case info, success, error, warning }

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let icon: String
}

@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var items: [ToastItem] = []
    private init() {}

    func show(_ message: String, style: ToastStyle = .info, icon: String? = nil) {
        let defaultIcon: String
        switch style {
        case .info:    defaultIcon = "info.circle.fill"
        case .success: defaultIcon = "checkmark.circle.fill"
        case .error:   defaultIcon = "xmark.circle.fill"
        case .warning: defaultIcon = "exclamationmark.triangle.fill"
        }
        let item = ToastItem(message: message, style: style, icon: icon ?? defaultIcon)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            items.append(item)
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                items.removeAll { $0.id == item.id }
            }
        }
    }
}

// iOS-style pill toast — floats at top, no background panel
struct ToastOverlay: View {
    @EnvironmentObject private var toast: ToastManager

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toast.items) { item in
                PillToast(item: item)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.85).combined(with: .opacity)
                    ))
            }
            Spacer()
        }
        .padding(.top, 56)
        .padding(.horizontal, 16)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: toast.items.count)
    }
}

private struct PillToast: View {
    let item: ToastItem

    private var accentColor: Color {
        switch item.style {
        case .info:    return Theme.accentChats
        case .success: return Theme.accentContacts
        case .error:   return Color(hex: "#EF4444")
        case .warning: return Theme.accentGroups
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: item.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor)
            Text(item.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(hex: "#1c1c2e"))
                .overlay(Capsule().stroke(accentColor.opacity(0.3), lineWidth: 0.8))
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
    }
}
