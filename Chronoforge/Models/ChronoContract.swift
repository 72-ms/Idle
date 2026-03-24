import Foundation

struct ContractID: Hashable, Codable {
    let rawValue: String
}

struct ContractConfig {
    let id: ContractID
    let name: String
    let description: String
    let goal: ContractGoal
    let reward: ContractReward
    let durationHours: Int
    let maxParticipants: Int
}

enum ContractGoal: Codable {
    case collectTE(amount: Decimal)
    case performPrestiges(count: Int)
    case forgeRelics(count: Int)
    case reachEra(era: Era)
    case tapCount(count: Int)
}

enum ContractReward: Codable {
    case chronoShards(amount: Int)
    case epochCrystals(amount: Int)
    case relicMaterials(amount: Int)
    case exclusiveRelic(relicId: String)
}

struct ActiveContract: Codable, Identifiable {
    let id: UUID
    let configId: ContractID
    let name: String
    let goal: ContractGoal
    let reward: ContractReward
    let startDate: Date
    let endDate: Date
    var currentProgress: Decimal = 0
    var targetProgress: Decimal
    var isCompleted: Bool = false
    var isClaimed: Bool = false

    var timeRemaining: TimeInterval {
        max(0, endDate.timeIntervalSince(Date()))
    }

    var isExpired: Bool {
        Date() >= endDate
    }

    var progressFraction: Double {
        guard targetProgress > 0 else { return 0 }
        return min(1.0, NSDecimalNumber(decimal: currentProgress / targetProgress).doubleValue)
    }

    var goalDescription: String {
        switch goal {
        case .collectTE(let amount):
            return "Collect \(TEFormatter.format(amount)) TE"
        case .performPrestiges(let count):
            return "Perform \(count) prestiges"
        case .forgeRelics(let count):
            return "Forge \(count) relics"
        case .reachEra(let era):
            return "Reach \(era.displayName)"
        case .tapCount(let count):
            return "Tap \(count) times"
        }
    }

    var rewardDescription: String {
        switch reward {
        case .chronoShards(let amount):
            return "\(amount) Chrono Shards"
        case .epochCrystals(let amount):
            return "\(amount) Epoch Crystals"
        case .relicMaterials(let amount):
            return "\(amount) Relic Materials"
        case .exclusiveRelic:
            return "Exclusive Relic"
        }
    }
}

struct ContractSystem {
    static let weeklyContracts: [ContractConfig] = [
        ContractConfig(id: ContractID(rawValue: "weekly_te"), name: "Time Harvest", description: "Collect a massive amount of Temporal Energy", goal: .collectTE(amount: Decimal(string: "1e15")!), reward: .chronoShards(amount: 50), durationHours: 168, maxParticipants: 100),
        ContractConfig(id: ContractID(rawValue: "weekly_prestige"), name: "Timeline Rush", description: "Collapse as many timelines as possible", goal: .performPrestiges(count: 10), reward: .chronoShards(amount: 30), durationHours: 168, maxParticipants: 50),
        ContractConfig(id: ContractID(rawValue: "weekly_forge"), name: "Forge Frenzy", description: "Forge relics at an impressive rate", goal: .forgeRelics(count: 15), reward: .relicMaterials(amount: 50), durationHours: 168, maxParticipants: 50),
        ContractConfig(id: ContractID(rawValue: "weekly_taps"), name: "Tap Marathon", description: "Show your dedication with pure tapping power", goal: .tapCount(count: 10000), reward: .chronoShards(amount: 20), durationHours: 168, maxParticipants: 200),
    ]

    static func generateContract(from config: ContractConfig) -> ActiveContract {
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(config.durationHours * 3600))

        let target: Decimal
        switch config.goal {
        case .collectTE(let amount): target = amount
        case .performPrestiges(let count): target = Decimal(count)
        case .forgeRelics(let count): target = Decimal(count)
        case .reachEra: target = 1
        case .tapCount(let count): target = Decimal(count)
        }

        return ActiveContract(
            id: UUID(),
            configId: config.id,
            name: config.name,
            goal: config.goal,
            reward: config.reward,
            startDate: now,
            endDate: end,
            targetProgress: target
        )
    }
}
