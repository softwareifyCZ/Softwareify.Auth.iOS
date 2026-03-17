import Foundation

/// OIDC Authentication Manager — reusable across projects.
///
/// Usage:
/// ```swift
/// let config = OIDCConfiguration(
///     baseURL: "https://auth.example.com",
///     clientId: "my-client",
///     redirectURI: "myapp:/oauth2redirect"
/// )
/// let auth = AuthManager(configuration: config)
/// ```
public final class AuthManager: @unchecked Sendable {

    // MARK: - Storage keys

    private enum StorageKey {
        static let accessToken = "smar-auth-access-token"
        static let refreshToken = "smar-auth-refresh-token"
        static let userEmail = "smar-auth-user-email"
    }

    // MARK: - Properties

    public let configuration: OIDCConfiguration
    private let storage = SecureStorage.shared
    private let session: URLSession

    public var isAuthenticated: Bool {
        storage.get(StorageKey.accessToken) != nil
    }

    public var accessToken: String? {
        storage.get(StorageKey.accessToken)
    }

    public var email: String? {
        storage.get(StorageKey.userEmail)
    }

    // MARK: - Init

    public init(configuration: OIDCConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: - PKCE Authorization URL

    /// Generates a PKCE authorization URL and code verifier for the sign-in flow.
    /// Returns `(url, codeVerifier)` — pass the `codeVerifier` to `handleCallback` after redirect.
    public func authorizationURL() -> (url: URL, codeVerifier: String)? {
        let verifier = PKCEHelper.generateCodeVerifier()
        guard let challenge = PKCEHelper.generateCodeChallenge(from: verifier) else { return nil }

        var components = URLComponents(string: "\(configuration.baseURL)/connect/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
        ]

        guard let url = components?.url else { return nil }
        return (url, verifier)
    }

    // MARK: - Handle Callback

    /// Exchanges the authorization code from the redirect URL for tokens.
    public func handleCallback(url: URL, codeVerifier: String) async throws -> TokenResponse {
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.invalidResponse
        }

        let tokenResponse = try await exchangeCodeForToken(code: code, codeVerifier: codeVerifier)

        storage.set(tokenResponse.accessToken, forKey: StorageKey.accessToken)
        storage.set(tokenResponse.refreshToken, forKey: StorageKey.refreshToken)

        // Fetch user info after successful token exchange
        let userInfo = try await fetchUserInfo()
        storage.set(userInfo.email, forKey: StorageKey.userEmail)

        return tokenResponse
    }

    // MARK: - User Info

    /// Fetches user info from the OIDC provider.
    public func fetchUserInfo() async throws -> UserInfo {
        guard let token = storage.get(StorageKey.accessToken) else {
            throw AuthError.tokenExpired
        }

        var request = URLRequest(url: URL(string: "\(configuration.baseURL)/connect/userinfo")!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return try await performRequest(request)
    }

    // MARK: - Sign Out

    public func signOut() {
        storage.remove(StorageKey.accessToken)
        storage.remove(StorageKey.refreshToken)
        storage.remove(StorageKey.userEmail)
    }

    // MARK: - Authenticated Request

    /// Performs a URL request with automatic token refresh on 401.
    public func authenticatedRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        var req = request
        if let token = storage.get(StorageKey.accessToken) {
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            return try await performRequest(req)
        } catch AuthError.tokenExpired {
            // Try refreshing the token once
            try await refreshAccessToken()

            // Retry with new token
            var retryReq = request
            if let token = storage.get(StorageKey.accessToken) {
                retryReq.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            return try await performRequest(retryReq)
        }
    }

    // MARK: - Private

    private func exchangeCodeForToken(code: String, codeVerifier: String) async throws -> TokenResponse {
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
        ]

        var request = URLRequest(url: URL(string: "\(configuration.baseURL)/connect/token")!)
        request.httpMethod = "POST"
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        return try await performRequest(request)
    }

    private func refreshAccessToken() async throws {
        guard let refreshToken = storage.get(StorageKey.refreshToken) else {
            throw AuthError.tokenExpired
        }

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]

        var request = URLRequest(url: URL(string: "\(configuration.baseURL)/connect/token")!)
        request.httpMethod = "POST"
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let response: TokenResponse = try await performRequest(request)
        storage.set(response.accessToken, forKey: StorageKey.accessToken)
        storage.set(response.refreshToken, forKey: StorageKey.refreshToken)
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw AuthError.tokenExpired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AuthError.decodingFailed
        }
    }
}
