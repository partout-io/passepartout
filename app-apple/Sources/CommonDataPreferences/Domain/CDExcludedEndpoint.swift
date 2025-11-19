// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData
import Foundation

@objc(CDExcludedEndpoint)
final class CDExcludedEndpoint: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDExcludedEndpoint> {
        NSFetchRequest<CDExcludedEndpoint>(entityName: "CDExcludedEndpoint")
    }

    @NSManaged var endpoint: String?
    @NSManaged var modulePreferences: CDModulePreferencesV3?
}
