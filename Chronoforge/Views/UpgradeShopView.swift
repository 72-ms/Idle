import SwiftUI

struct UpgradeShopView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(availableUpgrades, id: \.id.rawValue) { config in
                    UpgradeRow(config: config)
                }

                if availableUpgrades.isEmpty {
                    VStack(spacing: 8) {
                        Text("No upgrades available")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Keep buying generators to unlock upgrades")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var availableUpgrades: [UpgradeConfig] {
        GameConfig.allUpgrades.filter { config in
            guard !player.hasUpgrade(config.id) else { return false }
            guard player.isEraUnlocked(config.era) else { return false }
            return true
        }
    }
}

struct UpgradeRow: View {
    let config: UpgradeConfig
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    private var canAfford: Bool {
        player.temporalEnergy >= config.cost
    }

    var body: some View {
        Button {
            if engine.buyUpgrade(id: config.id) {
                HapticsManager.mediumTap()
                AudioManager.shared.play(.upgrade)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.headline)
                    Text(config.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Text(TEFormatter.format(config.cost))
                    .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.white.opacity(canAfford ? 0.1 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .disabled(!canAfford)
        .opacity(canAfford ? 1 : 0.5)
    }
}
