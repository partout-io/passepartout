// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

#if !PSP_CROSS
extension WebReceiverManager: ObservableObject {}
#endif

@MainActor
public final class WebReceiverManager {
    public typealias PasscodeGenerator = () -> String

    private let webReceiver: WebReceiver

    private let passcodeGenerator: PasscodeGenerator?

    public var isStarted: Bool {
        website != nil
    }

    public private(set) var website: ABI.WebsiteWithPasscode? {
        willSet {
#if !PSP_CROSS
            objectWillChange.send()
#endif
        }
        didSet {
            if let website {
                didChange.send(.start(website: website))
            } else {
                didChange.send(.stop)
            }
        }
    }

    public let didChange: PassthroughStream<UniqueID, ABI.WebReceiverEvent>

    public init(
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
                self?.didChange.send(.newUpload(ABI.WebFileUpload(name: $0, contents: $1)))
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
    public convenience init() {
        self.init(webReceiver: DummyWebReceiver(url: URL(fileURLWithPath: "")))
    }
}
