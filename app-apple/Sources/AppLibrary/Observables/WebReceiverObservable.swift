// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class WebReceiverObservable {
    private let abi: AppABIWebReceiverProtocol
    public let uploads: PassthroughStream<UniqueID, ABI.WebFileUpload>

    public init(abi: AppABIWebReceiverProtocol) {
        self.abi = abi
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
    public var isStarted: Bool {
        abi.isStarted
    }

    public var website: ABI.WebsiteWithPasscode? {
        abi.website
    }

    func onUpdate(_ event: ABI.WebReceiverEvent) {
        switch event {
        case .newUpload(let upload):
            uploads.send(upload)
        }
    }
}
