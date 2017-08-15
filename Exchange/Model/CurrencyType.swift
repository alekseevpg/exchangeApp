import Foundation

enum CurrencyType: String {
    case gbp = "GBP"
    case usd = "USD"
    case eur = "EUR"

    func toSign() -> String {
        switch (self) {
        case .eur:
            return "€"
        case .usd:
            return "$"
        case .gbp:
            return "£"
        }
    }
}
