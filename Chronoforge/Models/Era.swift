import Foundation

enum Era: String, Codable, CaseIterable, Identifiable {
    case ancient
    case medieval
    case industrial
    case digital
    case cosmic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ancient: return "Ancient Era"
        case .medieval: return "Medieval Era"
        case .industrial: return "Industrial Era"
        case .digital: return "Digital Era"
        case .cosmic: return "Cosmic Era"
        }
    }

    var unlockCost: Decimal {
        switch self {
        case .ancient: return 0
        case .medieval: return 1_000_000
        case .industrial: return 1_000_000_000
        case .digital: return 1e15
        case .cosmic: return 1e24
        }
    }

    var order: Int {
        switch self {
        case .ancient: return 0
        case .medieval: return 1
        case .industrial: return 2
        case .digital: return 3
        case .cosmic: return 4
        }
    }
}
