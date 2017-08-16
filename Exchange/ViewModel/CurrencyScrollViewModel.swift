import Foundation
import RxCocoa
import RxSwift

class CurrencyScrollViewModel {
    var accountsStorage = DIContainer.Instance.resolve(AccountStorage.self)!
    var disposeBag = DisposeBag()

    var items = [CurrencyType.eur, .gbp, .usd]

    var currentIndex: Variable<Int> = Variable<Int>(0)
    var currentItem: Variable<CurrencyType> = Variable<CurrencyType>(.eur)
    var sufficientFundsToExchange: Variable<Bool> = Variable<Bool>(true)
    var accounts: [CurrencyType: Variable<Double>] = [.eur: Variable<Double>(0),
                                                      .gbp: Variable<Double>(0),
                                                      .usd: Variable<Double>(0)]

    init() {
        accountsStorage.currenciesStorage.asObservable()
                .subscribe(onNext: { rates in
                    for rate in rates {
                        if (self.accounts[rate.key] != nil) {
                            self.accounts[rate.key]!.value = rate.value
                        }
                    }
                }).addDisposableTo(disposeBag)

        currentIndex.asObservable().subscribe(onNext: { next in
            self.currentItem.value = self.items[next]
        }).addDisposableTo(disposeBag)
    }
}
