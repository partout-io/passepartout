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
                    let path = NSTemporaryDirectory().appending("imported-file.txt")
                    let url = URL(filePath: path)
                    let text = "{\"id\":\"e790a205-af25-4a8b-af89-0711245ac96c\",\"name\":\"imported url\",\"modules\":[],\"activeModulesIds\":[]}"
                    try text.write(to: url, atomically: true, encoding: .utf8)
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
                    // FIXME: ###
                    let text = "{\"id\":\"e80c727f-e52c-4fed-8f59-e77d3d313a88\",\"name\":\"imported text\",\"modules\":[],\"activeModulesIds\":[]}"
                    try await profileObserver.new(fromText: text)
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
