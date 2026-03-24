import SwiftUI

struct AchievementView: View {
    @Environment(PlayerState.self) private var player

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary
                HStack(spacing: 20) {
                    VStack {
                        Text("\(player.achievementState.unlockedAchievements.count)")
                            .font(.title2.bold())
                            .foregroundStyle(.yellow)
                        Text("Unlocked")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    VStack {
                        Text("\(AchievementSystem.allAchievements.count)")
                            .font(.title2.bold())
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.top, 16)

                // Achievement list
                LazyVStack(spacing: 8) {
                    ForEach(AchievementSystem.allAchievements, id: \.id.rawValue) { achievement in
                        AchievementRow(
                            achievement: achievement,
                            isUnlocked: player.achievementState.isUnlocked(achievement.id)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct AchievementRow: View {
    let achievement: AchievementConfig
    let isUnlocked: Bool

    var body: some View {
        HStack {
            Image(systemName: isUnlocked ? "trophy.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(isUnlocked ? .yellow : .gray.opacity(0.3))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.4))
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(isUnlocked ? 0.6 : 0.3))
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(10)
        .background(.white.opacity(isUnlocked ? 0.05 : 0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
