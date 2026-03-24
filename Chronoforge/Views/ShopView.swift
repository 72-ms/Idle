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
                vipStatusSection
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

            chronoPassCard

            // VIP subscription (earns VIP points monthly + passive perks)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.mint)
                    Text("VIP Monthly")
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
                    Text("+1000 pts/mo")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Label("2x offline earnings while active", systemImage: "checkmark")
                    Label("50 Chrono Shards daily while active", systemImage: "checkmark")
                    Label("1000 VIP Points each billing cycle", systemImage: "checkmark")
                    Label("Ad-free experience", systemImage: "checkmark")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

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

    // MARK: - VIP Status

    private var vipStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("VIP Status", symbol: "crown.fill")

            // Status card with tier + progress
            VStack(spacing: 16) {
                // Current tier display
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(vipTierColor(store.vipProgress.currentTier).opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: store.vipProgress.currentTier.symbolName)
                            .font(.title2)
                            .foregroundStyle(vipTierColor(store.vipProgress.currentTier))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(store.vipProgress.currentTier == .none
                                 ? "No VIP Tier"
                                 : "\(store.vipProgress.currentTier.displayName) VIP")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)

                            if store.vipProgress.currentTier != .none {
                                Text(store.vipProgress.currentTier.displayName)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(vipTierColor(store.vipProgress.currentTier))
                                    .clipShape(Capsule())
                            }
                        }

                        Text("\(store.vipProgress.totalPoints) VIP Points")
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()
                }

                // Progress to next tier
                if let next = store.vipProgress.nextTier {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Next: \(next.displayName)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(vipTierColor(next))
                            Spacer()
                            Text("\(store.vipProgress.pointsToNextTier ?? 0) pts to go")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [vipTierColor(store.vipProgress.currentTier),
                                                 vipTierColor(next)],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: max(0, geo.size.width * store.vipProgress.progressToNextTier))
                            }
                        }
                        .frame(height: 8)
                    }
                } else {
                    Text("Maximum VIP tier reached")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(vipTierColor(.obsidian))
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Text("Every purchase earns VIP Points based on its value.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(vipTierColor(store.vipProgress.currentTier).opacity(0.25), lineWidth: 1)
            )

            // Current tier perks
            if store.vipProgress.currentTier != .none {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Perks")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))

                    ForEach(Array(store.vipProgress.currentTier.perks.enumerated()), id: \.offset) { _, perk in
                        Label(perk.displayText, systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(vipTierColor(store.vipProgress.currentTier).opacity(0.85))
                    }
                }
                .padding(14)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // VIP tier packs
            vipTierPacksList
        }
    }

    private var vipTierPacksList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tier Exclusive Packs")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))

            ForEach(store.vipTierPacks) { pack in
                let isUnlocked = store.vipProgress.currentTier >= pack.tier
                let isClaimed = store.vipProgress.hasClaimed(pack.tier)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(vipTierColor(pack.tier).opacity(isUnlocked ? 0.15 : 0.05))
                            .frame(width: 40, height: 40)
                        Image(systemName: pack.tier.symbolName)
                            .font(.body)
                            .foregroundStyle(isUnlocked ? vipTierColor(pack.tier) : .white.opacity(0.2))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pack.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isUnlocked ? .white : .white.opacity(0.35))

                        if !isUnlocked {
                            Text("Reach \(pack.tier.displayName) VIP to unlock")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.3))
                        } else {
                            HStack(spacing: 6) {
                                vipPackTag("\(pack.shards) Shards")
                                vipPackTag("\(pack.crystals) Crystals")
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    if isClaimed {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(vipTierColor(pack.tier))
                    } else if isUnlocked {
                        Button {
                            Task {
                                isPurchasing = true
                                _ = await store.purchaseVIPTierPack(pack)
                                isPurchasing = false
                            }
                        } label: {
                            Text(store.product(forVIPTierPack: pack)?.displayPrice ?? "Buy")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(vipTierColor(pack.tier))
                                .clipShape(Capsule())
                        }
                        .disabled(isPurchasing)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.2))
                    }
                }
                .padding(10)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(isUnlocked ? 1.0 : 0.6)
            }
        }
    }

    private func vipPackTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.5))
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

    // MARK: - VIP Helpers

    private func vipTierColor(_ tier: VIPTier) -> Color {
        switch tier {
        case .none: return .gray
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .diamond: return Color(red: 0.53, green: 0.81, blue: 0.98)
        case .obsidian: return Color(red: 0.60, green: 0.20, blue: 0.90)
        }
    }
}
