// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonProviders
import Foundation
import Partout
import Testing

struct HideMeProviderTests: APITestSuite {
    init() {
        setUpLogging()
    }

    let providerId: ProviderID = .hideme

    @Test(arguments: [
        FetchInput(
            cache: nil,
            presetsCount: 1,
            serversCount: 2,
            isCached: false
        )
//        FetchInput(
//            cache: nil,
//            presetsCount: 1,
//            serversCount: 99,
//            isCached: false,
//            hijacked: false
//        ),
//        FetchInput(
//            cache: ProviderCache(lastUpdate: nil, tag: "\\\"0103dd09364f346ff8a8c2b9d5285b5d\\\""),
//            presetsCount: 1,
//            serversCount: 99,
//            isCached: true,
//            hijacked: false
//        )
    ])
    func whenFetchInfrastructure_thenReturns(input: FetchInput) async throws {
        let sut = try newAPIMapper(input.hijacked ? { @Sendable in
            providerId.hijacker(forFetchURL: $1)
        } : nil)
        do {
            let module = try ProviderModule(emptyWithProviderId: providerId)
            let infra = try await sut.infrastructure(for: module, cache: input.cache)
            #expect(infra.presets.count == input.presetsCount)
            #expect(infra.servers.count == input.serversCount)

            try infra.presets.forEach {
                let template = try JSONDecoder().decode(OpenVPNProviderTemplate.self, from: $0.templateData)
                switch $0.presetId {
                case "default":
                    #expect(template.configuration.cipher == .aes256cbc)
                    #expect(template.endpoints.map(\.rawValue) == [
                        "UDP:3000", "UDP:3010", "UDP:3020", "UDP:3030", "UDP:3040", "UDP:3050",
                        "UDP:3060", "UDP:3070", "UDP:3080", "UDP:3090", "UDP:3100",
                        "TCP:3000", "TCP:3010", "TCP:3020", "TCP:3030", "TCP:3040", "TCP:3050",
                        "TCP:3060", "TCP:3070", "TCP:3080", "TCP:3090", "TCP:3100"
                    ])
                default:
                    break
                }
            }
        } catch let error as PartoutError {
            if input.isCached {
                #expect(error.code == .cached)
            } else {
                #expect(Bool(false), "Failed: \(error)")
            }
        } catch {
            #expect(Bool(false), "Failed: \(error)")
        }
    }
}
