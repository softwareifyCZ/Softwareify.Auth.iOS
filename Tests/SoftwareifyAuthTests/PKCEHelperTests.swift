import XCTest
@testable import SoftwareifyAuth

final class PKCEHelperTests: XCTestCase {

    func testGenerateCodeVerifierIsURLSafeWithoutPadding() {
        let verifier = PKCEHelper.generateCodeVerifier()
        XCTAssertFalse(verifier.isEmpty)
        XCTAssertFalse(verifier.contains("="))
        XCTAssertFalse(verifier.contains("+"))
        XCTAssertFalse(verifier.contains("/"))
    }

    func testGenerateCodeChallengeMatchesRFC7636AppendixB() {
        // https://datatracker.ietf.org/doc/html/rfc7636#appendix-B
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = PKCEHelper.generateCodeChallenge(from: verifier)
        XCTAssertEqual(challenge, "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }
}
