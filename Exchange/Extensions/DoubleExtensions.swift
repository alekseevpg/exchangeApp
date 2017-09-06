import Foundation

extension Double {
    func toString(_ fractionalDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = fractionalDigits
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Optional where Wrapped == Double {
    func toString() -> String {
        guard let value = self else {
            return ""
        }
        return value.toString(2)
    }

    func isNilOrZero() -> Bool {
        guard let value = self else {
            return false
        }
        return value == 0
    }
}
