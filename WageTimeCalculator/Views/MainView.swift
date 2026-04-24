import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = WageCalculatorViewModel()
    @State private var selectedShiftID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            shiftInputSection
            shiftTableSection
            wageSection
            totalsSection
            conversionSection
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 780, minHeight: 620)
        .task {
            await viewModel.refreshRate(force: false)
        }
    }

    private var shiftInputSection: some View {
        HStack {
            Text("Shift (H:MM:SS)")
            TextField("32:07:13", text: $viewModel.shiftInput)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 220)
            Button("Add Shift") {
                viewModel.addShift()
            }
            if let validationError = viewModel.validationError {
                Text(validationError)
                    .foregroundStyle(.red)
            }
        }
    }

    private var shiftTableSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Logged Shifts")
                .font(.headline)

            Table(viewModel.shifts, selection: $selectedShiftID) {
                TableColumn("Added At") { shift in
                    Text(shift.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                TableColumn("Duration") { shift in
                    Text(DurationParser.formatHHHHmmss(seconds: shift.seconds))
                }
                TableColumn("Decimal Hours") { shift in
                    Text(String(format: "%.4f", DurationParser.decimalHours(seconds: shift.seconds)))
                }
            }
            .frame(height: 220)

            HStack {
                Button("Remove Selected") {
                    guard let selectedShiftID else { return }
                    viewModel.removeShift(id: selectedShiftID)
                    self.selectedShiftID = nil
                }
                .disabled(selectedShiftID == nil)
                Text("Total shifts: \(viewModel.shifts.count)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var wageSection: some View {
        HStack(spacing: 12) {
            Text("Hourly Wage")
            TextField("15", text: $viewModel.hourlyWageText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .onChange(of: viewModel.hourlyWageText) { _, _ in
                    viewModel.saveSettings()
                }

            Picker("Base Currency", selection: $viewModel.baseCurrency) {
                ForEach(viewModel.availableCurrencies, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            .onChange(of: viewModel.baseCurrency) { _, _ in
                viewModel.saveSettings()
            }

            Picker("Convert To", selection: $viewModel.targetCurrency) {
                ForEach(viewModel.availableCurrencies.filter { $0 != viewModel.baseCurrency }, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            .onChange(of: viewModel.targetCurrency) { _, _ in
                viewModel.saveSettings()
            }
        }
    }

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Totals")
                .font(.headline)
            Text("Time (HHHH:mm:ss): \(viewModel.totalDurationText)")
            Text("Hours (decimal): \(viewModel.decimalHoursText)")
            Text("Earnings (\(viewModel.baseCurrency)): \(viewModel.baseEarningsText)")
        }
    }

    private var conversionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button("Refresh Today's Rate") {
                    Task {
                        await viewModel.refreshRate(force: false)
                    }
                }
                Button("Force Online Refresh") {
                    Task {
                        await viewModel.refreshRate(force: true)
                    }
                }
            }

            Text("Converted (\(viewModel.targetCurrency)): \(viewModel.convertedEarningsText)")
            Text(viewModel.rateStatusText)
                .foregroundStyle(.secondary)
            if let updatedAt = viewModel.rateUpdatedAt {
                Text("Rate updated: \(updatedAt.formatted(date: .abbreviated, time: .standard))")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
