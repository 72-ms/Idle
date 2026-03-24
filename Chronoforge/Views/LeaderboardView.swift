import SwiftUI
import GameKit

struct LeaderboardView: View {
    @Environment(LeaderboardManager.self) private var leaderboard
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store
    @State private var selectedBoard: String = LeaderboardManager.totalTEEarned
    @State private var isLoading = false

    private var localVIPTier: VIPTier { store.vipProgress.currentTier }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Text("Leaderboards")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                if !leaderboard.isAuthenticated {
                    // Not signed in
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                        Text("Sign in to Game Center to view leaderboards")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Sign In") {
                            leaderboard.authenticate()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(32)
                } else {
                    // Board selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            boardTab("Lifetime TE", id: LeaderboardManager.totalTEEarned)
                            boardTab("Fastest Prestige", id: LeaderboardManager.fastestPrestige)
                            boardTab("Epoch Resets", id: LeaderboardManager.epochCount)
                            boardTab("Challenges", id: LeaderboardManager.challengesCompleted)
                        }
                        .padding(.horizontal)
                    }

                    // Entries
                    if isLoading {
                        ProgressView()
                            .padding(40)
                    } else if leaderboard.leaderboardEntries.isEmpty {
                        Text("No entries yet")
                            .foregroundStyle(.secondary)
                            .padding(40)
                    } else {
                        LazyVStack(spacing: 2) {
                            ForEach(leaderboard.leaderboardEntries, id: \.rank) { entry in
                                HStack {
                                    Text("#\(entry.rank)")
                                        .font(.subheadline.monospacedDigit().bold())
                                        .foregroundStyle(entry.rank <= 3 ? .yellow : .white)
                                        .frame(width: 40, alignment: .leading)

                                    if entry.isLocalPlayer {
                                        // Local player uses their actual VIP tier from store
                                        LeaderboardNameRow(
                                            name: entry.playerName,
                                            vipTier: localVIPTier,
                                            nameColorId: player.equippedNameColor,
                                            title: player.equippedTitle,
                                            isLocalPlayer: true
                                        )
                                    } else {
                                        LeaderboardNameRow(
                                            name: entry.playerName,
                                            vipTier: entry.vipTier,
                                            nameColorId: entry.nameColorId,
                                            title: entry.title,
                                            isLocalPlayer: false
                                        )
                                    }

                                    Spacer()

                                    Text("\(entry.score)")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(entry.isLocalPlayer ? Color.white.opacity(0.08) : Color.clear)
                            }
                        }
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
            }
        }
        .task {
            await loadBoard()
        }
        .onChange(of: selectedBoard) { _, _ in
            Task { await loadBoard() }
        }
    }

    private func boardTab(_ title: String, id: String) -> some View {
        Button {
            selectedBoard = id
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedBoard == id ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                .foregroundStyle(selectedBoard == id ? .white : .white.opacity(0.6))
                .clipShape(Capsule())
        }
    }

    private func loadBoard() async {
        isLoading = true
        await leaderboard.loadEntries(for: selectedBoard)
        isLoading = false
    }
}
