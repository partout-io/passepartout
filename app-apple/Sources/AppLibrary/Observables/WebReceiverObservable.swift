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
    public let uploads: PassthroughStream<UniqueID, ABI.WebFileUpload>

    public var isStarted: Bool {
        website != nil
    }

    public init(abi: AppABIWebReceiverProtocol) {
        self.abi = abi
        website = nil
        uploads = PassthroughStream()
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

    public func refresh() {
        abi.refresh()
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
        case .newUpload(let upload):
            uploads.send(upload)
        }
    }
}
