// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@BusinessActor
public final class WebReceiverManager {
    public typealias PasscodeGenerator = @Sendable () -> String

    private let webReceiver: WebReceiver

    private let passcodeGenerator: PasscodeGenerator?

    public var isStarted: Bool {
        website != nil
    }

    public private(set) var website: ABI.WebsiteWithPasscode? {
        didSet {
            if let website {
                didChange.send(ABI.WebReceiverEvent.Start(
                    website: website
                ))
            } else {
                didChange.send(ABI.WebReceiverEvent.Stop())
            }
        }
    }

    public nonisolated let didChange: PassthroughStream<ABI.WebReceiverEventProtocol>

    public nonisolated init(
        webReceiver: WebReceiver,
        passcodeGenerator: PasscodeGenerator? = nil
    ) {
        self.webReceiver = webReceiver
        self.passcodeGenerator = passcodeGenerator
        didChange = PassthroughStream()
    }

    public func start() throws {
        let passcode = passcodeGenerator?()
        do {
            let url = try webReceiver.start(passcode: passcode) { [weak self] in
                self?.didChange.send(ABI.WebReceiverEvent.NewUpload(
                    upload: ABI.WebFileUpload(name: $0, contents: $1)
                ))
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
        didChange.finish()
    }
}

extension WebReceiverManager {
    public convenience nonisolated init() {
        self.init(webReceiver: DummyWebReceiver(url: URL(fileURLWithPath: "")))
    }
}
