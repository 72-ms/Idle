import SwiftUI

struct DailyRewardView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @Environment(\.dismiss) private var dismiss
    @State private var claimed = false
    @State private var claimedReward: DailyRewardConfig?

    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Reward")
                .font(.title2.bold())
                .foregroundStyle(.white)

            // Streak info
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(player.dailyRewardState.currentStreak) day streak")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            // Calendar
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    DayCell(
                        day: day,
                        reward: DailyRewardSystem.reward(for: day),
                        isToday: day == player.dailyRewardState.todayRewardDay,
                        isClaimed: day < player.dailyRewardState.todayRewardDay || claimed
                    )
                }
            }
            .padding(.horizontal, 8)

            // Today's reward
            if let reward = claimedReward {
                VStack(spacing: 8) {
                    Text("Claimed!")
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text(reward.description)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .transition(.scale.combined(with: .opacity))
            } else if engine.canClaimDailyReward() {
                let todayReward = DailyRewardSystem.reward(for: player.dailyRewardState.todayRewardDay)
                VStack(spacing: 8) {
                    Text("Today's Reward")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(todayReward.description)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        claimedReward = engine.claimDailyReward()
                        claimed = true
                    }
                    HapticsManager.heavyTap()
                    AudioManager.shared.play(.reward)
                } label: {
                    Text("Claim Reward")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.orange)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("Come back tomorrow!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Button("Close") {
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 8)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(24)
    }
}

struct DayCell: View {
    let day: Int
    let reward: DailyRewardConfig
    let isToday: Bool
    let isClaimed: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("Day \(day)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? .orange.opacity(0.2) : (isClaimed ? .green.opacity(0.1) : .white.opacity(0.05)))
                    .frame(height: 40)

                if isClaimed {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                } else {
                    rewardIcon
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? .orange : .clear, lineWidth: 2)
                .offset(y: 10)
        )
    }

    @ViewBuilder
    private var rewardIcon: some View {
        switch reward.reward {
        case .temporalEnergy:
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
        case .chronoShards:
            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(.cyan)
        case .relicMaterials:
            Image(systemName: "diamond.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        case .productionBoost:
            Image(systemName: "arrow.up.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}
