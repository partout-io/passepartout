// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol ExtensionInstaller: Sendable {
    var currentResult: ExtensionInstallerResult { get }

    func load() async throws -> ExtensionInstallerResult

    func install() async throws -> ExtensionInstallerResult
}

public enum ExtensionInstallerResult: Sendable {
    case unknown

    case success

    case needsApproval

    case requiresRestart
}
