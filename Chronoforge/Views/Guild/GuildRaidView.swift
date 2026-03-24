import SwiftUI

struct GuildRaidView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @Environment(GameEngine.self) private var engine

    private var guild: Guild { guildManager.currentGuild! }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let raid = guild.activeRaid {
                        activRaidView(raid)
                    } else {
                        noRaidView
                    }

                    raidHistorySection
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Guild Raid")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Active Raid

    private func activRaidView(_ raid: GuildRaid) -> some View {
        VStack(spacing: 16) {
            // Boss header
            VStack(spacing: 8) {
                Image(systemName: "flame.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)

                Text(raid.bossName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text(raid.bossDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }

            // HP bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(0, geo.size.width * raid.progressFraction))
                    }
                }
                .frame(height: 14)

                HStack {
                    Text("\(Int(raid.progressFraction * 100))% damage dealt")
                        .font(.caption2.weight(.medium))
                    Spacer()
                    Text(formattedTime(raid.timeRemaining))
                        .font(.caption2.monospaced())
                }
                .foregroundStyle(.white.opacity(0.5))
            }

            // Attack button
            Button {
                let damage = engine.totalProductionRate * 10  // 10 seconds of production
                guildManager.contributeRaidDamage(amount: damage, player: player)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("Attack!")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Your contribution
            let myDamage = raid.contribution(for: player.profileId)
            if myDamage > 0 {
                HStack {
                    Text("Your damage:")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text(TEFormatter.format(myDamage))
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(.orange)
                }
                .padding(10)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Top contributors
            let topContributors = raid.contributions
                .sorted { $0.value > $1.value }
                .prefix(5)

            if !topContributors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Top Contributors")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))

                    ForEach(Array(topContributors.enumerated()), id: \.element.key) { idx, entry in
                        let member = guild.members.first { $0.id.uuidString == entry.key }
                        HStack {
                            Text("#\(idx + 1)")
                                .font(.caption2.weight(.bold).monospaced())
                                .foregroundStyle(.orange)
                                .frame(width: 24)

                            if let member {
                                VIPNameView(
                                    name: member.displayName,
                                    vipTier: member.vipTier,
                                    nameColorId: member.equippedNameColor,
                                    font: .caption.weight(.medium)
                                )
                            } else {
                                Text("Unknown")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            Spacer()

                            Text(TEFormatter.format(entry.value))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Rewards preview
            VStack(alignment: .leading, spacing: 6) {
                Text("Victory Rewards")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 16) {
                    rewardTag("\(raid.rewardShards)", icon: "diamond.fill", color: .cyan)
                    rewardTag("\(raid.rewardCrystals)", icon: "star.fill", color: .purple)
                    rewardTag("\(raid.rewardRelicMaterials)", icon: "hammer.fill", color: .orange)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - No Raid

    private var noRaidView: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.circle")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))

            Text("No Active Raid")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))

            if player.guildRole == .leader || player.guildRole == .officer {
                Button {
                    guildManager.startRaid()
                } label: {
                    Text("Start New Raid")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Text("Only leaders and officers can start raids.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Raid History

    private var raidHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Raids Completed: \(guild.completedRaidCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))

            Text("Total Guild Damage: \(TEFormatter.format(guild.totalRaidDamage))")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helpers

    private func rewardTag(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.caption.weight(.semibold).monospaced())
        }
        .foregroundStyle(color)
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 24 { return "\(h / 24)d \(h % 24)h" }
        return "\(h)h \(m)m"
    }
}
