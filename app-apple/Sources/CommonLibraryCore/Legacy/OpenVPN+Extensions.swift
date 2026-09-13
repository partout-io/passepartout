// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension OpenVPNModule: ConnectionModule, SerializableModule {
    public var preferredExtension: String {
        "ovpn"
    }
}
