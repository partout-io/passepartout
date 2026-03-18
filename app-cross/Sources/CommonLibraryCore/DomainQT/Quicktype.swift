// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let quicktypeAppFeature = try? JSONDecoder().decode(QuicktypeAppFeature.self, from: jsonData)
//   let quicktypeAppProfileHeader = try? JSONDecoder().decode(QuicktypeAppProfileHeader.self, from: jsonData)
//   let quicktypeAppTunnelInfo = try? JSONDecoder().decode(QuicktypeAppTunnelInfo.self, from: jsonData)
//   let quicktypeAppTunnelStatus = try? JSONDecoder().decode(QuicktypeAppTunnelStatus.self, from: jsonData)
//   let quicktypeConfigEventRefresh = try? JSONDecoder().decode(QuicktypeConfigEventRefresh.self, from: jsonData)
//   let quicktypeConfigFlag = try? JSONDecoder().decode(QuicktypeConfigFlag.self, from: jsonData)
//   let quicktypeIAPEventEligibleFeatures = try? JSONDecoder().decode(QuicktypeIAPEventEligibleFeatures.self, from: jsonData)
//   let quicktypeIAPEventLoadReceipt = try? JSONDecoder().decode(QuicktypeIAPEventLoadReceipt.self, from: jsonData)
//   let quicktypeIAPEventNewReceipt = try? JSONDecoder().decode(QuicktypeIAPEventNewReceipt.self, from: jsonData)
//   let quicktypeIAPEventStatus = try? JSONDecoder().decode(QuicktypeIAPEventStatus.self, from: jsonData)
//   let quicktypeModuleType = try? JSONDecoder().decode(QuicktypeModuleType.self, from: jsonData)
//   let quicktypeOriginalPurchase = try? JSONDecoder().decode(QuicktypeOriginalPurchase.self, from: jsonData)
//   let quicktypeProfileEventChangeRemoteImporting = try? JSONDecoder().decode(QuicktypeProfileEventChangeRemoteImporting.self, from: jsonData)
//   let quicktypeProfileEventLocalProfiles = try? JSONDecoder().decode(QuicktypeProfileEventLocalProfiles.self, from: jsonData)
//   let quicktypeProfileEventReady = try? JSONDecoder().decode(QuicktypeProfileEventReady.self, from: jsonData)
//   let quicktypeProfileEventRefresh = try? JSONDecoder().decode(QuicktypeProfileEventRefresh.self, from: jsonData)
//   let quicktypeProfileEventSave = try? JSONDecoder().decode(QuicktypeProfileEventSave.self, from: jsonData)
//   let quicktypeProfileEventStartRemoteImport = try? JSONDecoder().decode(QuicktypeProfileEventStartRemoteImport.self, from: jsonData)
//   let quicktypeProfileEventStopRemoteImport = try? JSONDecoder().decode(QuicktypeProfileEventStopRemoteImport.self, from: jsonData)
//   let quicktypeProfileSharingFlag = try? JSONDecoder().decode(QuicktypeProfileSharingFlag.self, from: jsonData)
//   let quicktypeProviderInfo = try? JSONDecoder().decode(QuicktypeProviderInfo.self, from: jsonData)
//   let quicktypeSemanticVersion = try? JSONDecoder().decode(QuicktypeSemanticVersion.self, from: jsonData)
//   let quicktypeTimestamp = try? JSONDecoder().decode(QuicktypeTimestamp.self, from: jsonData)
//   let quicktypeTunnelEventDataCount = try? JSONDecoder().decode(QuicktypeTunnelEventDataCount.self, from: jsonData)
//   let quicktypeTunnelEventRefresh = try? JSONDecoder().decode(QuicktypeTunnelEventRefresh.self, from: jsonData)
//   let quicktypeVersionEventNew = try? JSONDecoder().decode(QuicktypeVersionEventNew.self, from: jsonData)
//   let quicktypeVersionRelease = try? JSONDecoder().decode(QuicktypeVersionRelease.self, from: jsonData)
//   let quicktypeWebFileUpload = try? JSONDecoder().decode(QuicktypeWebFileUpload.self, from: jsonData)
//   let quicktypeWebReceiverEventNewUpload = try? JSONDecoder().decode(QuicktypeWebReceiverEventNewUpload.self, from: jsonData)
//   let quicktypeWebReceiverEventStart = try? JSONDecoder().decode(QuicktypeWebReceiverEventStart.self, from: jsonData)
//   let quicktypeWebReceiverEventStop = try? JSONDecoder().decode(QuicktypeWebReceiverEventStop.self, from: jsonData)
//   let quicktypeWebReceiverEventUploadFailure = try? JSONDecoder().decode(QuicktypeWebReceiverEventUploadFailure.self, from: jsonData)
//   let quicktypeWebsiteWithPasscode = try? JSONDecoder().decode(QuicktypeWebsiteWithPasscode.self, from: jsonData)

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

import Partout

// MARK: - QuicktypeConfigEventRefresh
public struct QuicktypeConfigEventRefresh: Codable, Equatable, Sendable {
    public let data: [String: JSON]
    public let flags: [QuicktypeConfigFlag]

    public init(data: [String: JSON], flags: [QuicktypeConfigFlag]) {
        self.data = data
        self.flags = flags
    }
}

public enum QuicktypeData: Codable, Sendable {
    case anythingArray([JSONAny])
    case bool(Bool)
    case double(Double)
    case integer(Int)
    case string(String)
    case unionMap([String: QuicktypeDatum])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([JSONAny].self) {
            self = .anythingArray(x)
            return
        }
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode([String: QuicktypeDatum].self) {
            self = .unionMap(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(QuicktypeData.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for QuicktypeData"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .anythingArray(let x):
            try container.encode(x)
        case .bool(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .unionMap(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

public enum QuicktypeDatum: Codable, Sendable {
    case anythingArray([JSONAny])
    case anythingMap([String: JSONAny])
    case bool(Bool)
    case double(Double)
    case integer(Int)
    case string(String)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) {
            self = .bool(x)
            return
        }
        if let x = try? container.decode(Int.self) {
            self = .integer(x)
            return
        }
        if let x = try? container.decode([JSONAny].self) {
            self = .anythingArray(x)
            return
        }
        if let x = try? container.decode(Double.self) {
            self = .double(x)
            return
        }
        if let x = try? container.decode([String: JSONAny].self) {
            self = .anythingMap(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if container.decodeNil() {
            self = .null
            return
        }
        throw DecodingError.typeMismatch(QuicktypeDatum.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for QuicktypeDatum"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .anythingArray(let x):
            try container.encode(x)
        case .anythingMap(let x):
            try container.encode(x)
        case .bool(let x):
            try container.encode(x)
        case .double(let x):
            try container.encode(x)
        case .integer(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        case .null:
            try container.encodeNil()
        }
    }
}

public enum QuicktypeConfigFlag: String, Codable, Equatable, Sendable {
    case allowsRelaxedVerification = "allowsRelaxedVerification"
    case appNotWorking = "appNotWorking"
    case neSocketTCP = "neSocketTCP"
    case neSocketUDP = "neSocketUDP"
    case unknown = "unknown"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventEligibleFeatures
public struct QuicktypeIAPEventEligibleFeatures: Codable, Equatable, Sendable {
    public let features: [QuicktypeAppFeature]
    public let forComplete, forFeedback: Bool

    public init(features: [QuicktypeAppFeature], forComplete: Bool, forFeedback: Bool) {
        self.features = features
        self.forComplete = forComplete
        self.forFeedback = forFeedback
    }
}

public enum QuicktypeAppFeature: String, Codable, Equatable, Sendable {
    case appleTV = "appleTV"
    case dns = "dns"
    case httpProxy = "httpProxy"
    case onDemand = "onDemand"
    case otp = "otp"
    case providers = "providers"
    case routing = "routing"
    case sharing = "sharing"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventLoadReceipt
public struct QuicktypeIAPEventLoadReceipt: Codable, Equatable, Sendable {
    public let isLoading: Bool

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventNewReceipt
public struct QuicktypeIAPEventNewReceipt: Codable, Equatable, Sendable {
    public let isBeta: Bool
    public let originalPurchase: QuicktypeOriginalPurchase?
    public let products: [String]

    public init(isBeta: Bool, originalPurchase: QuicktypeOriginalPurchase?, products: [String]) {
        self.isBeta = isBeta
        self.originalPurchase = originalPurchase
        self.products = products
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeOriginalPurchase
public struct QuicktypeOriginalPurchase: Codable, Equatable, Sendable {
    public let buildNumber: Int
    public let purchaseDate: String

    public init(buildNumber: Int, purchaseDate: String) {
        self.buildNumber = buildNumber
        self.purchaseDate = purchaseDate
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeIAPEventStatus
public struct QuicktypeIAPEventStatus: Codable, Equatable, Sendable {
    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventChangeRemoteImporting
public struct QuicktypeProfileEventChangeRemoteImporting: Codable, Equatable, Sendable {
    public let isImporting: Bool

    public init(isImporting: Bool) {
        self.isImporting = isImporting
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventLocalProfiles
public struct QuicktypeProfileEventLocalProfiles: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventReady
public struct QuicktypeProfileEventReady: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventRefresh
public struct QuicktypeProfileEventRefresh: Codable, Equatable, Sendable {
    public let headers: [String: QuicktypeAppProfileHeader]

    public init(headers: [String: QuicktypeAppProfileHeader]) {
        self.headers = headers
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppProfileHeader
public struct QuicktypeAppProfileHeader: Codable, Equatable, Sendable {
    public let fingerprint, id: String
    public let moduleTypes: [QuicktypeModuleType]
    public let name: String
    public let primaryModuleType: QuicktypeModuleType?
    public let providerInfo: QuicktypeProviderInfo?
    public let requiredFeatures: [QuicktypeAppFeature]
    public let secondaryModuleTypes: [QuicktypeModuleType]
    public let sharingFlags: [QuicktypeProfileSharingFlag]

    public init(fingerprint: String, id: String, moduleTypes: [QuicktypeModuleType], name: String, primaryModuleType: QuicktypeModuleType?, providerInfo: QuicktypeProviderInfo?, requiredFeatures: [QuicktypeAppFeature], secondaryModuleTypes: [QuicktypeModuleType], sharingFlags: [QuicktypeProfileSharingFlag]) {
        self.fingerprint = fingerprint
        self.id = id
        self.moduleTypes = moduleTypes
        self.name = name
        self.primaryModuleType = primaryModuleType
        self.providerInfo = providerInfo
        self.requiredFeatures = requiredFeatures
        self.secondaryModuleTypes = secondaryModuleTypes
        self.sharingFlags = sharingFlags
    }
}

public enum QuicktypeModuleType: String, Codable, Equatable, Sendable {
    case dns = "DNS"
    case httpProxy = "HTTPProxy"
    case ip = "IP"
    case onDemand = "OnDemand"
    case openVPN = "OpenVPN"
    case wireGuard = "WireGuard"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProviderInfo
public struct QuicktypeProviderInfo: Codable, Equatable, Sendable {
    public let countryCode: String?
    public let providerID: String

    public enum CodingKeys: String, CodingKey {
        case countryCode
        case providerID = "providerId"
    }

    public init(countryCode: String?, providerID: String) {
        self.countryCode = countryCode
        self.providerID = providerID
    }
}

public enum QuicktypeProfileSharingFlag: String, Codable, Equatable, Sendable {
    case shared = "shared"
    case tv = "tv"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventSave
public struct QuicktypeProfileEventSave: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventStartRemoteImport
public struct QuicktypeProfileEventStartRemoteImport: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeProfileEventStopRemoteImport
public struct QuicktypeProfileEventStopRemoteImport: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeTunnelEventDataCount
public struct QuicktypeTunnelEventDataCount: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeTunnelEventRefresh
public struct QuicktypeTunnelEventRefresh: Codable, Equatable, Sendable {
    public let active: [String: QuicktypeAppTunnelInfo]

    public init(active: [String: QuicktypeAppTunnelInfo]) {
        self.active = active
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeAppTunnelInfo
public struct QuicktypeAppTunnelInfo: Codable, Equatable, Sendable {
    public let id: String
    public let onDemand: Bool
    public let status: QuicktypeAppTunnelStatus

    public init(id: String, onDemand: Bool, status: QuicktypeAppTunnelStatus) {
        self.id = id
        self.onDemand = onDemand
        self.status = status
    }
}

public enum QuicktypeAppTunnelStatus: String, Codable, Equatable, Sendable {
    case connected = "connected"
    case connecting = "connecting"
    case disconnected = "disconnected"
    case disconnecting = "disconnecting"
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeVersionEventNew
public struct QuicktypeVersionEventNew: Codable, Equatable, Sendable {
    public let release: QuicktypeVersionRelease

    public init(release: QuicktypeVersionRelease) {
        self.release = release
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeVersionRelease
public struct QuicktypeVersionRelease: Codable, Equatable, Sendable {
    public let url: String
    public let version: QuicktypeSemanticVersion

    public init(url: String, version: QuicktypeSemanticVersion) {
        self.url = url
        self.version = version
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeSemanticVersion
public struct QuicktypeSemanticVersion: Codable, Equatable, Sendable {
    public let major, minor, patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventNewUpload
public struct QuicktypeWebReceiverEventNewUpload: Codable, Equatable, Sendable {
    public let file: QuicktypeWebFileUpload

    public init(file: QuicktypeWebFileUpload) {
        self.file = file
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebFileUpload
public struct QuicktypeWebFileUpload: Codable, Equatable, Sendable {
    public let contents, name: String

    public init(contents: String, name: String) {
        self.contents = contents
        self.name = name
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventStart
public struct QuicktypeWebReceiverEventStart: Codable, Equatable, Sendable {
    public let website: QuicktypeWebsiteWithPasscode

    public init(website: QuicktypeWebsiteWithPasscode) {
        self.website = website
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebsiteWithPasscode
public struct QuicktypeWebsiteWithPasscode: Codable, Equatable, Sendable {
    public let passcode: String?
    public let url: String

    public init(passcode: String?, url: String) {
        self.passcode = passcode
        self.url = url
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventStop
public struct QuicktypeWebReceiverEventStop: Codable, Equatable, Sendable {

    public init() {
    }
}

//
// Hashable or Equatable:
// The compiler will not be able to synthesize the implementation of Hashable or Equatable
// for types that require the use of JSONAny, nor will the implementation of Hashable be
// synthesized for types that have collections (such as arrays or dictionaries).

// MARK: - QuicktypeWebReceiverEventUploadFailure
public struct QuicktypeWebReceiverEventUploadFailure: Codable, Equatable, Sendable {
    public let error: String

    public init(error: String) {
        self.error = error
    }
}

public typealias QuicktypeTimestamp = String

// MARK: - Encode/decode helpers

public class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
    }

    public var hashValue: Int {
            return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
    }

    public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
    }
}

final class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
            return nil
    }

    required init?(stringValue: String) {
            key = stringValue
    }

    var intValue: Int? {
            return nil
    }

    var stringValue: String {
            return key
    }
}

public class JSONAny: Codable, @unchecked Sendable {

    public let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
            return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
            return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if container.decodeNil() {
                    return JSONNull()
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if let value = try? container.decodeNil() {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer() {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
            if let value = try? container.decode(Bool.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Int64.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(String.self, forKey: key) {
                    return value
            }
            if let value = try? container.decodeNil(forKey: key) {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer(forKey: key) {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
            var arr: [Any] = []
            while !container.isAtEnd {
                    let value = try decode(from: &container)
                    arr.append(value)
            }
            return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
            var dict = [String: Any]()
            for key in container.allKeys {
                    let value = try decode(from: &container, forKey: key)
                    dict[key.stringValue] = value
            }
            return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
            for value in array {
                    if let value = value as? Bool {
                            try container.encode(value)
                    } else if let value = value as? Int64 {
                            try container.encode(value)
                    } else if let value = value as? Double {
                            try container.encode(value)
                    } else if let value = value as? String {
                            try container.encode(value)
                    } else if value is JSONNull {
                            try container.encodeNil()
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer()
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
            for (key, value) in dictionary {
                    let key = JSONCodingKey(stringValue: key)!
                    if let value = value as? Bool {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Int64 {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Double {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? String {
                            try container.encode(value, forKey: key)
                    } else if value is JSONNull {
                            try container.encodeNil(forKey: key)
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer(forKey: key)
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
            if let value = value as? Bool {
                    try container.encode(value)
            } else if let value = value as? Int64 {
                    try container.encode(value)
            } else if let value = value as? Double {
                    try container.encode(value)
            } else if let value = value as? String {
                    try container.encode(value)
            } else if value is JSONNull {
                    try container.encodeNil()
            } else {
                    throw encodingError(forValue: value, codingPath: container.codingPath)
            }
    }

    public required init(from decoder: Decoder) throws {
            if var arrayContainer = try? decoder.unkeyedContainer() {
                    self.value = try JSONAny.decodeArray(from: &arrayContainer)
            } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
                    self.value = try JSONAny.decodeDictionary(from: &container)
            } else {
                    let container = try decoder.singleValueContainer()
                    self.value = try JSONAny.decode(from: container)
            }
    }

    public func encode(to encoder: Encoder) throws {
            if let arr = self.value as? [Any] {
                    var container = encoder.unkeyedContainer()
                    try JSONAny.encode(to: &container, array: arr)
            } else if let dict = self.value as? [String: Any] {
                    var container = encoder.container(keyedBy: JSONCodingKey.self)
                    try JSONAny.encode(to: &container, dictionary: dict)
            } else {
                    var container = encoder.singleValueContainer()
                    try JSONAny.encode(to: &container, value: self.value)
            }
    }
}

extension QuicktypeAppFeature: CaseIterable {}
extension QuicktypeConfigFlag: CaseIterable {}
