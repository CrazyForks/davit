import SwiftUI
import AppKit

/// Headless UI verification: `Davit.app/Contents/MacOS/Davit --snapshot /tmp/out`
/// waits for live data, renders each major screen via ImageRenderer (no
/// screen-recording permission needed), writes PNGs, then quits.
enum SnapshotDriver {
    static var outputDir: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    @MainActor
    static func runIfRequested(state: AppState) {
        guard let dir = outputDir else { return }
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        Task { @MainActor in
            // Let initial data + a few stats samples arrive
            try? await Task.sleep(for: .seconds(9))

            render(DashboardView(scrollable: false), state: state, size: CGSize(width: 940, height: 980), to: "\(dir)/dashboard.png")
            render(ContainerListContent(containers: state.containers, scrollable: false) { _ in },
                   state: state, size: CGSize(width: 940, height: 400), to: "\(dir)/containers.png")
            render(ImageListContent(images: state.images, scrollable: false, open: { _ in }, run: { _ in }),
                   state: state, size: CGSize(width: 940, height: 400), to: "\(dir)/images.png")
            render(VolumeListContent(volumes: state.volumes, usedNames: ["testvol"], scrollable: false),
                   state: state, size: CGSize(width: 940, height: 300), to: "\(dir)/volumes.png")
            render(NetworkListContent(networks: state.networks, scrollable: false),
                   state: state, size: CGSize(width: 940, height: 300), to: "\(dir)/networks.png")

            render(RunContainerSheet(prefilledImage: "nginx:latest", scrollable: false),
                   state: state, size: CGSize(width: 560, height: 800), to: "\(dir)/run-sheet.png")

            if let running = state.containers.first(where: { $0.isRunning }) {
                render(ContainerOverviewTab(container: running, scrollable: false),
                       state: state, size: CGSize(width: 940, height: 900), to: "\(dir)/container-overview.png")
                render(ContainerStatsTab(container: running, scrollable: false),
                       state: state, size: CGSize(width: 940, height: 900), to: "\(dir)/container-stats.png")
            }
            NSApp.terminate(nil)
        }
    }

    @MainActor
    static func render<V: View>(_ view: V, state: AppState, size: CGSize, to path: String) {
        let wrapped = view
            .environmentObject(state)
            .frame(width: size.width, height: size.height)
            .background(Color(nsColor: .windowBackgroundColor))
        let renderer = ImageRenderer(content: wrapped)
        renderer.scale = 2
        guard let cg = renderer.cgImage else { return }
        let rep = NSBitmapImageRep(cgImage: cg)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
