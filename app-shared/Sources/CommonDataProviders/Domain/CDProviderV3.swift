// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData
import Foundation

@objc(CDProviderV3)
final class CDProviderV3: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDProviderV3> {
        NSFetchRequest<CDProviderV3>(entityName: "CDProviderV3")
    }

    @NSManaged var providerId: String?
    @NSManaged var fullName: String?
    @NSManaged var supportedModuleTypes: String?
    @NSManaged var encodedMetadata: Data? // [String: Provider.Metadata]
    @NSManaged var cache: Data?
}
