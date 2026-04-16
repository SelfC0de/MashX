import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showSessions      = false
    @State private var showAccentPicker  = false
    @State private var showDeleteAlert   = false
    @State private var showDeleteConfirm = false
    @State private var deletePassword    = ""
    @State private var expandedCards: Set<String> = []
    @State private var languageTick      = false

    private var accent: Color { themeManager.accent }

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
                        settingsCard(id: "notifications", icon: "bell.fill",       title: "Уведомления и звуки") { notificationsContent }
                        settingsCard(id: "privacy",       icon: "eye.fill",        title: "Приватность")  { privacyContent }
                        settingsCard(id: "security",      icon: "shield.lefthalf.filled", title: "Безопасность") { securityContent }
                        settingsCard(id: "appearance",    icon: "paintpalette.fill", title: "Внешний вид") { appearanceContent }
                        settingsCard(id: "ai",            icon: "sparkles",        title: "AI и Автоматизация") { aiContent }
                        settingsCard(id: "account",       icon: "person.crop.circle.badge.exclamationmark", title: "Аккаунт") { accountContent }
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSessions)     { SessionsView() }
            .sheet(isPresented: $showAccentPicker) {
                AccentPickerSheet(presets: accentPresets, current: Binding(
                    get: { themeManager.accentIndex },
                    set: { themeManager.accentIndex = $0; settings.accentIndex = $0 }
                ))
            }
            .sheet(isPresented: $showDeleteConfirm) { deleteConfirmSheet }
            .alert("Удалить аккаунт?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) { showDeleteConfirm = true }
            } message: {
                Text("Все данные будут удалены безвозвратно.")
            }
        }
        .id(languageTick)
    }

    // MARK: - Delete confirm sheet
    private var deleteConfirmSheet: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10)
                Image(systemName: "trash.fill").font(.system(size: 36)).foregroundColor(.red)
                    .frame(width: 72, height: 72).background(Color.red.opacity(0.12)).cornerRadius(20)
                Text("Подтвердите удаление").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                Text("Введите пароль для подтверждения").font(.system(size: 14)).foregroundColor(Theme.muted)

                SecureField("Пароль", text: $deletePassword)
                    .foregroundColor(Theme.text).tint(.red)
                    .padding(12).background(Theme.card).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 0.5))
                    .padding(.horizontal, 24)

                if let err = auth.errorMessage {
                    Text(err).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 24)
                }

                Button {
                    Task {
                        let ok = await auth.deleteAccount(password: deletePassword)
                        if !ok { deletePassword = "" }
                    }
                } label: {
                    ZStack {
                        if auth.isLoading { ProgressView().tint(.white) }
                        else { Text("Удалить аккаунт").font(.system(size: 16, weight: .semibold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.red).cornerRadius(14)
                }
                .disabled(deletePassword.isEmpty || auth.isLoading)
                .padding(.horizontal, 24)
                Spacer()
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Card builder
    private func settingsCard<Content: View>(
        id: String, icon: String, title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expandedCards.contains(id)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded { expandedCards.remove(id) } else { expandedCards.insert(id) }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon).font(.system(size: 13)).foregroundColor(accent)
                        .frame(width: 28, height: 28).background(accent.opacity(0.14)).cornerRadius(7)
                    Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.dim)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            if isExpanded { Divider().background(Theme.sep); content() }
        }
        .background(Theme.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
    }

    // MARK: - Card contents

    // Уведомления + звуки объединены в одну карточку
    private var notificationsContent: some View {
        VStack(spacing: 0) {
            toggleRow("Уведомления",      "bell.fill",           $settings.notificationsEnabled)
            rowDivider()
            toggleRow("Звуки",            "speaker.wave.2.fill", $settings.soundEnabled)
            rowDivider()
            toggleRow("Звук приветствия", "music.note",          $settings.splashSoundEnabled)
        }.padding(.vertical, 4)
    }

    private var privacyContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                accentIcon(settings.offlineMode ? "eye.slash.fill" : "circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Оффлайн режим")
                        .font(.system(size: 15)).foregroundColor(Theme.text)
                    Text(settings.offlineMode ? "Статус скрыт везде" : "Статус виден другим")
                        .font(.system(size: 12)).foregroundColor(Theme.muted)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.offlineMode },
                    set: { val in
                        settings.offlineMode = val
                        settings.showOnlineStatus = !val
                        Task { await auth.updateOnlineStatus(!val) }
                    }
                )).tint(accent).labelsHidden()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            rowDivider()
            toggleRow("Отчёт о прочтении", "checkmark.circle.fill",             $settings.sendReadReceipts)
            rowDivider()
            toggleRow("Proximity Ping",    "antenna.radiowaves.left.and.right", $settings.proximityPing)
        }.padding(.vertical, 4)
    }

    private var securityContent: some View {
        VStack(spacing: 0) {
            segmentRow("Авто-удаление", "timer", ["Выкл", "1ч", "24ч", "7д"], $settings.autoDeleteIndex)
            rowDivider()
            arrowRow(icon: "iphone.and.arrow.forward", label: "Активные сессии", value: "") { showSessions = true }
        }.padding(.vertical, 4)
    }

    private var appearanceContent: some View {
        VStack(spacing: 0) {
            Button { showAccentPicker = true } label: {
                HStack(spacing: 14) {
                    accentIcon("paintbrush.fill")
                    Text("Акцентный цвет").font(.system(size: 15)).foregroundColor(Theme.text)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(accentPresets[themeManager.accentIndex].1).frame(width: 16, height: 16)
                        Text(accentPresets[themeManager.accentIndex].0).font(.system(size: 13)).foregroundColor(Theme.muted)
                        Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Theme.dim)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            rowDivider()
            segmentRow("Язык", "globe", ["RU", "EN"], Binding(
                get: { themeManager.languageIndex },
                set: { idx in
                    themeManager.languageIndex = idx
                    settings.languageIndex = idx
                    UserDefaults.standard.set(idx, forKey: "language_index")
                    UserDefaults.standard.synchronize()
                    languageTick.toggle()
                }
            ))
        }.padding(.vertical, 4)
    }

    private var aiContent: some View {
        VStack(spacing: 0) {
            toggleRow("Smart Reply AI", "sparkles",    $settings.smartReply)
            rowDivider()
            toggleRow("Антиспам",       "shield.fill", $settings.antispam)
        }.padding(.vertical, 4)
    }

    private var accountContent: some View {
        VStack(spacing: 0) {
            Button {
                Task { await auth.logout() }
            } label: {
                HStack(spacing: 14) {
                    accentIcon("rectangle.portrait.and.arrow.right", color: .red)
                    if auth.isLoading {
                        ProgressView().tint(.red)
                    } else {
                        Text("Выйти из аккаунта").font(.system(size: 15)).foregroundColor(.red)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(auth.isLoading)
            rowDivider()
            Button { showDeleteAlert = true } label: {
                HStack(spacing: 14) {
                    accentIcon("trash.fill", color: .red)
                    Text("Удалить аккаунт").font(.system(size: 15)).foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }.padding(.vertical, 4)
    }

    // MARK: - Helpers
    private func rowDivider() -> some View { Divider().background(Theme.sep).padding(.leading, 58) }

    private func accentIcon(_ name: String, color: Color? = nil) -> some View {
        let c = color ?? accent
        return Image(systemName: name).font(.system(size: 13)).foregroundColor(c)
            .frame(width: 28, height: 28).background(c.opacity(0.14)).cornerRadius(7)
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
            .background(Theme.card).cornerRadius(8)
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
                if !value.isEmpty { Text(value).font(.system(size: 13)).foregroundColor(accent) }
                Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Theme.dim)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}
