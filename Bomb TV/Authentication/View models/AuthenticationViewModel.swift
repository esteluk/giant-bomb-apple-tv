import BombAPI
import Foundation
import PromiseKit

class AuthenticationViewModel {

    private enum Constants {
        static let appName = "bombtv"
    }

    func getRegistrationToken(code: String?) -> Promise<Void> {
        firstly { () -> Promise<AuthenticationResponse> in
            try validate(code: code)
            return BombAPI().getAuthenticationToken(appName: Constants.appName, code: code!)
        }.done { response in
            guard response.isSuccessful,
                let token = response.token else {
                throw AuthenticationError.unknownError
            }
            let store = AuthenticationStore()
            store.save(response: response)
            BombAPI.setAPIKey(token)
        }
    }

    func validate(code: String?) throws {
        guard let code = code,
            code.count == 6 else {
            throw AuthenticationError.isIncorrectLength
        }
    }
}

enum AuthenticationError: Error, LocalizedError {
    case isIncorrectLength
    case unknownError

    var errorDescription: String? {
        switch self {
        case .isIncorrectLength:
            return "Link codes should be six characters long"
        case .unknownError:
            return "It wasn't possible to log you in right now. Please try again later."
        }
    }
}
