import SwiftUI

struct ContactsView: View {
    @State private var contacts     = MockData.contacts
    @State private var searchText   = ""
    @State private var showQR       = false
    @State private var showScanner  = false
    @State private var showPending  = false
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentContacts

    private var filtered: [Contact] {
        let list = contacts.filter { !$0.isPendingRequest }
        guard !searchText.isEmpty else { return list }
        let q = searchText.lowercased()
        return list.filter { $0.name.lowercased().contains(q) || $0.username.lowercased().contains(q) }
    }

    private var pending:   [Contact] { contacts.filter { $0.isPendingRequest } }
    private var favorites: [Contact] { filtered.filter { $0.isFavorite } }
    private var online:    [Contact] { filtered.filter { $0.isOnline && !$0.isFavorite } }
    private var offline:   [Contact] { filtered.filter { !$0.isOnline && !$0.isFavorite } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    SearchBar(text: $searchText, accentColor: accent)
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    if !pending.isEmpty { pendingBanner }
                    contactList
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showQR)      { QRCardSheet(accent: accent) }
            .sheet(isPresented: $showScanner) { QRScannerStub() }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                AnimatedIcon(name: "person.2.fill", size: 17, color: accent)
                Text("Контакты")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text).kerning(-0.5)
            }
            Spacer()
            HStack(spacing: 8) {
                if settings.proximityPing {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 13)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
                Button { showScanner = true } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
                Button { showQR = true } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
                Button {
                    if settings.antispam {
                        toast.show("Запрос отправлен контакту", style: .info, icon: "person.badge.plus")
                    } else {
                        toast.show("Контакт добавлен", style: .success, icon: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
    }

    // MARK: - Pending Banner (антиспам)
    private var pendingBanner: some View {
        Button {
            withAnimation { showPending.toggle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.clock.fill")
                    .font(.system(size: 14)).foregroundColor(accent)
                    .frame(width: 32, height: 32).background(accent.opacity(0.12)).cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Запросы на добавление")
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.text)
                    Text("\(pending.count) ожидает ответа")
                        .font(.system(size: 12)).foregroundColor(Theme.muted)
                }
                Spacer()
                UnreadBadge(count: pending.count, color: accent)
                Image(systemName: showPending ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11)).foregroundColor(Theme.dim)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(accent.opacity(0.06))
            .overlay(Rectangle().frame(height: 0.5).foregroundColor(accent.opacity(0.2)), alignment: .bottom)
        }
        .buttonStyle(.plain)

        if showPending {
            VStack(spacing: 0) {
                ForEach(pending) { contact in
                    PendingContactRow(contact: contact, accent: accent) { accept in
                        withAnimation {
                            contacts.removeAll { $0.id == contact.id }
                            if accept {
                                var c = contact; c = Contact(
                                    name: c.name, username: c.username,
                                    isPendingRequest: false)
                                contacts.append(c)
                                toast.show("\(contact.name) добавлен", style: .success)
                            } else {
                                toast.show("Запрос отклонён", style: .error)
                            }
                        }
                    }
                    Divider().background(Theme.sep).padding(.leading, 72)
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - List
    private var contactList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                if !favorites.isEmpty {
                    Section {
                        ForEach(favorites) { c in contactRow(c) }
                    } header: {
                        SectionHeader(title: "Избранные · \(favorites.count)", accentColor: accent).background(Theme.bg)
                    }
                }
                if !online.isEmpty {
                    Section {
                        ForEach(online) { c in contactRow(c) }
                    } header: {
                        SectionHeader(title: "Онлайн · \(online.count)", accentColor: accent).background(Theme.bg)
                    }
                }
                if !offline.isEmpty {
                    Section {
                        ForEach(offline) { c in contactRow(c) }
                    } header: {
                        SectionHeader(title: "Остальные", accentColor: accent).background(Theme.bg)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contactRow(_ contact: Contact) -> some View {
        ContactRow(contact: contact, accent: accent) {
            toast.show("Написать \(contact.name)", style: .info)
        }
        .contextMenu {
            Button { toast.show("Изменить", style: .info) } label: {
                Label("Редактировать", systemImage: "pencil")
            }
            Button(role: .destructive) {
                toast.show("\(contact.name) заблокирован", style: .error, icon: "slash.circle.fill")
            } label: {
                Label("Заблокировать", systemImage: "slash.circle.fill")
            }
        }
        Divider().background(Theme.sep).padding(.leading, 72)
    }
}

// MARK: - Pending Row
struct PendingContactRow: View {
    let contact: Contact
    let accent: Color
    let onDecide: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: contact.avatarInitials, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                Text(contact.username).font(.system(size: 12)).foregroundColor(Theme.muted)
            }
            Spacer()
            HStack(spacing: 8) {
                Button { onDecide(false) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                        .frame(width: 30, height: 30).background(Color.red.opacity(0.1)).cornerRadius(8)
                }
                Button { onDecide(true) } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(accent)
                        .frame(width: 30, height: 30).background(accent.opacity(0.1)).cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - ContactRow
struct ContactRow: View {
    let contact: Contact
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: contact.avatarInitials, size: 46,
                       isOnline: contact.isOnline, hasStory: contact.hasStory)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    if contact.isFavorite {
                        Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(Theme.accentGroups)
                    }
                }
                Text(contact.isOnline
                     ? "онлайн"
                     : (contact.lastSeen.isEmpty ? contact.username : "был \(contact.lastSeen)"))
                .font(.system(size: 13))
                .foregroundColor(contact.isOnline ? accent : Theme.muted)
            }
            Spacer()
            Button(action: onTap) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 14)).foregroundColor(accent)
                    .frame(width: 32, height: 32).background(accent.opacity(0.12)).cornerRadius(8)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 9).contentShape(Rectangle())
    }
}

// MARK: - QR Scanner Stub
struct QRScannerStub: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Сканер QR").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.accentContacts, lineWidth: 2)
                        .frame(width: 220, height: 220)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50)).foregroundColor(Theme.accentContacts.opacity(0.4))
                    Text("Камера недоступна\nв симуляторе")
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center).padding(.top, 70)
                }
                Button { dismiss() } label: {
                    Text("Закрыть").font(.system(size: 15)).foregroundColor(Theme.accentContacts)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
