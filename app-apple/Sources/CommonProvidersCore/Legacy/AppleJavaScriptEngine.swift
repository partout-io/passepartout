// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@preconcurrency import JavaScriptCore
import Partout

/// A scripting engine based on the JavaScriptCore framework. This class is not actor-safe.
public final class AppleJavaScriptEngine: ScriptingEngine, @unchecked Sendable {
    private let engine: JSContext

    public init() {
        engine = JSContext()
        engine.exceptionHandler = { _, exception in
            pp_log_g(.core, .error, "AppleJavaScriptEngine: \(exception?.toString() ?? "unknown error")")
        }
    }

    public func inject(_ name: String, object: Any) {
        engine.setObject(object, forKeyedSubscript: name as NSString)
    }

    public func execute<O>(_ script: String, after preScript: String?, returning: O.Type) async throws -> O where O: Decodable & Sendable {
        try await Task.detached {
            if let preScript {
                _ = self.engine.evaluateScript(preScript)
            }
            guard let value = self.engine.evaluateScript(script) else {
                throw PartoutError(.parsing)
            }
            guard !value.isUndefined else {
                throw PartoutError(.scriptException)
            }
            guard let data = value.toString().data(using: .utf8) else {
                throw PartoutError(.parsing, value)
            }
            return try JSONDecoder.shared().decode(O.self, from: data)
        }.value
    }
}
