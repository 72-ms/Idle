import Foundation

struct AchievementID: Hashable, Codable {
    let rawValue: String
}

struct AchievementConfig {
    let id: AchievementID
    let name: String
    let description: String
    let requirement: AchievementRequirement
    let reward: AchievementReward
    let gameKitID: String // For GameKit integration
}

enum AchievementRequirement {
    case totalTELifetime(minimum: Decimal)
    case totalTaps(minimum: Int)
    case totalPrestiges(minimum: Int)
    case totalEpochs(minimum: Int)
    case relicsForged(minimum: Int)
    case eraUnlocked(era: Era)
    case generatorQuantity(generatorId: GeneratorID, minimum: Int)
    case dailyStreak(minimum: Int)
    case playTime(hours: Int)
}

enum AchievementReward {
    case chronoShards(amount: Int)
    case relicMaterials(amount: Int)
    case title(name: String)
}

struct AchievementState: Codable {
    var unlockedAchievements: Set<String> = []

    func isUnlocked(_ id: AchievementID) -> Bool {
        unlockedAchievements.contains(id.rawValue)
    }

    mutating func unlock(_ id: AchievementID) {
        unlockedAchievements.insert(id.rawValue)
    }
}

struct AchievementSystem {
    static let allAchievements: [AchievementConfig] = [
        // Progression
        AchievementConfig(id: AchievementID(rawValue: "first_tap"), name: "First Spark", description: "Tap for the first time", requirement: .totalTaps(minimum: 1), reward: .chronoShards(amount: 0), gameKitID: "chronoforge.first_tap"),
        AchievementConfig(id: AchievementID(rawValue: "tap_1000"), name: "Dedicated Tapper", description: "Tap 1,000 times", requirement: .totalTaps(minimum: 1000), reward: .chronoShards(amount: 5), gameKitID: "chronoforge.tap_1000"),
        AchievementConfig(id: AchievementID(rawValue: "tap_100000"), name: "Tap Master", description: "Tap 100,000 times", requirement: .totalTaps(minimum: 100_000), reward: .relicMaterials(amount: 25), gameKitID: "chronoforge.tap_100000"),

        // Eras
        AchievementConfig(id: AchievementID(rawValue: "unlock_medieval"), name: "Medieval Times", description: "Unlock the Medieval Era", requirement: .eraUnlocked(era: .medieval), reward: .chronoShards(amount: 5), gameKitID: "chronoforge.medieval"),
        AchievementConfig(id: AchievementID(rawValue: "unlock_industrial"), name: "Industrial Revolution", description: "Unlock the Industrial Era", requirement: .eraUnlocked(era: .industrial), reward: .chronoShards(amount: 10), gameKitID: "chronoforge.industrial"),
        AchievementConfig(id: AchievementID(rawValue: "unlock_digital"), name: "Digital Dawn", description: "Unlock the Digital Era", requirement: .eraUnlocked(era: .digital), reward: .chronoShards(amount: 15), gameKitID: "chronoforge.digital"),
        AchievementConfig(id: AchievementID(rawValue: "unlock_cosmic"), name: "Cosmic Awakening", description: "Unlock the Cosmic Era", requirement: .eraUnlocked(era: .cosmic), reward: .chronoShards(amount: 25), gameKitID: "chronoforge.cosmic"),

        // Prestige
        AchievementConfig(id: AchievementID(rawValue: "first_prestige"), name: "Timeline Collapse", description: "Perform your first prestige", requirement: .totalPrestiges(minimum: 1), reward: .chronoShards(amount: 3), gameKitID: "chronoforge.first_prestige"),
        AchievementConfig(id: AchievementID(rawValue: "prestige_10"), name: "Time Traveler", description: "Prestige 10 times", requirement: .totalPrestiges(minimum: 10), reward: .relicMaterials(amount: 15), gameKitID: "chronoforge.prestige_10"),
        AchievementConfig(id: AchievementID(rawValue: "prestige_50"), name: "Chrono Veteran", description: "Prestige 50 times", requirement: .totalPrestiges(minimum: 50), reward: .chronoShards(amount: 50), gameKitID: "chronoforge.prestige_50"),

        // Epoch
        AchievementConfig(id: AchievementID(rawValue: "first_epoch"), name: "Epoch Breaker", description: "Perform your first Epoch Reset", requirement: .totalEpochs(minimum: 1), reward: .relicMaterials(amount: 50), gameKitID: "chronoforge.first_epoch"),

        // Relics
        AchievementConfig(id: AchievementID(rawValue: "first_relic"), name: "Apprentice Smith", description: "Forge your first relic", requirement: .relicsForged(minimum: 1), reward: .relicMaterials(amount: 5), gameKitID: "chronoforge.first_relic"),
        AchievementConfig(id: AchievementID(rawValue: "relic_10"), name: "Master Forger", description: "Forge 10 relics", requirement: .relicsForged(minimum: 10), reward: .relicMaterials(amount: 20), gameKitID: "chronoforge.relic_10"),

        // Streaks
        AchievementConfig(id: AchievementID(rawValue: "streak_7"), name: "Dedicated", description: "Maintain a 7-day login streak", requirement: .dailyStreak(minimum: 7), reward: .chronoShards(amount: 10), gameKitID: "chronoforge.streak_7"),
        AchievementConfig(id: AchievementID(rawValue: "streak_30"), name: "Committed", description: "Maintain a 30-day login streak", requirement: .dailyStreak(minimum: 30), reward: .chronoShards(amount: 50), gameKitID: "chronoforge.streak_30"),

        // Play time
        AchievementConfig(id: AchievementID(rawValue: "playtime_10h"), name: "Time Well Spent", description: "Play for 10 hours total", requirement: .playTime(hours: 10), reward: .relicMaterials(amount: 10), gameKitID: "chronoforge.playtime_10"),
    ]

    static func checkAchievements(player: PlayerState, achievements: inout AchievementState) -> [AchievementConfig] {
        var newlyUnlocked: [AchievementConfig] = []

        for config in allAchievements {
            guard !achievements.isUnlocked(config.id) else { continue }

            let met: Bool
            switch config.requirement {
            case .totalTELifetime(let min): met = player.totalLifetimeTEEarned >= min
            case .totalTaps(let min): met = player.totalTaps >= min
            case .totalPrestiges(let min): met = player.totalPrestigeCount >= min
            case .totalEpochs(let min): met = player.totalEpochCount >= min
            case .relicsForged(let min): met = player.totalRelicsForged >= min
            case .eraUnlocked(let era): met = player.isEraUnlocked(era)
            case .generatorQuantity(let gId, let min): met = player.generatorState(for: gId).quantity >= min
            case .dailyStreak(let min): met = player.dailyRewardState.currentStreak >= min
            case .playTime(let hours): met = player.totalPlayTime >= TimeInterval(hours * 3600)
            }

            if met {
                achievements.unlock(config.id)
                newlyUnlocked.append(config)
            }
        }

        return newlyUnlocked
    }
}
