// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.AppProfile {
    public enum Status: Int, Codable, Sendable {
        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    public struct Info: Identifiable, Hashable, Codable, Sendable {
        public let id: ABI.AppIdentifier
        public let status: Status
        public let onDemand: Bool

        public init(id: ABI.AppIdentifier, status: Status, onDemand: Bool) {
            self.id = id
            self.status = status
            self.onDemand = onDemand
        }
    }
}
