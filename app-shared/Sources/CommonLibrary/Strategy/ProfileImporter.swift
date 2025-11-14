// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public enum ProfileImporterInput {
    case contents(filename: String, data: String)

    case file(URL)
}

public protocol ProfileImporter {
    func importedProfile(from input: ProfileImporterInput, passphrase: String?) throws -> Profile
}
