import Foundation
import RxCocoa
import RxSwift

class AccountStorage {
    var exchangeRateService: ExchangeRateServiceProtocol

    private (set) var accounts: [CurrencyType: Variable<Double>] = [.eur: Variable<Double>(100),
                                                                    .gbp: Variable<Double>(100),
                                                                    .usd: Variable<Double>(100)]
    init(_ exchangeRateService: ExchangeRateServiceProtocol) {
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

    func exchangeTemp(from: CurrencyType, to: CurrencyType, amount: Double) -> Observable<()> {
        return Observable<()>.create { observer in
            guard let rate = self.exchangeRateService.getRate(from: from, to: to) else {
                observer.onCompleted()
                return Disposables.create()
            }
            let toAmount = amount * rate
            self.accounts[from]!.value = self.accounts[from]!.value - amount
            self.accounts[to]!.value = self.accounts[to]!.value + toAmount
            observer.onNext()
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
