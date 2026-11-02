import Foundation

final class JellyfinSessionStore {
    private let defaults: any DefaultsStore
    private let serverURLKey = "jellyfin.server.url"
    private let userIDKey = "jellyfin.user.id"
    private let userNameKey = "jellyfin.user.name"
    private let tokenKey = "jellyfin.access.token"
    private let loadSecureValue: @MainActor (String) -> String?
    private let saveSecureValue: @MainActor (String, String) throws -> Void
    private let removeSecureValue: @MainActor (String) -> Void

    convenience init() {
        self.init(
            defaults: UserDefaults.standard,
            loadSecureValue: { KeychainStore.value(for: $0) },
            saveSecureValue: { try KeychainStore.setValue($0, for: $1) },
            removeSecureValue: { KeychainStore.removeValue(for: $0) }
        )
    }

    init(
        defaults: any DefaultsStore,
        loadSecureValue: @escaping @MainActor (String) -> String?,
        saveSecureValue: @escaping @MainActor (String, String) throws -> Void,
        removeSecureValue: @escaping @MainActor (String) -> Void
    ) {
        self.defaults = defaults
        self.loadSecureValue = loadSecureValue
        self.saveSecureValue = saveSecureValue
        self.removeSecureValue = removeSecureValue
    }

    var serverURL: String? {
        get { defaults.string(forKey: serverURLKey) }
        set { defaults.set(newValue, forKey: serverURLKey) }
    }

    var userID: String? {
        get { defaults.string(forKey: userIDKey) }
        set { defaults.set(newValue, forKey: userIDKey) }
    }

    var userName: String? {
        get { defaults.string(forKey: userNameKey) }
        set { defaults.set(newValue, forKey: userNameKey) }
    }

    var accessToken: String? {
        loadSecureValue(tokenKey)
    }

    func setAccessToken(_ token: String) throws {
        try saveSecureValue(token, tokenKey)
    }

    var hasSavedConnection: Bool {
        serverURL != nil && userID != nil && accessToken != nil
    }

    func clear() {
        defaults.removeObject(forKey: serverURLKey)
        defaults.removeObject(forKey: userIDKey)
        defaults.removeObject(forKey: userNameKey)
        removeSecureValue(tokenKey)
    }
}
