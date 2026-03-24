import SwiftUI

struct GuildHubView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store

    @State private var showCreate = false
    @State private var showBrowse = false

    var body: some View {
        Group {
            if guildManager.currentGuild != nil {
                GuildDashboardView()
            } else {
                noGuildView
            }
        }
    }

    private var noGuildView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.2))

            VStack(spacing: 6) {
                Text("No Guild")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Join or create a guild to unlock shared perks, raids, and guild chat.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                Button {
                    showCreate = true
                } label: {
                    Label("Create Guild", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    showBrowse = true
                } label: {
                    Label("Browse Guilds", systemImage: "magnifyingglass")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .sheet(isPresented: $showCreate) {
            GuildCreateView()
        }
        .sheet(isPresented: $showBrowse) {
            GuildBrowseView()
        }
    }
}
