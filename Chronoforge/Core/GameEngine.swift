import Foundation
import Combine

@Observable
class GameEngine {
    let player: PlayerState
    private let saveManager: SaveManager
    private var tickTimer: Timer?
    private var saveTimer: Timer?
    private var lastTickTime: Date = Date()

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

        guard offlineSeconds > 60 else { return 0 } // Minimum 1 minute offline

        let offlineEfficiency = player.offlineEfficiency + offlineSkillBonus()
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
        let tapValue = player.tapPower * tapSkillMultiplier()
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
        let cost = era.unlockCost * eraDiscountMultiplier()
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
        let bonus = prestigeSkillBonus()
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

        recalculateProduction()
        save()
    }

    func allocateSkillPoint(nodeId: SkillNodeID) -> Bool {
        let success = player.skillTree.allocate(nodeId: nodeId)
        if success {
            recalculateProduction()
        }
        return success
    }

    // MARK: - Private

    private func tick() {
        let now = Date()
        let delta = now.timeIntervalSince(lastTickTime)
        lastTickTime = now

        let earned = totalProductionRate * Decimal(delta)
        if earned > 0 {
            player.temporalEnergy += earned
            player.totalTEEarned += earned
            player.totalLifetimeTEEarned += earned
        }

        player.totalPlayTime += delta
        player.lastOnlineTimestamp = now
    }

    func recalculateProduction() {
        var total: Decimal = 0

        for era in Era.allCases where player.isEraUnlocked(era) {
            for config in GameConfig.generators(for: era) {
                let state = player.generatorState(for: config.id)
                guard state.quantity > 0 else { continue }

                let upgradeMultiplier = upgradeMultiplier(for: config.id, era: era)
                let skillMultiplier = productionSkillMultiplier()

                let production = state.production(
                    upgradeMultiplier: upgradeMultiplier,
                    skillMultiplier: skillMultiplier,
                    relicMultiplier: 1 // Relics in Phase 2
                )
                total += production
            }
        }

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

    private func tapSkillMultiplier() -> Decimal {
        var multiplier: Decimal = 1
        for node in GameConfig.allSkillNodes {
            let level = player.skillTree.level(for: node.id)
            guard level > 0 else { continue }
            if case .tapPower(let perLevel) = node.effect {
                multiplier += perLevel * Decimal(level)
            }
        }

        // Also apply tap upgrades
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
