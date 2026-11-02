import Foundation
import Security

enum KeychainStore {
    enum Failure: LocalizedError {
        case saveFailed

        var errorDescription: String? {
            "Freya couldn't save your sign-in to the Keychain. Please try again."
        }
    }

    private static let service = "ottecode.FreyaPlayer"
    private static let fallbackPrefix = "keychain.fallback"
    private static let removedPrefix = "keychain.removed"

    static func value(for key: String) -> String? {
        guard !UserDefaults.standard.bool(forKey: removedKey(for: key)) else { return nil }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return migratedFallbackValue(for: key)
        }

        return String(data: data, encoding: .utf8)
    }

    static func setValue(_ value: String, for key: String) throws {
        removeValue(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else {
            throw Failure.saveFailed
        }

        UserDefaults.standard.set(false, forKey: removedKey(for: key))
    }

    static func removeValue(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: fallbackKey(for: key))
        UserDefaults.standard.set(true, forKey: removedKey(for: key))
    }

    private static func migratedFallbackValue(for key: String) -> String? {
        guard let value = UserDefaults.standard.string(forKey: fallbackKey(for: key)) else { return nil }

        do {
            try setValue(value, for: key)
            return value
        } catch {
            return nil
        }
    }

    private static func fallbackKey(for key: String) -> String {
        "\(fallbackPrefix).\(key)"
    }

    private static func removedKey(for key: String) -> String {
        "\(removedPrefix).\(key)"
    }
}
