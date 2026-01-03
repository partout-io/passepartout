// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@_exported import AppStrings
import CommonLibrary
import Foundation

@MainActor
public protocol AppLibraryConfiguring {
    func configure(with context: AppContext)
}
