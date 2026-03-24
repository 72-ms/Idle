import Foundation

struct GameConfig {

    // MARK: - Generators

    static let allGenerators: [GeneratorConfig] = [
        // Ancient Era
        GeneratorConfig(id: GeneratorID(era: .ancient, index: 0), name: "Sundial", description: "Captures the sun's passage through time", era: .ancient, baseProduction: Decimal(string: "0.5")!, baseCost: 10, costMultiplier: Decimal(string: "1.07")!),
        GeneratorConfig(id: GeneratorID(era: .ancient, index: 1), name: "Hourglass", description: "Sand flows, energy gathers", era: .ancient, baseProduction: 3, baseCost: 100, costMultiplier: Decimal(string: "1.08")!),
        GeneratorConfig(id: GeneratorID(era: .ancient, index: 2), name: "Water Clock", description: "Drips of time become a stream", era: .ancient, baseProduction: 15, baseCost: 1_000, costMultiplier: Decimal(string: "1.09")!),
        GeneratorConfig(id: GeneratorID(era: .ancient, index: 3), name: "Astrolabe", description: "Charts the heavens, harvests eternity", era: .ancient, baseProduction: 80, baseCost: 10_000, costMultiplier: Decimal(string: "1.10")!),

        // Medieval Era
        GeneratorConfig(id: GeneratorID(era: .medieval, index: 0), name: "Bell Tower", description: "Tolls resonate through the fabric of time", era: .medieval, baseProduction: 400, baseCost: 100_000, costMultiplier: Decimal(string: "1.08")!),
        GeneratorConfig(id: GeneratorID(era: .medieval, index: 1), name: "Clockwork", description: "Gears turn, time bends", era: .medieval, baseProduction: 2_000, baseCost: 1_000_000, costMultiplier: Decimal(string: "1.09")!),
        GeneratorConfig(id: GeneratorID(era: .medieval, index: 2), name: "Pendulum", description: "Swings between moments", era: .medieval, baseProduction: 10_000, baseCost: 10_000_000, costMultiplier: Decimal(string: "1.10")!),
        GeneratorConfig(id: GeneratorID(era: .medieval, index: 3), name: "Orrery", description: "A mechanical cosmos generating temporal energy", era: .medieval, baseProduction: 50_000, baseCost: 100_000_000, costMultiplier: Decimal(string: "1.11")!),
    ]

    static func generator(for id: GeneratorID) -> GeneratorConfig {
        allGenerators.first { $0.id == id }!
    }

    static func generators(for era: Era) -> [GeneratorConfig] {
        allGenerators.filter { $0.era == era }
    }

    // MARK: - Upgrades

    static let allUpgrades: [UpgradeConfig] = [
        // Ancient Era upgrades
        UpgradeConfig(id: UpgradeID(rawValue: "sundial_2x"), name: "Sharper Shadows", description: "Sundials produce 2x TE", cost: 500, era: .ancient, effect: .generatorMultiplier(generatorId: GeneratorID(era: .ancient, index: 0), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .ancient, index: 0), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "hourglass_2x"), name: "Fine Sand", description: "Hourglasses produce 2x TE", cost: 5_000, era: .ancient, effect: .generatorMultiplier(generatorId: GeneratorID(era: .ancient, index: 1), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .ancient, index: 1), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "waterclock_2x"), name: "Purified Flow", description: "Water Clocks produce 2x TE", cost: 50_000, era: .ancient, effect: .generatorMultiplier(generatorId: GeneratorID(era: .ancient, index: 2), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .ancient, index: 2), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "astrolabe_2x"), name: "Star Alignment", description: "Astrolabes produce 2x TE", cost: 500_000, era: .ancient, effect: .generatorMultiplier(generatorId: GeneratorID(era: .ancient, index: 3), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .ancient, index: 3), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "ancient_global_2x"), name: "Ancient Wisdom", description: "All Ancient generators produce 2x TE", cost: 1_000_000, era: .ancient, effect: .eraMultiplier(era: .ancient, multiplier: 2), requirement: .totalTE(minimum: 500_000)),
        UpgradeConfig(id: UpgradeID(rawValue: "tap_2x"), name: "Focused Intent", description: "Taps produce 2x TE", cost: 2_000, era: .ancient, effect: .tapMultiplier(multiplier: 2), requirement: nil),

        // Medieval Era upgrades
        UpgradeConfig(id: UpgradeID(rawValue: "belltower_2x"), name: "Resonant Bronze", description: "Bell Towers produce 2x TE", cost: 5_000_000, era: .medieval, effect: .generatorMultiplier(generatorId: GeneratorID(era: .medieval, index: 0), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .medieval, index: 0), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "clockwork_2x"), name: "Precision Gears", description: "Clockworks produce 2x TE", cost: 50_000_000, era: .medieval, effect: .generatorMultiplier(generatorId: GeneratorID(era: .medieval, index: 1), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .medieval, index: 1), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "pendulum_2x"), name: "Weighted Swing", description: "Pendulums produce 2x TE", cost: 500_000_000, era: .medieval, effect: .generatorMultiplier(generatorId: GeneratorID(era: .medieval, index: 2), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .medieval, index: 2), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "orrery_2x"), name: "Celestial Mechanics", description: "Orreries produce 2x TE", cost: 5_000_000_000, era: .medieval, effect: .generatorMultiplier(generatorId: GeneratorID(era: .medieval, index: 3), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .medieval, index: 3), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "medieval_global_2x"), name: "Guild Mastery", description: "All Medieval generators produce 2x TE", cost: 10_000_000_000, era: .medieval, effect: .eraMultiplier(era: .medieval, multiplier: 2), requirement: .totalTE(minimum: 5_000_000_000)),
    ]

    static func upgrade(for id: UpgradeID) -> UpgradeConfig? {
        allUpgrades.first { $0.id == id }
    }

    static func upgrades(for era: Era) -> [UpgradeConfig] {
        allUpgrades.filter { $0.era == era }
    }

    // MARK: - Skill Tree

    static let allSkillNodes: [SkillNodeConfig] = [
        // Acceleration branch
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 0), name: "Temporal Surge", description: "+10% global production per level", maxLevel: 10, costPerLevel: 1, effect: .productionMultiplier(perLevel: Decimal(string: "0.1")!), prerequisite: nil),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 1), name: "Chrono Boost", description: "+25% global production per level", maxLevel: 5, costPerLevel: 3, effect: .productionMultiplier(perLevel: Decimal(string: "0.25")!), prerequisite: SkillNodeID(branch: .acceleration, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 2), name: "Time Warp", description: "+50% global production per level", maxLevel: 3, costPerLevel: 10, effect: .productionMultiplier(perLevel: Decimal(string: "0.5")!), prerequisite: SkillNodeID(branch: .acceleration, index: 1)),

        // Resonance branch
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 0), name: "Residual Echo", description: "+10% offline efficiency per level", maxLevel: 10, costPerLevel: 1, effect: .offlineEfficiency(perLevel: Decimal(string: "0.1")!), prerequisite: nil),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 1), name: "Harmonic Flow", description: "+5% generator synergy per level", maxLevel: 5, costPerLevel: 3, effect: .generatorSynergy(perLevel: Decimal(string: "0.05")!), prerequisite: SkillNodeID(branch: .resonance, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 2), name: "Temporal Resonance", description: "+10% prestige bonus per level", maxLevel: 5, costPerLevel: 5, effect: .prestigeBonus(perLevel: Decimal(string: "0.1")!), prerequisite: SkillNodeID(branch: .resonance, index: 1)),

        // Mastery branch
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 0), name: "Forge Strength", description: "+20% tap power per level", maxLevel: 10, costPerLevel: 1, effect: .tapPower(perLevel: Decimal(string: "0.2")!), prerequisite: nil),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 1), name: "Era Affinity", description: "10% era unlock cost reduction per level", maxLevel: 5, costPerLevel: 3, effect: .eraUnlockDiscount(perLevel: Decimal(string: "0.1")!), prerequisite: SkillNodeID(branch: .mastery, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 2), name: "Relic Mastery", description: "+1 relic slot per level", maxLevel: 3, costPerLevel: 8, effect: .relicSlots(perLevel: 1), prerequisite: SkillNodeID(branch: .mastery, index: 1)),
    ]

    static func skillNode(for id: SkillNodeID) -> SkillNodeConfig {
        allSkillNodes.first { $0.id == id }!
    }

    static func skillNodes(for branch: SkillBranch) -> [SkillNodeConfig] {
        allSkillNodes.filter { $0.id.branch == branch }
    }

    // MARK: - Prestige

    static func chronoShardsForPrestige(totalTE: Decimal) -> Int {
        guard totalTE > 1_000_000_000_000 else { return 0 }
        let value = NSDecimalNumber(decimal: totalTE / 1_000_000_000_000).doubleValue
        return Int(sqrt(value))
    }

    // MARK: - Offline

    static let maxOfflineSeconds: TimeInterval = 8 * 60 * 60 // 8 hours
    static let baseOfflineEfficiency: Decimal = Decimal(string: "0.5")!
}
