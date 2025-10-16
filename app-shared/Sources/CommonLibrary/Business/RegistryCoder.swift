// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor
public final class RegistryCoder: ObservableObject, Sendable {
    private let registry: Registry

    public init(registry: Registry) {
        self.registry = registry
    }

    public nonisolated func string(from profile: Profile) throws -> String {
        try registry.encodedProfile(profile)
    }

    public nonisolated func profile(from string: String) throws -> Profile {
        try registry.decodedProfile(from: string)
    }

    public nonisolated func module(from string: String, object: Any?) throws -> Module {
        try registry.module(fromContents: string, object: object)
    }
}
