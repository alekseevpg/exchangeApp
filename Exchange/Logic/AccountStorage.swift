import Foundation
import RxCocoa
import RxSwift

class AccountStorage {
    var exchangeRateService: CurrencyRateService

    private (set) var accounts: [CurrencyType: Variable<Double>] = [.eur: Variable<Double>(100),
                                                                    .gbp: Variable<Double>(100),
                                                                    .usd: Variable<Double>(100)]
    init(_ exchangeRateService: CurrencyRateService) {
        self.exchangeRateService = exchangeRateService
    }

    func isEnoughFunds(from: CurrencyType, amount: Double) -> Bool {
        return amount <= accounts[from]!.value
    }

    func exchange(from: CurrencyType, to: CurrencyType, amount: Double) {
        guard let rate = exchangeRateService.getRate(from: from, to: to) else {
            return
        }
        let toAmount = amount * rate
        accounts[from]!.value = accounts[from]!.value - amount
        accounts[to]!.value = accounts[to]!.value + toAmount
    }
}
