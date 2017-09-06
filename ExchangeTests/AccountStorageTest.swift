import Foundation
import XCTest
import RxSwift
import RxCocoa
import RxTest

@testable import Exchange

class AccountStorageTest: XCTestCase {
    var accountStorage: AccountStorage!
    var disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        //Fake rate 1 eur - 10 gbp
        accountStorage = AccountStorage(MockExchangeRateService(10))
    }

    func testIsEnoughFunds() {
        XCTAssert(accountStorage.isEnoughFunds(from: .eur, amount: 50))
        XCTAssert(accountStorage.isEnoughFunds(from: .eur, amount: 100))
        XCTAssert(!accountStorage.isEnoughFunds(from: .eur, amount: 200))
    }

    func testExchange() {
        let scheduler = TestScheduler(initialClock: 0)

        let fromObserver = scheduler.createObserver(Double.self)
        let toObserver = scheduler.createObserver(Double.self)
        accountStorage.accounts[.eur]!.asObservable()
                .subscribe(fromObserver)
                .addDisposableTo(disposeBag)
        accountStorage.accounts[.gbp]!.asObservable()
                .subscribe(toObserver)
                .addDisposableTo(disposeBag)
        let fromResult = [
                next(0, Double(100)),
                next(0, Double(0))
        ]
        let toResult = [
                next(0, Double(100)),
                next(0, Double(1100))
        ]
        scheduler.start()

        accountStorage.exchange(from: .eur, to: .gbp, amount: 100)

        XCTAssertEqual(fromObserver.events, fromResult)
        XCTAssertEqual(toObserver.events, toResult)
    }
}
