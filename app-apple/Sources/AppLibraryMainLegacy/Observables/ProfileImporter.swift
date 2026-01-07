// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore

protocol ProfileImporter {
    func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile
}
