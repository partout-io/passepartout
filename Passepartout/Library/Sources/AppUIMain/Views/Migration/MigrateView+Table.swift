//
//  MigrateView+Table.swift
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

extension MigrateView {
    struct TableView: View {
        let profiles: [MigratableProfile]

        @Binding
        var excluded: Set<UUID>

        let statuses: [UUID: MigrationStatus]

        var body: some View {
            Table(profiles) {
                TableColumn(Strings.Global.name, value: \.name)
                TableColumn(Strings.Global.lastUpdate, value: \.timestamp)
                TableColumn("") { profile in
                    if let status = statuses[profile.id] {
                        imageName(forStatus: status)
                            .map {
                                ThemeImage($0)
                            }
                    } else {
                        Toggle("", isOn: isOnBinding(for: profile.id))
                            .labelsHidden()
                    }
                }
            }
        }

        func isOnBinding(for profileId: UUID) -> Binding<Bool> {
            Binding {
                !excluded.contains(profileId)
            } set: {
                if $0 {
                    excluded.remove(profileId)
                } else {
                    excluded.insert(profileId)
                }
            }
        }

        func imageName(forStatus status: MigrationStatus) -> Theme.ImageName? {
            switch status {
            case .excluded:
                return nil

            case .pending:
                return .progress

            case .success:
                return .marked

            case .failure:
                return .failure
            }
        }
    }
}

private extension MigratableProfile {
    var timestamp: String {
        lastUpdate?.localizedDescription(style: .timestamp) ?? ""
    }
}
