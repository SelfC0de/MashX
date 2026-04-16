import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager

    @State private var showSessions     = false
    @State private var showAccentPicker = false
    @State private var showDeleteAlert  = false
    @State private var deleteConfirm    = false

    // Expanded state per card
    @State private var expandedCards: Set<String> = []

    private let accent = Theme.accentProfile

    private let accentPresets: [(String, Color)] = [
        ("Фиолет",  Color(hex: "#7B5CFA")),
        ("Синий",   Color(hex: "#3B82F6")),
        ("Зелёный", Color(hex: "#10B981")),
        ("Розовый", Color(hex: "#EC4899")),
        ("Янтарь",  Color(hex: "#F59E0B")),
        ("Красный", Color(hex: "#EF4444")),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 4)
                        settingsCard(id: "notifications", icon: "bell.fill", title: "Уведомления") {
                            notificationsContent
                        }
                        settingsCard(id: "privacy", icon: "eye.fill", title: "Приватность") {
                            privacyContent
                        }
                        settingsCard(id: "security", icon: "shield.lefthalf.filled", title: "Безопасность") {
                            securityContent
                        }
                        settingsCard(id: "appearance", icon: "paintpalette.fill", title: "Внешний вид") {
                            appearanceContent
                        }
                        settingsCard(id: "ai", icon: "sparkles", title: "AI и Автоматизация") {
                            aiContent
                        }
                        settingsCard(id: "account", icon: "person.crop.circle.badge.exclamationmark", title: "Аккаунт") {
                            accountContent
                        }
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSessions)     { SessionsView() }
            .sheet(isPresented: $showAccentPicker) { AccentPickerSheet(presets: accentPresets, current: $settings.accentIndex) }
            .alert("Удалить аккаунт?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    toast.show("Аккаунт удалён", style: .error, icon: "trash.fill")
                }
            } message: {
                Text("Все данные будут удалены безвозвратно. Это действие нельзя отменить.")
            }
        }
    }

    // MARK: - Card builder
    private func settingsCard<Content: View>(
        id: String,
        icon: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expandedCards.contains(id)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded { expandedCards.remove(id) }
                    else { expandedCards.insert(id) }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(accent)
                        .frame(width: 28, height: 28)
                        .background(accent.opacity(0.14))
                        .cornerRadius(7)
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.dim)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(Theme.sep)
                content()
            }
        }
        .background(Theme.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }

    // MARK: - Notifications content
    private var notificationsContent: some View {
        VStack(spacing: 0) {
            toggleRow("Уведомления",        "bell.fill",            $settings.notificationsEnabled)
            rowDivider()
            toggleRow("Звуки",              "speaker.wave.2.fill",  $settings.soundEnabled)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Privacy content
    private var privacyContent: some View {
        VStack(spacing: 0) {
            toggleRow("Статус онлайн",      "circle.fill",          $settings.showOnlineStatus)
            rowDivider()
            toggleRow("Оффлайн режим",      "eye.slash.fill",       $settings.offlineMode)
            rowDivider()
            toggleRow("Отчёт о прочтении",  "checkmark.circle.fill",$settings.sendReadReceipts)
            rowDivider()
            toggleRow("Proximity Ping",     "antenna.radiowaves.left.and.right", $settings.proximityPing)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Security content
    private var securityContent: some View {
        VStack(spacing: 0) {
            segmentRow("Авто-удаление", "timer", ["Выкл", "1ч", "24ч", "7д"], $settings.autoDeleteIndex)
            rowDivider()
            arrowRow(icon: "iphone.and.arrow.forward", label: "Активные сессии",
                     value: "2 устройства") { showSessions = true }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Appearance content
    private var appearanceContent: some View {
        VStack(spacing: 0) {
            Button { showAccentPicker = true } label: {
                HStack(spacing: 14) {
                    accentIcon("paintbrush.fill")
                    Text("Акцентный цвет")
                        .font(.system(size: 15)).foregroundColor(Theme.text)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(accentPresets[settings.accentIndex].1).frame(width: 16, height: 16)
                        Text(accentPresets[settings.accentIndex].0)
                            .font(.system(size: 13)).foregroundColor(Theme.muted)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11)).foregroundColor(Theme.dim)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            rowDivider()

            VStack(spacing: 10) {
                HStack {
                    accentIcon("textformat.size")
                    Text("Размер шрифта")
                        .font(.system(size: 15)).foregroundColor(Theme.text)
                    Spacer()
                    Text(["S", "M", "L"][settings.fontSizeIndex])
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 20)
                }
                Slider(value: Binding(
                    get: { Double(settings.fontSizeIndex) },
                    set: { settings.fontSizeIndex = Int($0.rounded()) }
                ), in: 0...2, step: 1)
                .tint(accent)
                .padding(.leading, 42)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            rowDivider()

            segmentRow("Язык", "globe", ["RU", "EN"], $settings.languageIndex)
        }
        .padding(.vertical, 4)
    }

    // MARK: - AI content
    private var aiContent: some View {
        VStack(spacing: 0) {
            toggleRow("Smart Reply AI",     "sparkles",             $settings.smartReply)
            rowDivider()
            toggleRow("Антиспам",           "shield.fill",          $settings.antispam)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Account content
    private var accountContent: some View {
        VStack(spacing: 0) {
            Button {
                toast.show("Выход выполнен", style: .error, icon: "rectangle.portrait.and.arrow.right")
            } label: {
                HStack(spacing: 14) {
                    accentIcon("rectangle.portrait.and.arrow.right", color: .red)
                    Text("Выйти из аккаунта").font(.system(size: 15)).foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            rowDivider()

            Button {
                if !deleteConfirm {
                    deleteConfirm = true
                    toast.show("Нажмите ещё раз для подтверждения", style: .warning, icon: "exclamationmark.triangle.fill")
                } else {
                    showDeleteAlert = true
                    deleteConfirm = false
                }
            } label: {
                HStack(spacing: 14) {
                    accentIcon("trash.fill", color: .red)
                    Text("Удалить аккаунт").font(.system(size: 15)).foregroundColor(.red)
                    Spacer()
                    if deleteConfirm {
                        Text("Подтвердить")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.red).cornerRadius(6)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers
    private func rowDivider() -> some View {
        Divider().background(Theme.sep).padding(.leading, 58)
    }

    private func accentIcon(_ name: String, color: Color? = nil) -> some View {
        let c = color ?? accent
        return Image(systemName: name)
            .font(.system(size: 13))
            .foregroundColor(c)
            .frame(width: 28, height: 28)
            .background(c.opacity(0.14))
            .cornerRadius(7)
    }

    private func toggleRow(_ label: String, _ icon: String, _ binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            accentIcon(icon)
            Text(label).font(.system(size: 15)).foregroundColor(Theme.text)
            Spacer()
            Toggle("", isOn: binding).tint(accent).labelsHidden()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func segmentRow(_ label: String, _ icon: String, _ options: [String], _ binding: Binding<Int>) -> some View {
        HStack(spacing: 14) {
            accentIcon(icon)
            Text(label).font(.system(size: 15)).foregroundColor(Theme.text)
            Spacer()
            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { binding.wrappedValue = i }
                    } label: {
                        Text(options[i])
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(binding.wrappedValue == i ? .white : Theme.muted)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(binding.wrappedValue == i ? accent : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Theme.card)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private func arrowRow(icon: String, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                accentIcon(icon)
                Text(label).font(.system(size: 15)).foregroundColor(Theme.text)
                Spacer()
                Text(value).font(.system(size: 13)).foregroundColor(accent)
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Theme.dim)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
