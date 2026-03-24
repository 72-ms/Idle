import SwiftUI
import SpriteKit

struct MainGameView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player
    @State private var selectedTab: GameTab = .generators
    @State private var showPrestige = false
    @State private var showSettings = false
    @State private var showStats = false
    @State private var showSkillTree = false
    @State private var showDailyReward = false

    var body: some View {
        ZStack {
            eraBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                Divider()
                gameArea
                Divider()
                tabContent
                bottomTabBar
            }

            if appState.showOfflineEarnings {
                offlineEarningsOverlay
            }

            if showDailyReward {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { showDailyReward = false }
                DailyRewardView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if engine.canClaimDailyReward() {
                showDailyReward = true
            }
            NotificationManager.shared.requestPermission()
            NotificationManager.shared.rescheduleNotifications()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 4) {
            Text(TEFormatter.format(player.temporalEnergy))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.1), value: player.temporalEnergy)

            Text("Temporal Energy")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            if engine.totalProductionRate > 0 {
                Text(TEFormatter.formatRate(engine.totalProductionRate))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(eraAccentColor)
            }

            // Secondary info row
            HStack(spacing: 16) {
                if player.relicMaterials > 0 {
                    Label("\(player.relicMaterials)", systemImage: "diamond.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.8))
                }
                if player.hasActiveBoost {
                    Label("\(NSDecimalNumber(decimal: player.activeBoostMultiplier))x Boost", systemImage: "arrow.up.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                if engine.canClaimDailyReward() {
                    Button {
                        showDailyReward = true
                    } label: {
                        Label("Daily!", systemImage: "gift.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Game Area (Tap Zone)

    private var gameArea: some View {
        ZStack {
            SpriteView(scene: makeScene(), options: [.allowsTransparency])
                .frame(height: 200)

            // Tap target
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    engine.tap()
                    HapticsManager.lightTap()
                }
        }
    }

    private func makeScene() -> SKScene {
        let scene = GameScene(size: CGSize(width: 400, height: 200))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .generators:
                GeneratorListView()
            case .upgrades:
                UpgradeShopView()
            case .relics:
                RelicForgeView()
            case .prestige:
                PrestigeView()
            case .skills:
                SkillTreeView()
            case .epoch:
                EpochResetView()
            case .contracts:
                ContractView()
            case .achievements:
                AchievementView()
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Bottom Tab Bar

    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            tabButton("Generators", icon: "gearshape.2", tab: .generators)
            tabButton("Upgrades", icon: "arrow.up.circle", tab: .upgrades)

            if player.totalRelicsForged > 0 || player.relicMaterials >= 3 {
                tabButton("Relics", icon: "diamond", tab: .relics)
            }

            if player.totalPrestigeCount > 0 || engine.canPrestige() {
                tabButton("Prestige", icon: "arrow.counterclockwise.circle", tab: .prestige)
            }

            if player.totalPrestigeCount > 0 {
                tabButton("Skills", icon: "sparkles", tab: .skills)
            }

            if player.totalEpochCount > 0 || engine.canEpochReset() {
                tabButton("Epoch", icon: "arrow.triangle.2.circlepath", tab: .epoch)
            }

            // More menu
            Menu {
                if !player.activeContracts.isEmpty || player.completedContractCount > 0 {
                    Button {
                        selectedTab = .contracts
                    } label: {
                        Label("Contracts", systemImage: "doc.text")
                    }
                }

                Button {
                    selectedTab = .achievements
                } label: {
                    Label("Achievements", systemImage: "trophy")
                }

                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func tabButton(_ title: String, icon: String, tab: GameTab) -> some View {
        Button {
            selectedTab = tab
            HapticsManager.lightTap()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selectedTab == tab ? eraAccentColor : .white.opacity(0.5))
        }
    }

    // MARK: - Offline Earnings Overlay

    private var offlineEarningsOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Welcome Back!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("While you were away for \(OfflineCalculator.formatDuration(appState.offlineDuration)), you earned:")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Text(TEFormatter.format(appState.offlineEarnings))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(eraAccentColor)

                Text("Temporal Energy")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))

                Button("Collect") {
                    appState.showOfflineEarnings = false
                    HapticsManager.mediumTap()
                }
                .font(.headline)
                .padding(.horizontal, 48)
                .padding(.vertical, 12)
                .background(eraAccentColor)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(24)
        }
    }

    // MARK: - Era Theming

    private var eraBackground: some View {
        LinearGradient(
            colors: eraGradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var eraGradientColors: [Color] {
        switch player.currentEra {
        case .ancient:
            return [Color(red: 0.15, green: 0.1, blue: 0.05), Color(red: 0.3, green: 0.2, blue: 0.1)]
        case .medieval:
            return [Color(red: 0.08, green: 0.08, blue: 0.15), Color(red: 0.15, green: 0.15, blue: 0.25)]
        case .industrial:
            return [Color(red: 0.12, green: 0.1, blue: 0.08), Color(red: 0.25, green: 0.2, blue: 0.15)]
        case .digital:
            return [Color(red: 0.02, green: 0.05, blue: 0.1), Color(red: 0.05, green: 0.1, blue: 0.2)]
        case .cosmic:
            return [Color(red: 0.05, green: 0.0, blue: 0.1), Color(red: 0.15, green: 0.05, blue: 0.25)]
        }
    }

    private var eraAccentColor: Color {
        switch player.currentEra {
        case .ancient: return Color(red: 0.9, green: 0.75, blue: 0.4)
        case .medieval: return Color(red: 0.4, green: 0.5, blue: 0.9)
        case .industrial: return Color(red: 0.85, green: 0.65, blue: 0.3)
        case .digital: return Color(red: 0.2, green: 0.9, blue: 0.9)
        case .cosmic: return Color(red: 0.7, green: 0.4, blue: 0.9)
        }
    }
}

enum GameTab: String {
    case generators
    case upgrades
    case relics
    case prestige
    case skills
    case epoch
    case contracts
    case achievements
}
