import BombAPI
import UIKit

class RootCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = true
        self.navigationController = navigationController
    }

    func start() {
        let store = AuthenticationStore()

        let storyboard: UIStoryboard
        let viewController: UIViewController
        if let token = store.registrationToken {
            BombAPI.setAPIKey(token)
            storyboard = UIStoryboard(name: "Main", bundle: nil)
            viewController = storyboard.instantiateInitialViewController()!
        } else {
            storyboard = UIStoryboard(name: "Authentication", bundle: nil)
            let authController = storyboard.instantiateInitialViewController() as? AuthenticationViewController
            authController?.coordinator = self
            viewController = authController!
        }

        navigationController.pushViewController(viewController, animated: false)
    }

    func successfulLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateInitialViewController() else {
            preconditionFailure()
        }

        navigationController.setViewControllers([viewController], animated: true)
    }

}

protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}
