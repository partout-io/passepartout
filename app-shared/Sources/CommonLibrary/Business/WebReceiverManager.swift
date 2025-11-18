// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

@MainActor
public final class WebReceiverManager: ObservableObject {
    public typealias PasscodeGenerator = () -> String

    private let webReceiver: WebReceiver

    private let passcodeGenerator: PasscodeGenerator?

    private let filesStream: PassthroughStream<ABI.WebFileUpload>

    public var isStarted: Bool {
        website != nil
    }

    public private(set) var website: ABI.WebsiteWithPasscode? {
        willSet {
            objectWillChange.send()
        }
    }

    public var files: AsyncStream<ABI.WebFileUpload> {
        filesStream.subscribe()
    }

    public init(
        webReceiver: WebReceiver,
        passcodeGenerator: PasscodeGenerator? = nil
    ) {
        self.webReceiver = webReceiver
        self.passcodeGenerator = passcodeGenerator
        filesStream = PassthroughStream()
    }

    public func start() throws {
        let passcode = passcodeGenerator?()
        do {
            let url = try webReceiver.start(passcode: passcode) { [weak self] in
                self?.filesStream.send(ABI.WebFileUpload(name: $0, contents: $1))
            }
            website = ABI.WebsiteWithPasscode(url: url, passcode: passcode)
        } catch let error as WebReceiverError {
            throw ABI.AppError.webReceiver(error)
        }
    }

    public func renewPasscode() {
        stop()
        try? start()
    }

    public func stop() {
        webReceiver.stop()
        website = nil
    }

    public func destroy() {
        stop()
        filesStream.finish()
    }
}
