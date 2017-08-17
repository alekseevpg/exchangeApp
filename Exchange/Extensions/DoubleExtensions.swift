import Foundation

extension Double {
    func toString(_ fractionalDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        //We want to show doubles in format #.##
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
        let formatter = NumberFormatter()
        //We want to show doubles in format #.##
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
