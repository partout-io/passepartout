// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData

@objc(CDProviderPresetV3)
final class CDProviderPresetV3: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDProviderPresetV3> {
        NSFetchRequest<CDProviderPresetV3>(entityName: "CDProviderPresetV3")
    }

    @NSManaged var providerId: String?
    @NSManaged var presetId: String?
    @NSManaged var presetDescription: String?
    @NSManaged var moduleType: String?
    @NSManaged var templateData: Data?
}
