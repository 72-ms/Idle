import Foundation

@Observable
final class ProfileManager {

    // MARK: - Available Cosmetic Options

    /// Returns all titles available to the player (from VIP perks + achievement rewards).
    func availableTitles(vipTier: VIPTier, achievementState: AchievementState) -> [String] {
        var titles: [String] = []

        // Collect titles from all tiers up to and including current
        for tier in VIPTier.allCases where tier <= vipTier {
            for perk in tier.perks {
                if case .exclusiveTitle(let title) = perk {
                    titles.append(title)
                }
            }
        }

        // Collect titles from unlocked achievements
        for config in AchievementSystem.allAchievements {
            guard achievementState.isUnlocked(config.id) else { continue }
            if case .title(let name) = config.reward {
                titles.append(name)
            }
        }

        return titles
    }

    /// Returns all avatar frame IDs available to the player from VIP perks.
    func availableAvatarFrames(vipTier: VIPTier) -> [String] {
        var frames: [String] = []
        for tier in VIPTier.allCases where tier <= vipTier {
            for perk in tier.perks {
                if case .exclusiveAvatar(let id) = perk {
                    frames.append(id)
                }
            }
        }
        return frames
    }

    /// Returns all name color IDs available from VIP perks.
    func availableNameColors(vipTier: VIPTier) -> [String] {
        var colors: [String] = []
        for tier in VIPTier.allCases where tier <= vipTier {
            for perk in tier.perks {
                if case .animatedNameColor(let id) = perk {
                    colors.append(id)
                }
            }
        }
        return colors
    }

    /// Returns all profile border IDs available from VIP perks.
    func availableProfileBorders(vipTier: VIPTier) -> [String] {
        var borders: [String] = []
        for tier in VIPTier.allCases where tier <= vipTier {
            for perk in tier.perks {
                if case .profileBorder(let id) = perk {
                    borders.append(id)
                }
            }
        }
        return borders
    }

    /// Returns all chat flair IDs available from VIP perks.
    func availableChatFlairs(vipTier: VIPTier) -> [String] {
        var flairs: [String] = []
        for tier in VIPTier.allCases where tier <= vipTier {
            for perk in tier.perks {
                if case .chatFlair(let id) = perk {
                    flairs.append(id)
                }
            }
        }
        return flairs
    }

    /// Returns all profile background IDs available from VIP perks.
    func availableProfileBackgrounds(vipTier: VIPTier) -> [String] {
        var bgs: [String] = []
        for tier in VIPTier.allCases where tier <= vipTier {
            for perk in tier.perks {
                if case .customProfileBackground(let id) = perk {
                    bgs.append(id)
                }
            }
        }
        return bgs
    }

    // MARK: - Equip Actions

    func equipTitle(_ title: String?, on player: PlayerState) {
        player.equippedTitle = title
    }

    func equipAvatarFrame(_ frameId: String?, on player: PlayerState) {
        player.equippedAvatarFrame = frameId
    }

    func equipNameColor(_ colorId: String?, on player: PlayerState) {
        player.equippedNameColor = colorId
    }

    func equipProfileBorder(_ borderId: String?, on player: PlayerState) {
        player.equippedProfileBorder = borderId
    }

    func equipChatFlair(_ flairId: String?, on player: PlayerState) {
        player.equippedChatFlair = flairId
    }

    func equipProfileBackground(_ bgId: String?, on player: PlayerState) {
        player.equippedProfileBackground = bgId
    }

    // MARK: - Pinned Achievements

    func togglePinnedAchievement(_ achievementId: String, on player: PlayerState) {
        if let idx = player.pinnedAchievements.firstIndex(of: achievementId) {
            player.pinnedAchievements.remove(at: idx)
        } else if player.pinnedAchievements.count < 5 {
            player.pinnedAchievements.append(achievementId)
        }
    }

    func updateDisplayName(_ name: String, on player: PlayerState) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 20 else { return }
        player.displayName = trimmed
    }
}
