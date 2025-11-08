// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CloudKit
import Foundation

extension Utils {
    private static let cloudKitZone = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone")

    public static func eraseCloudKitStore(fromContainerWithId containerId: String) async throws {
        let container = CKContainer(identifier: containerId)
        let db = container.privateCloudDatabase
        try await db.deleteRecordZone(withID: Self.cloudKitZone)
    }
}
