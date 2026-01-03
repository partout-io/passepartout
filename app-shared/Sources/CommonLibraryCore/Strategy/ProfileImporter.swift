// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol ProfileImporter {
    func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile
}
