// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum ProfileImporterInput {
        case contents(filename: String, data: String)

        case file(URL)
    }
}
