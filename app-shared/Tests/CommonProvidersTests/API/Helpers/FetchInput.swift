// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProviders
import MiniFoundation

struct FetchInput {
    let cache: ProviderCache?

    let presetsCount: Int

    let serversCount: Int

    let isCached: Bool

    var hijacked = true
}

extension ProviderID {
    func hijacker(forFetchURL urlString: String) -> (Int, Data) {
        guard let url = Bundle.module.url(forResource: "Resources/\(rawValue)/fetch", withExtension: "json") else {
            fatalError("Unable to find fetch.json")
        }
        do {
            let data = try Data(contentsOf: url)
            return (200, data)
        } catch {
            fatalError("Unable to read JSON contents: \(error)")
        }
    }
}
