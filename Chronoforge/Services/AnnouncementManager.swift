import Foundation

@Observable
final class AnnouncementManager {

    struct Announcement: Identifiable {
        let id = UUID()
        let playerName: String
        let vipTier: VIPTier
        let nameColorId: String?
        let title: String?
        let message: String
        let timestamp: Date
    }

    // MARK: - State

    private(set) var activeAnnouncement: Announcement?
    private(set) var announcementHistory: [Announcement] = []
    private var queue: [Announcement] = []
    private var dismissTimer: Timer?
    private var mockTimer: Timer?

    /// How long each announcement stays visible.
    static let displayDuration: TimeInterval = 5.0

    // MARK: - Lifecycle

    func start() {
        // Generate periodic mock Chronarch announcements for atmosphere
        mockTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.generateMockAnnouncement()
        }
        // Show one shortly after launch for flavor
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.generateMockAnnouncement()
        }
    }

    func stop() {
        mockTimer?.invalidate()
        mockTimer = nil
        dismissTimer?.invalidate()
        dismissTimer = nil
    }

    // MARK: - Post Announcement

    /// Posts a Chronarch-level achievement announcement for the local player.
    func postLocalAchievement(playerName: String, vipTier: VIPTier, nameColorId: String?, title: String?, achievementName: String) {
        guard vipTier == .chronarch else { return }
        let announcement = Announcement(
            playerName: playerName,
            vipTier: vipTier,
            nameColorId: nameColorId,
            title: title,
            message: "has achieved \(achievementName)!",
            timestamp: Date()
        )
        enqueue(announcement)
    }

    /// Dismisses the current announcement immediately.
    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        activeAnnouncement = nil
        showNext()
    }

    // MARK: - Private

    private func enqueue(_ announcement: Announcement) {
        announcementHistory.append(announcement)
        if announcementHistory.count > 50 {
            announcementHistory = Array(announcementHistory.suffix(50))
        }

        if activeAnnouncement == nil {
            show(announcement)
        } else {
            queue.append(announcement)
        }
    }

    private func show(_ announcement: Announcement) {
        activeAnnouncement = announcement
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: Self.displayDuration, repeats: false) { [weak self] _ in
            self?.activeAnnouncement = nil
            self?.showNext()
        }
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        show(next)
    }

    // MARK: - Mock Announcements

    private static let mockChronarchNames = [
        "Chronarch Supreme", "TimeWeaver_X", "VoidSovereign", "InfiniteLoop99",
        "EternalFlame", "CosmicForger", "QuantumTick", "ArcaneChronarch"
    ]

    private static let mockAchievements = [
        "Epoch Breaker", "Timeline Collapse x1000", "Cosmic Awakening",
        "The Eternal Forge", "Void Conqueror", "Tap Master Supreme",
        "10 Billion TE Lifetime", "100 Epoch Resets", "All Challenges Complete"
    ]

    private func generateMockAnnouncement() {
        guard let name = Self.mockChronarchNames.randomElement(),
              let achievement = Self.mockAchievements.randomElement() else { return }

        let announcement = Announcement(
            playerName: name,
            vipTier: .chronarch,
            nameColorId: "vip_chronarch_reality_warp",
            title: "Chronarch Supreme",
            message: "has achieved \(achievement)!",
            timestamp: Date()
        )
        enqueue(announcement)
    }
}
