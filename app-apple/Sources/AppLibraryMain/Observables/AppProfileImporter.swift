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
        profileObservable: ProfileObservable,
        importer: ProfileImporter? = nil
    ) async throws {
        var withPassphrase: [URL] = []

        for url in urls {
            do {
                try await importURL(
                    url,
                    withPassphrase: nil,
                    profileObservable: profileObservable,
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

    func reImport(url: URL, profileObservable: ProfileObservable, importer: ProfileImporter? = nil) async throws {
        do {
            try await importURL(
                url,
                withPassphrase: currentPassphrase,
                profileObservable: profileObservable,
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
        profileObservable: ProfileObservable,
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
            try await profileObservable.save(ABI.AppProfile(native: profile))
            return
        }
        try await profileObservable.import(.file(url), passphrase: passphrase)
    }
}
