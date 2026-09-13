// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Imports a ``Module`` from a text content.
public protocol ModuleImporter: Sendable {
    func module(fromContents contents: String, object: Any?) throws -> Module
}

extension ModuleImporter {
    public func module(fromContents contents: String) throws -> Module {
        try module(fromContents: contents, object: nil)
    }

    public func module(fromURL url: URL, object: Any? = nil) throws -> Module {
        var encoding: String.Encoding = .utf8
        let contents = try String(contentsOf: url, usedEncoding: &encoding)
        return try module(fromContents: contents, object: object)
    }

    public func module(fromPath path: String, object: Any? = nil) throws -> Module {
        var encoding: String.Encoding = .utf8
        let contents = try String(contentsOfFile: path, usedEncoding: &encoding)
        return try module(fromContents: contents, object: object)
    }
}
