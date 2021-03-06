import BombAPI
import PromiseKit
import UIKit

class AuthenticationViewController: UIViewController {

    weak var coordinator: RootCoordinator?
    
    @IBOutlet private var backgroundView: ExcitingBackgroundView!
    @IBOutlet private var doneButton: UIButton!
    @IBOutlet private var stack: UIStackView!

    private lazy var codeTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.enablesReturnKeyAutomatically = true
        textField.returnKeyType = .done
        textField.textContentType = .oneTimeCode

        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 100)
        ])

        return textField
    }()
    
    private let viewModel = AuthenticationViewModel()

    private lazy var activity: NSUserActivity = {
        let activity = NSUserActivity(activityType: "uk.co.nathanwong.giantbomb.tv.webpage")
        activity.title = "Launch Giant Bomb"
        activity.webpageURL = URL(string: "https://giantbomb.com/app/bombtv")
        activity.isEligibleForHandoff = true
        return activity
    }()

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [codeTextField, doneButton]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        activity.becomeCurrent()
        stack.insertArrangedSubview(codeTextField, at: 1)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backgroundView.startAnimations()
    }

    override func viewDidDisappear(_ animated: Bool) {
        backgroundView.stopAnimations()
        super.viewDidDisappear(animated)
    }

    @IBAction private func doneAction(_ sender: Any) {
        firstly {
            viewModel.getRegistrationToken(code: codeTextField.text)
        }.ensure {
            self.activity.invalidate()
        }.done {
            self.coordinator?.successfulLogin()
        }.catch { error in  
            self.showAlert(for: error)
        }
    }

    private func showAlert(for error: Error) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

}

extension AuthenticationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneAction(textField)
        return true
    }
}
