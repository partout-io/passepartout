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
    public let uploadFailure: PassthroughStream<UniqueID, Error>

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
    func onUpdate(_ event: ABI.WebReceiverEvent) {
        switch event {
        case .start(let website):
            self.website = website
        case .stop:
            website = nil
        case .uploadFailure(let error):
            uploadFailure.send(error)
        default:
            break
        }
    }
}
