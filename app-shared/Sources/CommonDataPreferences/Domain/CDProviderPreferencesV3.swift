// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData
import Foundation

@objc(CDProviderPreferencesV3)
final class CDProviderPreferencesV3: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDProviderPreferencesV3> {
        NSFetchRequest<CDProviderPreferencesV3>(entityName: "CDProviderPreferencesV3")
    }

    @NSManaged var providerId: String?
    @NSManaged var lastUpdate: Date?
    @NSManaged var favoriteServerIds: Data?
    @NSManaged var favoriteServers: Set<CDFavoriteServer>?
}
