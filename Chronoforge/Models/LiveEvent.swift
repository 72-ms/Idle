import Foundation

// MARK: - Live Event System
// Multi-day events with daily rotating challenges, milestone rewards,
// and cumulative event rewards. Inspired by Whiteout Survival's event model.

// MARK: - Daily Challenge Types

/// The action a player must perform to earn points on a given day.
enum LiveEventChallengeType: String, Codable, CaseIterable {
    case tapFrenzy          // Earn points per tap
    case productionSurge    // Earn points per TE generated
    case generatorRush      // Earn points per generator purchased
    case relicForging       // Earn points per relic forged
    case prestigeMarathon   // Earn points per prestige
    case upgradeSpree       // Earn points per upgrade purchased
    case materialHarvest    // Earn points per relic material collected
    case shardCollection    // Earn points per chrono shard earned
    case epochPush          // Earn points per epoch reset
    case eraExplorer        // Earn points per era unlocked (big multiplier)

    var displayName: String {
        switch self {
        case .tapFrenzy: return "Tap Frenzy"
        case .productionSurge: return "Production Surge"
        case .generatorRush: return "Generator Rush"
        case .relicForging: return "Relic Forging"
        case .prestigeMarathon: return "Prestige Marathon"
        case .upgradeSpree: return "Upgrade Spree"
        case .materialHarvest: return "Material Harvest"
        case .shardCollection: return "Shard Collection"
        case .epochPush: return "Epoch Push"
        case .eraExplorer: return "Era Explorer"
        }
    }

    var description: String {
        switch self {
        case .tapFrenzy: return "Tap to earn event points! Each tap counts."
        case .productionSurge: return "Generate Temporal Energy to earn points."
        case .generatorRush: return "Purchase generators to earn points."
        case .relicForging: return "Forge relics to earn massive points."
        case .prestigeMarathon: return "Perform prestiges to earn points."
        case .upgradeSpree: return "Purchase upgrades to earn points."
        case .materialHarvest: return "Collect relic materials to earn points."
        case .shardCollection: return "Earn Chrono Shards to gain points."
        case .epochPush: return "Perform epoch resets for huge points."
        case .eraExplorer: return "Unlock new eras for massive points."
        }
    }

    var iconName: String {
        switch self {
        case .tapFrenzy: return "hand.tap.fill"
        case .productionSurge: return "bolt.fill"
        case .generatorRush: return "gearshape.2.fill"
        case .relicForging: return "diamond.fill"
        case .prestigeMarathon: return "arrow.counterclockwise.circle.fill"
        case .upgradeSpree: return "arrow.up.circle.fill"
        case .materialHarvest: return "cube.fill"
        case .shardCollection: return "sparkle"
        case .epochPush: return "arrow.triangle.2.circlepath"
        case .eraExplorer: return "globe.americas.fill"
        }
    }

    /// Base points awarded per action unit for this challenge type.
    var pointsPerAction: Int {
        switch self {
        case .tapFrenzy: return 1
        case .productionSurge: return 1  // per 1M TE
        case .generatorRush: return 10
        case .relicForging: return 500
        case .prestigeMarathon: return 1000
        case .upgradeSpree: return 50
        case .materialHarvest: return 5
        case .shardCollection: return 25
        case .epochPush: return 5000
        case .eraExplorer: return 2000
        }
    }
}

// MARK: - Daily Challenge

/// A single day's challenge within a live event.
struct LiveEventDay: Codable, Identifiable {
    let id: Int  // Day number (0-indexed)
    let challengeType: LiveEventChallengeType
    let bonusMultiplier: Decimal  // 1.0 = normal, 2.0 = double points

    /// Daily milestone thresholds and their rewards.
    let milestones: [LiveEventMilestone]
}

// MARK: - Milestone

struct LiveEventMilestone: Codable, Identifiable {
    var id: String { "\(points)" }
    let points: Int
    let reward: LiveEventReward

    var displayPoints: String {
        if points >= 1_000_000 { return String(format: "%.1fM", Double(points) / 1_000_000) }
        if points >= 1_000 { return String(format: "%.0fK", Double(points) / 1_000) }
        return "\(points)"
    }
}

// MARK: - Event Reward

enum LiveEventReward: Codable {
    case temporalEnergy(Decimal)
    case chronoShards(Int)
    case epochCrystals(Int)
    case relicMaterials(Int)
    case productionBoost(multiplier: Decimal, minutes: Int)
    case eventPoints(Int)  // Bonus event points
    case cosmetic(String)  // Exclusive cosmetic ID
    case eventToken(Int)   // Tokens for the event shop

    var displayText: String {
        switch self {
        case .temporalEnergy(let amount):
            return "\(LiveEventReward.formatDecimal(amount)) TE"
        case .chronoShards(let n): return "\(n) Chrono Shards"
        case .epochCrystals(let n): return "\(n) Epoch Crystals"
        case .relicMaterials(let n): return "\(n) Relic Materials"
        case .productionBoost(let mult, let mins):
            return "\(NSDecimalNumber(decimal: mult))x Boost (\(mins)m)"
        case .eventPoints(let n): return "+\(n) Event Points"
        case .cosmetic: return "Exclusive Cosmetic"
        case .eventToken(let n): return "\(n) Event Tokens"
        }
    }

    var iconName: String {
        switch self {
        case .temporalEnergy: return "bolt.fill"
        case .chronoShards: return "sparkle"
        case .epochCrystals: return "hexagon.fill"
        case .relicMaterials: return "diamond.fill"
        case .productionBoost: return "arrow.up.circle.fill"
        case .eventPoints: return "star.fill"
        case .cosmetic: return "paintbrush.fill"
        case .eventToken: return "ticket.fill"
        }
    }

    private static func formatDecimal(_ d: Decimal) -> String {
        let n = NSDecimalNumber(decimal: d).doubleValue
        if n >= 1_000_000_000 { return String(format: "%.1fB", n / 1_000_000_000) }
        if n >= 1_000_000 { return String(format: "%.1fM", n / 1_000_000) }
        if n >= 1_000 { return String(format: "%.0fK", n / 1_000) }
        return "\(Int(n))"
    }
}

// MARK: - Event Pack Tier

/// An event-specific bundle pack with escalating value.
struct LiveEventPack: Codable, Identifiable {
    let id: String
    let tier: Int           // 0 = free, 1+ = paid
    let name: String
    let price: String       // "$0.00" for free, "$X.99" for paid
    let rewards: [LiveEventReward]
    let isFree: Bool

    static func freePack(eventId: String) -> LiveEventPack {
        LiveEventPack(
            id: "\(eventId)_pack_free",
            tier: 0,
            name: "Starter Pack",
            price: "Free",
            rewards: [
                .eventPoints(500),
                .chronoShards(25),
                .relicMaterials(10)
            ],
            isFree: true
        )
    }

    static func paidPacks(eventId: String) -> [LiveEventPack] {
        [
            LiveEventPack(
                id: "\(eventId)_pack_1",
                tier: 1, name: "Bronze Event Pack",
                price: "$0.99",
                rewards: [
                    .eventPoints(2000),
                    .chronoShards(100),
                    .relicMaterials(25),
                    .productionBoost(multiplier: 2, minutes: 60)
                ],
                isFree: false
            ),
            LiveEventPack(
                id: "\(eventId)_pack_2",
                tier: 2, name: "Silver Event Pack",
                price: "$4.99",
                rewards: [
                    .eventPoints(8000),
                    .chronoShards(500),
                    .epochCrystals(15),
                    .relicMaterials(75),
                    .productionBoost(multiplier: 5, minutes: 60)
                ],
                isFree: false
            ),
            LiveEventPack(
                id: "\(eventId)_pack_3",
                tier: 3, name: "Gold Event Pack",
                price: "$19.99",
                rewards: [
                    .eventPoints(30000),
                    .chronoShards(2500),
                    .epochCrystals(50),
                    .relicMaterials(200),
                    .productionBoost(multiplier: 10, minutes: 120),
                    .eventToken(10)
                ],
                isFree: false
            ),
            LiveEventPack(
                id: "\(eventId)_pack_4",
                tier: 4, name: "Diamond Event Pack",
                price: "$49.99",
                rewards: [
                    .eventPoints(100000),
                    .chronoShards(10000),
                    .epochCrystals(150),
                    .relicMaterials(500),
                    .productionBoost(multiplier: 10, minutes: 240),
                    .eventToken(50),
                    .cosmetic("event_exclusive_pack_aura")
                ],
                isFree: false
            )
        ]
    }
}

// MARK: - Cumulative Event Milestones

/// Total-event milestones that reward based on cumulative points across all days.
struct LiveEventTotalMilestone: Codable, Identifiable {
    var id: String { "\(totalPoints)" }
    let totalPoints: Int
    let reward: LiveEventReward
    let isExclusive: Bool  // If true, reward is exclusive to this event

    var displayPoints: String {
        if totalPoints >= 1_000_000 { return String(format: "%.1fM", Double(totalPoints) / 1_000_000) }
        if totalPoints >= 1_000 { return String(format: "%.0fK", Double(totalPoints) / 1_000) }
        return "\(totalPoints)"
    }
}

// MARK: - Live Event Config

/// A fully configured multi-day event.
struct LiveEventConfig: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let theme: LiveEventTheme
    let startDate: Date
    let endDate: Date
    let days: [LiveEventDay]
    let totalMilestones: [LiveEventTotalMilestone]
    let packs: [LiveEventPack]

    var duration: Int { days.count }
    var isActive: Bool { Date() >= startDate && Date() <= endDate }
    var hasEnded: Bool { Date() > endDate }

    /// Which day index is currently active (0-based), or nil if event hasn't started/ended.
    var currentDayIndex: Int? {
        guard isActive else { return nil }
        let elapsed = Date().timeIntervalSince(startDate)
        let dayIndex = Int(elapsed / 86400)
        return min(dayIndex, days.count - 1)
    }

    var timeRemaining: TimeInterval {
        max(0, endDate.timeIntervalSince(Date()))
    }

    var currentDay: LiveEventDay? {
        guard let idx = currentDayIndex else { return nil }
        return days[idx]
    }
}

// MARK: - Event Theme

enum LiveEventTheme: String, Codable, CaseIterable {
    case chronoSurge     // Blue/cyan, production focused
    case forgeInferno    // Red/orange, forging focused
    case temporalStorm   // Purple, prestige/epoch focused
    case harvestMoon     // Gold/amber, collection focused
    case voidRift        // Dark purple, challenge focused
    case cosmicDawn      // Rainbow, mixed challenge

    var displayName: String {
        switch self {
        case .chronoSurge: return "Chrono Surge"
        case .forgeInferno: return "Forge Inferno"
        case .temporalStorm: return "Temporal Storm"
        case .harvestMoon: return "Harvest Moon"
        case .voidRift: return "Void Rift"
        case .cosmicDawn: return "Cosmic Dawn"
        }
    }

    var iconName: String {
        switch self {
        case .chronoSurge: return "bolt.horizontal.circle.fill"
        case .forgeInferno: return "flame.fill"
        case .temporalStorm: return "tornado"
        case .harvestMoon: return "moon.fill"
        case .voidRift: return "waveform.path.ecg"
        case .cosmicDawn: return "sunrise.fill"
        }
    }

    /// Typical daily challenge lineup for this theme.
    var dailyChallenges: [LiveEventChallengeType] {
        switch self {
        case .chronoSurge:
            return [.productionSurge, .generatorRush, .tapFrenzy, .upgradeSpree, .shardCollection, .productionSurge, .generatorRush]
        case .forgeInferno:
            return [.relicForging, .materialHarvest, .tapFrenzy, .relicForging, .generatorRush, .materialHarvest, .relicForging]
        case .temporalStorm:
            return [.prestigeMarathon, .shardCollection, .productionSurge, .prestigeMarathon, .tapFrenzy, .shardCollection, .epochPush]
        case .harvestMoon:
            return [.materialHarvest, .productionSurge, .generatorRush, .materialHarvest, .upgradeSpree, .tapFrenzy, .shardCollection]
        case .voidRift:
            return [.epochPush, .prestigeMarathon, .relicForging, .tapFrenzy, .eraExplorer, .shardCollection, .prestigeMarathon]
        case .cosmicDawn:
            return [.tapFrenzy, .productionSurge, .relicForging, .prestigeMarathon, .generatorRush, .materialHarvest, .epochPush]
        }
    }
}

// MARK: - Player Event State (persisted)

struct LiveEventPlayerState: Codable {
    var activeEventId: String?
    var totalPoints: Int = 0
    var dailyPoints: [Int: Int] = [:]  // day index -> points earned that day
    var claimedDailyMilestones: [Int: Set<String>] = [:]  // day index -> set of milestone IDs
    var claimedTotalMilestones: Set<String> = []
    var claimedPacks: Set<String> = []
    var eventTokens: Int = 0

    /// Snapshot of tracked stats at the start of each day, for delta calculation.
    var dayStartSnapshots: [Int: DayStartSnapshot] = [:]

    mutating func reset(for eventId: String) {
        activeEventId = eventId
        totalPoints = 0
        dailyPoints = [:]
        claimedDailyMilestones = [:]
        claimedTotalMilestones = []
        claimedPacks = []
        eventTokens = 0
        dayStartSnapshots = [:]
    }

    func pointsForDay(_ day: Int) -> Int {
        dailyPoints[day] ?? 0
    }
}

// MARK: - Day Start Snapshot

/// Captures player stats at the start of a day so we can compute deltas.
struct DayStartSnapshot: Codable {
    let totalTaps: Int
    let totalTEEarned: Decimal
    let totalPrestigeCount: Int
    let totalEpochCount: Int
    let totalRelicsForged: Int
    let relicMaterials: Int
    let totalChronoShardsEarned: Int
    let purchasedUpgradeCount: Int
    let unlockedEraCount: Int
    let generatorCount: Int

    static func capture(from player: PlayerState) -> DayStartSnapshot {
        DayStartSnapshot(
            totalTaps: player.totalTaps,
            totalTEEarned: player.totalTEEarned,
            totalPrestigeCount: player.totalPrestigeCount,
            totalEpochCount: player.totalEpochCount,
            totalRelicsForged: player.totalRelicsForged,
            relicMaterials: player.relicMaterials,
            totalChronoShardsEarned: player.totalChronoShardsEarned,
            purchasedUpgradeCount: player.purchasedUpgrades.count,
            unlockedEraCount: player.unlockedEras.count,
            generatorCount: player.generators.values.reduce(0) { $0 + $1.quantity }
        )
    }
}
