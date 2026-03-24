import SwiftUI

struct GuildLeaderboardView: View {
    @Environment(GuildManager.self) private var guildManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(guildManager.guildLeaderboard) { entry in
                    leaderboardRow(entry)
                        .listRowBackground(Color.white.opacity(0.03))
                        .listRowSeparatorTint(.white.opacity(0.06))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Guild Rankings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func leaderboardRow(_ entry: GuildLeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.subheadline.weight(.bold).monospaced())
                .foregroundStyle(rankColor(entry.rank))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.guildName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("Lv. \(entry.level)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.yellow)
                }

                HStack(spacing: 8) {
                    Label("\(entry.memberCount)", systemImage: "person.2")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))

                    HStack(spacing: 3) {
                        VIPBadgeView(tier: entry.leaderVIPTier, size: .small)
                        Text(entry.leaderName)
                            .font(.system(size: 10))
                            .foregroundStyle(VIPColorResolver.color(for: entry.leaderVIPTier).opacity(0.7))
                    }
                }
            }

            Spacer()

            // Highlight if it's the player's guild
            if let currentGuild = guildManager.currentGuild, currentGuild.id == entry.id {
                Text("YOU")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.cyan.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.8)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .white.opacity(0.4)
        }
    }
}
