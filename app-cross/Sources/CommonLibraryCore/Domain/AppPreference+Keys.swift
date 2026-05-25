//// SPDX-FileCopyrightText: 2026 Davide De Rosa
////
//// SPDX-License-Identifier: GPL-3.0
//
//import Partout
//
//extension ABI {
//    public struct AppPreferenceKey: Hashable, Codable, Identifiable, Sendable {
//        public let id: String
//        public let preference: AppPreference
//        public let valueType: AppPreferenceValueType
//        public let defaultValue: JSON
//        public let isOptional: Bool
//
//        public init(
//            preference: AppPreference,
//            valueType: AppPreferenceValueType,
//            defaultValue: JSON,
//            isOptional: Bool = false
//        ) {
//            id = preference.key
//            self.preference = preference
//            self.valueType = valueType
//            self.defaultValue = defaultValue
//            self.isOptional = isOptional
//        }
//    }
//
//    public enum AppPreferenceValueType: String, Hashable, Codable, Sendable {
//        case bool
//        case data
//        case double
//        case string
//        case uuid
//    }
//}
//
//extension ABI.AppPreferenceKey {
//    public static let deviceId = Self(
//        preference: .deviceId,
//        valueType: .string,
//        defaultValue: .null,
//        isOptional: true
//    )
//
//    public static let configFlags = Self(
//        preference: .configFlags,
//        valueType: .data,
//        defaultValue: .null,
//        isOptional: true
//    )
//
//    public static let dnsFallsBack = Self(
//        preference: .dnsFallsBack,
//        valueType: .bool,
//        defaultValue: .bool(true)
//    )
//
//    public static let extensiveLogging = Self(
//        preference: .extensiveLogging,
//        valueType: .bool,
//        defaultValue: .bool(false)
//    )
//
//    public static let lastCheckedVersionDate = Self(
//        preference: .lastCheckedVersionDate,
//        valueType: .double,
//        defaultValue: .null,
//        isOptional: true
//    )
//
//    public static let lastCheckedVersion = Self(
//        preference: .lastCheckedVersion,
//        valueType: .string,
//        defaultValue: .null,
//        isOptional: true
//    )
//
//    public static let lastUsedProfileId = Self(
//        preference: .lastUsedProfileId,
//        valueType: .uuid,
//        defaultValue: .null,
//        isOptional: true
//    )
//
//    public static let logsPrivateData = Self(
//        preference: .logsPrivateData,
//        valueType: .bool,
//        defaultValue: .bool(false)
//    )
//
//    public static let newProfileEncoding = Self(
//        preference: .newProfileEncoding,
//        valueType: .bool,
//        defaultValue: .bool(false)
//    )
//
//    public static let relaxedVerification = Self(
//        preference: .relaxedVerification,
//        valueType: .bool,
//        defaultValue: .bool(false)
//    )
//
//    public static let skipsPurchases = Self(
//        preference: .skipsPurchases,
//        valueType: .bool,
//        defaultValue: .bool(false)
//    )
//
//    public static let experimental = Self(
//        preference: .experimental,
//        valueType: .data,
//        defaultValue: .null,
//        isOptional: true
//    )
//
//    public static let all: [Self] = ABI.AppPreference.allCases.map(\.metadata)
//
//    public static let byId: [String: Self] = Dictionary(
//        uniqueKeysWithValues: all.map {
//            ($0.id, $0)
//        }
//    )
//}
//
//extension ABI.AppPreference {
//    public var metadata: ABI.AppPreferenceKey {
//        switch self {
//        case .deviceId:
//            return .deviceId
//        case .configFlags:
//            return .configFlags
//        case .dnsFallsBack:
//            return .dnsFallsBack
//        case .extensiveLogging:
//            return .extensiveLogging
//        case .lastCheckedVersionDate:
//            return .lastCheckedVersionDate
//        case .lastCheckedVersion:
//            return .lastCheckedVersion
//        case .lastUsedProfileId:
//            return .lastUsedProfileId
//        case .logsPrivateData:
//            return .logsPrivateData
//        case .newProfileEncoding:
//            return .newProfileEncoding
//        case .relaxedVerification:
//            return .relaxedVerification
//        case .skipsPurchases:
//            return .skipsPurchases
//        case .experimental:
//            return .experimental
//        }
//    }
//}
//
//extension ABI.AppPreference: CaseIterable, Codable {
//    public static let allCases: [Self] = [
//        .deviceId,
//        .configFlags,
//        .dnsFallsBack,
//        .extensiveLogging,
//        .lastCheckedVersionDate,
//        .lastCheckedVersion,
//        .lastUsedProfileId,
//        .logsPrivateData,
//        .newProfileEncoding,
//        .relaxedVerification,
//        .skipsPurchases,
//        .experimental
//    ]
//
//    public init(from decoder: any Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        let rawValue = try container.decode(String.self)
//        guard let preference = Self(rawValue: rawValue) else {
//            throw DecodingError.dataCorruptedError(
//                in: container,
//                debugDescription: "Invalid app preference: \(rawValue)"
//            )
//        }
//        self = preference
//    }
//
//    public func encode(to encoder: any Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(rawValue)
//    }
//}
