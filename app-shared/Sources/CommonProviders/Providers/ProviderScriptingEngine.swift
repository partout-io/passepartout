// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

protocol ProviderScriptingEngine: ScriptingEngine {
    func inject(from engine: ProviderScriptingAPI)
}

// inject ProviderEngine functions into the ScriptingEngine
// available on the current platform
extension ProviderScriptingAPI {
    func newScriptingEngine(_ ctx: PartoutLoggerContext) -> ScriptingEngine {
        let engine: ProviderScriptingEngine
#if canImport(Darwin)
        engine = AppleJavaScriptEngine(ctx)
#else
        fatalError("Unsupported platform")
#endif
        engine.inject(from: self)
        return engine
    }
}
