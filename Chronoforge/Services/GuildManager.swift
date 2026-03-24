import Foundation

@Observable
final class GuildManager {

    // MARK: - State

    private(set) var currentGuild: Guild?
    private(set) var availableGuilds: [Guild] = []
    private(set) var guildLeaderboard: [GuildLeaderboardEntry] = []
    private(set) var isLoading: Bool = false

    private let guildSaveKey = "chronoforge_guild_state"
    private let browseSaveKey = "chronoforge_guild_browse"

    /// Callback for delivering guild perk rewards (daily shards, raid rewards).
    var onReward: ((GuildReward) -> Void)?

    enum GuildReward {
        case dailyShards(Int)
        case raidComplete(shards: Int, crystals: Int, relicMaterials: Int)
    }

    // MARK: - Mock Chat Activity

    private static let mockChatMessages: [String] = [
        "Just prestiged! 🔄", "Anyone close to their next epoch?",
        "Check out my new VIP frame!", "Donated another 500 shards to the treasury.",
        "This raid boss is insane!", "Need more damage on the boss!",
        "Finally hit Diamond VIP!", "What's the best generator for cosmic era?",
        "Let's push the guild to level 10!", "GG everyone, raid boss down!",
        "Love the new guild perks.", "Anyone want to coordinate on contracts?",
        "Just forged my first legendary relic.", "That production bonus is huge.",
        "Offline earnings are so much better now.", "How many shards should I donate?",
        "I think we can take on the next raid tier.", "Welcome new members!",
        "This game is so addicting lol", "Just unlocked the cosmic era!",
        "My tap power is insane with these boosts.", "Time warp is so worth it.",
        "Obsidian VIP here, AMA 💎", "Grinding for Mythic tier...",
    ]

    // MARK: - Init

    init() {
        load()
        if availableGuilds.isEmpty {
            generateBrowseGuilds()
        }
        generateLeaderboard()
    }

    // MARK: - Create Guild

    func createGuild(name: String, description: String, banner: GuildBanner, player: PlayerState, vipTier: VIPTier) -> Guild {
        let profile = PlayerProfile.fromLocal(player: player, vipTier: vipTier)
        let leader = GuildMember.fromProfile(profile, role: .leader)

        var guild = Guild(
            id: UUID(),
            name: name,
            description: description,
            banner: banner,
            leaderProfileId: player.profileId,
            members: [leader],
            level: 1,
            totalXP: 0,
            treasuryShards: 0,
            createdDate: Date(),
            activeRaid: nil,
            completedRaidCount: 0,
            totalRaidDamage: 0,
            chatMessages: [.system("\(player.displayName) founded the guild!")]
        )

        // Fill with mock members
        let mockCount = Int.random(in: 5...15)
        for _ in 0..<mockCount {
            let mockProfile = PlayerProfile.generateMock()
            var member = GuildMember.fromProfile(mockProfile)
            member.totalDonated = Int.random(in: 0...500)
            member.weeklyContribution = Int.random(in: 0...100)
            member.lastActive = Date().addingTimeInterval(-TimeInterval.random(in: 0...86400))
            guild.members.append(member)
        }

        // Add some initial chat history
        addMockChatHistory(to: &guild)

        currentGuild = guild
        player.guildId = guild.id
        player.guildName = guild.name
        player.guildRole = .leader
        save()
        return guild
    }

    // MARK: - Join Guild

    func joinGuild(_ guild: Guild, player: PlayerState, vipTier: VIPTier) -> Bool {
        guard !guild.isFull else { return false }
        guard currentGuild == nil else { return false }

        var joined = guild
        let profile = PlayerProfile.fromLocal(player: player, vipTier: vipTier)
        let member = GuildMember.fromProfile(profile)
        joined.members.append(member)
        joined.chatMessages.append(.system("\(player.displayName) joined the guild!"))

        currentGuild = joined
        player.guildId = joined.id
        player.guildName = joined.name
        player.guildRole = .member

        // Remove from browse list
        availableGuilds.removeAll { $0.id == guild.id }
        save()
        return true
    }

    // MARK: - Leave Guild

    func leaveGuild(player: PlayerState) {
        guard var guild = currentGuild else { return }

        guild.members.removeAll { $0.id == player.profileId }
        guild.chatMessages.append(.system("\(player.displayName) left the guild."))

        currentGuild = nil
        player.guildId = nil
        player.guildName = nil
        player.guildRole = nil
        save()
    }

    // MARK: - Promote / Kick

    func promoteToOfficer(memberId: UUID) {
        guard var guild = currentGuild,
              let idx = guild.members.firstIndex(where: { $0.id == memberId }),
              guild.members[idx].role == .member else { return }
        guild.members[idx].role = .officer
        guild.chatMessages.append(.system("\(guild.members[idx].displayName) was promoted to Officer!"))
        currentGuild = guild
        save()
    }

    func kickMember(memberId: UUID) {
        guard var guild = currentGuild,
              let idx = guild.members.firstIndex(where: { $0.id == memberId }),
              guild.members[idx].role != .leader else { return }
        let name = guild.members[idx].displayName
        guild.members.remove(at: idx)
        guild.chatMessages.append(.system("\(name) was removed from the guild."))
        currentGuild = guild
        save()
    }

    // MARK: - Donate

    func donateShards(amount: Int, player: PlayerState) -> Bool {
        guard var guild = currentGuild, player.chronoShards >= amount, amount > 0 else { return false }
        player.chronoShards -= amount
        player.totalGuildDonations += amount
        guild.donate(shards: amount, from: player.profileId)
        guild.chatMessages.append(
            GuildChatMessage(
                id: UUID(), senderId: player.profileId,
                senderName: player.displayName,
                senderVIPTier: .none,  // will be resolved at display time
                senderNameColor: player.equippedNameColor,
                senderChatFlair: player.equippedChatFlair,
                senderTitle: player.equippedTitle,
                senderRole: player.guildRole ?? .member,
                content: "Donated \(amount) Chrono Shards to the treasury!",
                timestamp: Date(), isSystemMessage: true
            )
        )
        currentGuild = guild
        save()
        return true
    }

    // MARK: - Chat

    func sendMessage(content: String, player: PlayerState, vipTier: VIPTier) {
        guard var guild = currentGuild, !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let message = GuildChatMessage(
            id: UUID(),
            senderId: player.profileId,
            senderName: player.displayName,
            senderVIPTier: vipTier,
            senderNameColor: player.equippedNameColor,
            senderChatFlair: player.equippedChatFlair,
            senderTitle: player.equippedTitle,
            senderRole: player.guildRole ?? .member,
            content: content,
            timestamp: Date(),
            isSystemMessage: false
        )
        guild.chatMessages.append(message)

        // Keep last 200 messages
        if guild.chatMessages.count > 200 {
            guild.chatMessages = Array(guild.chatMessages.suffix(200))
        }

        currentGuild = guild
        save()
    }

    /// Generate periodic mock chat activity from guild members.
    func generateMockChatActivity() {
        guard var guild = currentGuild else { return }
        // Only generate if the last mock message was > 30s ago
        let mockMembers = guild.members.filter { $0.id != guild.leaderProfileId }
        guard let sender = mockMembers.randomElement() else { return }
        guard let msgText = Self.mockChatMessages.randomElement() else { return }

        let message = GuildChatMessage(
            id: UUID(),
            senderId: sender.id,
            senderName: sender.displayName,
            senderVIPTier: sender.vipTier,
            senderNameColor: sender.equippedNameColor,
            senderChatFlair: sender.equippedChatFlair,
            senderTitle: sender.equippedTitle,
            senderRole: sender.role,
            content: msgText,
            timestamp: Date(),
            isSystemMessage: false
        )
        guild.chatMessages.append(message)
        if guild.chatMessages.count > 200 {
            guild.chatMessages = Array(guild.chatMessages.suffix(200))
        }
        currentGuild = guild
    }

    // MARK: - Raids

    func startRaid() {
        guard var guild = currentGuild, guild.hasRaidsUnlocked, guild.activeRaid == nil else { return }
        guild.activeRaid = GuildRaid.generate(guildLevel: guild.level)
        guild.chatMessages.append(.system("A new raid has begun: \(guild.activeRaid!.bossName)!"))
        currentGuild = guild
        save()
    }

    func contributeRaidDamage(amount: Decimal, player: PlayerState) {
        guard var guild = currentGuild, guild.activeRaid != nil else { return }
        guild.activeRaid!.dealDamage(amount, from: player.profileId)

        if let idx = guild.members.firstIndex(where: { $0.id == player.profileId }) {
            guild.members[idx].raidDamageThisWeek += amount
        }
        guild.totalRaidDamage += amount

        if guild.activeRaid!.isDefeated {
            let raid = guild.activeRaid!
            guild.completedRaidCount += 1
            guild.chatMessages.append(.system("\(raid.bossName) has been defeated! Rewards distributed!"))
            guild.activeRaid = nil
            onReward?(.raidComplete(
                shards: raid.rewardShards,
                crystals: raid.rewardCrystals,
                relicMaterials: raid.rewardRelicMaterials
            ))
        }

        currentGuild = guild
        save()
    }

    /// Called periodically to simulate mock member raid contributions.
    func tickRaid() {
        guard var guild = currentGuild,
              var raid = guild.activeRaid,
              raid.isActive else { return }

        // Each mock member contributes some damage
        let mockMembers = guild.members.filter { $0.id != guild.leaderProfileId }
        for member in mockMembers {
            if Bool.random() {  // ~50% chance each tick
                let baseDamage = Decimal(Int.random(in: 100...5000))
                let vipMult = Decimal(max(1, member.vipTier.rawValue))
                raid.dealDamage(baseDamage * vipMult, from: member.id)
            }
        }

        guild.activeRaid = raid
        if raid.isDefeated {
            guild.completedRaidCount += 1
            guild.chatMessages.append(.system("\(raid.bossName) has been defeated!"))
            guild.activeRaid = nil
            onReward?(.raidComplete(
                shards: raid.rewardShards,
                crystals: raid.rewardCrystals,
                relicMaterials: raid.rewardRelicMaterials
            ))
        }

        currentGuild = guild
    }

    // MARK: - Guild Production Bonuses

    var guildProductionMultiplier: Decimal {
        guard let guild = currentGuild else { return 1 }
        return 1 + Decimal(guild.productionBonusPercent)
    }

    var guildOfflineMultiplier: Decimal {
        guard let guild = currentGuild else { return 1 }
        return 1 + Decimal(guild.offlineBonusPercent)
    }

    // MARK: - Browse Guilds

    private func generateBrowseGuilds() {
        let guildNames = [
            "Temporal Knights", "Epoch Guardians", "Chrono Collective",
            "Void Reapers", "Shard Syndicate", "The Time Lords",
            "Relic Hunters", "Era Walkers", "Infinity Order",
            "Paradox Assembly", "Clockwork Legion", "Astral Forge",
            "Timeline Breakers", "Crystal Vanguard", "The Eternal Watch"
        ]

        availableGuilds = guildNames.prefix(12).enumerated().map { idx, name in
            let level = Int.random(in: 1...15)
            let leaderProfile = PlayerProfile.generateMock(vipTier: VIPTier.allCases.randomElement())
            let memberCount = Int.random(in: 8...45)

            var members: [GuildMember] = []
            let leader = GuildMember.fromProfile(leaderProfile, role: .leader)
            members.append(leader)
            for _ in 0..<(memberCount - 1) {
                let mp = PlayerProfile.generateMock()
                var m = GuildMember.fromProfile(mp)
                m.totalDonated = Int.random(in: 0...2000)
                m.lastActive = Date().addingTimeInterval(-TimeInterval.random(in: 0...172800))
                if Bool.random() && members.filter({ $0.role == .officer }).count < 5 {
                    m.role = .officer
                }
                members.append(m)
            }

            return Guild(
                id: UUID(),
                name: name,
                description: "A guild for dedicated Chronoforgers. Level \(level) and growing!",
                banner: GuildBanner(
                    emblemId: GuildBanner.emblemOptions.randomElement()!,
                    primaryColor: GuildBanner.colorOptions.randomElement()!,
                    secondaryColor: GuildBanner.colorOptions.randomElement()!
                ),
                leaderProfileId: leaderProfile.id,
                members: members,
                level: level,
                totalXP: GuildLevelConfig.config(for: level)?.xpRequired ?? 0,
                treasuryShards: Int.random(in: 100...50000),
                createdDate: Date().addingTimeInterval(-TimeInterval.random(in: 86400...2592000)),
                activeRaid: level >= 5 && Bool.random() ? GuildRaid.generate(guildLevel: level) : nil,
                completedRaidCount: Int.random(in: 0...50),
                totalRaidDamage: Decimal(Int.random(in: 0...100_000_000)),
                chatMessages: []
            )
        }
    }

    private func generateLeaderboard() {
        var entries: [GuildLeaderboardEntry] = []

        // Include current guild if present
        if let guild = currentGuild {
            let leader = guild.members.first { $0.role == .leader }
            entries.append(GuildLeaderboardEntry(
                id: guild.id, guildName: guild.name, level: guild.level,
                memberCount: guild.memberCount, totalRaidDamage: guild.totalRaidDamage,
                leaderVIPTier: leader?.vipTier ?? .none,
                leaderName: leader?.displayName ?? "Unknown", rank: 0
            ))
        }

        // Add mock entries
        for guild in availableGuilds {
            let leader = guild.members.first { $0.role == .leader }
            entries.append(GuildLeaderboardEntry(
                id: guild.id, guildName: guild.name, level: guild.level,
                memberCount: guild.memberCount, totalRaidDamage: guild.totalRaidDamage,
                leaderVIPTier: leader?.vipTier ?? .none,
                leaderName: leader?.displayName ?? "Unknown", rank: 0
            ))
        }

        // Sort by level desc, then raid damage
        entries.sort { ($0.level, $0.totalRaidDamage) > ($1.level, $1.totalRaidDamage) }
        guildLeaderboard = entries.enumerated().map { idx, entry in
            GuildLeaderboardEntry(
                id: entry.id, guildName: entry.guildName, level: entry.level,
                memberCount: entry.memberCount, totalRaidDamage: entry.totalRaidDamage,
                leaderVIPTier: entry.leaderVIPTier, leaderName: entry.leaderName,
                rank: idx + 1
            )
        }
    }

    // MARK: - Mock Chat History

    private func addMockChatHistory(to guild: inout Guild) {
        let mockMembers = guild.members.filter { $0.role != .leader }
        for _ in 0..<min(15, mockMembers.count * 2) {
            guard let sender = mockMembers.randomElement(),
                  let text = Self.mockChatMessages.randomElement() else { continue }
            guild.chatMessages.append(GuildChatMessage(
                id: UUID(), senderId: sender.id,
                senderName: sender.displayName,
                senderVIPTier: sender.vipTier,
                senderNameColor: sender.equippedNameColor,
                senderChatFlair: sender.equippedChatFlair,
                senderTitle: sender.equippedTitle,
                senderRole: sender.role,
                content: text,
                timestamp: Date().addingTimeInterval(-TimeInterval.random(in: 60...3600)),
                isSystemMessage: false
            ))
        }
        guild.chatMessages.sort { $0.timestamp < $1.timestamp }
    }

    // MARK: - Persistence

    func save() {
        if let guild = currentGuild, let data = try? JSONEncoder().encode(guild) {
            UserDefaults.standard.set(data, forKey: guildSaveKey)
        } else {
            UserDefaults.standard.removeObject(forKey: guildSaveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: guildSaveKey),
           let guild = try? JSONDecoder().decode(Guild.self, from: data) {
            currentGuild = guild
        }
    }
}
