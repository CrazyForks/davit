import SwiftUI

enum SidebarSection: String, Hashable, CaseIterable {
    case dashboard, containers, images, volumes, networks

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .containers: return "Containers"
        case .images: return "Images"
        case .volumes: return "Volumes"
        case .networks: return "Networks"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.50percent"
        case .containers: return "shippingbox"
        case .images: return "square.stack.3d.down.forward"
        case .volumes: return "externaldrive"
        case .networks: return "network"
        }
    }
}

struct MainWindow: View {
    @EnvironmentObject var state: AppState
    @State private var selection: SidebarSection? = .dashboard

    var body: some View {
        Group {
            if state.cliMissing {
                OnboardingView()
            } else {
                NavigationSplitView {
                    sidebar
                } detail: {
                    detail
                }
            }
        }
        .task {
            SnapshotDriver.runIfRequested(state: state)
        }
        .alert(item: $state.lastError) { err in
            Alert(
                title: Text("Command Failed"),
                message: Text(err.command.isEmpty ? err.message : "\(err.command)\n\n\(err.message)"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section("Overview") {
                    sidebarRow(.dashboard)
                }
                Section("Resources") {
                    sidebarRow(.containers, badge: state.runningContainers.count)
                    sidebarRow(.images, badge: state.images.count)
                    sidebarRow(.volumes, badge: state.volumes.count)
                    sidebarRow(.networks, badge: state.networks.count)
                }
            }
            .listStyle(.sidebar)

            Divider()
            systemFooter
        }
        .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 300)
    }

    private func sidebarRow(_ section: SidebarSection, badge: Int? = nil) -> some View {
        Label(section.title, systemImage: section.icon)
            .badge(badge.map { $0 > 0 ? Text("\($0)") : nil } ?? nil)
            .tag(section)
    }

    private var systemFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.systemState.isRunning ? Color.green : Color.secondary.opacity(0.5))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.systemState.isRunning ? "Services running" : "Services stopped")
                    .font(.caption)
                if let binary = state.resolvedBinary {
                    Text(binary.source.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                state.toggleSystem()
            } label: {
                if state.busyIDs.contains("system") {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: state.systemState.isRunning ? "stop.circle" : "play.circle")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(state.systemState.isRunning ? "Stop container services" : "Start container services")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .dashboard {
        case .dashboard: DashboardView()
        case .containers: ContainersView()
        case .images: ImagesView()
        case .volumes: VolumesView()
        case .networks: NetworksView()
        }
    }
}

// MARK: - Onboarding (CLI not installed)

struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @AppStorage(ContainerBinary.defaultsKey) private var binaryPath = ""

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Apple container platform not found")
                .font(.title2.weight(.semibold))
            Text("Davit talks directly to Apple's open-source container services.\nInstall the platform once, then this app will pick it up automatically.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Download Installer…") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/apple/container/releases")!)
                }
                .buttonStyle(.borderedProminent)
                Button("Check Again") {
                    Task { await state.refreshAll() }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Already installed somewhere unusual? Enter the install root:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("/usr/local", text: $binaryPath)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 340)
                    .onSubmit { Task { await state.refreshAll() } }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
