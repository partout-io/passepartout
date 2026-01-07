// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor
extension ProfileObservable {
    public func removeProfiles(at offsets: IndexSet) async {
        let idsToRemove = filteredHeaders
            .enumerated()
            .filter {
                offsets.contains($0.offset)
            }
            .map(\.element.id)

        await remove(withIds: idsToRemove)
    }
}

@MainActor
extension ProfileManager {
    public func removeProfiles(at offsets: IndexSet) async {
        let idsToRemove = previews
            .enumerated()
            .filter {
                offsets.contains($0.offset)
            }
            .map(\.element.id)

        await remove(withIds: idsToRemove)
    }
}
