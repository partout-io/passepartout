// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI
import AppABI_C
import Foundation
import Observation

@MainActor @Observable
final class ProfileObserver {
    private(set) var headers: [ProfileHeaderUI]

    init() {
        headers = []
        refresh()
    }

    func refresh() {
        headers = abi.profileGetHeaders()
    }

    @discardableResult
    func new() async throws -> ProfileHeaderUI {
        try await abi.profileNew()
    }

    @discardableResult
    func new(fromURL url: URL) async throws -> ProfileHeaderUI {
        // FIXME: ###
//        let text = try String(contentsOf: url)
        let text = "{\"id\":\"imported-url\",\"name\":\"imported url\"}"
        return try await abi.profileImportText(text)
    }

    @discardableResult
    func new(fromText text: String) async throws -> ProfileHeaderUI {
        // FIXME: ###
        let text = "{\"id\":\"imported-text\",\"name\":\"imported text\"}"
        return try await abi.profileImportText(text)
    }

    func onUpdate() {
        print("onUpdate() called")
        refresh()
    }
}
