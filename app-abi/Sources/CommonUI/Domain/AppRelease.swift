// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public struct AppRelease: Sendable {
        private let name: String

        public let build: Int

        public init(_ name: String, build: Int) {
            self.name = name
            self.build = build
        }
    }
}
