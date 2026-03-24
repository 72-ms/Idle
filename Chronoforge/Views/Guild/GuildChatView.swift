import SwiftUI

struct GuildChatView: View {
    @Environment(GuildManager.self) private var guildManager
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store

    @State private var messageText = ""

    private var messages: [GuildChatMessage] {
        guildManager.currentGuild?.chatMessages ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                if message.isSystemMessage {
                                    systemMessageRow(message)
                                } else {
                                    chatMessageRow(message)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                Divider()

                // Input bar
                HStack(spacing: 10) {
                    TextField("Message...", text: $messageText)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Guild Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - System Message

    private func systemMessageRow(_ message: GuildChatMessage) -> some View {
        Text(message.content)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.4))
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .id(message.id)
    }

    // MARK: - Chat Message Row

    private func chatMessageRow(_ message: GuildChatMessage) -> some View {
        let isLocal = message.senderId == player.profileId

        return HStack(alignment: .top, spacing: 8) {
            if !isLocal {
                // Avatar badge
                VIPBadgeView(tier: message.senderVIPTier, size: .small)
                    .padding(.top, 2)
            }

            VStack(alignment: isLocal ? .trailing : .leading, spacing: 3) {
                // Name row with flair
                HStack(spacing: 4) {
                    if !isLocal {
                        ChatFlairView(flairId: message.senderChatFlair, vipTier: message.senderVIPTier)

                        VIPNameView(
                            name: message.senderName,
                            vipTier: message.senderVIPTier,
                            nameColorId: message.senderNameColor,
                            title: message.senderTitle,
                            showBadge: false,
                            font: .caption.weight(.semibold)
                        )

                        // Role badge
                        if message.senderRole >= .officer {
                            Image(systemName: message.senderRole.symbolName)
                                .font(.system(size: 8))
                                .foregroundStyle(message.senderRole == .leader ? .yellow : .orange)
                        }
                    }
                }

                // Message bubble
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isLocal ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.25))
            }

            if isLocal {
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 20)
            }
        }
        .padding(.horizontal, isLocal ? 0 : 0)
        .frame(maxWidth: .infinity, alignment: isLocal ? .trailing : .leading)
        .id(message.id)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        guildManager.sendMessage(content: text, player: player, vipTier: store.vipProgress.currentTier)
        messageText = ""
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
