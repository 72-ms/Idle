import Foundation

@Observable
class PlayerState: Codable {
    var temporalEnergy: Decimal = 0
    var totalTEEarned: Decimal = 0
    var totalLifetimeTEEarned: Decimal = 0

    var chronoShards: Int = 0
    var totalChronoShardsEarned: Int = 0
    var epochCrystals: Int = 0

    var generators: [String: GeneratorState] = [:]
    var purchasedUpgrades: Set<String> = []

    var skillTree: SkillTreeState = SkillTreeState()

    var currentEra: Era = .ancient
    var unlockedEras: Set<String> = ["ancient"]

    var totalPrestigeCount: Int = 0
    var totalEpochCount: Int = 0
    var totalTaps: Int = 0

    var tapPower: Decimal = 1
    var offlineEfficiency: Decimal = 0.5

    var lastSaveTimestamp: Date = Date()
    var lastOnlineTimestamp: Date = Date()
    var totalPlayTime: TimeInterval = 0

    // Relics
    var relics: [Relic] = []
    var relicMaterials: Int = 0
    var totalRelicsForged: Int = 0

    // Daily Rewards
    var dailyRewardState: DailyRewardState = DailyRewardState()

    // Production boost (from daily rewards)
    var activeBoostMultiplier: Decimal = 1
    var boostExpirationDate: Date?

    // Epoch Perks
    var epochPerkState: EpochPerkState = EpochPerkState()

    // Contracts
    var activeContracts: [ActiveContract] = []
    var completedContractCount: Int = 0

    // Achievements
    var achievementState: AchievementState = AchievementState()

    // Challenges (Eternal Forge)
    var challengeState: ChallengeState = ChallengeState()

    // Seasonal Events
    var seasonalEventState: SeasonalEventState = SeasonalEventState()

    // Live Events
    var liveEventState: LiveEventPlayerState = LiveEventPlayerState()

    // Guild Events
    var guildEventState: GuildEventPlayerState = GuildEventPlayerState()

    // Cosmetics
    var ownedCosmetics: Set<String> = []
    var equippedCosmetics: Set<String> = []

    // Profile
    var profileId: UUID = UUID()
    var displayName: String = "Chrono Traveler"
    var equippedTitle: String?
    var equippedProfileBorder: String?
    var equippedProfileBackground: String?
    var equippedNameColor: String?
    var equippedChatFlair: String?
    var equippedAvatarFrame: String?
    var pinnedAchievements: [String] = []

    // Guild
    var guildId: UUID?
    var guildName: String?
    var guildRole: GuildRole?
    var totalGuildDonations: Int = 0

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case temporalEnergy, totalTEEarned, totalLifetimeTEEarned
        case chronoShards, totalChronoShardsEarned, epochCrystals
        case generators, purchasedUpgrades
        case skillTree
        case currentEra, unlockedEras
        case totalPrestigeCount, totalEpochCount, totalTaps
        case tapPower, offlineEfficiency
        case lastSaveTimestamp, lastOnlineTimestamp, totalPlayTime
        case relics, relicMaterials, totalRelicsForged
        case dailyRewardState
        case activeBoostMultiplier, boostExpirationDate
        case epochPerkState
        case activeContracts, completedContractCount
        case achievementState
        case challengeState
        case seasonalEventState
        case liveEventState
        case guildEventState
        case ownedCosmetics, equippedCosmetics
        case profileId, displayName
        case equippedTitle, equippedProfileBorder, equippedProfileBackground
        case equippedNameColor, equippedChatFlair, equippedAvatarFrame
        case pinnedAchievements
        case guildId, guildName, guildRole, totalGuildDonations
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temporalEnergy = try container.decode(Decimal.self, forKey: .temporalEnergy)
        totalTEEarned = try container.decode(Decimal.self, forKey: .totalTEEarned)
        totalLifetimeTEEarned = try container.decode(Decimal.self, forKey: .totalLifetimeTEEarned)
        chronoShards = try container.decode(Int.self, forKey: .chronoShards)
        totalChronoShardsEarned = try container.decode(Int.self, forKey: .totalChronoShardsEarned)
        epochCrystals = try container.decode(Int.self, forKey: .epochCrystals)
        generators = try container.decode([String: GeneratorState].self, forKey: .generators)
        purchasedUpgrades = try container.decode(Set<String>.self, forKey: .purchasedUpgrades)
        skillTree = try container.decode(SkillTreeState.self, forKey: .skillTree)
        currentEra = try container.decode(Era.self, forKey: .currentEra)
        unlockedEras = try container.decode(Set<String>.self, forKey: .unlockedEras)
        totalPrestigeCount = try container.decode(Int.self, forKey: .totalPrestigeCount)
        totalEpochCount = try container.decode(Int.self, forKey: .totalEpochCount)
        totalTaps = try container.decode(Int.self, forKey: .totalTaps)
        tapPower = try container.decode(Decimal.self, forKey: .tapPower)
        offlineEfficiency = try container.decode(Decimal.self, forKey: .offlineEfficiency)
        lastSaveTimestamp = try container.decode(Date.self, forKey: .lastSaveTimestamp)
        lastOnlineTimestamp = try container.decode(Date.self, forKey: .lastOnlineTimestamp)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        relics = try container.decodeIfPresent([Relic].self, forKey: .relics) ?? []
        relicMaterials = try container.decodeIfPresent(Int.self, forKey: .relicMaterials) ?? 0
        totalRelicsForged = try container.decodeIfPresent(Int.self, forKey: .totalRelicsForged) ?? 0
        dailyRewardState = try container.decodeIfPresent(DailyRewardState.self, forKey: .dailyRewardState) ?? DailyRewardState()
        activeBoostMultiplier = try container.decodeIfPresent(Decimal.self, forKey: .activeBoostMultiplier) ?? 1
        boostExpirationDate = try container.decodeIfPresent(Date.self, forKey: .boostExpirationDate)
        epochPerkState = try container.decodeIfPresent(EpochPerkState.self, forKey: .epochPerkState) ?? EpochPerkState()
        activeContracts = try container.decodeIfPresent([ActiveContract].self, forKey: .activeContracts) ?? []
        completedContractCount = try container.decodeIfPresent(Int.self, forKey: .completedContractCount) ?? 0
        achievementState = try container.decodeIfPresent(AchievementState.self, forKey: .achievementState) ?? AchievementState()
        challengeState = try container.decodeIfPresent(ChallengeState.self, forKey: .challengeState) ?? ChallengeState()
        seasonalEventState = try container.decodeIfPresent(SeasonalEventState.self, forKey: .seasonalEventState) ?? SeasonalEventState()
        liveEventState = try container.decodeIfPresent(LiveEventPlayerState.self, forKey: .liveEventState) ?? LiveEventPlayerState()
        guildEventState = try container.decodeIfPresent(GuildEventPlayerState.self, forKey: .guildEventState) ?? GuildEventPlayerState()
        ownedCosmetics = try container.decodeIfPresent(Set<String>.self, forKey: .ownedCosmetics) ?? []
        equippedCosmetics = try container.decodeIfPresent(Set<String>.self, forKey: .equippedCosmetics) ?? []
        profileId = try container.decodeIfPresent(UUID.self, forKey: .profileId) ?? UUID()
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? "Chrono Traveler"
        equippedTitle = try container.decodeIfPresent(String.self, forKey: .equippedTitle)
        equippedProfileBorder = try container.decodeIfPresent(String.self, forKey: .equippedProfileBorder)
        equippedProfileBackground = try container.decodeIfPresent(String.self, forKey: .equippedProfileBackground)
        equippedNameColor = try container.decodeIfPresent(String.self, forKey: .equippedNameColor)
        equippedChatFlair = try container.decodeIfPresent(String.self, forKey: .equippedChatFlair)
        equippedAvatarFrame = try container.decodeIfPresent(String.self, forKey: .equippedAvatarFrame)
        pinnedAchievements = try container.decodeIfPresent([String].self, forKey: .pinnedAchievements) ?? []
        guildId = try container.decodeIfPresent(UUID.self, forKey: .guildId)
        guildName = try container.decodeIfPresent(String.self, forKey: .guildName)
        guildRole = try container.decodeIfPresent(GuildRole.self, forKey: .guildRole)
        totalGuildDonations = try container.decodeIfPresent(Int.self, forKey: .totalGuildDonations) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(temporalEnergy, forKey: .temporalEnergy)
        try container.encode(totalTEEarned, forKey: .totalTEEarned)
        try container.encode(totalLifetimeTEEarned, forKey: .totalLifetimeTEEarned)
        try container.encode(chronoShards, forKey: .chronoShards)
        try container.encode(totalChronoShardsEarned, forKey: .totalChronoShardsEarned)
        try container.encode(epochCrystals, forKey: .epochCrystals)
        try container.encode(generators, forKey: .generators)
        try container.encode(purchasedUpgrades, forKey: .purchasedUpgrades)
        try container.encode(skillTree, forKey: .skillTree)
        try container.encode(currentEra, forKey: .currentEra)
        try container.encode(unlockedEras, forKey: .unlockedEras)
        try container.encode(totalPrestigeCount, forKey: .totalPrestigeCount)
        try container.encode(totalEpochCount, forKey: .totalEpochCount)
        try container.encode(totalTaps, forKey: .totalTaps)
        try container.encode(tapPower, forKey: .tapPower)
        try container.encode(offlineEfficiency, forKey: .offlineEfficiency)
        try container.encode(lastSaveTimestamp, forKey: .lastSaveTimestamp)
        try container.encode(lastOnlineTimestamp, forKey: .lastOnlineTimestamp)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(relics, forKey: .relics)
        try container.encode(relicMaterials, forKey: .relicMaterials)
        try container.encode(totalRelicsForged, forKey: .totalRelicsForged)
        try container.encode(dailyRewardState, forKey: .dailyRewardState)
        try container.encode(activeBoostMultiplier, forKey: .activeBoostMultiplier)
        try container.encode(boostExpirationDate, forKey: .boostExpirationDate)
        try container.encode(epochPerkState, forKey: .epochPerkState)
        try container.encode(activeContracts, forKey: .activeContracts)
        try container.encode(completedContractCount, forKey: .completedContractCount)
        try container.encode(achievementState, forKey: .achievementState)
        try container.encode(challengeState, forKey: .challengeState)
        try container.encode(seasonalEventState, forKey: .seasonalEventState)
        try container.encode(liveEventState, forKey: .liveEventState)
        try container.encode(guildEventState, forKey: .guildEventState)
        try container.encode(ownedCosmetics, forKey: .ownedCosmetics)
        try container.encode(equippedCosmetics, forKey: .equippedCosmetics)
        try container.encode(profileId, forKey: .profileId)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(equippedTitle, forKey: .equippedTitle)
        try container.encodeIfPresent(equippedProfileBorder, forKey: .equippedProfileBorder)
        try container.encodeIfPresent(equippedProfileBackground, forKey: .equippedProfileBackground)
        try container.encodeIfPresent(equippedNameColor, forKey: .equippedNameColor)
        try container.encodeIfPresent(equippedChatFlair, forKey: .equippedChatFlair)
        try container.encodeIfPresent(equippedAvatarFrame, forKey: .equippedAvatarFrame)
        try container.encode(pinnedAchievements, forKey: .pinnedAchievements)
        try container.encodeIfPresent(guildId, forKey: .guildId)
        try container.encodeIfPresent(guildName, forKey: .guildName)
        try container.encodeIfPresent(guildRole, forKey: .guildRole)
        try container.encode(totalGuildDonations, forKey: .totalGuildDonations)
    }

    // MARK: - Helpers

    func generatorState(for id: GeneratorID) -> GeneratorState {
        generators[id.id] ?? GeneratorState(id: id)
    }

    func isEraUnlocked(_ era: Era) -> Bool {
        unlockedEras.contains(era.rawValue)
    }

    func hasUpgrade(_ upgradeId: UpgradeID) -> Bool {
        purchasedUpgrades.contains(upgradeId.rawValue)
    }

    var equippedRelics: [Relic] {
        relics.filter { $0.isEquipped }
    }

    var maxRelicSlots: Int {
        var slots = GameConfig.baseRelicSlots
        for node in GameConfig.allSkillNodes {
            let level = skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .relicSlots(let perLevel) = node.effect {
                slots += perLevel * level
            }
        }
        return slots
    }

    var hasActiveBoost: Bool {
        guard let expiration = boostExpirationDate else { return false }
        return Date() < expiration
    }

    var pendingChronoShards: Int {
        guard totalTEEarned > 0 else { return 0 }
        let value = NSDecimalNumber(decimal: totalTEEarned / 1_000_000_000_000).doubleValue
        return max(0, Int(sqrt(value)) - chronoShards)
    }
}
