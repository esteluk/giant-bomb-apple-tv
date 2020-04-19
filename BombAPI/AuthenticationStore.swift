import Foundation

public class AuthenticationStore {

    private enum Constants {
        static let expiryKey = "registrationExpiry"
        static let tokenKey = "registrationToken"
    }

    private let store: UserDefaults?

    public init(suiteName: String = "group.uk.co.nathanwong.giantbomb.tv") {
        store = UserDefaults(suiteName: suiteName)
        migrate()
    }

    public var registrationToken: String? {
        return store?.string(forKey: Constants.tokenKey)
    }

    public func save(response: AuthenticationResponse) {
        store?.set(response.token, forKey: Constants.tokenKey)
    }

    private func migrate() {
        guard registrationToken == nil,
            let oldKey = UserDefaults.standard.string(forKey: Constants.tokenKey) else { return }

        store?.set(oldKey, forKey: Constants.tokenKey)
        UserDefaults.standard.removeObject(forKey: Constants.tokenKey)
    }
}
