import SwiftUI

/// Manage registry logins (Docker Hub, ghcr.io, quay.io, …) for pulling private
/// images. Credentials are validated against the registry and stored in the
/// login keychain — shared with the platform, so CLI pulls see them too.
struct RegistrySettings: View {
    @State private var logins: [RegistryLoginRecord] = []
    @State private var showAdd = false
    @State private var updating: RegistryLoginRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Registry Logins").font(.headline)
            Text("Sign in to a registry to pull private images. Credentials are verified and stored in your login keychain (shared with the `container` CLI).")
                .font(.caption)
                .foregroundStyle(.secondary)

            if logins.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "key").font(.system(size: 30)).foregroundStyle(.quaternary)
                    Text("No registry logins").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(logins) { login in
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill").foregroundStyle(.tint)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(login.hostname).font(.body.weight(.medium))
                                Text(login.username).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Update…") { updating = login }
                                .controlSize(.small)
                                .help("Replace the stored password or token (e.g. after rotating it)")
                            Button("Log Out") { logout(login) }
                                .controlSize(.small)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .frame(maxHeight: .infinity)
            }

            HStack {
                Spacer()
                Button {
                    showAdd = true
                } label: {
                    Label("Add Login…", systemImage: "plus")
                }
            }
        }
        .padding()
        .onAppear { logins = RegistryService.listLogins() }
        .sheet(isPresented: $showAdd) {
            RegistryLoginSheet { logins = RegistryService.listLogins() }
        }
        .sheet(item: $updating) { login in
            RegistryLoginSheet(prefilledServer: login.hostname, prefilledUsername: login.username) {
                logins = RegistryService.listLogins()
            }
        }
    }

    private func logout(_ login: RegistryLoginRecord) {
        try? RegistryService.logout(server: login.hostname)
        logins = RegistryService.listLogins()
    }
}

struct RegistryLoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// When set, the sheet updates an existing login: the server is fixed
    /// (it's the keychain key) and saving replaces the stored credential.
    var prefilledServer: String? = nil
    var prefilledUsername: String? = nil
    var onChange: () -> Void

    @State private var server = "docker.io"
    @State private var username = ""
    @State private var password = ""
    @State private var working = false
    @State private var errorText: String?

    private var isUpdate: Bool { prefilledServer != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(isUpdate ? "Update Registry Login" : "Add Registry Login").font(.title3.weight(.semibold))
            Form {
                TextField("Registry", text: $server)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isUpdate)
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password or access token", text: $password)
                    .textFieldStyle(.roundedBorder)
            }
            .formStyle(.columns)
            Text("For Docker Hub, use an access token instead of your password.")
                .font(.caption).foregroundStyle(.secondary)

            if let errorText {
                Text(errorText).font(.caption).foregroundStyle(.red).textSelection(.enabled).lineLimit(4)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button {
                    logIn()
                } label: {
                    if working { ProgressView().controlSize(.small) } else { Text(isUpdate ? "Update" : "Log In") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(server.isEmpty || username.isEmpty || password.isEmpty || working)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            if let prefilledServer { server = prefilledServer }
            if let prefilledUsername { username = prefilledUsername }
        }
    }

    private func logIn() {
        working = true
        errorText = nil
        Task {
            do {
                try await RegistryService.login(server: server, username: username, password: password)
                onChange()
                dismiss()
            } catch let e as CLIError {
                errorText = e.message
            } catch {
                errorText = error.localizedDescription
            }
            working = false
        }
    }
}
