import SwiftUI

// MARK: - API Models
struct APIContact: Decodable, Identifiable {
    let id: String
    let contact_id: String
    let status: String
    let is_favorite: Bool
    let user: APIContactUser?

    struct APIContactUser: Decodable {
        let id: String
        let username: String
        let display_name: String
        let avatar_url: String
        let bio: String
        let is_online: Bool
    }
}

struct APIPendingContact: Decodable, Identifiable {
    let id: String
    var _id: String { id }
    let contact_record_id: String
    let from_user_id: String
    let username: String
    let display_name: String
    let avatar_url: String
}

struct ContactsView: View {
    @State private var contacts:  [APIContact] = []
    @State private var pending:   [APIPendingContact] = []
    @State private var searchText = ""
    @State private var showPending = false
    @State private var showAddSheet = false
    @State private var showQR = false
    @State private var isLoading = false

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentContacts

    private var accepted: [APIContact] { contacts.filter { $0.status == "accepted" } }

    private var filtered: [APIContact] {
        guard !searchText.isEmpty else { return accepted }
        let q = searchText.lowercased()
        return accepted.filter {
            ($0.user?.display_name.lowercased().contains(q) ?? false) ||
            ($0.user?.username.lowercased().contains(q) ?? false)
        }
    }

    private var favorites: [APIContact] { filtered.filter { $0.is_favorite } }
    private var online:    [APIContact] { filtered.filter { ($0.user?.is_online ?? false) && !$0.is_favorite && !settings.offlineMode } }
    private var offline:   [APIContact] { filtered.filter { (!($0.user?.is_online ?? false) || settings.offlineMode) && !$0.is_favorite } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    SearchBar(text: $searchText, accentColor: accent)
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    if !pending.isEmpty { pendingBanner }
                    if isLoading && contacts.isEmpty {
                        Spacer()
                        ProgressView().tint(accent)
                        Spacer()
                    } else {
                        contactList
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSheet) { AddContactSheet(accent: accent, onAdded: loadContacts) }
            .sheet(isPresented: $showQR)       { QRCardSheet(accent: accent) }
            .task { await loadContacts(); await loadPending() }
            .refreshable { await loadContacts(); await loadPending() }
        }
    }

    private func loadContacts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            contacts = try await APIClient.shared.request(url: API.Contacts.list)
        } catch {
            toast.show("Ошибка загрузки контактов", style: .error)
        }
    }

    private func loadPending() async {
        do {
            pending = try await APIClient.shared.request(url: API.Contacts.pending)
        } catch {}
    }

    private func accept(_ p: APIPendingContact) async {
        do {
            _ = try await APIClient.shared.request(
                url: API.Contacts.accept(p.contact_record_id), method: .POST) as EmptyResponse
            pending.removeAll { $0.contact_record_id == p.contact_record_id }
            await loadContacts()
            toast.show("\(p.display_name) добавлен", style: .success)
        } catch { toast.show("Ошибка", style: .error) }
    }

    private func reject(_ p: APIPendingContact) async {
        do {
            _ = try await APIClient.shared.request(
                url: API.Contacts.reject(p.contact_record_id), method: .POST) as EmptyResponse
            pending.removeAll { $0.contact_record_id == p.contact_record_id }
            toast.show("Запрос отклонён", style: .error)
        } catch { toast.show("Ошибка", style: .error) }
    }

    private func remove(_ c: APIContact) async {
        do {
            _ = try await APIClient.shared.request(
                url: API.Contacts.remove(c.contact_id), method: .DELETE) as EmptyResponse
            contacts.removeAll { $0.id == c.id }
            toast.show("Контакт удалён", style: .info)
        } catch { toast.show("Ошибка", style: .error) }
    }

    private func toggleFavorite(_ c: APIContact) async {
        struct FavReq: Encodable { let favorite: Bool }
        do {
            _ = try await APIClient.shared.request(
                url: API.Contacts.favorite(c.contact_id), method: .PATCH,
                body: FavReq(favorite: !c.is_favorite)) as EmptyResponse
            await loadContacts()
        } catch {}
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

                Button { showQR = true } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
                Button { showAddSheet = true } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
    }

    // MARK: - Pending Banner
    private var pendingBanner: some View {
        VStack(spacing: 0) {
            Button { withAnimation { showPending.toggle() } } label: {
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
                    ForEach(pending) { p in
                        HStack(spacing: 12) {
                            AvatarView(initials: String(p.display_name.prefix(2)).uppercased(), size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.display_name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                                Text("@\(p.username)").font(.system(size: 12)).foregroundColor(Theme.muted)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button { Task { await reject(p) } } label: {
                                    Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                                        .frame(width: 30, height: 30).background(Color.red.opacity(0.1)).cornerRadius(8)
                                }
                                Button { Task { await accept(p) } } label: {
                                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(accent)
                                        .frame(width: 30, height: 30).background(accent.opacity(0.1)).cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        Divider().background(Theme.sep).padding(.leading, 72)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPending)
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
                if filtered.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2").font(.system(size: 32)).foregroundColor(Theme.dim)
                        Text(searchText.isEmpty ? "Нет контактов" : "Ничего не найдено")
                            .font(.system(size: 15)).foregroundColor(Theme.muted)
                        if searchText.isEmpty {
                            Button { showAddSheet = true } label: {
                                Text("Добавить контакт")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
        }
    }

    @ViewBuilder
    private func contactRow(_ c: APIContact) -> some View {
        let name = c.user?.display_name ?? c.user?.username ?? "Unknown"
        let initials = String(name.prefix(2)).uppercased()
        let isOnline = (c.user?.is_online ?? false) && !settings.offlineMode

        HStack(spacing: 12) {
            AvatarView(initials: initials, size: 46, isOnline: isOnline)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    if c.is_favorite {
                        Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(Theme.accentGroups)
                    }
                }
                Text(isOnline ? "онлайн" : "@\(c.user?.username ?? "")")
                    .font(.system(size: 13))
                    .foregroundColor(isOnline ? accent : Theme.muted)
            }
            Spacer()
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 14)).foregroundColor(accent)
                .frame(width: 32, height: 32).background(accent.opacity(0.12)).cornerRadius(8)
        }
        .padding(.horizontal, 16).padding(.vertical, 9).contentShape(Rectangle())
        .contextMenu {
            Button { Task { await toggleFavorite(c) } } label: {
                Label(c.is_favorite ? "Убрать из избранных" : "В избранное",
                      systemImage: c.is_favorite ? "star.slash" : "star")
            }
            Button(role: .destructive) { Task { await remove(c) } } label: {
                Label("Удалить", systemImage: "person.badge.minus")
            }
        }
        Divider().background(Theme.sep).padding(.leading, 72)
    }
}

// MARK: - Add Contact Sheet
struct AddContactSheet: View {
    let accent: Color
    let onAdded: () async -> Void
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10)
                Text("Добавить контакт")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Username").font(.system(size: 13)).foregroundColor(Theme.muted)
                    HStack(spacing: 10) {
                        Image(systemName: "at").foregroundColor(accent)
                        TextField("username", text: $username)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .foregroundColor(Theme.text).tint(accent)
                    }
                    .padding(12).background(Theme.card).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                }
                .padding(.horizontal, 24)

                if let e = errorMsg {
                    Text(e).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 24)
                }

                Button {
                    Task { await addContact() }
                } label: {
                    ZStack {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Добавить").font(.system(size: 16, weight: .semibold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(username.count >= 3 ? accent : Theme.dim).cornerRadius(14)
                }
                .disabled(username.count < 3 || isLoading)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }

    private func addContact() async {
        isLoading = true; errorMsg = nil
        defer { isLoading = false }
        struct AddReq: Encodable { let username: String }
        do {
            _ = try await APIClient.shared.request(
                url: API.Contacts.list, method: .POST,
                body: AddReq(username: username.lowercased())) as EmptyResponse
            await onAdded()
            toast.show("Запрос отправлен", style: .success)
            dismiss()
        } catch APIError.server(let msg) {
            errorMsg = msg
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}

