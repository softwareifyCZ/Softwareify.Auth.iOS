import XCTest
@testable import SoftwareifyAuth

final class OIDCConfigurationTests: XCTestCase {

    func testUpdateBaseURLPreservesOtherFields() {
        let auth = AuthManager(
            configuration: OIDCConfiguration(
                baseURL: "https://auth.example.com",
                clientId: "client",
                redirectURI: "app:/callback",
                scopes: "openid",
                resource: "api"
            )
        )

        auth.updateBaseURL("https://auth2.example.com")

        XCTAssertEqual(auth.configuration.baseURL, "https://auth2.example.com")
        XCTAssertEqual(auth.configuration.clientId, "client")
        XCTAssertEqual(auth.configuration.redirectURI, "app:/callback")
        XCTAssertEqual(auth.configuration.scopes, "openid")
        XCTAssertEqual(auth.configuration.resource, "api")
    }

    func testAuthorizationURLIncludesPKCEAndOptionalResource() {
        let auth = AuthManager(
            configuration: OIDCConfiguration(
                baseURL: "https://auth.example.com",
                clientId: "client",
                redirectURI: "app:/callback",
                resource: "api"
            )
        )

        guard let result = auth.authorizationURL() else {
            return XCTFail("authorizationURL returned nil")
        }

        let items = URLComponents(url: result.url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let map = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        XCTAssertEqual(map["client_id"], "client")
        XCTAssertEqual(map["response_type"], "code")
        XCTAssertEqual(map["code_challenge_method"], "S256")
        XCTAssertEqual(map["redirect_uri"], "app:/callback")
        XCTAssertEqual(map["resource"], "api")
        XCTAssertNotNil(map["code_challenge"])
        XCTAssertFalse(result.codeVerifier.isEmpty)
    }
}
