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
        try url.absoluteString.withCString { cURL in
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
