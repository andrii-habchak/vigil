import Foundation

/// Persists user settings in `UserDefaults`. Kept tiny and dependency-free so it can
/// be swapped for an in-memory instance in tests.
final class SettingsStore {
    private let defaults: UserDefaults
    private enum Key {
        static let schedule = "vigil.schedule"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSchedule() -> ScheduleModel {
        guard let data = defaults.data(forKey: Key.schedule),
              let model = try? JSONDecoder().decode(ScheduleModel.self, from: data) else {
            return ScheduleModel()
        }
        return model
    }

    func saveSchedule(_ model: ScheduleModel) {
        guard let data = try? JSONEncoder().encode(model) else { return }
        defaults.set(data, forKey: Key.schedule)
    }
}
