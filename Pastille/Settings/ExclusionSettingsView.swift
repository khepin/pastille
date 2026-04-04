import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ExclusionSettingsView: View {
    @State private var excludedApps: [ExcludedApp] = ExclusionSettingsView.loadExcludedApps()

    struct ExcludedApp: Identifiable, Codable {
        let id: String // bundle identifier
        let name: String
    }

    var body: some View {
        Form {
            Section {
                if excludedApps.isEmpty {
                    Text("No excluded apps")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    List {
                        ForEach(excludedApps) { app in
                            HStack(spacing: 8) {
                                if let icon = AppIconCache.shared.icon(for: app.id) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                }
                                Text(app.name)
                                Spacer()
                                Button {
                                    removeApp(app)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: min(CGFloat(excludedApps.count) * 32 + 8, 160))
                }

                Button("Add App\u{2026}") {
                    addApp()
                }
            } header: {
                Text("Excluded Applications")
            } footer: {
                Text("Clipboard content from excluded apps will not be saved to history. Password managers are detected automatically via concealed clipboard markers.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Add"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else { return }

        // Avoid duplicates
        guard !excludedApps.contains(where: { $0.id == bundleId }) else { return }

        let name = bundle.infoDictionary?["CFBundleName"] as? String
            ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
            ?? url.deletingPathExtension().lastPathComponent

        let app = ExcludedApp(id: bundleId, name: name)
        excludedApps.append(app)
        saveExcludedApps()
    }

    private func removeApp(_ app: ExcludedApp) {
        excludedApps.removeAll { $0.id == app.id }
        saveExcludedApps()
    }

    private func saveExcludedApps() {
        let ids = excludedApps.map(\.id)
        UserDefaults.standard.set(ids, forKey: "excludedApps")

        if let data = try? JSONEncoder().encode(excludedApps) {
            UserDefaults.standard.set(data, forKey: "excludedAppsDetail")
        }

        // Notify the clipboard monitor
        NotificationCenter.default.post(name: .excludedAppsChanged, object: ids)
    }

    static func loadExcludedApps() -> [ExcludedApp] {
        if let data = UserDefaults.standard.data(forKey: "excludedAppsDetail"),
           let apps = try? JSONDecoder().decode([ExcludedApp].self, from: data) {
            return apps
        }
        return []
    }
}

extension Notification.Name {
    static let excludedAppsChanged = Notification.Name("excludedAppsChanged")
}
