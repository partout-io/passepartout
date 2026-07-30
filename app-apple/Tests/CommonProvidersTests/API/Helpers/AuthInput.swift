// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

struct AuthInput {
    let accessToken: String?

    let tokenExpiryTimestamp: String?

    let privateKey: String

    let publicKey: String

    let existingPeerId: String?

    var peerAddresses: [String]?

    var hijacked = true
}
