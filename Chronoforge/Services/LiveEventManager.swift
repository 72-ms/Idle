import Foundation

@Observable
final class LiveEventManager {

    // MARK: - State

    private(set) var currentEvent: LiveEventConfig?
    private(set) var upcomingEvents: [LiveEventConfig] = []

    /// Competitive leaderboard for the current event.
    private(set) var leaderboardEntries: [EventLeaderboardEntry] = []
    private(set) var localPlayerRank: Int?
    private(set) var localPlayerPercentile: Double?
    private(set) var totalParticipants: Int = 0

    /// Reference to LeaderboardManager for Game Center integration.
    var leaderboardManager: LeaderboardManager?

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

            // Submit updated score to the event leaderboard
            submitScore(player: player)
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

    // MARK: - Leaderboard

    /// Submits the player's current event score to Game Center.
    func submitScore(player: PlayerState) {
        guard let event = currentEvent else { return }
        let score = player.liveEventState.totalPoints
        guard score > 0 else { return }
        leaderboardManager?.submitScore(score, to: event.leaderboardID)
    }

    /// Loads the event leaderboard from Game Center and fills in simulated
    /// competitors to ensure the board always feels populated.
    func loadLeaderboard(player: PlayerState) async {
        guard let event = currentEvent else { return }

        // Load real Game Center entries
        var realEntries: [LeaderboardEntry] = []
        if let lbManager = leaderboardManager {
            await lbManager.loadEntries(for: event.leaderboardID)
            realEntries = lbManager.leaderboardEntries
        }

        let playerScore = player.liveEventState.totalPoints

        // Generate simulated competitors to ensure a full leaderboard.
        // This guarantees there's always a competitive feel even with low GC adoption.
        let simulated = Self.generateSimulatedCompetitors(
            playerScore: playerScore,
            eventScaleFactor: event.scaleFactor,
            realEntryCount: realEntries.count
        )

        // Merge real + simulated, sort by score descending, assign ranks
        var combined: [(name: String, score: Int, isLocal: Bool, vip: VIPTier)] = []

        for entry in realEntries {
            combined.append((entry.playerName, entry.score, entry.isLocalPlayer, entry.vipTier))
        }
        for sim in simulated {
            combined.append((sim.name, sim.score, false, sim.vip))
        }

        // Add local player if not already present from GC
        if !combined.contains(where: { $0.isLocal }) && playerScore > 0 {
            combined.append(("You", playerScore, true, .none))
        }

        combined.sort { $0.score > $1.score }

        let total = combined.count
        var entries: [EventLeaderboardEntry] = []
        var playerRank: Int?
        var playerPct: Double?

        for (i, entry) in combined.enumerated() {
            let rank = i + 1
            let percentile = Double(rank) / Double(total) * 100.0
            let tier = EventPlacementTier.tier(forPercentile: percentile)

            entries.append(EventLeaderboardEntry(
                id: entry.isLocal ? "local" : "entry_\(i)",
                rank: rank,
                playerName: entry.name,
                score: entry.score,
                isLocalPlayer: entry.isLocal,
                vipTier: entry.vip,
                placementTier: tier
            ))

            if entry.isLocal {
                playerRank = rank
                playerPct = percentile
            }
        }

        await MainActor.run {
            self.leaderboardEntries = entries
            self.localPlayerRank = playerRank
            self.localPlayerPercentile = playerPct
            self.totalParticipants = total
        }
    }

    /// Finalizes placement when an event ends. Called once per event.
    func finalizePlacement(player: PlayerState) {
        guard player.liveEventState.finalRank == nil else { return }
        guard player.liveEventState.totalPoints > 0 else { return }

        player.liveEventState.finalRank = localPlayerRank ?? 1
        player.liveEventState.finalPercentile = localPlayerPercentile ?? 50.0
    }

    /// Claims the placement reward for a completed event.
    func claimPlacementReward(player: PlayerState) -> Bool {
        guard let tier = player.liveEventState.placementTier else { return false }
        guard !player.liveEventState.claimedPlacementReward else { return false }

        let scaleFactor = currentEvent?.scaleFactor ?? 1
        let rewards = tier.rewards(scaleFactor: scaleFactor)
        for reward in rewards {
            deliverReward(reward, to: player)
        }

        player.liveEventState.claimedPlacementReward = true
        return true
    }

    // MARK: - Simulated Competitors

    /// Generates a pool of simulated competitors with realistic score distributions.
    /// Creates a bell curve centered near the player's score so they're always in
    /// a competitive bracket — not always first, not always last.
    private static func generateSimulatedCompetitors(
        playerScore: Int,
        eventScaleFactor: Int,
        realEntryCount: Int
    ) -> [(name: String, score: Int, vip: VIPTier)] {
        // Target ~100 total entries; fewer sims if lots of real players
        let simCount = max(20, 100 - realEntryCount)
        let baseScore = max(1000, playerScore)

        // Seeded from scale factor so the same event always has the same competitors
        var rng = SeededRNG(seed: UInt64(eventScaleFactor * 7919 + 42))

        let names = [
            "ChronoKnight", "TimeWeaver", "EpochRider", "ForgeHammer", "TemporalAce",
            "ShardHunter", "VoidWalker", "EraBreaker", "RelicSmith", "PrestigeLord",
            "NovaCrafter", "AeonBlade", "FluxMaster", "DawnForger", "CosmicAnvil",
            "SurgeKing", "InfernoSmith", "StormChaser", "MoonReaper", "RiftRunner",
            "TimeLord99", "xXForgeXx", "CrystalMage", "EpochGrinder", "ShardQueen",
            "NanoForge", "TurboPrestige", "IdleMaster", "TEFarmer", "GeneratorGod",
            "RelicHoarder", "EraHopper", "TapKing420", "BoostAddict", "VoidKnight",
            "SurgeQueen", "HammerTime", "ChronicleFan", "EventHero", "ForgeFury",
            "TempoSlayer", "AstralSmith", "PrismForger", "NexusRunner", "WarpDriven",
            "IronEpoch", "SilverForge", "GoldRush777", "DiamondHands", "PlatinumAge",
            "OmegaForge", "AlphaStrike", "ZenithPeak", "NadirDeep", "TwilightForge",
            "DuskHammer", "RainbowAnvil", "ThunderForge", "FrostEpoch", "BlazeSurge",
            "PhantomForge", "ShadowSmith", "CrimsonEra", "EmeraldShard", "SapphireTE",
            "RubyPrestige", "OnyxVoid", "TopazCraft", "AmethystAeon", "JadeForger",
            "CobaltStorm", "TitanForge", "ZephyrRun", "MeteorStrike", "CometTail",
            "NovaBlast", "PulsarGrind", "QuasarForge", "NebulaSmith", "GalaxyBrain",
            "StarForger", "MoonForge", "SunSmith", "EclipseRun", "SolsticeGrind",
            "EquinoxForge", "AuroraSmith", "MirageForge", "OasisRun", "MirageCraft",
            "TempestForge", "CycloneRun", "TyphoonSmith", "HurricaneTE", "BreezeForge",
            "GaleForce", "ZephyrSmith", "DraftForge", "CurrentRun", "FlowCraft"
        ]

        var results: [(name: String, score: Int, vip: VIPTier)] = []

        for i in 0..<simCount {
            let name = names[i % names.count] + (i >= names.count ? "\(i)" : "")

            // Score distribution: top players well above, tail well below
            let normalish = rng.nextGaussian()
            let score: Int
            let position = Double(i) / Double(simCount)

            if position < 0.02 {
                // Top 2%: whales who out-grind everyone
                score = Int(Double(baseScore) * (2.5 + abs(normalish) * 1.5))
            } else if position < 0.1 {
                // Top 10%: dedicated grinders
                score = Int(Double(baseScore) * (1.3 + abs(normalish) * 0.8))
            } else if position < 0.5 {
                // Middle 40%: competitive bracket near the player
                score = Int(Double(baseScore) * (0.6 + normalish * 0.35))
            } else {
                // Bottom 50%: casual players
                score = Int(Double(baseScore) * (0.1 + abs(normalish) * 0.25))
            }

            let vip: VIPTier
            if position < 0.02 { vip = [.mythic, .eternal, .chronarch].randomElement()! }
            else if position < 0.1 { vip = [.gold, .diamond, .obsidian].randomElement()! }
            else if position < 0.3 { vip = [.none, .bronze, .silver, .gold].randomElement()! }
            else { vip = [.none, .none, .none, .bronze].randomElement()! }

            results.append((name, max(1, score), vip))
        }

        return results
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

    /// Checks for event transitions. If the current event ended, finalizes
    /// placement for the player and rotates to the next event.
    func checkEventTransition(player: PlayerState?) {
        if currentEvent?.hasEnded == true {
            // Finalize placement before rotating away
            if let player {
                finalizePlacement(player: player)
            }
            leaderboardEntries = []
            localPlayerRank = nil
            localPlayerPercentile = nil
            totalParticipants = 0
        }

        if currentEvent?.hasEnded == true || currentEvent == nil {
            generateSchedule()
        }
    }

    private func activateCurrentEvent() {
        // Timer-based check (no player context — finalization happens via checkEventTransition)
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

// MARK: - Seeded RNG

/// Simple xoshiro256** PRNG for deterministic simulated competitor generation.
private struct SeededRNG: RandomNumberGenerator {
    private var state: (UInt64, UInt64, UInt64, UInt64)

    init(seed: UInt64) {
        // SplitMix64 to expand the seed into 4 state words
        var s = seed
        func next() -> UInt64 {
            s &+= 0x9e3779b97f4a7c15
            var z = s
            z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
            z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
            return z ^ (z >> 31)
        }
        state = (next(), next(), next(), next())
    }

    mutating func next() -> UInt64 {
        let result = rotl(state.1 &* 5, 7) &* 9
        let t = state.1 << 17
        state.2 ^= state.0
        state.3 ^= state.1
        state.1 ^= state.2
        state.0 ^= state.3
        state.2 ^= t
        state.3 = rotl(state.3, 45)
        return result
    }

    private func rotl(_ x: UInt64, _ k: Int) -> UInt64 {
        (x << k) | (x >> (64 - k))
    }

    /// Approximate Gaussian via Box-Muller.
    mutating func nextGaussian() -> Double {
        let u1 = max(1e-10, Double(next()) / Double(UInt64.max))
        let u2 = Double(next()) / Double(UInt64.max)
        return (-2.0 * log(u1)).squareRoot() * cos(2.0 * .pi * u2)
    }
}
