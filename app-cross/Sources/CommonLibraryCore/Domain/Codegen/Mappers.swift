// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

protocol QuicktypeEncodable {
    associatedtype QuicktypeType
    var toProto: QuicktypeType { get }
}

protocol QuicktypeDecodable {
    associatedtype NativeType
    var fromProto: NativeType { get }
}

// MARK: - Encodable

extension ABI.AppProfileHeader: QuicktypeEncodable {
    var toProto: QuicktypeAppProfileHeader {
        QuicktypeAppProfileHeader(
            fingerprint: fingerprint,
            id: id.uuidString,
            moduleTypes: moduleTypes.compactMap(\.toProto),
            name: name,
            primaryModuleType: primaryModuleType?.toProto,
            providerInfo: providerInfo?.toProto,
            requiredFeatures: Array(requiredFeatures),
            secondaryModuleTypes: secondaryModuleTypes?.compactMap(\.toProto) ?? [],
            sharingFlags: sharingFlags
        )
    }
}

extension ABI.AppTunnelInfo: QuicktypeEncodable {
    var toProto: QuicktypeAppTunnelInfo {
        QuicktypeAppTunnelInfo(
            id: id.uuidString,
            onDemand: onDemand,
            status: status
        )
    }
}

extension ABI.OriginalPurchase: QuicktypeEncodable {
    var toProto: QuicktypeOriginalPurchase {
        QuicktypeOriginalPurchase(
            buildNumber: buildNumber,
            purchaseDate: purchaseDate.formatted(.iso8601)
        )
    }
}

extension ABI.ProviderInfo: QuicktypeEncodable {
    var toProto: QuicktypeProviderInfo {
        QuicktypeProviderInfo(
            countryCode: countryCode,
            providerID: providerId.rawValue
        )
    }
}

extension ABI.VersionRelease: QuicktypeEncodable {
    var toProto: QuicktypeVersionRelease {
        QuicktypeVersionRelease(url: url.absoluteString, version: version)
    }
}

extension ModuleType: QuicktypeEncodable {
    var toProto: QuicktypeModuleType? {
        QuicktypeModuleType(rawValue: rawValue)
    }
}

// MARK: - Decodable

extension QuicktypeAppConstantsLogOptions: QuicktypeDecodable {
    public var maxDebugLogLevel: DebugLog.Level {
        DebugLog.Level(rawValue: maxLevel) ?? .info
    }

    public var fromProto: LocalLogger.Options {
        LocalLogger.Options(
            maxLevel: maxDebugLogLevel,
            maxSize: UInt64(maxSize),
            maxBufferedLines: maxBufferedLines,
            maxAge: maxAge
        )
    }
}

// MARK: - Helpers

extension URL {
    // XXX: Quicktype is unable to leverage the "uri" format
    // to parse URL directly from JSON.
    init(forceString string: String, description: String) {
        guard let url = URL(string: string) else {
            fatalError("Malformed '\(description)' URL")
        }
        self = url
    }
}
