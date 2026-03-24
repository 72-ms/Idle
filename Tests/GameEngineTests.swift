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
}
