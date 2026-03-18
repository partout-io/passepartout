// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.Credits.License {
    public var licenseFoundationURL: URL {
        URL(forceString: licenseURL, description: "licenseURL")
    }
}
