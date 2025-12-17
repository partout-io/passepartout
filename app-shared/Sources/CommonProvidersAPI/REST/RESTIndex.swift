// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonProvidersCore
#endif
import Partout

extension API.REST {
    public struct Index: Decodable {
        public struct Provider: Decodable {
            public let id: ProviderID

            public let description: String

            public let metadata: [String: JSON]
        }

        public let providers: [Provider]
    }
}
