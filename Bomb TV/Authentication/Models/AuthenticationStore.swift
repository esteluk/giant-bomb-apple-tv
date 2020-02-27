import BombAPI
import Foundation

class AuthenticationStore {

    private enum Constants {
        static let expiryKey = "registrationExpiry"
        static let tokenKey = "registrationToken"
    }

    private let store = UserDefaults.standard

    var registrationToken: String? {
        return store.string(forKey: Constants.tokenKey)
    }

    func save(response: AuthenticationResponse) {
        store.set(response.token, forKey: Constants.tokenKey)
    }
}
