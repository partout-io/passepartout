// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

@MainActor @Observable
public final class WebReceiverObservable {
    private let abi: AppABIWebReceiverProtocol
    public private(set) var website: ABI.WebsiteWithPasscode?
    public let uploadFailure: PassthroughStream<String>

    public var isStarted: Bool {
        website != nil
    }

    public init(abi: AppABIWebReceiverProtocol) {
        self.abi = abi
        website = nil
        uploadFailure = PassthroughStream()
    }
}

// MARK: - Actions

extension WebReceiverObservable {
    public func start() throws {
        try abi.start()
    }

    public func stop() {
        abi.stop()
    }
}

// MARK: - State

extension WebReceiverObservable {
    func onUpdate(_ event: ABI.WebReceiverEventProtocol) {
        switch event {
        case let payload as ABI.WebReceiverEvent.Start:
            self.website = payload.website
        case is ABI.WebReceiverEvent.Stop:
            website = nil
        case is ABI.WebReceiverEvent.NewUpload:
            break
        case let payload as ABI.WebReceiverEvent.UploadFailure:
            uploadFailure.send(payload.error)
        default:
            assertionFailure()
        }
    }
}
