import Foundation
import RxSwift
import RxCocoa

class ExchangeViewModel {
    var disposeBag = DisposeBag()

    var fromScrollViewModel = CurrencyScrollViewModel()
    var toScrollViewModel = CurrencyScrollViewModel()

    var fromAmountString: Variable<String> = Variable<String>("")
    var fromAmount: Variable<Float?> = Variable<Float?>(nil)

    var toAmount: Variable<Float?> = Variable<Float?>(nil)

    var currentExchangeRate: Variable<String> = Variable<String>("")

    var sufficientFundsToExchange: Variable<Bool> = Variable<Bool>(true)
    var storage: [CurrencyType: Variable<Float>] = [.eur: Variable<Float>(0),
                                                    .gbp: Variable<Float>(0),
                                                    .usd: Variable<Float>(0)]

    var exchangeRateService = DIContainer.Instance.resolve(CurrencyRateService.self)!
    init() {
        Observable.combineLatest(
                        fromScrollViewModel.currentItem.asObservable(),
                        toScrollViewModel.currentItem.asObservable(),
                        exchangeRateService.currenciesRates.asObservable())
                .subscribe(onNext: { _ in
                    if (self.fromScrollViewModel.currentItem.value == self.toScrollViewModel.currentItem.value) {
                        self.toScrollViewModel.selectNextCurrency()
                    }
                    self.updateRate()
                })
                .addDisposableTo(disposeBag)

        exchangeRateService.currenciesStorage.asObservable()
                .subscribe(onNext: { rates in
                    for rate in rates {
                        if (self.storage[rate.key] != nil) {
                            self.storage[rate.key]!.value = rate.value
                        }
                    }
                }).addDisposableTo(disposeBag)

        Observable.combineLatest(
                        fromScrollViewModel.currentItem.asObservable(),
                        fromAmountString.asObservable(),
                        toScrollViewModel.currentItem.asObservable(),
                        exchangeRateService.currenciesRates.asObservable())
                .subscribe(onNext: { next in
                    self.fromFieldUpdate()
                }).addDisposableTo(disposeBag)
    }

    func updateRate() {
        let from = fromScrollViewModel.currentItem.value
        let to = toScrollViewModel.currentItem.value
        guard let rate = exchangeRateService.getRate(from: from, to: to) else {
            return
        }
        currentExchangeRate.value = "1 \(from.toSign()) = \(rate) \(to.toSign())"
    }

    func fromFieldUpdate() {
        guard let amount = Float(fromAmountString.value) else {
            return
        }
        var to = toScrollViewModel.currentItem.value
        var from = fromScrollViewModel.currentItem.value
        toAmount.value = convert(from: from, to: to, amount: amount)
        fromAmount.value = amount
        var currentAmount = self.storage[from]!.value
        self.sufficientFundsToExchange.value = amount <= currentAmount
        self.fromScrollViewModel.sufficientFundsToExchange.value = self.sufficientFundsToExchange.value
    }

    func toFieldUpdate(_ str: String?) {
        guard let amount = Float(str ?? "") else {
            return
        }
        let to = toScrollViewModel.currentItem.value
        let from = fromScrollViewModel.currentItem.value
        fromAmount.value = convert(from: to, to: from, amount: amount)
        toAmount.value = amount
        var currentAmount = self.storage[from]!.value
        self.sufficientFundsToExchange.value = amount <= currentAmount
        self.fromScrollViewModel.sufficientFundsToExchange.value = self.sufficientFundsToExchange.value
    }

    private func convert(from: CurrencyType, to: CurrencyType, amount: Float) -> Float? {
        guard let rate = exchangeRateService.getRate(from: from, to: to) else {
            return nil
        }
        return amount * rate
    }

    func exchange() {
        let from = fromScrollViewModel.currentItem.value
        let to = toScrollViewModel.currentItem.value
        guard let amount = self.fromAmount.value else {
            return
        }
        exchangeRateService.exchange(from: from, to: to, amount: amount)
        fromAmount.value = nil
        toAmount.value = nil
    }
}
