// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor @Observable
final class AppProfileImporter {
    var isPresentingPassphrase = false

    var currentPassphrase = ""

    private(set) var urlsRequiringPassphrase: [URL] = []

    var nextURL: URL? {
        urlsRequiringPassphrase.first
    }

    func tryImport(
        urls: [URL],
        profileManager: ProfileManager,
        registry: Registry,
        importer: ProfileImporter? = nil
    ) async throws {
        var withPassphrase: [URL] = []

        for url in urls {
            do {
                try await importURL(
                    url,
                    withPassphrase: nil,
                    profileManager: profileManager,
                    registry: registry,
                    importer: importer
                )
            } catch {
                if let error = error as? PartoutError, error.code == .OpenVPN.passphraseRequired {
                    withPassphrase.append(url)
                    continue
                }
                pp_log_g(.App.core, .fault, "Unable to import URL: \(error)")
                throw error
            }
        }

        urlsRequiringPassphrase = withPassphrase
        if !urlsRequiringPassphrase.isEmpty {
            scheduleNextImport()
        }
    }

    func reImport(url: URL, profileManager: ProfileManager, registry: Registry, importer: ProfileImporter? = nil) async throws {
        do {
            try await importURL(
                url,
                withPassphrase: currentPassphrase,
                profileManager: profileManager,
                registry: registry,
                importer: importer
            )
            urlsRequiringPassphrase.removeFirst()
            scheduleNextImport()
        } catch {
            scheduleNextImport()
            throw error
        }
    }

    func cancelImport() {
        urlsRequiringPassphrase.removeFirst()
        scheduleNextImport()
    }
}

private extension AppProfileImporter {
    func scheduleNextImport() {
        guard !urlsRequiringPassphrase.isEmpty else {
            return
        }
        Task {
            // XXX: re-present same alert after artificial delay
            try? await Task.sleep(for: .milliseconds(500))
            currentPassphrase = ""
            isPresentingPassphrase = true
        }
    }

    func importURL(
        _ url: URL,
        withPassphrase passphrase: String?,
        profileManager: ProfileManager,
        registry: Registry,
        importer: ProfileImporter?
    ) async throws {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        if let importer {
            let profile = try importer.importedProfile(from: .file(url), passphrase: passphrase)
            try await profileManager.save(profile)
            return
        }
        try await profileManager.legacyImport(
            .file(url),
            registry: registry,
            passphrase: passphrase
        )
    }
}
