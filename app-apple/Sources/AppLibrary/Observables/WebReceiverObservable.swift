// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

@MainActor @Observable
public final class WebReceiverObservable {
    private let webReceiverManager: WebReceiverManager
    public private(set) var website: ABI.WebsiteWithPasscode?
    public let uploadFailure: PassthroughStream<String>

    public var isStarted: Bool {
        website != nil
    }

    public init(webReceiverManager: WebReceiverManager) {
        self.webReceiverManager = webReceiverManager
        website = nil
        uploadFailure = PassthroughStream()
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
}

// MARK: - State

extension WebReceiverObservable {
    func onUpdate(_ event: ABI.WebReceiverEvent) {
        switch event {
        case .start(let payload):
            website = payload.website
        case .stop:
            website = nil
        case .newUpload:
            break
        case .uploadFailure(let payload):
            uploadFailure.send(payload.error)
        }
    }
}
