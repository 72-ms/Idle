import Foundation

struct EpochPerkID: Hashable, Codable {
    let rawValue: String
}

struct EpochPerkConfig {
    let id: EpochPerkID
    let name: String
    let description: String
    let cost: Int // Epoch Crystals
    let maxLevel: Int
    let effect: EpochPerkEffect
}

enum EpochPerkEffect: Codable {
    case startingTE(amount: Decimal)
    case autoTap(tapsPerSecond: Int)
    case startingGenerators(era: Era, generatorIndex: Int, quantity: Int)
    case permanentProductionMultiplier(multiplier: Decimal)
    case bonusRelicSlot(count: Int)
    case offlineCapExtension(hours: Int)
    case prestigeMultiplier(multiplier: Decimal)
    case startingMaterials(amount: Int)
}

struct EpochPerkState: Codable {
    var purchasedPerks: [String: Int] = [:] // perkId -> level

    func level(for perkId: EpochPerkID) -> Int {
        purchasedPerks[perkId.rawValue] ?? 0
    }

    mutating func purchase(perkId: EpochPerkID) -> Bool {
        let config = EpochConfig.perk(for: perkId)
        let currentLevel = level(for: perkId)
        guard currentLevel < config.maxLevel else { return false }
        purchasedPerks[perkId.rawValue] = currentLevel + 1
        return true
    }
}

struct EpochConfig {
    static let allPerks: [EpochPerkConfig] = [
        EpochPerkConfig(id: EpochPerkID(rawValue: "head_start"), name: "Head Start", description: "Start each run with 10,000 TE per level", cost: 1, maxLevel: 10, effect: .startingTE(amount: 10_000)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "auto_tap"), name: "Auto-Tap", description: "Automatically tap 1/s per level", cost: 2, maxLevel: 5, effect: .autoTap(tapsPerSecond: 1)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "sundial_start"), name: "Ancient Memory", description: "Start each run with 5 Sundials per level", cost: 1, maxLevel: 5, effect: .startingGenerators(era: .ancient, generatorIndex: 0, quantity: 5)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "eternal_forge"), name: "Eternal Production", description: "+25% permanent production per level", cost: 3, maxLevel: 5, effect: .permanentProductionMultiplier(multiplier: Decimal(string: "0.25")!)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "relic_vault"), name: "Relic Vault", description: "+1 relic slot per level", cost: 2, maxLevel: 3, effect: .bonusRelicSlot(count: 1)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "deep_sleep"), name: "Deep Sleep", description: "+2 hours offline cap per level", cost: 2, maxLevel: 4, effect: .offlineCapExtension(hours: 2)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "shard_amplifier"), name: "Shard Amplifier", description: "+20% prestige shards per level", cost: 3, maxLevel: 5, effect: .prestigeMultiplier(multiplier: Decimal(string: "0.2")!)),
        EpochPerkConfig(id: EpochPerkID(rawValue: "material_cache"), name: "Material Cache", description: "Start each run with 10 materials per level", cost: 1, maxLevel: 10, effect: .startingMaterials(amount: 10)),
    ]

    static func perk(for id: EpochPerkID) -> EpochPerkConfig {
        allPerks.first { $0.id == id }!
    }

    // Formula: EC = floor((totalLifetimeCS / 1_000_000) ^ 0.4)
    static func epochCrystalsForReset(totalLifetimeCS: Int) -> Int {
        guard totalLifetimeCS > 1_000_000 else { return 0 }
        return Int(pow(Double(totalLifetimeCS) / 1_000_000, 0.4))
    }

    static let minimumPrestigesForEpoch = 10
}
