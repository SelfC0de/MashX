import SwiftUI

// MARK: - ProfileView
struct ProfileView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager

    @State private var showQR = false
    @FocusState private var field: ProfileField?

    private let accent = Theme.accentProfile
    private enum ProfileField { case name, bio }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader
                        Divider().background(Theme.sep).padding(.vertical, 4)
                        editSection
                        Divider().background(Theme.sep).padding(.vertical, 4)
                        linksSection
                        Spacer().frame(height: 110)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") { field = nil }
                        .foregroundColor(accent).fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showQR) { QRCardSheet(accent: accent) }
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        ZStack {
            ProfileGridBG().frame(height: 220).opacity(0.35)
            VStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(colors: [accent, Color(hex: "#EC4899")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2.5
                            )
                            .frame(width: 96, height: 96)
                        RoundedRectangle(cornerRadius: 28)
                            .fill(accent.opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(accent.opacity(0.35), lineWidth: 0.5))
                            .frame(width: 84, height: 84)
                        Text(avatarInitials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(accent)
                    }
                    Button {
                        toast.show("Изменить фото", style: .info, icon: "camera.fill")
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(accent)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.bg, lineWidth: 2))
                    }
                    .offset(x: 4, y: 4)
                }

                VStack(spacing: 4) {
                    Text(settings.username.isEmpty ? "Ваше имя" : settings.username)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(settings.username.isEmpty ? Theme.muted : Theme.text)

                    if !settings.bio.isEmpty {
                        Text(settings.bio)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.muted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Button {
                        UIPasteboard.general.string = "@mashx_user"
                        toast.show("@mashx_user скопирован", style: .success, icon: "doc.on.clipboard")
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "at").font(.system(size: 10, weight: .bold)).foregroundColor(accent)
                            Text("mashx_user").font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(accent.opacity(0.12))
                        .overlay(Capsule().stroke(accent.opacity(0.3), lineWidth: 0.5))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 0) {
                    statCard("7",  "Чатов",     accent)
                    Rectangle().fill(Theme.sep).frame(width: 0.5, height: 32)
                    statCard("5",  "Групп",     Theme.accentGroups)
                    Rectangle().fill(Theme.sep).frame(width: 0.5, height: 32)
                    statCard("7",  "Контактов", Theme.accentContacts)
                }
                .padding(.horizontal, 24).padding(.top, 4)
            }
            .padding(.top, 24).padding(.bottom, 20)
        }
    }

    private var avatarInitials: String {
        let parts = settings.username.components(separatedBy: " ")
        let ini = parts.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
        return ini.isEmpty ? "MX" : ini
    }

    private func statCard(_ val: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(val).font(.system(size: 20, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Edit section
    private var editSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 11)).foregroundColor(accent)
                Text("ЛИЧНЫЕ ДАННЫЕ")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted).kerning(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 8)

            profileField("Имя",    placeholder: "Ваше имя",       text: $settings.username, tag: .name)
            Divider().background(Theme.sep).padding(.leading, 48)
            profileField("Статус", placeholder: "Напишите статус", text: $settings.bio,      tag: .bio)
        }
    }

    private func profileField(_ label: String, placeholder: String, text: Binding<String>, tag: ProfileField) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15)).foregroundColor(Theme.muted)
                .frame(width: 64, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.system(size: 15)).foregroundColor(Theme.text)
                .tint(accent)
                .focused($field, equals: tag)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    // MARK: - Links section
    private var linksSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "link").font(.system(size: 11)).foregroundColor(accent)
                Text("ПОДЕЛИТЬСЯ").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted).kerning(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 8)

            Button { showQR = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 13)).foregroundColor(accent)
                        .frame(width: 28, height: 28).background(accent.opacity(0.14)).cornerRadius(7)
                    Text("QR-визитка").font(.system(size: 15)).foregroundColor(Theme.text)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(Theme.dim)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Subtle grid background
struct ProfileGridBG: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 28
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            ctx.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 0.5)
        }
    }
}

// MARK: - Sessions Sheet
struct SessionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentProfile

    private let sessions: [(String, String, String, String, Bool)] = [
        ("iPhone 15 Pro", "iOS 17.4",   "Москва, RU", "Сейчас",   true),
        ("MacBook Pro",   "macOS 14.3", "Москва, RU", "3ч назад", false),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10).padding(.bottom, 16)

                HStack {
                    Text("Активные сессии").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)

                ForEach(sessions, id: \.0) { name, os, location, time, current in
                    HStack(spacing: 14) {
                        Image(systemName: name.contains("Mac") ? "laptopcomputer" : "iphone")
                            .font(.system(size: 22)).foregroundColor(accent)
                            .frame(width: 50, height: 50).background(accent.opacity(0.12)).cornerRadius(12)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                                if current {
                                    Text("текущее")
                                        .font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(accent).cornerRadius(4)
                                }
                            }
                            Text(os).font(.system(size: 12)).foregroundColor(Theme.muted)
                            HStack(spacing: 3) {
                                Image(systemName: "location.fill").font(.system(size: 9)).foregroundColor(Theme.dim)
                                Text("\(location) · \(time)").font(.system(size: 11)).foregroundColor(Theme.dim)
                            }
                        }
                        Spacer()
                        if !current {
                            Button {
                                toast.show("Сессия завершена", style: .success)
                            } label: {
                                Text("Завершить")
                                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.red)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    Divider().background(Theme.sep).padding(.leading, 84)
                }

                Spacer()

                Button {
                    toast.show("Все сессии завершены", style: .success)
                    dismiss()
                } label: {
                    Text("Завершить все остальные")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.red)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - QR Card Sheet
struct QRCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
    let accent: Color

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10).padding(.bottom, 24)

                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(colors: [accent, Color(hex: "#EC4899")],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
                            )
                        VStack(spacing: 16) {
                            Text("MashX").font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.white).frame(width: 180, height: 180)
                                Image(systemName: "qrcode").font(.system(size: 140)).foregroundColor(Color(hex: "#0d0d14"))
                            }
                            VStack(spacing: 4) {
                                Text("@mashx_user").font(.system(size: 16, weight: .semibold)).foregroundColor(accent)
                                Text("Отсканируй чтобы написать").font(.system(size: 12)).foregroundColor(Theme.muted)
                            }
                        }
                        .padding(28)
                    }
                    .padding(.horizontal, 32)

                    HStack(spacing: 12) {
                        shareButton("square.and.arrow.up", "Поделиться") { toast.show("Ссылка скопирована", style: .success) }
                        shareButton("doc.on.clipboard", "Скопировать") {
                            UIPasteboard.general.string = "https://mashx.app/@mashx_user"
                            toast.show("Ссылка скопирована", style: .success)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                Spacer()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func shareButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(label).font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(accent)
            .frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(accent.opacity(0.12)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Accent Picker Sheet
struct AccentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let presets: [(String, Color)]
    @Binding var current: Int
    private let accent = Theme.accentProfile

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10).padding(.bottom, 20)
                Text("Акцентный цвет").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text).padding(.bottom, 24)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(presets.indices, id: \.self) { i in
                        let (label, color) = presets[i]
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { current = i }
                        } label: {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(color.opacity(0.18)).frame(width: 64, height: 64)
                                    Circle().fill(color).frame(width: 40, height: 40)
                                    if current == i {
                                        Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                                    }
                                }
                                .overlay(Circle().stroke(current == i ? color : Color.clear, lineWidth: 2).frame(width: 64, height: 64))
                                Text(label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(current == i ? color : Theme.muted)
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(current == i ? 1.05 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: current == i)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                Button { dismiss() } label: {
                    Text("Применить")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(presets[current].1).cornerRadius(14)
                }
                .padding(.horizontal, 32).padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
