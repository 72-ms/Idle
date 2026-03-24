import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(PlayerState.self) private var player
    @State private var showResetConfirmation = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            List {
                Section("Audio & Feedback") {
                    Toggle("Sound Effects", isOn: $soundEnabled)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section("Statistics") {
                    StatRow(label: "Total TE Earned (Lifetime)", value: TEFormatter.format(player.totalLifetimeTEEarned))
                    StatRow(label: "Total Taps", value: "\(player.totalTaps)")
                    StatRow(label: "Total Prestiges", value: "\(player.totalPrestigeCount)")
                    StatRow(label: "Chrono Shards Earned", value: "\(player.totalChronoShardsEarned)")
                    StatRow(label: "Relics Forged", value: "\(player.totalRelicsForged)")
                    StatRow(label: "Relic Materials", value: "\(player.relicMaterials)")
                    StatRow(label: "Epoch Resets", value: "\(player.totalEpochCount)")
                    StatRow(label: "Epoch Crystals", value: "\(player.epochCrystals)")
                    StatRow(label: "Contracts Completed", value: "\(player.completedContractCount)")
                    StatRow(label: "Achievements", value: "\(player.achievementState.unlockedAchievements.count)/\(AchievementSystem.allAchievements.count)")
                    StatRow(label: "Daily Streak", value: "\(player.dailyRewardState.currentStreak) days")
                    StatRow(label: "Play Time", value: formatPlayTime(player.totalPlayTime))
                }

                Section("Data") {
                    Button("Reset All Progress", role: .destructive) {
                        showResetConfirmation = true
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Game")
                        Spacer()
                        Text("Chronoforge")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Everything", role: .destructive) {
                    appState.resetGame()
                    dismiss()
                }
            } message: {
                Text("This will permanently delete all your progress. This cannot be undone.")
            }
        }
    }

    private func formatPlayTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.subheadline.monospacedDigit())
        }
    }
}
