import BombAPI
import UIKit

class RootCoordinator: NavigationCoordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = true
        self.navigationController = navigationController
    }

    func start() {
        let store = AuthenticationStore()

        if let token = store.registrationToken {
            BombAPI.setAPIKey(token)
            successfulLogin()
        } else {
            startFirstLaunch()
        }
    }

    func successfulLogin() {
        let tabController = TabBarController(coordinator: self)
        navigationController.setViewControllers([tabController], animated: true)
    }

    private func startFirstLaunch() {
        let authController = StoryboardScene.Authentication.initialScene.instantiate()
        authController.coordinator = self
        navigationController.setViewControllers([authController], animated: true)
    }

}

protocol Coordinator: class {
    func start()
}

extension NavigationCoordinator {
    func childDidFinish(_ child: Coordinator) {
        for (index, coordinator) in childCoordinators.enumerated() {
            if coordinator === child {
                childCoordinators.remove(at: index)
                break
            }
        }
    }
}

protocol NavigationCoordinator: Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
}
protocol DestinationCoordinator: Coordinator {
    var rootController: UIViewController { get set }
}
