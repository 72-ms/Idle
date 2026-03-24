import Foundation

struct OfflineCalculator {
    static func calculate(
        productionRate: Decimal,
        offlineSeconds: TimeInterval,
        offlineEfficiency: Decimal
    ) -> Decimal {
        let cappedSeconds = min(offlineSeconds, GameConfig.maxOfflineSeconds)
        guard cappedSeconds > 60 else { return 0 }
        return productionRate * Decimal(cappedSeconds) * offlineEfficiency
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
