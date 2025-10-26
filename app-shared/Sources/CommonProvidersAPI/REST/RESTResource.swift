// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersCore

extension API.REST {
    public enum Resource {
        case index

        case provider(ProviderID)

        public var path: String {
            switch self {
            case .index:
                "index.json"
            case .provider(let id):
                "providers/\(id.rawValue).js"
            }
        }
    }
}
