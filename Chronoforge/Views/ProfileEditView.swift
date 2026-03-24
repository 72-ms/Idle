import SwiftUI

struct ProfileEditView: View {
    @Environment(PlayerState.self) private var player
    @Environment(StoreManager.self) private var store
    @Environment(ProfileManager.self) private var profileManager
    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String = ""

    var vipTier: VIPTier { store.vipProgress.currentTier }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    nameSection
                    titleSection
                    avatarFrameSection
                    nameColorSection
                    profileBorderSection
                    chatFlairSection
                    profileBackgroundSection
                    pinnedAchievementsSection
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
            .onAppear {
                editedName = player.displayName
            }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Display Name")

            HStack {
                TextField("Enter name", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: editedName) { _, newValue in
                        if newValue.count <= 20 {
                            profileManager.updateDisplayName(newValue, on: player)
                        } else {
                            editedName = String(newValue.prefix(20))
                        }
                    }

                Text("\(editedName.count)/20")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .sectionCard()
    }

    // MARK: - Title

    private var titleSection: some View {
        let titles = profileManager.availableTitles(vipTier: vipTier, achievementState: player.achievementState)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Title")

            if titles.isEmpty {
                lockedLabel("Unlock titles through VIP tiers and achievements")
            } else {
                cosmeticPicker(
                    options: titles,
                    selected: player.equippedTitle,
                    allowNone: true
                ) { title in
                    profileManager.equipTitle(title, on: player)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Avatar Frame

    private var avatarFrameSection: some View {
        let frames = profileManager.availableAvatarFrames(vipTier: vipTier)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Avatar Frame")

            if frames.isEmpty {
                lockedLabel("Unlock avatar frames at Bronze VIP and above")
            } else {
                cosmeticPicker(
                    options: frames,
                    selected: player.equippedAvatarFrame,
                    allowNone: true
                ) { frame in
                    profileManager.equipAvatarFrame(frame, on: player)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Name Color

    private var nameColorSection: some View {
        let colors = profileManager.availableNameColors(vipTier: vipTier)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Name Color")

            if colors.isEmpty {
                lockedLabel("Unlock animated name colors at Gold VIP and above")
            } else {
                cosmeticPicker(
                    options: colors,
                    selected: player.equippedNameColor,
                    allowNone: true
                ) { color in
                    profileManager.equipNameColor(color, on: player)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Profile Border

    private var profileBorderSection: some View {
        let borders = profileManager.availableProfileBorders(vipTier: vipTier)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Profile Border")

            if borders.isEmpty {
                lockedLabel("Unlock profile borders at Diamond VIP and above")
            } else {
                cosmeticPicker(
                    options: borders,
                    selected: player.equippedProfileBorder,
                    allowNone: true
                ) { border in
                    profileManager.equipProfileBorder(border, on: player)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Chat Flair

    private var chatFlairSection: some View {
        let flairs = profileManager.availableChatFlairs(vipTier: vipTier)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Chat Flair")

            if flairs.isEmpty {
                lockedLabel("Unlock chat flairs at Mythic VIP and above")
            } else {
                cosmeticPicker(
                    options: flairs,
                    selected: player.equippedChatFlair,
                    allowNone: true
                ) { flair in
                    profileManager.equipChatFlair(flair, on: player)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Profile Background

    private var profileBackgroundSection: some View {
        let bgs = profileManager.availableProfileBackgrounds(vipTier: vipTier)
        return VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Profile Background")

            if bgs.isEmpty {
                lockedLabel("Unlock custom backgrounds at Chronarch VIP")
            } else {
                cosmeticPicker(
                    options: bgs,
                    selected: player.equippedProfileBackground,
                    allowNone: true
                ) { bg in
                    profileManager.equipProfileBackground(bg, on: player)
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Pinned Achievements

    private var pinnedAchievementsSection: some View {
        let unlocked = AchievementSystem.allAchievements.filter {
            player.achievementState.isUnlocked($0.id)
        }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader("Pinned Achievements")
                Spacer()
                Text("\(player.pinnedAchievements.count)/5")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            if unlocked.isEmpty {
                lockedLabel("Unlock achievements to pin them on your profile")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                    ForEach(unlocked, id: \.id.rawValue) { achievement in
                        let isPinned = player.pinnedAchievements.contains(achievement.id.rawValue)
                        Button {
                            profileManager.togglePinnedAchievement(achievement.id.rawValue, on: player)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: isPinned ? "trophy.fill" : "trophy")
                                    .font(.title3)
                                    .foregroundStyle(isPinned ? .yellow : .white.opacity(0.3))
                                Text(achievement.name)
                                    .font(.system(size: 9))
                                    .foregroundStyle(isPinned ? .white : .white.opacity(0.5))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isPinned ? Color.yellow.opacity(0.1) : Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(isPinned ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .sectionCard()
    }

    // MARK: - Shared Components

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
    }

    private func lockedLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.white.opacity(0.4))
        .padding(.vertical, 4)
    }

    private func cosmeticPicker(options: [String], selected: String?, allowNone: Bool, onSelect: @escaping (String?) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if allowNone {
                    cosmeticChip(label: "None", isSelected: selected == nil) {
                        onSelect(nil)
                    }
                }
                ForEach(options, id: \.self) { option in
                    cosmeticChip(
                        label: option.replacingOccurrences(of: "vip_", with: "")
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized,
                        isSelected: selected == option
                    ) {
                        onSelect(option)
                    }
                }
            }
        }
    }

    private func cosmeticChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? VIPColorResolver.color(for: vipTier).opacity(0.2) : Color.white.opacity(0.05))
                .foregroundStyle(isSelected ? VIPColorResolver.color(for: vipTier) : .white.opacity(0.6))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? VIPColorResolver.color(for: vipTier).opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
    }
}

// MARK: - Section Card Modifier

private struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }
}
