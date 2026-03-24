import Foundation

struct UpgradeID: Hashable, Codable {
    let rawValue: String
}

struct UpgradeConfig {
    let id: UpgradeID
    let name: String
    let description: String
    let cost: Decimal
    let era: Era
    let effect: UpgradeEffect
    let requirement: UpgradeRequirement?
}

enum UpgradeEffect: Codable {
    case generatorMultiplier(generatorId: GeneratorID, multiplier: Decimal)
    case eraMultiplier(era: Era, multiplier: Decimal)
    case globalMultiplier(multiplier: Decimal)
    case tapMultiplier(multiplier: Decimal)
    case offlineEfficiency(bonus: Decimal)
}

enum UpgradeRequirement {
    case generatorQuantity(generatorId: GeneratorID, minimum: Int)
    case totalTE(minimum: Decimal)
    case prestigeCount(minimum: Int)
}
