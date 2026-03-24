import Foundation

struct PrestigeManager {
    static func canPrestige(player: PlayerState) -> Bool {
        GameConfig.chronoShardsForPrestige(totalTE: player.totalTEEarned) > 0
    }

    static func shardsToEarn(player: PlayerState, prestigeBonus: Decimal = 0) -> Int {
        let base = GameConfig.chronoShardsForPrestige(totalTE: player.totalTEEarned)
        return NSDecimalNumber(decimal: Decimal(base) * (1 + prestigeBonus)).intValue
    }

    static func resetDescription() -> (resets: [String], keeps: [String]) {
        let resets = [
            "Temporal Energy",
            "All Generators",
            "All Upgrades",
            "Era Progress (back to Ancient)"
        ]
        let keeps = [
            "Chrono Shards (+ new ones earned)",
            "Skill Tree Progress",
            "Lifetime Statistics"
        ]
        return (resets, keeps)
    }
}
