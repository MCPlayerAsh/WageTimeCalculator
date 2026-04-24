import Foundation

enum DurationParserError: LocalizedError {
    case invalidFormat
    case invalidNumber
    case invalidMinuteOrSecond

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Use the format H:MM:SS or HH:MM:SS."
        case .invalidNumber:
            return "Time values must be numbers."
        case .invalidMinuteOrSecond:
            return "Minutes and seconds must be between 0 and 59."
        }
    }
}

enum DurationParser {
    static func parseToSeconds(_ input: String) throws -> Int {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleaned.split(separator: ":")
        guard parts.count == 3 else { throw DurationParserError.invalidFormat }

        guard let hours = Int(parts[0]),
              let minutes = Int(parts[1]),
              let seconds = Int(parts[2]) else {
            throw DurationParserError.invalidNumber
        }

        guard hours >= 0 else { throw DurationParserError.invalidNumber }
        guard (0...59).contains(minutes), (0...59).contains(seconds) else {
            throw DurationParserError.invalidMinuteOrSecond
        }

        return (hours * 3600) + (minutes * 60) + seconds
    }

    static func formatHHHHmmss(seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let secs = safeSeconds % 60
        return String(format: "%04d:%02d:%02d", hours, minutes, secs)
    }

    static func decimalHours(seconds: Int) -> Double {
        Double(seconds) / 3600.0
    }
}
