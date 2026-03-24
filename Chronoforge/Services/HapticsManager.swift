import UIKit

struct HapticsManager {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func lightTap() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }

    static func mediumTap() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }

    static func heavyTap() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
    }
}
