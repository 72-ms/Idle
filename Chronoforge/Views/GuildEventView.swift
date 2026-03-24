import SwiftUI

struct GuildEventView: View {
    @Environment(GuildEventManager.self) private var eventManager
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @State private var selectedDay: Int = 0
    @State private var showContributions: Bool = true

    private var event: GuildEventConfig? { eventManager.currentEvent }
    private var state: GuildEventPlayerState { player.guildEventState }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if guildManager.currentGuild == nil {
                    noGuildView
                } else if let event {
                    guildEventHeader(event)
                    daySelector(event)
                    if selectedDay < event.days.count {
                        dailyChallengeCard(event.days[selectedDay], dayIndex: selectedDay)
                    }
                    leaderboardSection(event)
                    contributionSection(event)
                    guildPlacementRewardsSection(event)
                    contributionRewardsSection(event)
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
            eventManager.buildContributionLeaderboard(player: player)
            Task {
                await eventManager.loadGuildLeaderboard(player: player)
            }
        }
    }

    // MARK: - Header

    private func guildEventHeader(_ event: GuildEventConfig) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title)
                    .foregroundStyle(themeAccent(event.theme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    if let guild = guildManager.currentGuild {
                        Text(guild.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(themeAccent(event.theme).opacity(0.8))
                    }
                }

                Spacer()
            }

            Text(event.description)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text(shortNumber(eventManager.guildTotalScore(player: player)))
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(themeAccent(event.theme))
                    Text("Guild Total")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(spacing: 2) {
                    Text(shortNumber(state.personalPoints))
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("Your Contribution")
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

    private func daySelector(_ event: GuildEventConfig) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(0..<event.days.count, id: \.self) { dayIndex in
                    let day = event.days[dayIndex]
                    let isCurrent = dayIndex == event.currentDayIndex
                    let isSelected = dayIndex == selectedDay
                    let dayPoints = state.personalPointsForDay(dayIndex)

                    Button {
                        selectedDay = dayIndex
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
        let dayPoints = state.personalPointsForDay(dayIndex)

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

            HStack {
                Text("\(dayPoints)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(themeAccent(event!.theme))
                Text("your contribution today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Guild vs Guild Leaderboard

    private func leaderboardSection(_ event: GuildEventConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(themeAccent(event.theme))
                Text("Guild Rankings")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if eventManager.totalGuilds > 0 {
                    Text("\(eventManager.totalGuilds) guilds")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Guild rank summary
            if let rank = eventManager.localGuildRank,
               let pct = eventManager.localGuildPercentile {
                let tier = EventPlacementTier.tier(forPercentile: pct)
                HStack(spacing: 12) {
                    Image(systemName: tier.iconName)
                        .font(.title2)
                        .foregroundStyle(tierColor(tier))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guild Rank #\(rank)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        Text(tier.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tierColor(tier))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(shortNumber(eventManager.guildTotalScore(player: player)))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(themeAccent(event.theme))
                        Text("guild total")
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
            } else if eventManager.guildLeaderboardEntries.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No guild rankings yet")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            // Top guild entries
            ForEach(eventManager.guildLeaderboardEntries.prefix(15)) { entry in
                HStack(spacing: 10) {
                    Text("#\(entry.rank)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(rankColor(entry.rank))
                        .frame(width: 32, alignment: .trailing)

                    Image(systemName: "shield.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(entry.isLocalGuild ? themeAccent(event.theme) : .white.opacity(0.3))

                    Text(entry.guildName)
                        .font(.subheadline.weight(entry.isLocalGuild ? .bold : .regular))
                        .foregroundStyle(entry.isLocalGuild ? themeAccent(event.theme) : .white.opacity(0.8))
                        .lineLimit(1)

                    if entry.isLocalGuild {
                        Text("YOUR GUILD")
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
                .background(entry.isLocalGuild ? themeAccent(event.theme).opacity(0.06) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                Task { await eventManager.loadGuildLeaderboard(player: player) }
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

    // MARK: - Within-Guild Contribution

    private func contributionSection(_ event: GuildEventConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(themeAccent(event.theme))
                Text("Guild Contributions")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if let rank = eventManager.localContributionRank {
                    Text("#\(rank) of \(eventManager.contributionEntries.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeAccent(event.theme).opacity(0.7))
                }
            }

            ForEach(eventManager.contributionEntries) { entry in
                HStack(spacing: 10) {
                    Text("#\(entry.rank)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(contributionRankColor(entry.contributionTier))
                        .frame(width: 24, alignment: .trailing)

                    if entry.contributionTier == .mvp {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                    }

                    if entry.vipTier != .none {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(vipColor(entry.vipTier))
                    }

                    Text(entry.memberName)
                        .font(.caption.weight(entry.isLocalPlayer ? .bold : .regular))
                        .foregroundStyle(entry.isLocalPlayer ? themeAccent(event.theme) : .white.opacity(0.7))
                        .lineLimit(1)

                    if entry.isLocalPlayer {
                        Text("YOU")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(themeAccent(event.theme))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(themeAccent(event.theme).opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Text(shortNumber(entry.score))
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(entry.isLocalPlayer ? themeAccent(event.theme).opacity(0.05) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Guild Placement Rewards

    private func guildPlacementRewardsSection(_ event: GuildEventConfig) -> some View {
        let scale = event.scaleFactor

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.yellow)
                Text("Guild Placement Rewards")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            // Claim banner for completed events
            if let tier = state.guildPlacementTier, !state.claimedGuildPlacementReward {
                claimBanner(
                    title: "Guild Event Complete!",
                    subtitle: tier.displayName,
                    rank: state.finalGuildRank,
                    tier: tier,
                    event: event
                ) {
                    _ = eventManager.claimGuildPlacementReward(player: player)
                }
            } else if state.claimedGuildPlacementReward, let tier = state.guildPlacementTier {
                claimedBadge("\(tier.displayName) guild rewards claimed")
            }

            let guildPct = eventManager.localGuildPercentile
            ForEach(EventPlacementTier.allCases, id: \.rawValue) { tier in
                let isCurrent = guildPct.map { EventPlacementTier.tier(forPercentile: $0) == tier } ?? false
                tierRow(
                    tier: tier,
                    rewards: tier.guildEventRewards(scaleFactor: scale),
                    isCurrentTier: isCurrent
                )
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Contribution Rewards

    private func contributionRewardsSection(_ event: GuildEventConfig) -> some View {
        let scale = event.scaleFactor

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.fill.checkmark")
                    .foregroundStyle(.orange)
                Text("Contribution Rewards")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            // Claim banner
            if let tier = state.contributionTier, !state.claimedContributionReward {
                claimBanner(
                    title: "Your Contribution Rewarded!",
                    subtitle: tier.displayName,
                    rank: state.finalContributionRank,
                    tier: nil,
                    event: event,
                    contributionTier: tier
                ) {
                    _ = eventManager.claimContributionReward(player: player)
                }
            } else if state.claimedContributionReward, let tier = state.contributionTier {
                claimedBadge("\(tier.displayName) contribution rewards claimed")
            }

            let currentContribRank = eventManager.localContributionRank
            let totalMembers = eventManager.contributionEntries.count
            ForEach(GuildContributionTier.allCases, id: \.rawValue) { tier in
                let isCurrent = currentContribRank.map {
                    GuildContributionTier.tier(forRank: $0, totalMembers: totalMembers) == tier
                } ?? false

                HStack(spacing: 10) {
                    Image(systemName: tier.iconName)
                        .font(.caption)
                        .foregroundStyle(isCurrent ? contributionRankColor(tier) : .white.opacity(0.4))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(tier.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isCurrent ? contributionRankColor(tier) : .white.opacity(0.7))

                            if isCurrent {
                                Text("YOU")
                                    .font(.system(size: 7, weight: .heavy))
                                    .foregroundStyle(contributionRankColor(tier))
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(contributionRankColor(tier).opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(tier.rewards(scaleFactor: scale).map(\.displayText).joined(separator: ", "))
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isCurrent ? contributionRankColor(tier).opacity(0.06) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Shared Components

    private func claimBanner(title: String, subtitle: String, rank: Int?, tier: EventPlacementTier?, event: GuildEventConfig, contributionTier: GuildContributionTier? = nil, action: @escaping () -> Void) -> some View {
        let color: Color = tier.map { tierColor($0) } ?? contributionRankColor(contributionTier ?? .participant)

        return VStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            HStack {
                Image(systemName: tier?.iconName ?? contributionTier?.iconName ?? "star.fill")
                    .font(.title)
                    .foregroundStyle(color)
                VStack(alignment: .leading) {
                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
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
                    .background(color.opacity(0.2))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }

    private func claimedBadge(_ text: String) -> some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.green.opacity(0.8))
        }
        .padding(10)
    }

    private func tierRow(tier: EventPlacementTier, rewards: [LiveEventReward], isCurrentTier: Bool) -> some View {
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
                        Text("YOUR GUILD")
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
            Text("Upcoming Guild Events")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(eventManager.upcomingEvents) { upcoming in
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
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

    // MARK: - Empty States

    private var noGuildView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text("Join a Guild First")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text("You need to be in a guild to participate in guild events.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var noEventView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text("No Active Guild Event")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text("Guild events run regularly — check back soon!")
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

    private func tierColor(_ tier: EventPlacementTier) -> Color {
        switch tier {
        case .top1:   return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .top5:   return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .top10:  return Color(red: 0.80, green: 0.50, blue: 0.20)
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

    private func contributionRankColor(_ tier: GuildContributionTier) -> Color {
        switch tier {
        case .mvp:            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .topContributor: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .strong:         return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .active:         return .cyan
        case .participant:    return .gray
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
}
