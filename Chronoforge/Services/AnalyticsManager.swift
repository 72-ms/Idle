import Foundation

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    // MARK: - Analytics Event Definitions

    enum AnalyticsEvent {
        case sessionStart
        case sessionEnd
        case tap
        case generatorPurchase(id: String, count: Int)
        case upgradePurchase(id: String)
        case eraUnlock(era: String)
        case prestige(shardsEarned: Double)
        case epochReset(crystalsEarned: Double)
        case relicForge(relicId: String)
        case relicEquip(relicId: String)
        case relicSalvage(relicId: String)
        case dailyRewardClaim(day: Int, streak: Int)
        case contractComplete(contractId: String)
        case achievementUnlock(achievementId: String)
        case shopPurchase(productId: String)
        case adWatched(type: String)
        case challengeStart(challengeId: String)
        case challengeComplete(challengeId: String)
        case offlineEarnings(amount: Double, duration: TimeInterval)
        case skillPointAllocated(nodeId: String)

        var name: String {
            switch self {
            case .sessionStart:                return "session_start"
            case .sessionEnd:                  return "session_end"
            case .tap:                         return "tap"
            case .generatorPurchase:           return "generator_purchase"
            case .upgradePurchase:             return "upgrade_purchase"
            case .eraUnlock:                   return "era_unlock"
            case .prestige:                    return "prestige"
            case .epochReset:                  return "epoch_reset"
            case .relicForge:                  return "relic_forge"
            case .relicEquip:                  return "relic_equip"
            case .relicSalvage:                return "relic_salvage"
            case .dailyRewardClaim:            return "daily_reward_claim"
            case .contractComplete:            return "contract_complete"
            case .achievementUnlock:           return "achievement_unlock"
            case .shopPurchase:                return "shop_purchase"
            case .adWatched:                   return "ad_watched"
            case .challengeStart:              return "challenge_start"
            case .challengeComplete:           return "challenge_complete"
            case .offlineEarnings:             return "offline_earnings"
            case .skillPointAllocated:         return "skill_point_allocated"
            }
        }

        var parameters: [String: String] {
            switch self {
            case .sessionStart, .sessionEnd, .tap:
                return [:]
            case .generatorPurchase(let id, let count):
                return ["id": id, "count": "\(count)"]
            case .upgradePurchase(let id):
                return ["id": id]
            case .eraUnlock(let era):
                return ["era": era]
            case .prestige(let shardsEarned):
                return ["shards_earned": "\(shardsEarned)"]
            case .epochReset(let crystalsEarned):
                return ["crystals_earned": "\(crystalsEarned)"]
            case .relicForge(let relicId):
                return ["relic_id": relicId]
            case .relicEquip(let relicId):
                return ["relic_id": relicId]
            case .relicSalvage(let relicId):
                return ["relic_id": relicId]
            case .dailyRewardClaim(let day, let streak):
                return ["day": "\(day)", "streak": "\(streak)"]
            case .contractComplete(let contractId):
                return ["contract_id": contractId]
            case .achievementUnlock(let achievementId):
                return ["achievement_id": achievementId]
            case .shopPurchase(let productId):
                return ["product_id": productId]
            case .adWatched(let type):
                return ["type": type]
            case .challengeStart(let challengeId):
                return ["challenge_id": challengeId]
            case .challengeComplete(let challengeId):
                return ["challenge_id": challengeId]
            case .offlineEarnings(let amount, let duration):
                return ["amount": "\(amount)", "duration": "\(duration)"]
            case .skillPointAllocated(let nodeId):
                return ["node_id": nodeId]
            }
        }
    }

    // MARK: - Stored Event Record

    private struct EventRecord: Codable {
        let name: String
        let parameters: [String: String]
        let timestamp: Date
    }

    // MARK: - Configuration

    private static let bufferFlushThreshold = 50
    private static let userDefaultsKey = "com.chronoforge.analytics.events"
    private static let sessionHistoryKey = "com.chronoforge.analytics.sessions"
    private static let dailyActiveKey = "com.chronoforge.analytics.lastActiveDate"

    // MARK: - Properties

    var externalHandler: ((AnalyticsEvent) -> Void)?

    private var eventBuffer: [EventRecord] = []
    private var sessionStartDate: Date?
    private var sessionDurations: [TimeInterval] = []
    private let queue = DispatchQueue(label: "com.chronoforge.analytics", qos: .utility)

    // MARK: - Init

    private init() {
        loadPersistedSessions()
        updateDailyActiveMetric()
    }

    // MARK: - Tracking

    func track(_ event: AnalyticsEvent) {
        let record = EventRecord(
            name: event.name,
            parameters: event.parameters,
            timestamp: Date()
        )

        queue.async { [weak self] in
            guard let self = self else { return }
            self.eventBuffer.append(record)
            self.log("[\(record.name)] \(record.parameters)")

            if case .sessionStart = event {
                self.sessionStartDate = record.timestamp
            }

            if case .sessionEnd = event {
                if let start = self.sessionStartDate {
                    let duration = record.timestamp.timeIntervalSince(start)
                    self.sessionDurations.append(duration)
                    self.sessionStartDate = nil
                    self.persistSessionDurations()
                }
            }

            if self.eventBuffer.count >= AnalyticsManager.bufferFlushThreshold {
                self.performFlush()
            }
        }

        externalHandler?(event)
    }

    // MARK: - Flush

    func flush() {
        queue.async { [weak self] in
            self?.performFlush()
        }
    }

    private func performFlush() {
        guard !eventBuffer.isEmpty else { return }

        var persisted = loadPersistedEvents()
        persisted.append(contentsOf: eventBuffer)
        eventBuffer.removeAll()

        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: AnalyticsManager.userDefaultsKey)
        }

        log("Flushed \(persisted.count) total events to UserDefaults")
    }

    // MARK: - Aggregate Queries

    func totalEventsToday() -> Int {
        let allEvents = allPersistedAndBufferedEvents()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return allEvents.filter { $0.timestamp >= startOfDay }.count
    }

    func eventCount(for eventName: String) -> Int {
        let allEvents = allPersistedAndBufferedEvents()
        return allEvents.filter { $0.name == eventName }.count
    }

    func averageSessionDuration() -> TimeInterval {
        guard !sessionDurations.isEmpty else { return 0 }
        let total = sessionDurations.reduce(0, +)
        return total / Double(sessionDurations.count)
    }

    // MARK: - Daily Active Metric

    private func updateDailyActiveMetric() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        UserDefaults.standard.set(today, forKey: AnalyticsManager.dailyActiveKey)
    }

    func lastActiveDate() -> String? {
        return UserDefaults.standard.string(forKey: AnalyticsManager.dailyActiveKey)
    }

    // MARK: - Persistence Helpers

    private func loadPersistedEvents() -> [EventRecord] {
        guard let data = UserDefaults.standard.data(forKey: AnalyticsManager.userDefaultsKey),
              let events = try? JSONDecoder().decode([EventRecord].self, from: data) else {
            return []
        }
        return events
    }

    private func allPersistedAndBufferedEvents() -> [EventRecord] {
        var results: [EventRecord] = []
        queue.sync {
            results = self.loadPersistedEvents() + self.eventBuffer
        }
        return results
    }

    private func persistSessionDurations() {
        if let data = try? JSONEncoder().encode(sessionDurations) {
            UserDefaults.standard.set(data, forKey: AnalyticsManager.sessionHistoryKey)
        }
    }

    private func loadPersistedSessions() {
        guard let data = UserDefaults.standard.data(forKey: AnalyticsManager.sessionHistoryKey),
              let durations = try? JSONDecoder().decode([TimeInterval].self, from: data) else {
            return
        }
        sessionDurations = durations
    }

    // MARK: - Debug Logging

    private func log(_ message: String) {
        #if DEBUG
        print("[AnalyticsManager] \(message)")
        #endif
    }
}
