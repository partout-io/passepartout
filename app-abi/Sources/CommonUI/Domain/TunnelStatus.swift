// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public enum TunnelStatus: String, DTO {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }
}
