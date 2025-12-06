// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ProfileAttributes {
    public struct ModulePreferences {
        private enum Key: String {
            case excludedEndpoints
        }

        private(set) var userInfo: JSON

        init(userInfo: JSON?) {
            self.userInfo = userInfo ?? [:]
        }

        public var excludedEndpoints: Set<ExtendedEndpoint> {
            get {
                Set(rawExcludedEndpoints.compactMap(ExtendedEndpoint.init(rawValue:)))
            }
            set {
                rawExcludedEndpoints = newValue.map(\.rawValue)
            }
        }

        public func isExcludedEndpoint(_ endpoint: ExtendedEndpoint) -> Bool {
            rawExcludedEndpoints.contains(endpoint.rawValue)
        }

        public mutating func addExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
            rawExcludedEndpoints.append(endpoint.rawValue)
        }

        public mutating func removeExcludedEndpoint(_ endpoint: ExtendedEndpoint) {
            let rawValue = endpoint.rawValue
            rawExcludedEndpoints.removeAll {
                $0 == rawValue
            }
        }
    }
}

extension ProfileAttributes.ModulePreferences {
    var rawExcludedEndpoints: [String] {
        get {
            userInfo[Key.excludedEndpoints.rawValue]?
                .arrayValue?
                .compactMap(\.stringValue) ?? []
        }
        set {
            userInfo[Key.excludedEndpoints.rawValue] = .array(newValue.map {
                .string($0)
            })
        }
    }
}
