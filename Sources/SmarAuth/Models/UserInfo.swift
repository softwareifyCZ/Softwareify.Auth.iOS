import Foundation

public struct UserInfo: Codable, Sendable {
    public let sub: String
    public let email: String
    public let emailVerified: Bool
    public let role: [String]

    enum CodingKeys: String, CodingKey {
        case sub, email
        case emailVerified = "email_verified"
        case role
    }
}
