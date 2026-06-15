// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

@objc(CDFavoriteServer)
final class CDFavoriteServer: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDFavoriteServer> {
        NSFetchRequest<CDFavoriteServer>(entityName: "CDFavoriteServer")
    }

    @NSManaged var serverId: String?
    @NSManaged var providerPreferences: CDProviderPreferencesV3?
}
