import AVKit
import BombAPI
import UIKit

class HomeCoordinator: NavigationCoordinator, VideoPresenting {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = true
        self.navigationController = navigationController
    }

    func start() {
        let controller = StoryboardScene.Main.home.instantiate()
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: false)
    }

    func launchShow(show: Show) {
        let controller = StoryboardScene.Shows.singleShow.instantiate()
        controller.show = show
        controller.coordinator = self
        navigationController.pushViewController(controller, animated: true)
    }
}
