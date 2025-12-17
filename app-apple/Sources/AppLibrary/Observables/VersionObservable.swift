// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class VersionObservable {
    private let versionChecker: VersionChecker
    private var latestRelease: ABI.VersionRelease?

    public init(versionChecker: VersionChecker) {
        self.versionChecker = versionChecker
        latestRelease = nil
    }

    func onUpdate(_ event: ABI.VersionEvent) {
        switch event {
        case .new:
            latestRelease = versionChecker.latestRelease
        }
    }
}
