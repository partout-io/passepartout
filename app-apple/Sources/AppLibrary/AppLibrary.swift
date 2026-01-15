// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@_exported import AppStrings
import CommonLibrary
@_exported import Partout

@MainActor
public protocol AppLibraryConfiguring {
    func configure(with context: AppContext)
}
