// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import XCTest

final class WebReceiverManagerTests: XCTestCase {
}

@MainActor
extension WebReceiverManagerTests {
    func test_givenUploader_whenStart_thenReceivesFiles() async throws {
        let webReceiver = MockWebReceiver(file: ABI.WebFileUpload(name: "name", contents: "contents"))
        let sut = WebReceiverManager(webReceiver: webReceiver)
        let stream = sut.files
        let expReceive = expectation(description: "UploadReceive")
        let expEnd = expectation(description: "UploadEnd")
        Task {
            for await file in stream {
                XCTAssertEqual(file.name, "name")
                XCTAssertEqual(file.contents, "contents")
                expReceive.fulfill()
            }
            expEnd.fulfill()
        }
        try sut.start()
        await fulfillment(of: [expReceive])
        sut.destroy()
        await fulfillment(of: [expEnd])
    }
}

private final class MockWebReceiver: WebReceiver {
    private let file: ABI.WebFileUpload

    init(file: ABI.WebFileUpload) {
        self.file = file
    }

    func start(passcode: String?, onReceive: @escaping (String, String) -> Void) throws -> URL {
        onReceive(file.name, file.contents)
        return URL(fileURLWithPath: "")
    }

    func stop() {
    }
}
