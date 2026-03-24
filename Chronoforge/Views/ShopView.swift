import SwiftUI
import StoreKit

struct ShopView: View {
    @Environment(StoreManager.self) private var store
    @Environment(PlayerState.self) private var player

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var selectedCosmetic: CosmeticItem?
    @State private var cosmeticFilter: CosmeticType? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                chronoPassSection
                cosmeticsSection
                specialOffersSection
                restorePurchasesButton
                Spacer(minLength: 40)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(item: $selectedCosmetic) { cosmetic in
            cosmeticDetailSheet(cosmetic)
        }
    }

    // MARK: - Chrono Pass

    private var chronoPassSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Chrono Pass", symbol: "shield.checkerboard")

            VStack(spacing: 14) {
                HStack {
                    Text("Season Pass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Tier \(store.chronoPassProgress.currentTier) / \(ChronoPassProgress.totalTiers)")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.white.opacity(0.7))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [eraAccentColor, eraAccentColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * store.xpProgressForCurrentTier())
                    }
                }
                .frame(height: 10)

                Text("\(store.chronoPassProgress.currentXP) XP to next tier")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                if !store.isChronoPassActive {
                    Button {
                        Task {
                            isPurchasing = true
                            _ = await store.purchaseChronoPass()
                            isPurchasing = false
                        }
                    } label: {
                        Text("Unlock Premium Pass")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isPurchasing)
                } else {
                    Label("Premium Unlocked", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Cosmetics

    private var cosmeticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Cosmetics", symbol: "paintpalette.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", type: nil)
                    filterChip(label: "Skins", type: .skin)
                    filterChip(label: "Particles", type: .particleEffect)
                    filterChip(label: "Themes", type: .uiTheme)
                    filterChip(label: "Relics", type: .relicAppearance)
                    filterChip(label: "Avatars", type: .avatar)
                }
            }

            let filtered = filteredCosmetics
            if filtered.isEmpty {
                Text("No cosmetics available in this category.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(filtered) { item in
                        cosmeticCard(item)
                    }
                }
            }
        }
    }

    private var filteredCosmetics: [CosmeticItem] {
        guard let filter = cosmeticFilter else { return store.cosmeticCatalog }
        return store.cosmeticCatalog.filter { $0.type == filter }
    }

    private func filterChip(label: String, type: CosmeticType?) -> some View {
        let isSelected = cosmeticFilter == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                cosmeticFilter = type
            }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? eraAccentColor : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    private func cosmeticCard(_ item: CosmeticItem) -> some View {
        let isOwned = store.ownsCosmetic(item)
        let isEquipped = player.equippedCosmetics.contains(item.id)

        return Button {
            selectedCosmetic = item
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isEquipped ? eraAccentColor.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 56, height: 56)

                    Image(systemName: iconForCosmeticType(item.type))
                        .font(.title2)
                        .foregroundStyle(isEquipped ? eraAccentColor : .white.opacity(0.8))
                }

                Text(item.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if isEquipped {
                    Text("Equipped")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(eraAccentColor)
                } else if isOwned {
                    Text("Owned")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    Text(store.product(for: item)?.displayPrice ?? "$\(NSDecimalNumber(decimal: item.price))")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isEquipped ? eraAccentColor.opacity(0.5) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cosmetic Detail Sheet

    private func cosmeticDetailSheet(_ item: CosmeticItem) -> some View {
        let isOwned = store.ownsCosmetic(item)
        let isEquipped = player.equippedCosmetics.contains(item.id)

        return VStack(spacing: 24) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            ZStack {
                Circle()
                    .fill(eraAccentColor.opacity(0.15))
                    .frame(width: 88, height: 88)

                Image(systemName: iconForCosmeticType(item.type))
                    .font(.largeTitle)
                    .foregroundStyle(eraAccentColor)
            }

            VStack(spacing: 6) {
                Text(item.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(displayName(for: item.type))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(eraAccentColor)

                if let era = item.era {
                    Text(era.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            if isOwned {
                Button {
                    if isEquipped {
                        player.equippedCosmetics.remove(item.id)
                    } else {
                        player.equippedCosmetics.insert(item.id)
                    }
                    selectedCosmetic = nil
                } label: {
                    Text(isEquipped ? "Unequip" : "Equip")
                        .font(.headline)
                        .foregroundStyle(isEquipped ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isEquipped ? Color.white.opacity(0.12) : eraAccentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            } else {
                Button {
                    Task {
                        isPurchasing = true
                        _ = await store.purchaseCosmetic(item)
                        isPurchasing = false
                        selectedCosmetic = nil
                    }
                } label: {
                    Text(store.product(for: item)?.displayPrice ?? "$\(NSDecimalNumber(decimal: item.price))")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(eraAccentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isPurchasing)
            }
        }
        .padding()
        .padding(.bottom, 16)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(white: 0.1))
    }

    // MARK: - Special Offers

    private var specialOffersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Special Offers", symbol: "sparkles")

            if !store.hasStarterPack {
                specialOfferCard(
                    title: "Starter Pack",
                    description: "Bonus Chrono Shards, exclusive Founder cosmetic, and a 2x boost.",
                    symbol: "shippingbox.fill",
                    badge: "Best Value",
                    accent: .orange
                ) {
                    _ = await store.purchaseStarterPack()
                }
            }

            if !store.isAdFree {
                specialOfferCard(
                    title: "Remove Ads",
                    description: "Permanently remove all banner and interstitial ads.",
                    symbol: "eye.slash.fill",
                    badge: "Forever",
                    accent: .mint
                ) {
                    _ = await store.purchaseRemoveAds()
                }
            }

            if store.hasStarterPack && store.isAdFree {
                Text("You own all special offers. Thank you!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
    }

    private func specialOfferCard(
        title: String,
        description: String,
        symbol: String,
        badge: String,
        accent: Color,
        action: @escaping () async -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)

                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accent)
                            .clipShape(Capsule())
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }

            Button {
                Task {
                    isPurchasing = true
                    await action()
                    isPurchasing = false
                }
            } label: {
                Text("Purchase")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isPurchasing)
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Restore Purchases

    private var restorePurchasesButton: some View {
        Button {
            Task {
                isRestoring = true
                await store.restorePurchases()
                isRestoring = false
            }
        } label: {
            HStack(spacing: 8) {
                if isRestoring {
                    ProgressView()
                        .tint(.white.opacity(0.6))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text("Restore Purchases")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isRestoring)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
    }

    private var cardBackground: some ShapeStyle {
        Color.white.opacity(0.05)
    }

    private var eraAccentColor: Color {
        EraTheme.theme(for: player.currentEra).accent
    }

    private func iconForCosmeticType(_ type: CosmeticType) -> String {
        switch type {
        case .skin: return "paintbrush.fill"
        case .particleEffect: return "sparkles"
        case .uiTheme: return "rectangle.dashed"
        case .relicAppearance: return "seal.fill"
        case .avatar: return "person.crop.circle.fill"
        }
    }

    private func displayName(for type: CosmeticType) -> String {
        switch type {
        case .skin: return "Era Skin"
        case .particleEffect: return "Particle Effect"
        case .uiTheme: return "UI Theme"
        case .relicAppearance: return "Relic Appearance"
        case .avatar: return "Avatar"
        }
    }
}
