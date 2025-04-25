//
//  ProfileImporter.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/8/24.
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

import CommonLibrary
import CommonUtils
import Foundation

@MainActor
final class ProfileImporter: ObservableObject {

    @Published
    var isPresentingPassphrase = false

    @Published
    var currentPassphrase = ""

    private(set) var urlsRequiringPassphrase: [URL] = []

    var nextURL: URL? {
        urlsRequiringPassphrase.first
    }

    func tryImport(
        urls: [URL],
        profileManager: ProfileManager,
        importer: ModuleImporter
    ) async throws {
        var withPassphrase: [URL] = []

        for url in urls {
            do {
                try await importURL(
                    url,
                    withPassphrase: nil,
                    profileManager: profileManager,
                    importer: importer
                )
            } catch {
                if let error = error as? PartoutError, error.code == .OpenVPN.passphraseRequired {
                    withPassphrase.append(url)
                    continue
                }
                pp_log(.app, .fault, "Unable to import URL: \(error)")
                throw error
            }
        }

        urlsRequiringPassphrase = withPassphrase
        if !urlsRequiringPassphrase.isEmpty {
            scheduleNextImport()
        }
    }

    func reImport(url: URL, profileManager: ProfileManager, importer: ModuleImporter) async throws {
        do {
            try await importURL(
                url,
                withPassphrase: currentPassphrase,
                profileManager: profileManager,
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

private extension ProfileImporter {
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
        importer: ModuleImporter
    ) async throws {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let module = try importer.module(fromURL: url, object: passphrase)
        let onDemandModule = OnDemandModule.Builder().tryBuild()

        var builder = Profile.Builder()
        builder.name = url.lastPathComponent
        builder.modules = [module, onDemandModule]
        builder.activeModulesIds = Set(builder.modules.map(\.id))
        let profile = try builder.tryBuild()

        try await profileManager.save(profile)
    }
}
