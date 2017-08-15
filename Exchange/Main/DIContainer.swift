import Foundation
import Swinject

struct DIContainer {
    private var instance = Container() { c in
        c.register(CurrencyRateService.self) { _ in
            CurrencyRateService()
        }.inObjectScope(.container)
    }

    func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return instance.resolve(serviceType)
    }

    static let Instance = DIContainer()

    private init() {
    }
}
