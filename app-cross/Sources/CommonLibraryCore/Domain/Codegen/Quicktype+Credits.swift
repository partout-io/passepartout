// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// FIXME: #1723, Precompute in Quicktype decoding
extension ABI.Credits.License {
    public var licenseFoundationURL: URL {
        URL(forceString: licenseURL, description: "licenseURL")
    }
}
