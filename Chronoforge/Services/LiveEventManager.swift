import Foundation

@Observable
final class LiveEventManager {

    // MARK: - State

    private(set) var currentEvent: LiveEventConfig?
    private(set) var upcomingEvents: [LiveEventConfig] = []

    /// Callback for delivering rewards to the player.
    var onReward: ((LiveEventReward) -> Void)?

    private let saveKey = "chronoforge_live_events"
    private var checkTimer: Timer?

    // MARK: - Init

    init() {
        generateSchedule()
        activateCurrentEvent()
    }

    // MARK: - Schedule Generation

    /// Generates a rolling 8-week event schedule so there's always something running.
    /// Events run back-to-back with occasional 1-day gaps. Each event is 5-7 days.
    /// Two events can overlap: one solo + one guild-flavored.
    private func generateSchedule() {
        let calendar = Calendar.current
        let now = Date()

        // Find the Monday of the current week
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        // Adjust to Monday (dateInterval start is Sunday)
        weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart

        let themes = LiveEventTheme.allCases
        var events: [LiveEventConfig] = []
        var eventDate = calendar.date(byAdding: .day, value: -7, to: weekStart)!  // Start a week ago

        for i in 0..<12 {
            let theme = themes[i % themes.count]
            let duration = [5, 6, 7][i % 3]
            let eventStart = eventDate
            let eventEnd = calendar.date(byAdding: .day, value: duration, to: eventStart)!

            let event = Self.buildEvent(
                index: i,
                theme: theme,
                start: eventStart,
                end: eventEnd,
                duration: duration
            )
            events.append(event)

            // Next event starts 0-1 days after this one ends
            let gap = i % 3 == 2 ? 1 : 0
            eventDate = calendar.date(byAdding: .day, value: gap, to: eventEnd)!
        }

        // Split into current and upcoming
        let active = events.filter { $0.isActive }
        let upcoming = events.filter { !$0.isActive && !$0.hasEnded }

        currentEvent = active.first
        upcomingEvents = Array(upcoming.prefix(5))
    }

    /// Builds a fully configured event from a theme and date range.
    static func buildEvent(index: Int, theme: LiveEventTheme, start: Date, end: Date, duration: Int) -> LiveEventConfig {
        let challenges = theme.dailyChallenges
        let scaleFactor = max(1, index / 3 + 1)  // Events get harder over time

        var days: [LiveEventDay] = []
        for d in 0..<duration {
            let challenge = challenges[d % challenges.count]
            let bonusMult: Decimal = d == duration - 1 ? 2 : 1  // Last day = double points

            let dailyMilestones = Self.generateDailyMilestones(
                for: challenge,
                dayIndex: d,
                scaleFactor: scaleFactor
            )

            days.append(LiveEventDay(
                id: d,
                challengeType: challenge,
                bonusMultiplier: bonusMult,
                milestones: dailyMilestones
            ))
        }

        let totalMilestones = Self.generateTotalMilestones(
            theme: theme,
            scaleFactor: scaleFactor,
            eventId: "\(theme.rawValue)_\(index)"
        )

        let eventId = "\(theme.rawValue)_\(index)"
        var packs = [LiveEventPack.freePack(eventId: eventId)]
        packs.append(contentsOf: LiveEventPack.paidPacks(eventId: eventId))

        return LiveEventConfig(
            id: eventId,
            name: "\(theme.displayName) \(romanNumeral(index + 1))",
            description: eventDescription(for: theme),
            theme: theme,
            startDate: start,
            endDate: end,
            days: days,
            totalMilestones: totalMilestones,
            packs: packs
        )
    }

    // MARK: - Daily Milestone Generation

    static func generateDailyMilestones(for challenge: LiveEventChallengeType, dayIndex: Int, scaleFactor: Int) -> [LiveEventMilestone] {
        let base = challenge.pointsPerAction
        let scale = scaleFactor

        // 5 milestone tiers per day
        let thresholds: [Int]
        switch challenge {
        case .tapFrenzy:
            thresholds = [100, 500, 2000, 10000, 50000].map { $0 * scale }
        case .productionSurge:
            thresholds = [500, 2000, 10000, 50000, 200000].map { $0 * scale }
        case .generatorRush:
            thresholds = [200, 1000, 5000, 20000, 80000].map { $0 * scale }
        case .relicForging:
            thresholds = [500, 2500, 10000, 50000, 200000].map { $0 * scale }
        case .prestigeMarathon:
            thresholds = [1000, 5000, 20000, 80000, 300000].map { $0 * scale }
        case .upgradeSpree:
            thresholds = [250, 1500, 6000, 25000, 100000].map { $0 * scale }
        case .materialHarvest:
            thresholds = [200, 1000, 5000, 20000, 80000].map { $0 * scale }
        case .shardCollection:
            thresholds = [500, 2500, 10000, 50000, 200000].map { $0 * scale }
        case .epochPush:
            thresholds = [5000, 15000, 50000, 150000, 500000].map { $0 * scale }
        case .eraExplorer:
            thresholds = [2000, 8000, 30000, 100000, 400000].map { $0 * scale }
        }

        let rewards: [LiveEventReward] = [
            .chronoShards(10 * scale),
            .relicMaterials(15 * scale),
            .chronoShards(30 * scale),
            .productionBoost(multiplier: 3, minutes: 30),
            .eventToken(5 * scale)
        ]

        return zip(thresholds, rewards).map { pts, reward in
            LiveEventMilestone(points: pts, reward: reward)
        }
    }

    // MARK: - Total Event Milestones

    static func generateTotalMilestones(theme: LiveEventTheme, scaleFactor: Int, eventId: String) -> [LiveEventTotalMilestone] {
        let s = scaleFactor
        return [
            LiveEventTotalMilestone(
                totalPoints: 5000 * s,
                reward: .chronoShards(50 * s),
                isExclusive: false
            ),
            LiveEventTotalMilestone(
                totalPoints: 25000 * s,
                reward: .relicMaterials(50 * s),
                isExclusive: false
            ),
            LiveEventTotalMilestone(
                totalPoints: 75000 * s,
                reward: .epochCrystals(10 * s),
                isExclusive: false
            ),
            LiveEventTotalMilestone(
                totalPoints: 200000 * s,
                reward: .productionBoost(multiplier: 5, minutes: 120),
                isExclusive: false
            ),
            LiveEventTotalMilestone(
                totalPoints: 500000 * s,
                reward: .eventToken(25 * s),
                isExclusive: false
            ),
            LiveEventTotalMilestone(
                totalPoints: 1000000 * s,
                reward: .cosmetic("event_\(eventId)_frame"),
                isExclusive: true
            ),
            LiveEventTotalMilestone(
                totalPoints: 2500000 * s,
                reward: .cosmetic("event_\(eventId)_title"),
                isExclusive: true
            )
        ]
    }

    // MARK: - Point Calculation

    /// Calculates points earned for the current day based on player action deltas.
    func calculateDayPoints(player: PlayerState, eventState: LiveEventPlayerState) -> Int {
        guard let event = currentEvent,
              let dayIndex = event.currentDayIndex,
              let day = event.currentDay,
              let snapshot = eventState.dayStartSnapshots[dayIndex] else {
            return 0
        }

        let challenge = day.challengeType
        var rawPoints = 0

        switch challenge {
        case .tapFrenzy:
            rawPoints = (player.totalTaps - snapshot.totalTaps) * challenge.pointsPerAction

        case .productionSurge:
            let teDelta = player.totalTEEarned - snapshot.totalTEEarned
            let millions = NSDecimalNumber(decimal: teDelta / 1_000_000).intValue
            rawPoints = max(0, millions) * challenge.pointsPerAction

        case .generatorRush:
            let genDelta = player.generators.values.reduce(0) { $0 + $1.quantity } - snapshot.generatorCount
            rawPoints = max(0, genDelta) * challenge.pointsPerAction

        case .relicForging:
            rawPoints = max(0, player.totalRelicsForged - snapshot.totalRelicsForged) * challenge.pointsPerAction

        case .prestigeMarathon:
            rawPoints = max(0, player.totalPrestigeCount - snapshot.totalPrestigeCount) * challenge.pointsPerAction

        case .upgradeSpree:
            rawPoints = max(0, player.purchasedUpgrades.count - snapshot.purchasedUpgradeCount) * challenge.pointsPerAction

        case .materialHarvest:
            rawPoints = max(0, player.relicMaterials - snapshot.relicMaterials) * challenge.pointsPerAction

        case .shardCollection:
            rawPoints = max(0, player.totalChronoShardsEarned - snapshot.totalChronoShardsEarned) * challenge.pointsPerAction

        case .epochPush:
            rawPoints = max(0, player.totalEpochCount - snapshot.totalEpochCount) * challenge.pointsPerAction

        case .eraExplorer:
            rawPoints = max(0, player.unlockedEras.count - snapshot.unlockedEraCount) * challenge.pointsPerAction
        }

        // Apply daily point cap (before bonus multiplier) to prevent macro/AFK abuse
        if let cap = challenge.dailyPointCap {
            rawPoints = min(rawPoints, cap)
        }

        // Apply day bonus multiplier
        return Int(Decimal(rawPoints) * day.bonusMultiplier)
    }

    /// Updates the player's event state with current progress.
    func updateProgress(player: PlayerState) {
        guard let event = currentEvent,
              let dayIndex = event.currentDayIndex else { return }

        // Ensure we have a snapshot for today
        if player.liveEventState.dayStartSnapshots[dayIndex] == nil {
            player.liveEventState.dayStartSnapshots[dayIndex] = DayStartSnapshot.capture(from: player)
        }

        // Ensure event state is initialized
        if player.liveEventState.activeEventId != event.id {
            player.liveEventState.reset(for: event.id)
            player.liveEventState.dayStartSnapshots[dayIndex] = DayStartSnapshot.capture(from: player)
        }

        let dayPoints = calculateDayPoints(player: player, eventState: player.liveEventState)
        let previousDayPoints = player.liveEventState.pointsForDay(dayIndex)

        if dayPoints > previousDayPoints {
            let delta = dayPoints - previousDayPoints
            player.liveEventState.dailyPoints[dayIndex] = dayPoints
            player.liveEventState.totalPoints += delta
        }
    }

    // MARK: - Claim Rewards

    func claimDailyMilestone(milestoneId: String, dayIndex: Int, player: PlayerState) -> Bool {
        guard let event = currentEvent,
              dayIndex < event.days.count else { return false }

        let day = event.days[dayIndex]
        guard let milestone = day.milestones.first(where: { $0.id == milestoneId }) else { return false }

        let dayPoints = player.liveEventState.pointsForDay(dayIndex)
        guard dayPoints >= milestone.points else { return false }

        var claimed = player.liveEventState.claimedDailyMilestones[dayIndex] ?? []
        guard !claimed.contains(milestoneId) else { return false }

        claimed.insert(milestoneId)
        player.liveEventState.claimedDailyMilestones[dayIndex] = claimed

        deliverReward(milestone.reward, to: player)
        return true
    }

    func claimTotalMilestone(milestoneId: String, player: PlayerState) -> Bool {
        guard let event = currentEvent else { return false }
        guard let milestone = event.totalMilestones.first(where: { $0.id == milestoneId }) else { return false }
        guard player.liveEventState.totalPoints >= milestone.totalPoints else { return false }
        guard !player.liveEventState.claimedTotalMilestones.contains(milestoneId) else { return false }

        player.liveEventState.claimedTotalMilestones.insert(milestoneId)
        deliverReward(milestone.reward, to: player)
        return true
    }

    func claimPack(packId: String, player: PlayerState) -> Bool {
        guard let event = currentEvent else { return false }
        guard let pack = event.packs.first(where: { $0.id == packId }) else { return false }
        guard !player.liveEventState.claimedPacks.contains(packId) else { return false }
        guard pack.isFree else { return false }

        player.liveEventState.claimedPacks.insert(packId)
        for reward in pack.rewards {
            deliverReward(reward, to: player)
        }
        return true
    }

    /// Called after a successful StoreKit purchase to deliver a paid event pack.
    func deliverPaidPack(packId: String, player: PlayerState) -> Bool {
        guard let event = currentEvent else { return false }
        guard let pack = event.packs.first(where: { $0.id == packId }) else { return false }
        guard !player.liveEventState.claimedPacks.contains(packId) else { return false }
        guard !pack.isFree else { return false }

        player.liveEventState.claimedPacks.insert(packId)
        for reward in pack.rewards {
            deliverReward(reward, to: player)
        }
        return true
    }

    /// Returns the product ID for a paid pack so the view can initiate a StoreKit purchase.
    func productId(for packId: String) -> String? {
        guard let event = currentEvent else { return nil }
        guard let pack = event.packs.first(where: { $0.id == packId }) else { return nil }
        guard !pack.isFree else { return nil }
        return pack.productId
    }

    // MARK: - Reward Delivery

    private func deliverReward(_ reward: LiveEventReward, to player: PlayerState) {
        switch reward {
        case .temporalEnergy(let amount):
            player.temporalEnergy += amount
            player.totalTEEarned += amount
            player.totalLifetimeTEEarned += amount

        case .chronoShards(let n):
            player.chronoShards += n
            player.totalChronoShardsEarned += n
            player.skillTree.availablePoints += n

        case .epochCrystals(let n):
            player.epochCrystals += n

        case .relicMaterials(let n):
            player.relicMaterials += n

        case .productionBoost(let mult, let mins):
            onReward?(.productionBoost(multiplier: mult, minutes: mins))

        case .eventPoints(let n):
            player.liveEventState.totalPoints += n

        case .cosmetic(let id):
            player.ownedCosmetics.insert(id)

        case .eventToken(let n):
            player.liveEventState.eventTokens += n
        }
    }

    // MARK: - Lifecycle

    func start() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.activateCurrentEvent()
        }
    }

    func stop() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func activateCurrentEvent() {
        // Regenerate if current event ended
        if currentEvent?.hasEnded == true || currentEvent == nil {
            generateSchedule()
        }
    }

    // MARK: - Helpers

    private static func romanNumeral(_ n: Int) -> String {
        let cycle = ((n - 1) % 20) + 1
        let values = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var result = ""
        var remaining = cycle
        for (value, numeral) in values {
            while remaining >= value {
                result += numeral
                remaining -= value
            }
        }
        return result
    }

    private static func eventDescription(for theme: LiveEventTheme) -> String {
        switch theme {
        case .chronoSurge:
            return "A surge of temporal energy floods the Chronoforge! Maximize production and generator output to earn massive event rewards."
        case .forgeInferno:
            return "The forge burns white-hot! Forge relics and gather materials to prove your mastery of the anvil."
        case .temporalStorm:
            return "A temporal storm rages across all eras! Push through prestiges and epoch resets for incredible rewards."
        case .harvestMoon:
            return "The harvest moon rises over the Chronoforge! Collect resources and materials during this bountiful event."
        case .voidRift:
            return "A rift to the void has opened! Only the most dedicated forgers can conquer its challenges."
        case .cosmicDawn:
            return "A new cosmic dawn breaks across all timelines! Complete varied challenges each day for ultimate rewards."
        }
    }
}
