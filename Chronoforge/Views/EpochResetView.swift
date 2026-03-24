import SwiftUI

struct EpochResetView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @State private var showConfirmation = false
    @State private var selectedPerkTab: PerkTab = .perks

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Epoch Crystals display
                VStack(spacing: 4) {
                    Text("\(player.epochCrystals)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                    Text("Epoch Crystals")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 16)

                // Reset info
                VStack(spacing: 8) {
                    Text("Epoch Reset")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    if engine.canEpochReset() {
                        Text("You will earn \(engine.epochResetReward()) Epoch Crystals")
                            .font(.headline)
                            .foregroundStyle(.purple)
                    } else {
                        Text("Requires \(EpochConfig.minimumPrestigesForEpoch) prestiges")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Current: \(player.totalPrestigeCount) prestiges")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                // Tab picker
                Picker("", selection: $selectedPerkTab) {
                    Text("Perks").tag(PerkTab.perks)
                    Text("Reset").tag(PerkTab.reset)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedPerkTab {
                case .perks:
                    perksGrid
                case .reset:
                    resetInfo
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Perks

    private var perksGrid: some View {
        LazyVStack(spacing: 8) {
            ForEach(EpochConfig.allPerks, id: \.id.rawValue) { perk in
                EpochPerkRow(perk: perk)
            }
        }
    }

    // MARK: - Reset Info

    private var resetInfo: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What Resets")
                    .font(.headline)
                    .foregroundStyle(.red.opacity(0.8))

                ForEach(epochResets, id: \.self) { item in
                    Label(item, systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.red.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text("What Stays")
                    .font(.headline)
                    .foregroundStyle(.green.opacity(0.8))

                ForEach(epochKeeps, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.green.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showConfirmation = true
            } label: {
                Text("Epoch Reset")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(engine.canEpochReset() ? .purple : .gray.opacity(0.3))
                    .foregroundStyle(engine.canEpochReset() ? .white : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!engine.canEpochReset())

            Text("Total Epoch Resets: \(player.totalEpochCount)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .alert("Epoch Reset?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                engine.performEpochReset()
                HapticsManager.heavyTap()
                AudioManager.shared.play(.epoch)
            }
        } message: {
            Text("This will reset EVERYTHING except Epoch Crystals and Perks. You will earn \(engine.epochResetReward()) Epoch Crystals.")
        }
    }

    private var epochResets: [String] {
        ["Temporal Energy", "All Generators", "All Upgrades", "Chrono Shards", "Skill Tree", "All Relics", "Relic Materials", "Era Progress"]
    }

    private var epochKeeps: [String] {
        ["Epoch Crystals (+ new ones)", "Epoch Perks", "Cosmetics", "Achievements", "Lifetime Statistics"]
    }
}

struct EpochPerkRow: View {
    let perk: EpochPerkConfig
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    private var currentLevel: Int {
        player.epochPerkState.level(for: perk.id)
    }

    private var isMaxed: Bool {
        currentLevel >= perk.maxLevel
    }

    private var canBuy: Bool {
        !isMaxed && player.epochCrystals >= perk.cost
    }

    var body: some View {
        Button {
            if engine.buyEpochPerk(perkId: perk.id) {
                HapticsManager.mediumTap()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(perk.name)
                            .font(.subheadline.weight(.medium))
                        Text("\(currentLevel)/\(perk.maxLevel)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(isMaxed ? .purple.opacity(0.3) : .white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text(perk.description)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if !isMaxed {
                    HStack(spacing: 2) {
                        Text("\(perk.cost)")
                            .font(.caption.weight(.semibold))
                        Text("EC")
                            .font(.caption2)
                    }
                    .foregroundStyle(canBuy ? .purple : .gray)
                }
            }
            .padding(10)
            .background(canBuy ? .purple.opacity(0.06) : .white.opacity(0.02))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
        }
        .disabled(!canBuy)
        .opacity(canBuy ? 1 : (isMaxed ? 0.7 : 0.4))
    }
}

enum PerkTab {
    case perks
    case reset
}
