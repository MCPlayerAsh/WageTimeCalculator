import Foundation

struct CachedRate: Codable {
    let base: String
    let target: String
    let dateKey: String
    let rate: Double
    let updatedAt: Date
}

final class DailyRateCache {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "daily-rates.json") {
        let manager = FileManager.default
        let appSupport = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("WageTimeCalculator", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent(filename)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadRate(base: String, target: String, for date: Date = .now) -> CachedRate? {
        let key = cacheKey(base: base, target: target, date: date)
        let storage = loadStorage()
        return storage[key]
    }

    func saveRate(base: String, target: String, date: Date = .now, rate: Double) {
        var storage = loadStorage()
        let key = cacheKey(base: base, target: target, date: date)
        storage[key] = CachedRate(
            base: base,
            target: target,
            dateKey: Self.isoDateString(from: date),
            rate: rate,
            updatedAt: .now
        )
        if let data = try? encoder.encode(storage) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func latestRate(base: String, target: String) -> CachedRate? {
        let storage = loadStorage()
        return storage.values
            .filter { $0.base == base && $0.target == target }
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .first
    }

    private func cacheKey(base: String, target: String, date: Date) -> String {
        "\(base)_\(target)_\(Self.isoDateString(from: date))"
    }

    private func loadStorage() -> [String: CachedRate] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        return (try? decoder.decode([String: CachedRate].self, from: data)) ?? [:]
    }

    private static func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
