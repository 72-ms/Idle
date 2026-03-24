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

    var pendingChronoShards: Int {
        guard totalTEEarned > 0 else { return 0 }
        let value = NSDecimalNumber(decimal: totalTEEarned / 1_000_000_000_000).doubleValue
        return max(0, Int(sqrt(value)) - chronoShards)
    }
}
