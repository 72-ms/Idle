import Foundation
import SwiftUI

@Observable
class AppState {
    let saveManager: SaveManager
    let engine: GameEngine
    var showOfflineEarnings: Bool = false
    var offlineEarnings: Decimal = 0
    var offlineDuration: TimeInterval = 0

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
        engine.start()
    }

    func handleAppBecameActive() {
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

    func resetGame() {
        engine.stop()
        saveManager.deleteSave()

        let newPlayer = PlayerState()
        let newEngine = GameEngine(player: newPlayer, saveManager: saveManager)
        // Note: In a full implementation, we'd rebuild the environment.
        // For MVP, the user restarts the app after reset.
    }
}
