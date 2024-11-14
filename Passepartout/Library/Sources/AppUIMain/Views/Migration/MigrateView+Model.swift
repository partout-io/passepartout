//
//  MigrateView+Model.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/14/24.
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
import Foundation
import PassepartoutKit

extension MigrateView {
    struct Model: Equatable {
        enum Step: Equatable {
            case initial

            case fetching

            case fetched

            case migrating

            case migrated([Profile])

            case importing

            case imported
        }

        var step: Step = .initial

        var profiles: [MigratableProfile] = []

        var statuses: [UUID: MigrationStatus] = [:]

        mutating func excludeFailed() {
            statuses.forEach {
                if statuses[$0.key] == .failed {
                    statuses[$0.key] = .excluded
                }
            }
        }
    }
}

extension MigrateView.Model {

    // XXX: filtering out the excluded rows may crash on macOS, because ThemeImage is
    // momentarily removed from the hierarchy and loses access to the Theme
    // .environmentObject(). this is certainly a SwiftUI bug
    //
    // https://github.com/passepartoutvpn/passepartout/pull/867#issuecomment-2476293204
    //
    var visibleProfiles: [MigratableProfile] {
        profiles
//            .filter {
//                switch step {
//                case .initial, .fetching, .fetched:
//                    return true
//
//                case .migrating, .migrated, .importing, .imported:
//                    return statuses[$0.id] != .excluded
//                }
//            }
            .sorted {
                $0.name.lowercased() < $1.name.lowercased()
            }
    }

    var selection: Set<UUID> {
        Set(profiles
            .filter {
                statuses[$0.id] != .excluded
            }
            .map(\.id))
    }
}
