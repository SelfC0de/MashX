import SwiftUI

private enum SettingsTab: Int, CaseIterable {
    case profile, messages, privacy, appearance, account

    var title: String {
        switch self {
        case .profile:    return "Профиль"
        case .messages:   return "Сообщения"
        case .privacy:    return "Приватность"
        case .appearance: return "Внешний вид"
        case .account:    return "Аккаунт"
        }
    }

    var icon: String {
        switch self {
        case .profile:    return "person.fill"
        case .messages:   return "bubble.left.fill"
        case .privacy:    return "eye.fill"
        case .appearance: return "paintpalette.fill"
        case .account:    return "gearshape.fill"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var settings:     SettingsStore
    @EnvironmentObject private var toast:        ToastManager
    @EnvironmentObject private var auth:         AuthManager
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedTab:      SettingsTab = .profile
    @State private var showSessions      = false
    @State private var showDeleteAlert   = false
    @State private var showDeleteConfirm = false
    @State private var deletePassword    = ""
    @State private var expandedCards:    Set<String> = []
    @State private var languageTick      = false

    private var accent: Color { themeManager.accent }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    tabBar
                    tabContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSessions)     { SessionsView() }
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

    // MARK: - Tab bar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            selectedTab = tab
                            expandedCards = []
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : Theme.muted)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(selectedTab == tab ? accent : accent.opacity(0.08))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Theme.bg)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .bottom)
    }

    // MARK: - Tab content
    @ViewBuilder
    private var tabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                Spacer().frame(height: 8)
                switch selectedTab {
                case .profile:    profilePage
                case .messages:   messagesPage
                case .privacy:    privacyPage
                case .appearance: appearancePage
                case .account:    accountPage
                }
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Pages

    private var profilePage: some View {
        VStack(spacing: 12) {
            emptyCard(icon: "person.crop.circle", text: "Настройки профиля появятся здесь")
        }
    }

    private var messagesPage: some View {
        VStack(spacing: 12) {
            settingsCard(id: "notifications", icon: "bell.fill", title: "Уведомления и звуки") {
                VStack(spacing: 0) {
                    toggleRow("Уведомления",      "bell.fill",           $settings.notificationsEnabled)
                    rowDivider()
                    toggleRow("Звуки",            "speaker.wave.2.fill", $settings.soundEnabled)
                    rowDivider()
                    toggleRow("Звук приветствия", "music.note",          $settings.splashSoundEnabled)
                }.padding(.vertical, 4)
            }
            settingsCard(id: "automate", icon: "sparkles", title: "AI и Автоматизация") {
                VStack(spacing: 0) {
                    toggleRow("Smart Reply AI", "sparkles",   $settings.smartReply)
                    rowDivider()
                    toggleRow("Антиспам",       "shield.fill", $settings.antispam)
                }.padding(.vertical, 4)
            }
            settingsCard(id: "retention", icon: "timer", title: "Хранение") {
                VStack(spacing: 0) {
                    segmentRow("Авто-удаление", "timer", ["Выкл", "1ч", "24ч", "7д"], $settings.autoDeleteIndex)
                }.padding(.vertical, 4)
            }
        }
    }

    private var privacyPage: some View {
        VStack(spacing: 12) {
            settingsCard(id: "online", icon: "eye.fill", title: "Статус и видимость") {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        accentIcon(settings.offlineMode ? "eye.slash.fill" : "circle.fill")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Оффлайн режим").font(.system(size: 15)).foregroundColor(Theme.text)
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
                    toggleRow("Отчёт о прочтении", "checkmark.circle.fill", $settings.sendReadReceipts)
                    rowDivider()
                    toggleRow("Proximity Ping", "antenna.radiowaves.left.and.right", $settings.proximityPing)
                }.padding(.vertical, 4)
            }
            settingsCard(id: "security", icon: "shield.lefthalf.filled", title: "Безопасность") {
                VStack(spacing: 0) {
                    arrowRow(icon: "iphone.and.arrow.forward", label: "Активные сессии", value: "") { showSessions = true }
                }.padding(.vertical, 4)
            }
        }
    }

    private var appearancePage: some View {
        VStack(spacing: 12) {
            settingsCard(id: "theme", icon: "paintpalette.fill", title: "Тема") {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        accentIcon("paintbrush.fill")
                        Text("Акцентный цвет").font(.system(size: 15)).foregroundColor(Theme.text)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { themeManager.accent },
                            set: { color in
                                if let components = UIColor(color).cgColor.components, components.count >= 3 {
                                    let hex = String(format: "#%02X%02X%02X",
                                        Int(components[0] * 255),
                                        Int(components[1] * 255),
                                        Int(components[2] * 255))
                                    UserDefaults.standard.set(hex, forKey: "custom_accent_hex")
                                    themeManager.customAccentHex = hex
                                }
                            }
                        ), supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }.padding(.vertical, 4)
            }
            settingsCard(id: "language", icon: "globe", title: "Язык") {
                VStack(spacing: 0) {
                    segmentRow("Язык интерфейса", "globe", ["RU", "EN"], Binding(
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
        }
    }

    private var accountPage: some View {
        VStack(spacing: 12) {
            settingsCard(id: "session", icon: "rectangle.portrait.and.arrow.right", title: "Сессия") {
                VStack(spacing: 0) {
                    Button {
                        Task { await auth.logout() }
                    } label: {
                        HStack(spacing: 14) {
                            accentIcon("rectangle.portrait.and.arrow.right", color: .red)
                            if auth.isLoading { ProgressView().tint(.red) }
                            else { Text("Выйти из аккаунта").font(.system(size: 15)).foregroundColor(.red) }
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                    }
                    .buttonStyle(.plain).disabled(auth.isLoading)
                }.padding(.vertical, 4)
            }
            settingsCard(id: "danger", icon: "trash.fill", title: "Опасная зона") {
                VStack(spacing: 0) {
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
        }
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

    private func emptyCard(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(Theme.dim)
            Text(text).font(.system(size: 14)).foregroundColor(Theme.muted)
            Spacer()
        }
        .padding(16)
        .background(Theme.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
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
