import Foundation
import RxSwift
import RxCocoa

class ExchangeViewModel {
    var disposeBag = DisposeBag()

    var fromScrollViewModel = CurrencyScrollViewModel()
    var toScrollViewModel = CurrencyScrollViewModel()

    var fromAmountInput: Variable<String> = Variable<String>("")
    var fromAmountOutput: Variable<Float?> = Variable<Float?>(nil)

    var toAmountInput: Variable<Float?> = Variable<Float?>(nil)

    var exchangeRate: Variable<String> = Variable<String>("")
    var exchangeRateReverted: Variable<String> = Variable<String>("")

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
                    self.updateCurrentExchangeRate()
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
                        fromAmountInput.asObservable(),
                        toScrollViewModel.currentItem.asObservable(),
                        exchangeRateService.currenciesRates.asObservable())
                .subscribe(onNext: { next in
                    self.fromFieldUpdate()
                }).addDisposableTo(disposeBag)
    }

    func updateCurrentExchangeRate() {
        let from = fromScrollViewModel.currentItem.value
        let to = toScrollViewModel.currentItem.value
        guard let rate = exchangeRateService.getRate(from: from, to: to) else {
            return
        }
        exchangeRate.value = "1 \(from.toSign()) = \(rate.toString(4)) \(to.toSign())"

        guard let rateReverted = exchangeRateService.getRate(from: to, to: from) else {
            return
        }
        exchangeRateReverted.value = "1 \(to.toSign()) = \(rateReverted.toString()) \(from.toSign())"
    }

    func fromFieldUpdate() {
        guard let amount = Float(fromAmountInput.value) else {
            return
        }
        let to = toScrollViewModel.currentItem.value
        let from = fromScrollViewModel.currentItem.value
        toAmountInput.value = convert(from: from, to: to, amount: amount)
        fromAmountOutput.value = amount
        let currentAmount = self.storage[from]!.value
        self.sufficientFundsToExchange.value = amount <= currentAmount
        self.fromScrollViewModel.sufficientFundsToExchange.value = self.sufficientFundsToExchange.value
    }

    func toFieldUpdate(_ str: String?) {
        guard let amount = Float(str ?? "") else {
            return
        }
        let to = toScrollViewModel.currentItem.value
        let from = fromScrollViewModel.currentItem.value
        fromAmountOutput.value = convert(from: to, to: from, amount: amount)
        toAmountInput.value = amount
        let currentAmount = self.storage[from]!.value
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
        guard let amount = self.fromAmountOutput.value else {
            return
        }
        exchangeRateService.exchange(from: from, to: to, amount: amount)
        fromAmountOutput.value = nil
        toAmountInput.value = nil
    }
}
