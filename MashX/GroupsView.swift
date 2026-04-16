import SwiftUI

// MARK: - API Models
struct APIGroup: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String
    let avatar_url: String
    let is_public: Bool
    let owner_id: String
    let member_count: Int
    let created_at: String
}

struct APIGroupMember: Decodable, Identifiable {
    let id: String
    let user_id: String
    let role: String
    let user: APIMemberUser?

    struct APIMemberUser: Decodable {
        let id: String
        let username: String
        let display_name: String
        let avatar_url: String
        let is_online: Bool
    }
}

struct GroupsView: View {
    @State private var myGroups:    [APIGroup] = []
    @State private var publicGroups:[APIGroup] = []
    @State private var searchText  = ""
    @State private var filterIndex = 0
    @State private var showDiscover = false
    @State private var showCreate   = false
    @State private var isLoading    = false

    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentGroups
    private let filters = ["Все", "Мои", "Публичные"]

    private var filtered: [APIGroup] {
        var list: [APIGroup]
        switch filterIndex {
        case 1: list = myGroups
        case 2: list = publicGroups
        default: list = myGroups
        }
        guard !searchText.isEmpty else { return list }
        return list.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    headerBar
                    SearchBar(text: $searchText, accentColor: accent).padding(.horizontal, 16).padding(.bottom, 8)
                    filterChips
                    if isLoading && myGroups.isEmpty {
                        Spacer(); ProgressView().tint(accent); Spacer()
                    } else {
                        groupList
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDiscover) { DiscoverRoomsView(accent: accent, onJoined: loadMyGroups) }
            .sheet(isPresented: $showCreate)   { CreateGroupSheet(accent: accent, onCreated: loadMyGroups) }
            .task { await loadMyGroups(); await loadPublic() }
            .refreshable { await loadMyGroups(); await loadPublic() }
        }
    }

    private func loadMyGroups() async {
        isLoading = true; defer { isLoading = false }
        do { myGroups = try await APIClient.shared.request(url: API.Groups.list) }
        catch { toast.show("Ошибка загрузки групп", style: .error) }
    }

    private func loadPublic() async {
        do { publicGroups = try await APIClient.shared.request(url: API.Groups.pub) }
        catch {}
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                AnimatedIcon(name: "person.3.fill", size: 17, color: accent)
                Text("Группы").font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text).kerning(-0.5)
            }
            Spacer()
            HStack(spacing: 8) {
                Button { showDiscover = true } label: {
                    Image(systemName: "safari.fill").font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
                Button { showCreate = true } label: {
                    Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(filters.indices, id: \.self) { i in
                    FilterChip(label: filters[i], isSelected: filterIndex == i, accent: accent) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { filterIndex = i }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private var groupList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filtered) { g in
                    NavigationLink(destination: GroupDetailView(group: g, onLeft: loadMyGroups)) {
                        APIGroupRow(group: g, accent: accent)
                    }
                    .buttonStyle(.plain)
                    Divider().background(Theme.sep).padding(.leading, 72)
                }
                if filtered.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3").font(.system(size: 32)).foregroundColor(Theme.dim)
                        Text("Нет групп").font(.system(size: 15)).foregroundColor(Theme.muted)
                        Button { showCreate = true } label: {
                            Text("Создать группу").font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                }
            }
        }
    }
}

// MARK: - GroupRow
struct APIGroupRow: View {
    let group: APIGroup
    let accent: Color
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: String(group.name.prefix(2)).uppercased(), size: 48, accentColor: accent)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(group.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    if group.is_public { Image(systemName: "globe").font(.system(size: 10)).foregroundColor(accent) }
                    Spacer()
                }
                HStack(spacing: 3) {
                    Image(systemName: "person.2.fill").font(.system(size: 9)).foregroundColor(Theme.dim)
                    Text("\(group.member_count) участников").font(.system(size: 12)).foregroundColor(Theme.muted)
                }
                if !group.description.isEmpty {
                    Text(group.description).font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
    }
}

// MARK: - Group Detail
struct GroupDetailView: View {
    let group: APIGroup
    let onLeft: () async -> Void
    @State private var members: [APIGroupMember] = []
    @State private var showMembers = false
    @State private var isLeaving = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
    @EnvironmentObject private var auth: AuthManager
    private let accent = Theme.accentGroups

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Group info card
                        VStack(spacing: 10) {
                            AvatarView(initials: String(group.name.prefix(2)).uppercased(), size: 64, accentColor: accent)
                            Text(group.name).font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text)
                            if !group.description.isEmpty {
                                Text(group.description).font(.system(size: 14)).foregroundColor(Theme.muted)
                                    .multilineTextAlignment(.center).padding(.horizontal, 24)
                            }
                            HStack(spacing: 16) {
                                Label("\(group.member_count)", systemImage: "person.2.fill")
                                    .font(.system(size: 13)).foregroundColor(Theme.muted)
                                if group.is_public {
                                    Label("Публичная", systemImage: "globe")
                                        .font(.system(size: 13)).foregroundColor(accent)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                        .background(Theme.card).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 0.5))
                        .padding(.horizontal, 16).padding(.top, 8)

                        // Members preview
                        if !members.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                SectionHeader(title: "Участники · \(group.member_count)", accentColor: accent)
                                ForEach(members.prefix(5)) { m in
                                    memberRow(m)
                                    Divider().background(Theme.sep).padding(.leading, 60)
                                }
                                if group.member_count > 5 {
                                    Button { showMembers = true } label: {
                                        Text("Все участники →")
                                            .font(.system(size: 14)).foregroundColor(accent)
                                            .padding(.horizontal, 16).padding(.vertical, 12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Theme.card).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
                            .padding(.horizontal, 16)
                        }

                        // Leave button (не для owner)
                        if group.owner_id != (auth.currentUser?.id ?? "") {
                            Button {
                                Task { await leaveGroup() }
                            } label: {
                                HStack(spacing: 8) {
                                    if isLeaving { ProgressView().tint(.red) }
                                    else {
                                        Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.red)
                                        Text("Покинуть группу").foregroundColor(.red)
                                    }
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color.red.opacity(0.1)).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 0.5))
                            }
                            .padding(.horizontal, 16)
                            .disabled(isLeaving)
                        }

                        Spacer().frame(height: 80)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showMembers) { MembersSheetView(group: group, members: members, accent: accent) }
        .task { await loadMembers() }
    }

    private func loadMembers() async {
        do { members = try await APIClient.shared.request(url: API.Groups.members(group.id)) }
        catch {}
    }

    private func leaveGroup() async {
        isLeaving = true; defer { isLeaving = false }
        do {
            _ = try await APIClient.shared.request(url: API.Groups.leave(group.id), method: .DELETE) as EmptyResponse
            await onLeft()
            toast.show("Вы покинули группу", style: .info)
            dismiss()
        } catch APIError.server(let msg) {
            toast.show(msg, style: .error)
        } catch {
            toast.show("Ошибка", style: .error)
        }
    }

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    Text("Группы")
                }
                .foregroundColor(accent)
            }
            Spacer()
            Text(group.name).font(.system(size: 16, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
            Spacer()
            Button { showMembers = true } label: {
                Image(systemName: "person.2.fill").font(.system(size: 15)).foregroundColor(accent)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Theme.bgSecond)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .bottom)
    }

    private func memberRow(_ m: APIGroupMember) -> some View {
        let name = m.user?.display_name ?? m.user?.username ?? "User"
        let initials = String(name.prefix(2)).uppercased()
        return HStack(spacing: 12) {
            AvatarView(initials: initials, size: 38, isOnline: m.user?.is_online ?? false)
            Text(name).font(.system(size: 14)).foregroundColor(Theme.text)
            Spacer()
            roleLabel(m.role)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func roleLabel(_ role: String) -> some View {
        let (label, color): (String, Color) = {
            switch role {
            case "owner":     return ("Владелец", Color(hex: "#EC4899"))
            case "admin":     return ("Админ",    Theme.accentProfile)
            case "moderator": return ("Модер",    Theme.accentChats)
            default:          return ("Участник", Theme.muted)
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .semibold)).foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.12)).cornerRadius(6)
    }
}

// MARK: - Members Sheet
struct MembersSheetView: View {
    let group: APIGroup
    let members: [APIGroupMember]
    let accent: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10).padding(.bottom, 16)
                HStack {
                    Text("Участники · \(group.member_count)")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(members) { m in
                            let name = m.user?.display_name ?? m.user?.username ?? "User"
                            HStack(spacing: 12) {
                                AvatarView(initials: String(name.prefix(2)).uppercased(), size: 42,
                                           isOnline: m.user?.is_online ?? false)
                                Text(name).font(.system(size: 15)).foregroundColor(Theme.text)
                                Spacer()
                                roleTag(m.role)
                            }
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            Divider().background(Theme.sep).padding(.leading, 74)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func roleTag(_ role: String) -> some View {
        let (label, color): (String, Color) = {
            switch role {
            case "owner":     return ("Владелец", Color(hex: "#EC4899"))
            case "admin":     return ("Админ",    Theme.accentProfile)
            case "moderator": return ("Модер",    Theme.accentChats)
            default:          return ("Участник", Theme.muted)
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .semibold)).foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.12)).cornerRadius(6)
    }
}

// MARK: - Discover Rooms
struct DiscoverRoomsView: View {
    let accent: Color
    let onJoined: () async -> Void
    @State private var rooms: [APIGroup] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager

    private var filtered: [APIGroup] {
        guard !searchText.isEmpty else { return rooms }
        return rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Публичные группы").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                        Text("Открытые группы по темам").font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                SearchBar(text: $searchText, accentColor: accent).padding(.horizontal, 16).padding(.bottom, 8)

                if isLoading {
                    Spacer(); ProgressView().tint(accent); Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(filtered) { room in
                                HStack(spacing: 12) {
                                    AvatarView(initials: String(room.name.prefix(2)).uppercased(), size: 46, accentColor: accent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(room.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                                        if !room.description.isEmpty {
                                            Text(room.description).font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
                                        }
                                        HStack(spacing: 3) {
                                            Image(systemName: "person.2.fill").font(.system(size: 9)).foregroundColor(Theme.dim)
                                            Text("\(room.member_count)").font(.system(size: 11)).foregroundColor(Theme.dim)
                                        }
                                    }
                                    Spacer()
                                    Button { Task { await joinGroup(room) } } label: {
                                        Text("Вступить")
                                            .font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(accent.opacity(0.12)).cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent.opacity(0.3), lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                Divider().background(Theme.sep).padding(.leading, 78)
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .task { await loadPublic() }
    }

    private func loadPublic() async {
        isLoading = true; defer { isLoading = false }
        do {
            let q = searchText.isEmpty ? "" : "?q=\(searchText)"
            rooms = try await APIClient.shared.request(url: API.Groups.pub + q)
        } catch {}
    }

    private func joinGroup(_ g: APIGroup) async {
        do {
            _ = try await APIClient.shared.request(url: API.Groups.join(g.id), method: .POST) as EmptyResponse
            await onJoined()
            toast.show("Вы вступили в \(g.name)", style: .success)
            dismiss()
        } catch APIError.server(let msg) {
            toast.show(msg, style: .error)
        } catch { toast.show("Ошибка", style: .error) }
    }
}

// MARK: - Create Group Sheet
struct CreateGroupSheet: View {
    let accent: Color
    let onCreated: () async -> Void
    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var isLoading = false
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule().fill(Theme.dim).frame(width: 36, height: 4).padding(.top, 10)
                Text("Создать группу").font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)

                VStack(spacing: 12) {
                    fieldView("Название группы", placeholder: "Введите название", text: $name)
                    fieldView("Описание (необязательно)", placeholder: "О чём группа?", text: $description)

                    HStack {
                        Text("Публичная группа").font(.system(size: 15)).foregroundColor(Theme.text)
                        Spacer()
                        Toggle("", isOn: $isPublic).tint(accent).labelsHidden()
                    }
                    .padding(12).background(Theme.card).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
                }
                .padding(.horizontal, 24)

                if let e = errorMsg {
                    Text(e).font(.system(size: 13)).foregroundColor(.red).padding(.horizontal, 24)
                }

                Button { Task { await createGroup() } } label: {
                    ZStack {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Создать").font(.system(size: 16, weight: .semibold)).foregroundColor(.white) }
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(name.count >= 2 ? accent : Theme.dim).cornerRadius(14)
                }
                .disabled(name.count < 2 || isLoading)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .presentationDetents([.medium])
    }

    private func fieldView(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13)).foregroundColor(Theme.muted)
            TextField(placeholder, text: text)
                .foregroundColor(Theme.text).tint(accent)
                .padding(12).background(Theme.card).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
        }
    }

    private func createGroup() async {
        isLoading = true; errorMsg = nil; defer { isLoading = false }
        struct CreateReq: Encodable { let name: String; let description: String; let is_public: Bool }
        do {
            _ = try await APIClient.shared.request(
                url: API.Groups.list, method: .POST,
                body: CreateReq(name: name, description: description, is_public: isPublic)) as EmptyResponse
            await onCreated()
            toast.show("Группа создана", style: .success)
            dismiss()
        } catch APIError.server(let msg) { errorMsg = msg }
        catch { errorMsg = error.localizedDescription }
    }
}
