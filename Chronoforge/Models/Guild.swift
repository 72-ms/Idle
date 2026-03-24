import Foundation

// MARK: - Guild Role

enum GuildRole: String, Codable, CaseIterable, Comparable {
    case member
    case officer
    case leader

    static func < (lhs: GuildRole, rhs: GuildRole) -> Bool {
        let order: [GuildRole] = [.member, .officer, .leader]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }

    var displayName: String {
        switch self {
        case .member: return "Member"
        case .officer: return "Officer"
        case .leader: return "Leader"
        }
    }

    var symbolName: String {
        switch self {
        case .member: return "person.fill"
        case .officer: return "star.fill"
        case .leader: return "crown.fill"
        }
    }
}

// MARK: - Guild Perk

enum GuildPerk: Codable, Equatable {
    case productionBonus(Double)
    case offlineBonus(Double)
    case memberSlots(Int)
    case raidUnlock
    case bannerCustomization
    case treasuryBonus(Double)
    case dailyShardsBonus(Int)
    case relicForgeDiscount(Double)

    var displayText: String {
        switch self {
        case .productionBonus(let pct): return "+\(Int(pct * 100))% guild production"
        case .offlineBonus(let pct): return "+\(Int(pct * 100))% offline earnings"
        case .memberSlots(let n): return "+\(n) member slots"
        case .raidUnlock: return "Guild raids unlocked"
        case .bannerCustomization: return "Banner customization"
        case .treasuryBonus(let pct): return "+\(Int(pct * 100))% donation value"
        case .dailyShardsBonus(let n): return "+\(n) daily shards for members"
        case .relicForgeDiscount(let pct): return "\(Int(pct * 100))% cheaper relic forging"
        }
    }
}

// MARK: - Guild Level Config

struct GuildLevelConfig {
    let level: Int
    let xpRequired: Int
    let perks: [GuildPerk]

    static let maxLevel = 20

    static let levels: [GuildLevelConfig] = {
        var configs: [GuildLevelConfig] = []
        for level in 1...maxLevel {
            var perks: [GuildPerk] = []
            // Every level: small production bonus
            perks.append(.productionBonus(Double(level) * 0.02))
            // Every 2 levels: offline bonus
            if level % 2 == 0 { perks.append(.offlineBonus(Double(level / 2) * 0.05)) }
            // Level 3, 8, 14: extra member slots
            if level == 3 { perks.append(.memberSlots(10)) }
            if level == 8 { perks.append(.memberSlots(15)) }
            if level == 14 { perks.append(.memberSlots(25)) }
            // Level 5: raids
            if level == 5 { perks.append(.raidUnlock) }
            // Level 4: banner
            if level == 4 { perks.append(.bannerCustomization) }
            // Level 7, 13: treasury bonus
            if level == 7 { perks.append(.treasuryBonus(0.10)) }
            if level == 13 { perks.append(.treasuryBonus(0.25)) }
            // Level 10, 15, 20: daily shard bonus
            if level == 10 { perks.append(.dailyShardsBonus(10)) }
            if level == 15 { perks.append(.dailyShardsBonus(25)) }
            if level == 20 { perks.append(.dailyShardsBonus(50)) }
            // Level 12: relic discount
            if level == 12 { perks.append(.relicForgeDiscount(0.15)) }
            // Level 18: bigger relic discount
            if level == 18 { perks.append(.relicForgeDiscount(0.30)) }

            let xp = 500 * level * level  // 500, 2000, 4500, 8000, ...
            configs.append(GuildLevelConfig(level: level, xpRequired: xp, perks: perks))
        }
        return configs
    }()

    static func config(for level: Int) -> GuildLevelConfig? {
        levels.first { $0.level == level }
    }
}

// MARK: - Guild Member

struct GuildMember: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var role: GuildRole
    var vipTier: VIPTier
    var equippedNameColor: String?
    var equippedChatFlair: String?
    var equippedTitle: String?
    var equippedAvatarFrame: String?
    var totalDonated: Int
    var lastActive: Date
    var weeklyContribution: Int
    var raidDamageThisWeek: Decimal

    static func fromProfile(_ profile: PlayerProfile, role: GuildRole = .member) -> GuildMember {
        GuildMember(
            id: profile.id,
            displayName: profile.displayName,
            role: role,
            vipTier: profile.vipTier,
            equippedNameColor: profile.equippedNameColor,
            equippedChatFlair: profile.equippedChatFlair,
            equippedTitle: profile.equippedTitle,
            equippedAvatarFrame: profile.equippedAvatarFrame,
            totalDonated: 0,
            lastActive: Date(),
            weeklyContribution: 0,
            raidDamageThisWeek: 0
        )
    }
}

// MARK: - Guild Chat Message

struct GuildChatMessage: Codable, Identifiable {
    let id: UUID
    let senderId: UUID
    let senderName: String
    let senderVIPTier: VIPTier
    let senderNameColor: String?
    let senderChatFlair: String?
    let senderTitle: String?
    let senderRole: GuildRole
    let content: String
    let timestamp: Date
    let isSystemMessage: Bool

    static func system(_ content: String) -> GuildChatMessage {
        GuildChatMessage(
            id: UUID(), senderId: UUID(),
            senderName: "System", senderVIPTier: .none,
            senderNameColor: nil, senderChatFlair: nil,
            senderTitle: nil, senderRole: .member,
            content: content, timestamp: Date(),
            isSystemMessage: true
        )
    }
}

// MARK: - Guild Raid

struct GuildRaid: Codable, Identifiable {
    let id: UUID
    let bossName: String
    let bossDescription: String
    let bossMaxHP: Decimal
    var currentHP: Decimal
    var contributions: [String: Decimal]  // member UUID string -> damage
    let startDate: Date
    let endDate: Date
    let rewardShards: Int
    let rewardCrystals: Int
    let rewardRelicMaterials: Int

    var isDefeated: Bool { currentHP <= 0 }
    var isExpired: Bool { Date() > endDate && !isDefeated }
    var isActive: Bool { !isDefeated && !isExpired }

    var progressFraction: Double {
        guard bossMaxHP > 0 else { return 0 }
        return NSDecimalNumber(decimal: (bossMaxHP - currentHP) / bossMaxHP).doubleValue
    }

    var timeRemaining: TimeInterval {
        max(0, endDate.timeIntervalSince(Date()))
    }

    func contribution(for memberId: UUID) -> Decimal {
        contributions[memberId.uuidString] ?? 0
    }

    mutating func dealDamage(_ amount: Decimal, from memberId: UUID) {
        guard isActive else { return }
        let existing = contributions[memberId.uuidString] ?? 0
        contributions[memberId.uuidString] = existing + amount
        currentHP = max(0, currentHP - amount)
    }

    // MARK: - Raid Configs

    static let raidConfigs: [(name: String, desc: String, hp: Decimal, hours: Int, shards: Int, crystals: Int, mats: Int)] = [
        ("Chrono Wurm", "A massive temporal serpent that devours timelines.", 1_000_000, 24, 500, 10, 100),
        ("The Paradox Engine", "A rogue machine creating deadly time loops.", 5_000_000, 48, 1500, 30, 250),
        ("Epoch Titan", "An ancient guardian of the eras, awakened in fury.", 25_000_000, 72, 5000, 80, 500),
        ("Void Sovereign", "A being from beyond time itself. Only the mightiest guilds dare face it.", 100_000_000, 96, 15000, 200, 1500),
        ("The Chronarch's Shadow", "An echo of the ultimate Chronarch. The final test.", 500_000_000, 168, 50000, 500, 5000)
    ]

    static func generate(guildLevel: Int) -> GuildRaid {
        let tier = min(guildLevel / 4, raidConfigs.count - 1)
        let config = raidConfigs[tier]
        // Scale HP with guild level
        let hpMultiplier = Decimal(1 + guildLevel) / 5
        return GuildRaid(
            id: UUID(),
            bossName: config.name,
            bossDescription: config.desc,
            bossMaxHP: config.hp * hpMultiplier,
            currentHP: config.hp * hpMultiplier,
            contributions: [:],
            startDate: Date(),
            endDate: Date().addingTimeInterval(TimeInterval(config.hours * 3600)),
            rewardShards: config.shards * max(1, guildLevel / 3),
            rewardCrystals: config.crystals * max(1, guildLevel / 5),
            rewardRelicMaterials: config.mats * max(1, guildLevel / 4)
        )
    }
}

// MARK: - Guild Banner

struct GuildBanner: Codable {
    var emblemId: String
    var primaryColor: String
    var secondaryColor: String

    static let defaultBanner = GuildBanner(
        emblemId: "emblem_default",
        primaryColor: "blue",
        secondaryColor: "gold"
    )

    static let emblemOptions = [
        "emblem_default", "emblem_sword", "emblem_shield", "emblem_crown",
        "emblem_flame", "emblem_star", "emblem_gear", "emblem_crystal",
        "emblem_dragon", "emblem_phoenix", "emblem_wolf", "emblem_serpent",
        "emblem_tower", "emblem_hourglass", "emblem_infinity", "emblem_void"
    ]

    static let colorOptions = [
        "blue", "red", "green", "gold", "purple", "silver",
        "orange", "cyan", "pink", "black", "white", "crimson"
    ]
}

// MARK: - Guild

struct Guild: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var banner: GuildBanner

    var leaderProfileId: UUID
    var members: [GuildMember]

    var level: Int
    var totalXP: Int
    var treasuryShards: Int

    var createdDate: Date

    var activeRaid: GuildRaid?
    var completedRaidCount: Int
    var totalRaidDamage: Decimal

    var chatMessages: [GuildChatMessage]

    // Computed
    var memberCount: Int { members.count }

    var maxMembers: Int {
        var slots = 20  // base
        for lvl in 1...max(1, level) {
            if let config = GuildLevelConfig.config(for: lvl) {
                for perk in config.perks {
                    if case .memberSlots(let n) = perk { slots += n }
                }
            }
        }
        return slots
    }

    var isFull: Bool { memberCount >= maxMembers }

    var xpForNextLevel: Int? {
        guard level < GuildLevelConfig.maxLevel else { return nil }
        return GuildLevelConfig.config(for: level + 1)?.xpRequired
    }

    var xpProgress: Double {
        guard let required = xpForNextLevel, required > 0 else {
            return level >= GuildLevelConfig.maxLevel ? 1.0 : 0.0
        }
        let currentLevelXP = GuildLevelConfig.config(for: level)?.xpRequired ?? 0
        let progressXP = totalXP - currentLevelXP
        let rangeXP = required - currentLevelXP
        guard rangeXP > 0 else { return 1.0 }
        return Double(progressXP) / Double(rangeXP)
    }

    /// All perks unlocked up to the current level.
    var activePerks: [GuildPerk] {
        var perks: [GuildPerk] = []
        for lvl in 1...max(1, level) {
            if let config = GuildLevelConfig.config(for: lvl) {
                perks.append(contentsOf: config.perks)
            }
        }
        return perks
    }

    var hasRaidsUnlocked: Bool {
        activePerks.contains { if case .raidUnlock = $0 { return true }; return false }
    }

    var productionBonusPercent: Double {
        activePerks.compactMap { if case .productionBonus(let v) = $0 { return v }; return nil }.last ?? 0
    }

    var offlineBonusPercent: Double {
        activePerks.compactMap { if case .offlineBonus(let v) = $0 { return v }; return nil }.last ?? 0
    }

    // MARK: - Mutating

    mutating func addXP(_ amount: Int) {
        totalXP += amount
        while level < GuildLevelConfig.maxLevel {
            guard let nextConfig = GuildLevelConfig.config(for: level + 1),
                  totalXP >= nextConfig.xpRequired else { break }
            level += 1
            chatMessages.append(.system("Guild reached Level \(level)!"))
        }
    }

    mutating func donate(shards amount: Int, from memberId: UUID) {
        treasuryShards += amount
        // 1 shard = 1 XP, modified by treasury bonus perk
        let bonusMult = activePerks.compactMap {
            if case .treasuryBonus(let v) = $0 { return v }; return nil
        }.last ?? 0
        let xpGain = Int(Double(amount) * (1.0 + bonusMult))
        addXP(xpGain)

        if let idx = members.firstIndex(where: { $0.id == memberId }) {
            members[idx].totalDonated += amount
            members[idx].weeklyContribution += amount
        }
    }
}

// MARK: - Guild Leaderboard Entry

struct GuildLeaderboardEntry: Identifiable {
    let id: UUID
    let guildName: String
    let level: Int
    let memberCount: Int
    let totalRaidDamage: Decimal
    let leaderVIPTier: VIPTier
    let leaderName: String
    let rank: Int
}
