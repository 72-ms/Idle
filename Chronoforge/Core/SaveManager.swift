import Foundation

class SaveManager {
    private let saveKey = "chronoforge_player_state"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save(_ player: PlayerState) {
        do {
            let data = try encoder.encode(player)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("[SaveManager] Failed to save: \(error)")
        }
    }

    func load() -> PlayerState? {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        do {
            return try decoder.decode(PlayerState.self, from: data)
        } catch {
            print("[SaveManager] Failed to load: \(error)")
            return nil
        }
    }

    func deleteSave() {
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    func hasSave() -> Bool {
        UserDefaults.standard.data(forKey: saveKey) != nil
    }
}
