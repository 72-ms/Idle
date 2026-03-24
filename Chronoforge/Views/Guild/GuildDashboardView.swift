import SwiftUI

struct GuildDashboardView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store

    @State private var showChat = false
    @State private var showMembers = false
    @State private var showRaid = false
    @State private var showLeaderboard = false
    @State private var donateAmount: String = ""
    @State private var showDonateSheet = false
    @State private var showLeaveConfirm = false

    private var guild: Guild { guildManager.currentGuild! }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                guildHeader
                quickActions
                perksSection
                if guild.hasRaidsUnlocked {
                    raidSection
                }
                treasurySection
                leaveButton
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showChat) { GuildChatView() }
        .sheet(isPresented: $showMembers) { GuildMemberListView() }
        .sheet(isPresented: $showRaid) { GuildRaidView() }
        .sheet(isPresented: $showLeaderboard) { GuildLeaderboardView() }
        .sheet(isPresented: $showDonateSheet) { donateSheet }
        .alert("Leave Guild?", isPresented: $showLeaveConfirm) {
            Button("Leave", role: .destructive) { guildManager.leaveGuild(player: player) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will lose access to guild perks and chat history.")
        }
    }

    // MARK: - Guild Header

    private var guildHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Banner icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "shield.fill")
                        .font(.title)
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(guild.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Label("Lv. \(guild.level)", systemImage: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.yellow)

                        Text("\(guild.memberCount)/\(guild.maxMembers) members")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()
            }

            // XP progress
            if guild.level < GuildLevelConfig.maxLevel {
                VStack(spacing: 4) {
                    HStack {
                        Text("Level \(guild.level + 1)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(guild.xpProgress * 100))%")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * guild.xpProgress))
                        }
                    }
                    .frame(height: 6)
                }
            } else {
                Text("Max Level!")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 10) {
            actionButton("Chat", icon: "bubble.left.and.bubble.right.fill", color: .green) { showChat = true }
            actionButton("Members", icon: "person.3.fill", color: .blue) { showMembers = true }
            if guild.hasRaidsUnlocked {
                actionButton("Raid", icon: "flame.fill", color: .red) { showRaid = true }
            }
            actionButton("Ranks", icon: "list.number", color: .purple) { showLeaderboard = true }
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Perks

    private var perksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Perks")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))

            // Show the most impactful perks
            let perks = guild.activePerks
            let uniquePerks = deduplicatePerks(perks)
            ForEach(Array(uniquePerks.enumerated()), id: \.offset) { _, perk in
                Label(perk.displayText, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.cyan.opacity(0.8))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Keep only the highest value for each perk type.
    private func deduplicatePerks(_ perks: [GuildPerk]) -> [GuildPerk] {
        var seen: Set<String> = []
        var result: [GuildPerk] = []
        for perk in perks.reversed() {
            let key = String(describing: perk).components(separatedBy: "(").first ?? ""
            if seen.insert(key).inserted {
                result.append(perk)
            }
        }
        return result.reversed()
    }

    // MARK: - Raid Section

    private var raidSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Guild Raid")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))

            if let raid = guild.activeRaid {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(raid.bossName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(0, geo.size.width * raid.progressFraction))
                            }
                        }
                        .frame(height: 8)

                        Text("\(Int(raid.progressFraction * 100))% — \(formattedTimeRemaining(raid.timeRemaining))")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Button { showRaid = true } label: {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .padding(10)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            } else {
                Text("No active raid.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Treasury

    private var treasurySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Treasury")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Label("\(guild.treasuryShards)", systemImage: "diamond.fill")
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(.cyan)
            }

            Button {
                showDonateSheet = true
            } label: {
                Text("Donate Shards")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var donateSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("You have \(player.chronoShards) Chrono Shards")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))

                TextField("Amount", text: $donateAmount)
                    .keyboardType(.numberPad)
                    .font(.title2.weight(.bold).monospaced())
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    ForEach([50, 100, 500, 1000], id: \.self) { amount in
                        Button("\(amount)") { donateAmount = "\(amount)" }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.cyan.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Button {
                    if let amount = Int(donateAmount), amount > 0 {
                        _ = guildManager.donateShards(amount: amount, player: player)
                        showDonateSheet = false
                        donateAmount = ""
                    }
                } label: {
                    Text("Donate")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(Int(donateAmount) ?? 0 <= 0 || (Int(donateAmount) ?? 0) > player.chronoShards)

                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Donate to Treasury")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Leave

    private var leaveButton: some View {
        Button {
            showLeaveConfirm = true
        } label: {
            Text("Leave Guild")
                .font(.caption.weight(.medium))
                .foregroundStyle(.red.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private func formattedTimeRemaining(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m left" }
        return "\(m)m left"
    }
}
