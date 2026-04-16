import SwiftUI

struct RootView: View {
    @EnvironmentObject private var toast: ToastManager
    @State private var selectedTab: Tab = .chats

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ZStack {
                ProfileView()
                    .opacity(selectedTab == .profile  ? 1 : 0)
                    .allowsHitTesting(selectedTab == .profile)

                ContactsView()
                    .opacity(selectedTab == .contacts ? 1 : 0)
                    .allowsHitTesting(selectedTab == .contacts)

                ChatsView()
                    .opacity(selectedTab == .chats    ? 1 : 0)
                    .allowsHitTesting(selectedTab == .chats)

                GroupsView()
                    .opacity(selectedTab == .groups   ? 1 : 0)
                    .allowsHitTesting(selectedTab == .groups)

                SettingsView()
                    .opacity(selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(selectedTab == .settings)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)

            ToastOverlay()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(tab.accent.opacity(0.15))
                                    .frame(width: 44, height: 30)
                                    .matchedGeometryEffect(id: "tabBG", in: ns)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? tab.accent : Theme.dim)
                                .scaleEffect(selectedTab == tab ? 1.08 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selectedTab == tab)
                        }
                        .frame(width: 44, height: 30)

                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? tab.accent : Theme.dim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 24)
        .background(
            Theme.bgSecond
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(Theme.border), alignment: .top)
        )
    }
}
