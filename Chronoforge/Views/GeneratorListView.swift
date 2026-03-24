import SwiftUI

struct GeneratorListView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @State private var buyAmount: BuyAmount = .one

    var body: some View {
        VStack(spacing: 0) {
            eraSelector
            buyAmountPicker

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(availableGenerators, id: \.id) { config in
                        GeneratorRow(config: config, buyAmount: buyAmount)
                    }

                    nextEraButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    private var eraSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Era.allCases) { era in
                    if player.isEraUnlocked(era) {
                        Button(era.displayName) {
                            // Era filtering could be added here
                        }
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(player.currentEra == era ? .white.opacity(0.15) : .clear)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var buyAmountPicker: some View {
        HStack(spacing: 8) {
            ForEach(BuyAmount.allCases, id: \.self) { amount in
                Button(amount.label) {
                    buyAmount = amount
                    HapticsManager.lightTap()
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(buyAmount == amount ? .white.opacity(0.2) : .white.opacity(0.05))
                .clipShape(Capsule())
                .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var availableGenerators: [GeneratorConfig] {
        var generators: [GeneratorConfig] = []
        for era in Era.allCases where player.isEraUnlocked(era) {
            generators.append(contentsOf: GameConfig.generators(for: era))
        }
        return generators
    }

    @ViewBuilder
    private var nextEraButton: some View {
        if let nextEra = nextLockedEra {
            Button {
                if engine.unlockEra(nextEra) {
                    HapticsManager.heavyTap()
                }
            } label: {
                VStack(spacing: 4) {
                    Text("Unlock \(nextEra.displayName)")
                        .font(.headline)
                    Text(TEFormatter.format(nextEra.unlockCost))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(player.temporalEnergy >= nextEra.unlockCost ? 0.15 : 0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(player.temporalEnergy < nextEra.unlockCost)
            .opacity(player.temporalEnergy >= nextEra.unlockCost ? 1 : 0.5)
        }
    }

    private var nextLockedEra: Era? {
        Era.allCases.first { !player.isEraUnlocked($0) }
    }
}

struct GeneratorRow: View {
    let config: GeneratorConfig
    let buyAmount: BuyAmount
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    private var state: GeneratorState {
        player.generatorState(for: config.id)
    }

    private var count: Int {
        switch buyAmount {
        case .one: return 1
        case .ten: return 10
        case .hundred: return 100
        case .max: return maxAffordable
        }
    }

    private var cost: Decimal {
        state.costForBulk(count)
    }

    private var canAfford: Bool {
        count > 0 && player.temporalEnergy >= cost
    }

    private var maxAffordable: Int {
        var n = 0
        var total: Decimal = 0
        let config = GameConfig.generator(for: config.id)
        while true {
            let nextCost = config.baseCost * pow(config.costMultiplier, state.quantity + n)
            if total + nextCost > player.temporalEnergy { break }
            total += nextCost
            n += 1
            if n >= 1000 { break }
        }
        return n
    }

    var body: some View {
        Button {
            if engine.buyGenerator(id: config.id, count: count) {
                HapticsManager.mediumTap()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(config.name)
                            .font(.headline)
                        if state.quantity > 0 {
                            Text("x\(state.quantity)")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    Text(config.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    if state.quantity > 0 {
                        Text("\(TEFormatter.formatRate(state.production(upgradeMultiplier: 1, skillMultiplier: 1, relicMultiplier: 1)))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(TEFormatter.format(cost))
                        .font(.subheadline.weight(.semibold))
                    if buyAmount == .max && maxAffordable > 0 {
                        Text("x\(maxAffordable)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
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

private func pow(_ base: Decimal, _ exponent: Int) -> Decimal {
    if exponent == 0 { return 1 }
    var result: Decimal = 1
    for _ in 0..<exponent {
        result *= base
    }
    return result
}

enum BuyAmount: CaseIterable {
    case one, ten, hundred, max

    var label: String {
        switch self {
        case .one: return "x1"
        case .ten: return "x10"
        case .hundred: return "x100"
        case .max: return "Max"
        }
    }
}
