// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct WebReceiverManagerTests {
}

@MainActor
extension WebReceiverManagerTests {
    @Test
    func givenUploader_whenStart_thenReceivesFiles() async throws {
        let webReceiver = MockWebReceiver(file: ABI.WebFileUpload(name: "name", contents: "contents"))
        let sut = WebReceiverManager(webReceiver: webReceiver)
        let stream = sut.files
        let expReceive = Expectation()
        let expEnd = Expectation()
        Task {
            for await file in stream {
                #expect(file.name == "name")
                #expect(file.contents == "contents")
                await expReceive.fulfill()
            }
            await expEnd.fulfill()
        }
        try sut.start()
        try await expReceive.fulfillment(timeout: 100)
        sut.destroy()
        try await expEnd.fulfillment(timeout: 100)
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
