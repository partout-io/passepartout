// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.AppProduct {
    public enum Donations {
        public static let tiny = ABI.AppProduct(donationId: "Tiny")

        public static let small = ABI.AppProduct(donationId: "Small")

        public static let medium = ABI.AppProduct(donationId: "Medium")

        public static let big = ABI.AppProduct(donationId: "Big")

        public static let huge = ABI.AppProduct(donationId: "Huge")

        public static let maxi = ABI.AppProduct(donationId: "Maxi")

        public static let all: [ABI.AppProduct] = [
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
