import SwiftUI
import SpriteKit

@main
struct ChronoforgeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainGameView()
                .environment(appState)
                .environment(appState.engine)
                .environment(appState.engine.player)
                .environment(appState.storeManager)
                .environment(appState.leaderboardManager)
                .environment(appState.guildManager)
                .environment(appState.profileManager)
                .environment(appState.announcementManager)
                .environment(appState.liveEventManager)
                .environment(appState.guildEventManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    appState.handleAppWillResignActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    appState.handleAppBecameActive()
                }
        }
    }
}
