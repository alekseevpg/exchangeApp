import Foundation
import RxSwift
import RxCocoa

class ExchangeViewModel {
    private var disposeBag = DisposeBag()
    private var exchangeRateService = DIContainer.Instance.resolve(ExchangeRateServiceProtocol.self)!
    private var accountsStorage = DIContainer.Instance.resolve(AccountStorage.self)!

    var fromScrollViewModel = CurrencyScrollViewModel()
    var toScrollViewModel = CurrencyScrollViewModel()

    var fromAmountInput: Variable<String> = Variable<String>("")
    var fromAmountOutput: Variable<Double?> = Variable<Double?>(nil)

    var toAmountOutput: Variable<Double?> = Variable<Double?>(nil)

    var exchangeRate: Variable<String> = Variable<String>("")
    var exchangeRateReverted: Variable<String> = Variable<String>("")

    var sufficientFundsToExchange: Variable<Bool> = Variable<Bool>(true)

    let exchangeBtnEnabled: Observable<Bool>
    let amountPrefixIsHidden: Observable<Bool>

    init() {
        exchangeBtnEnabled = Observable.combineLatest(
                sufficientFundsToExchange.asObservable(),
                toAmountOutput.asObservable(),
                fromAmountOutput.asObservable(),
                fromScrollViewModel.currentItem.asObservable(),
                toScrollViewModel.currentItem.asObservable()) { (enoughFunds: Bool, toAmount: Double?,
                                                                 fromAmount: Double?, fromItem: CurrencyType,
                                                                 toItem: CurrencyType) in
            return enoughFunds && toAmount != nil && fromAmount != nil && fromItem != toItem
        }.shareReplay(1)

        amountPrefixIsHidden = Observable.combineLatest(
                toAmountOutput.asObservable(),
                fromAmountOutput.asObservable()) {
            !($0 != nil && $1 != nil)
        }.shareReplay(1)

        Observable.combineLatest(
                        fromScrollViewModel.currentItem.asObservable(),
                        fromAmountInput.asObservable(),
                        toScrollViewModel.currentItem.asObservable(),
                        exchangeRateService.currenciesRates.asObservable())
                .subscribe(onNext: { _ in
                    self.updateCurrentExchangeRate()
                    self.fromFieldUpdate()
                }).addDisposableTo(disposeBag)
    }

    func exchange() {
        let from = fromScrollViewModel.currentItem.value
        let to = toScrollViewModel.currentItem.value
        guard let amount = self.fromAmountOutput.value else {
            return
        }
        accountsStorage.exchange(from: from, to: to, amount: amount)
        fromAmountOutput.value = nil
        toAmountOutput.value = nil
        fromAmountInput.value = ""
    }

    func toFieldUpdate(_ input: String) {
        guard let amount = Double(input) else {
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
        guard let amount = Double(fromAmountInput.value) else {
            toAmountOutput.value = nil
            return
        }
        let to = toScrollViewModel.currentItem.value
        let from = fromScrollViewModel.currentItem.value
        toAmountOutput.value = convert(from: from, to: to, amount: amount)
        fromAmountOutput.value = amount
        checkIfEnoughFunds()
    }

    private func updateCurrentExchangeRate() {
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

    private func checkIfEnoughFunds() {
        var isEnough = true
        if let amount = fromAmountOutput.value {
            isEnough = accountsStorage.isEnoughFunds(from: fromScrollViewModel.currentItem.value, amount: amount)
        }
        sufficientFundsToExchange.value = isEnough
        fromScrollViewModel.sufficientFundsToExchange.value = isEnough
    }

    private func convert(from: CurrencyType, to: CurrencyType, amount: Double) -> Double? {
        guard let rate = exchangeRateService.getRate(from: from, to: to) else {
            return nil
        }
        return amount * rate
    }
}
