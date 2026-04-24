import Foundation
import Combine

@MainActor
final class WageCalculatorViewModel: ObservableObject {
    @Published var shifts: [Shift] = []
    @Published var shiftInput = ""
    @Published var hourlyWageText = "15"
    @Published var baseCurrency = "USD"
    @Published var targetCurrency = "EUR"

    @Published var convertedTotal: Double?
    @Published var lastRate: Double?
    @Published var rateUpdatedAt: Date?
    @Published var rateStatusText = "No conversion loaded yet."
    @Published var validationError: String?

    let availableCurrencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "NZD"]

    private let stateStore: StateStore
    private let fxService: ExchangeRateService

    init(
        stateStore: StateStore = StateStore(),
        fxService: ExchangeRateService = ExchangeRateService()
    ) {
        self.stateStore = stateStore
        self.fxService = fxService
        loadState()
    }

    var totalSeconds: Int {
        shifts.reduce(0) { $0 + $1.seconds }
    }

    var totalDurationText: String {
        DurationParser.formatHHHHmmss(seconds: totalSeconds)
    }

    var decimalHours: Double {
        DurationParser.decimalHours(seconds: totalSeconds)
    }

    var decimalHoursText: String {
        String(format: "%.4f", decimalHours)
    }

    var hourlyWage: Double {
        Double(hourlyWageText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var baseEarnings: Double {
        decimalHours * hourlyWage
    }

    var baseEarningsText: String {
        Self.moneyString(amount: baseEarnings, currencyCode: baseCurrency)
    }

    var convertedEarningsText: String {
        guard let convertedTotal else { return "-" }
        return Self.moneyString(amount: convertedTotal, currencyCode: targetCurrency)
    }

    func addShift() {
        do {
            let seconds = try DurationParser.parseToSeconds(shiftInput)
            shifts.append(Shift(seconds: seconds))
            shiftInput = ""
            validationError = nil
            recalculateConvertedTotal()
            saveState()
        } catch {
            validationError = (error as? LocalizedError)?.errorDescription ?? "Invalid shift format."
        }
    }

    func removeShift(id: UUID) {
        shifts.removeAll { $0.id == id }
        recalculateConvertedTotal()
        saveState()
    }

    func saveSettings() {
        recalculateConvertedTotal()
        saveState()
    }

    func refreshRate(force: Bool = false) async {
        do {
            let result = try await fxService.getRate(base: baseCurrency, target: targetCurrency, forceRefresh: force)
            lastRate = result.rate
            rateUpdatedAt = result.updatedAt
            rateStatusText = result.source == .cache ? "Using today's cached rate." : "Fetched latest daily rate."
            recalculateConvertedTotal()
            saveState()
        } catch {
            if let fallback = fxService.fallbackLatest(base: baseCurrency, target: targetCurrency) {
                lastRate = fallback.rate
                rateUpdatedAt = fallback.updatedAt
                rateStatusText = "Offline or fetch failed. Using most recent cached rate."
                recalculateConvertedTotal()
            } else {
                rateStatusText = "Could not fetch exchange rate and no cache exists yet."
                convertedTotal = nil
            }
        }
    }

    private func recalculateConvertedTotal() {
        guard let lastRate else {
            convertedTotal = nil
            return
        }
        convertedTotal = baseEarnings * lastRate
    }

    private func loadState() {
        guard let state = stateStore.load() else { return }
        shifts = state.shifts
        hourlyWageText = state.hourlyWageText
        baseCurrency = state.baseCurrency
        targetCurrency = state.targetCurrency
    }

    private func saveState() {
        let state = PersistedState(
            shifts: shifts,
            hourlyWageText: hourlyWageText,
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency
        )
        stateStore.save(state)
    }

    private static func moneyString(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currencyCode) \(amount)"
    }
}
