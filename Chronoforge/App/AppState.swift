import Foundation
import SwiftUI

@Observable
class AppState {
    let saveManager: SaveManager
    let engine: GameEngine
    var showOfflineEarnings: Bool = false
    var offlineEarnings: Decimal = 0
    var offlineDuration: TimeInterval = 0
    let storeManager: StoreManager
    let leaderboardManager: LeaderboardManager
    let guildManager: GuildManager
    let profileManager: ProfileManager
    let announcementManager: AnnouncementManager

    init() {
        let saveManager = SaveManager()
        self.saveManager = saveManager

        let player: PlayerState
        if let saved = saveManager.load() {
            player = saved
        } else {
            player = PlayerState()
        }

        self.engine = GameEngine(player: player, saveManager: saveManager)
        self.storeManager = StoreManager()
        self.leaderboardManager = LeaderboardManager()
        self.guildManager = GuildManager()
        self.profileManager = ProfileManager()
        self.announcementManager = AnnouncementManager()

        // Wire up consumable purchase delivery
        let engineRef = self.engine
        storeManager.onConsumablePurchased = { reward in
            engineRef.applyStoreReward(reward)
        }

        // Wire up guild reward delivery
        guildManager.onReward = { [weak engineRef] reward in
            guard let engine = engineRef else { return }
            switch reward {
            case .dailyShards(let amount):
                engine.player.chronoShards += amount
                engine.player.totalChronoShardsEarned += amount
            case .raidComplete(let shards, let crystals, let relicMaterials):
                engine.player.chronoShards += shards
                engine.player.totalChronoShardsEarned += shards
                engine.player.epochCrystals += crystals
                engine.player.relicMaterials += relicMaterials
            }
            engine.save()
        }

        // Sync guild bonuses into engine, and re-sync whenever guild level changes
        syncGuildBonuses()
        guildManager.onBonusChanged = { [weak self] in
            self?.syncGuildBonuses()
        }

        // Wire achievement announcements for Chronarch-tier players
        let announcementRef = self.announcementManager
        let storeRef = self.storeManager
        engine.onAchievementUnlocked = { [weak engineRef] achievement in
            guard let engine = engineRef else { return }
            let vipTier = storeRef.vipProgress.currentTier
            announcementRef.postLocalAchievement(
                playerName: engine.player.displayName,
                vipTier: vipTier,
                nameColorId: engine.player.equippedNameColor,
                title: engine.player.equippedTitle,
                achievementName: achievement.name
            )
        }

        // Sync seasonal event bonus and deliver VIP daily rewards on launch
        syncSeasonalBonus()
        deliverVIPDailyRewards()

        engine.start()
        Task {
            await storeManager.loadProducts()
            leaderboardManager.authenticate()
        }
        AnalyticsManager.shared.track(.sessionStart)
    }

    func handleAppBecameActive() {
        syncGuildBonuses()
        syncSeasonalBonus()
        deliverVIPDailyRewards()
        let earnings = engine.calculateOfflineEarnings()
        if earnings > 0 {
            offlineEarnings = earnings
            offlineDuration = min(
                Date().timeIntervalSince(engine.player.lastOnlineTimestamp),
                GameConfig.maxOfflineSeconds
            )
            showOfflineEarnings = true
        }
        engine.collectOfflineEarnings()
        engine.recalculateProduction()
        engine.start()
    }

    func handleAppWillResignActive() {
        engine.stop()
        AnalyticsManager.shared.track(.sessionEnd)
        AnalyticsManager.shared.flush()
        NotificationManager.shared.rescheduleNotifications()
    }

    func resetGame() {
        engine.stop()
        saveManager.deleteSave()

        let newPlayer = PlayerState()
        let newEngine = GameEngine(player: newPlayer, saveManager: saveManager)
        // Note: In a full implementation, we'd rebuild the environment.
        // For MVP, the user restarts the app after reset.
    }

    /// Pushes current guild-level multipliers into the engine.
    func syncGuildBonuses() {
        engine.guildProductionMultiplier = guildManager.guildProductionMultiplier
        engine.guildOfflineMultiplier = guildManager.guildOfflineMultiplier
        engine.recalculateProduction()
    }

    /// Applies the active seasonal event's production bonus multiplier.
    func syncSeasonalBonus() {
        if let event = SeasonalEventSystem.currentEvent() {
            engine.seasonalMultiplier = event.bonusMultiplier

            // Track participation
            if engine.player.seasonalEventState.currentEventId != event.id {
                engine.player.seasonalEventState = SeasonalEventState(currentEventId: event.id)
            }
        } else {
            engine.seasonalMultiplier = 1
            if engine.player.seasonalEventState.currentEventId != nil {
                engine.player.seasonalEventState.currentEventId = nil
            }
        }
        engine.recalculateProduction()
    }

    /// Delivers VIP-tier daily free rewards once per calendar day.
    /// Uses UserDefaults to track the last claim date.
    private static let vipDailyClaimKey = "chronoforge_vip_daily_claim"

    func deliverVIPDailyRewards() {
        let tier = storeManager.vipProgress.currentTier
        guard tier != .none else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastClaim = UserDefaults.standard.object(forKey: Self.vipDailyClaimKey) as? Date ?? .distantPast
        guard today > lastClaim else { return }

        // Aggregate all daily perks from all tiers up to current
        var shards = 0
        var crystals = 0
        var relicMaterials = 0

        for t in VIPTier.allCases where t <= tier && t != .none {
            for perk in t.perks {
                switch perk {
                case .dailyShards(let n): shards = max(shards, n)
                case .dailyCrystals(let n): crystals = max(crystals, n)
                case .dailyRelicMaterials(let n): relicMaterials = max(relicMaterials, n)
                default: break
                }
            }
        }

        if shards > 0 {
            engine.player.chronoShards += shards
            engine.player.totalChronoShardsEarned += shards
            engine.player.skillTree.availablePoints += shards
        }
        if crystals > 0 {
            engine.player.epochCrystals += crystals
        }
        if relicMaterials > 0 {
            engine.player.relicMaterials += relicMaterials
        }

        UserDefaults.standard.set(today, forKey: Self.vipDailyClaimKey)
        engine.save()
    }
}
