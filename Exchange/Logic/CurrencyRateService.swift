import Foundation
import Alamofire
import SWXMLHash
import RxSwift
import RxCocoa

class CurrencyRateService {
    private let currencyAPIUrl = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
    var disposeBag = DisposeBag()

    private(set) var currenciesStorage: Variable<[CurrencyType: Float]> = Variable<[CurrencyType: Float]>([.eur: 100,
                                                                                                           .gbp: 100,
                                                                                                           .usd: 100])

    private(set) var currenciesRates: Variable<[CurrencyType: Float]> = Variable<[CurrencyType: Float]>([.eur: 1,
                                                                                                         .gbp: 0.90303,
                                                                                                         .usd: 1.1732])

    init() {
        let timer = Observable<NSInteger>.interval(130, scheduler: MainScheduler.instance)
        timer.subscribe(onNext: { _ in
            self.updateRates()
                    .subscribe(onNext: { rate in
                        self.currenciesRates.value[rate.0] = rate.1
                    }).disposed(by: self.disposeBag)
        }).addDisposableTo(disposeBag)
    }

    func exchange(from: CurrencyType, to: CurrencyType, amount: Float) {
        guard let rate = getRate(from: from, to: to) else {
            return
        }
        let toAmount = amount * rate
        currenciesStorage.value[from] = currenciesStorage.value[from]! - amount
        currenciesStorage.value[to] = currenciesStorage.value[to]! + toAmount
    }

    func getRate(from: CurrencyType, to: CurrencyType) -> Float? {
        guard let rateTo = currenciesRates.value[to], let rateFrom = currenciesRates.value[from] else {
            return nil
        }
        switch from {
        case .eur:
            return rateTo
        default:
            return rateTo / rateFrom
        }
    }

    private func updateRates() -> Observable<(CurrencyType, Float)> {
        return Observable.create { observer in
            Alamofire.request(self.currencyAPIUrl, method: .get)
                    .responseString { response in
                        guard response.result.isSuccess, let result = response.result.value else {
                            observer.onError(response.result.error!)
                            return
                        }
                        let xml = SWXMLHash.parse(result)
                        xml["gesmes:Envelope"]["Cube"]["Cube"]["Cube"].all.forEach({ item in
                            guard let currencyName = item.element?.attribute(by: "currency")?.text,
                                  let type = CurrencyType(rawValue: currencyName),
                                  let rate = item.element?.attribute(by: "rate")?.text,
                                  let rate2 = Float(rate) else {
                                return
                            }
                            observer.onNext(type, rate2)
                        })
                        observer.onCompleted()
                    }
            return Disposables.create()
        }
    }
}
