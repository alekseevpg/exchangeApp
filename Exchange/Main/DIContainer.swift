import Foundation
import Swinject

struct DIContainer {
    private var instance = Container() { container in
        container.register(ExchangeRateServiceProtocol.self) { _ in
            ExchangeRateService()
        }.inObjectScope(.container)
        container.register(AccountStorage.self) { _ in
            AccountStorage(container.resolve(ExchangeRateServiceProtocol.self)!)
        }.inObjectScope(.container)
    }

    func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return instance.resolve(serviceType)
    }

    static let Instance = DIContainer()

    private init() {
    }
}
