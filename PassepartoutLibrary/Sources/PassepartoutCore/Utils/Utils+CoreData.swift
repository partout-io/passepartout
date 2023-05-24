//
//  Utils+CoreData.swift
//  Passepartout
//
//  Created by Davide De Rosa on 3/16/22.
//  Copyright (c) 2023 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CoreData
import Foundation

extension Utils {
    public static func randomizeFetchResults<T>(_ request: NSFetchRequest<T>, in context: NSManagedObjectContext) throws {
        let count = try context.count(for: request)
        if count > 0 {
            request.fetchOffset = Int.random(in: 0..<count)
            request.fetchLimit = 1
        }
    }
}
