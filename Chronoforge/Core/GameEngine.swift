import Foundation
import Combine

@Observable
class GameEngine {
    let player: PlayerState
    private let saveManager: SaveManager
    private var tickTimer: Timer?
    private var saveTimer: Timer?
    private var lastTickTime: Date = Date()
    private var materialAccumulator: Double = 0
    private var autoTapAccumulator: Double = 0
    private var tickCounter: Int = 0

    private(set) var totalProductionRate: Decimal = 0
    private(set) var isRunning = false

    init(player: PlayerState, saveManager: SaveManager) {
        self.player = player
        self.saveManager = saveManager
        recalculateProduction()
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        isRunning = true
        lastTickTime = Date()
        checkBoostExpiration()

        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }

        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.save()
        }
    }

    func stop() {
        isRunning = false
        tickTimer?.invalidate()
        tickTimer = nil
        saveTimer?.invalidate()
        saveTimer = nil
        save()
    }

    func calculateOfflineEarnings() -> Decimal {
        let now = Date()
        let offlineSeconds = min(
            now.timeIntervalSince(player.lastOnlineTimestamp),
            GameConfig.maxOfflineSeconds
        )

        guard offlineSeconds > 60 else { return 0 }

        let offlineEfficiency = player.offlineEfficiency + offlineSkillBonus() + offlineRelicBonus()
        let earnings = totalProductionRate * Decimal(offlineSeconds) * offlineEfficiency

        return earnings
    }

    func collectOfflineEarnings() {
        let earnings = calculateOfflineEarnings()
        guard earnings > 0 else { return }
        player.temporalEnergy += earnings
        player.totalTEEarned += earnings
        player.totalLifetimeTEEarned += earnings
        player.lastOnlineTimestamp = Date()
    }

    // MARK: - Game Actions

    func tap() {
        let tapValue = player.tapPower * tapSkillMultiplier() * tapRelicMultiplier()
        player.temporalEnergy += tapValue
        player.totalTEEarned += tapValue
        player.totalLifetimeTEEarned += tapValue
        player.totalTaps += 1
    }

    func buyGenerator(id: GeneratorID, count: Int = 1) -> Bool {
        var state = player.generatorState(for: id)
        let cost = state.costForBulk(count)
        guard player.temporalEnergy >= cost else { return false }

        player.temporalEnergy -= cost
        state.quantity += count
        player.generators[id.id] = state
        recalculateProduction()
        return true
    }

    func buyUpgrade(id: UpgradeID) -> Bool {
        guard let config = GameConfig.upgrade(for: id) else { return false }
        guard !player.hasUpgrade(id) else { return false }
        guard player.temporalEnergy >= config.cost else { return false }
        guard meetsRequirement(config.requirement) else { return false }

        player.temporalEnergy -= config.cost
        player.purchasedUpgrades.insert(id.rawValue)
        recalculateProduction()
        return true
    }

    func unlockEra(_ era: Era) -> Bool {
        guard !player.isEraUnlocked(era) else { return false }
        let cost = era.unlockCost * eraDiscountMultiplier() * eraRelicDiscount()
        guard player.temporalEnergy >= cost else { return false }

        player.temporalEnergy -= cost
        player.unlockedEras.insert(era.rawValue)
        player.currentEra = era
        return true
    }

    // MARK: - Prestige

    func canPrestige() -> Bool {
        GameConfig.chronoShardsForPrestige(totalTE: player.totalTEEarned) > 0
    }

    func prestigeReward() -> Int {
        let total = GameConfig.chronoShardsForPrestige(totalTE: player.totalTEEarned)
        let bonus = prestigeSkillBonus() + prestigeRelicBonus()
        return Int(Decimal(total) * (1 + bonus))
    }

    func performPrestige() {
        let shards = prestigeReward()
        guard shards > 0 else { return }

        player.chronoShards += shards
        player.totalChronoShardsEarned += shards
        player.totalPrestigeCount += 1
        player.skillTree.availablePoints += shards

        // Reset run-level state
        player.temporalEnergy = 0
        player.totalTEEarned = 0
        player.generators = [:]
        player.purchasedUpgrades = []
        player.unlockedEras = ["ancient"]
        player.currentEra = .ancient
        player.tapPower = 1
        // Relics persist across soft prestiges

        // Apply epoch perks after reset
        applyEpochPerksOnPrestige()

        recalculateProduction()
        checkAchievements()
        save()
    }

    func allocateSkillPoint(nodeId: SkillNodeID) -> Bool {
        let success = player.skillTree.allocate(nodeId: nodeId)
        if success {
            recalculateProduction()
        }
        return success
    }

    // MARK: - Relics

    func forgeRelic(configId: RelicID) -> Bool {
        guard let config = GameConfig.relic(for: configId) else { return false }
        guard player.isEraUnlocked(config.era) else { return false }
        guard player.temporalEnergy >= config.forgeCost else { return false }
        guard player.relicMaterials >= config.materialCost else { return false }

        player.temporalEnergy -= config.forgeCost
        player.relicMaterials -= config.materialCost

        let relic = Relic(from: config)
        player.relics.append(relic)
        player.totalRelicsForged += 1

        return true
    }

    func equipRelic(relicId: UUID) -> Bool {
        guard let index = player.relics.firstIndex(where: { $0.id == relicId }) else { return false }
        guard !player.relics[index].isEquipped else { return false }
        guard player.equippedRelics.count < player.maxRelicSlots else { return false }

        player.relics[index].isEquipped = true
        recalculateProduction()
        return true
    }

    func unequipRelic(relicId: UUID) -> Bool {
        guard let index = player.relics.firstIndex(where: { $0.id == relicId }) else { return false }
        guard player.relics[index].isEquipped else { return false }

        player.relics[index].isEquipped = false
        recalculateProduction()
        return true
    }

    func salvageRelic(relicId: UUID) -> Bool {
        guard let index = player.relics.firstIndex(where: { $0.id == relicId }) else { return false }
        let relic = player.relics[index]

        // Return some materials based on rarity
        let materialsBack: Int
        switch relic.rarity {
        case .common: materialsBack = 2
        case .rare: materialsBack = 5
        case .epic: materialsBack = 10
        case .legendary: materialsBack = 20
        }

        player.relicMaterials += materialsBack
        player.relics.remove(at: index)
        recalculateProduction()
        return true
    }

    // MARK: - Daily Rewards

    func canClaimDailyReward() -> Bool {
        player.dailyRewardState.canClaimToday
    }

    func claimDailyReward() -> DailyRewardConfig? {
        guard canClaimDailyReward() else { return nil }

        let rewardDay = player.dailyRewardState.todayRewardDay
        let config = DailyRewardSystem.reward(for: rewardDay)

        player.dailyRewardState.claim()

        switch config.reward {
        case .temporalEnergy(let amount):
            let scaled = DailyRewardSystem.scaledTEReward(
                baseAmount: amount,
                playerProductionRate: totalProductionRate
            )
            player.temporalEnergy += scaled
            player.totalTEEarned += scaled
            player.totalLifetimeTEEarned += scaled
        case .chronoShards(let amount):
            player.chronoShards += amount
            player.totalChronoShardsEarned += amount
            player.skillTree.availablePoints += amount
        case .relicMaterials(let amount):
            player.relicMaterials += amount
        case .productionBoost(let multiplier, let minutes):
            player.activeBoostMultiplier = multiplier
            player.boostExpirationDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            recalculateProduction()
        }

        save()
        return config
    }

    // MARK: - Epoch Reset

    func canEpochReset() -> Bool {
        player.totalPrestigeCount >= EpochConfig.minimumPrestigesForEpoch &&
        EpochConfig.epochCrystalsForReset(totalLifetimeCS: player.totalChronoShardsEarned) > 0
    }

    func epochResetReward() -> Int {
        EpochConfig.epochCrystalsForReset(totalLifetimeCS: player.totalChronoShardsEarned)
    }

    func performEpochReset() {
        let crystals = epochResetReward()
        guard crystals > 0 else { return }

        player.epochCrystals += crystals
        player.totalEpochCount += 1

        // Hard reset everything except epoch stuff
        player.temporalEnergy = 0
        player.totalTEEarned = 0
        player.chronoShards = 0
        player.totalChronoShardsEarned = 0
        player.generators = [:]
        player.purchasedUpgrades = []
        player.skillTree = SkillTreeState()
        player.unlockedEras = ["ancient"]
        player.currentEra = .ancient
        player.tapPower = 1
        player.relics = []
        player.relicMaterials = 0
        player.totalPrestigeCount = 0
        // Keep: epochCrystals, epochPerkState, achievements, cosmetics, dailyRewardState, lifetime stats

        applyEpochPerksOnPrestige()
        recalculateProduction()
        checkAchievements()
        save()
    }

    func buyEpochPerk(perkId: EpochPerkID) -> Bool {
        let config = EpochConfig.perk(for: perkId)
        guard player.epochCrystals >= config.cost else { return false }
        guard player.epochPerkState.purchase(perkId: perkId) else { return false }

        player.epochCrystals -= config.cost
        recalculateProduction()
        save()
        return true
    }

    private func applyEpochPerksOnPrestige() {
        for perk in EpochConfig.allPerks {
            let level = player.epochPerkState.level(for: perk.id)
            guard level > 0 else { continue }

            switch perk.effect {
            case .startingTE(let amount):
                player.temporalEnergy += amount * Decimal(level)
            case .startingGenerators(let era, let index, let qty):
                let id = GeneratorID(era: era, index: index)
                var state = player.generatorState(for: id)
                state.quantity += qty * level
                player.generators[id.id] = state
            case .startingMaterials(let amount):
                player.relicMaterials += amount * level
            default:
                break // Other perks are passive multipliers applied during calculation
            }
        }
    }

    // MARK: - Contracts

    func generateNewContracts() {
        // Remove expired/claimed contracts
        player.activeContracts.removeAll { $0.isExpired || $0.isClaimed }

        // Generate new ones if empty
        guard player.activeContracts.isEmpty else { return }

        let available = ContractSystem.weeklyContracts.shuffled().prefix(2)
        for config in available {
            let contract = ContractSystem.generateContract(from: config)
            player.activeContracts.append(contract)
        }
        save()
    }

    func updateContractProgress() {
        for i in 0..<player.activeContracts.count {
            guard !player.activeContracts[i].isCompleted else { continue }
            guard !player.activeContracts[i].isExpired else { continue }

            switch player.activeContracts[i].goal {
            case .collectTE:
                player.activeContracts[i].currentProgress = player.totalTEEarned
            case .performPrestiges:
                player.activeContracts[i].currentProgress = Decimal(player.totalPrestigeCount)
            case .forgeRelics:
                player.activeContracts[i].currentProgress = Decimal(player.totalRelicsForged)
            case .reachEra(let era):
                player.activeContracts[i].currentProgress = player.isEraUnlocked(era) ? 1 : 0
            case .tapCount:
                player.activeContracts[i].currentProgress = Decimal(player.totalTaps)
            }

            if player.activeContracts[i].currentProgress >= player.activeContracts[i].targetProgress {
                player.activeContracts[i].isCompleted = true
            }
        }
    }

    func claimContractReward(contractId: UUID) {
        guard let index = player.activeContracts.firstIndex(where: { $0.id == contractId }) else { return }
        guard player.activeContracts[index].isCompleted else { return }
        guard !player.activeContracts[index].isClaimed else { return }

        let reward = player.activeContracts[index].reward
        switch reward {
        case .chronoShards(let amount):
            player.chronoShards += amount
            player.totalChronoShardsEarned += amount
            player.skillTree.availablePoints += amount
        case .epochCrystals(let amount):
            player.epochCrystals += amount
        case .relicMaterials(let amount):
            player.relicMaterials += amount
        case .exclusiveRelic:
            break // Future: grant exclusive relic
        }

        player.activeContracts[index].isClaimed = true
        player.completedContractCount += 1
        save()
    }

    // MARK: - Achievements

    func checkAchievements() {
        let newlyUnlocked = AchievementSystem.checkAchievements(
            player: player,
            achievements: &player.achievementState
        )

        for achievement in newlyUnlocked {
            switch achievement.reward {
            case .chronoShards(let amount) where amount > 0:
                player.chronoShards += amount
                player.totalChronoShardsEarned += amount
                player.skillTree.availablePoints += amount
            case .relicMaterials(let amount):
                player.relicMaterials += amount
            default:
                break
            }
        }
    }

    // MARK: - Private

    private func tick() {
        let now = Date()
        let delta = now.timeIntervalSince(lastTickTime)
        lastTickTime = now

        // Check boost expiration
        checkBoostExpiration()

        let earned = totalProductionRate * Decimal(delta)
        if earned > 0 {
            player.temporalEnergy += earned
            player.totalTEEarned += earned
            player.totalLifetimeTEEarned += earned
        }

        // Accumulate relic materials from generators
        let activeGeneratorCount = player.generators.values.reduce(0) { $0 + $1.quantity }
        if activeGeneratorCount > 0 {
            materialAccumulator += Double(activeGeneratorCount) * GameConfig.relicMaterialDropRate * delta
            if materialAccumulator >= 1.0 {
                let dropped = Int(materialAccumulator)
                player.relicMaterials += dropped
                materialAccumulator -= Double(dropped)
            }
        }

        // Auto-tap from epoch perk
        let autoTapLevel = player.epochPerkState.level(for: EpochPerkID(rawValue: "auto_tap"))
        if autoTapLevel > 0 {
            autoTapAccumulator += Double(autoTapLevel) * delta
            while autoTapAccumulator >= 1.0 {
                tap()
                autoTapAccumulator -= 1.0
            }
        }

        // Periodically check contracts and achievements (every ~5 seconds)
        tickCounter += 1
        if tickCounter % 50 == 0 {
            updateContractProgress()
            checkAchievements()
        }

        player.totalPlayTime += delta
        player.lastOnlineTimestamp = now
    }

    private func checkBoostExpiration() {
        if let expiration = player.boostExpirationDate, Date() >= expiration {
            player.activeBoostMultiplier = 1
            player.boostExpirationDate = nil
            recalculateProduction()
        }
    }

    func recalculateProduction() {
        var total: Decimal = 0

        for era in Era.allCases where player.isEraUnlocked(era) {
            for config in GameConfig.generators(for: era) {
                let state = player.generatorState(for: config.id)
                guard state.quantity > 0 else { continue }

                let upgradeMultiplier = upgradeMultiplier(for: config.id, era: era)
                let skillMultiplier = productionSkillMultiplier()
                let relicMultiplier = productionRelicMultiplier(for: era)

                let production = state.production(
                    upgradeMultiplier: upgradeMultiplier,
                    skillMultiplier: skillMultiplier,
                    relicMultiplier: relicMultiplier
                )
                total += production
            }
        }

        // Apply active boost
        if player.hasActiveBoost {
            total *= player.activeBoostMultiplier
        }

        // Apply epoch perk permanent production multiplier
        let epochLevel = player.epochPerkState.level(for: EpochPerkID(rawValue: "eternal_forge"))
        if epochLevel > 0 {
            total *= (1 + Decimal(string: "0.25")! * Decimal(epochLevel))
        }

        // Apply epoch prestige multiplier to production too
        let shardAmpLevel = player.epochPerkState.level(for: EpochPerkID(rawValue: "shard_amplifier"))
        // Note: shard_amplifier only affects prestige rewards, not production

        totalProductionRate = total
    }

    private func upgradeMultiplier(for generatorId: GeneratorID, era: Era) -> Decimal {
        var multiplier: Decimal = 1

        for upgradeId in player.purchasedUpgrades {
            guard let config = GameConfig.upgrade(for: UpgradeID(rawValue: upgradeId)) else { continue }
            switch config.effect {
            case .generatorMultiplier(let gId, let mult) where gId == generatorId:
                multiplier *= mult
            case .eraMultiplier(let e, let mult) where e == era:
                multiplier *= mult
            case .globalMultiplier(let mult):
                multiplier *= mult
            default:
                break
            }
        }

        return multiplier
    }

    private func productionSkillMultiplier() -> Decimal {
        var multiplier: Decimal = 1
        for node in GameConfig.allSkillNodes {
            let level = player.skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .productionMultiplier(let perLevel) = node.effect {
                multiplier += perLevel * Decimal(level)
            }
        }
        return multiplier
    }

    // MARK: - Relic Multipliers

    private func productionRelicMultiplier(for era: Era) -> Decimal {
        var multiplier: Decimal = 1
        for relic in player.equippedRelics {
            switch relic.effect {
            case .generatorBoost(let relicEra, let mult) where relicEra == era:
                multiplier *= mult
            case .allProductionBoost(let mult):
                multiplier *= mult
            case .synergyBoost(let mult):
                multiplier *= mult
            default:
                break
            }
        }
        return multiplier
    }

    private func tapRelicMultiplier() -> Decimal {
        var multiplier: Decimal = 1
        for relic in player.equippedRelics {
            if case .tapBoost(let mult) = relic.effect {
                multiplier *= mult
            }
        }
        return multiplier
    }

    private func offlineRelicBonus() -> Decimal {
        var bonus: Decimal = 0
        for relic in player.equippedRelics {
            if case .offlineBoost(let mult) = relic.effect {
                bonus += mult - 1
            }
        }
        return bonus
    }

    private func prestigeRelicBonus() -> Decimal {
        var bonus: Decimal = 0
        for relic in player.equippedRelics {
            if case .prestigeBoost(let mult) = relic.effect {
                bonus += mult - 1
            }
        }
        return bonus
    }

    private func eraRelicDiscount() -> Decimal {
        var discount: Decimal = 0
        for relic in player.equippedRelics {
            if case .eraUnlockDiscount(let disc) = relic.effect {
                discount += disc
            }
        }
        return max(Decimal(string: "0.1")!, 1 - discount)
    }

    // MARK: - Skill Helpers

    private func tapSkillMultiplier() -> Decimal {
        var multiplier: Decimal = 1
        for node in GameConfig.allSkillNodes {
            let level = player.skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .tapPower(let perLevel) = node.effect {
                multiplier += perLevel * Decimal(level)
            }
        }

        for upgradeId in player.purchasedUpgrades {
            guard let config = GameConfig.upgrade(for: UpgradeID(rawValue: upgradeId)) else { continue }
            if case .tapMultiplier(let mult) = config.effect {
                multiplier *= mult
            }
        }

        return multiplier
    }

    private func offlineSkillBonus() -> Decimal {
        var bonus: Decimal = 0
        for node in GameConfig.allSkillNodes {
            let level = player.skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .offlineEfficiency(let perLevel) = node.effect {
                bonus += perLevel * Decimal(level)
            }
        }
        return bonus
    }

    private func prestigeSkillBonus() -> Decimal {
        var bonus: Decimal = 0
        for node in GameConfig.allSkillNodes {
            let level = player.skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .prestigeBonus(let perLevel) = node.effect {
                bonus += perLevel * Decimal(level)
            }
        }
        return bonus
    }

    private func eraDiscountMultiplier() -> Decimal {
        var discount: Decimal = 0
        for node in GameConfig.allSkillNodes {
            let level = player.skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .eraUnlockDiscount(let perLevel) = node.effect {
                discount += perLevel * Decimal(level)
            }
        }
        return max(Decimal(string: "0.1")!, 1 - discount)
    }

    private func meetsRequirement(_ requirement: UpgradeRequirement?) -> Bool {
        guard let req = requirement else { return true }
        switch req {
        case .generatorQuantity(let gId, let min):
            return player.generatorState(for: gId).quantity >= min
        case .totalTE(let min):
            return player.totalTEEarned >= min
        case .prestigeCount(let min):
            return player.totalPrestigeCount >= min
        }
    }

    private func save() {
        player.lastSaveTimestamp = Date()
        saveManager.save(player)
    }
}
