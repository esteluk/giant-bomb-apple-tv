import UIKit

class PremiumCoordinator: NavigationCoordinator, VideoPresenting {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = true
        self.navigationController = navigationController
    }

    func start() {
        let controller = StoryboardScene.Premium.initialScene.instantiate()
        controller.coordinator = self

        navigationController.pushViewController(controller, animated: false)
    }
}
