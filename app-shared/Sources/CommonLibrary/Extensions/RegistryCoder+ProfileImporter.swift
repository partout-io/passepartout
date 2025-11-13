// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

extension RegistryCoder: ProfileImporter {
    public nonisolated func importedProfile(from input: ProfileImporterInput, passphrase: String?) throws -> Profile {
        let name: String
        let contents: String
        switch input {
        case .contents(let filename, let data):
            name = filename
            contents = data
        case .file(let url):
            var encoding: String.Encoding = .utf8
            // XXX: this may be very inefficient
            contents = try String(contentsOf: url, usedEncoding: &encoding)
            name = url.lastPathComponent
        }

        // Try to decode a full Partout profile first
        do {
            return try profile(from: contents)
        } catch {
            pp_log_g(.App.core, .debug, "Unable to decode profile for import: \(error)")
        }

        // Fall back to parsing a single module
        let importedModule = try module(from: contents, object: passphrase)
        return try profile(withName: name, singleModule: importedModule)
    }
}
