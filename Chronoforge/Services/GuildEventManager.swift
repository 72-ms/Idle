import Foundation

@Observable
final class GuildEventManager {

    // MARK: - State

    private(set) var currentEvent: GuildEventConfig?
    private(set) var upcomingEvents: [GuildEventConfig] = []

    /// Guild vs guild leaderboard.
    private(set) var guildLeaderboardEntries: [GuildEventLeaderboardEntry] = []
    private(set) var localGuildRank: Int?
    private(set) var localGuildPercentile: Double?
    private(set) var totalGuilds: Int = 0

    /// Within-guild contribution leaderboard.
    private(set) var contributionEntries: [GuildContributionEntry] = []
    private(set) var localContributionRank: Int?

    /// References set by AppState.
    var leaderboardManager: LeaderboardManager?
    var guildManager: GuildManager?

    /// Callback for delivering rewards.
    var onReward: ((LiveEventReward) -> Void)?

    private var checkTimer: Timer?

    // MARK: - Init

    init() {
        generateSchedule()
        activateCurrentEvent()
    }

    // MARK: - Schedule Generation

    /// Guild events alternate with solo events — offset by ~3 days.
    /// Shorter (3-5 days) to keep pressure high.
    private func generateSchedule() {
        let calendar = Calendar.current
        let now = Date()

        var weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart) ?? weekStart

        let themes = LiveEventTheme.allCases
        var events: [GuildEventConfig] = []
        // Offset guild events by 3 days from solo events
        var eventDate = calendar.date(byAdding: .day, value: -4, to: weekStart)!

        for i in 0..<12 {
            let theme = themes[(i + 3) % themes.count]  // Different theme rotation than solo
            let duration = [3, 4, 5][i % 3]
            let eventStart = eventDate
            let eventEnd = calendar.date(byAdding: .day, value: duration, to: eventStart)!

            let event = buildEvent(index: i, theme: theme, start: eventStart, end: eventEnd, duration: duration)
            events.append(event)

            // Guild events have bigger gaps (2-3 days between)
            let gap = i % 3 == 2 ? 3 : 2
            eventDate = calendar.date(byAdding: .day, value: gap, to: eventEnd)!
        }

        let active = events.filter { $0.isActive }
        let upcoming = events.filter { !$0.isActive && !$0.hasEnded }

        currentEvent = active.first
        upcomingEvents = Array(upcoming.prefix(3))
    }

    private func buildEvent(index: Int, theme: LiveEventTheme, start: Date, end: Date, duration: Int) -> GuildEventConfig {
        let challenges = theme.dailyChallenges
        let scaleFactor = max(1, index / 3 + 1)

        var days: [LiveEventDay] = []
        for d in 0..<duration {
            let challenge = challenges[d % challenges.count]
            let bonusMult: Decimal = d == duration - 1 ? 2 : 1

            let milestones = LiveEventManager.generateDailyMilestones(
                for: challenge, dayIndex: d, scaleFactor: scaleFactor
            )

            days.append(LiveEventDay(
                id: d,
                challengeType: challenge,
                bonusMultiplier: bonusMult,
                milestones: milestones
            ))
        }

        let eventId = "guild_\(theme.rawValue)_\(index)"
        return GuildEventConfig(
            id: eventId,
            name: "Guild \(theme.displayName)",
            description: guildEventDescription(for: theme),
            theme: theme,
            startDate: start,
            endDate: end,
            days: days
        )
    }

    // MARK: - Point Calculation

    /// Calculates the local player's personal contribution for the current day.
    func calculateDayPoints(player: PlayerState, eventState: GuildEventPlayerState) -> Int {
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

        if let cap = challenge.dailyPointCap {
            rawPoints = min(rawPoints, cap)
        }

        return Int(Decimal(rawPoints) * day.bonusMultiplier)
    }

    /// Updates the player's guild event contribution.
    func updateProgress(player: PlayerState) {
        guard let event = currentEvent,
              let dayIndex = event.currentDayIndex else { return }
        guard guildManager?.currentGuild != nil else { return }

        // Ensure snapshot for today
        if player.guildEventState.dayStartSnapshots[dayIndex] == nil {
            player.guildEventState.dayStartSnapshots[dayIndex] = DayStartSnapshot.capture(from: player)
        }

        // Initialize for new event
        if player.guildEventState.activeGuildEventId != event.id {
            player.guildEventState.reset(for: event.id)
            player.guildEventState.dayStartSnapshots[dayIndex] = DayStartSnapshot.capture(from: player)
        }

        let dayPoints = calculateDayPoints(player: player, eventState: player.guildEventState)
        let previousDayPoints = player.guildEventState.personalPointsForDay(dayIndex)

        if dayPoints > previousDayPoints {
            let delta = dayPoints - previousDayPoints
            player.guildEventState.dailyPersonalPoints[dayIndex] = dayPoints
            player.guildEventState.personalPoints += delta

            // Submit guild total to leaderboard
            submitGuildScore(player: player)
        }
    }

    // MARK: - Guild Score

    /// The guild's total score = local player's points + simulated contributions from guild members.
    func guildTotalScore(player: PlayerState) -> Int {
        guard let guild = guildManager?.currentGuild else { return 0 }

        let personalContribution = player.guildEventState.personalPoints

        // Mock member contributions scale with guild level and member count
        let mockMembers = guild.members.filter { $0.id != guild.leaderProfileId }
        var mockTotal = 0
        for member in mockMembers {
            // Each mock member contributes a fraction of the player's output,
            // weighted by their VIP tier and activity
            let activityFactor = member.lastActive.timeIntervalSince(Date()) > -86400 ? 0.8 : 0.3
            let vipFactor = 1.0 + Double(member.vipTier.rawValue) * 0.15
            let baseContribution = Double(max(1, personalContribution)) * 0.3 * activityFactor * vipFactor
            mockTotal += Int(baseContribution)
        }

        return personalContribution + mockTotal
    }

    private func submitGuildScore(player: PlayerState) {
        guard let event = currentEvent else { return }
        let score = guildTotalScore(player: player)
        guard score > 0 else { return }
        leaderboardManager?.submitScore(score, to: event.leaderboardID)

        if let dayIndex = event.currentDayIndex {
            let dayScore = player.guildEventState.personalPointsForDay(dayIndex)
            if dayScore > 0 {
                leaderboardManager?.submitScore(dayScore, to: event.dailyLeaderboardID(dayIndex: dayIndex))
            }
        }
    }

    // MARK: - Guild vs Guild Leaderboard

    func loadGuildLeaderboard(player: PlayerState) async {
        guard let event = currentEvent else { return }
        guard let lbManager = leaderboardManager else {
            await MainActor.run {
                self.guildLeaderboardEntries = []
                self.localGuildRank = nil
                self.localGuildPercentile = nil
                self.totalGuilds = 0
            }
            return
        }

        await lbManager.loadEntries(for: event.leaderboardID)
        let gcEntries = lbManager.leaderboardEntries

        let total = gcEntries.count
        var entries: [GuildEventLeaderboardEntry] = []
        var guildRank: Int?
        var guildPct: Double?

        for entry in gcEntries {
            let percentile = total > 0 ? Double(entry.rank) / Double(total) * 100.0 : 100.0
            let tier = EventPlacementTier.tier(forPercentile: percentile)

            entries.append(GuildEventLeaderboardEntry(
                id: entry.isLocalPlayer ? "local_guild" : "guild_\(entry.rank)",
                rank: entry.rank,
                guildName: entry.playerName,  // GC displays guild name as player name
                guildLevel: 0,
                score: entry.score,
                memberCount: 0,
                isLocalGuild: entry.isLocalPlayer,
                placementTier: tier
            ))

            if entry.isLocalPlayer {
                guildRank = entry.rank
                guildPct = percentile
            }
        }

        await MainActor.run {
            self.guildLeaderboardEntries = entries
            self.localGuildRank = guildRank
            self.localGuildPercentile = guildPct
            self.totalGuilds = total
        }
    }

    // MARK: - Contribution Leaderboard (Within Guild)

    /// Builds the within-guild contribution ranking. Includes mock member simulated contributions.
    func buildContributionLeaderboard(player: PlayerState) {
        guard let guild = guildManager?.currentGuild else {
            contributionEntries = []
            localContributionRank = nil
            return
        }

        let personalPoints = player.guildEventState.personalPoints

        var entries: [(id: UUID, name: String, score: Int, isLocal: Bool, vip: VIPTier)] = []

        // Local player
        entries.append((player.profileId, player.displayName, personalPoints, true, .none))

        // Mock members
        for member in guild.members where member.id != guild.leaderProfileId {
            let activityFactor = member.lastActive.timeIntervalSince(Date()) > -86400 ? 0.8 : 0.3
            let vipFactor = 1.0 + Double(member.vipTier.rawValue) * 0.15
            let contribution = Int(Double(max(1, personalPoints)) * 0.3 * activityFactor * vipFactor)
            entries.append((member.id, member.displayName, contribution, false, member.vipTier))
        }

        entries.sort { $0.score > $1.score }

        let total = entries.count
        var mapped: [GuildContributionEntry] = []
        var playerRank: Int?

        for (i, entry) in entries.enumerated() {
            let rank = i + 1
            let tier = GuildContributionTier.tier(forRank: rank, totalMembers: total)

            mapped.append(GuildContributionEntry(
                id: entry.id,
                rank: rank,
                memberName: entry.name,
                score: entry.score,
                isLocalPlayer: entry.isLocal,
                vipTier: entry.vip,
                contributionTier: tier
            ))

            if entry.isLocal {
                playerRank = rank
            }
        }

        contributionEntries = mapped
        localContributionRank = playerRank
    }

    // MARK: - Finalization & Reward Claiming

    func finalizeEventPlacement(player: PlayerState) {
        guard player.guildEventState.finalGuildRank == nil else { return }
        guard player.guildEventState.personalPoints > 0 else { return }

        player.guildEventState.finalGuildRank = localGuildRank
        player.guildEventState.finalGuildPercentile = localGuildPercentile

        player.guildEventState.finalContributionRank = localContributionRank
        player.guildEventState.finalContributionTotalMembers = contributionEntries.count
    }

    func claimGuildPlacementReward(player: PlayerState) -> Bool {
        guard let tier = player.guildEventState.guildPlacementTier else { return false }
        guard !player.guildEventState.claimedGuildPlacementReward else { return false }

        let scaleFactor = currentEvent?.scaleFactor ?? 1
        for reward in tier.guildEventRewards(scaleFactor: scaleFactor) {
            deliverReward(reward, to: player)
        }

        player.guildEventState.claimedGuildPlacementReward = true
        return true
    }

    func claimContributionReward(player: PlayerState) -> Bool {
        guard let tier = player.guildEventState.contributionTier else { return false }
        guard !player.guildEventState.claimedContributionReward else { return false }

        let scaleFactor = currentEvent?.scaleFactor ?? 1
        for reward in tier.rewards(scaleFactor: scaleFactor) {
            deliverReward(reward, to: player)
        }

        player.guildEventState.claimedContributionReward = true
        return true
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
            player.guildEventState.personalPoints += n
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

    func checkEventTransition(player: PlayerState?) {
        if let event = currentEvent, event.hasEnded {
            if let player {
                finalizeEventPlacement(player: player)
            }
            guildLeaderboardEntries = []
            localGuildRank = nil
            localGuildPercentile = nil
            totalGuilds = 0
            contributionEntries = []
            localContributionRank = nil
        }

        if currentEvent?.hasEnded == true || currentEvent == nil {
            generateSchedule()
        }
    }

    private func activateCurrentEvent() {
        if currentEvent?.hasEnded == true || currentEvent == nil {
            generateSchedule()
        }
    }

    // MARK: - Helpers

    private func guildEventDescription(for theme: LiveEventTheme) -> String {
        switch theme {
        case .chronoSurge:
            return "Unite your guild to harness a surge of temporal energy! Every member's production counts toward your guild's total."
        case .forgeInferno:
            return "Your guild's forges burn as one! Coordinate relic forging and material gathering to outpace rival guilds."
        case .temporalStorm:
            return "A storm challenges all guilds! Push prestiges and epochs together to prove your guild's dominance."
        case .harvestMoon:
            return "The harvest moon empowers guilds! Collectively gather resources to claim the top guild rewards."
        case .voidRift:
            return "A rift threatens all guilds! Only the strongest guilds working together will conquer its challenges."
        case .cosmicDawn:
            return "A new dawn rises for all guilds! Diverse daily challenges test your guild's versatility."
        }
    }
}
