// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class WebReceiverObservable {
    private let webReceiverManager: WebReceiverManager

    public init(webReceiverManager: WebReceiverManager) {
        self.webReceiverManager = webReceiverManager
    }
}

// MARK: - Actions

extension WebReceiverObservable {
    public func start() throws {
        try webReceiverManager.start()
    }

    public func stop() {
        webReceiverManager.stop()
    }

    public func renewPasscode() {
        webReceiverManager.renewPasscode()
    }
}

// MARK: - State

extension WebReceiverObservable {
    public var isStarted: Bool {
        webReceiverManager.isStarted
    }

    public var website: ABI.WebsiteWithPasscode? {
        webReceiverManager.website
    }

    public var files: AsyncStream<ABI.WebFileUpload> {
        webReceiverManager.files
    }
}
