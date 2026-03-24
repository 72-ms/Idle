import SwiftUI
import SpriteKit

// MARK: - Era Colors

struct EraTheme {
    let primary: Color
    let secondary: Color
    let accent: Color
    let backgroundTop: Color
    let backgroundBottom: Color
    let particleColor: UIColor
    let textColor: Color

    static func theme(for era: Era) -> EraTheme {
        switch era {
        case .ancient:
            return EraTheme(
                primary: Color(red: 0.9, green: 0.75, blue: 0.4),
                secondary: Color(red: 0.7, green: 0.55, blue: 0.25),
                accent: Color(red: 1.0, green: 0.85, blue: 0.5),
                backgroundTop: Color(red: 0.15, green: 0.1, blue: 0.05),
                backgroundBottom: Color(red: 0.3, green: 0.2, blue: 0.1),
                particleColor: UIColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1),
                textColor: .white
            )
        case .medieval:
            return EraTheme(
                primary: Color(red: 0.4, green: 0.5, blue: 0.9),
                secondary: Color(red: 0.3, green: 0.35, blue: 0.7),
                accent: Color(red: 0.6, green: 0.65, blue: 1.0),
                backgroundTop: Color(red: 0.08, green: 0.08, blue: 0.15),
                backgroundBottom: Color(red: 0.15, green: 0.15, blue: 0.25),
                particleColor: UIColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 1),
                textColor: .white
            )
        case .industrial:
            return EraTheme(
                primary: Color(red: 0.85, green: 0.65, blue: 0.3),
                secondary: Color(red: 0.65, green: 0.5, blue: 0.2),
                accent: Color(red: 0.95, green: 0.75, blue: 0.4),
                backgroundTop: Color(red: 0.12, green: 0.1, blue: 0.08),
                backgroundBottom: Color(red: 0.25, green: 0.2, blue: 0.15),
                particleColor: UIColor(red: 0.85, green: 0.65, blue: 0.3, alpha: 1),
                textColor: .white
            )
        case .digital:
            return EraTheme(
                primary: Color(red: 0.2, green: 0.9, blue: 0.9),
                secondary: Color(red: 0.1, green: 0.6, blue: 0.7),
                accent: Color(red: 0.3, green: 1.0, blue: 1.0),
                backgroundTop: Color(red: 0.02, green: 0.05, blue: 0.1),
                backgroundBottom: Color(red: 0.05, green: 0.1, blue: 0.2),
                particleColor: UIColor(red: 0.2, green: 0.9, blue: 0.9, alpha: 1),
                textColor: .white
            )
        case .cosmic:
            return EraTheme(
                primary: Color(red: 0.7, green: 0.4, blue: 0.9),
                secondary: Color(red: 0.5, green: 0.25, blue: 0.7),
                accent: Color(red: 0.85, green: 0.55, blue: 1.0),
                backgroundTop: Color(red: 0.05, green: 0.0, blue: 0.1),
                backgroundBottom: Color(red: 0.15, green: 0.05, blue: 0.25),
                particleColor: UIColor(red: 0.7, green: 0.4, blue: 0.9, alpha: 1),
                textColor: .white
            )
        }
    }
}

// MARK: - Generator Icons (SF Symbol mappings)

struct GeneratorIcon {
    let symbolName: String
    let color: Color

    static func icon(for generatorId: GeneratorID) -> GeneratorIcon {
        let era = generatorId.era
        let idx = generatorId.index
        let theme = EraTheme.theme(for: era)

        let symbol: String
        switch (era, idx) {
        // Ancient
        case (.ancient, 0): symbol = "sun.max.fill"         // Sundial
        case (.ancient, 1): symbol = "hourglass"              // Hourglass
        case (.ancient, 2): symbol = "drop.fill"              // Water Clock
        case (.ancient, 3): symbol = "star.fill"              // Astrolabe

        // Medieval
        case (.medieval, 0): symbol = "bell.fill"             // Bell Tower
        case (.medieval, 1): symbol = "gearshape.2.fill"      // Clockwork
        case (.medieval, 2): symbol = "metronome.fill"         // Pendulum
        case (.medieval, 3): symbol = "globe.americas.fill"    // Orrery

        // Industrial
        case (.industrial, 0): symbol = "smoke.fill"           // Steam Clock
        case (.industrial, 1): symbol = "bolt.horizontal.fill" // Telegraph
        case (.industrial, 2): symbol = "rectangle.3.group.fill" // Assembly Line
        case (.industrial, 3): symbol = "bolt.circle.fill"     // Dynamo

        // Digital
        case (.digital, 0): symbol = "cpu.fill"               // Quartz Processor
        case (.digital, 1): symbol = "server.rack"             // Server Farm
        case (.digital, 2): symbol = "atom"                    // Quantum Clock
        case (.digital, 3): symbol = "brain.head.profile"      // AI Core

        // Cosmic
        case (.cosmic, 0): symbol = "waveform.circle.fill"    // Pulsar Tap
        case (.cosmic, 1): symbol = "circle.dotted"            // Black Hole Engine
        case (.cosmic, 2): symbol = "wind"                     // Entropy Harvester
        case (.cosmic, 3): symbol = "sparkle"                  // Chrono Reactor

        default: symbol = "questionmark.circle"
        }

        return GeneratorIcon(symbolName: symbol, color: theme.primary)
    }
}

// MARK: - Relic Icons

struct RelicIcon {
    static func symbolName(for rarity: RelicRarity) -> String {
        switch rarity {
        case .common: return "shield.fill"
        case .rare: return "shield.lefthalf.filled"
        case .epic: return "seal.fill"
        case .legendary: return "crown.fill"
        }
    }

    static func color(for rarity: RelicRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .epic: return Color(red: 0.7, green: 0.3, blue: 0.9)
        case .legendary: return Color(red: 1.0, green: 0.7, blue: 0.2)
        }
    }
}

// MARK: - Programmatic App Icon Generator

struct AppIconRenderer {
    static func renderAppIcon(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            let context = ctx.cgContext

            // Background gradient (deep purple to dark blue)
            let colors = [
                UIColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colors as CFArray,
                                       locations: [0, 1])!
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0),
                                       end: CGPoint(x: size, y: size), options: [])

            // Central hourglass/forge shape
            let centerX = size / 2
            let centerY = size / 2
            let iconSize = size * 0.45

            // Outer ring (time circle)
            context.setStrokeColor(UIColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 0.8).cgColor)
            context.setLineWidth(size * 0.03)
            context.addEllipse(in: CGRect(x: centerX - iconSize/2, y: centerY - iconSize/2,
                                           width: iconSize, height: iconSize))
            context.strokePath()

            // Inner diamond (forge/anvil)
            let diamondSize = iconSize * 0.5
            context.setFillColor(UIColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1).cgColor)
            context.move(to: CGPoint(x: centerX, y: centerY - diamondSize/2))
            context.addLine(to: CGPoint(x: centerX + diamondSize/2, y: centerY))
            context.addLine(to: CGPoint(x: centerX, y: centerY + diamondSize/2))
            context.addLine(to: CGPoint(x: centerX - diamondSize/2, y: centerY))
            context.closePath()
            context.fillPath()

            // Small circle in center
            let dotSize = size * 0.06
            context.setFillColor(UIColor(red: 0.15, green: 0.05, blue: 0.25, alpha: 1).cgColor)
            context.fillEllipse(in: CGRect(x: centerX - dotSize/2, y: centerY - dotSize/2,
                                            width: dotSize, height: dotSize))

            // Radiating lines (time rays)
            context.setStrokeColor(UIColor(red: 0.7, green: 0.55, blue: 0.3, alpha: 0.4).cgColor)
            context.setLineWidth(size * 0.01)
            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 6) {
                let innerR = iconSize * 0.55
                let outerR = iconSize * 0.72
                let x1 = centerX + CGFloat(cos(angle)) * innerR
                let y1 = centerY + CGFloat(sin(angle)) * innerR
                let x2 = centerX + CGFloat(cos(angle)) * outerR
                let y2 = centerY + CGFloat(sin(angle)) * outerR
                context.move(to: CGPoint(x: x1, y: y1))
                context.addLine(to: CGPoint(x: x2, y: y2))
            }
            context.strokePath()

            // Star particles
            context.setFillColor(UIColor(red: 1, green: 0.9, blue: 0.6, alpha: 0.6).cgColor)
            let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
                (0.2, 0.15, 3), (0.8, 0.2, 2.5), (0.15, 0.75, 2),
                (0.85, 0.8, 3.5), (0.7, 0.12, 2), (0.3, 0.85, 2.5),
            ]
            for (px, py, r) in starPositions {
                let x = px * size
                let y = py * size
                context.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
        }
    }
}

// MARK: - Launch Screen Gradient

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.05, blue: 0.25),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.75, blue: 0.4),
                                Color(red: 0.7, green: 0.55, blue: 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("CHRONOFORGE")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.9, green: 0.75, blue: 0.4),
                                Color(red: 0.7, green: 0.55, blue: 0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Forge the Fabric of Time")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}
