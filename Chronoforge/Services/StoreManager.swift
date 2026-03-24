import Foundation
import StoreKit

// MARK: - Cosmetic Types

enum CosmeticType: String, Codable, CaseIterable {
    case skin
    case particleEffect
    case uiTheme
    case relicAppearance
    case avatar
}

// MARK: - CosmeticItem

struct CosmeticItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let type: CosmeticType
    let era: Era?
    let productID: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CosmeticItem, rhs: CosmeticItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - ChronoPass

struct ChronoPassTierReward: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let isPremium: Bool
    let cosmeticID: String?
    let shardAmount: Int?
}

struct ChronoPassTier: Codable, Identifiable {
    let id: Int
    let xpRequired: Int
    let freeReward: ChronoPassTierReward
    let premiumReward: ChronoPassTierReward
}

struct ChronoPassProgress: Codable {
    var currentTier: Int
    var currentXP: Int
    var claimedFreeTiers: Set<Int>
    var claimedPremiumTiers: Set<Int>

    static let totalTiers = 30

    var isMaxTier: Bool {
        currentTier >= Self.totalTiers
    }

    mutating func addXP(_ amount: Int, tiers: [ChronoPassTier]) {
        guard !isMaxTier else { return }
        currentXP += amount
        while currentTier < Self.totalTiers {
            let requiredXP = tiers[safe: currentTier]?.xpRequired ?? Int.max
            if currentXP >= requiredXP {
                currentXP -= requiredXP
                currentTier += 1
            } else {
                break
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Currency Pack

struct CurrencyPack: Identifiable {
    let id: String
    let name: String
    let description: String
    let productID: String
    let amount: Int
    let bonusAmount: Int
    let currencyType: CurrencyPackType
    let badge: String?

    var totalAmount: Int { amount + bonusAmount }

    enum CurrencyPackType: String {
        case chronoShards
        case epochCrystals
    }
}

// MARK: - Time Warp Pack

struct TimeWarpPack: Identifiable {
    let id: String
    let name: String
    let description: String
    let productID: String
    let hours: Int
}

// MARK: - Booster Pack

struct BoosterPack: Identifiable {
    let id: String
    let name: String
    let description: String
    let productID: String
    let multiplier: Decimal
    let durationMinutes: Int
}

// MARK: - Premium Bundle

struct PremiumBundle: Identifiable {
    let id: String
    let name: String
    let description: String
    let productID: String
    let shards: Int
    let crystals: Int
    let boostMultiplier: Decimal
    let boostMinutes: Int
    let relicMaterials: Int
    let exclusiveCosmeticID: String?
    let permanentTapBonus: Decimal
    let badge: String
    let accent: BundleAccent

    enum BundleAccent: String {
        case blue, purple, gold
    }
}

// MARK: - VIP System

enum VIPTier: Int, Codable, CaseIterable, Comparable {
    case none = 0
    case bronze = 1
    case silver = 2
    case gold = 3
    case diamond = 4
    case obsidian = 5

    static func < (lhs: VIPTier, rhs: VIPTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .diamond: return "Diamond"
        case .obsidian: return "Obsidian"
        }
    }

    var pointsRequired: Int {
        switch self {
        case .none: return 0
        case .bronze: return 100
        case .silver: return 500
        case .gold: return 2000
        case .diamond: return 8000
        case .obsidian: return 25000
        }
    }

    var nextTier: VIPTier? {
        VIPTier(rawValue: rawValue + 1)
    }

    var symbolName: String {
        switch self {
        case .none: return "circle"
        case .bronze: return "shield.fill"
        case .silver: return "shield.lefthalf.filled"
        case .gold: return "crown.fill"
        case .diamond: return "diamond.fill"
        case .obsidian: return "sparkle"
        }
    }

    /// Passive perks that apply while at this tier or above.
    var perks: [VIPPerk] {
        switch self {
        case .none:
            return []
        case .bronze:
            return [
                .productionBonus(0.1),
                .dailyShards(25),
                .exclusiveAvatar("vip_bronze_frame")
            ]
        case .silver:
            return [
                .productionBonus(0.25),
                .dailyShards(75),
                .offlineBonus(0.15),
                .exclusiveAvatar("vip_silver_frame"),
                .shopDiscount(0.05)
            ]
        case .gold:
            return [
                .productionBonus(0.5),
                .dailyShards(150),
                .offlineBonus(0.3),
                .exclusiveAvatar("vip_gold_frame"),
                .shopDiscount(0.10),
                .bonusCurrencyOnPurchase(0.10)
            ]
        case .diamond:
            return [
                .productionBonus(1.0),
                .dailyShards(300),
                .offlineBonus(0.5),
                .exclusiveAvatar("vip_diamond_frame"),
                .shopDiscount(0.15),
                .bonusCurrencyOnPurchase(0.20),
                .exclusiveParticle("vip_diamond_aura")
            ]
        case .obsidian:
            return [
                .productionBonus(2.0),
                .dailyShards(500),
                .offlineBonus(1.0),
                .exclusiveAvatar("vip_obsidian_frame"),
                .shopDiscount(0.20),
                .bonusCurrencyOnPurchase(0.35),
                .exclusiveParticle("vip_obsidian_void"),
                .exclusiveTheme("vip_obsidian_theme"),
                .leaderboardBadge
            ]
        }
    }
}

enum VIPPerk {
    case productionBonus(Double)        // e.g. 0.1 = +10% production
    case dailyShards(Int)               // free shards per day
    case offlineBonus(Double)           // e.g. 0.15 = +15% offline earnings
    case shopDiscount(Double)           // e.g. 0.05 = 5% bonus currency on pack purchases
    case bonusCurrencyOnPurchase(Double) // e.g. 0.10 = +10% bonus on currency pack buys
    case exclusiveAvatar(String)        // cosmetic ID
    case exclusiveParticle(String)      // cosmetic ID
    case exclusiveTheme(String)         // cosmetic ID
    case leaderboardBadge               // special badge on leaderboard

    var displayText: String {
        switch self {
        case .productionBonus(let pct): return "+\(Int(pct * 100))% production"
        case .dailyShards(let n): return "\(n) Chrono Shards daily"
        case .offlineBonus(let pct): return "+\(Int(pct * 100))% offline earnings"
        case .shopDiscount(let pct): return "\(Int(pct * 100))% bonus on pack purchases"
        case .bonusCurrencyOnPurchase(let pct): return "+\(Int(pct * 100))% extra currency on buys"
        case .exclusiveAvatar: return "Exclusive avatar frame"
        case .exclusiveParticle: return "Exclusive particle effect"
        case .exclusiveTheme: return "Exclusive UI theme"
        case .leaderboardBadge: return "Leaderboard VIP badge"
        }
    }
}

struct VIPProgress: Codable {
    var totalPoints: Int = 0
    var claimedTierPacks: Set<Int> = []  // VIPTier rawValues that have been claimed

    var currentTier: VIPTier {
        for tier in VIPTier.allCases.reversed() {
            if totalPoints >= tier.pointsRequired {
                return tier
            }
        }
        return .none
    }

    var nextTier: VIPTier? { currentTier.nextTier }

    var pointsToNextTier: Int? {
        guard let next = nextTier else { return nil }
        return max(0, next.pointsRequired - totalPoints)
    }

    var progressToNextTier: Double {
        guard let next = nextTier else { return 1.0 }
        let current = currentTier.pointsRequired
        let range = next.pointsRequired - current
        guard range > 0 else { return 1.0 }
        return Double(totalPoints - current) / Double(range)
    }

    func hasClaimed(_ tier: VIPTier) -> Bool {
        claimedTierPacks.contains(tier.rawValue)
    }

    mutating func claim(_ tier: VIPTier) {
        claimedTierPacks.insert(tier.rawValue)
    }
}

struct VIPTierPack: Identifiable {
    let id: String
    let tier: VIPTier
    let name: String
    let description: String
    let productID: String
    let shards: Int
    let crystals: Int
    let relicMaterials: Int
    let boostMultiplier: Decimal
    let boostMinutes: Int
    let exclusiveCosmeticID: String?
}

// MARK: - VIP Point Values

/// Maps product IDs to VIP points earned on purchase.
/// Roughly 100 points per $1 USD spent.
enum VIPPointMap {
    static func points(for productID: String) -> Int {
        switch productID {
        // Shard packs
        case StoreManager.ProductIDs.shardPackSmall: return 100
        case StoreManager.ProductIDs.shardPackMedium: return 300
        case StoreManager.ProductIDs.shardPackLarge: return 500
        case StoreManager.ProductIDs.shardPackHuge: return 1000
        case StoreManager.ProductIDs.shardPackMega: return 2500

        // Crystal packs
        case StoreManager.ProductIDs.crystalPackSmall: return 300
        case StoreManager.ProductIDs.crystalPackMedium: return 700
        case StoreManager.ProductIDs.crystalPackLarge: return 2000

        // Time warps
        case StoreManager.ProductIDs.timeWarp1h: return 100
        case StoreManager.ProductIDs.timeWarp8h: return 300
        case StoreManager.ProductIDs.timeWarp24h: return 500

        // Boosters
        case StoreManager.ProductIDs.boost2x30m: return 100
        case StoreManager.ProductIDs.boost5x30m: return 200
        case StoreManager.ProductIDs.boost10x1h: return 500

        // Subscriptions (points each billing cycle)
        case StoreManager.ProductIDs.chronoPassMonthly: return 500
        case StoreManager.ProductIDs.vipMonthly: return 1000

        // One-time purchases
        case StoreManager.ProductIDs.removeAds: return 300
        case StoreManager.ProductIDs.starterPack: return 500
        case StoreManager.ProductIDs.progressionBundle: return 1000
        case StoreManager.ProductIDs.legendaryBundle: return 3000
        case StoreManager.ProductIDs.titanBundle: return 10000

        // VIP tier packs
        case StoreManager.ProductIDs.vipTierPackBronze: return 300
        case StoreManager.ProductIDs.vipTierPackSilver: return 700
        case StoreManager.ProductIDs.vipTierPackGold: return 1500
        case StoreManager.ProductIDs.vipTierPackDiamond: return 5000
        case StoreManager.ProductIDs.vipTierPackObsidian: return 15000

        // Cosmetics (~$1-3 each)
        default:
            if productID.hasPrefix(StoreManager.ProductIDs.cosmeticPrefix) {
                return 150
            }
            return 0
        }
    }
}

// MARK: - StoreManager

@Observable
final class StoreManager {

    // MARK: - Product IDs

    struct ProductIDs {
        static let removeAds = "com.chronoforge.removeads"
        static let starterPack = "com.chronoforge.starterpack"
        static let chronoPassMonthly = "com.chronoforge.chronopass.monthly"

        // VIP subscription
        static let vipMonthly = "com.chronoforge.vip.monthly"

        // Chrono Shard packs (consumable)
        static let shardPackSmall = "com.chronoforge.shards.small"
        static let shardPackMedium = "com.chronoforge.shards.medium"
        static let shardPackLarge = "com.chronoforge.shards.large"
        static let shardPackHuge = "com.chronoforge.shards.huge"
        static let shardPackMega = "com.chronoforge.shards.mega"

        // Epoch Crystal packs (consumable)
        static let crystalPackSmall = "com.chronoforge.crystals.small"
        static let crystalPackMedium = "com.chronoforge.crystals.medium"
        static let crystalPackLarge = "com.chronoforge.crystals.large"

        // Time Warp (consumable) - skip hours of production
        static let timeWarp1h = "com.chronoforge.timewarp.1h"
        static let timeWarp8h = "com.chronoforge.timewarp.8h"
        static let timeWarp24h = "com.chronoforge.timewarp.24h"

        // Booster packs (consumable) - temporary production multiplier
        static let boost2x30m = "com.chronoforge.boost.2x30m"
        static let boost5x30m = "com.chronoforge.boost.5x30m"
        static let boost10x1h = "com.chronoforge.boost.10x1h"

        // Premium bundles (one-time)
        static let progressionBundle = "com.chronoforge.bundle.progression"
        static let legendaryBundle = "com.chronoforge.bundle.legendary"
        static let titanBundle = "com.chronoforge.bundle.titan"

        // VIP tier exclusive packs (one-time, unlocked at each tier)
        static let vipTierPackBronze = "com.chronoforge.vip.pack.bronze"
        static let vipTierPackSilver = "com.chronoforge.vip.pack.silver"
        static let vipTierPackGold = "com.chronoforge.vip.pack.gold"
        static let vipTierPackDiamond = "com.chronoforge.vip.pack.diamond"
        static let vipTierPackObsidian = "com.chronoforge.vip.pack.obsidian"

        // Cosmetic shop prefixes
        static let cosmeticPrefix = "com.chronoforge.cosmetic."

        static let skinPrefix = "\(cosmeticPrefix)skin."
        static let particleEffectPrefix = "\(cosmeticPrefix)particle."
        static let uiThemePrefix = "\(cosmeticPrefix)theme."
        static let relicAppearancePrefix = "\(cosmeticPrefix)relic."
        static let avatarPrefix = "\(cosmeticPrefix)avatar."

        static var allProductIDs: Set<String> {
            Set([
                removeAds, starterPack, chronoPassMonthly, vipMonthly,
                shardPackSmall, shardPackMedium, shardPackLarge, shardPackHuge, shardPackMega,
                crystalPackSmall, crystalPackMedium, crystalPackLarge,
                timeWarp1h, timeWarp8h, timeWarp24h,
                boost2x30m, boost5x30m, boost10x1h,
                progressionBundle, legendaryBundle, titanBundle,
                vipTierPackBronze, vipTierPackSilver, vipTierPackGold,
                vipTierPackDiamond, vipTierPackObsidian
            ])
        }
    }

    // MARK: - Entitlements

    private(set) var isAdFree: Bool = false
    private(set) var isChronoPassActive: Bool = false
    private(set) var isVIPActive: Bool = false
    private(set) var hasStarterPack: Bool = false
    private(set) var hasProgressionBundle: Bool = false
    private(set) var hasLegendaryBundle: Bool = false
    private(set) var hasTitanBundle: Bool = false
    private(set) var ownedCosmeticIDs: Set<String> = []

    // MARK: - Products

    private(set) var products: [Product] = []
    private(set) var removeAdsProduct: Product?
    private(set) var starterPackProduct: Product?
    private(set) var chronoPassProduct: Product?
    private(set) var vipProduct: Product?
    private(set) var cosmeticProducts: [Product] = []
    private(set) var currencyPackProducts: [Product] = []
    private(set) var timeWarpProducts: [Product] = []
    private(set) var boosterProducts: [Product] = []
    private(set) var bundleProducts: [Product] = []
    private(set) var vipTierPackProducts: [Product] = []

    // MARK: - VIP State

    var vipProgress: VIPProgress = VIPProgress()
    private(set) var vipTierPacks: [VIPTierPack] = []
    private let vipProgressKey = "StoreManager.vipProgress"

    // MARK: - Chrono Pass State

    private(set) var chronoPassTiers: [ChronoPassTier] = []
    var chronoPassProgress: ChronoPassProgress = ChronoPassProgress(
        currentTier: 0,
        currentXP: 0,
        claimedFreeTiers: [],
        claimedPremiumTiers: []
    )

    // MARK: - Catalogs

    private(set) var cosmeticCatalog: [CosmeticItem] = []
    private(set) var currencyPacks: [CurrencyPack] = []
    private(set) var timeWarpPacks: [TimeWarpPack] = []
    private(set) var boosterPacks: [BoosterPack] = []
    private(set) var premiumBundles: [PremiumBundle] = []

    // MARK: - Purchase State

    private(set) var purchaseInProgress: Bool = false
    private(set) var lastError: String?

    // MARK: - Private

    private var transactionListener: Task<Void, Error>?
    private let entitlementsCacheKey = "StoreManager.entitlements"
    private let chronoPassProgressKey = "StoreManager.chronoPassProgress"

    /// Callback invoked when a consumable purchase needs to grant resources.
    /// Set by AppState/GameEngine to wire up resource delivery.
    var onConsumablePurchased: ((ConsumableReward) -> Void)?

    enum ConsumableReward {
        case chronoShards(Int)
        case epochCrystals(Int)
        case timeWarp(hours: Int)
        case productionBoost(multiplier: Decimal, minutes: Int)
        case bundle(shards: Int, crystals: Int, relicMaterials: Int,
                    boostMultiplier: Decimal, boostMinutes: Int,
                    permanentTapBonus: Decimal, cosmeticID: String?)
        case vipTierPack(shards: Int, crystals: Int, relicMaterials: Int,
                         boostMultiplier: Decimal, boostMinutes: Int,
                         cosmeticID: String?)
        case vipCosmeticGrant(String)
    }

    // MARK: - Init

    init() {
        loadCachedEntitlements()
        loadChronoPassProgress()
        loadVIPProgress()
        buildChronoPassTiers()
        buildCosmeticCatalog()
        buildCurrencyPacks()
        buildTimeWarpPacks()
        buildBoosterPacks()
        buildPremiumBundles()
        buildVIPTierPacks()

        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    @MainActor
    func loadProducts() async {
        do {
            var allIDs = ProductIDs.allProductIDs
            for item in cosmeticCatalog {
                allIDs.insert(item.productID)
            }

            let storeProducts = try await Product.products(for: allIDs)
            products = storeProducts.sorted { $0.price < $1.price }

            removeAdsProduct = storeProducts.first { $0.id == ProductIDs.removeAds }
            starterPackProduct = storeProducts.first { $0.id == ProductIDs.starterPack }
            chronoPassProduct = storeProducts.first { $0.id == ProductIDs.chronoPassMonthly }
            vipProduct = storeProducts.first { $0.id == ProductIDs.vipMonthly }
            cosmeticProducts = storeProducts.filter { $0.id.hasPrefix(ProductIDs.cosmeticPrefix) }

            let currencyIDs = Set(currencyPacks.map(\.productID))
            currencyPackProducts = storeProducts.filter { currencyIDs.contains($0.id) }

            let timeWarpIDs = Set(timeWarpPacks.map(\.productID))
            timeWarpProducts = storeProducts.filter { timeWarpIDs.contains($0.id) }

            let boosterIDs = Set(boosterPacks.map(\.productID))
            boosterProducts = storeProducts.filter { boosterIDs.contains($0.id) }

            let bundleIDs = Set(premiumBundles.map(\.productID))
            bundleProducts = storeProducts.filter { bundleIDs.contains($0.id) }

            let vipPackIDs = Set(vipTierPacks.map(\.productID))
            vipTierPackProducts = storeProducts.filter { vipPackIDs.contains($0.id) }
        } catch {
            lastError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async -> Bool {
        guard !purchaseInProgress else { return false }
        purchaseInProgress = true
        lastError = nil

        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerification(verification)
                await applyTransaction(transaction)
                await transaction.finish()
                awardVIPPoints(for: product.id)
                return true

            case .userCancelled:
                return false

            case .pending:
                lastError = "Purchase is pending approval."
                return false

            @unknown default:
                lastError = "Unknown purchase result."
                return false
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    @MainActor
    func purchaseCosmetic(_ item: CosmeticItem) async -> Bool {
        guard let product = cosmeticProducts.first(where: { $0.id == item.productID }) else {
            lastError = "Product not found for cosmetic: \(item.name)"
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseRemoveAds() async -> Bool {
        guard let product = removeAdsProduct else {
            lastError = "Remove Ads product not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseStarterPack() async -> Bool {
        guard !hasStarterPack else {
            lastError = "Starter Pack already owned."
            return false
        }
        guard let product = starterPackProduct else {
            lastError = "Starter Pack product not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseChronoPass() async -> Bool {
        guard let product = chronoPassProduct else {
            lastError = "Chrono Pass product not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseVIP() async -> Bool {
        guard let product = vipProduct else {
            lastError = "VIP subscription not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseCurrencyPack(_ pack: CurrencyPack) async -> Bool {
        guard let product = currencyPackProducts.first(where: { $0.id == pack.productID }) else {
            lastError = "Currency pack not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseTimeWarp(_ pack: TimeWarpPack) async -> Bool {
        guard let product = timeWarpProducts.first(where: { $0.id == pack.productID }) else {
            lastError = "Time Warp not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseBooster(_ pack: BoosterPack) async -> Bool {
        guard let product = boosterProducts.first(where: { $0.id == pack.productID }) else {
            lastError = "Booster not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseBundle(_ bundle: PremiumBundle) async -> Bool {
        guard let product = bundleProducts.first(where: { $0.id == bundle.productID }) else {
            lastError = "Bundle not available."
            return false
        }
        return await purchase(product)
    }

    @MainActor
    func purchaseVIPTierPack(_ pack: VIPTierPack) async -> Bool {
        guard vipProgress.currentTier >= pack.tier else {
            lastError = "You must reach \(pack.tier.displayName) VIP to unlock this pack."
            return false
        }
        guard !vipProgress.hasClaimed(pack.tier) else {
            lastError = "You have already purchased this tier pack."
            return false
        }
        guard let product = vipTierPackProducts.first(where: { $0.id == pack.productID }) else {
            lastError = "VIP tier pack not available."
            return false
        }
        return await purchase(product)
    }

    // MARK: - Product Lookup

    func product(forCurrencyPack pack: CurrencyPack) -> Product? {
        currencyPackProducts.first { $0.id == pack.productID }
    }

    func product(forTimeWarp pack: TimeWarpPack) -> Product? {
        timeWarpProducts.first { $0.id == pack.productID }
    }

    func product(forBooster pack: BoosterPack) -> Product? {
        boosterProducts.first { $0.id == pack.productID }
    }

    func product(forBundle bundle: PremiumBundle) -> Product? {
        bundleProducts.first { $0.id == bundle.productID }
    }

    func product(forVIPTierPack pack: VIPTierPack) -> Product? {
        vipTierPackProducts.first { $0.id == pack.productID }
    }

    // MARK: - Restore Purchases

    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Entitlements

    @MainActor
    func refreshEntitlements() async {
        var adFree = false
        var passActive = false
        var vipActive = false
        var starterOwned = false
        var progressionOwned = false
        var legendaryOwned = false
        var titanOwned = false
        var cosmetics: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerification(result) else { continue }

            switch transaction.productID {
            case ProductIDs.removeAds:
                if transaction.revocationDate == nil {
                    adFree = true
                }

            case ProductIDs.starterPack:
                if transaction.revocationDate == nil {
                    starterOwned = true
                }

            case ProductIDs.chronoPassMonthly:
                if transaction.revocationDate == nil,
                   let expirationDate = transaction.expirationDate,
                   expirationDate > Date() {
                    passActive = true
                }

            case ProductIDs.vipMonthly:
                if transaction.revocationDate == nil,
                   let expirationDate = transaction.expirationDate,
                   expirationDate > Date() {
                    vipActive = true
                }

            case ProductIDs.progressionBundle:
                if transaction.revocationDate == nil { progressionOwned = true }

            case ProductIDs.legendaryBundle:
                if transaction.revocationDate == nil { legendaryOwned = true }

            case ProductIDs.titanBundle:
                if transaction.revocationDate == nil { titanOwned = true }

            default:
                if transaction.productID.hasPrefix(ProductIDs.cosmeticPrefix),
                   transaction.revocationDate == nil {
                    if let cosmeticItem = cosmeticCatalog.first(where: { $0.productID == transaction.productID }) {
                        cosmetics.insert(cosmeticItem.id)
                    }
                }
                // Consumables (shards, crystals, time warps, boosters) are
                // handled at purchase time via applyTransaction — they don't
                // persist as entitlements.
            }
        }

        isAdFree = adFree
        isChronoPassActive = passActive
        isVIPActive = vipActive
        hasStarterPack = starterOwned
        hasProgressionBundle = progressionOwned
        hasLegendaryBundle = legendaryOwned
        hasTitanBundle = titanOwned
        ownedCosmeticIDs = cosmetics

        cacheEntitlements()
    }

    func ownsCosmetic(_ itemID: String) -> Bool {
        ownedCosmeticIDs.contains(itemID)
    }

    func ownsCosmetic(_ item: CosmeticItem) -> Bool {
        ownedCosmeticIDs.contains(item.id)
    }

    // MARK: - Chrono Pass

    func addChronoPassXP(_ amount: Int) {
        guard isChronoPassActive || chronoPassProgress.currentTier < ChronoPassProgress.totalTiers else { return }
        chronoPassProgress.addXP(amount, tiers: chronoPassTiers)
        saveChronoPassProgress()
    }

    func claimFreeTierReward(tier: Int) -> ChronoPassTierReward? {
        guard tier <= chronoPassProgress.currentTier,
              !chronoPassProgress.claimedFreeTiers.contains(tier),
              let passTier = chronoPassTiers[safe: tier] else {
            return nil
        }
        chronoPassProgress.claimedFreeTiers.insert(tier)
        saveChronoPassProgress()
        return passTier.freeReward
    }

    func claimPremiumTierReward(tier: Int) -> ChronoPassTierReward? {
        guard isChronoPassActive,
              tier <= chronoPassProgress.currentTier,
              !chronoPassProgress.claimedPremiumTiers.contains(tier),
              let passTier = chronoPassTiers[safe: tier] else {
            return nil
        }
        chronoPassProgress.claimedPremiumTiers.insert(tier)
        saveChronoPassProgress()
        return passTier.premiumReward
    }

    func xpProgressForCurrentTier() -> Double {
        guard !chronoPassProgress.isMaxTier,
              let tier = chronoPassTiers[safe: chronoPassProgress.currentTier],
              tier.xpRequired > 0 else {
            return chronoPassProgress.isMaxTier ? 1.0 : 0.0
        }
        return Double(chronoPassProgress.currentXP) / Double(tier.xpRequired)
    }

    func resetChronoPassProgress() {
        chronoPassProgress = ChronoPassProgress(
            currentTier: 0,
            currentXP: 0,
            claimedFreeTiers: [],
            claimedPremiumTiers: []
        )
        saveChronoPassProgress()
    }

    // MARK: - Cosmetic Helpers

    func cosmetics(ofType type: CosmeticType) -> [CosmeticItem] {
        cosmeticCatalog.filter { $0.type == type }
    }

    func cosmetics(forEra era: Era) -> [CosmeticItem] {
        cosmeticCatalog.filter { $0.era == era }
    }

    func product(for cosmetic: CosmeticItem) -> Product? {
        cosmeticProducts.first { $0.id == cosmetic.productID }
    }

    // MARK: - Transaction Verification

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerification(result) {
                    await self.applyTransaction(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    @MainActor
    private func applyTransaction(_ transaction: Transaction) async {
        switch transaction.productID {
        case ProductIDs.removeAds:
            isAdFree = transaction.revocationDate == nil

        case ProductIDs.starterPack:
            hasStarterPack = transaction.revocationDate == nil

        case ProductIDs.chronoPassMonthly:
            if transaction.revocationDate == nil,
               let expiration = transaction.expirationDate,
               expiration > Date() {
                isChronoPassActive = true
            } else {
                isChronoPassActive = false
            }

        case ProductIDs.vipMonthly:
            if transaction.revocationDate == nil,
               let expiration = transaction.expirationDate,
               expiration > Date() {
                isVIPActive = true
            } else {
                isVIPActive = false
            }

        case ProductIDs.progressionBundle:
            if transaction.revocationDate == nil {
                hasProgressionBundle = true
                if let bundle = premiumBundles.first(where: { $0.productID == ProductIDs.progressionBundle }) {
                    deliverBundleReward(bundle)
                }
            }

        case ProductIDs.legendaryBundle:
            if transaction.revocationDate == nil {
                hasLegendaryBundle = true
                if let bundle = premiumBundles.first(where: { $0.productID == ProductIDs.legendaryBundle }) {
                    deliverBundleReward(bundle)
                }
            }

        case ProductIDs.titanBundle:
            if transaction.revocationDate == nil {
                hasTitanBundle = true
                if let bundle = premiumBundles.first(where: { $0.productID == ProductIDs.titanBundle }) {
                    deliverBundleReward(bundle)
                }
            }

        default:
            if transaction.productID.hasPrefix(ProductIDs.cosmeticPrefix),
               transaction.revocationDate == nil {
                if let cosmeticItem = cosmeticCatalog.first(where: { $0.productID == transaction.productID }) {
                    ownedCosmeticIDs.insert(cosmeticItem.id)
                }
            } else if let pack = currencyPacks.first(where: { $0.productID == transaction.productID }) {
                switch pack.currencyType {
                case .chronoShards:
                    onConsumablePurchased?(.chronoShards(pack.totalAmount))
                case .epochCrystals:
                    onConsumablePurchased?(.epochCrystals(pack.totalAmount))
                }
            } else if let warp = timeWarpPacks.first(where: { $0.productID == transaction.productID }) {
                onConsumablePurchased?(.timeWarp(hours: warp.hours))
            } else if let booster = boosterPacks.first(where: { $0.productID == transaction.productID }) {
                onConsumablePurchased?(.productionBoost(
                    multiplier: booster.multiplier,
                    minutes: booster.durationMinutes
                ))
            } else if let tierPack = vipTierPacks.first(where: { $0.productID == transaction.productID }) {
                vipProgress.claim(tierPack.tier)
                saveVIPProgress()
                onConsumablePurchased?(.vipTierPack(
                    shards: tierPack.shards,
                    crystals: tierPack.crystals,
                    relicMaterials: tierPack.relicMaterials,
                    boostMultiplier: tierPack.boostMultiplier,
                    boostMinutes: tierPack.boostMinutes,
                    cosmeticID: tierPack.exclusiveCosmeticID
                ))
            }
        }

        cacheEntitlements()
    }

    private func deliverBundleReward(_ bundle: PremiumBundle) {
        onConsumablePurchased?(.bundle(
            shards: bundle.shards,
            crystals: bundle.crystals,
            relicMaterials: bundle.relicMaterials,
            boostMultiplier: bundle.boostMultiplier,
            boostMinutes: bundle.boostMinutes,
            permanentTapBonus: bundle.permanentTapBonus,
            cosmeticID: bundle.exclusiveCosmeticID
        ))
    }

    // MARK: - Persistence

    private func cacheEntitlements() {
        let cache = EntitlementCache(
            isAdFree: isAdFree,
            isChronoPassActive: isChronoPassActive,
            isVIPActive: isVIPActive,
            hasStarterPack: hasStarterPack,
            hasProgressionBundle: hasProgressionBundle,
            hasLegendaryBundle: hasLegendaryBundle,
            hasTitanBundle: hasTitanBundle,
            ownedCosmeticIDs: ownedCosmeticIDs
        )
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: entitlementsCacheKey)
        }
    }

    private func loadCachedEntitlements() {
        guard let data = UserDefaults.standard.data(forKey: entitlementsCacheKey),
              let cache = try? JSONDecoder().decode(EntitlementCache.self, from: data) else {
            return
        }
        isAdFree = cache.isAdFree
        isChronoPassActive = cache.isChronoPassActive
        isVIPActive = cache.isVIPActive
        hasStarterPack = cache.hasStarterPack
        hasProgressionBundle = cache.hasProgressionBundle
        hasLegendaryBundle = cache.hasLegendaryBundle
        hasTitanBundle = cache.hasTitanBundle
        ownedCosmeticIDs = cache.ownedCosmeticIDs
    }

    private func saveChronoPassProgress() {
        if let data = try? JSONEncoder().encode(chronoPassProgress) {
            UserDefaults.standard.set(data, forKey: chronoPassProgressKey)
        }
    }

    private func loadChronoPassProgress() {
        guard let data = UserDefaults.standard.data(forKey: chronoPassProgressKey),
              let progress = try? JSONDecoder().decode(ChronoPassProgress.self, from: data) else {
            return
        }
        chronoPassProgress = progress
    }

    // MARK: - VIP Persistence & Points

    private func saveVIPProgress() {
        if let data = try? JSONEncoder().encode(vipProgress) {
            UserDefaults.standard.set(data, forKey: vipProgressKey)
        }
    }

    private func loadVIPProgress() {
        guard let data = UserDefaults.standard.data(forKey: vipProgressKey),
              let progress = try? JSONDecoder().decode(VIPProgress.self, from: data) else {
            return
        }
        vipProgress = progress
    }

    private func awardVIPPoints(for productID: String) {
        let points = VIPPointMap.points(for: productID)
        guard points > 0 else { return }
        let previousTier = vipProgress.currentTier
        vipProgress.totalPoints += points
        saveVIPProgress()

        // Grant cosmetics for newly reached tiers
        let newTier = vipProgress.currentTier
        if newTier > previousTier {
            grantVIPTierCosmetics(from: previousTier, to: newTier)
        }
    }

    private func grantVIPTierCosmetics(from oldTier: VIPTier, to newTier: VIPTier) {
        for tier in VIPTier.allCases where tier > oldTier && tier <= newTier {
            for perk in tier.perks {
                switch perk {
                case .exclusiveAvatar(let id), .exclusiveParticle(let id), .exclusiveTheme(let id):
                    ownedCosmeticIDs.insert(id)
                    onConsumablePurchased?(.vipCosmeticGrant(id))
                default:
                    break
                }
            }
        }
        cacheEntitlements()
    }

    func vipTierPack(for tier: VIPTier) -> VIPTierPack? {
        vipTierPacks.first { $0.tier == tier }
    }

    // MARK: - Chrono Pass Tier Builder

    private func buildChronoPassTiers() {
        chronoPassTiers = (0..<ChronoPassProgress.totalTiers).map { tier in
            let xpRequired = 100 + (tier * 50) // Escalating XP per tier
            return ChronoPassTier(
                id: tier,
                xpRequired: xpRequired,
                freeReward: ChronoPassTierReward(
                    id: "free_tier_\(tier)",
                    name: "Free Reward Tier \(tier + 1)",
                    description: "Chrono Shards and basic items",
                    isPremium: false,
                    cosmeticID: nil,
                    shardAmount: 10 + (tier * 5)
                ),
                premiumReward: ChronoPassTierReward(
                    id: "premium_tier_\(tier)",
                    name: "Premium Reward Tier \(tier + 1)",
                    description: "Exclusive cosmetics and bonus Chrono Shards",
                    isPremium: true,
                    cosmeticID: tier % 5 == 4 ? "pass_cosmetic_\(tier)" : nil,
                    shardAmount: 25 + (tier * 10)
                )
            )
        }
    }

    // MARK: - Cosmetic Catalog Builder

    private func buildCosmeticCatalog() {
        var catalog: [CosmeticItem] = []

        // Era-themed skins
        for era in Era.allCases {
            catalog.append(CosmeticItem(
                id: "skin_\(era.rawValue)",
                name: "\(era.rawValue.capitalized) Era Skin",
                description: "Transform your base with the essence of the \(era.rawValue) era.",
                price: 1.99,
                type: .skin,
                era: era,
                productID: "\(ProductIDs.skinPrefix)\(era.rawValue)"
            ))
        }

        // Particle effects
        let particleEffects: [(String, String, Era?)] = [
            ("temporal_flux", "Temporal Flux", .digital),
            ("ancient_embers", "Ancient Embers", .ancient),
            ("arcane_glyphs", "Arcane Glyphs", .medieval),
            ("star_dust", "Star Dust", .cosmic),
            ("clockwork_gears", "Clockwork Gears", .industrial)
        ]
        for (id, name, era) in particleEffects {
            catalog.append(CosmeticItem(
                id: "particle_\(id)",
                name: name,
                description: "A \(name.lowercased()) particle effect for your timeline.",
                price: 0.99,
                type: .particleEffect,
                era: era,
                productID: "\(ProductIDs.particleEffectPrefix)\(id)"
            ))
        }

        // UI themes
        let uiThemes: [(String, String, Era?)] = [
            ("obsidian_time", "Obsidian Time", nil),
            ("golden_age", "Golden Age", .medieval),
            ("neon_future", "Neon Future", .digital),
            ("parchment", "Ancient Parchment", .ancient),
            ("void_walker", "Void Walker", .cosmic)
        ]
        for (id, name, era) in uiThemes {
            catalog.append(CosmeticItem(
                id: "theme_\(id)",
                name: name,
                description: "Reshape your interface with the \(name) theme.",
                price: 2.99,
                type: .uiTheme,
                era: era,
                productID: "\(ProductIDs.uiThemePrefix)\(id)"
            ))
        }

        // Relic appearances
        let relicAppearances: [(String, String, Era?)] = [
            ("crystal_shard", "Crystal Shard", .ancient),
            ("enchanted_tome", "Enchanted Tome", .medieval),
            ("quantum_core", "Quantum Core", .digital),
            ("solar_prism", "Solar Prism", .cosmic)
        ]
        for (id, name, era) in relicAppearances {
            catalog.append(CosmeticItem(
                id: "relic_\(id)",
                name: name,
                description: "Adorn your relics with the \(name) appearance.",
                price: 1.49,
                type: .relicAppearance,
                era: era,
                productID: "\(ProductIDs.relicAppearancePrefix)\(id)"
            ))
        }

        // Avatars
        let avatars: [(String, String, Era?)] = [
            ("chronomancer", "Chronomancer", nil),
            ("timesmith", "Timesmith", .ancient),
            ("knight_temporal", "Knight Temporal", .medieval),
            ("inventor", "The Inventor", .industrial),
            ("digitizer", "The Digitizer", .digital),
            ("singularity", "Singularity", .cosmic)
        ]
        for (id, name, era) in avatars {
            catalog.append(CosmeticItem(
                id: "avatar_\(id)",
                name: name,
                description: "Take on the visage of the \(name).",
                price: 1.99,
                type: .avatar,
                era: era,
                productID: "\(ProductIDs.avatarPrefix)\(id)"
            ))
        }

        cosmeticCatalog = catalog
    }

    // MARK: - Currency Pack Builder

    private func buildCurrencyPacks() {
        currencyPacks = [
            CurrencyPack(
                id: "shards_small", name: "Handful of Shards",
                description: "A small pouch of Chrono Shards.",
                productID: ProductIDs.shardPackSmall,
                amount: 50, bonusAmount: 0,
                currencyType: .chronoShards, badge: nil
            ),
            CurrencyPack(
                id: "shards_medium", name: "Shard Satchel",
                description: "A generous satchel of Chrono Shards.",
                productID: ProductIDs.shardPackMedium,
                amount: 150, bonusAmount: 25,
                currencyType: .chronoShards, badge: "+17% Bonus"
            ),
            CurrencyPack(
                id: "shards_large", name: "Shard Chest",
                description: "A heavy chest brimming with Chrono Shards.",
                productID: ProductIDs.shardPackLarge,
                amount: 500, bonusAmount: 125,
                currencyType: .chronoShards, badge: "+25% Bonus"
            ),
            CurrencyPack(
                id: "shards_huge", name: "Shard Vault",
                description: "An entire vault of Chrono Shards. Serious collectors only.",
                productID: ProductIDs.shardPackHuge,
                amount: 1200, bonusAmount: 400,
                currencyType: .chronoShards, badge: "+33% Bonus"
            ),
            CurrencyPack(
                id: "shards_mega", name: "Temporal Treasury",
                description: "An unfathomable treasury of Chrono Shards. The ultimate haul.",
                productID: ProductIDs.shardPackMega,
                amount: 3000, bonusAmount: 1500,
                currencyType: .chronoShards, badge: "Best Value"
            ),
            CurrencyPack(
                id: "crystals_small", name: "Crystal Fragment",
                description: "A handful of precious Epoch Crystals.",
                productID: ProductIDs.crystalPackSmall,
                amount: 5, bonusAmount: 0,
                currencyType: .epochCrystals, badge: nil
            ),
            CurrencyPack(
                id: "crystals_medium", name: "Crystal Cluster",
                description: "A cluster of gleaming Epoch Crystals.",
                productID: ProductIDs.crystalPackMedium,
                amount: 15, bonusAmount: 3,
                currencyType: .epochCrystals, badge: "+20% Bonus"
            ),
            CurrencyPack(
                id: "crystals_large", name: "Crystal Motherload",
                description: "A massive cache of Epoch Crystals. Fortune favors the bold.",
                productID: ProductIDs.crystalPackLarge,
                amount: 50, bonusAmount: 15,
                currencyType: .epochCrystals, badge: "Best Value"
            )
        ]
    }

    // MARK: - Time Warp Builder

    private func buildTimeWarpPacks() {
        timeWarpPacks = [
            TimeWarpPack(
                id: "warp_1h", name: "Minor Time Warp",
                description: "Instantly collect 1 hour of production.",
                productID: ProductIDs.timeWarp1h, hours: 1
            ),
            TimeWarpPack(
                id: "warp_8h", name: "Major Time Warp",
                description: "Instantly collect 8 hours of production.",
                productID: ProductIDs.timeWarp8h, hours: 8
            ),
            TimeWarpPack(
                id: "warp_24h", name: "Temporal Rift",
                description: "Instantly collect 24 hours of production. Massive leap forward.",
                productID: ProductIDs.timeWarp24h, hours: 24
            )
        ]
    }

    // MARK: - Booster Builder

    private func buildBoosterPacks() {
        boosterPacks = [
            BoosterPack(
                id: "boost_2x30m", name: "Chrono Catalyst",
                description: "2x production for 30 minutes.",
                productID: ProductIDs.boost2x30m,
                multiplier: 2, durationMinutes: 30
            ),
            BoosterPack(
                id: "boost_5x30m", name: "Temporal Surge",
                description: "5x production for 30 minutes.",
                productID: ProductIDs.boost5x30m,
                multiplier: 5, durationMinutes: 30
            ),
            BoosterPack(
                id: "boost_10x1h", name: "Epoch Overdrive",
                description: "10x production for 1 hour. Maximum output.",
                productID: ProductIDs.boost10x1h,
                multiplier: 10, durationMinutes: 60
            )
        ]
    }

    // MARK: - Premium Bundle Builder

    private func buildPremiumBundles() {
        premiumBundles = [
            PremiumBundle(
                id: "bundle_progression",
                name: "Progression Pack",
                description: "Jump-start your timeline with shards, crystals, and a permanent tap boost.",
                productID: ProductIDs.progressionBundle,
                shards: 500, crystals: 10,
                boostMultiplier: 3, boostMinutes: 120,
                relicMaterials: 50,
                exclusiveCosmeticID: nil,
                permanentTapBonus: 2,
                badge: "Popular",
                accent: .blue
            ),
            PremiumBundle(
                id: "bundle_legendary",
                name: "Legendary Bundle",
                description: "Massive resources, an exclusive avatar, and a permanent tap multiplier. For dedicated Chronoforgers.",
                productID: ProductIDs.legendaryBundle,
                shards: 2000, crystals: 40,
                boostMultiplier: 5, boostMinutes: 240,
                relicMaterials: 200,
                exclusiveCosmeticID: "avatar_chrono_lord",
                permanentTapBonus: 5,
                badge: "Best Value",
                accent: .purple
            ),
            PremiumBundle(
                id: "bundle_titan",
                name: "Titan Bundle",
                description: "The ultimate package for temporal titans. Exclusive animated cosmetic, absurd resources, and a huge permanent boost.",
                productID: ProductIDs.titanBundle,
                shards: 6000, crystals: 120,
                boostMultiplier: 10, boostMinutes: 480,
                relicMaterials: 500,
                exclusiveCosmeticID: "avatar_temporal_titan",
                permanentTapBonus: 10,
                badge: "Whale Tier",
                accent: .gold
            )
        ]
    }

    // MARK: - VIP Tier Pack Builder

    private func buildVIPTierPacks() {
        vipTierPacks = [
            VIPTierPack(
                id: "vip_pack_bronze", tier: .bronze,
                name: "Bronze Initiate Pack",
                description: "A welcome gift for reaching Bronze VIP. A solid boost to get rolling.",
                productID: ProductIDs.vipTierPackBronze,
                shards: 200, crystals: 3, relicMaterials: 25,
                boostMultiplier: 2, boostMinutes: 60,
                exclusiveCosmeticID: "skin_vip_bronze"
            ),
            VIPTierPack(
                id: "vip_pack_silver", tier: .silver,
                name: "Silver Vanguard Pack",
                description: "Exclusive to Silver VIP members. Premium resources and a unique particle effect.",
                productID: ProductIDs.vipTierPackSilver,
                shards: 600, crystals: 10, relicMaterials: 75,
                boostMultiplier: 3, boostMinutes: 120,
                exclusiveCosmeticID: "particle_vip_silver_trail"
            ),
            VIPTierPack(
                id: "vip_pack_gold", tier: .gold,
                name: "Gold Sovereign Pack",
                description: "Fit for temporal royalty. Massive resources and an exclusive golden relic skin.",
                productID: ProductIDs.vipTierPackGold,
                shards: 1500, crystals: 30, relicMaterials: 200,
                boostMultiplier: 5, boostMinutes: 240,
                exclusiveCosmeticID: "relic_vip_gold_crown"
            ),
            VIPTierPack(
                id: "vip_pack_diamond", tier: .diamond,
                name: "Diamond Ascendant Pack",
                description: "Only the most dedicated reach Diamond. An extraordinary haul of resources and an animated avatar.",
                productID: ProductIDs.vipTierPackDiamond,
                shards: 4000, crystals: 80, relicMaterials: 400,
                boostMultiplier: 8, boostMinutes: 480,
                exclusiveCosmeticID: "avatar_vip_diamond_ascendant"
            ),
            VIPTierPack(
                id: "vip_pack_obsidian", tier: .obsidian,
                name: "Obsidian Eternal Pack",
                description: "The pinnacle of VIP. A legendary cache of resources, an animated theme, and eternal bragging rights.",
                productID: ProductIDs.vipTierPackObsidian,
                shards: 10000, crystals: 200, relicMaterials: 1000,
                boostMultiplier: 10, boostMinutes: 720,
                exclusiveCosmeticID: "theme_vip_obsidian_eternal"
            )
        ]
    }
}

// MARK: - Entitlement Cache

private struct EntitlementCache: Codable {
    let isAdFree: Bool
    let isChronoPassActive: Bool
    let isVIPActive: Bool
    let hasStarterPack: Bool
    let hasProgressionBundle: Bool
    let hasLegendaryBundle: Bool
    let hasTitanBundle: Bool
    let ownedCosmeticIDs: Set<String>
}
