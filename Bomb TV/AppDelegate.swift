import BombAPI
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var coordinator: RootCoordinator?
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let navController = UINavigationController()
        coordinator = RootCoordinator(navigationController: navController)

        coordinator?.start()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navController

        window?.makeKeyAndVisible()

        return true
    }

    /// ## URL Schema
    /// `giantbomb-tv://video/(video-id)` - launches directly to a video
    /// `giantbomb-tv://show/(showid)` - launches to the details page for the given show

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let target = components.host else { return false }

        switch target {
        case "video":
            guard let slashIndex = components.path.firstIndex(of: "/"),
                let videoId = Int(components.path.suffix(from: components.path.index(after: slashIndex))) else { return false }

            playVideoWithId(id: videoId)
            return true
            
        default:
            return false
        }
    }

    private func playVideoWithId(id: Int) {
        let api = BombAPI()
        api.video(for: id).map { $0.viewModel(api: api) }.done { viewModel in
            self.coordinator?.launchVideo(viewModel: viewModel)
        }.catch { error in
            print(error.localizedDescription)
        }
    }

}
