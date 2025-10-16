// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension AppProduct {
    public enum Donations {
        public static let tiny = AppProduct(donationId: "Tiny")

        public static let small = AppProduct(donationId: "Small")

        public static let medium = AppProduct(donationId: "Medium")

        public static let big = AppProduct(donationId: "Big")

        public static let huge = AppProduct(donationId: "Huge")

        public static let maxi = AppProduct(donationId: "Maxi")

        public static let all: [AppProduct] = [
            .Donations.maxi,
            .Donations.huge,
            .Donations.big,
            .Donations.medium,
            .Donations.small,
            .Donations.tiny
        ]
    }

    static let donationPrefix = "donations."

    private init(donationId: String) {
        self.init(rawValue: "\(Self.donationPrefix)\(donationId)")!
    }

    public var isDonation: Bool {
        rawValue.hasPrefix(Self.donationPrefix)
    }
}
