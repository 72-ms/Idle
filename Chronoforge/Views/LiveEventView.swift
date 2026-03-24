import SwiftUI

struct LiveEventView: View {
    @Environment(LiveEventManager.self) private var eventManager
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store
    @Environment(GameEngine.self) private var engine
    @State private var selectedDay: Int = 0
    @State private var showDailyLeaderboard: Bool = true

    private var event: LiveEventConfig? { eventManager.currentEvent }
    private var state: LiveEventPlayerState { player.liveEventState }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let event {
                    eventHeader(event)
                    daySelector(event)
                    if selectedDay < event.days.count {
                        dailyChallengeCard(event.days[selectedDay], dayIndex: selectedDay)
                        dailyMilestonesSection(event.days[selectedDay], dayIndex: selectedDay)
                    }
                    totalMilestonesSection(event)
                    leaderboardSection(event)
                    placementRewardsSection(event)
                    eventPacksSection(event)
                    if !eventManager.upcomingEvents.isEmpty {
                        upcomingSection
                    }
                } else {
                    noEventView
                }
            }
            .padding()
        }
        .onAppear {
            if let event, let dayIdx = event.currentDayIndex {
                selectedDay = dayIdx
            }
            Task {
                await eventManager.loadLeaderboard(player: player)
                if let dayIdx = event?.currentDayIndex {
                    await eventManager.loadDailyLeaderboard(dayIndex: dayIdx)
                }
            }
        }
    }

    // MARK: - Header

    private func eventHeader(_ event: LiveEventConfig) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: event.theme.iconName)
                    .font(.title)
                    .foregroundStyle(themeAccent(event.theme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(event.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("\(state.totalPoints)")
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(themeAccent(event.theme))
                    Text("Total Points")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 2) {
                    Text(timeString(event.timeRemaining))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.orange)
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 2) {
                    Text("Day \((event.currentDayIndex ?? 0) + 1)/\(event.duration)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Progress")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(themeAccent(event.theme).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(themeAccent(event.theme).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Day Selector

    private func daySelector(_ event: LiveEventConfig) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(0..<event.days.count, id: \.self) { dayIndex in
                    let day = event.days[dayIndex]
                    let isCurrent = dayIndex == event.currentDayIndex
                    let isSelected = dayIndex == selectedDay
                    let dayPoints = state.pointsForDay(dayIndex)

                    Button {
                        selectedDay = dayIndex
                        if showDailyLeaderboard {
                            Task { await eventManager.loadDailyLeaderboard(dayIndex: dayIndex) }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("Day \(dayIndex + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))

                            Image(systemName: day.challengeType.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(isSelected ? themeAccent(event.theme) : .white.opacity(0.4))

                            if dayPoints > 0 {
                                Text(shortNumber(dayPoints))
                                    .font(.system(size: 8, weight: .bold).monospacedDigit())
                                    .foregroundStyle(themeAccent(event.theme).opacity(0.8))
                            }

                            if day.bonusMultiplier > 1 {
                                Text("\(NSDecimalNumber(decimal: day.bonusMultiplier))x")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .frame(width: 52, height: 65)
                        .background(isSelected ? themeAccent(event.theme).opacity(0.15) : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isCurrent ? themeAccent(event.theme).opacity(0.6) : Color.clear,
                                    lineWidth: isCurrent ? 2 : 0
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Daily Challenge Card

    private func dailyChallengeCard(_ day: LiveEventDay, dayIndex: Int) -> some View {
        let isToday = dayIndex == event?.currentDayIndex
        let dayPoints = state.pointsForDay(dayIndex)

        return VStack(spacing: 12) {
            HStack {
                Image(systemName: day.challengeType.iconName)
                    .font(.title2)
                    .foregroundStyle(themeAccent(event!.theme))

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(day.challengeType.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)

                        if isToday {
                            Text("TODAY")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        if day.bonusMultiplier > 1 {
                            Text("\(NSDecimalNumber(decimal: day.bonusMultiplier))x BONUS")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(.yellow.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(day.challengeType.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }

            // Points display with cap indicator
            HStack {
                Text("\(dayPoints)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(themeAccent(event!.theme))

                if let cap = day.challengeType.dailyPointCap {
                    let effectiveCap = Int(Decimal(cap) * day.bonusMultiplier)
                    let atCap = dayPoints >= effectiveCap
                    Text("/ \(shortNumber(effectiveCap))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(atCap ? .green.opacity(0.7) : .white.opacity(0.4))

                    if atCap {
                        Text("MAXED")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                } else {
                    Text("points today")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Daily Milestones

    private func dailyMilestonesSection(_ day: LiveEventDay, dayIndex: Int) -> some View {
        let dayPoints = state.pointsForDay(dayIndex)
        let claimed = state.claimedDailyMilestones[dayIndex] ?? []

        return VStack(alignment: .leading, spacing: 10) {
            Text("Daily Milestones")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(day.milestones) { milestone in
                let isReached = dayPoints >= milestone.points
                let isClaimed = claimed.contains(milestone.id)

                HStack(spacing: 12) {
                    // Progress indicator
                    ZStack {
                        Circle()
                            .fill(isClaimed ? .green.opacity(0.2) : (isReached ? themeAccent(event!.theme).opacity(0.2) : Color.white.opacity(0.05)))
                            .frame(width: 32, height: 32)

                        if isClaimed {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: milestone.reward.iconName)
                                .font(.caption)
                                .foregroundStyle(isReached ? themeAccent(event!.theme) : .white.opacity(0.3))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(milestone.displayPoints) pts")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isReached ? .white : .white.opacity(0.5))
                        Text(milestone.reward.displayText)
                            .font(.caption)
                            .foregroundStyle(isReached ? themeAccent(event!.theme).opacity(0.8) : .white.opacity(0.4))
                    }

                    Spacer()

                    if isClaimed {
                        Text("Claimed")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green.opacity(0.7))
                    } else if isReached {
                        Button {
                            _ = eventManager.claimDailyMilestone(milestoneId: milestone.id, dayIndex: dayIndex, player: player)
                        } label: {
                            Text("Claim")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(themeAccent(event!.theme).opacity(0.2))
                                .foregroundStyle(themeAccent(event!.theme))
                                .clipShape(Capsule())
                        }
                    } else {
                        // Progress bar
                        let progress = min(1.0, Double(dayPoints) / Double(milestone.points))
                        Text("\(Int(progress * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(10)
                .background(isReached && !isClaimed ? themeAccent(event!.theme).opacity(0.05) : Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Total Event Milestones

    private func totalMilestonesSection(_ event: LiveEventConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Event Milestones")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(state.totalPoints) total pts")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(themeAccent(event.theme).opacity(0.7))
            }

            ForEach(event.totalMilestones) { milestone in
                let isReached = state.totalPoints >= milestone.totalPoints
                let isClaimed = state.claimedTotalMilestones.contains(milestone.id)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isClaimed ? .green.opacity(0.2) : (isReached ? themeAccent(event.theme).opacity(0.2) : Color.white.opacity(0.05)))
                            .frame(width: 32, height: 32)

                        if isClaimed {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        } else if milestone.isExclusive {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(isReached ? .yellow : .white.opacity(0.3))
                        } else {
                            Image(systemName: milestone.reward.iconName)
                                .font(.caption)
                                .foregroundStyle(isReached ? themeAccent(event.theme) : .white.opacity(0.3))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(milestone.displayPoints) pts")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(isReached ? .white : .white.opacity(0.5))
                            if milestone.isExclusive {
                                Text("EXCLUSIVE")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(.yellow.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(milestone.reward.displayText)
                            .font(.caption)
                            .foregroundStyle(isReached ? themeAccent(event.theme).opacity(0.8) : .white.opacity(0.4))
                    }

                    Spacer()

                    if isClaimed {
                        Text("Claimed")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green.opacity(0.7))
                    } else if isReached {
                        Button {
                            _ = eventManager.claimTotalMilestone(milestoneId: milestone.id, player: player)
                        } label: {
                            Text("Claim")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(themeAccent(event.theme).opacity(0.2))
                                .foregroundStyle(themeAccent(event.theme))
                                .clipShape(Capsule())
                        }
                    } else {
                        let progress = min(1.0, Double(state.totalPoints) / Double(milestone.totalPoints))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 50, height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(themeAccent(event.theme).opacity(0.4))
                                    .frame(width: 50 * progress, height: 6)
                            }
                        }
                        .frame(width: 50, height: 6)
                    }
                }
                .padding(10)
                .background(milestone.isExclusive ? Color.yellow.opacity(0.03) : Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Event Packs

    private func eventPacksSection(_ event: LiveEventConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event Packs")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(event.packs) { pack in
                let isClaimed = state.claimedPacks.contains(pack.id)
                let isWhale = pack.tier >= 5

                VStack(spacing: 0) {
                    // Badge banner for featured packs
                    if let badge = pack.badge, !isClaimed {
                        Text(badge)
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                            .background(
                                isWhale
                                ? LinearGradient(colors: [.orange, .yellow, .orange], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [themeAccent(event.theme), themeAccent(event.theme).opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                    }

                    HStack(spacing: 12) {
                        Image(systemName: pack.isFree ? "gift.fill" : (isWhale ? "crown.fill" : "bag.fill"))
                            .font(.title3)
                            .foregroundStyle(pack.isFree ? .green : (isWhale ? .yellow : themeAccent(event.theme)))
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(isWhale ? .yellow : .white)

                            Text(pack.rewards.map(\.displayText).joined(separator: " + "))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(2)
                        }

                        Spacer()

                        if isClaimed {
                            Text("Claimed")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green.opacity(0.7))
                        } else if pack.isFree {
                            Button {
                                _ = eventManager.claimPack(packId: pack.id, player: player)
                            } label: {
                                Text("FREE")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    } else {
                        Button {
                            Task {
                                await purchasePack(pack)
                            }
                        } label: {
                            Text(pack.price)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isWhale ? Color.yellow.opacity(0.2) : themeAccent(event.theme).opacity(0.15))
                                .foregroundStyle(isWhale ? .yellow : themeAccent(event.theme))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(12)
                .background(
                    isWhale && !isClaimed
                    ? Color.yellow.opacity(0.04)
                    : (pack.isFree && !isClaimed ? Color.green.opacity(0.05) : Color.white.opacity(0.03))
                )
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    isWhale && !isClaimed
                    ? RoundedRectangle(cornerRadius: 12).strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                    : nil
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Leaderboard

    private func leaderboardSection(_ event: LiveEventConfig) -> some View {
        let entries = showDailyLeaderboard ? eventManager.dailyLeaderboardEntries : eventManager.leaderboardEntries
        let playerRank = showDailyLeaderboard ? eventManager.dailyPlayerRank : eventManager.localPlayerRank
        let playerPct = showDailyLeaderboard ? eventManager.dailyPlayerPercentile : eventManager.localPlayerPercentile
        let participants = showDailyLeaderboard ? eventManager.dailyTotalParticipants : eventManager.totalParticipants

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundStyle(themeAccent(event.theme))
                Text("Leaderboard")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if participants > 0 {
                    Text("\(participants) players")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Daily / Event toggle
            HStack(spacing: 0) {
                Button {
                    showDailyLeaderboard = true
                    Task { await eventManager.loadDailyLeaderboard(dayIndex: selectedDay) }
                } label: {
                    Text("Day \(selectedDay + 1)")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(showDailyLeaderboard ? themeAccent(event.theme).opacity(0.15) : Color.white.opacity(0.05))
                        .foregroundStyle(showDailyLeaderboard ? themeAccent(event.theme) : .white.opacity(0.5))
                }
                Button {
                    showDailyLeaderboard = false
                    Task { await eventManager.loadLeaderboard(player: player) }
                } label: {
                    Text("Overall")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!showDailyLeaderboard ? themeAccent(event.theme).opacity(0.15) : Color.white.opacity(0.05))
                        .foregroundStyle(!showDailyLeaderboard ? themeAccent(event.theme) : .white.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Player rank summary
            if let rank = playerRank, let pct = playerPct {
                let tier = EventPlacementTier.tier(forPercentile: pct)
                let score = showDailyLeaderboard ? state.pointsForDay(selectedDay) : state.totalPoints
                HStack(spacing: 12) {
                    Image(systemName: tier.iconName)
                        .font(.title2)
                        .foregroundStyle(tierColor(tier))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rank #\(rank)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        Text(tier.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tierColor(tier))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(shortNumber(score))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(themeAccent(event.theme))
                        Text(showDailyLeaderboard ? "today" : "total")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(12)
                .background(tierColor(tier).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(tierColor(tier).opacity(0.2), lineWidth: 1)
                )
            } else if entries.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No rankings yet")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Earn points to appear on the leaderboard!")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            // Top entries
            let topEntries = Array(entries.prefix(25))
            ForEach(topEntries) { entry in
                leaderboardRow(entry, event: event)
            }

            // Show player's position if outside top entries
            if let rank = playerRank, rank > 25 {
                HStack {
                    Spacer()
                    Text("...")
                        .foregroundStyle(.white.opacity(0.2))
                    Spacer()
                }

                if let localEntry = entries.first(where: { $0.isLocalPlayer }) {
                    leaderboardRow(localEntry, event: event)
                }
            }

            // Refresh button
            Button {
                Task {
                    if showDailyLeaderboard {
                        await eventManager.loadDailyLeaderboard(dayIndex: selectedDay)
                    } else {
                        await eventManager.loadLeaderboard(player: player)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(themeAccent(event.theme).opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func leaderboardRow(_ entry: EventLeaderboardEntry, event: LiveEventConfig) -> some View {
        HStack(spacing: 10) {
            Text("#\(entry.rank)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(rankColor(entry.rank))
                .frame(width: 32, alignment: .trailing)

            if entry.vipTier != .none {
                Image(systemName: "crown.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(vipColor(entry.vipTier))
            }

            Text(entry.playerName)
                .font(.subheadline.weight(entry.isLocalPlayer ? .bold : .regular))
                .foregroundStyle(entry.isLocalPlayer ? themeAccent(event.theme) : .white.opacity(0.8))
                .lineLimit(1)

            if entry.isLocalPlayer {
                Text("YOU")
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundStyle(themeAccent(event.theme))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(themeAccent(event.theme).opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(shortNumber(entry.score))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(entry.isLocalPlayer ? themeAccent(event.theme).opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Placement Rewards

    private func placementRewardsSection(_ event: LiveEventConfig) -> some View {
        let scale = event.scaleFactor

        return VStack(alignment: .leading, spacing: 14) {
            // MARK: Daily Placement Rewards
            dailyPlacementSection(event, scale: scale)

            // MARK: Event Placement Rewards
            eventPlacementSection(event, scale: scale)
        }
    }

    private func dailyPlacementSection(_ event: LiveEventConfig, scale: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(themeAccent(event.theme))
                Text("Daily Ranking Rewards")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Day \(selectedDay + 1)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Claimable daily reward for completed days
            let dayFinalized = state.dailyPercentiles[selectedDay] != nil
            let dayClaimed = state.claimedDailyPlacementRewards.contains(selectedDay)

            if dayFinalized, let tier = state.dailyPlacementTier(dayIndex: selectedDay) {
                if !dayClaimed {
                    claimBanner(
                        title: "Day \(selectedDay + 1) Complete!",
                        tier: tier,
                        rank: state.dailyRanks[selectedDay],
                        event: event
                    ) {
                        _ = eventManager.claimDailyPlacementReward(dayIndex: selectedDay, player: player)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Day \(selectedDay + 1): \(tier.displayName) rewards claimed")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                    .padding(10)
                }
            }

            // Daily tier breakdown
            let dailyPct = eventManager.dailyPlayerPercentile
            ForEach(EventPlacementTier.allCases, id: \.rawValue) { tier in
                let isCurrentTier = dailyPct.map { EventPlacementTier.tier(forPercentile: $0) == tier } ?? false

                placementTierRow(
                    tier: tier,
                    rewards: tier.dailyRewards(scaleFactor: scale),
                    isCurrentTier: isCurrentTier,
                    event: event
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eventPlacementSection(_ event: LiveEventConfig, scale: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Event Ranking Rewards")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            // Claimable event reward
            if let tier = state.placementTier, !state.claimedPlacementReward {
                claimBanner(
                    title: "Event Complete!",
                    tier: tier,
                    rank: state.finalRank,
                    event: event
                ) {
                    _ = eventManager.claimPlacementReward(player: player)
                }
            } else if state.claimedPlacementReward, let tier = state.placementTier {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("\(tier.displayName) rewards claimed")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green.opacity(0.8))
                }
                .padding(10)
            }

            // Event tier breakdown — the big prizes
            let eventPct = eventManager.localPlayerPercentile
            ForEach(EventPlacementTier.allCases, id: \.rawValue) { tier in
                let isCurrentTier = eventPct.map { EventPlacementTier.tier(forPercentile: $0) == tier } ?? false

                placementTierRow(
                    tier: tier,
                    rewards: tier.eventRewards(scaleFactor: scale),
                    isCurrentTier: isCurrentTier,
                    event: event
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func claimBanner(title: String, tier: EventPlacementTier, rank: Int?, event: LiveEventConfig, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            HStack {
                Image(systemName: tier.iconName)
                    .font(.title)
                    .foregroundStyle(tierColor(tier))
                VStack(alignment: .leading) {
                    Text(tier.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tierColor(tier))
                    if let rank {
                        Text("Rank #\(rank)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            Button(action: action) {
                Text("Claim Rewards")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(tierColor(tier).opacity(0.2))
                    .foregroundStyle(tierColor(tier))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(tierColor(tier).opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(tierColor(tier).opacity(0.3), lineWidth: 1)
        )
    }

    private func placementTierRow(tier: EventPlacementTier, rewards: [LiveEventReward], isCurrentTier: Bool, event: LiveEventConfig) -> some View {
        HStack(spacing: 10) {
            Image(systemName: tier.iconName)
                .font(.caption)
                .foregroundStyle(tierColor(tier))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(tier.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isCurrentTier ? tierColor(tier) : .white.opacity(0.7))

                    if isCurrentTier {
                        Text("YOU")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(tierColor(tier))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(tierColor(tier).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(rewards.map(\.displayText).joined(separator: ", "))
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(isCurrentTier ? tierColor(tier).opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Upcoming Events

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coming Up")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(eventManager.upcomingEvents) { upcoming in
                HStack(spacing: 12) {
                    Image(systemName: upcoming.theme.iconName)
                        .font(.title3)
                        .foregroundStyle(themeAccent(upcoming.theme).opacity(0.6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(upcoming.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Starts \(relativeDate(upcoming.startDate))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Text("\(upcoming.duration) days")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(10)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - No Event

    private var noEventView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text("No Active Event")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text("Check back soon — events run continuously!")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))

            if !eventManager.upcomingEvents.isEmpty {
                upcomingSection
            }
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func themeAccent(_ theme: LiveEventTheme) -> Color {
        switch theme {
        case .chronoSurge: return .cyan
        case .forgeInferno: return .orange
        case .temporalStorm: return .purple
        case .harvestMoon: return Color(red: 0.9, green: 0.75, blue: 0.3)
        case .voidRift: return Color(red: 0.6, green: 0.2, blue: 0.8)
        case .cosmicDawn: return Color(red: 0.9, green: 0.5, blue: 0.7)
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func shortNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    private func relativeDate(_ date: Date) -> String {
        let days = Int(date.timeIntervalSince(Date()) / 86400)
        if days <= 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days) days"
    }

    private func tierColor(_ tier: EventPlacementTier) -> Color {
        switch tier {
        case .top1:   return Color(red: 1.0, green: 0.84, blue: 0.0)  // Gold
        case .top5:   return Color(red: 0.75, green: 0.75, blue: 0.78) // Silver
        case .top10:  return Color(red: 0.80, green: 0.50, blue: 0.20) // Bronze
        case .top25:  return .blue
        case .top50:  return .green
        case .top100: return .gray
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:    return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2:    return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3:    return Color(red: 0.80, green: 0.50, blue: 0.20)
        case 4...10: return .white.opacity(0.7)
        default:   return .white.opacity(0.4)
        }
    }

    private func vipColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .none:      return .clear
        case .bronze:    return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver:    return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold:      return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .diamond:   return .cyan
        case .obsidian:  return Color(red: 0.2, green: 0.2, blue: 0.3)
        case .mythic:    return .purple
        case .eternal:   return Color(red: 0.9, green: 0.5, blue: 0.9)
        case .celestial: return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .chronarch: return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
    }

    private func purchasePack(_ pack: LiveEventPack) async {
        guard let productId = eventManager.productId(for: pack.id) else { return }

        // Find the StoreKit product matching this event pack
        guard let product = store.products.first(where: { $0.id == productId }) else {
            // Product not loaded from App Store — fall through silently
            return
        }

        let success = await store.purchase(product)
        if success {
            _ = eventManager.deliverPaidPack(packId: pack.id, player: player)
        }
    }
}
