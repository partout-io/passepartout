// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

protocol OpenAPIEncodable {
    associatedtype OpenAPIType
    var toProto: OpenAPIType { get }
}

protocol OpenAPIDecodable {
    associatedtype NativeType
    var fromProto: NativeType { get }
}

// MARK: - Encodable

extension ABI.AppProfileHeader: OpenAPIEncodable {
    var toProto: OpenAPIAppProfileHeader {
        OpenAPIAppProfileHeader(
            id: id.uuidString,
            name: name,
            moduleTypes: moduleTypes.compactMap(\.toProto),
            primaryModuleType: primaryModuleType?.toProto,
            secondaryModuleTypes: secondaryModuleTypes?.compactMap(\.toProto) ?? [],
            providerInfo: providerInfo?.toProto,
            fingerprint: fingerprint,
            sharingFlags: sharingFlags,
            requiredFeatures: Array(requiredFeatures)
        )
    }
}

extension ABI.AppTunnelInfo: OpenAPIEncodable {
    var toProto: OpenAPIAppTunnelInfo {
        OpenAPIAppTunnelInfo(
            id: id.uuidString,
            status: status,
            onDemand: onDemand
        )
    }
}

extension ABI.OriginalPurchase: OpenAPIEncodable {
    var toProto: OpenAPIOriginalPurchase {
        OpenAPIOriginalPurchase(
            buildNumber: buildNumber,
            purchaseDate: purchaseDate.formatted(.iso8601)
        )
    }
}

extension ABI.ProviderInfo: OpenAPIEncodable {
    var toProto: OpenAPIProviderInfo {
        OpenAPIProviderInfo(
            providerId: providerId.rawValue,
            countryCode: countryCode
        )
    }
}

extension ABI.VersionRelease: OpenAPIEncodable {
    var toProto: OpenAPIVersionRelease {
        OpenAPIVersionRelease(
            version: version,
            url: url.absoluteString
        )
    }
}

extension ModuleType: OpenAPIEncodable {
    var toProto: OpenAPIModuleType? {
        OpenAPIModuleType(rawValue: rawValue)
    }
}

// MARK: - Decodable

extension OpenAPILocalLoggerOptions: OpenAPIDecodable {
    public var maxDebugLogLevel: DebugLog.Level {
        DebugLog.Level(rawValue: maxLevel.rawValue) ?? .info
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
