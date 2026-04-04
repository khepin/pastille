import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var maxHistoryCount: Int = UserDefaults.standard.object(forKey: "maxHistoryCount") as? Int ?? 1000
    @State private var showClearConfirmation = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !newValue
                        }
                    }
            }

            Section {
                HStack {
                    Text("Maximum history items")
                    Spacer()
                    TextField("", value: $maxHistoryCount, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: maxHistoryCount) { _, newValue in
                            let clamped = max(10, min(50000, newValue))
                            UserDefaults.standard.set(clamped, forKey: "maxHistoryCount")
                        }
                }
            }

            Section {
                Button("Clear All History\u{2026}", role: .destructive) {
                    showClearConfirmation = true
                }
                .confirmationDialog(
                    "Clear all clipboard history?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) {
                        // Will be wired to StorageManager
                        NotificationCenter.default.post(name: .clearAllHistory, object: nil)
                    }
                } message: {
                    Text("This action cannot be undone. Pinned items will also be removed.")
                }
            }
        }
        .formStyle(.grouped)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

extension Notification.Name {
    static let clearAllHistory = Notification.Name("clearAllHistory")
}
