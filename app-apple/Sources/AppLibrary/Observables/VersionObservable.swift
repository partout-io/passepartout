// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class VersionObservable {
    private let abi: AppABIProtocol
    private var latestRelease: ABI.VersionRelease?

    public init(abi: AppABIProtocol) {
        self.abi = abi
        latestRelease = nil
    }

    public func check() async {
        await abi.versionCheckLatestRelease()
    }

    func onUpdate(_ event: ABI.VersionEvent) {
        switch event {
        case .new:
            latestRelease = abi.versionLatestRelease
        }
    }
}
