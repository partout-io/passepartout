// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ProfileListView: View {
    @Environment(ProfileObserver.self)
    private var profileObserver

    @Environment(TunnelObserver.self)
    private var tunnelObserver

    @State
    private var search = ""

    var body: some View {
        List {
            profilesSection
        }
        .toolbar {
            newProfileButton
            importURLButton
            importTextButton
        }
        .searchable(text: $search)
        .onChange(of: search) { _, new in
            profileObserver.search(byName: new)
        }
    }
}

private extension ProfileListView {
    var profilesSection: some View {
        ForEach(profileObserver.filteredHeaders) { profile in
            HStack {
                Text(profile.name)
                Spacer()
                // FIXME: ###, could mix tunnel status into ProfileHeader
                Text(tunnelObserver.status(for: profile.id).rawValue)
                if profile.sharingFlags.contains(.tv) {
                    Text("TV")
                } else if profile.sharingFlags.contains(.shared) {
                    Text("SH")
                }
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
                    try await profileObserver.new(fromURL: url)
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
