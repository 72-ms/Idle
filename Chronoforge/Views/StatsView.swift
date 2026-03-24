import SwiftUI

struct StatsView: View {
    @Environment(PlayerState.self) private var player

    var body: some View {
        NavigationStack {
            List {
                Section("Currency") {
                    StatRow(label: "Current TE", value: TEFormatter.format(player.temporalEnergy))
                    StatRow(label: "Total TE (This Run)", value: TEFormatter.format(player.totalTEEarned))
                    StatRow(label: "Total TE (Lifetime)", value: TEFormatter.format(player.totalLifetimeTEEarned))
                    StatRow(label: "Chrono Shards", value: "\(player.chronoShards)")
                }

                Section("Progress") {
                    StatRow(label: "Current Era", value: player.currentEra.displayName)
                    StatRow(label: "Eras Unlocked", value: "\(player.unlockedEras.count)")
                    StatRow(label: "Generators Owned", value: "\(totalGenerators)")
                    StatRow(label: "Upgrades Purchased", value: "\(player.purchasedUpgrades.count)")
                }

                Section("Activity") {
                    StatRow(label: "Total Taps", value: "\(player.totalTaps)")
                    StatRow(label: "Total Prestiges", value: "\(player.totalPrestigeCount)")
                    StatRow(label: "Skill Points Allocated", value: "\(player.skillTree.totalAllocated)")
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var totalGenerators: Int {
        player.generators.values.reduce(0) { $0 + $1.quantity }
    }
}
