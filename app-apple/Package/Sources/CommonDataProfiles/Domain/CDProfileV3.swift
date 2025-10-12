// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CoreData
import Foundation

@objc(CDProfileV3)
final class CDProfileV3: NSManagedObject {
    @nonobjc static func fetchRequest() -> NSFetchRequest<CDProfileV3> {
        NSFetchRequest<CDProfileV3>(entityName: "CDProfileV3")
    }

    @NSManaged var uuid: UUID?
    @NSManaged var name: String?
    @NSManaged var encodedJSON: String?
    @NSManaged var isAvailableForTV: NSNumber?
    @NSManaged var lastUpdate: Date?
    @NSManaged var fingerprint: UUID?

    @available(*, deprecated, renamed: "encodedJSON")
    @NSManaged var encoded: String?
}
