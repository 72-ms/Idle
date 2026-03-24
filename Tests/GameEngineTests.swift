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
    }

    func testAllSkillNodesExist() {
        XCTAssertFalse(GameConfig.skillNodes(for: .acceleration).isEmpty)
        XCTAssertFalse(GameConfig.skillNodes(for: .resonance).isEmpty)
        XCTAssertFalse(GameConfig.skillNodes(for: .mastery).isEmpty)
    }

    func testEraOrdering() {
        XCTAssertLessThan(Era.ancient.order, Era.medieval.order)
        XCTAssertLessThan(Era.medieval.order, Era.industrial.order)
        XCTAssertLessThan(Era.industrial.order, Era.digital.order)
        XCTAssertLessThan(Era.digital.order, Era.cosmic.order)
    }
}
