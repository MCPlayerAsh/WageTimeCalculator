import Foundation

struct PersistedState: Codable {
    var shifts: [Shift]
    var hourlyWageText: String
    var baseCurrency: String
    var targetCurrency: String
}

final class StateStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "state.json") {
        let manager = FileManager.default
        let appSupport = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("WageTimeCalculator", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent(filename)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func save(_ state: PersistedState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func load() -> PersistedState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(PersistedState.self, from: data)
    }
}
