// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonProvidersCore
#endif

extension ProviderID {
    public static let hideme = Self(rawValue: "hideme")

    public static let ivpn = Self(rawValue: "ivpn")

    public static let mullvad = Self(rawValue: "mullvad")

    public static let nordvpn = Self(rawValue: "nordvpn")

    public static let oeck = Self(rawValue: "oeck")

    public static let pia = Self(rawValue: "pia")

    public static let surfshark = Self(rawValue: "surfshark")

    public static let torguard = Self(rawValue: "torguard")

    public static let tunnelbear = Self(rawValue: "tunnelbear")

    public static let vyprvpn = Self(rawValue: "vyprvpn")

    public static let windscribe = Self(rawValue: "windscribe")
}
