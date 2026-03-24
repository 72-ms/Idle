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

    /// Maximum raw points (before bonus multiplier) earnable per day for this challenge.
    /// Prevents macro abuse on tap-heavy challenges and AFK farming on passive ones.
    /// nil = no cap (for actions that are naturally limited like epoch resets).
    var dailyPointCap: Int? {
        switch self {
        case .tapFrenzy: return 10_000          // 10K taps worth — ~30min of active play
        case .productionSurge: return 100_000   // Passive earnings capped
        case .generatorRush: return 50_000      // ~5000 generators
        case .relicForging: return 25_000       // 50 relics — very active session
        case .prestigeMarathon: return nil      // Naturally gated by prestige cost
        case .upgradeSpree: return 15_000       // 300 upgrades
        case .materialHarvest: return 50_000    // 10K materials
        case .shardCollection: return 75_000    // 3K shards
        case .epochPush: return nil             // Naturally gated by epoch requirements
        case .eraExplorer: return nil           // Only 5 eras total, self-limiting
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
/// Tier 0 is free (hooks players in), tiers 1-6 escalate from impulse buy to whale territory.
/// Each tier is purchasable once per event. Value-per-dollar improves at higher tiers
/// to incentivize bigger spends.
struct LiveEventPack: Codable, Identifiable {
    let id: String
    let tier: Int           // 0 = free, 1+ = paid
    let name: String
    let price: String       // "Free" or "$X.99"
    let productId: String   // StoreKit product ID
    let rewards: [LiveEventReward]
    let isFree: Bool
    let badge: String?      // Optional badge text like "BEST VALUE", "LIMITED"

    static func freePack(eventId: String) -> LiveEventPack {
        LiveEventPack(
            id: "\(eventId)_pack_free",
            tier: 0,
            name: "Starter Pack",
            price: "Free",
            productId: "",
            rewards: [
                .eventPoints(500),
                .chronoShards(25),
                .relicMaterials(10)
            ],
            isFree: true,
            badge: nil
        )
    }

    static func paidPacks(eventId: String) -> [LiveEventPack] {
        [
            // Tier 1 — Impulse buy, low barrier to entry
            LiveEventPack(
                id: "\(eventId)_pack_1",
                tier: 1, name: "Bronze Event Pack",
                price: "$0.99",
                productId: "com.chronoforge.event.pack.bronze",
                rewards: [
                    .eventPoints(2_000),
                    .chronoShards(100),
                    .relicMaterials(25),
                    .productionBoost(multiplier: 2, minutes: 60)
                ],
                isFree: false,
                badge: nil
            ),
            // Tier 2 — Light spender, 2.5x better value than Tier 1
            LiveEventPack(
                id: "\(eventId)_pack_2",
                tier: 2, name: "Silver Event Pack",
                price: "$4.99",
                productId: "com.chronoforge.event.pack.silver",
                rewards: [
                    .eventPoints(12_000),
                    .chronoShards(600),
                    .epochCrystals(15),
                    .relicMaterials(80),
                    .productionBoost(multiplier: 3, minutes: 120)
                ],
                isFree: false,
                badge: nil
            ),
            // Tier 3 — Mid spender, crossing the $10 threshold
            LiveEventPack(
                id: "\(eventId)_pack_3",
                tier: 3, name: "Gold Event Pack",
                price: "$9.99",
                productId: "com.chronoforge.event.pack.gold",
                rewards: [
                    .eventPoints(30_000),
                    .chronoShards(2_000),
                    .epochCrystals(40),
                    .relicMaterials(200),
                    .productionBoost(multiplier: 5, minutes: 120),
                    .eventToken(8)
                ],
                isFree: false,
                badge: "POPULAR"
            ),
            // Tier 4 — Committed spender
            LiveEventPack(
                id: "\(eventId)_pack_4",
                tier: 4, name: "Platinum Event Pack",
                price: "$19.99",
                productId: "com.chronoforge.event.pack.platinum",
                rewards: [
                    .eventPoints(75_000),
                    .chronoShards(5_000),
                    .epochCrystals(100),
                    .relicMaterials(400),
                    .productionBoost(multiplier: 10, minutes: 180),
                    .eventToken(25)
                ],
                isFree: false,
                badge: nil
            ),
            // Tier 5 — Whale entry, big jump in exclusive content
            LiveEventPack(
                id: "\(eventId)_pack_5",
                tier: 5, name: "Diamond Event Pack",
                price: "$49.99",
                productId: "com.chronoforge.event.pack.diamond",
                rewards: [
                    .eventPoints(200_000),
                    .chronoShards(15_000),
                    .epochCrystals(250),
                    .relicMaterials(800),
                    .productionBoost(multiplier: 10, minutes: 360),
                    .eventToken(60),
                    .cosmetic("event_exclusive_diamond_aura")
                ],
                isFree: false,
                badge: "BEST VALUE"
            ),
            // Tier 6 — Whale pack, nearly guarantees top event milestones
            LiveEventPack(
                id: "\(eventId)_pack_6",
                tier: 6, name: "Chronarch Event Pack",
                price: "$99.99",
                productId: "com.chronoforge.event.pack.chronarch",
                rewards: [
                    .eventPoints(500_000),
                    .chronoShards(40_000),
                    .epochCrystals(600),
                    .relicMaterials(2_000),
                    .productionBoost(multiplier: 15, minutes: 480),
                    .eventToken(150),
                    .cosmetic("event_exclusive_chronarch_frame"),
                    .cosmetic("event_exclusive_chronarch_title")
                ],
                isFree: false,
                badge: "LIMITED"
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

// MARK: - Event Placement Tiers

/// Competitive placement tiers — rewards scale with rank.
/// Percentile-based so every player has a shot regardless of server population.
enum EventPlacementTier: Int, Codable, CaseIterable, Comparable {
    case top1      = 1    // Top 1%
    case top5      = 5    // Top 5%
    case top10     = 10   // Top 10%
    case top25     = 25   // Top 25%
    case top50     = 50   // Top 50%
    case top100    = 100  // Everyone who participated

    static func < (lhs: EventPlacementTier, rhs: EventPlacementTier) -> Bool {
        lhs.rawValue < rhs.rawValue  // Lower rawValue = higher tier
    }

    static func tier(forPercentile percentile: Double) -> EventPlacementTier {
        switch percentile {
        case ...1:  return .top1
        case ...5:  return .top5
        case ...10: return .top10
        case ...25: return .top25
        case ...50: return .top50
        default:    return .top100
        }
    }

    var displayName: String {
        switch self {
        case .top1:   return "Top 1%"
        case .top5:   return "Top 5%"
        case .top10:  return "Top 10%"
        case .top25:  return "Top 25%"
        case .top50:  return "Top 50%"
        case .top100: return "Participant"
        }
    }

    var iconName: String {
        switch self {
        case .top1:   return "trophy.fill"
        case .top5:   return "medal.fill"
        case .top10:  return "rosette"
        case .top25:  return "star.fill"
        case .top50:  return "star.leadinghalf.filled"
        case .top100: return "checkmark.seal"
        }
    }

    var accentColor: String {
        switch self {
        case .top1:   return "gold"
        case .top5:   return "silver"
        case .top10:  return "bronze"
        case .top25:  return "blue"
        case .top50:  return "green"
        case .top100: return "gray"
        }
    }

    /// Placement rewards scale per tier. scaleFactor increases for later events.
    func rewards(scaleFactor: Int) -> [LiveEventReward] {
        let s = scaleFactor
        switch self {
        case .top1:
            return [
                .chronoShards(500 * s),
                .epochCrystals(50 * s),
                .eventToken(100 * s),
                .cosmetic("event_rank_champion_frame"),
                .cosmetic("event_rank_champion_title")
            ]
        case .top5:
            return [
                .chronoShards(250 * s),
                .epochCrystals(25 * s),
                .eventToken(50 * s),
                .cosmetic("event_rank_elite_frame")
            ]
        case .top10:
            return [
                .chronoShards(150 * s),
                .epochCrystals(15 * s),
                .eventToken(30 * s)
            ]
        case .top25:
            return [
                .chronoShards(75 * s),
                .epochCrystals(8 * s),
                .eventToken(15 * s)
            ]
        case .top50:
            return [
                .chronoShards(30 * s),
                .eventToken(5 * s)
            ]
        case .top100:
            return [
                .chronoShards(10 * s)
            ]
        }
    }
}

// MARK: - Event Leaderboard Entry

struct EventLeaderboardEntry: Identifiable {
    let id: String
    let rank: Int
    let playerName: String
    let score: Int
    let isLocalPlayer: Bool
    let vipTier: VIPTier
    let placementTier: EventPlacementTier
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

    /// Game Center leaderboard ID for this event.
    var leaderboardID: String { "com.chronoforge.event.\(id)" }

    /// The scale factor for placement rewards (later events = bigger rewards).
    var scaleFactor: Int {
        // Extract the index from the event ID (e.g. "chronoSurge_3" -> 3)
        let parts = id.split(separator: "_")
        let index = Int(parts.last ?? "0") ?? 0
        return max(1, index / 3 + 1)
    }

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

    // MARK: - Leaderboard / Placement
    var finalRank: Int?                     // Set when event ends
    var finalPercentile: Double?            // Set when event ends
    var claimedPlacementReward: Bool = false // True after player claims their tier reward

    var placementTier: EventPlacementTier? {
        guard let pct = finalPercentile else { return nil }
        return EventPlacementTier.tier(forPercentile: pct)
    }

    mutating func reset(for eventId: String) {
        activeEventId = eventId
        totalPoints = 0
        dailyPoints = [:]
        claimedDailyMilestones = [:]
        claimedTotalMilestones = []
        claimedPacks = []
        eventTokens = 0
        dayStartSnapshots = [:]
        finalRank = nil
        finalPercentile = nil
        claimedPlacementReward = false
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
