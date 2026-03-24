import Foundation

struct PlayerProfile: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var vipTier: VIPTier

    // Equipped cosmetics
    var equippedAvatarFrame: String?
    var equippedNameColor: String?
    var equippedTitle: String?
    var equippedProfileBorder: String?
    var equippedProfileBackground: String?
    var equippedChatFlair: String?

    // Public stats
    var totalPrestigeCount: Int
    var totalEpochCount: Int
    var totalLifetimeTEEarned: Decimal
    var totalPlayTime: TimeInterval
    var currentEra: Era
    var totalRelicsForged: Int
    var totalChallengesCompleted: Int
    var totalTaps: Int

    // Achievement showcase (up to 5 pinned)
    var pinnedAchievements: [String]

    // Guild affiliation
    var guildId: UUID?
    var guildName: String?
    var guildRole: GuildRole?

    // MARK: - Build from local player

    static func fromLocal(
        player: PlayerState,
        vipTier: VIPTier
    ) -> PlayerProfile {
        PlayerProfile(
            id: player.profileId,
            displayName: player.displayName,
            vipTier: vipTier,
            equippedAvatarFrame: player.equippedAvatarFrame,
            equippedNameColor: player.equippedNameColor,
            equippedTitle: player.equippedTitle,
            equippedProfileBorder: player.equippedProfileBorder,
            equippedProfileBackground: player.equippedProfileBackground,
            equippedChatFlair: player.equippedChatFlair,
            totalPrestigeCount: player.totalPrestigeCount,
            totalEpochCount: player.totalEpochCount,
            totalLifetimeTEEarned: player.totalLifetimeTEEarned,
            totalPlayTime: player.totalPlayTime,
            currentEra: player.currentEra,
            totalRelicsForged: player.totalRelicsForged,
            totalChallengesCompleted: player.challengeState.completedChallenges.count,
            totalTaps: player.totalTaps,
            pinnedAchievements: player.pinnedAchievements,
            guildId: player.guildId,
            guildName: player.guildName,
            guildRole: player.guildRole
        )
    }

    // MARK: - Mock generation

    private static let mockNames = [
        "ChronoKnight", "TemporalVoid", "EpochSlayer", "TimeWeaver",
        "ShardHunter", "VoidWalker99", "AncientOne", "NeonChrono",
        "CosmicForger", "DigitalSage", "IronClock", "StarSmith",
        "RelicLord", "EraShifter", "FluxMaster", "QuantumTick",
        "ShadowEpoch", "CrystalTide", "ArcaneTime", "InfiniteLoop",
        "PrestigePro", "GearGrinder", "MythicForge", "EternalFlame",
        "CelestialX", "ObsidianKing", "DiamondHands", "GoldRusher"
    ]

    static func generateMock(vipTier: VIPTier? = nil) -> PlayerProfile {
        let tier = vipTier ?? randomWeightedVIPTier()
        let name = mockNames.randomElement()! + "\(Int.random(in: 1...999))"

        return PlayerProfile(
            id: UUID(),
            displayName: name,
            vipTier: tier,
            equippedAvatarFrame: tier >= .bronze ? tier.perks.compactMap {
                if case .exclusiveAvatar(let id) = $0 { return id }; return nil
            }.first : nil,
            equippedNameColor: tier >= .gold ? tier.perks.compactMap {
                if case .animatedNameColor(let id) = $0 { return id }; return nil
            }.first : nil,
            equippedTitle: tier >= .obsidian ? tier.perks.compactMap {
                if case .exclusiveTitle(let t) = $0 { return t }; return nil
            }.first : nil,
            equippedProfileBorder: tier >= .diamond ? tier.perks.compactMap {
                if case .profileBorder(let id) = $0 { return id }; return nil
            }.first : nil,
            equippedProfileBackground: tier >= .chronarch ? tier.perks.compactMap {
                if case .customProfileBackground(let id) = $0 { return id }; return nil
            }.first : nil,
            equippedChatFlair: tier >= .mythic ? tier.perks.compactMap {
                if case .chatFlair(let id) = $0 { return id }; return nil
            }.first : nil,
            totalPrestigeCount: Int.random(in: 0...500) * max(1, tier.rawValue),
            totalEpochCount: Int.random(in: 0...50) * max(1, tier.rawValue),
            totalLifetimeTEEarned: Decimal(Int.random(in: 1_000...1_000_000_000)) * Decimal(max(1, tier.rawValue)),
            totalPlayTime: TimeInterval.random(in: 3600...360000) * Double(max(1, tier.rawValue)),
            currentEra: Era.allCases.randomElement()!,
            totalRelicsForged: Int.random(in: 0...200),
            totalChallengesCompleted: Int.random(in: 0...8),
            totalTaps: Int.random(in: 1000...500_000),
            pinnedAchievements: [],
            guildId: nil,
            guildName: nil,
            guildRole: nil
        )
    }

    /// Weighted distribution: most players are low tier, very few are high tier.
    private static func randomWeightedVIPTier() -> VIPTier {
        let roll = Int.random(in: 1...1000)
        switch roll {
        case 1:           return .chronarch   // 0.1%
        case 2...5:       return .celestial   // 0.4%
        case 6...15:      return .eternal     // 1.0%
        case 16...35:     return .mythic      // 2.0%
        case 36...75:     return .obsidian    // 4.0%
        case 76...145:    return .diamond     // 7.0%
        case 146...265:   return .gold        // 12.0%
        case 266...445:   return .silver      // 18.0%
        case 446...700:   return .bronze      // 25.5%
        default:          return .none        // 30.0%
        }
    }
}
