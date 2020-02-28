import UIKit

class SearchCoordinator: NavigationCoordinator, VideoPresenting {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = true
        self.navigationController = navigationController
    }

    func start() {
        let resultsController = StoryboardScene.Main.search.instantiate()
        resultsController.coordinator = self
        let searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = resultsController
        let controller = UISearchContainerViewController(searchController: searchController)
        controller.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 3)

        navigationController.pushViewController(controller, animated: false)
    }
}
