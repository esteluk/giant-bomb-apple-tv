struct CredentialProvider: CredentialProviderType {
    static var credential: String?
}

protocol CredentialProviderType {
    static var credential: String? { get }
}
