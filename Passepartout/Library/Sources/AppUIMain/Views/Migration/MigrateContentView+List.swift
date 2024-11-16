//
//  MigrateContentView+List.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/13/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import SwiftUI

extension MigrateContentView {
    struct ListView: View {
        let step: MigrateViewStep

        let profiles: [MigratableProfile]

        @Binding
        var statuses: [UUID: MigrationStatus]

        @Binding
        var isEditing: Bool

        let onDelete: ([MigratableProfile]) -> Void

        let performButton: () -> PerformButton

        @State
        private var selection: Set<UUID> = []

        var body: some View {
            List {
                Section {
                    Text(Strings.Views.Migrate.Sections.Main.header)
                }
                Section {
                    ForEach(profiles, id: \.id) {
                        if isEditing {
                            EditableRowView(profile: $0, selection: $selection)
                        } else {
                            ControlView(
                                step: step,
                                profile: $0,
                                isIncluded: isIncludedBinding(for: $0.id),
                                status: statusBinding(for: $0.id)
                            )
                        }
                    }
                } header: {
                    editButton
                }
                .disabled(!step.canSelect)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    performButton()
                        .disabled(isEditing)
                }
            }
        }
    }
}

private extension MigrateContentView.ListView {
    var editButton: some View {
        HStack {
            if isEditing {
                Button(Strings.Global.cancel) {
                    isEditing = false
                }
            }
            Spacer()
            Button(isEditing ? Strings.Global.delete : Strings.Global.edit, role: isEditing ? .destructive : nil) {
                if isEditing {
                    if !selection.isEmpty {
                        onDelete(profiles.filter {
                            selection.contains($0.id)
                        })
                        // disable isEditing after confirmation
                    } else {
                        isEditing = false
                    }
                } else {
                    selection = []
                    isEditing = true
                }
            }
            .disabled(isEditing && selection.isEmpty)
        }
        .frame(height: 30)
    }
}

private extension MigrateContentView.ListView {
    func isIncludedBinding(for profileId: UUID) -> Binding<Bool> {
        Binding {
            statuses[profileId] != .excluded
        } set: {
            if $0 {
                statuses.removeValue(forKey: profileId)
            } else {
                statuses[profileId] = .excluded
            }
        }
    }

    func statusBinding(for profileId: UUID) -> Binding<MigrationStatus?> {
        Binding {
            statuses[profileId]
        } set: {
            if let newValue = $0 {
                statuses[profileId] = newValue
            } else {
                statuses.removeValue(forKey: profileId)
            }
        }
    }
}

private extension MigrateContentView.ListView {
    struct EditableRowView: View {
        let profile: MigratableProfile

        @Binding
        var selection: Set<UUID>

        var body: some View {
            Button {
                if selection.contains(profile.id) {
                    selection.remove(profile.id)
                } else {
                    selection.insert(profile.id)
                }
            } label: {
                HStack {
                    CardView(profile: profile)
                    Spacer()
                    ThemeImage(selection.contains(profile.id) ? .selectionOn : .selectionOff)
                }
            }
        }
    }

    struct ControlView: View {
        let step: MigrateViewStep

        let profile: MigratableProfile

        @Binding
        var isIncluded: Bool

        @Binding
        var status: MigrationStatus?

        var body: some View {
            switch step {
            case .initial, .fetching, .fetched:
                buttonView

            default:
                rowView
            }
        }

        var buttonView: some View {
            Button {
                if status == .excluded {
                    status = nil
                } else {
                    status = .excluded
                }
            } label: {
                rowView
            }
        }

        var rowView: some View {
            HStack {
                CardView(profile: profile)
                Spacer()
                StatusView(isIncluded: status != .excluded, status: status)
            }
            .foregroundStyle(status.style)
        }
    }
}

private extension MigrateContentView.ListView {
    struct CardView: View {
        let profile: MigratableProfile

        var body: some View {
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)

                profile.lastUpdate.map {
                    Text($0.localizedDescription(style: .timestamp))
                        .font(.subheadline)
                }
            }
        }
    }
}

private extension MigrateContentView.ListView {
    struct StatusView: View {
        let isIncluded: Bool

        let status: MigrationStatus?

        var body: some View {
            if let status {
                icon(forStatus: status)
            } else if isIncluded {
                ThemeImage(.marked)
            }
        }

        @ViewBuilder
        func icon(forStatus status: MigrationStatus) -> some View {
            switch status {
            case .excluded:
                Text("--")

            case .pending:
                ProgressView()

            case .migrated, .imported:
                ThemeImage(.marked)

            case .failed:
                ThemeImage(.failure)
            }
        }
    }
}
