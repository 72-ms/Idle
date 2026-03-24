import SwiftUI

struct RelicForgeView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @State private var selectedTab: RelicTab = .forge

    var body: some View {
        VStack(spacing: 0) {
            // Materials header
            HStack {
                Label("\(player.relicMaterials)", systemImage: "diamond.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(player.equippedRelics.count)/\(player.maxRelicSlots) equipped")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Forge").tag(RelicTab.forge)
                Text("Inventory (\(player.relics.count))").tag(RelicTab.inventory)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                switch selectedTab {
                case .forge:
                    forgeList
                case .inventory:
                    inventoryList
                }
            }
        }
    }

    // MARK: - Forge List

    private var forgeList: some View {
        LazyVStack(spacing: 8) {
            ForEach(availableRelicConfigs, id: \.id.rawValue) { config in
                ForgeRelicRow(config: config)
            }

            if availableRelicConfigs.isEmpty {
                VStack(spacing: 8) {
                    Text("No relics available to forge")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Unlock more eras to discover new relics")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.top, 40)
            }
        }
        .padding(.horizontal, 16)
    }

    private var availableRelicConfigs: [RelicConfig] {
        GameConfig.allRelics.filter { config in
            player.isEraUnlocked(config.era)
        }
    }

    // MARK: - Inventory List

    private var inventoryList: some View {
        LazyVStack(spacing: 8) {
            if player.relics.isEmpty {
                VStack(spacing: 8) {
                    Text("No relics forged yet")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Forge relics to boost your production")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.top, 40)
            }

            // Equipped first
            let equipped = player.relics.filter { $0.isEquipped }
            let unequipped = player.relics.filter { !$0.isEquipped }

            if !equipped.isEmpty {
                Section {
                    ForEach(equipped) { relic in
                        InventoryRelicRow(relic: relic)
                    }
                } header: {
                    Text("Equipped")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !unequipped.isEmpty {
                Section {
                    ForEach(unequipped) { relic in
                        InventoryRelicRow(relic: relic)
                    }
                } header: {
                    Text("Unequipped")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ForgeRelicRow: View {
    let config: RelicConfig
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    private var canForge: Bool {
        player.temporalEnergy >= config.forgeCost && player.relicMaterials >= config.materialCost
    }

    var body: some View {
        Button {
            if engine.forgeRelic(configId: config.id) {
                HapticsManager.heavyTap()
                AudioManager.shared.play(.forge)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(config.name)
                            .font(.subheadline.weight(.semibold))
                        Text(config.rarity.displayName)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(rarityColor(config.rarity).opacity(0.2))
                            .clipShape(Capsule())
                            .foregroundStyle(rarityColor(config.rarity))
                    }
                    Text(config.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(TEFormatter.format(config.forgeCost))
                        .font(.caption.weight(.semibold))
                    HStack(spacing: 2) {
                        Image(systemName: "diamond.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(config.materialCost)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(12)
            .background(canForge ? rarityColor(config.rarity).opacity(0.08) : .white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .disabled(!canForge)
        .opacity(canForge ? 1 : 0.5)
    }
}

struct InventoryRelicRow: View {
    let relic: Relic
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @State private var showSalvageConfirm = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(relic.name)
                        .font(.subheadline.weight(.semibold))
                    Text(relic.rarity.displayName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rarityColor(relic.rarity).opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(rarityColor(relic.rarity))
                }
                Text(relic.effectDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 8) {
                // Equip/Unequip button
                Button {
                    if relic.isEquipped {
                        _ = engine.unequipRelic(relicId: relic.id)
                    } else {
                        _ = engine.equipRelic(relicId: relic.id)
                    }
                    HapticsManager.mediumTap()
                } label: {
                    Text(relic.isEquipped ? "Remove" : "Equip")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(relic.isEquipped ? .red.opacity(0.2) : .green.opacity(0.2))
                        .clipShape(Capsule())
                }
                .disabled(!relic.isEquipped && player.equippedRelics.count >= player.maxRelicSlots)

                // Salvage button
                Button {
                    showSalvageConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(relic.isEquipped ? rarityColor(relic.rarity).opacity(0.06) : .white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(.white)
        .alert("Salvage \(relic.name)?", isPresented: $showSalvageConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Salvage", role: .destructive) {
                _ = engine.salvageRelic(relicId: relic.id)
            }
        } message: {
            Text("This relic will be destroyed. You'll recover some materials.")
        }
    }
}

private func rarityColor(_ rarity: RelicRarity) -> Color {
    switch rarity {
    case .common: return .gray
    case .rare: return .blue
    case .epic: return .purple
    case .legendary: return .orange
    }
}

enum RelicTab {
    case forge
    case inventory
}
