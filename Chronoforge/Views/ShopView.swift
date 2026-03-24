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
                premiumBundlesSection
                currencyPacksSection
                boostersAndWarpsSection
                subscriptionsSection
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

    // MARK: - Premium Bundles

    private var premiumBundlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Premium Bundles", symbol: "gift.fill")

            ForEach(store.premiumBundles) { bundle in
                let isOwned = isBundleOwned(bundle)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(bundleAccentColor(bundle).opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: bundleIcon(bundle))
                                .font(.title3)
                                .foregroundStyle(bundleAccentColor(bundle))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(bundle.name)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)

                                Text(bundle.badge)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(bundleAccentColor(bundle))
                                    .clipShape(Capsule())
                            }

                            Text(bundle.description)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(3)
                        }

                        Spacer(minLength: 0)
                    }

                    // Contents preview
                    HStack(spacing: 12) {
                        bundleContentTag("\(bundle.shards) Shards", symbol: "diamond.fill")
                        bundleContentTag("\(bundle.crystals) Crystals", symbol: "hexagon.fill")
                        if bundle.permanentTapBonus > 0 {
                            bundleContentTag("+\(NSDecimalNumber(decimal: bundle.permanentTapBonus))x Tap", symbol: "hand.tap.fill")
                        }
                    }
                    .font(.caption2)

                    if isOwned {
                        Label("Owned", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(bundleAccentColor(bundle))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    } else {
                        Button {
                            Task {
                                isPurchasing = true
                                _ = await store.purchaseBundle(bundle)
                                isPurchasing = false
                            }
                        } label: {
                            Text(store.product(forBundle: bundle)?.displayPrice ?? "Purchase")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(bundleAccentColor(bundle))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isPurchasing)
                    }
                }
                .padding(16)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(bundleAccentColor(bundle).opacity(0.2), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Currency Packs

    private var currencyPacksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Chrono Shards", symbol: "diamond.fill")

            let shardPacks = store.currencyPacks.filter { $0.currencyType == .chronoShards }
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(shardPacks) { pack in
                    currencyPackCard(pack, accent: .cyan)
                }
            }

            sectionHeader("Epoch Crystals", symbol: "hexagon.fill")

            let crystalPacks = store.currencyPacks.filter { $0.currencyType == .epochCrystals }
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(crystalPacks) { pack in
                    currencyPackCard(pack, accent: .purple)
                }
            }
        }
    }

    private func currencyPackCard(_ pack: CurrencyPack, accent: Color) -> some View {
        Button {
            Task {
                isPurchasing = true
                _ = await store.purchaseCurrencyPack(pack)
                isPurchasing = false
            }
        } label: {
            VStack(spacing: 8) {
                if let badge = pack.badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accent)
                        .clipShape(Capsule())
                }

                Text("\(pack.totalAmount)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)

                Text(pack.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if pack.bonusAmount > 0 {
                    Text("+\(pack.bonusAmount) bonus")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(accent.opacity(0.7))
                }

                Text(store.product(forCurrencyPack: pack)?.displayPrice ?? "—")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    // MARK: - Boosters & Time Warps

    private var boostersAndWarpsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Time Warps", symbol: "clock.arrow.2.circlepath")

            ForEach(store.timeWarpPacks) { warp in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "clock.arrow.2.circlepath")
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(warp.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(warp.description)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer(minLength: 0)

                    Button {
                        Task {
                            isPurchasing = true
                            _ = await store.purchaseTimeWarp(warp)
                            isPurchasing = false
                        }
                    } label: {
                        Text(store.product(forTimeWarp: warp)?.displayPrice ?? "—")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.green)
                            .clipShape(Capsule())
                    }
                    .disabled(isPurchasing)
                }
                .padding(12)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            sectionHeader("Production Boosters", symbol: "bolt.fill")

            ForEach(store.boosterPacks) { booster in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(booster.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(booster.description)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer(minLength: 0)

                    Button {
                        Task {
                            isPurchasing = true
                            _ = await store.purchaseBooster(booster)
                            isPurchasing = false
                        }
                    } label: {
                        Text(store.product(forBooster: booster)?.displayPrice ?? "—")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.orange)
                            .clipShape(Capsule())
                    }
                    .disabled(isPurchasing)
                }
                .padding(12)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - Subscriptions

    private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Subscriptions", symbol: "crown.fill")

            // Chrono Pass
            chronoPassCard

            // VIP
            vipCard
        }
    }

    private var chronoPassCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "shield.checkerboard")
                    .foregroundStyle(.yellow)
                Text("Chrono Pass")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("Tier \(store.chronoPassProgress.currentTier) / \(ChronoPassProgress.totalTiers)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.7))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.yellow, .yellow.opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * store.xpProgressForCurrentTier())
                }
            }
            .frame(height: 8)

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
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var vipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.mint)
                Text("VIP Membership")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                if store.isVIPActive {
                    Text("Active")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.mint)
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                vipPerk("2x offline earnings")
                vipPerk("50 Chrono Shards daily")
                vipPerk("Exclusive VIP avatar frame")
                vipPerk("Priority queue for seasonal events")
                vipPerk("Ad-free experience")
            }

            if !store.isVIPActive {
                Button {
                    Task {
                        isPurchasing = true
                        _ = await store.purchaseVIP()
                        isPurchasing = false
                    }
                } label: {
                    Text(store.vipProduct?.displayPrice.map { "\($0)/month" } ?? "Subscribe")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.mint)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isPurchasing)
            }
        }
        .padding(16)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func vipPerk(_ text: String) -> some View {
        Label(text, systemImage: "checkmark")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
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

    // MARK: - Bundle Helpers

    private func isBundleOwned(_ bundle: PremiumBundle) -> Bool {
        switch bundle.productID {
        case StoreManager.ProductIDs.progressionBundle: return store.hasProgressionBundle
        case StoreManager.ProductIDs.legendaryBundle: return store.hasLegendaryBundle
        case StoreManager.ProductIDs.titanBundle: return store.hasTitanBundle
        default: return false
        }
    }

    private func bundleAccentColor(_ bundle: PremiumBundle) -> Color {
        switch bundle.accent {
        case .blue: return .blue
        case .purple: return .purple
        case .gold: return .yellow
        }
    }

    private func bundleIcon(_ bundle: PremiumBundle) -> String {
        switch bundle.accent {
        case .blue: return "shippingbox.fill"
        case .purple: return "star.circle.fill"
        case .gold: return "crown.fill"
        }
    }

    private func bundleContentTag(_ text: String, symbol: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 8))
            Text(text)
        }
        .foregroundStyle(.white.opacity(0.5))
    }
}
