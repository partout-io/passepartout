// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

@MainActor @Observable
public final class VersionObservable {
    private let versionChecker: VersionChecker

    public init(versionChecker: VersionChecker) {
        self.versionChecker = versionChecker
    }
}
