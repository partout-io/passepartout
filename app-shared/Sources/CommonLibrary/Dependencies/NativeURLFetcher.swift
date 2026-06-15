// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary_C
import Partout

final class NativeURLFetcher: URLFetcher {
    private nonisolated(unsafe) let ctx: UnsafeMutableRawPointer
    private let callback: psp_request_callback
    private let timeout: TimeInterval

    init(ctx: UnsafeMutableRawPointer, callback: psp_request_callback, timeout: TimeInterval) {
        self.ctx = ctx
        self.callback = callback
        self.timeout = timeout
    }

    func data(for url: URL, cached: Bool) async throws -> Data {
        let request = Request(
            urlString: url.absoluteString,
            cached: cached,
            ctx: ctx,
            callback: callback,
            timeout: timeout
        )
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    continuation.resume(returning: try request.perform())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private struct Request: @unchecked Sendable {
    let urlString: String
    let cached: Bool
    let ctx: UnsafeMutableRawPointer
    let callback: psp_request_callback
    let timeout: TimeInterval

    func perform() throws -> Data {
        try urlString.withCString { cURL in
            var bytes: UnsafeMutablePointer<UInt8>?
            var count = 0
            let code = callback(
                ctx,
                cURL,
                cached,
                timeout,
                &bytes,
                &count
            )
            defer {
                psp_free(bytes)
            }
            guard code == PSPCompletionCodeOK else {
                throw ABI.AppError.urlRequestFailed(reason: nil)
            }
            guard let bytes else {
                return Data()
            }
            return Data(bytes: bytes, count: count)
        }
    }
}
