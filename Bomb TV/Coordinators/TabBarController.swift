import UIKit

class TabBarController: UITabBarController {
    unowned var coordinator: RootCoordinator

    let homeCoordinator = HomeCoordinator(navigationController: UINavigationController())
    let showsCoordinator = ShowsTabCoordinator(navigationController: UINavigationController())
    let premiumCoordinator = PremiumCoordinator(navigationController: UINavigationController())
    let searchCoordinator = SearchCoordinator(navigationController: UINavigationController())

    init(coordinator: RootCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        homeCoordinator.start()
        showsCoordinator.start()
        premiumCoordinator.start()
        searchCoordinator.start()

        viewControllers = [
            homeCoordinator.navigationController,
            showsCoordinator.navigationController,
            premiumCoordinator.navigationController,
            searchCoordinator.navigationController
        ]
    }
}
