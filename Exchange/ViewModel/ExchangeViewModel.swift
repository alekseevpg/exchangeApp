import Foundation
import RxSwift
import RxCocoa

final class ExchangeViewModel {
    private var disposeBag = DisposeBag()

    var fromScrollViewModel = CurrencyScrollViewModel()
    var toScrollViewModel = CurrencyScrollViewModel()

    var fromAmountOutput: Variable<Double?> = Variable<Double?>(nil)
    var sufficientFundsToExchange: Variable<Bool> = Variable<Bool>(true)

    var fromUpdated: Observable<Double?>
    var toUpdated: Observable<Double?>
    var exchangeRate: Observable<String>
    var exchangeRateReverted: Observable<String>
    let exchangeBtnEnabled: Observable<Bool>
    let toPrefixIsHidden: Observable<Bool>
    let fromPrefixIsHidden: Observable<Bool>
    var exchanged: Observable<()>

    init(exchangeTap: Observable<Void>,
         fromItem: Observable<CurrencyType>,
         toItem: Observable<CurrencyType>,
         fromFieldText: Observable<String>,
         toFieldText: Observable<String>,
         exchangeService: ExchangeRateServiceProtocol,
         accountsStorage: AccountStorage) {

        var fromVar = Variable<Double>(0)
        var toVar = Variable<Double>(0)
        let filtredFrom = fromFieldText
                .throttle(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .filter { input in
                    if let last = input.characters.last, (last == "." || last == ",") {
                        return false
                    } else {
                        return true
                    }
                }.map { amount -> Double in
                    fromVar.value = Double(amount) ?? 0
                    return fromVar.value
                }

        let filtredTo = toFieldText
                .throttle(0.3, scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .filter { input in
                    if let last = input.characters.last, (last == "." || last == ",") {
                        return false
                    } else {
                        return true
                    }
                }.map { amount -> Double in
                    toVar.value = Double(amount) ?? 0
                    return toVar.value
                }

        var ratesUpdated = exchangeService.currenciesRates.asObservable()

        exchangeRate = Observable.combineLatest(fromItem, toItem, ratesUpdated) { from, to, _ in
            guard let rate = exchangeService.getRate(from: from, to: to) else {
                return ""
            }
            return "1 \(from.toSign()) = \(rate.toString(4)) \(to.toSign())"
        }

        exchangeRateReverted = Observable.combineLatest(fromItem, toItem, ratesUpdated) { from, to, _ in
            guard let rate = exchangeService.getRate(from: to, to: from) else {
                return ""
            }
            return "1 \(to.toSign()) = \(rate.toString()) \(from.toSign())"
        }

        var toInfo = Observable.combineLatest(fromItem, toItem, filtredTo, ratesUpdated) { from, to, _, _ in
            return (from, to)
        }
        fromUpdated = toInfo.withLatestFrom(toVar.asObservable()) { info, _ in
            guard let rate = exchangeService.getRate(from: info.1, to: info.0) else {
                return nil
            }
            fromVar.value = toVar.value * rate
            return fromVar.value
        }

        var fromInfo = Observable.combineLatest(fromItem, toItem, filtredFrom, ratesUpdated) { from, to, _, _ in
            return (from, to)
        }
        toUpdated = fromInfo.withLatestFrom(fromVar.asObservable()) { info, _ in
            guard let rate = exchangeService.getRate(from: info.0, to: info.1) else {
                return nil
            }
            toVar.value = fromVar.value * rate
            return toVar.value
        }

        let exchangeInfo = Observable.combineLatest(fromItem, toItem, fromUpdated) {
            return ($0, $1, $2)
        }

        let storage = accountsStorage
        exchanged = exchangeTap.withLatestFrom(exchangeInfo)
                .flatMapLatest { (from, to, amount) in
                    return storage.exchangeTemp(from: from, to: to, amount: amount!) //todo unwrap
                }

        exchangeBtnEnabled = Observable.combineLatest(
                        sufficientFundsToExchange.asObservable(),
                        toUpdated,
                        fromUpdated,
                        fromItem, toItem) { (_: Bool, toAmount: Double?,
                                             fromAmount: Double?, fromItem: CurrencyType,
                                             toItem: CurrencyType) in
                    return toAmount != nil && fromAmount != nil && fromItem != toItem
                            && fromAmount! != 0 && toAmount! != 0
                }.distinctUntilChanged()
                .shareReplay(1)

        fromPrefixIsHidden = fromVar
                .asObservable()
                .map {
                    $0 == 0
                }

        toPrefixIsHidden = toVar
                .asObservable()
                .map {
                    $0 == 0
                }
    }

    private func checkIfEnoughFunds() {
//        var isEnough = true
//        if let amount = fromAmountOutput.value {
//            isEnough = accountsStorage.isEnoughFunds(from: fromScrollViewModel.currentItem.value, amount: amount)
//        }
//        sufficientFundsToExchange.value = isEnough
//        fromScrollViewModel.sufficientFundsToExchange.value = isEnough
    }
}