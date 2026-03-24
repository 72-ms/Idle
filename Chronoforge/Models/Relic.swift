import Foundation

struct RelicID: Hashable, Codable {
    let rawValue: String
}

enum RelicEffect: Codable, Equatable {
    case generatorBoost(era: Era, multiplier: Decimal)
    case allProductionBoost(multiplier: Decimal)
    case tapBoost(multiplier: Decimal)
    case offlineBoost(multiplier: Decimal)
    case prestigeBoost(multiplier: Decimal)
    case cheaperGenerators(era: Era, discount: Decimal)
    case eraUnlockDiscount(discount: Decimal)
    case synergyBoost(multiplier: Decimal)
}

struct RelicConfig {
    let id: RelicID
    let name: String
    let description: String
    let era: Era
    let rarity: RelicRarity
    let effect: RelicEffect
    let forgeCost: Decimal
    let materialCost: Int
}

enum RelicRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary

    var displayName: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .common: return "gray"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
}

struct Relic: Codable, Identifiable, Equatable {
    let id: UUID
    let configId: RelicID
    let name: String
    let rarity: RelicRarity
    let effect: RelicEffect
    let era: Era
    var isEquipped: Bool = false

    init(from config: RelicConfig) {
        self.id = UUID()
        self.configId = config.id
        self.name = config.name
        self.rarity = config.rarity
        self.effect = config.effect
        self.era = config.era
    }

    var effectDescription: String {
        switch effect {
        case .generatorBoost(let era, let mult):
            return "+\(Int(truncating: NSDecimalNumber(decimal: (mult - 1) * 100)))% \(era.displayName) production"
        case .allProductionBoost(let mult):
            return "+\(Int(truncating: NSDecimalNumber(decimal: (mult - 1) * 100)))% all production"
        case .tapBoost(let mult):
            return "+\(Int(truncating: NSDecimalNumber(decimal: (mult - 1) * 100)))% tap power"
        case .offlineBoost(let mult):
            return "+\(Int(truncating: NSDecimalNumber(decimal: (mult - 1) * 100)))% offline earnings"
        case .prestigeBoost(let mult):
            return "+\(Int(truncating: NSDecimalNumber(decimal: (mult - 1) * 100)))% prestige shards"
        case .cheaperGenerators(let era, let disc):
            return "-\(Int(truncating: NSDecimalNumber(decimal: disc * 100)))% \(era.displayName) generator cost"
        case .eraUnlockDiscount(let disc):
            return "-\(Int(truncating: NSDecimalNumber(decimal: disc * 100)))% era unlock cost"
        case .synergyBoost(let mult):
            return "+\(Int(truncating: NSDecimalNumber(decimal: (mult - 1) * 100)))% generator synergy"
        }
    }
}
