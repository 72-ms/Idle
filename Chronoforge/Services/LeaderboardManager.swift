import Foundation
import GameKit

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let playerName: String
    let score: Int
    let isLocalPlayer: Bool
    let vipTier: VIPTier
    let nameColorId: String?
    let title: String?
}

// MARK: - Leaderboard Manager

@Observable
final class LeaderboardManager {

    // MARK: Leaderboard IDs

    static let fastestPrestige = "com.chronoforge.fastest_prestige"
    static let totalTEEarned = "com.chronoforge.total_te_earned"
    static let epochCount = "com.chronoforge.epoch_count"
    static let challengesCompleted = "com.chronoforge.challenges_completed"

    // MARK: Properties

    var isAuthenticated: Bool = false
    var localPlayerName: String = ""
    var leaderboardEntries: [LeaderboardEntry] = []

    // MARK: - Authentication

    /// Authenticates the local player with Game Center.
    /// Failures are handled gracefully without crashing.
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    print("[LeaderboardManager] Authentication failed: \(error.localizedDescription)")
                    self.isAuthenticated = false
                    self.localPlayerName = ""
                    return
                }

                if viewController != nil {
                    // The system will present the Game Center login UI automatically.
                    // Nothing to do here; the handler will be called again after login.
                    return
                }

                let player = GKLocalPlayer.local
                self.isAuthenticated = player.isAuthenticated
                self.localPlayerName = player.isAuthenticated ? player.displayName : ""
            }
        }
    }

    // MARK: - Score Submission

    /// Submits a score to the specified leaderboard.
    func submitScore(_ score: Int, to leaderboardID: String) {
        guard isAuthenticated else {
            print("[LeaderboardManager] Cannot submit score — player not authenticated.")
            return
        }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error {
                print("[LeaderboardManager] Failed to submit score to \(leaderboardID): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Load Entries

    /// Loads leaderboard entries for the given leaderboard ID.
    /// Populates `leaderboardEntries` on success.
    func loadEntries(for leaderboardID: String) async {
        guard isAuthenticated else {
            print("[LeaderboardManager] Cannot load entries — player not authenticated.")
            return
        }

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])

            guard let leaderboard = leaderboards.first else {
                print("[LeaderboardManager] Leaderboard not found: \(leaderboardID)")
                return
            }

            let (entries, _, _) = try await leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 25)
            )

            let localID = GKLocalPlayer.local.gamePlayerID

            let mapped = entries.map { entry in
                let isLocal = entry.player.gamePlayerID == localID
                // For non-local players, generate a weighted random VIP tier for display
                let mockProfile = isLocal ? nil : PlayerProfile.generateMock()
                return LeaderboardEntry(
                    rank: entry.rank,
                    playerName: entry.player.displayName,
                    score: entry.score,
                    isLocalPlayer: isLocal,
                    vipTier: isLocal ? .none : (mockProfile?.vipTier ?? .none),
                    nameColorId: isLocal ? nil : mockProfile?.equippedNameColor,
                    title: isLocal ? nil : mockProfile?.equippedTitle
                )
            }

            await MainActor.run {
                self.leaderboardEntries = mapped
            }
        } catch {
            print("[LeaderboardManager] Failed to load entries for \(leaderboardID): \(error.localizedDescription)")
            await MainActor.run {
                self.leaderboardEntries = []
            }
        }
    }

    // MARK: - Achievement Reporting

    /// Reports progress toward an achievement.
    func reportAchievement(_ achievementID: String, percentComplete: Double) {
        guard isAuthenticated else {
            print("[LeaderboardManager] Cannot report achievement — player not authenticated.")
            return
        }

        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = min(max(percentComplete, 0), 100)
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error {
                print("[LeaderboardManager] Failed to report achievement \(achievementID): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Game Center Dashboard

    /// Returns a view controller that presents the Game Center dashboard.
    func showGameCenterDashboard() -> GKGameCenterViewController {
        let viewController = GKGameCenterViewController(state: .default)
        return viewController
    }
}
