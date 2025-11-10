// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI {
    public struct AppProduct: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init?(rawValue: String) {
            if let range = rawValue.range(of: Self.featurePrefix) ?? rawValue.range(of: Self.providerPrefix) ?? rawValue.range(of: Self.donationPrefix) {
                self.rawValue = String(rawValue[range.lowerBound..<rawValue.endIndex])
            } else {
                self.rawValue = rawValue
            }
        }
    }
}

extension UI.AppProduct {
    public static var all: [Self] {
        Features.all + Essentials.all + Complete.all + Donations.all
    }
}

extension UI.AppProduct: CustomDebugStringConvertible {
    public var debugDescription: String {
        rawValue
    }
}
