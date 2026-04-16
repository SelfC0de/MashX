import SwiftUI

// MARK: - GroupsView
struct GroupsView: View {
    @State private var groups       = MockData.groups
    @State private var publicRooms  = MockData.publicRooms
    @State private var searchText   = ""
    @State private var filterIndex  = 0
    @State private var showDiscover = false
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentGroups
    private let filters = ["Все", "Мои", "Публичные"]

    private var filtered: [Group] {
        var list = groups
        switch filterIndex {
        case 1: list = list.filter { !$0.isPublic }
        case 2: list = list.filter { $0.isPublic }
        default: break
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
                    SearchBar(text: $searchText, accentColor: accent)
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    filterChips
                    groupList
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showDiscover) { DiscoverRoomsView(rooms: publicRooms) }
        }
    }

    private var headerBar: some View {
        HStack {
            HStack(spacing: 6) {
                AnimatedIcon(name: "person.3.fill", size: 17, color: accent)
                Text("Группы")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text).kerning(-0.5)
            }
            Spacer()
            HStack(spacing: 8) {
                Button { showDiscover = true } label: {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(accent)
                        .frame(width: 34, height: 34).background(accent.opacity(0.12)).cornerRadius(8)
                }
                Button {
                    toast.show("Создать группу", style: .info, icon: "person.3.fill")
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold)).foregroundColor(accent)
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
                ForEach(filtered) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupRow(group: group, accent: accent)
                    }
                    .buttonStyle(.plain)
                    Divider().background(Theme.sep).padding(.leading, 72)
                }
            }
        }
    }
}

// MARK: - GroupRow
struct GroupRow: View {
    let group: Group
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: group.avatarInitials, size: 48, accentColor: accent)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text).lineLimit(1)
                    if group.isPublic {
                        Image(systemName: "globe")
                            .font(.system(size: 10)).foregroundColor(accent)
                    }
                    Spacer()
                    Text(group.time).font(.system(size: 12)).foregroundColor(Theme.dim)
                }
                HStack {
                    Text(group.lastMessage)
                        .font(.system(size: 13)).foregroundColor(Theme.muted).lineLimit(1)
                    Spacer()
                    UnreadBadge(count: group.unread, color: accent)
                }
                if let thread = group.activeThread {
                    HStack(spacing: 4) {
                        Image(systemName: "text.bubble.fill").font(.system(size: 9)).foregroundColor(accent)
                        Text(thread).font(.system(size: 11)).foregroundColor(accent)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10).contentShape(Rectangle())
    }
}

// MARK: - GroupDetailView
struct GroupDetailView: View {
    let group: Group
    @State private var messages   = MockData.messages
    @State private var poll       = MockData.poll
    @State private var inputText  = ""
    @State private var showThread: Message? = nil
    @State private var showMembers = false
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
    private let accent = Theme.accentGroups

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        PollCard(poll: $poll, accent: accent).padding(.horizontal, 16).padding(.top, 8)
                        ForEach(messages) { msg in
                            VStack(alignment: .leading, spacing: 2) {
                                MessageBubble(message: msg, accent: accent)
                                if !msg.thread.isEmpty || msg.isOutgoing {
                                    threadButton(msg)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)
                }
                inputBar
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focused = false }.foregroundColor(accent).fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showMembers) { MembersSheet(group: group) }
        .sheet(item: $showThread) { msg in
            ThreadView(parentMessage: msg, accent: accent)
        }
    }

    private var navBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(accent)
            }
            AvatarView(initials: group.avatarInitials, size: 34, accentColor: accent)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    if group.isPublic {
                        Image(systemName: "globe").font(.system(size: 10)).foregroundColor(accent)
                    }
                }
                Text("\(group.memberCount) участников")
                    .font(.system(size: 12)).foregroundColor(Theme.muted)
            }
            Spacer()
            Button { showMembers = true } label: {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14)).foregroundColor(accent)
                    .frame(width: 32, height: 32).background(accent.opacity(0.12)).cornerRadius(8)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.bgSecond)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .bottom)
    }

    private func threadButton(_ msg: Message) -> some View {
        Button { showThread = msg } label: {
            HStack(spacing: 5) {
                Image(systemName: "text.bubble").font(.system(size: 10)).foregroundColor(accent)
                Text(msg.thread.isEmpty ? "Ответить в ветке" : "\(msg.thread.count) ответов")
                    .font(.system(size: 11)).foregroundColor(accent)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(accent.opacity(0.08)).cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.leading, msg.isOutgoing ? 0 : 16)
        .frame(maxWidth: .infinity, alignment: msg.isOutgoing ? .trailing : .leading)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            // @ mention hint
            if inputText.hasPrefix("@") {
                Text("@упоминание").font(.system(size: 12)).foregroundColor(accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(accent.opacity(0.1)).cornerRadius(8)
            }
            TextField("Сообщение...", text: $inputText, axis: .vertical)
                .font(.system(size: 15)).foregroundColor(Theme.text).tint(accent)
                .focused($focused).lineLimit(1...4)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Theme.card).cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(focused ? accent.opacity(0.4) : Theme.border, lineWidth: 0.5))
            Button {
                let t = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { return }
                withAnimation { messages.append(Message(text: t, isOutgoing: true, time: "сейчас", status: .sent)) }
                inputText = ""
            } label: {
                Image(systemName: inputText.isEmpty ? "mic.fill" : "arrow.up")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(inputText.isEmpty ? Theme.dim : accent)
                    .clipShape(Circle())
                    .animation(.spring(response: 0.2), value: inputText.isEmpty)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.bgSecond.overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top))
    }
}

// MARK: - Thread View
struct ThreadView: View, Identifiable {
    var id: UUID { parentMessage.id }
    let parentMessage: Message
    let accent: Color
    @State private var replyText = ""
    @State private var replies: [Message] = []
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Ветка обсуждения")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Theme.bgSecond)
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        MessageBubble(message: parentMessage, accent: accent)
                            .padding(.top, 8)
                        if !replies.isEmpty {
                            Divider().background(Theme.sep).padding(.horizontal, 16)
                            ForEach(replies) { r in MessageBubble(message: r, accent: accent) }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                HStack(spacing: 10) {
                    TextField("Ответить...", text: $replyText)
                        .font(.system(size: 15)).foregroundColor(Theme.text).tint(accent)
                        .focused($focused)
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(Theme.card).cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.3), lineWidth: 0.5))
                    Button {
                        let t = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        withAnimation { replies.append(Message(text: t, isOutgoing: true, time: "сейчас", status: .sent)) }
                        replyText = ""
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                            .frame(width: 34, height: 34).background(accent).clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Theme.bgSecond.overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { focused = false }.foregroundColor(accent).fontWeight(.semibold)
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Members Sheet
struct MembersSheet: View {
    let group: Group
    @Environment(\.dismiss) private var dismiss
    private let accent = Theme.accentGroups

    private let roleLabels: [GroupMember.GroupRole: String] = [
        .owner: "Владелец", .admin: "Админ", .moderator: "Модератор", .member: "Участник"
    ]
    private let roleColors: [GroupMember.GroupRole: Color] = [
        .owner: Color(hex: "#EC4899"), .admin: Theme.accentProfile,
        .moderator: Theme.accentChats, .member: Theme.muted
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Участники · \(group.memberCount)")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(group.members) { member in
                            HStack(spacing: 12) {
                                AvatarView(initials: member.avatarInitials, size: 42)
                                Text(member.name).font(.system(size: 15)).foregroundColor(Theme.text)
                                Spacer()
                                Text(roleLabels[member.role] ?? "")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(roleColors[member.role] ?? Theme.muted)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background((roleColors[member.role] ?? Theme.muted).opacity(0.12))
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal, 20).padding(.vertical, 10)
                            Divider().background(Theme.sep).padding(.leading, 74)
                        }
                    }
                }

                Button {} label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus").font(.system(size: 14)).foregroundColor(accent)
                        Text("Пригласить участников").font(.system(size: 15)).foregroundColor(accent)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(accent.opacity(0.1)).cornerRadius(14)
                }
                .padding(.horizontal, 20).padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Discover Rooms
struct DiscoverRoomsView: View {
    let rooms: [Group]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toast: ToastManager
    @State private var searchText = ""
    private let accent = Theme.accentGroups

    private var filtered: [Group] {
        guard !searchText.isEmpty else { return rooms }
        return rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Публичные комнаты")
                            .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                        Text("Открытые группы по темам")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                SearchBar(text: $searchText, accentColor: accent).padding(.horizontal, 16).padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { room in
                            HStack(spacing: 12) {
                                AvatarView(initials: room.avatarInitials, size: 46, accentColor: accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(room.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                                    Text(room.lastMessage).font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
                                    HStack(spacing: 3) {
                                        Image(systemName: "person.2.fill").font(.system(size: 9)).foregroundColor(Theme.dim)
                                        Text("\(room.memberCount)").font(.system(size: 11)).foregroundColor(Theme.dim)
                                    }
                                }
                                Spacer()
                                Button { toast.show("Вступил в \(room.name)", style: .success) } label: {
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
        .presentationDetents([.large])
    }
}

// MARK: - Poll Card
struct PollCard: View {
    @Binding var poll: Poll
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill").font(.system(size: 12)).foregroundColor(accent)
                Text("Голосование").font(.system(size: 11, weight: .semibold)).foregroundColor(accent)
                Spacer()
                Text("\(poll.totalVotes) голосов").font(.system(size: 11)).foregroundColor(Theme.dim)
            }
            Text(poll.question).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
            ForEach(poll.options.indices, id: \.self) { i in
                let (option, votes) = poll.options[i]
                let pct = poll.totalVotes > 0 ? Double(votes) / Double(poll.totalVotes) : 0
                let isVoted = poll.userVote == i
                Button {
                    guard poll.userVote == nil else { return }
                    poll = Poll(id: poll.id, question: poll.question,
                                options: poll.options.enumerated().map { j, o in j == i ? (o.0, o.1+1) : o },
                                totalVotes: poll.totalVotes + 1, userVote: i)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            if isVoted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12)).foregroundColor(accent)
                            }
                            Text(option).font(.system(size: 14)).foregroundColor(Theme.text)
                            Spacer()
                            Text("\(Int(pct * 100))%").font(.system(size: 12, weight: .semibold)).foregroundColor(accent)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(Theme.sep).frame(height: 5)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isVoted ? accent : accent.opacity(0.4))
                                    .frame(width: max(5, geo.size.width * pct), height: 5)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pct)
                            }
                        }
                        .frame(height: 5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Theme.card).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.2), lineWidth: 0.5))
    }
}
