import SwiftUI

struct LiveEventView: View {
    @Environment(LiveEventManager.self) private var eventManager
    @Environment(PlayerState.self) private var player
    @Environment(GameEngine.self) private var engine
    @State private var selectedDay: Int = 0

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

                HStack(spacing: 12) {
                    Image(systemName: pack.isFree ? "gift.fill" : "bag.fill")
                        .font(.title3)
                        .foregroundStyle(pack.isFree ? .green : themeAccent(event.theme))
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pack.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

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
                        Text(pack.price)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(themeAccent(event.theme).opacity(0.15))
                            .foregroundStyle(themeAccent(event.theme))
                            .clipShape(Capsule())
                    }
                }
                .padding(12)
                .background(pack.isFree && !isClaimed ? Color.green.opacity(0.05) : Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
}
