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

// MARK: - StoreManager

@Observable
final class StoreManager {

    // MARK: - Product IDs

    struct ProductIDs {
        static let removeAds = "com.chronoforge.removeads"
        static let starterPack = "com.chronoforge.starterpack"
        static let chronoPassMonthly = "com.chronoforge.chronopass.monthly"

        // Cosmetic shop prefixes
        static let cosmeticPrefix = "com.chronoforge.cosmetic."

        static let skinPrefix = "\(cosmeticPrefix)skin."
        static let particleEffectPrefix = "\(cosmeticPrefix)particle."
        static let uiThemePrefix = "\(cosmeticPrefix)theme."
        static let relicAppearancePrefix = "\(cosmeticPrefix)relic."
        static let avatarPrefix = "\(cosmeticPrefix)avatar."

        static var allProductIDs: Set<String> {
            var ids: Set<String> = [
                removeAds,
                starterPack,
                chronoPassMonthly
            ]
            // Cosmetic IDs are loaded from the catalog at runtime
            return ids
        }
    }

    // MARK: - Entitlements

    private(set) var isAdFree: Bool = false
    private(set) var isChronoPassActive: Bool = false
    private(set) var hasStarterPack: Bool = false
    private(set) var ownedCosmeticIDs: Set<String> = []

    // MARK: - Products

    private(set) var products: [Product] = []
    private(set) var removeAdsProduct: Product?
    private(set) var starterPackProduct: Product?
    private(set) var chronoPassProduct: Product?
    private(set) var cosmeticProducts: [Product] = []

    // MARK: - Chrono Pass State

    private(set) var chronoPassTiers: [ChronoPassTier] = []
    var chronoPassProgress: ChronoPassProgress = ChronoPassProgress(
        currentTier: 0,
        currentXP: 0,
        claimedFreeTiers: [],
        claimedPremiumTiers: []
    )

    // MARK: - Cosmetic Catalog

    private(set) var cosmeticCatalog: [CosmeticItem] = []

    // MARK: - Purchase State

    private(set) var purchaseInProgress: Bool = false
    private(set) var lastError: String?

    // MARK: - Private

    private var transactionListener: Task<Void, Error>?
    private let entitlementsCacheKey = "StoreManager.entitlements"
    private let chronoPassProgressKey = "StoreManager.chronoPassProgress"

    // MARK: - Init

    init() {
        loadCachedEntitlements()
        loadChronoPassProgress()
        buildChronoPassTiers()
        buildCosmeticCatalog()

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
            cosmeticProducts = storeProducts.filter { $0.id.hasPrefix(ProductIDs.cosmeticPrefix) }
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
        var starterOwned = false
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

            default:
                if transaction.productID.hasPrefix(ProductIDs.cosmeticPrefix),
                   transaction.revocationDate == nil {
                    // Map product ID back to cosmetic item ID
                    if let cosmeticItem = cosmeticCatalog.first(where: { $0.productID == transaction.productID }) {
                        cosmetics.insert(cosmeticItem.id)
                    }
                }
            }
        }

        isAdFree = adFree
        isChronoPassActive = passActive
        hasStarterPack = starterOwned
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

        default:
            if transaction.productID.hasPrefix(ProductIDs.cosmeticPrefix),
               transaction.revocationDate == nil {
                if let cosmeticItem = cosmeticCatalog.first(where: { $0.productID == transaction.productID }) {
                    ownedCosmeticIDs.insert(cosmeticItem.id)
                }
            }
        }

        cacheEntitlements()
    }

    // MARK: - Persistence

    private func cacheEntitlements() {
        let cache = EntitlementCache(
            isAdFree: isAdFree,
            isChronoPassActive: isChronoPassActive,
            hasStarterPack: hasStarterPack,
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
        hasStarterPack = cache.hasStarterPack
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
}

// MARK: - Entitlement Cache

private struct EntitlementCache: Codable {
    let isAdFree: Bool
    let isChronoPassActive: Bool
    let hasStarterPack: Bool
    let ownedCosmeticIDs: Set<String>
}
