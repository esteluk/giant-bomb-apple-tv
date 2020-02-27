public struct AuthenticationResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case status
        case token = "regToken"
    }

    let status: AuthenticationStatus
    public let token: String?

    public var isSuccessful: Bool {
        return status == .success
    }
}

enum AuthenticationStatus: String, Decodable {
    case failure
    case success
}
