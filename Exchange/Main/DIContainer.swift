import Foundation
import Swinject

struct DIContainer {
    private var instance = Container() { c in
        c.register(ExchangeRateServiceProtocol.self) { _ in
            ExchangeRateService()
        }.inObjectScope(.container)
        c.register(AccountStorage.self) { _ in
            AccountStorage(c.resolve(ExchangeRateServiceProtocol.self)!)
        }.inObjectScope(.container)
    }

    func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return instance.resolve(serviceType)
    }

    static let Instance = DIContainer()

    private init() {
    }
}
