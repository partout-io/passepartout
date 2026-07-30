// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

@MainActor @Observable
public final class WebReceiverObservable {
    private enum Backend {
        case abi(AppABIWebReceiverProtocol)
        case manager(WebReceiverManager)
    }

    private let backend: Backend
    public private(set) var website: ABI.WebsiteWithPasscode?
    public let uploadFailure: PassthroughStream<String>

    public var isStarted: Bool {
        website != nil
    }

    public init(abi: AppABIWebReceiverProtocol) {
        backend = .abi(abi)
        website = nil
        uploadFailure = PassthroughStream()
    }

    public init(webReceiverManager: WebReceiverManager) {
        backend = .manager(webReceiverManager)
        website = nil
        uploadFailure = PassthroughStream()
    }
}

// MARK: - Actions

extension WebReceiverObservable {
    public func start() throws {
        switch backend {
        case .abi(let abi):
            try abi.start()
        case .manager(let webReceiverManager):
            try webReceiverManager.start()
        }
    }

    public func stop() {
        switch backend {
        case .abi(let abi):
            abi.stop()
        case .manager(let webReceiverManager):
            webReceiverManager.stop()
        }
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
