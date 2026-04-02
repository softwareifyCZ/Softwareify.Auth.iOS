import Foundation

public enum AuthError: Error, Sendable {
    case general
    case unknown
    /// Access token expired — a refresh attempt may resolve this.
    case tokenExpired
    /// Refresh token is invalid, revoked, or expired — user must re-authenticate.
    case refreshFailed
    case networkError
    case invalidResponse
    case decodingFailed
}
