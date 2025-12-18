// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class WebReceiverObservable {
    private let abi: ABIProtocol
    public let uploads: PassthroughStream<UniqueID, ABI.WebFileUpload>

    public init(abi: ABIProtocol) {
        self.abi = abi
        uploads = PassthroughStream()
    }
}

// MARK: - Actions

extension WebReceiverObservable {
    public func start() throws {
        try abi.webReceiverStart()
    }

    public func stop() {
        abi.webReceiverStop()
    }

    public func refresh() {
        abi.webReceiverRefresh()
    }
}

// MARK: - State

extension WebReceiverObservable {
    public var isStarted: Bool {
        abi.webReceiverIsStarted
    }

    public var website: ABI.WebsiteWithPasscode? {
        abi.webReceiverWebsite
    }

    func onUpdate(_ event: ABI.WebReceiverEvent) {
        switch event {
        case .newUpload(let upload):
            uploads.send(upload)
        }
    }
}
