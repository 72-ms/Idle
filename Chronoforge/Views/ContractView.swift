import SwiftUI

struct ContractView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Chrono Contracts")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 16)

                if player.activeContracts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.3))

                        Text("No active contracts")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))

                        Text("New contracts appear weekly")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))

                        Button {
                            engine.generateNewContracts()
                            HapticsManager.mediumTap()
                        } label: {
                            Text("Check for Contracts")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.white.opacity(0.1))
                                .clipShape(Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(player.activeContracts) { contract in
                        ContractCard(contract: contract)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ContractCard: View {
    let contract: ActiveContract
    @Environment(GameEngine.self) private var engine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(contract.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if contract.isCompleted && !contract.isClaimed {
                    Text("COMPLETE")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.green)
                        .clipShape(Capsule())
                        .foregroundStyle(.black)
                } else if contract.isExpired {
                    Text("EXPIRED")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.red.opacity(0.5))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }

            // Goal
            Text(contract.goalDescription)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            // Progress bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.1))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(contract.isCompleted ? .green : .cyan)
                            .frame(width: geo.size.width * contract.progressFraction, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(contract.progressFraction * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    if !contract.isExpired && !contract.isCompleted {
                        Text(formatTimeRemaining(contract.timeRemaining))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            // Reward
            HStack {
                Text("Reward: \(contract.rewardDescription)")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Spacer()

                if contract.isCompleted && !contract.isClaimed {
                    Button {
                        engine.claimContractReward(contractId: contract.id)
                        HapticsManager.heavyTap()
                    } label: {
                        Text("Claim")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(.green)
                            .clipShape(Capsule())
                            .foregroundStyle(.black)
                    }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let days = hours / 24
        if days > 0 {
            return "\(days)d \(hours % 24)h left"
        }
        let minutes = (Int(seconds) % 3600) / 60
        return "\(hours)h \(minutes)m left"
    }
}
