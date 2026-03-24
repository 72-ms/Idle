import Foundation

struct GeneratorID: Hashable, Codable, Identifiable {
    let era: Era
    let index: Int
    var id: String { "\(era.rawValue)_\(index)" }
}

struct GeneratorConfig {
    let id: GeneratorID
    let name: String
    let description: String
    let era: Era
    let baseProduction: Decimal
    let baseCost: Decimal
    let costMultiplier: Decimal
}

struct GeneratorState: Codable, Identifiable {
    let id: GeneratorID
    var quantity: Int = 0

    var totalCostForNext: Decimal {
        let config = GameConfig.generator(for: id)
        return config.baseCost * pow(config.costMultiplier, quantity)
    }

    func costForBulk(_ count: Int) -> Decimal {
        let config = GameConfig.generator(for: id)
        var total: Decimal = 0
        for i in 0..<count {
            total += config.baseCost * pow(config.costMultiplier, quantity + i)
        }
        return total
    }

    func production(upgradeMultiplier: Decimal, skillMultiplier: Decimal, relicMultiplier: Decimal) -> Decimal {
        let config = GameConfig.generator(for: id)
        let milestoneMultiplier = Self.milestoneBonus(for: quantity)
        return config.baseProduction * Decimal(quantity) * milestoneMultiplier * upgradeMultiplier * skillMultiplier * relicMultiplier
    }

    static func milestoneBonus(for quantity: Int) -> Decimal {
        var multiplier: Decimal = 1
        if quantity >= 10 { multiplier *= 2 }
        if quantity >= 25 { multiplier *= 2 }
        if quantity >= 50 { multiplier *= 3 }
        if quantity >= 100 { multiplier *= 4 }
        if quantity >= 250 { multiplier *= 5 }
        if quantity >= 500 { multiplier *= 10 }
        return multiplier
    }
}

private func pow(_ base: Decimal, _ exponent: Int) -> Decimal {
    if exponent == 0 { return 1 }
    var result: Decimal = 1
    for _ in 0..<exponent {
        result *= base
    }
    return result
}
