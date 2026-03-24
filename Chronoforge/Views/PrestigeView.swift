import SwiftUI

struct PrestigeView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current shards
                VStack(spacing: 4) {
                    Text("\(player.chronoShards)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("Chrono Shards")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 20)

                // Shards to earn
                VStack(spacing: 8) {
                    Text("Timeline Collapse")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    if engine.canPrestige() {
                        Text("You will earn \(engine.prestigeReward()) Chrono Shards")
                            .font(.headline)
                            .foregroundStyle(.cyan)
                    } else {
                        Text("Earn more TE to unlock prestige")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Required: \(TEFormatter.format(1_000_000_000_000)) total TE")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                // What resets / what stays
                let info = PrestigeManager.resetDescription()

                VStack(alignment: .leading, spacing: 8) {
                    Text("What Resets")
                        .font(.headline)
                        .foregroundStyle(.red.opacity(0.8))

                    ForEach(info.resets, id: \.self) { item in
                        Label(item, systemImage: "xmark.circle")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.red.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("What Stays")
                        .font(.headline)
                        .foregroundStyle(.green.opacity(0.8))

                    ForEach(info.keeps, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Prestige button
                Button {
                    showConfirmation = true
                } label: {
                    Text("Collapse Timeline")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(engine.canPrestige() ? .cyan : .gray.opacity(0.3))
                        .foregroundStyle(engine.canPrestige() ? .black : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!engine.canPrestige())

                // Stats
                VStack(spacing: 4) {
                    Text("Total Prestiges: \(player.totalPrestigeCount)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Total TE this run: \(TEFormatter.format(player.totalTEEarned))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
        }
        .alert("Collapse Timeline?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Collapse", role: .destructive) {
                engine.performPrestige()
                HapticsManager.heavyTap()
                AudioManager.shared.play(.prestige)
            }
        } message: {
            Text("You will earn \(engine.prestigeReward()) Chrono Shards. Your generators, upgrades, and TE will be reset.")
        }
    }
}
