import ContainerizationOCI
import ContainerizationOS
import Foundation

/// A saved registry login (credentials live in the login keychain, not here).
struct RegistryLoginRecord: Identifiable, Hashable {
    let hostname: String
    let username: String
    let modified: Date?
    var id: String { hostname }
}

/// Registry credential management, mirroring `container registry login/list/logout`.
/// Credentials are stored in the same login keychain the platform uses, so a
/// login here works for CLI pulls too (and vice-versa).
enum RegistryService {
    /// Same security domain the platform's CLI uses (Constants.keychainID).
    static let keychainDomain = "com.apple.container.registry"

    private static var keychain: KeychainHelper { KeychainHelper(securityDomain: keychainDomain) }

    static func listLogins() -> [RegistryLoginRecord] {
        let infos = (try? keychain.list()) ?? []
        return infos
            .map { RegistryLoginRecord(hostname: $0.hostname, username: $0.username, modified: $0.modifiedDate) }
            .sorted { $0.hostname < $1.hostname }
    }

    /// Validates the credentials against the registry, then saves them. `server`
    /// is the user-facing name (e.g. "docker.io"); it's resolved to the real
    /// registry host for both the check and the keychain key.
    static func login(server rawServer: String, username: String, password: String) async throws {
        let server = Reference.resolveDomain(domain: rawServer.trimmingCharacters(in: .whitespaces))
        let client = RegistryClient(
            host: server,
            scheme: "https",
            authentication: BasicAuthentication(username: username, password: password),
            retryOptions: .init(maxRetries: 3, retryInterval: 300_000_000,
                                shouldRetry: { $0.status.code >= 500 }))
        do {
            try await client.ping()
        } catch {
            throw CLIError(command: "registry login \(server)", message: "authentication failed: \(String(describing: error))")
        }
        do {
            try keychain.save(hostname: server, username: username, password: password)
        } catch {
            throw CLIError(command: "registry login \(server)", message: "credentials verified but keychain save failed: \(error.localizedDescription)")
        }
    }

    static func logout(server rawServer: String) throws {
        let server = Reference.resolveDomain(domain: rawServer.trimmingCharacters(in: .whitespaces))
        do {
            try keychain.delete(hostname: server)
        } catch {
            throw CLIError(command: "registry logout \(server)", message: error.localizedDescription)
        }
    }
}
