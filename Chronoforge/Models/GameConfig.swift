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

        // Industrial Era
        GeneratorConfig(id: GeneratorID(era: .industrial, index: 0), name: "Steam Clock", description: "Pressure builds, time accelerates", era: .industrial, baseProduction: 250_000, baseCost: 1_000_000_000, costMultiplier: Decimal(string: "1.08")!),
        GeneratorConfig(id: GeneratorID(era: .industrial, index: 1), name: "Telegraph", description: "Signals pulse through temporal wires", era: .industrial, baseProduction: 1_500_000, baseCost: 10_000_000_000, costMultiplier: Decimal(string: "1.09")!),
        GeneratorConfig(id: GeneratorID(era: .industrial, index: 2), name: "Assembly Line", description: "Mass-produced moments of time", era: .industrial, baseProduction: 8_000_000, baseCost: 100_000_000_000, costMultiplier: Decimal(string: "1.10")!),
        GeneratorConfig(id: GeneratorID(era: .industrial, index: 3), name: "Dynamo", description: "Electromagnetic temporal generation", era: .industrial, baseProduction: 40_000_000, baseCost: 1_000_000_000_000, costMultiplier: Decimal(string: "1.11")!),

        // Digital Era
        GeneratorConfig(id: GeneratorID(era: .digital, index: 0), name: "Quartz Processor", description: "Crystal oscillations mark nanoseconds", era: .digital, baseProduction: 200_000_000, baseCost: Decimal(string: "1e13")!, costMultiplier: Decimal(string: "1.09")!),
        GeneratorConfig(id: GeneratorID(era: .digital, index: 1), name: "Server Farm", description: "Distributed temporal computation", era: .digital, baseProduction: 1_000_000_000, baseCost: Decimal(string: "1e15")!, costMultiplier: Decimal(string: "1.10")!),
        GeneratorConfig(id: GeneratorID(era: .digital, index: 2), name: "Quantum Clock", description: "Entangled particles synchronize time itself", era: .digital, baseProduction: 5_000_000_000, baseCost: Decimal(string: "1e17")!, costMultiplier: Decimal(string: "1.11")!),
        GeneratorConfig(id: GeneratorID(era: .digital, index: 3), name: "AI Core", description: "Artificial intelligence optimizes temporal flow", era: .digital, baseProduction: 25_000_000_000, baseCost: Decimal(string: "1e19")!, costMultiplier: Decimal(string: "1.12")!),

        // Cosmic Era
        GeneratorConfig(id: GeneratorID(era: .cosmic, index: 0), name: "Pulsar Tap", description: "Harvests the rhythm of dying stars", era: .cosmic, baseProduction: 150_000_000_000, baseCost: Decimal(string: "1e22")!, costMultiplier: Decimal(string: "1.09")!),
        GeneratorConfig(id: GeneratorID(era: .cosmic, index: 1), name: "Black Hole Engine", description: "Time dilates at the event horizon", era: .cosmic, baseProduction: Decimal(string: "1e12")!, baseCost: Decimal(string: "1e24")!, costMultiplier: Decimal(string: "1.10")!),
        GeneratorConfig(id: GeneratorID(era: .cosmic, index: 2), name: "Entropy Harvester", description: "Feeds on the heat death of universes", era: .cosmic, baseProduction: Decimal(string: "5e12")!, baseCost: Decimal(string: "1e27")!, costMultiplier: Decimal(string: "1.11")!),
        GeneratorConfig(id: GeneratorID(era: .cosmic, index: 3), name: "Chrono Reactor", description: "The ultimate forge of time itself", era: .cosmic, baseProduction: Decimal(string: "2.5e13")!, baseCost: Decimal(string: "1e30")!, costMultiplier: Decimal(string: "1.12")!),
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

        // Industrial Era upgrades
        UpgradeConfig(id: UpgradeID(rawValue: "steamclock_2x"), name: "High Pressure", description: "Steam Clocks produce 2x TE", cost: 50_000_000_000, era: .industrial, effect: .generatorMultiplier(generatorId: GeneratorID(era: .industrial, index: 0), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .industrial, index: 0), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "telegraph_2x"), name: "Copper Wiring", description: "Telegraphs produce 2x TE", cost: 500_000_000_000, era: .industrial, effect: .generatorMultiplier(generatorId: GeneratorID(era: .industrial, index: 1), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .industrial, index: 1), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "assembly_2x"), name: "Automation", description: "Assembly Lines produce 2x TE", cost: 5_000_000_000_000, era: .industrial, effect: .generatorMultiplier(generatorId: GeneratorID(era: .industrial, index: 2), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .industrial, index: 2), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "dynamo_2x"), name: "Superconductor", description: "Dynamos produce 2x TE", cost: 50_000_000_000_000, era: .industrial, effect: .generatorMultiplier(generatorId: GeneratorID(era: .industrial, index: 3), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .industrial, index: 3), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "industrial_global_2x"), name: "Revolution", description: "All Industrial generators produce 2x TE", cost: 100_000_000_000_000, era: .industrial, effect: .eraMultiplier(era: .industrial, multiplier: 2), requirement: .totalTE(minimum: 50_000_000_000_000)),
        UpgradeConfig(id: UpgradeID(rawValue: "tap_4x"), name: "Pneumatic Hammer", description: "Taps produce 4x TE", cost: 10_000_000_000, era: .industrial, effect: .tapMultiplier(multiplier: 4), requirement: .prestigeCount(minimum: 3)),
        UpgradeConfig(id: UpgradeID(rawValue: "offline_25"), name: "Night Shift", description: "+25% offline efficiency", cost: 25_000_000_000, era: .industrial, effect: .offlineEfficiency(bonus: Decimal(string: "0.25")!), requirement: .prestigeCount(minimum: 2)),

        // Digital Era upgrades
        UpgradeConfig(id: UpgradeID(rawValue: "quartz_2x"), name: "Overclocked", description: "Quartz Processors produce 2x TE", cost: Decimal(string: "5e14")!, era: .digital, effect: .generatorMultiplier(generatorId: GeneratorID(era: .digital, index: 0), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .digital, index: 0), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "server_2x"), name: "Cloud Scale", description: "Server Farms produce 2x TE", cost: Decimal(string: "5e16")!, era: .digital, effect: .generatorMultiplier(generatorId: GeneratorID(era: .digital, index: 1), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .digital, index: 1), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "quantum_2x"), name: "Superposition", description: "Quantum Clocks produce 2x TE", cost: Decimal(string: "5e18")!, era: .digital, effect: .generatorMultiplier(generatorId: GeneratorID(era: .digital, index: 2), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .digital, index: 2), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "aicore_2x"), name: "Deep Learning", description: "AI Cores produce 2x TE", cost: Decimal(string: "5e20")!, era: .digital, effect: .generatorMultiplier(generatorId: GeneratorID(era: .digital, index: 3), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .digital, index: 3), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "digital_global_2x"), name: "Singularity", description: "All Digital generators produce 2x TE", cost: Decimal(string: "1e21")!, era: .digital, effect: .eraMultiplier(era: .digital, multiplier: 2), requirement: .totalTE(minimum: Decimal(string: "5e20")!)),
        UpgradeConfig(id: UpgradeID(rawValue: "global_3x"), name: "Moore's Law", description: "All generators globally produce 3x TE", cost: Decimal(string: "1e18")!, era: .digital, effect: .globalMultiplier(multiplier: 3), requirement: .prestigeCount(minimum: 5)),

        // Cosmic Era upgrades
        UpgradeConfig(id: UpgradeID(rawValue: "pulsar_2x"), name: "Magnetar Pulse", description: "Pulsar Taps produce 2x TE", cost: Decimal(string: "5e23")!, era: .cosmic, effect: .generatorMultiplier(generatorId: GeneratorID(era: .cosmic, index: 0), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .cosmic, index: 0), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "blackhole_2x"), name: "Hawking Radiation", description: "Black Hole Engines produce 2x TE", cost: Decimal(string: "5e25")!, era: .cosmic, effect: .generatorMultiplier(generatorId: GeneratorID(era: .cosmic, index: 1), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .cosmic, index: 1), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "entropy_2x"), name: "Heat Death", description: "Entropy Harvesters produce 2x TE", cost: Decimal(string: "5e28")!, era: .cosmic, effect: .generatorMultiplier(generatorId: GeneratorID(era: .cosmic, index: 2), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .cosmic, index: 2), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "reactor_2x"), name: "Big Crunch", description: "Chrono Reactors produce 2x TE", cost: Decimal(string: "5e31")!, era: .cosmic, effect: .generatorMultiplier(generatorId: GeneratorID(era: .cosmic, index: 3), multiplier: 2), requirement: .generatorQuantity(generatorId: GeneratorID(era: .cosmic, index: 3), minimum: 10)),
        UpgradeConfig(id: UpgradeID(rawValue: "cosmic_global_2x"), name: "Cosmic Harmony", description: "All Cosmic generators produce 2x TE", cost: Decimal(string: "1e32")!, era: .cosmic, effect: .eraMultiplier(era: .cosmic, multiplier: 2), requirement: .totalTE(minimum: Decimal(string: "5e31")!)),
        UpgradeConfig(id: UpgradeID(rawValue: "tap_10x"), name: "Finger of God", description: "Taps produce 10x TE", cost: Decimal(string: "1e26")!, era: .cosmic, effect: .tapMultiplier(multiplier: 10), requirement: .prestigeCount(minimum: 10)),
    ]

    static func upgrade(for id: UpgradeID) -> UpgradeConfig? {
        allUpgrades.first { $0.id == id }
    }

    static func upgrades(for era: Era) -> [UpgradeConfig] {
        allUpgrades.filter { $0.era == era }
    }

    // MARK: - Skill Tree

    static let allSkillNodes: [SkillNodeConfig] = [
        // Acceleration branch (10 nodes)
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 0), name: "Temporal Surge", description: "+10% global production per level", maxLevel: 10, costPerLevel: 1, effect: .productionMultiplier(perLevel: Decimal(string: "0.1")!), prerequisite: nil),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 1), name: "Chrono Boost", description: "+25% global production per level", maxLevel: 5, costPerLevel: 3, effect: .productionMultiplier(perLevel: Decimal(string: "0.25")!), prerequisite: SkillNodeID(branch: .acceleration, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 2), name: "Time Warp", description: "+50% global production per level", maxLevel: 3, costPerLevel: 10, effect: .productionMultiplier(perLevel: Decimal(string: "0.5")!), prerequisite: SkillNodeID(branch: .acceleration, index: 1)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 3), name: "Rapid Decay", description: "+15% global production per level", maxLevel: 10, costPerLevel: 2, effect: .productionMultiplier(perLevel: Decimal(string: "0.15")!), prerequisite: SkillNodeID(branch: .acceleration, index: 1)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 4), name: "Temporal Cascade", description: "+30% global production per level", maxLevel: 5, costPerLevel: 5, effect: .productionMultiplier(perLevel: Decimal(string: "0.3")!), prerequisite: SkillNodeID(branch: .acceleration, index: 2)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 5), name: "Overclock", description: "+75% global production per level", maxLevel: 3, costPerLevel: 15, effect: .productionMultiplier(perLevel: Decimal(string: "0.75")!), prerequisite: SkillNodeID(branch: .acceleration, index: 4)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 6), name: "Infinite Loop", description: "+100% global production per level", maxLevel: 2, costPerLevel: 25, effect: .productionMultiplier(perLevel: Decimal(string: "1.0")!), prerequisite: SkillNodeID(branch: .acceleration, index: 5)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 7), name: "Speed Demon", description: "+20% global production per level", maxLevel: 10, costPerLevel: 3, effect: .productionMultiplier(perLevel: Decimal(string: "0.2")!), prerequisite: SkillNodeID(branch: .acceleration, index: 3)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 8), name: "Hyperdrive", description: "+40% global production per level", maxLevel: 5, costPerLevel: 8, effect: .productionMultiplier(perLevel: Decimal(string: "0.4")!), prerequisite: SkillNodeID(branch: .acceleration, index: 7)),
        SkillNodeConfig(id: SkillNodeID(branch: .acceleration, index: 9), name: "Ludicrous Speed", description: "+200% global production per level", maxLevel: 1, costPerLevel: 50, effect: .productionMultiplier(perLevel: Decimal(string: "2.0")!), prerequisite: SkillNodeID(branch: .acceleration, index: 6)),

        // Resonance branch (10 nodes)
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 0), name: "Residual Echo", description: "+10% offline efficiency per level", maxLevel: 10, costPerLevel: 1, effect: .offlineEfficiency(perLevel: Decimal(string: "0.1")!), prerequisite: nil),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 1), name: "Harmonic Flow", description: "+5% generator synergy per level", maxLevel: 5, costPerLevel: 3, effect: .generatorSynergy(perLevel: Decimal(string: "0.05")!), prerequisite: SkillNodeID(branch: .resonance, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 2), name: "Temporal Resonance", description: "+10% prestige bonus per level", maxLevel: 5, costPerLevel: 5, effect: .prestigeBonus(perLevel: Decimal(string: "0.1")!), prerequisite: SkillNodeID(branch: .resonance, index: 1)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 3), name: "Deep Sleep", description: "+15% offline efficiency per level", maxLevel: 8, costPerLevel: 2, effect: .offlineEfficiency(perLevel: Decimal(string: "0.15")!), prerequisite: SkillNodeID(branch: .resonance, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 4), name: "Dream Harvest", description: "+8% generator synergy per level", maxLevel: 5, costPerLevel: 4, effect: .generatorSynergy(perLevel: Decimal(string: "0.08")!), prerequisite: SkillNodeID(branch: .resonance, index: 1)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 5), name: "Shard Magnet", description: "+15% prestige bonus per level", maxLevel: 5, costPerLevel: 8, effect: .prestigeBonus(perLevel: Decimal(string: "0.15")!), prerequisite: SkillNodeID(branch: .resonance, index: 2)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 6), name: "Perpetual Echo", description: "+25% offline efficiency per level", maxLevel: 4, costPerLevel: 10, effect: .offlineEfficiency(perLevel: Decimal(string: "0.25")!), prerequisite: SkillNodeID(branch: .resonance, index: 3)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 7), name: "Frequency Lock", description: "+12% generator synergy per level", maxLevel: 5, costPerLevel: 6, effect: .generatorSynergy(perLevel: Decimal(string: "0.12")!), prerequisite: SkillNodeID(branch: .resonance, index: 4)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 8), name: "Shard Storm", description: "+25% prestige bonus per level", maxLevel: 3, costPerLevel: 15, effect: .prestigeBonus(perLevel: Decimal(string: "0.25")!), prerequisite: SkillNodeID(branch: .resonance, index: 5)),
        SkillNodeConfig(id: SkillNodeID(branch: .resonance, index: 9), name: "Eternal Rest", description: "+50% offline efficiency per level", maxLevel: 2, costPerLevel: 25, effect: .offlineEfficiency(perLevel: Decimal(string: "0.5")!), prerequisite: SkillNodeID(branch: .resonance, index: 6)),

        // Mastery branch (10 nodes)
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 0), name: "Forge Strength", description: "+20% tap power per level", maxLevel: 10, costPerLevel: 1, effect: .tapPower(perLevel: Decimal(string: "0.2")!), prerequisite: nil),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 1), name: "Era Affinity", description: "10% era unlock cost reduction per level", maxLevel: 5, costPerLevel: 3, effect: .eraUnlockDiscount(perLevel: Decimal(string: "0.1")!), prerequisite: SkillNodeID(branch: .mastery, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 2), name: "Relic Mastery", description: "+1 relic slot per level", maxLevel: 3, costPerLevel: 8, effect: .relicSlots(perLevel: 1), prerequisite: SkillNodeID(branch: .mastery, index: 1)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 3), name: "Heavy Blows", description: "+30% tap power per level", maxLevel: 8, costPerLevel: 2, effect: .tapPower(perLevel: Decimal(string: "0.3")!), prerequisite: SkillNodeID(branch: .mastery, index: 0)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 4), name: "Temporal Discount", description: "15% era unlock cost reduction per level", maxLevel: 5, costPerLevel: 5, effect: .eraUnlockDiscount(perLevel: Decimal(string: "0.15")!), prerequisite: SkillNodeID(branch: .mastery, index: 1)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 5), name: "Relic Affinity", description: "+1 relic slot per level", maxLevel: 2, costPerLevel: 15, effect: .relicSlots(perLevel: 1), prerequisite: SkillNodeID(branch: .mastery, index: 2)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 6), name: "Thunder Strike", description: "+50% tap power per level", maxLevel: 5, costPerLevel: 5, effect: .tapPower(perLevel: Decimal(string: "0.5")!), prerequisite: SkillNodeID(branch: .mastery, index: 3)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 7), name: "Chrono Bargain", description: "20% era unlock cost reduction per level", maxLevel: 3, costPerLevel: 10, effect: .eraUnlockDiscount(perLevel: Decimal(string: "0.2")!), prerequisite: SkillNodeID(branch: .mastery, index: 4)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 8), name: "God Hand", description: "+100% tap power per level", maxLevel: 3, costPerLevel: 15, effect: .tapPower(perLevel: Decimal(string: "1.0")!), prerequisite: SkillNodeID(branch: .mastery, index: 6)),
        SkillNodeConfig(id: SkillNodeID(branch: .mastery, index: 9), name: "Relic Grandmaster", description: "+2 relic slots per level", maxLevel: 1, costPerLevel: 30, effect: .relicSlots(perLevel: 2), prerequisite: SkillNodeID(branch: .mastery, index: 5)),
    ]

    static func skillNode(for id: SkillNodeID) -> SkillNodeConfig {
        allSkillNodes.first { $0.id == id }!
    }

    static func skillNodes(for branch: SkillBranch) -> [SkillNodeConfig] {
        allSkillNodes.filter { $0.id.branch == branch }
    }

    // MARK: - Relics

    static let baseRelicSlots = 2
    static let relicMaterialDropRate: Double = 0.01 // 1% chance per generator per tick

    static let allRelics: [RelicConfig] = [
        // Ancient relics
        RelicConfig(id: RelicID(rawValue: "hourglass_greed"), name: "Hourglass of Greed", description: "+50% Ancient Era production", era: .ancient, rarity: .common, effect: .generatorBoost(era: .ancient, multiplier: Decimal(string: "1.5")!), forgeCost: 100_000, materialCost: 5),
        RelicConfig(id: RelicID(rawValue: "sundial_fortune"), name: "Sundial of Fortune", description: "+25% all production", era: .ancient, rarity: .rare, effect: .allProductionBoost(multiplier: Decimal(string: "1.25")!), forgeCost: 500_000, materialCost: 10),
        RelicConfig(id: RelicID(rawValue: "astrolabe_wisdom"), name: "Astrolabe of Wisdom", description: "+30% tap power", era: .ancient, rarity: .common, effect: .tapBoost(multiplier: Decimal(string: "1.3")!), forgeCost: 200_000, materialCost: 7),
        RelicConfig(id: RelicID(rawValue: "ancient_crown"), name: "Crown of Ages", description: "+20% prestige shards", era: .ancient, rarity: .epic, effect: .prestigeBoost(multiplier: Decimal(string: "1.2")!), forgeCost: 1_000_000, materialCost: 15),

        // Medieval relics
        RelicConfig(id: RelicID(rawValue: "clockwork_heart"), name: "Clockwork Heart", description: "+50% Medieval production", era: .medieval, rarity: .common, effect: .generatorBoost(era: .medieval, multiplier: Decimal(string: "1.5")!), forgeCost: 50_000_000, materialCost: 8),
        RelicConfig(id: RelicID(rawValue: "pendulum_grace"), name: "Pendulum of Grace", description: "+40% offline earnings", era: .medieval, rarity: .rare, effect: .offlineBoost(multiplier: Decimal(string: "1.4")!), forgeCost: 100_000_000, materialCost: 12),
        RelicConfig(id: RelicID(rawValue: "guild_seal"), name: "Guild Seal", description: "+35% all production", era: .medieval, rarity: .epic, effect: .allProductionBoost(multiplier: Decimal(string: "1.35")!), forgeCost: 500_000_000, materialCost: 18),
        RelicConfig(id: RelicID(rawValue: "bell_resonance"), name: "Bell of Resonance", description: "+50% generator synergy", era: .medieval, rarity: .rare, effect: .synergyBoost(multiplier: Decimal(string: "1.5")!), forgeCost: 200_000_000, materialCost: 14),

        // Industrial relics
        RelicConfig(id: RelicID(rawValue: "steam_core"), name: "Steam Core", description: "+60% Industrial production", era: .industrial, rarity: .common, effect: .generatorBoost(era: .industrial, multiplier: Decimal(string: "1.6")!), forgeCost: 50_000_000_000, materialCost: 12),
        RelicConfig(id: RelicID(rawValue: "dynamo_spark"), name: "Dynamo Spark", description: "+50% all production", era: .industrial, rarity: .epic, effect: .allProductionBoost(multiplier: Decimal(string: "1.5")!), forgeCost: 500_000_000_000, materialCost: 25),
        RelicConfig(id: RelicID(rawValue: "assembly_key"), name: "Assembly Key", description: "-20% Industrial generator cost", era: .industrial, rarity: .rare, effect: .cheaperGenerators(era: .industrial, discount: Decimal(string: "0.2")!), forgeCost: 100_000_000_000, materialCost: 15),
        RelicConfig(id: RelicID(rawValue: "telegraph_signal"), name: "Telegraph Signal", description: "+60% offline earnings", era: .industrial, rarity: .rare, effect: .offlineBoost(multiplier: Decimal(string: "1.6")!), forgeCost: 200_000_000_000, materialCost: 18),

        // Digital relics
        RelicConfig(id: RelicID(rawValue: "quantum_chip"), name: "Quantum Chip", description: "+75% Digital production", era: .digital, rarity: .rare, effect: .generatorBoost(era: .digital, multiplier: Decimal(string: "1.75")!), forgeCost: Decimal(string: "5e14")!, materialCost: 18),
        RelicConfig(id: RelicID(rawValue: "ai_matrix"), name: "AI Matrix", description: "+75% all production", era: .digital, rarity: .legendary, effect: .allProductionBoost(multiplier: Decimal(string: "1.75")!), forgeCost: Decimal(string: "5e16")!, materialCost: 35),
        RelicConfig(id: RelicID(rawValue: "server_rack"), name: "Server Rack", description: "+80% offline earnings", era: .digital, rarity: .epic, effect: .offlineBoost(multiplier: Decimal(string: "1.8")!), forgeCost: Decimal(string: "1e15")!, materialCost: 22),
        RelicConfig(id: RelicID(rawValue: "data_crystal"), name: "Data Crystal", description: "+40% prestige shards", era: .digital, rarity: .epic, effect: .prestigeBoost(multiplier: Decimal(string: "1.4")!), forgeCost: Decimal(string: "2e15")!, materialCost: 28),

        // Cosmic relics
        RelicConfig(id: RelicID(rawValue: "pulsar_gem"), name: "Pulsar Gem", description: "+100% Cosmic production", era: .cosmic, rarity: .epic, effect: .generatorBoost(era: .cosmic, multiplier: 2), forgeCost: Decimal(string: "5e24")!, materialCost: 25),
        RelicConfig(id: RelicID(rawValue: "singularity_core"), name: "Singularity Core", description: "+100% all production", era: .cosmic, rarity: .legendary, effect: .allProductionBoost(multiplier: 2), forgeCost: Decimal(string: "5e27")!, materialCost: 50),
        RelicConfig(id: RelicID(rawValue: "entropy_shard"), name: "Entropy Shard", description: "+60% prestige shards", era: .cosmic, rarity: .legendary, effect: .prestigeBoost(multiplier: Decimal(string: "1.6")!), forgeCost: Decimal(string: "1e26")!, materialCost: 40),
        RelicConfig(id: RelicID(rawValue: "chrono_key"), name: "Chrono Key", description: "-30% era unlock cost", era: .cosmic, rarity: .epic, effect: .eraUnlockDiscount(discount: Decimal(string: "0.3")!), forgeCost: Decimal(string: "1e25")!, materialCost: 30),
    ]

    static func relic(for id: RelicID) -> RelicConfig? {
        allRelics.first { $0.id == id }
    }

    static func relics(for era: Era) -> [RelicConfig] {
        allRelics.filter { $0.era == era }
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
