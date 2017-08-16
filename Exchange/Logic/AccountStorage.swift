import Foundation
import RxCocoa
import RxSwift

class AccountStorage {

    private(set) var currenciesStorage: Variable<[CurrencyType: Double]> = Variable<[CurrencyType: Double]>([.eur: 100,
                                                                                                             .gbp: 100,
                                                                                                             .usd: 100])

    var exchangeRateService: CurrencyRateService
    init(_ exchangeRateService: CurrencyRateService) {
        self.exchangeRateService = exchangeRateService
    }

    func isEnoughFunds(from: CurrencyType, amount: Double) -> Bool {
        return amount <= currenciesStorage.value[from]!
    }

    func exchange(from: CurrencyType, to: CurrencyType, amount: Double) {
        guard let rate = exchangeRateService.getRate(from: from, to: to) else {
            return
        }
        let toAmount = amount * rate
        currenciesStorage.value[from] = currenciesStorage.value[from]! - amount
        currenciesStorage.value[to] = currenciesStorage.value[to]! + toAmount
    }
}
