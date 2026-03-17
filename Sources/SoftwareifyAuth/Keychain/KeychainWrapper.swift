import Foundation

private let SecMatchLimit: String! = kSecMatchLimit as String
private let SecReturnData: String! = kSecReturnData as String
private let SecValueData: String! = kSecValueData as String
private let SecAttrAccessible: String! = kSecAttrAccessible as String
private let SecClass: String! = kSecClass as String
private let SecAttrService: String! = kSecAttrService as String
private let SecAttrGeneric: String! = kSecAttrGeneric as String
private let SecAttrAccount: String! = kSecAttrAccount as String
private let SecAttrAccessGroup: String! = kSecAttrAccessGroup as String

class KeychainWrapper {

    static let standard = KeychainWrapper()

    private(set) var serviceName: String
    private(set) var accessGroup: String?

    private static let defaultServiceName: String = {
        Bundle.main.bundleIdentifier ?? "SmarAuth"
    }()

    private convenience init() {
        self.init(serviceName: KeychainWrapper.defaultServiceName)
    }

    init(serviceName: String, accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    // MARK: - Read

    func string(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> String? {
        guard let data = data(forKey: key, withAccessibility: accessibility) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func data(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Data? {
        var query = setupQuery(forKey: key, withAccessibility: accessibility)
        query[SecMatchLimit] = kSecMatchLimitOne
        query[SecReturnData] = kCFBooleanTrue

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == noErr ? result as? Data : nil
    }

    // MARK: - Write

    @discardableResult
    func set(_ value: String, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, forKey: key, withAccessibility: accessibility)
    }

    @discardableResult
    func set(_ value: Data, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
        var query = setupQuery(forKey: key, withAccessibility: accessibility)
        query[SecValueData] = value
        query[SecAttrAccessible] = (accessibility ?? .whenUnlocked).keychainAttrValue

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return update(value, forKey: key, withAccessibility: accessibility)
        }
        return false
    }

    // MARK: - Delete

    @discardableResult
    func removeObject(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
        let query = setupQuery(forKey: key, withAccessibility: accessibility)
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    @discardableResult
    func removeAllKeys() -> Bool {
        var query: [String: Any] = [SecClass: kSecClassGenericPassword]
        query[SecAttrService] = serviceName
        if let accessGroup { query[SecAttrAccessGroup] = accessGroup }
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Private

    private func update(_ value: Data, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
        var query = setupQuery(forKey: key, withAccessibility: accessibility)
        if let accessibility { query[SecAttrAccessible] = accessibility.keychainAttrValue }
        let update = [SecValueData: value]
        return SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecSuccess
    }

    private func setupQuery(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> [String: Any] {
        var query: [String: Any] = [SecClass: kSecClassGenericPassword]
        query[SecAttrService] = serviceName
        if let accessibility { query[SecAttrAccessible] = accessibility.keychainAttrValue }
        if let accessGroup { query[SecAttrAccessGroup] = accessGroup }
        let encoded = key.data(using: .utf8)
        query[SecAttrGeneric] = encoded
        query[SecAttrAccount] = encoded
        return query
    }
}
