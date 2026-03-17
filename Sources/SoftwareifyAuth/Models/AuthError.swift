import Foundation

public enum AuthError: Error, Sendable {
    case general
    case unknown
    case tokenExpired
    case networkError
    case invalidResponse
    case decodingFailed
}
