// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Abstract representation of a scripting engine with injected functions and execution capabilities.
public protocol ScriptingEngine {
    func inject(_ name: String, object: Any)

    func execute<O>(_ script: String, after preScript: String?, returning: O.Type) async throws -> O where O: Decodable
}
