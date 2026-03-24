import SwiftUI

// MARK: - Avatar Frame View

/// Wraps content in a VIP-tier-appropriate avatar frame with optional animation.
struct AvatarFrameView<Content: View>: View {
    let frameId: String?
    let vipTier: VIPTier
    let size: CGFloat
    @ViewBuilder let content: () -> Content

    init(frameId: String?, vipTier: VIPTier, size: CGFloat = 64, @ViewBuilder content: @escaping () -> Content) {
        self.frameId = frameId
        self.vipTier = vipTier
        self.size = size
        self.content = content
    }

    var body: some View {
        ZStack {
            content()
                .frame(width: size, height: size)
                .clipShape(Circle())

            if frameId != nil {
                if vipTier >= .mythic {
                    // Animated rotating border for Mythic+
                    TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    colors: VIPColorResolver.gradientColors(for: vipTier)
                                        + [VIPColorResolver.gradientColors(for: vipTier).first ?? .clear],
                                    center: .center,
                                    angle: .degrees(phase * 45)
                                ),
                                lineWidth: 3
                            )
                            .frame(width: size + 6, height: size + 6)
                    }
                } else {
                    // Static border for lower tiers
                    Circle()
                        .strokeBorder(
                            VIPColorResolver.color(for: vipTier),
                            lineWidth: 2
                        )
                        .frame(width: size + 4, height: size + 4)
                }
            }
        }
    }
}

// MARK: - Profile Border View

/// Wraps any rectangular content in a VIP animated border.
struct ProfileBorderView<Content: View>: View {
    let borderId: String?
    let vipTier: VIPTier
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(borderId: String?, vipTier: VIPTier, cornerRadius: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.borderId = borderId
        self.vipTier = vipTier
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .vipBorder(tier: vipTier, borderId: borderId, cornerRadius: cornerRadius)
    }
}

// MARK: - Profile Background View

/// Full-bleed animated background for profile cards, based on VIP tier.
struct ProfileBackgroundView: View {
    let backgroundId: String?
    let vipTier: VIPTier

    var body: some View {
        if let backgroundId, vipTier >= .chronarch {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: backgroundColors(for: backgroundId, phase: phase),
                        startPoint: UnitPoint(
                            x: 0.5 + 0.3 * cos(phase * 0.3),
                            y: 0
                        ),
                        endPoint: UnitPoint(
                            x: 0.5 + 0.3 * sin(phase * 0.2),
                            y: 1
                        )
                    )

                    // Subtle particle overlay
                    RadialGradient(
                        colors: [
                            VIPColorResolver.color(for: vipTier).opacity(0.15),
                            .clear
                        ],
                        center: UnitPoint(
                            x: 0.5 + 0.4 * sin(phase * 0.5),
                            y: 0.5 + 0.4 * cos(phase * 0.4)
                        ),
                        startRadius: 0,
                        endRadius: 200
                    )
                }
            }
        } else if vipTier >= .diamond {
            // Static premium background for Diamond-Celestial
            LinearGradient(
                colors: [
                    VIPColorResolver.color(for: vipTier).opacity(0.08),
                    Color.black,
                    VIPColorResolver.color(for: vipTier).opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.black
        }
    }

    private func backgroundColors(for id: String, phase: Double) -> [Color] {
        let tier = VIPColorResolver.gradientColors(for: vipTier)
        let alpha = 0.15 + 0.05 * sin(phase * 0.5)
        return tier.map { $0.opacity(alpha) } + [Color.black]
    }
}

// MARK: - Leaderboard Badge View

/// Compact VIP badge for leaderboard rows — shows tier icon with colored glow.
struct LeaderboardBadgeView: View {
    let tier: VIPTier

    var body: some View {
        if tier >= .diamond {
            ZStack {
                Circle()
                    .fill(VIPColorResolver.color(for: tier).opacity(0.2))
                    .frame(width: 22, height: 22)

                Image(systemName: tier.symbolName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(VIPColorResolver.color(for: tier))
            }
        }
    }
}

// MARK: - Leaderboard Name Row

/// A complete name row for leaderboard entries, combining VIP name + badge + title.
struct LeaderboardNameRow: View {
    let name: String
    let vipTier: VIPTier
    let nameColorId: String?
    let title: String?
    let isLocalPlayer: Bool

    var body: some View {
        HStack(spacing: 4) {
            LeaderboardBadgeView(tier: vipTier)

            VIPNameView(
                name: name,
                vipTier: vipTier,
                nameColorId: nameColorId,
                title: nil,
                showBadge: false,
                font: .subheadline
            )

            if let title {
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(VIPColorResolver.color(for: vipTier).opacity(0.6))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(VIPColorResolver.color(for: vipTier).opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }
}
