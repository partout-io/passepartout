//
//  OnboardingStep.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/25/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
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

import Foundation

// order matters
public enum OnboardingStep: String, RawRepresentable, CaseIterable {
    case doneV2

    case migrateV3

    case community

    case doneV3

    case migrateV3_2_2

    case doneV3_2_2
}

extension OnboardingStep {
    public static var last: Self {
        allCases.last!
    }
}

extension OnboardingStep: Comparable {
    var order: Int {
        OnboardingStep.allCases.firstIndex(of: self) ?? .max
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.order < rhs.order
    }
}
