// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class VersionObservable {
    private let versionChecker: VersionChecker
    public private(set) var latestRelease: ABI.VersionRelease?

    public init(versionChecker: VersionChecker) {
        self.versionChecker = versionChecker
        latestRelease = nil
    }

    public func fetchChangelog(of build: String) async throws -> [ABI.ChangelogEntry] {
        try await versionChecker.fetchChangelog(of: build)
    }

    func onUpdate(_ event: ABI.VersionEvent) {
        switch event {
        case .new(let payload):
            latestRelease = payload.release
        }
    }
}
