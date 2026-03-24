import Foundation

// MARK: - Seasonal Event

/// Defines a time-limited seasonal event with exclusive rewards and bonuses
struct SeasonalEvent: Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let startDate: Date
    let endDate: Date
    let theme: String
    let exclusiveCosmetics: [String]
    let bonusMultiplier: Decimal
    let specialCurrency: String

    /// Whether this event is active at the given date.
    func isActive(at date: Date = Date()) -> Bool {
        date >= startDate && date <= endDate
    }
}

// MARK: - Seasonal Event State

/// Persisted player state for seasonal event participation
struct SeasonalEventState: Codable {
    var currentEventId: String? = nil
    var earnedCurrency: Int = 0
    var claimedRewards: Set<String> = []

    init(currentEventId: String? = nil, earnedCurrency: Int = 0, claimedRewards: Set<String> = []) {
        self.currentEventId = currentEventId
        self.earnedCurrency = earnedCurrency
        self.claimedRewards = claimedRewards
    }
}

// MARK: - Seasonal Event System

/// Manages the rotating calendar of seasonal events.
/// Each year has four events aligned to the seasons, each with unique
/// cosmetics, a bonus multiplier, and a special currency.
enum SeasonalEventSystem {

    // MARK: - Helpers

    /// Builds a `Date` from month and day components in the given year.
    private static func date(month: Int, day: Int, year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - Event Definitions

    /// Generates the four seasonal events for a given year.
    static func events(for year: Int) -> [SeasonalEvent] {
        [
            SeasonalEvent(
                id: "spring_bloom_\(year)",
                name: "Spring Bloom",
                description: "The Chronoforge awakens with renewed energy. Flowers of time blossom across every era, boosting production and offering rare petal-themed cosmetics.",
                startDate: date(month: 3, day: 20, year: year),
                endDate: date(month: 6, day: 19, year: year),
                theme: "spring",
                exclusiveCosmetics: [
                    "cosmetic_blossom_anvil",
                    "cosmetic_petal_particles",
                    "cosmetic_verdant_frame"
                ],
                bonusMultiplier: 1.25,
                specialCurrency: "Time Petals"
            ),
            SeasonalEvent(
                id: "summer_solstice_\(year)",
                name: "Summer Solstice",
                description: "The sun reaches its peak and temporal energy surges. Forge under the blazing chrono-sun for amplified rewards and sun-forged cosmetics.",
                startDate: date(month: 6, day: 20, year: year),
                endDate: date(month: 9, day: 21, year: year),
                theme: "summer",
                exclusiveCosmetics: [
                    "cosmetic_solar_hammer",
                    "cosmetic_heatwave_aura",
                    "cosmetic_solstice_crown"
                ],
                bonusMultiplier: 1.5,
                specialCurrency: "Sun Shards"
            ),
            SeasonalEvent(
                id: "autumn_harvest_\(year)",
                name: "Autumn Harvest",
                description: "The temporal fields yield their bounty. Gather chrono-crops and reap the rewards of a season well forged.",
                startDate: date(month: 9, day: 22, year: year),
                endDate: date(month: 12, day: 20, year: year),
                theme: "autumn",
                exclusiveCosmetics: [
                    "cosmetic_harvest_bellows",
                    "cosmetic_amber_leaves",
                    "cosmetic_cornucopia_badge"
                ],
                bonusMultiplier: 1.35,
                specialCurrency: "Chrono Husks"
            ),
            SeasonalEvent(
                id: "winter_frost_\(year)",
                name: "Winter Frost",
                description: "Time itself slows as frost covers the forge. Break through frozen barriers for icy cosmetics and crystallized time rewards.",
                startDate: date(month: 12, day: 21, year: year),
                endDate: date(month: 3, day: 19, year: year + 1),
                theme: "winter",
                exclusiveCosmetics: [
                    "cosmetic_frost_anvil",
                    "cosmetic_snowflake_sparks",
                    "cosmetic_glacial_frame"
                ],
                bonusMultiplier: 1.4,
                specialCurrency: "Frozen Cogs"
            )
        ]
    }

    // MARK: - Current Event

    /// Returns the seasonal event that is currently active, if any.
    /// Checks the current year and the previous year (to cover the winter
    /// event that spans the year boundary).
    static func currentEvent(at date: Date = Date()) -> SeasonalEvent? {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)

        // Check current year's events and previous year's events
        // (winter frost spans Dec -> Mar across years)
        let candidates = events(for: year) + events(for: year - 1)
        return candidates.first { $0.isActive(at: date) }
    }

    /// Returns all events for the current year.
    static func currentYearEvents() -> [SeasonalEvent] {
        let year = Calendar(identifier: .gregorian).component(.year, from: Date())
        return events(for: year)
    }
}
