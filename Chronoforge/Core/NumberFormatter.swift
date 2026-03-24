import Foundation

struct TEFormatter {
    private static let suffixes = [
        "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc",
        "No", "Dc", "UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc",
        "SpDc", "OcDc", "NoDc", "Vg"
    ]

    static func format(_ value: Decimal) -> String {
        if value < 0 { return "-\(format(-value))" }
        if value < 1000 {
            let d = NSDecimalNumber(decimal: value).doubleValue
            if d == d.rounded(.down) {
                return "\(Int(d))"
            }
            return String(format: "%.1f", d)
        }

        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        guard doubleValue.isFinite else { return "Infinity" }

        let tier = Int(log10(doubleValue) / 3)
        let suffixIndex = min(tier, suffixes.count - 1)

        if suffixIndex >= suffixes.count {
            return String(format: "%.2e", doubleValue)
        }

        let divisor = pow(10.0, Double(suffixIndex * 3))
        let display = doubleValue / divisor

        if display >= 100 {
            return String(format: "%.0f%@", display, suffixes[suffixIndex])
        } else if display >= 10 {
            return String(format: "%.1f%@", display, suffixes[suffixIndex])
        } else {
            return String(format: "%.2f%@", display, suffixes[suffixIndex])
        }
    }

    static func formatRate(_ value: Decimal) -> String {
        "\(format(value))/s"
    }
}
