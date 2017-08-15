import Foundation
import RxCocoa
import RxSwift

class CurrencyScrollViewModel {
    var exchangeRateService = DIContainer.Instance.resolve(CurrencyRateService.self)!
    var disposeBag = DisposeBag()

    var items = [CurrencyType.eur, .gbp, .usd]

    var currentIndex: Variable<Int> = Variable<Int>(0)
    var currentItem: Variable<CurrencyType> = Variable<CurrencyType>(.eur)
    var sufficientFundsToExchange: Variable<Bool> = Variable<Bool>(true)
    var storage: [CurrencyType: Variable<Float>] = [.eur: Variable<Float>(0),
                                                    .gbp: Variable<Float>(0),
                                                    .usd: Variable<Float>(0)]

    init() {
        exchangeRateService.currenciesStorage.asObservable()
                .subscribe(onNext: { rates in
                    for rate in rates {
                        if (self.storage[rate.key] != nil) {
                            self.storage[rate.key]!.value = rate.value
                        }
                    }
                }).addDisposableTo(disposeBag)

        currentIndex.asObservable().subscribe(onNext: { next in
            self.currentItem.value = self.items[next]
        }).addDisposableTo(disposeBag)
    }
}
