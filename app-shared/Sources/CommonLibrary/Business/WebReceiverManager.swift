// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

@MainActor
public final class WebReceiverManager: ObservableObject {
    public struct Website: Sendable {
        public let url: URL

        public let passcode: String?
    }

    public struct File: Sendable {
        public let name: String

        public let contents: String
    }

    public typealias PasscodeGenerator = () -> String

    private let webReceiver: WebReceiver

    private let passcodeGenerator: PasscodeGenerator?

    private let filesStream: PassthroughStream<File>

    public var isStarted: Bool {
        website != nil
    }

    @Published
    public private(set) var website: Website?

    public var files: AsyncStream<File> {
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
                self?.filesStream.send(File(name: $0, contents: $1))
            }
            website = Website(url: url, passcode: passcode)
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
