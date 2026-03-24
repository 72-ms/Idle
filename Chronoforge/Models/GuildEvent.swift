import Foundation

// MARK: - Guild Event System
// Guild vs Guild competitive events. Same multi-day structure as solo events,
// but guild members collectively earn points for their guild.
// Two reward layers: guild placement (guild rank) + individual contribution (within guild).

// MARK: - Contribution Tier

/// Within-guild ranking tiers based on absolute position.
/// Percentile doesn't work well for 8-50 member groups, so we use fixed rank brackets.
enum GuildContributionTier: Int, Codable, CaseIterable, Comparable {
    case mvp           = 1   // #1 in guild
    case topContributor = 2  // #2-3
    case strong        = 3   // #4-5
    case active        = 4   // Top half (excluding above)
    case participant   = 5   // Bottom half

    static func < (lhs: GuildContributionTier, rhs: GuildContributionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func tier(forRank rank: Int, totalMembers: Int) -> GuildContributionTier {
        switch rank {
        case 1:         return .mvp
        case 2...3:     return .topContributor
        case 4...5:     return .strong
        default:
            let halfPoint = max(6, totalMembers / 2)
            return rank <= halfPoint ? .active : .participant
        }
    }

    var displayName: String {
        switch self {
        case .mvp:            return "MVP"
        case .topContributor: return "Top Contributor"
        case .strong:         return "Strong Contributor"
        case .active:         return "Active Contributor"
        case .participant:    return "Participant"
        }
    }

    var iconName: String {
        switch self {
        case .mvp:            return "crown.fill"
        case .topContributor: return "medal.fill"
        case .strong:         return "star.fill"
        case .active:         return "flame.fill"
        case .participant:    return "checkmark.seal"
        }
    }

    /// Individual contribution rewards — what you personally get based on how much you pulled your weight.
    func rewards(scaleFactor: Int) -> [LiveEventReward] {
        let s = scaleFactor
        switch self {
        case .mvp:
            return [
                .chronoShards(400 * s),
                .epochCrystals(40 * s),
                .eventToken(80 * s),
                .relicMaterials(200 * s),
                .cosmetic("guild_event_mvp_title")
            ]
        case .topContributor:
            return [
                .chronoShards(200 * s),
                .epochCrystals(20 * s),
                .eventToken(40 * s),
                .relicMaterials(100 * s)
            ]
        case .strong:
            return [
                .chronoShards(100 * s),
                .epochCrystals(10 * s),
                .eventToken(20 * s)
            ]
        case .active:
            return [
                .chronoShards(40 * s),
                .eventToken(8 * s)
            ]
        case .participant:
            return [
                .chronoShards(10 * s)
            ]
        }
    }
}

// MARK: - Guild Event Leaderboard Entry

struct GuildEventLeaderboardEntry: Identifiable {
    let id: String
    let rank: Int
    let guildName: String
    let guildLevel: Int
    let score: Int
    let memberCount: Int
    let isLocalGuild: Bool
    let placementTier: EventPlacementTier
}

// MARK: - Guild Member Contribution Entry

struct GuildContributionEntry: Identifiable {
    let id: UUID
    let rank: Int
    let memberName: String
    let score: Int
    let isLocalPlayer: Bool
    let vipTier: VIPTier
    let contributionTier: GuildContributionTier
}

// MARK: - Guild Event Config

/// A fully configured guild event. Reuses LiveEventChallengeType and LiveEventDay
/// for challenge structure, but scoring feeds into guild totals.
struct GuildEventConfig: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let theme: LiveEventTheme
    let startDate: Date
    let endDate: Date
    let days: [LiveEventDay]

    var duration: Int { days.count }
    var isActive: Bool { Date() >= startDate && Date() <= endDate }
    var hasEnded: Bool { Date() > endDate }

    var leaderboardID: String { "com.chronoforge.guildevent.\(id)" }

    func dailyLeaderboardID(dayIndex: Int) -> String {
        "com.chronoforge.guildevent.\(id).day\(dayIndex)"
    }

    var scaleFactor: Int {
        let parts = id.split(separator: "_")
        let index = Int(parts.last ?? "0") ?? 0
        return max(1, index / 3 + 1)
    }

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

// MARK: - Guild Event Player State (persisted)

struct GuildEventPlayerState: Codable {
    var activeGuildEventId: String?
    var personalPoints: Int = 0
    var dailyPersonalPoints: [Int: Int] = [:]
    var dayStartSnapshots: [Int: DayStartSnapshot] = [:]

    // Guild placement (guild vs guild)
    var finalGuildRank: Int?
    var finalGuildPercentile: Double?
    var claimedGuildPlacementReward: Bool = false

    // Individual contribution (within guild)
    var finalContributionRank: Int?
    var finalContributionTotalMembers: Int?
    var claimedContributionReward: Bool = false

    // Daily contribution
    var claimedDailyContributionRewards: Set<Int> = []
    var dailyContributionRanks: [Int: Int] = []

    var guildPlacementTier: EventPlacementTier? {
        guard let pct = finalGuildPercentile else { return nil }
        return EventPlacementTier.tier(forPercentile: pct)
    }

    var contributionTier: GuildContributionTier? {
        guard let rank = finalContributionRank, let total = finalContributionTotalMembers else { return nil }
        return GuildContributionTier.tier(forRank: rank, totalMembers: total)
    }

    func personalPointsForDay(_ day: Int) -> Int {
        dailyPersonalPoints[day] ?? 0
    }

    mutating func reset(for eventId: String) {
        activeGuildEventId = eventId
        personalPoints = 0
        dailyPersonalPoints = [:]
        dayStartSnapshots = [:]
        finalGuildRank = nil
        finalGuildPercentile = nil
        claimedGuildPlacementReward = false
        finalContributionRank = nil
        finalContributionTotalMembers = nil
        claimedContributionReward = false
        claimedDailyContributionRewards = []
        dailyContributionRanks = [:]
    }
}

// MARK: - Guild Placement Rewards

/// Guild placement rewards — everyone in the guild gets these based on where the guild ranked.
/// These are on top of individual contribution rewards.
extension EventPlacementTier {
    func guildEventRewards(scaleFactor: Int) -> [LiveEventReward] {
        let s = scaleFactor
        switch self {
        case .top1:
            return [
                .chronoShards(1500 * s),
                .epochCrystals(150 * s),
                .eventToken(200 * s),
                .relicMaterials(400 * s),
                .cosmetic("guild_event_champion_banner"),
                .cosmetic("guild_event_champion_title")
            ]
        case .top5:
            return [
                .chronoShards(800 * s),
                .epochCrystals(80 * s),
                .eventToken(100 * s),
                .relicMaterials(200 * s),
                .cosmetic("guild_event_elite_banner")
            ]
        case .top10:
            return [
                .chronoShards(400 * s),
                .epochCrystals(40 * s),
                .eventToken(50 * s),
                .relicMaterials(100 * s)
            ]
        case .top25:
            return [
                .chronoShards(150 * s),
                .epochCrystals(15 * s),
                .eventToken(20 * s)
            ]
        case .top50:
            return [
                .chronoShards(60 * s),
                .epochCrystals(5 * s)
            ]
        case .top100:
            return [
                .chronoShards(15 * s)
            ]
        }
    }
}
