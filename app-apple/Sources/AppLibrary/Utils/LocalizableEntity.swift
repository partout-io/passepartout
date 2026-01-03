// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol LocalizableEntity {
    var localizedDescription: String { get }
}

public protocol StyledLocalizableEntity {
    associatedtype Style

    func localizedDescription(style: Style) -> String
}

public protocol StyledOptionalLocalizableEntity {
    associatedtype OptionalStyle

    func localizedDescription(optionalStyle: OptionalStyle) -> String?
}
