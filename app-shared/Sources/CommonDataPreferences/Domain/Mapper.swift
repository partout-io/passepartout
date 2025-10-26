// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CoreData
import Foundation

struct DomainMapper {
}

struct CoreDataMapper {
    let context: NSManagedObjectContext

    func cdExcludedEndpoint(from endpoint: ExtendedEndpoint) -> CDExcludedEndpoint {
        let cdEndpoint = CDExcludedEndpoint(context: context)
        cdEndpoint.endpoint = endpoint.rawValue
        return cdEndpoint
    }

    func cdFavoriteServer(from serverId: String) -> CDFavoriteServer {
        let cdFavorite = CDFavoriteServer(context: context)
        cdFavorite.serverId = serverId
        return cdFavorite
    }
}
