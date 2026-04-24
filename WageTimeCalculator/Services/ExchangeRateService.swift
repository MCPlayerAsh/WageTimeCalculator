import Foundation

struct ExchangeRateFetchResult {
    let rate: Double
    let updatedAt: Date
    let source: Source

    enum Source {
        case cache
        case network
    }
}

final class ExchangeRateService {
    private let cache: DailyRateCache
    private let session: URLSession

    init(cache: DailyRateCache = DailyRateCache(), session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    func getRate(base: String, target: String, forceRefresh: Bool = false) async throws -> ExchangeRateFetchResult {
        if !forceRefresh, let todaysRate = cache.loadRate(base: base, target: target) {
            return ExchangeRateFetchResult(rate: todaysRate.rate, updatedAt: todaysRate.updatedAt, source: .cache)
        }

        let fetched = try await fetchLatestRate(base: base, target: target)
        cache.saveRate(base: base, target: target, rate: fetched.rate)
        return ExchangeRateFetchResult(rate: fetched.rate, updatedAt: .now, source: .network)
    }

    func fallbackLatest(base: String, target: String) -> CachedRate? {
        cache.latestRate(base: base, target: target)
    }

    private func fetchLatestRate(base: String, target: String) async throws -> (rate: Double, date: String) {
        var components = URLComponents(string: "https://api.frankfurter.app/latest")
        components?.queryItems = [
            URLQueryItem(name: "from", value: base),
            URLQueryItem(name: "to", value: target)
        ]
        guard let url = components?.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        guard let rate = decoded.rates[target] else { throw URLError(.cannotParseResponse) }
        return (rate, decoded.date)
    }
}

private struct FrankfurterResponse: Decodable {
    let amount: Double?
    let base: String
    let date: String
    let rates: [String: Double]
}
