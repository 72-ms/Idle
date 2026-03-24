import Foundation

enum DailyRewardType: Codable {
    case temporalEnergy(amount: Decimal)
    case chronoShards(amount: Int)
    case relicMaterials(amount: Int)
    case productionBoost(multiplier: Decimal, durationMinutes: Int)
}

struct DailyRewardConfig {
    let day: Int
    let reward: DailyRewardType
    let description: String
}

struct DailyRewardState: Codable {
    var lastClaimDate: Date?
    var currentStreak: Int = 0
    var totalDaysClaimed: Int = 0

    var canClaimToday: Bool {
        guard let lastClaim = lastClaimDate else { return true }
        return !Calendar.current.isDateInToday(lastClaim)
    }

    var streakBroken: Bool {
        guard let lastClaim = lastClaimDate else { return false }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return !Calendar.current.isDate(lastClaim, inSameDayAs: yesterday) &&
               !Calendar.current.isDateInToday(lastClaim)
    }

    mutating func claim() {
        if streakBroken {
            currentStreak = 0
        }
        currentStreak += 1
        totalDaysClaimed += 1
        lastClaimDate = Date()
    }

    var todayRewardDay: Int {
        // Cycle through 7 days
        ((currentStreak) % 7) + 1
    }
}

struct DailyRewardSystem {
    static let rewards: [DailyRewardConfig] = [
        DailyRewardConfig(day: 1, reward: .temporalEnergy(amount: 1000), description: "1,000 TE"),
        DailyRewardConfig(day: 2, reward: .temporalEnergy(amount: 5000), description: "5,000 TE"),
        DailyRewardConfig(day: 3, reward: .relicMaterials(amount: 5), description: "5 Relic Materials"),
        DailyRewardConfig(day: 4, reward: .temporalEnergy(amount: 25000), description: "25,000 TE"),
        DailyRewardConfig(day: 5, reward: .chronoShards(amount: 2), description: "2 Chrono Shards"),
        DailyRewardConfig(day: 6, reward: .productionBoost(multiplier: 2, durationMinutes: 60), description: "2x Production (1 hour)"),
        DailyRewardConfig(day: 7, reward: .chronoShards(amount: 5), description: "5 Chrono Shards"),
    ]

    static func reward(for day: Int) -> DailyRewardConfig {
        let index = ((day - 1) % 7)
        return rewards[index]
    }

    static func scaledTEReward(baseAmount: Decimal, playerProductionRate: Decimal) -> Decimal {
        // Scale daily TE rewards to be meaningful based on player progression
        let productionBased = playerProductionRate * 300 // ~5 minutes of production
        return max(baseAmount, productionBased)
    }
}
