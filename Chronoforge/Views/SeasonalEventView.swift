import SwiftUI

struct SeasonalEventView: View {
    @Environment(PlayerState.self) private var player
    @Environment(GameEngine.self) private var engine

    private var currentEvent: SeasonalEvent? {
        SeasonalEventSystem.currentEvent()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Seasonal Events")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                if let event = currentEvent {
                    activeEventCard(event)
                    eventProgressSection(event)
                    eventRewardsSection(event)
                } else {
                    noEventView
                }

                // Upcoming events
                upcomingEventsSection
            }
            .padding()
        }
    }

    // MARK: - Active Event

    private func activeEventCard(_ event: SeasonalEvent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: themeIcon(for: event.theme))
                    .font(.title)
                    .foregroundStyle(themeColor(for: event.theme))

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(event.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(3)
                }
            }

            HStack(spacing: 16) {
                Label("\(NSDecimalNumber(decimal: event.bonusMultiplier))x Production", systemImage: "bolt.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)

                Label(timeRemaining(until: event.endDate), systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .background(themeColor(for: event.theme).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(themeColor(for: event.theme).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Progress

    private func eventProgressSection(_ event: SeasonalEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event Currency")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Image(systemName: themeIcon(for: event.theme))
                    .font(.title2)
                    .foregroundStyle(themeColor(for: event.theme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.specialCurrency)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("\(player.seasonalEventState.earnedCurrency) earned")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Rewards

    private func eventRewardsSection(_ event: SeasonalEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Exclusive Cosmetics")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(event.exclusiveCosmetics, id: \.self) { cosmeticId in
                let isClaimed = player.seasonalEventState.claimedRewards.contains(cosmeticId)
                HStack(spacing: 12) {
                    Image(systemName: isClaimed ? "checkmark.circle.fill" : "gift.fill")
                        .font(.title3)
                        .foregroundStyle(isClaimed ? .green : themeColor(for: event.theme))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cosmeticId.replacingOccurrences(of: "cosmetic_", with: "")
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)

                        Text(isClaimed ? "Claimed" : "Earn event currency to unlock")
                            .font(.caption)
                            .foregroundStyle(isClaimed ? .green.opacity(0.7) : .white.opacity(0.5))
                    }

                    Spacer()

                    if !isClaimed {
                        let cost = cosmeticCost(for: cosmeticId, in: event)
                        Button {
                            claimCosmetic(cosmeticId, cost: cost)
                        } label: {
                            Text("\(cost) \(shortCurrency(event.specialCurrency))")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    player.seasonalEventState.earnedCurrency >= cost
                                    ? themeColor(for: event.theme).opacity(0.2)
                                    : Color.white.opacity(0.05)
                                )
                                .foregroundStyle(
                                    player.seasonalEventState.earnedCurrency >= cost
                                    ? themeColor(for: event.theme)
                                    : .white.opacity(0.3)
                                )
                                .clipShape(Capsule())
                        }
                        .disabled(player.seasonalEventState.earnedCurrency < cost)
                    }
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
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(.gray)

            Text("No Active Event")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.6))

            Text("Check back soon for the next seasonal event!")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Upcoming Events

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Event Calendar")
                .font(.headline)
                .foregroundStyle(.white)

            let allEvents = SeasonalEventSystem.currentYearEvents()
            ForEach(allEvents, id: \.id) { event in
                let isActive = event.isActive()
                let isPast = event.endDate < Date()

                HStack(spacing: 12) {
                    Image(systemName: themeIcon(for: event.theme))
                        .font(.title3)
                        .foregroundStyle(isActive ? themeColor(for: event.theme) : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isActive ? .white : .white.opacity(0.5))

                        Text(dateRange(event))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .clipShape(Capsule())
                    } else if isPast {
                        Text("ENDED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                }
                .padding(10)
                .background(isActive ? themeColor(for: event.theme).opacity(0.05) : Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Helpers

    private func themeIcon(for theme: String) -> String {
        switch theme {
        case "spring": return "leaf.fill"
        case "summer": return "sun.max.fill"
        case "autumn": return "wind"
        case "winter": return "snowflake"
        default: return "calendar"
        }
    }

    private func themeColor(for theme: String) -> Color {
        switch theme {
        case "spring": return .green
        case "summer": return .orange
        case "autumn": return Color(red: 0.85, green: 0.55, blue: 0.2)
        case "winter": return .cyan
        default: return .gray
        }
    }

    private func timeRemaining(until date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        let days = Int(remaining) / 86400
        if days > 0 { return "\(days)d remaining" }
        let hours = Int(remaining) / 3600
        return "\(hours)h remaining"
    }

    private func dateRange(_ event: SeasonalEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: event.startDate)) – \(formatter.string(from: event.endDate))"
    }

    private func cosmeticCost(for id: String, in event: SeasonalEvent) -> Int {
        guard let index = event.exclusiveCosmetics.firstIndex(of: id) else { return 100 }
        return (index + 1) * 50
    }

    private func shortCurrency(_ name: String) -> String {
        name.split(separator: " ").last.map(String.init) ?? name
    }

    private func claimCosmetic(_ cosmeticId: String, cost: Int) {
        guard player.seasonalEventState.earnedCurrency >= cost else { return }
        player.seasonalEventState.earnedCurrency -= cost
        player.seasonalEventState.claimedRewards.insert(cosmeticId)
        player.ownedCosmetics.insert(cosmeticId)
    }
}
