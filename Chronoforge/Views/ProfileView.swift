import SwiftUI

struct ProfileView: View {
    let profile: PlayerProfile
    let isLocalPlayer: Bool

    @Environment(StoreManager.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                statsGrid
                if !profile.pinnedAchievements.isEmpty {
                    achievementShowcase
                }
                guildAffiliation
                if isLocalPlayer {
                    cosmeticEquipSection
                }
            }
            .padding()
        }
        .background(profileBackground.ignoresSafeArea())
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar frame
            ZStack {
                Circle()
                    .fill(VIPColorResolver.color(for: profile.vipTier).opacity(0.1))
                    .frame(width: 90, height: 90)

                if profile.equippedAvatarFrame != nil {
                    Circle()
                        .strokeBorder(
                            VIPColorResolver.color(for: profile.vipTier),
                            lineWidth: profile.vipTier >= .mythic ? 3 : 2
                        )
                        .frame(width: 90, height: 90)
                }

                VIPBadgeView(tier: profile.vipTier, size: .large)
            }

            // Name with VIP styling
            VIPNameView(
                name: profile.displayName,
                vipTier: profile.vipTier,
                nameColorId: profile.equippedNameColor,
                title: profile.equippedTitle,
                showBadge: false,
                font: .title2.weight(.bold)
            )

            // VIP tier label
            if profile.vipTier != .none {
                HStack(spacing: 6) {
                    VIPBadgeView(tier: profile.vipTier, size: .small)
                    Text("\(profile.vipTier.displayName) VIP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VIPColorResolver.color(for: profile.vipTier))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(VIPColorResolver.color(for: profile.vipTier).opacity(0.1))
                .clipShape(Capsule())
            }

            // Era
            HStack(spacing: 4) {
                Circle()
                    .fill(EraTheme.theme(for: profile.currentEra).accent)
                    .frame(width: 8, height: 8)
                Text("\(profile.currentEra.displayName) Era")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .vipBorder(tier: profile.vipTier, borderId: profile.equippedProfileBorder, cornerRadius: 20)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statCard("Prestiges", value: "\(profile.totalPrestigeCount)", icon: "arrow.counterclockwise")
                statCard("Epochs", value: "\(profile.totalEpochCount)", icon: "arrow.triangle.2.circlepath")
                statCard("Taps", value: formatLargeNumber(profile.totalTaps), icon: "hand.tap")
                statCard("Relics", value: "\(profile.totalRelicsForged)", icon: "diamond")
                statCard("Challenges", value: "\(profile.totalChallengesCompleted)/8", icon: "flame")
                statCard("Play Time", value: formatPlayTime(profile.totalPlayTime), icon: "clock")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statCard(_ label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(VIPColorResolver.color(for: profile.vipTier).opacity(0.7))

            Text(value)
                .font(.subheadline.weight(.bold).monospaced())
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Achievement Showcase

    private var achievementShowcase: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pinned Achievements")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(profile.pinnedAchievements.prefix(5), id: \.self) { achievementId in
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                        Text(achievementId.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Guild Affiliation

    private var guildAffiliation: some View {
        Group {
            if let guildName = profile.guildName, let role = profile.guildRole {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(guildName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        HStack(spacing: 4) {
                            Image(systemName: role.symbolName)
                                .font(.system(size: 10))
                            Text(role.displayName)
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Cosmetic Equip (Local Player Only)

    private var cosmeticEquipSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Equipped Cosmetics")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                cosmeticRow("Avatar Frame", value: profile.equippedAvatarFrame, icon: "person.crop.circle")
                cosmeticRow("Name Color", value: profile.equippedNameColor, icon: "paintbrush")
                cosmeticRow("Title", value: profile.equippedTitle, icon: "text.badge.star")
                cosmeticRow("Profile Border", value: profile.equippedProfileBorder, icon: "square.dashed")
                cosmeticRow("Chat Flair", value: profile.equippedChatFlair, icon: "bubble.left.fill")
                cosmeticRow("Background", value: profile.equippedProfileBackground, icon: "photo")
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func cosmeticRow(_ label: String, value: String?, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Text(value?.replacingOccurrences(of: "_", with: " ").capitalized ?? "None")
                .font(.caption.weight(.medium))
                .foregroundStyle(value != nil ? VIPColorResolver.color(for: profile.vipTier) : .white.opacity(0.3))
        }
    }

    // MARK: - Helpers

    private var profileBackground: Color {
        Color.black
    }

    private func formatLargeNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fK", Double(n) / 1_000) }
        return "\(n)"
    }

    private func formatPlayTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours >= 24 { return "\(hours / 24)d" }
        return "\(hours)h"
    }
}
