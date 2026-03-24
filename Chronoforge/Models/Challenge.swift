import Foundation

// MARK: - Challenge Modifier Types

/// Challenge modifier types for Eternal Forge runs
enum ChallengeModifier: String, Codable, CaseIterable {
    case noTapping       // Cannot tap - passive only
    case singleEra       // Can only use one era's generators
    case speedRun        // Must prestige within time limit
    case doublePrice     // All costs are 2x
    case halfProduction  // Production rate halved
    case noRelics        // Cannot equip relics
    case noSkillTree     // Skill tree disabled
    case blindForge      // Relic effects hidden until equipped

    var displayName: String {
        switch self {
        case .noTapping: return "No Tapping"
        case .singleEra: return "Single Era"
        case .speedRun: return "Speed Run"
        case .doublePrice: return "Double Price"
        case .halfProduction: return "Half Production"
        case .noRelics: return "No Relics"
        case .noSkillTree: return "No Skill Tree"
        case .blindForge: return "Blind Forge"
        }
    }
}

// MARK: - Challenge ID

struct ChallengeID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

// MARK: - Challenge Config

/// Defines a challenge's static configuration: modifiers, rewards, and unlock criteria
struct ChallengeConfig: Codable, Hashable, Identifiable {
    let id: ChallengeID
    let name: String
    let description: String
    let modifiers: [ChallengeModifier]
    let rewardMultiplier: Decimal
    let unlockRequirement: Int
    let eraRestriction: Era?

    static func == (lhs: ChallengeConfig, rhs: ChallengeConfig) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Active Challenge

/// Tracks a challenge that is currently in progress
struct ActiveChallenge: Codable {
    let configId: ChallengeID
    let startTime: Date
    var timeLimit: TimeInterval?
    var completed: Bool

    init(configId: ChallengeID, startTime: Date, timeLimit: TimeInterval? = nil, completed: Bool = false) {
        self.configId = configId
        self.startTime = startTime
        self.timeLimit = timeLimit
        self.completed = completed
    }
}

// MARK: - Challenge State

/// Persisted state for the challenge system
struct ChallengeState: Codable {
    var completedChallenges: Set<String> = []
    var activeChallenge: ActiveChallenge? = nil
    var totalChallengesCompleted: Int = 0

    init(completedChallenges: Set<String> = [], activeChallenge: ActiveChallenge? = nil, totalChallengesCompleted: Int = 0) {
        self.completedChallenges = completedChallenges
        self.activeChallenge = activeChallenge
        self.totalChallengesCompleted = totalChallengesCompleted
    }
}

// MARK: - Challenge System

/// Static configuration and helpers for the Eternal Forge challenge system.
/// Challenges unlock after the player's first Epoch Reset and provide
/// increasingly difficult run modifiers with greater prestige rewards.
enum ChallengeSystem {

    // MARK: Challenge Definitions

    static let allChallenges: [ChallengeConfig] = [
        ChallengeConfig(
            id: ChallengeID(rawValue: "the_patient_path"),
            name: "The Patient Path",
            description: "Tapping is disabled. You must rely entirely on passive generation to forge your way through time.",
            modifiers: [.noTapping],
            rewardMultiplier: 1.5,
            unlockRequirement: 1,
            eraRestriction: nil
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "singular_focus"),
            name: "Singular Focus",
            description: "Only Ancient-era generators are available. Master the earliest tools of civilization.",
            modifiers: [.singleEra],
            rewardMultiplier: 1.75,
            unlockRequirement: 1,
            eraRestriction: .ancient
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "time_crunch"),
            name: "Time Crunch",
            description: "You have 30 minutes to reach prestige. Every second counts in this race against the clock.",
            modifiers: [.speedRun],
            rewardMultiplier: 2.0,
            unlockRequirement: 2,
            eraRestriction: nil
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "inflation"),
            name: "Inflation",
            description: "All costs are doubled. Careful resource management is the key to survival.",
            modifiers: [.doublePrice],
            rewardMultiplier: 2.0,
            unlockRequirement: 2,
            eraRestriction: nil
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "entropy"),
            name: "Entropy",
            description: "Production rates are halved across all generators. The flow of time resists your efforts.",
            modifiers: [.halfProduction],
            rewardMultiplier: 2.25,
            unlockRequirement: 3,
            eraRestriction: nil
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "bare_hands"),
            name: "Bare Hands",
            description: "Relics cannot be equipped. Prove your worth without the aid of ancient artifacts.",
            modifiers: [.noRelics],
            rewardMultiplier: 2.5,
            unlockRequirement: 3,
            eraRestriction: nil
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "raw_talent"),
            name: "Raw Talent",
            description: "The skill tree is completely disabled. Only your base generators and upgrades remain.",
            modifiers: [.noSkillTree],
            rewardMultiplier: 2.75,
            unlockRequirement: 4,
            eraRestriction: nil
        ),
        ChallengeConfig(
            id: ChallengeID(rawValue: "the_gauntlet"),
            name: "The Gauntlet",
            description: "The ultimate test. Prices are doubled, production is halved, relics are forbidden, and the skill tree is locked. Only the most dedicated forgers will prevail.",
            modifiers: [.doublePrice, .halfProduction, .noRelics, .noSkillTree],
            rewardMultiplier: 5.0,
            unlockRequirement: 5,
            eraRestriction: nil
        )
    ]

    // MARK: Lookup

    /// Returns the challenge config for a given id, if it exists.
    static func config(for id: ChallengeID) -> ChallengeConfig? {
        allChallenges.first { $0.id == id }
    }

    // MARK: Requirements Check

    /// Determines whether a challenge's unlock requirements are met.
    /// - Parameters:
    ///   - challengeId: The challenge to check.
    ///   - epochResets: The player's total number of epoch resets.
    /// - Returns: `true` if the player has enough epoch resets to attempt the challenge.
    static func requirementsMet(for challengeId: ChallengeID, epochResets: Int) -> Bool {
        guard let challenge = config(for: challengeId) else { return false }
        return epochResets >= challenge.unlockRequirement
    }

    static func requirementsMet(for config: ChallengeConfig, epochResets: Int) -> Bool {
        epochResets >= config.unlockRequirement
    }

    /// Returns all challenges the player is currently eligible to attempt.
    static func availableChallenges(epochResets: Int, completed: Set<String>) -> [ChallengeConfig] {
        allChallenges.filter { config in
            epochResets >= config.unlockRequirement
                && !completed.contains(config.id.rawValue)
        }
    }

    /// The speed-run time limit used by the "Time Crunch" challenge (30 minutes).
    static let speedRunTimeLimit: TimeInterval = 30 * 60
}
