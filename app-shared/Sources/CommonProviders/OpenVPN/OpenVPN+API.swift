// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonProvidersCore
#endif
import Partout

extension OpenVPN {
    public struct ProviderCustomization {
        public struct Credentials {
            public enum Purpose: String {
                case web

                case specific
            }

            public enum Option: String {
                case noPassword
            }

            public let purpose: Purpose

            public let options: Set<Option>?

            public let url: URL?
        }

        public let credentials: Credentials
    }
}

extension OpenVPN.ProviderCustomization {
    public init?(userInfo: JSON?) {
        guard let json = userInfo else {
            assertionFailure("Expected JSON object from PartoutAPI 'metadata.configurations'")
            return nil
        }
        guard let credentials = json.credentials else {
            return nil
        }
        let purpose = credentials.purpose?.stringValue
        let options = Set(credentials.options?.arrayValue?.compactMap {
            $0.stringValue.map {
                Credentials.Option(rawValue: $0)
            } ?? nil
        } ?? [])
        switch purpose {
        case "web":
            self.credentials = .init(purpose: .web, options: options, url: nil)
        case "specific":
            let url = credentials.url?.stringValue.map {
                URL(string: $0)
            }
            self.credentials = .init(purpose: .specific, options: options, url: url ?? nil)
        default:
            self.credentials = .init(purpose: .web, options: options, url: nil)
        }
    }

    public var userInfo: JSON? {
        var credentialsMap: [String: AnyHashable] = [:]
        credentialsMap["purpose"] = credentials.purpose.rawValue
        if let options = credentials.options {
            credentialsMap["options"] = options.map(\.rawValue)
        }
        if let url = credentials.url {
            credentialsMap["url"] = url.absoluteString
        }
        return try? JSON(["credentials": credentialsMap])
    }
}
