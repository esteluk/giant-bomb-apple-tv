import UIKit

class ShowsTabCoordinator: NavigationCoordinator {

    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController.isNavigationBarHidden = true
    }

    func start() {
        let controller = StoryboardScene.Main.shows.instantiate()
        navigationController.pushViewController(controller, animated: false)
    }
}
