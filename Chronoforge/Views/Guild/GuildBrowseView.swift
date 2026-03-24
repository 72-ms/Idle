import SwiftUI

struct GuildBrowseView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(guildManager.availableGuilds) { guild in
                    guildRow(guild)
                        .listRowBackground(Color.white.opacity(0.03))
                        .listRowSeparatorTint(.white.opacity(0.06))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Browse Guilds")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func guildRow(_ guild: Guild) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "shield.fill")
                    .font(.title3)
                    .foregroundStyle(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(guild.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Lv. \(guild.level)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.yellow.opacity(0.1))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    Label("\(guild.memberCount)/\(guild.maxMembers)", systemImage: "person.2")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))

                    if guild.hasRaidsUnlocked {
                        Label("Raids", systemImage: "flame")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange.opacity(0.6))
                    }

                    // Leader VIP badge
                    if let leader = guild.members.first(where: { $0.role == .leader }), leader.vipTier != .none {
                        HStack(spacing: 2) {
                            VIPBadgeView(tier: leader.vipTier, size: .small)
                            Text(leader.displayName)
                                .font(.system(size: 9))
                                .foregroundStyle(VIPColorResolver.color(for: leader.vipTier).opacity(0.7))
                        }
                    }
                }
            }

            Spacer()

            if !guild.isFull {
                Button {
                    if guildManager.joinGuild(guild, player: player, vipTier: store.vipProgress.currentTier) {
                        dismiss()
                    }
                } label: {
                    Text("Join")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(.cyan)
                        .clipShape(Capsule())
                }
            } else {
                Text("Full")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
}
