import SwiftUI

/// Renders a player name with VIP tier styling — animated gradient for Gold+, static for below.
struct VIPNameView: View {
    let name: String
    let vipTier: VIPTier
    let nameColorId: String?
    let title: String?
    let showBadge: Bool
    let font: Font

    init(
        name: String,
        vipTier: VIPTier,
        nameColorId: String? = nil,
        title: String? = nil,
        showBadge: Bool = true,
        font: Font = .subheadline.weight(.semibold)
    ) {
        self.name = name
        self.vipTier = vipTier
        self.nameColorId = nameColorId
        self.title = title
        self.showBadge = showBadge
        self.font = font
    }

    var body: some View {
        HStack(spacing: 4) {
            if showBadge && vipTier != .none {
                VIPBadgeView(tier: vipTier, size: .small)
            }

            if vipTier >= .gold, let colors = animatedColors {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let phase = timeline.date.timeIntervalSinceReferenceDate
                    Text(name)
                        .font(font)
                        .foregroundStyle(
                            animatedGradient(colors: colors, phase: phase)
                        )
                }
            } else {
                Text(name)
                    .font(font)
                    .foregroundStyle(tierColor)
            }

            if let title {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(tierColor.opacity(0.7))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(tierColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Color Resolution

    private var tierColor: Color {
        VIPColorResolver.color(for: vipTier)
    }

    private var animatedColors: [Color]? {
        guard vipTier >= .gold else { return nil }
        return VIPColorResolver.gradientColors(for: vipTier)
    }

    private func animatedGradient(colors: [Color], phase: Double) -> LinearGradient {
        let speed: Double = switch vipTier {
        case .chronarch: 3.0
        case .celestial: 2.5
        case .eternal: 2.0
        case .mythic: 1.5
        case .obsidian: 1.2
        case .diamond: 1.0
        default: 0.8
        }

        let offset = phase * speed
        let shiftedColors = colors.enumerated().map { idx, color in
            let shift = (Double(idx) / Double(colors.count) + offset).truncatingRemainder(dividingBy: 1.0)
            return (position: shift, color: color)
        }.sorted { $0.position < $1.position }

        return LinearGradient(
            colors: shiftedColors.map(\.color) + [shiftedColors.first?.color ?? .white],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - VIP Badge View

struct VIPBadgeView: View {
    let tier: VIPTier
    let size: BadgeSize

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 18
            case .large: return 28
            }
        }

        var frameSize: CGFloat {
            switch self {
            case .small: return 18
            case .medium: return 28
            case .large: return 42
            }
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(VIPColorResolver.color(for: tier).opacity(0.2))
                .frame(width: size.frameSize, height: size.frameSize)

            Image(systemName: tier.symbolName)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundStyle(VIPColorResolver.color(for: tier))
        }
    }
}

// MARK: - Chat Flair View

struct ChatFlairView: View {
    let flairId: String?
    let vipTier: VIPTier

    var body: some View {
        if let flairId, vipTier >= .mythic {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(VIPColorResolver.color(for: vipTier).opacity(0.15))
                    .frame(width: 16, height: 16)

                Image(systemName: flairSymbol(for: flairId))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(VIPColorResolver.color(for: vipTier))
            }
        }
    }

    private func flairSymbol(for id: String) -> String {
        if id.contains("chronarch") { return "bolt.fill" }
        if id.contains("celestial") { return "sun.max.fill" }
        if id.contains("eternal") { return "infinity" }
        if id.contains("mythic") { return "flame.fill" }
        return "sparkle"
    }
}

// MARK: - Animated Border Modifier

struct AnimatedBorderModifier: ViewModifier {
    let vipTier: VIPTier
    let borderId: String?
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if borderId != nil, vipTier >= .diamond {
            content
                .overlay(
                    TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                AngularGradient(
                                    colors: VIPColorResolver.gradientColors(for: vipTier)
                                        + [VIPColorResolver.gradientColors(for: vipTier).first ?? .clear],
                                    center: .center,
                                    angle: .degrees(phase * 60)
                                ),
                                lineWidth: vipTier >= .mythic ? 2.5 : 1.5
                            )
                    }
                )
        } else {
            content
        }
    }
}

extension View {
    func vipBorder(tier: VIPTier, borderId: String?, cornerRadius: CGFloat = 16) -> some View {
        modifier(AnimatedBorderModifier(vipTier: tier, borderId: borderId, cornerRadius: cornerRadius))
    }
}

// MARK: - VIP Color Resolver

enum VIPColorResolver {
    static func color(for tier: VIPTier) -> Color {
        switch tier {
        case .none: return .gray
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .diamond: return Color(red: 0.53, green: 0.81, blue: 0.98)
        case .obsidian: return Color(red: 0.60, green: 0.20, blue: 0.90)
        case .mythic: return Color(red: 1.0, green: 0.30, blue: 0.15)
        case .eternal: return Color(red: 0.95, green: 0.75, blue: 1.0)
        case .celestial: return Color(red: 1.0, green: 0.95, blue: 0.60)
        case .chronarch: return .white
        }
    }

    static func gradientColors(for tier: VIPTier) -> [Color] {
        switch tier {
        case .gold:
            return [.yellow, .orange, .yellow]
        case .diamond:
            return [Color(red: 0.53, green: 0.81, blue: 0.98), .white, .cyan, Color(red: 0.53, green: 0.81, blue: 0.98)]
        case .obsidian:
            return [.purple, Color(red: 0.60, green: 0.20, blue: 0.90), .indigo, .purple]
        case .mythic:
            return [.red, .orange, .yellow, .red]
        case .eternal:
            return [Color(red: 0.95, green: 0.75, blue: 1.0), .pink, .purple, Color(red: 0.95, green: 0.75, blue: 1.0)]
        case .celestial:
            return [.yellow, .white, Color(red: 1.0, green: 0.95, blue: 0.60), .orange, .yellow]
        case .chronarch:
            return [.white, .cyan, .purple, .pink, .yellow, .white]
        default:
            return [color(for: tier)]
        }
    }
}
