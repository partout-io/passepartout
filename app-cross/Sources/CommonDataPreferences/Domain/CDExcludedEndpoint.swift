// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

@objc(CDExcludedEndpoint)
final class CDExcludedEndpoint: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDExcludedEndpoint> {
        NSFetchRequest<CDExcludedEndpoint>(entityName: "CDExcludedEndpoint")
    }

    @NSManaged var endpoint: String?
    @NSManaged var modulePreferences: CDModulePreferencesV3?
}
