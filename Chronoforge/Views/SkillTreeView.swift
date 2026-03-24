import SwiftUI

struct SkillTreeView: View {
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Available points
                VStack(spacing: 4) {
                    Text("\(player.skillTree.availablePoints)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("Available Chrono Shards")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.top, 16)

                // Branches
                ForEach(SkillBranch.allCases, id: \.rawValue) { branch in
                    SkillBranchView(branch: branch)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}

struct SkillBranchView: View {
    let branch: SkillBranch
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    private var branchIcon: String {
        switch branch {
        case .acceleration: return "bolt.fill"
        case .resonance: return "waveform"
        case .mastery: return "star.fill"
        }
    }

    private var branchColor: Color {
        switch branch {
        case .acceleration: return .orange
        case .resonance: return .blue
        case .mastery: return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(branch.rawValue.capitalized, systemImage: branchIcon)
                .font(.headline)
                .foregroundStyle(branchColor)

            ForEach(GameConfig.skillNodes(for: branch), id: \.id.index) { node in
                SkillNodeRow(node: node, branchColor: branchColor)
            }
        }
        .padding()
        .background(.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SkillNodeRow: View {
    let node: SkillNodeConfig
    let branchColor: Color
    @Environment(GameEngine.self) private var engine
    @Environment(PlayerState.self) private var player

    private var currentLevel: Int {
        player.skillTree.level(for: node.id)
    }

    private var isMaxed: Bool {
        currentLevel >= node.maxLevel
    }

    private var canAllocate: Bool {
        !isMaxed && player.skillTree.availablePoints >= node.costPerLevel
    }

    var body: some View {
        Button {
            if engine.allocateSkillPoint(nodeId: node.id) {
                HapticsManager.mediumTap()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(node.name)
                            .font(.subheadline.weight(.medium))
                        Text("\(currentLevel)/\(node.maxLevel)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(isMaxed ? branchColor.opacity(0.3) : .white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text(node.description)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                if !isMaxed {
                    Text("\(node.costPerLevel) CS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(canAllocate ? branchColor : .gray)
                }
            }
            .padding(8)
            .background(canAllocate ? branchColor.opacity(0.08) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
        }
        .disabled(!canAllocate)
        .opacity(canAllocate ? 1 : (isMaxed ? 0.7 : 0.4))
    }
}
