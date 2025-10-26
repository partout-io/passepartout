// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if canImport(Combine)

import Combine
@testable import CommonProvidersAPI
import CommonProvidersCore
import Foundation
import Testing

@MainActor
struct APIManagerTests {
    @Test
    func givenAPI_whenFetchIndex_thenReturnsProviders() async throws {
        let sut = Self.manager()
        var subscriptions: Set<AnyCancellable> = []

        let exp = Expectation()
        sut
            .$providers
            .dropFirst(2) // initial, observeObjects
            .sink { _ in
                Task {
                    await exp.fulfill()
                }
            }
            .store(in: &subscriptions)

        try await sut.fetchIndex()
        try await exp.fulfillment(timeout: 200)

        #expect(sut.providers.map(\.description) == ["bar1", "bar2", "bar3"])
    }

    @Test
    func givenIndex_whenFilterBySupport_thenReturnsSupportedProviders() async throws {
        let sut = Self.manager()
        var subscriptions: Set<AnyCancellable> = []

        let exp = Expectation()
        sut
            .$providers
            .dropFirst(2)
            .sink { _ in
                Task {
                    await exp.fulfill()
                }
            }
            .store(in: &subscriptions)

        try await sut.fetchIndex()
        try await exp.fulfillment(timeout: 200)

        let supporting = sut.providers.filter {
            $0.supports(MockModule.self)
        }
        #expect(supporting.map(\.description) == ["bar2"])
    }
}

// MARK: -

@MainActor
private extension APIManagerTests {
    static func manager() -> APIManager {
        APIManager(.global, from: [MockAPI()], repository: MockRepository())
    }
}

#endif
