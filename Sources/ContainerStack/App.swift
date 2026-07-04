import SwiftUI

struct ContainerStackApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
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
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            Button("Quit Davit") { NSApp.terminate(nil) }
        }
    }
}
