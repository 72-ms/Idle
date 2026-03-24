import Foundation

enum SkillBranch: String, Codable, CaseIterable {
    case acceleration
    case resonance
    case mastery
}

struct SkillNodeID: Hashable, Codable {
    let branch: SkillBranch
    let index: Int
}

struct SkillNodeConfig {
    let id: SkillNodeID
    let name: String
    let description: String
    let maxLevel: Int
    let costPerLevel: Int
    let effect: SkillEffect
    let prerequisite: SkillNodeID?
}

enum SkillEffect {
    case productionMultiplier(perLevel: Decimal)
    case offlineEfficiency(perLevel: Decimal)
    case tapPower(perLevel: Decimal)
    case relicSlots(perLevel: Int)
    case eraUnlockDiscount(perLevel: Decimal)
    case generatorSynergy(perLevel: Decimal)
    case prestigeBonus(perLevel: Decimal)
}

struct SkillTreeState: Codable {
    var allocations: [String: Int] = [:]
    var availablePoints: Int = 0

    func level(for nodeId: SkillNodeID) -> Int {
        let key = "\(nodeId.branch.rawValue)_\(nodeId.index)"
        return allocations[key] ?? 0
    }

    mutating func allocate(nodeId: SkillNodeID) -> Bool {
        let config = GameConfig.skillNode(for: nodeId)
        let currentLevel = level(for: nodeId)

        guard currentLevel < config.maxLevel else { return false }
        guard availablePoints >= config.costPerLevel else { return false }

        if let prereq = config.prerequisite {
            let prereqConfig = GameConfig.skillNode(for: prereq)
            guard level(for: prereq) >= prereqConfig.maxLevel else { return false }
        }

        let key = "\(nodeId.branch.rawValue)_\(nodeId.index)"
        allocations[key] = currentLevel + 1
        availablePoints -= config.costPerLevel
        return true
    }

    var totalAllocated: Int {
        allocations.values.reduce(0, +)
    }
}
