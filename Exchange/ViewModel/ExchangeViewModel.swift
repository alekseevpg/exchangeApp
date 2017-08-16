import Foundation
import RxSwift
import RxCocoa

class ExchangeViewModel {
    var disposeBag = DisposeBag()

    var fromScrollViewModel = CurrencyScrollViewModel()
    var toScrollViewModel = CurrencyScrollViewModel()

    var fromAmountInput: Variable<String> = Variable<String>("")
    var fromAmountOutput: Variable<Float?> = Variable<Float?>(nil)

    var toAmountOutput: Variable<Float?> = Variable<Float?>(nil)

    var exchangeRate: Variable<String> = Variable<String>("")
    var exchangeRateReverted: Variable<String> = Variable<String>("")

    var sufficientFundsToExchange: Variable<Bool> = Variable<Bool>(true)

    var exchangeRateService = DIContainer.Instance.resolve(CurrencyRateService.self)!

    init() {
        Observable.combineLatest(
                        fromScrollViewModel.currentItem.asObservable(),
                        fromAmountInput.asObservable(),
                        toScrollViewModel.currentItem.asObservable(),
                        exchangeRateService.currenciesRates.asObservable())
                .subscribe(onNext: { next in
                    self.updateCurrentExchangeRate()
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

    func toFieldUpdate(_ input: String) {
        guard let amount = Float(input) else {
            fromAmountOutput.value = nil
            return
        }
        let to = toScrollViewModel.currentItem.value
        let from = fromScrollViewModel.currentItem.value
        fromAmountOutput.value = convert(from: to, to: from, amount: amount)
        fromAmountInput.value = fromAmountOutput.value.toString()
        toAmountOutput.value = amount
        checkIfEnoughFunds()
    }

    private func fromFieldUpdate() {
        guard let amount = Float(fromAmountInput.value) else {
            toAmountOutput.value = nil
            return
        }
        let to = toScrollViewModel.currentItem.value
        let from = fromScrollViewModel.currentItem.value
        toAmountOutput.value = convert(from: from, to: to, amount: amount)
        fromAmountOutput.value = amount
        checkIfEnoughFunds()
    }

    private func checkIfEnoughFunds() {
        var isEnough = true
        if let amount = fromAmountOutput.value {
            isEnough = exchangeRateService.isEnoughFunds(from: fromScrollViewModel.currentItem.value, amount: amount)
        }
        sufficientFundsToExchange.value = isEnough
        fromScrollViewModel.sufficientFundsToExchange.value = isEnough
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
        toAmountOutput.value = nil
        fromAmountInput.value = ""
    }
}
