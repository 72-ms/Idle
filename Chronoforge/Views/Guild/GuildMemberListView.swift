import SwiftUI

struct GuildMemberListView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player

    @State private var selectedProfile: PlayerProfile?

    private var guild: Guild { guildManager.currentGuild! }
    private var isLeaderOrOfficer: Bool { player.guildRole == .leader || player.guildRole == .officer }

    private var sortedMembers: [GuildMember] {
        guild.members.sorted { lhs, rhs in
            if lhs.role != rhs.role { return lhs.role > rhs.role }
            return lhs.weeklyContribution > rhs.weeklyContribution
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedMembers) { member in
                    memberRow(member)
                        .listRowBackground(Color.white.opacity(0.03))
                        .listRowSeparatorTint(.white.opacity(0.06))
                        .swipeActions(edge: .trailing) {
                            if isLeaderOrOfficer && member.id != player.profileId && member.role != .leader {
                                Button(role: .destructive) {
                                    guildManager.kickMember(memberId: member.id)
                                } label: {
                                    Label("Kick", systemImage: "xmark.circle")
                                }
                            }
                            if player.guildRole == .leader && member.role == .member {
                                Button {
                                    guildManager.promoteToOfficer(memberId: member.id)
                                } label: {
                                    Label("Promote", systemImage: "star")
                                }
                                .tint(.orange)
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Members (\(guild.memberCount))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func memberRow(_ member: GuildMember) -> some View {
        HStack(spacing: 10) {
            VIPBadgeView(tier: member.vipTier, size: .medium)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if member.equippedChatFlair != nil {
                        ChatFlairView(flairId: member.equippedChatFlair, vipTier: member.vipTier)
                    }

                    VIPNameView(
                        name: member.displayName,
                        vipTier: member.vipTier,
                        nameColorId: member.equippedNameColor,
                        title: member.equippedTitle,
                        showBadge: false,
                        font: .subheadline.weight(.semibold)
                    )
                }

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: member.role.symbolName)
                            .font(.system(size: 9))
                        Text(member.role.displayName)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(member.role == .leader ? .yellow : member.role == .officer ? .orange : .white.opacity(0.4))

                    if member.totalDonated > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 7))
                            Text("\(member.totalDonated)")
                                .font(.system(size: 10).monospaced())
                        }
                        .foregroundStyle(.cyan.opacity(0.6))
                    }

                    Text(timeAgo(member.lastActive))
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            Spacer()

            if member.vipTier != .none {
                Text(member.vipTier.displayName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(VIPColorResolver.color(for: member.vipTier))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(VIPColorResolver.color(for: member.vipTier).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}
