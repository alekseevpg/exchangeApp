import Foundation
import RxSwift
import RxCocoa
@testable import Exchange

class FakeRateService: ExchangeRateServiceProtocol {

    private(set) var currenciesRates: Variable<[CurrencyType: Double]> = Variable<[CurrencyType: Double]>([.eur: 0])

    func getRate(from: CurrencyType, to: CurrencyType) -> Double? {
        return rate
    }

    var rate: Double
    init(_ rate: Double) {
        self.rate = rate
    }

}
