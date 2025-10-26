// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData
import Foundation

@objc(CDProviderServerV3)
final class CDProviderServerV3: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDProviderServerV3> {
        NSFetchRequest<CDProviderServerV3>(entityName: "CDProviderServerV3")
    }

    @NSManaged var serverId: String?
    @NSManaged var hostname: String?
    @NSManaged var ipAddresses: Data?
    @NSManaged var providerId: String?
    @NSManaged var countryCode: String?
    @NSManaged var supportedModuleTypes: String?
    @NSManaged var supportedPresetIds: String?
    @NSManaged var categoryName: String?
    @NSManaged var localizedCountry: String?
    @NSManaged var otherCountryCodes: String?
    @NSManaged var area: String?
}
