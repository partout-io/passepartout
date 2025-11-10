// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension UI.AppProduct {
    public enum Donations {
        public static let tiny = UI.AppProduct(donationId: "Tiny")

        public static let small = UI.AppProduct(donationId: "Small")

        public static let medium = UI.AppProduct(donationId: "Medium")

        public static let big = UI.AppProduct(donationId: "Big")

        public static let huge = UI.AppProduct(donationId: "Huge")

        public static let maxi = UI.AppProduct(donationId: "Maxi")

        public static let all: [UI.AppProduct] = [
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
