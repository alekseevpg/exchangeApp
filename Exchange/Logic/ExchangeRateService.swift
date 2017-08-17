import Foundation
import Alamofire
import SWXMLHash
import RxSwift
import RxCocoa

protocol ExchangeRateServiceProtocol {

    func getRate(from: CurrencyType, to: CurrencyType) -> Double?

    var currenciesRates: Variable<[CurrencyType: Double]> { get }
}

class ExchangeRateService: ExchangeRateServiceProtocol {
    private let currencyAPIUrl = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
    private var disposeBag = DisposeBag()

    private(set) var currenciesRates: Variable<[CurrencyType: Double]> = Variable<[CurrencyType: Double]>([.eur: 1,
                                                                                                           .gbp: 0.90303,
                                                                                                           .usd: 1.1732])

    init() {
        let timer = Observable<NSInteger>
                .interval(RxTimeInterval(30), scheduler: MainScheduler.instance)
                .startWith(-1)
        timer.subscribe(onNext: { _ in
            self.updateRates()
                    .subscribe(onNext: { rate in
                        self.currenciesRates.value[rate.0] = rate.1
                    }).disposed(by: self.disposeBag)
        }).addDisposableTo(disposeBag)
    }

    func getRate(from: CurrencyType, to: CurrencyType) -> Double? {
        guard let rateTo = currenciesRates.value[to], let rateFrom = currenciesRates.value[from] else {
            return nil
        }
        //ECB give us all rates relative to eur. So we assert that eur is always 1
        switch from {
        case .eur:
            return rateTo
        default:
            return rateTo / rateFrom
        }
    }

    private func updateRates() -> Observable<(CurrencyType, Double)> {
        print("updateRates started")
        return Observable.create { observer in
            Alamofire.request(self.currencyAPIUrl, method: .get)
                    .responseString { response in
                        guard response.result.isSuccess, let result = response.result.value else {
                            observer.onError(response.result.error!)
                            return
                        }
                        let xml = SWXMLHash.parse(result)
                        xml["gesmes:Envelope"]["Cube"]["Cube"]["Cube"].all.forEach({ item in
                            guard let currencyTypeStr = item.element?.attribute(by: "currency")?.text,
                                  let type = CurrencyType(rawValue: currencyTypeStr),
                                  let currencyRateStr = item.element?.attribute(by: "rate")?.text,
                                  let rate = Double(currencyRateStr) else {
                                return
                            }
                            observer.onNext(type, rate)
                        })
                        observer.onCompleted()
                        print("updateRates finished")

                    }
            return Disposables.create()
        }
    }
}
