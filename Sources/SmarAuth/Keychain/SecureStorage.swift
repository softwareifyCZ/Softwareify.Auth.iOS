import Foundation

/// Internal secure storage backed by Keychain.
final class SecureStorage {

    static let shared = SecureStorage()

    private let keychain = KeychainWrapper.standard
    private let accessibility: KeychainItemAccessibility = .whenUnlocked

    func get(_ key: String) -> String? {
        keychain.string(forKey: key, withAccessibility: accessibility)
    }

    func set(_ value: String?, forKey key: String) {
        if let value, !value.isEmpty {
            keychain.set(value, forKey: key, withAccessibility: accessibility)
        } else {
            keychain.removeObject(forKey: key, withAccessibility: accessibility)
        }
    }

    func remove(_ key: String) {
        keychain.removeObject(forKey: key, withAccessibility: accessibility)
    }

    func removeAll() {
        keychain.removeAllKeys()
    }
}
