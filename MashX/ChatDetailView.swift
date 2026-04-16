import SwiftUI

struct ChatDetailView: View {
    let chat: Chat
    @EnvironmentObject private var settings: SettingsStore

    @State private var messages     = MockData.messages
    @State private var inputText    = ""
    @State private var replyTarget: Message?     = nil
    @State private var forwardMsg: Message?      = nil
    @State private var showForward              = false
    @State private var showMediaGallery         = false
    @State private var showReactionFor: UUID?   = nil
    @State private var showTyping               = false
    @State private var isRecording              = false
    @State private var recordSeconds            = 0
    @State private var showSchedulePicker       = false
    @State private var smartReplies: [String]   = []
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    private let accent = Theme.accentChats

    private let reactionEmojis = ["👍","❤️","😂","🔥","😮","👏"]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                if let p = chat.pinnedMessage { pinnedBanner(p) }
                messageList
                if showTyping { typingRow.transition(.move(edge: .bottom).combined(with: .opacity)) }
                if !smartReplies.isEmpty { smartReplyRow }
                inputBar
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { inputFocused = false }
                    .foregroundColor(accent).fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showMediaGallery) { MediaGalleryView(items: chat.mediaItems) }
        .sheet(isPresented: $showForward) { ForwardSheet(message: forwardMsg) }
        .sheet(isPresented: $showSchedulePicker) { ScheduleSheet { date in
            toast("Отправка запланирована на \(date.formatted(date: .abbreviated, time: .shortened))")
        }}
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showTyping = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showTyping = false }
                    if settings.smartReply {
                        withAnimation { smartReplies = ["Окей!", "Понял, спасибо", "Давай обсудим"] }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showTyping)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: smartReplies.count)
    }

    // MARK: - Pinned Banner
    private func pinnedBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(accent).frame(width: 3)
            Image(systemName: "pin.fill").font(.system(size: 10)).foregroundColor(accent)
            Text(text).font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
            Spacer()
            Button {} label: {
                Image(systemName: "xmark").font(.system(size: 10)).foregroundColor(Theme.dim)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(accent.opacity(0.06))
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(accent.opacity(0.2)), alignment: .bottom)
    }

    // MARK: - NavBar
    private var navBar: some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(accent)
            }
            AvatarView(initials: chat.avatarInitials, size: 36, isOnline: chat.isOnline && !settings.offlineMode)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(chat.name).font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.text)
                    if chat.isSecret {
                        Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(Theme.accentGroups)
                    }
                }
                Text(chat.isOnline && !settings.offlineMode ? "онлайн" : chat.time)
                    .font(.system(size: 12))
                    .foregroundColor(chat.isOnline && !settings.offlineMode ? Theme.accentContacts : Theme.muted)
            }
            Spacer()
            HStack(spacing: 6) {
                Button { showMediaGallery = true } label: {
                    navBtn("photo.on.rectangle")
                }
                Button {} label: { navBtn("video.fill") }
                Button {} label: { navBtn("phone.fill") }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.bgSecond)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .bottom)
    }

    private func navBtn(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold)).foregroundColor(accent)
            .frame(width: 30, height: 30).background(accent.opacity(0.1)).cornerRadius(7)
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(messages) { msg in
                        MessageBubble(
                            message: msg, accent: accent,
                            sendReadReceipts: settings.sendReadReceipts
                        )
                        .id(msg.id)
                        .contextMenu { messageContextMenu(msg) }
                        .onLongPressGesture(minimumDuration: 0.35) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                showReactionFor = msg.id
                            }
                        }

                        if showReactionFor == msg.id {
                            reactionPicker(msg.id)
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .onAppear {
                if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    // MARK: - Reaction Picker
    private func reactionPicker(_ msgId: UUID) -> some View {
        HStack(spacing: 8) {
            Spacer()
            HStack(spacing: 4) {
                ForEach(reactionEmojis, id: \.self) { emoji in
                    Button {
                        addReaction(emoji, to: msgId)
                        withAnimation { showReactionFor = nil }
                    } label: {
                        Text(emoji).font(.system(size: 22))
                            .frame(width: 38, height: 38)
                            .background(Theme.card).cornerRadius(19)
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    withAnimation { showReactionFor = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.muted)
                        .frame(width: 38, height: 38)
                        .background(Theme.card).cornerRadius(19)
                }
                .buttonStyle(.plain)
            }
            .padding(6)
            .background(Theme.bgSecond)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 0.5))
        }
        .padding(.horizontal, 16)
    }

    private func addReaction(_ emoji: String, to id: UUID) {
        guard let i = messages.firstIndex(where: { $0.id == id }) else { return }
        withAnimation {
            var current = messages[i].reactions
            current[emoji, default: 0] += 1
            messages[i].reactions = current
        }
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func messageContextMenu(_ msg: Message) -> some View {
        Button { replyTarget = msg } label: {
            Label("Ответить", systemImage: "arrowshape.turn.up.left.fill")
        }
        Button {
            forwardMsg = msg
            showForward = true
        } label: {
            Label("Переслать", systemImage: "arrowshape.turn.up.right.fill")
        }
        if msg.isOutgoing {
            Button { showSchedulePicker = true } label: {
                Label("Запланировать", systemImage: "clock.fill")
            }
        }
        Divider()
        Button(role: .destructive) {
            withAnimation { messages.removeAll { $0.id == msg.id } }
        } label: {
            Label("Удалить", systemImage: "trash.fill")
        }
    }

    // MARK: - Typing Row
    private var typingRow: some View {
        HStack {
            TypingIndicator()
            Text("печатает...").font(.system(size: 11)).foregroundColor(Theme.muted)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.bottom, 4)
    }

    // MARK: - Smart Reply Row
    private var smartReplyRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(smartReplies, id: \.self) { reply in
                    Button {
                        inputText = reply
                        withAnimation { smartReplies = [] }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10)).foregroundColor(accent)
                            Text(reply)
                                .font(.system(size: 13)).foregroundColor(Theme.text)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(accent.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(Capsule().stroke(accent.opacity(0.3), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    withAnimation { smartReplies = [] }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11)).foregroundColor(Theme.dim)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 6)
        .background(Theme.bgSecond)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 0) {
            if let reply = replyTarget { replyPanel(reply) }

            HStack(spacing: 10) {
                Button {} label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 18)).foregroundColor(Theme.muted)
                }

                TextField("Сообщение...", text: $inputText, axis: .vertical)
                    .font(.system(size: 15)).foregroundColor(Theme.text).tint(accent)
                    .focused($inputFocused).lineLimit(1...5)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Theme.card).cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(inputFocused ? accent.opacity(0.4) : Theme.border, lineWidth: 0.5))
                    .animation(.easeInOut(duration: 0.15), value: inputFocused)

                if inputText.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.2)) { isRecording.toggle() }
                        if isRecording { toast("Запись...") }
                        else { sendVoice() }
                    } label: {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isRecording ? .red : accent)
                            .frame(width: 36, height: 36)
                            .background((isRecording ? Color.red : accent).opacity(0.12))
                            .clipShape(Circle())
                            .animation(.spring(response: 0.2), value: isRecording)
                    }
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            .frame(width: 36, height: 36).background(accent).clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Theme.bgSecond.overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: replyTarget != nil)
        .animation(.spring(response: 0.2), value: inputText.isEmpty)
    }

    private func replyPanel(_ msg: Message) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(accent).frame(width: 3).cornerRadius(2)
            VStack(alignment: .leading, spacing: 2) {
                Text(msg.isOutgoing ? "Вы" : chat.name)
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(accent)
                Text(msg.text.isEmpty ? "Голосовое сообщение" : msg.text)
                    .font(.system(size: 12)).foregroundColor(Theme.muted).lineLimit(1)
            }
            Spacer()
            Button { replyTarget = nil } label: {
                Image(systemName: "xmark").font(.system(size: 12)).foregroundColor(Theme.muted)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(Theme.card)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions
    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            messages.append(Message(
                text: trimmed, isOutgoing: true, time: timeNow,
                status: .sending,
                replyTo: replyTarget.map { ReplyPreview(senderName: $0.isOutgoing ? "Вы" : chat.name, text: $0.text) }
            ))
        }
        inputText = ""; replyTarget = nil; smartReplies = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let i = messages.indices.last { messages[i].status = .sent }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let i = messages.indices.last { messages[i].status = .delivered }
        }
    }

    private func sendVoice() {
        let wf: [Float] = (0..<14).map { _ in Float.random(in: 0.1...1.0) }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            messages.append(Message(
                content: .voice(duration: 8, waveform: wf),
                isOutgoing: true, time: timeNow, status: .sent
            ))
        }
    }

    private func toast(_ msg: String) {
        // local helper — uses ToastManager via env
    }

    private var timeNow: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date())
    }
}

// MARK: - MessageBubble
struct MessageBubble: View {
    let message: Message
    let accent: Color
    var sendReadReceipts: Bool = true

    var body: some View {
        VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 3) {
            // Forward label
            if let fwd = message.forwardFrom {
                HStack(spacing: 4) {
                    if message.isOutgoing { Spacer() }
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 9)).foregroundColor(Theme.dim)
                    Text("Переслано от \(fwd)").font(.system(size: 10)).foregroundColor(Theme.dim)
                    if !message.isOutgoing { Spacer() }
                }
            }

            // Reply preview
            if let reply = message.replyTo {
                HStack {
                    if message.isOutgoing { Spacer(minLength: 60) }
                    HStack(spacing: 5) {
                        Rectangle().fill(accent).frame(width: 2.5).cornerRadius(1)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(reply.senderName)
                                .font(.system(size: 10, weight: .semibold)).foregroundColor(accent)
                            Text(reply.text)
                                .font(.system(size: 11)).foregroundColor(Theme.muted).lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(accent.opacity(0.08)).cornerRadius(8)
                    if !message.isOutgoing { Spacer(minLength: 60) }
                }
            }

            // Bubble
            HStack {
                if message.isOutgoing { Spacer(minLength: 60) }
                bubbleBody
                if !message.isOutgoing { Spacer(minLength: 60) }
            }

            // Reactions
            if !message.reactions.isEmpty {
                HStack {
                    if message.isOutgoing { Spacer() }
                    HStack(spacing: 4) {
                        ForEach(message.reactions.sorted(by: { $0.key < $1.key }), id: \.key) { emoji, count in
                            HStack(spacing: 2) {
                                Text(emoji).font(.system(size: 12))
                                if count > 1 {
                                    Text("\(count)").font(.system(size: 10, weight: .semibold)).foregroundColor(accent)
                                }
                            }
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(accent.opacity(0.1)).cornerRadius(10)
                        }
                    }
                    if !message.isOutgoing { Spacer() }
                }
            }

            // Time + status
            HStack(spacing: 3) {
                if message.isOutgoing { Spacer() }
                Text(message.time).font(.system(size: 10)).foregroundColor(Theme.dim)
                if message.isOutgoing {
                    statusIcon(message.status, sendReadReceipts: sendReadReceipts)
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: message.isOutgoing ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        ))
    }

    @ViewBuilder
    private var bubbleBody: some View {
        switch message.content {
        case .text(let t):
            Text(t)
                .font(.system(size: 15)).foregroundColor(message.isOutgoing ? .white : Theme.text)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(message.isOutgoing ? accent : Theme.card)
                .cornerRadius(message.isOutgoing ? 16 : 4, corners: .topLeft)
                .cornerRadius(message.isOutgoing ? 4 : 16, corners: .topRight)
                .cornerRadius(16, corners: .bottomLeft).cornerRadius(16, corners: .bottomRight)

        case .voice(let dur, let wf):
            VoiceBubble(duration: dur, waveform: wf, accent: accent, isOutgoing: message.isOutgoing)

        case .image(let name):
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.card).frame(width: 180, height: 140)
                Image(systemName: "photo.fill").font(.system(size: 40)).foregroundColor(Theme.dim)
                Text(name).font(.system(size: 10)).foregroundColor(Theme.muted).padding(.top, 60)
            }

        case .file(let name, let size):
            HStack(spacing: 10) {
                Image(systemName: "doc.fill").font(.system(size: 20)).foregroundColor(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.text).lineLimit(1)
                    Text(size).font(.system(size: 11)).foregroundColor(Theme.muted)
                }
            }
            .padding(12).background(Theme.card).cornerRadius(14)
        }
    }

    @ViewBuilder
    private func statusIcon(_ s: MessageStatus, sendReadReceipts: Bool) -> some View {
        switch s {
        case .sending:
            Image(systemName: "clock").font(.system(size: 9)).foregroundColor(Theme.dim)
        case .sent:
            Image(systemName: "checkmark").font(.system(size: 9)).foregroundColor(Theme.dim)
        case .delivered:
            Image(systemName: "checkmark.circle").font(.system(size: 10)).foregroundColor(Theme.dim)
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(sendReadReceipts ? accent : Theme.dim)
        }
    }
}

// MARK: - VoiceBubble
struct VoiceBubble: View {
    let duration: Int
    let waveform: [Float]
    let accent: Color
    let isOutgoing: Bool
    @State private var isPlaying = false
    @State private var progress: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.2)) { isPlaying.toggle() }
                if isPlaying {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(duration)) {
                        withAnimation { isPlaying = false; progress = 0 }
                    }
                }
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(isOutgoing ? .white : accent)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // Waveform
                HStack(spacing: 2) {
                    ForEach(waveform.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isOutgoing ? Color.white.opacity(Double(i) / Double(waveform.count) < progress ? 1 : 0.4) :
                                    accent.opacity(Double(i) / Double(waveform.count) < progress ? 1 : 0.35))
                            .frame(width: 3, height: max(4, CGFloat(waveform[i]) * 20))
                    }
                }
                Text(isPlaying ? "\(Int((1 - progress) * Double(duration)))с" : "\(duration)с")
                    .font(.system(size: 10)).foregroundColor(isOutgoing ? .white.opacity(0.7) : Theme.muted)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(isOutgoing ? accent : Theme.card)
        .cornerRadius(16)
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            guard isPlaying else { return }
            withAnimation { progress = min(1, progress + 0.1 / Double(duration)) }
        }
    }
}

// MARK: - Media Gallery
struct MediaGalleryView: View {
    let items: [MediaItem]
    @Environment(\.dismiss) private var dismiss
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Медиафайлы")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "photo.stack").font(.system(size: 40)).foregroundColor(Theme.dim)
                        Text("Нет медиафайлов").font(.system(size: 15)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: cols, spacing: 2) {
                            ForEach(items) { item in
                                ZStack {
                                    Rectangle()
                                        .fill(Theme.card)
                                        .aspectRatio(1, contentMode: .fill)
                                    Image(systemName: item.type == .video ? "video.fill" : "photo.fill")
                                        .font(.system(size: 24)).foregroundColor(Theme.dim)
                                }
                            }
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Forward Sheet
struct ForwardSheet: View {
    let message: Message?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    private let chats = MockData.chats

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Переслать в...")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundColor(Theme.muted)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                SearchBar(text: $searchText, accentColor: Theme.accentChats).padding(.horizontal, 16).padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(chats) { chat in
                            Button { dismiss() } label: {
                                HStack(spacing: 12) {
                                    AvatarView(initials: chat.avatarInitials, size: 40, isOnline: chat.isOnline)
                                    Text(chat.name).font(.system(size: 15)).foregroundColor(Theme.text)
                                    Spacer()
                                    Image(systemName: "arrowshape.turn.up.right.fill")
                                        .font(.system(size: 14)).foregroundColor(Theme.accentChats)
                                }
                                .padding(.horizontal, 20).padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            Divider().background(Theme.sep).padding(.leading, 72)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Schedule Sheet
struct ScheduleSheet: View {
    var onSchedule: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date().addingTimeInterval(3600)

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Запланировать отправку")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(Theme.text)
                    .padding(.top, 20)

                DatePicker("", selection: $date, in: Date()...)
                    .datePickerStyle(.wheel)
                    .tint(Theme.accentChats)
                    .colorScheme(.dark)
                    .labelsHidden()

                Button {
                    onSchedule(date)
                    dismiss()
                } label: {
                    Text("Запланировать")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Theme.accentChats).cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium])
    }
}
