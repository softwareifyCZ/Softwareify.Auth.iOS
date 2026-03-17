import Foundation

/// Configuration for the OIDC authentication flow.
public struct OIDCConfiguration {
    public let baseURL: String
    public let clientId: String
    public let redirectURI: String
    public let scopes: String

    public init(
        baseURL: String,
        clientId: String,
        redirectURI: String,
        scopes: String = "openid email profile roles offline_access"
    ) {
        self.baseURL = baseURL
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
}
