import SwiftUI

struct ContainerStackApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        // A single reopenable window (WindowGroup windows die on close and the
        // menu bar extra could no longer reopen them).
        Window("Davit", id: "main") {
            MainWindow()
                .environmentObject(state)
                .frame(minWidth: 940, minHeight: 560)
                .task {
                    state.startPolling()
                }
        }
        .defaultSize(width: 1180, height: 720)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh") { Task { await state.refreshAll() } }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }

        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
        } label: {
            Image(systemName: "shippingbox.fill")
        }

        Settings {
            SettingsView()
                .environmentObject(state)
        }
    }
}

// MARK: - Menu bar extra

struct MenuBarContent: View {
    @EnvironmentObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            switch state.systemState {
            case .running:
                Label("Services running", systemImage: "circle.fill")
                Button("Stop Services") { state.toggleSystem() }
            case .stopped:
                Label("Services stopped", systemImage: "circle")
                Button("Start Services") { state.toggleSystem() }
            case .unknown:
                Label("Status unknown", systemImage: "questionmark.circle")
            }

            Divider()

            if state.runningContainers.isEmpty {
                Text("No running containers")
            } else {
                Text("Running Containers")
                ForEach(state.runningContainers) { c in
                    Menu(c.id) {
                        Button("Stop") { state.stopContainer(c) }
                        Button("Restart") { state.restartContainer(c) }
                        Button("Open Terminal") { TerminalLauncher.openShell(containerID: c.id) }
                    }
                }
            }

            Divider()

            Button("Open Davit") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit Davit") { NSApp.terminate(nil) }
        }
    }
}
