// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

@main
struct ABIApp: App {
    init() {
        // Make this a GUI process instead of CLI:
        NSApplication.shared.setActivationPolicy(.regular)

        // Bring window to front
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ProfileListView()
                .forPreviews()
        }
    }
}

struct ProfileListView: View {
    @Environment(ProfileObserver.self)
    private var profileObserver

    @Environment(TunnelObserver.self)
    private var tunnelObserver

    var body: some View {
        List {
            profilesSection
        }
        .toolbar {
            newProfileButton
            importURLButton
            importTextButton
        }
    }
}

private extension ProfileListView {
    var profilesSection: some View {
        ForEach(profileObserver.headers) { profile in
            HStack {
                Text(profile.name)
                Spacer()
                Text(tunnelObserver.status(for: profile.id).rawValue)
                Toggle("", isOn: Binding {
                    tunnelObserver.status(for: profile.id) == .connected
                } set: {
                    tunnelObserver.setEnabled($0, profileId: profile.id)
                })
            }
        }
    }

    var newProfileButton: some View {
        Button("New") {
            Task {
                do {
                    try await profileObserver.new()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    var importURLButton: some View {
        Button("Import file") {
            Task {
                do {
                    guard let url = URL(string: "https://") else {
                        fatalError()
                    }
                    try await profileObserver.new(fromURL: url.absoluteString)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }

    var importTextButton: some View {
        Button("Import text") {
            Task {
                do {
                    try await profileObserver.new(fromText: "text")
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ProfileListView()
        .forPreviews()
}
