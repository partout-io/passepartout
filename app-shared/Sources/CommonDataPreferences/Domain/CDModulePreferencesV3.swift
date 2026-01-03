// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

@objc(CDModulePreferencesV3)
final class CDModulePreferencesV3: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDModulePreferencesV3> {
        NSFetchRequest<CDModulePreferencesV3>(entityName: "CDModulePreferencesV3")
    }

    @NSManaged var moduleId: UUID?
    @NSManaged var lastUpdate: Date?
    @NSManaged var excludedEndpoints: Set<CDExcludedEndpoint>?
}
