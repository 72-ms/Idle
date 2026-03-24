import SwiftUI

struct ChallengeView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    @State private var selectedChallenge: ChallengeConfig?
    @State private var showForfeitConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if let config = engine.activeChallengeConfig {
                    activeChallengeSection(config)
                }

                availableChallengesSection

                completedChallengesSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(item: $selectedChallenge) { challenge in
            challengeDetailSheet(challenge)
        }
        .alert("Forfeit Challenge", isPresented: $showForfeitConfirmation) {
            Button("Forfeit", role: .destructive) {
                engine.forfeitChallenge()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to forfeit the current challenge? All progress will be lost.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("The Eternal Forge")
                .font(.title.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Test your mastery against punishing modifiers for greater rewards.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Active Challenge

    private func activeChallengeSection(_ challenge: ChallengeConfig) -> some View {
        VStack(spacing: 12) {
            Label("Active Challenge", systemImage: "flame.fill")
                .font(.headline)
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                HStack {
                    Text(challenge.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(NSDecimalNumber(decimal: challenge.rewardMultiplier).doubleValue, specifier: "%.1f")x")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.3))
                        .clipShape(Capsule())
                        .foregroundStyle(.orange)
                }

                if let active = player.challengeState.activeChallenge {
                    let elapsed = Date().timeIntervalSince(active.startTime)
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.gray)
                        Text(formattedTime(elapsed))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white)

                        if let limit = active.timeLimit {
                            Spacer()
                            Text("Limit: \(formattedTime(limit))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(elapsed > limit * 0.8 ? .red : .gray)
                        }
                        Spacer()
                    }
                }

                modifierTags(challenge.modifiers)

                Button {
                    showForfeitConfirmation = true
                } label: {
                    Label("Forfeit Challenge", systemImage: "xmark.circle")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.orange.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Available Challenges

    private var availableChallengesSection: some View {
        VStack(spacing: 12) {
            Label("Available Challenges", systemImage: "list.bullet")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            let challenges = ChallengeSystem.allChallenges.filter { config in
                !player.challengeState.completedChallenges.contains(config.id.rawValue)
                    && player.challengeState.activeChallenge?.configId != config.id
            }

            if challenges.isEmpty {
                Text("All challenges completed!")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(challenges) { challenge in
                    challengeRow(challenge)
                }
            }
        }
    }

    private func challengeRow(_ challenge: ChallengeConfig) -> some View {
        let isUnlocked = ChallengeSystem.requirementsMet(for: challenge, epochResets: player.totalEpochCount)
        let isActive = player.challengeState.activeChallenge != nil

        return Button {
            if isUnlocked && !isActive {
                selectedChallenge = challenge
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isUnlocked ? "shield" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(isUnlocked ? .orange : .gray)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(isUnlocked ? .white : .gray)

                    Text(challenge.description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }

                Spacer()

                Text("\(NSDecimalNumber(decimal: challenge.rewardMultiplier).doubleValue, specifier: "%.1f")x")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isUnlocked ? .orange.opacity(0.2) : .gray.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(isUnlocked ? .orange : .gray)
            }
            .padding()
            .background(Color.white.opacity(isUnlocked ? 0.06 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked || isActive)
    }

    // MARK: - Completed Challenges

    private var completedChallengesSection: some View {
        let completedIDs = player.challengeState.completedChallenges
        let completed = ChallengeSystem.allChallenges.filter { completedIDs.contains($0.id.rawValue) }

        return Group {
            if !completed.isEmpty {
                VStack(spacing: 12) {
                    Label("Completed", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(completed) { challenge in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(challenge.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white.opacity(0.8))

                                Text(challenge.description)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(NSDecimalNumber(decimal: challenge.rewardMultiplier).doubleValue, specifier: "%.1f")x")
                                .font(.caption.bold())
                                .foregroundStyle(.green.opacity(0.8))
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Challenge Detail Sheet

    private func challengeDetailSheet(_ challenge: ChallengeConfig) -> some View {
        VStack(spacing: 20) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundStyle(.gray.opacity(0.5))
                .padding(.top, 12)

            Text(challenge.name)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(challenge.description)
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider().overlay(.gray.opacity(0.3))

            VStack(alignment: .leading, spacing: 12) {
                Text("Modifiers")
                    .font(.headline)
                    .foregroundStyle(.orange)

                modifierTags(challenge.modifiers)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            HStack {
                Text("Reward Multiplier")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(NSDecimalNumber(decimal: challenge.rewardMultiplier).doubleValue, specifier: "%.1f")x")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal)

            Spacer()

            Button {
                _ = engine.startChallenge(id: challenge.id)
                selectedChallenge = nil
            } label: {
                Text("Begin Challenge")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.1).ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    // MARK: - Modifier Tags

    private func modifierTags(_ modifiers: [ChallengeModifier]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(modifiers, id: \.rawValue) { modifier in
                Text(modifier.displayName)
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
