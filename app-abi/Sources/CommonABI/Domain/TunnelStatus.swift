// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum TunnelStatus: String, Codable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
}
