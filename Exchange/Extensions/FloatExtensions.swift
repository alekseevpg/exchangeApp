import Foundation


extension Optional where Wrapped == Float {
    func toString() -> String {
        guard var value = self else {
            return ""
        }
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
