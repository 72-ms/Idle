import XCTest
@testable import Chronoforge

final class GameEngineTests: XCTestCase {

    // MARK: - Number Formatter Tests

    func testFormatSmallNumbers() {
        XCTAssertEqual(TEFormatter.format(0), "0")
        XCTAssertEqual(TEFormatter.format(1), "1")
        XCTAssertEqual(TEFormatter.format(999), "999")
    }

    func testFormatThousands() {
        XCTAssertEqual(TEFormatter.format(1_000), "1.00K")
        XCTAssertEqual(TEFormatter.format(1_500), "1.50K")
        XCTAssertEqual(TEFormatter.format(15_000), "15.0K")
        XCTAssertEqual(TEFormatter.format(150_000), "150K")
    }

    func testFormatMillions() {
        XCTAssertEqual(TEFormatter.format(1_000_000), "1.00M")
        XCTAssertEqual(TEFormatter.format(2_500_000), "2.50M")
    }

    func testFormatBillions() {
        XCTAssertEqual(TEFormatter.format(1_000_000_000), "1.00B")
    }

    func testFormatRate() {
        XCTAssertEqual(TEFormatter.formatRate(100), "100/s")
        XCTAssertEqual(TEFormatter.formatRate(1_500), "1.50K/s")
    }

    // MARK: - Generator Tests

    func testGeneratorMilestoneBonus() {
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 0), 1)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 9), 1)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 10), 2)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 25), 4)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 50), 12)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 100), 48)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 250), 240)
        XCTAssertEqual(GeneratorState.milestoneBonus(for: 500), 2400)
    }

    func testGeneratorCostScaling() {
        let state = GeneratorState(id: GeneratorID(era: .ancient, index: 0), quantity: 0)
        let config = GameConfig.generator(for: state.id)
        XCTAssertEqual(state.totalCostForNext, config.baseCost)

        let state10 = GeneratorState(id: GeneratorID(era: .ancient, index: 0), quantity: 10)
        XCTAssertTrue(state10.totalCostForNext > state.totalCostForNext)
    }

    // MARK: - Prestige Tests

    func testPrestigeFormulaZero() {
        XCTAssertEqual(GameConfig.chronoShardsForPrestige(totalTE: 0), 0)
        XCTAssertEqual(GameConfig.chronoShardsForPrestige(totalTE: 999_999_999_999), 0)
    }

    func testPrestigeFormulaPositive() {
        XCTAssertEqual(GameConfig.chronoShardsForPrestige(totalTE: 1_000_000_000_000), 1)
        XCTAssertEqual(GameConfig.chronoShardsForPrestige(totalTE: 4_000_000_000_000), 2)
    }

    // MARK: - Skill Tree Tests

    func testSkillAllocation() {
        var tree = SkillTreeState()
        tree.availablePoints = 5

        let nodeId = SkillNodeID(branch: .acceleration, index: 0)
        let success = tree.allocate(nodeId: nodeId)
        XCTAssertTrue(success)
        XCTAssertEqual(tree.level(for: nodeId), 1)
        XCTAssertEqual(tree.availablePoints, 4)
    }

    func testSkillAllocationNotEnoughPoints() {
        var tree = SkillTreeState()
        tree.availablePoints = 0

        let nodeId = SkillNodeID(branch: .acceleration, index: 0)
        let success = tree.allocate(nodeId: nodeId)
        XCTAssertFalse(success)
        XCTAssertEqual(tree.level(for: nodeId), 0)
    }

    // MARK: - Player State Tests

    func testPlayerStateInitialValues() {
        let player = PlayerState()
        XCTAssertEqual(player.temporalEnergy, 0)
        XCTAssertEqual(player.chronoShards, 0)
        XCTAssertEqual(player.currentEra, .ancient)
        XCTAssertTrue(player.isEraUnlocked(.ancient))
        XCTAssertFalse(player.isEraUnlocked(.medieval))
    }

    func testPlayerStateSerialization() throws {
        let player = PlayerState()
        player.temporalEnergy = 12345
        player.chronoShards = 10
        player.totalTaps = 500

        let encoder = JSONEncoder()
        let data = try encoder.encode(player)

        let decoder = JSONDecoder()
        let loaded = try decoder.decode(PlayerState.self, from: data)

        XCTAssertEqual(loaded.temporalEnergy, 12345)
        XCTAssertEqual(loaded.chronoShards, 10)
        XCTAssertEqual(loaded.totalTaps, 500)
    }

    // MARK: - Offline Calculator Tests

    func testOfflineCalculatorCap() {
        let earnings = OfflineCalculator.calculate(
            productionRate: 100,
            offlineSeconds: 100_000,
            offlineEfficiency: Decimal(string: "0.5")!
        )
        let maxEarnings = 100 * Decimal(GameConfig.maxOfflineSeconds) * Decimal(string: "0.5")!
        XCTAssertEqual(earnings, maxEarnings)
    }

    func testOfflineCalculatorMinimumTime() {
        let earnings = OfflineCalculator.calculate(
            productionRate: 100,
            offlineSeconds: 30,
            offlineEfficiency: Decimal(string: "0.5")!
        )
        XCTAssertEqual(earnings, 0)
    }

    // MARK: - Game Config Tests

    func testAllGeneratorsExist() {
        XCTAssertEqual(GameConfig.generators(for: .ancient).count, 4)
        XCTAssertEqual(GameConfig.generators(for: .medieval).count, 4)
        XCTAssertEqual(GameConfig.generators(for: .industrial).count, 4)
        XCTAssertEqual(GameConfig.generators(for: .digital).count, 4)
        XCTAssertEqual(GameConfig.generators(for: .cosmic).count, 4)
        XCTAssertEqual(GameConfig.allGenerators.count, 20)
    }

    func testAllUpgradesExist() {
        XCTAssertTrue(GameConfig.upgrades(for: .ancient).count >= 5)
        XCTAssertTrue(GameConfig.upgrades(for: .medieval).count >= 4)
        XCTAssertTrue(GameConfig.upgrades(for: .industrial).count >= 5)
        XCTAssertTrue(GameConfig.upgrades(for: .digital).count >= 5)
        XCTAssertTrue(GameConfig.upgrades(for: .cosmic).count >= 5)
    }

    func testAllSkillNodesExist() {
        XCTAssertEqual(GameConfig.skillNodes(for: .acceleration).count, 10)
        XCTAssertEqual(GameConfig.skillNodes(for: .resonance).count, 10)
        XCTAssertEqual(GameConfig.skillNodes(for: .mastery).count, 10)
        XCTAssertEqual(GameConfig.allSkillNodes.count, 30)
    }

    func testEraOrdering() {
        XCTAssertLessThan(Era.ancient.order, Era.medieval.order)
        XCTAssertLessThan(Era.medieval.order, Era.industrial.order)
        XCTAssertLessThan(Era.industrial.order, Era.digital.order)
        XCTAssertLessThan(Era.digital.order, Era.cosmic.order)
    }

    // MARK: - Relic Tests

    func testAllRelicsExist() {
        XCTAssertEqual(GameConfig.relics(for: .ancient).count, 4)
        XCTAssertEqual(GameConfig.relics(for: .medieval).count, 4)
        XCTAssertEqual(GameConfig.relics(for: .industrial).count, 4)
        XCTAssertEqual(GameConfig.relics(for: .digital).count, 4)
        XCTAssertEqual(GameConfig.relics(for: .cosmic).count, 4)
        XCTAssertEqual(GameConfig.allRelics.count, 20)
    }

    func testRelicCreation() {
        let config = GameConfig.allRelics.first!
        let relic = Relic(from: config)
        XCTAssertEqual(relic.configId, config.id)
        XCTAssertEqual(relic.name, config.name)
        XCTAssertFalse(relic.isEquipped)
    }

    func testRelicEffectDescription() {
        let config = GameConfig.allRelics.first!
        let relic = Relic(from: config)
        XCTAssertFalse(relic.effectDescription.isEmpty)
    }

    func testMaxRelicSlots() {
        let player = PlayerState()
        XCTAssertEqual(player.maxRelicSlots, GameConfig.baseRelicSlots)
    }

    // MARK: - Daily Reward Tests

    func testDailyRewardCycle() {
        XCTAssertEqual(DailyRewardSystem.rewards.count, 7)
        for i in 1...7 {
            let reward = DailyRewardSystem.reward(for: i)
            XCTAssertEqual(reward.day, i)
        }
    }

    func testDailyRewardStateInitial() {
        let state = DailyRewardState()
        XCTAssertTrue(state.canClaimToday)
        XCTAssertEqual(state.currentStreak, 0)
    }

    func testDailyRewardClaim() {
        var state = DailyRewardState()
        state.claim()
        XCTAssertEqual(state.currentStreak, 1)
        XCTAssertEqual(state.totalDaysClaimed, 1)
        XCTAssertFalse(state.canClaimToday)
    }

    func testScaledTEReward() {
        let base: Decimal = 1000
        let scaled = DailyRewardSystem.scaledTEReward(baseAmount: base, playerProductionRate: 100)
        // 100 * 300 = 30000 > 1000
        XCTAssertEqual(scaled, 30000)
    }

    func testScaledTERewardMinimum() {
        let base: Decimal = 50000
        let scaled = DailyRewardSystem.scaledTEReward(baseAmount: base, playerProductionRate: 10)
        // 10 * 300 = 3000 < 50000, so use base
        XCTAssertEqual(scaled, 50000)
    }

    // MARK: - Player State with Relics Serialization

    func testPlayerStateWithRelicsSerialization() throws {
        let player = PlayerState()
        player.relicMaterials = 25
        player.totalRelicsForged = 3

        let config = GameConfig.allRelics.first!
        var relic = Relic(from: config)
        relic.isEquipped = true
        player.relics = [relic]

        let data = try JSONEncoder().encode(player)
        let loaded = try JSONDecoder().decode(PlayerState.self, from: data)

        XCTAssertEqual(loaded.relicMaterials, 25)
        XCTAssertEqual(loaded.totalRelicsForged, 3)
        XCTAssertEqual(loaded.relics.count, 1)
        XCTAssertTrue(loaded.relics.first!.isEquipped)
    }

    // MARK: - Generator Balance Tests

    func testGeneratorProductionScaling() {
        // Verify each era's generators produce more than the previous era
        let eras = Era.allCases
        for i in 0..<(eras.count - 1) {
            let currentEra = eras[i]
            let nextEra = eras[i + 1]
            let currentMax = GameConfig.generators(for: currentEra).last!.baseProduction
            let nextMin = GameConfig.generators(for: nextEra).first!.baseProduction
            XCTAssertGreaterThan(nextMin, currentMax,
                "\(nextEra.displayName) first generator should produce more than \(currentEra.displayName) last generator")
        }
    }

    // MARK: - Epoch Reset Tests

    func testEpochCrystalsFormula() {
        XCTAssertEqual(EpochConfig.epochCrystalsForReset(totalLifetimeCS: 0), 0)
        XCTAssertEqual(EpochConfig.epochCrystalsForReset(totalLifetimeCS: 500_000), 0)
        XCTAssertGreaterThan(EpochConfig.epochCrystalsForReset(totalLifetimeCS: 2_000_000), 0)
    }

    func testEpochPerksExist() {
        XCTAssertFalse(EpochConfig.allPerks.isEmpty)
        XCTAssertEqual(EpochConfig.allPerks.count, 8)
    }

    func testEpochPerkPurchase() {
        var state = EpochPerkState()
        let perkId = EpochPerkID(rawValue: "head_start")
        XCTAssertTrue(state.purchase(perkId: perkId))
        XCTAssertEqual(state.level(for: perkId), 1)
    }

    func testEpochPerkMaxLevel() {
        var state = EpochPerkState()
        let perkId = EpochPerkID(rawValue: "head_start")
        let config = EpochConfig.perk(for: perkId)
        for _ in 0..<config.maxLevel {
            _ = state.purchase(perkId: perkId)
        }
        XCTAssertFalse(state.purchase(perkId: perkId))
        XCTAssertEqual(state.level(for: perkId), config.maxLevel)
    }

    // MARK: - Contract Tests

    func testContractGeneration() {
        let config = ContractSystem.weeklyContracts.first!
        let contract = ContractSystem.generateContract(from: config)
        XCTAssertFalse(contract.isCompleted)
        XCTAssertFalse(contract.isClaimed)
        XCTAssertFalse(contract.isExpired)
        XCTAssertGreaterThan(contract.timeRemaining, 0)
    }

    func testContractProgress() {
        let config = ContractSystem.weeklyContracts.first!
        var contract = ContractSystem.generateContract(from: config)
        XCTAssertEqual(contract.progressFraction, 0)

        contract.currentProgress = contract.targetProgress / 2
        XCTAssertEqual(contract.progressFraction, 0.5, accuracy: 0.01)

        contract.currentProgress = contract.targetProgress
        XCTAssertEqual(contract.progressFraction, 1.0, accuracy: 0.01)
    }

    // MARK: - Achievement Tests

    func testAchievementInitialState() {
        let state = AchievementState()
        XCTAssertTrue(state.unlockedAchievements.isEmpty)
        XCTAssertFalse(state.isUnlocked(AchievementID(rawValue: "first_tap")))
    }

    func testAchievementUnlock() {
        var state = AchievementState()
        let id = AchievementID(rawValue: "first_tap")
        state.unlock(id)
        XCTAssertTrue(state.isUnlocked(id))
    }

    func testAchievementCheck() {
        let player = PlayerState()
        player.totalTaps = 1
        var achievements = AchievementState()

        let unlocked = AchievementSystem.checkAchievements(player: player, achievements: &achievements)
        XCTAssertTrue(unlocked.contains { $0.id.rawValue == "first_tap" })
        XCTAssertTrue(achievements.isUnlocked(AchievementID(rawValue: "first_tap")))
    }

    func testAchievementsExist() {
        XCTAssertGreaterThanOrEqual(AchievementSystem.allAchievements.count, 15)
    }

    // MARK: - Full Serialization Test

    func testFullPlayerStateSerialization() throws {
        let player = PlayerState()
        player.temporalEnergy = 99999
        player.chronoShards = 50
        player.epochCrystals = 3
        player.relicMaterials = 100
        player.totalRelicsForged = 5
        player.totalPrestigeCount = 12
        player.totalEpochCount = 1
        player.completedContractCount = 2
        player.achievementState.unlock(AchievementID(rawValue: "first_tap"))
        _ = player.epochPerkState.purchase(perkId: EpochPerkID(rawValue: "head_start"))

        let data = try JSONEncoder().encode(player)
        let loaded = try JSONDecoder().decode(PlayerState.self, from: data)

        XCTAssertEqual(loaded.temporalEnergy, 99999)
        XCTAssertEqual(loaded.epochCrystals, 3)
        XCTAssertEqual(loaded.completedContractCount, 2)
        XCTAssertTrue(loaded.achievementState.isUnlocked(AchievementID(rawValue: "first_tap")))
        XCTAssertEqual(loaded.epochPerkState.level(for: EpochPerkID(rawValue: "head_start")), 1)
    }
}
