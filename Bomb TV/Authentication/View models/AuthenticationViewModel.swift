import BombAPI
import Foundation

class AuthenticationViewModel {

    private enum Constants {
        static let appName = "bombtv"
    }

    func getRegistrationToken(code: String?) async throws {
        try validate(code: code)
        let response = try await BombAPI().getAuthenticationToken(appName: Constants.appName, code: code!)
        guard response.isSuccessful,
              let token = response.token else {
                  throw AuthenticationError.unknownError
        }

        let store = AuthenticationStore()
        store.save(response: response)
        BombAPI.setAPIKey(token)
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
            return "Link codes should consist of six characters."
        case .unknownError:
            return "It wasn't possible to log you in right now. Please try again later."
        }
    }
}
