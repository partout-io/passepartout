//
//  StandardOpenVPNParser.swift
//  PassepartoutKit
//
//  Created by Davide De Rosa on 9/5/18.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of PassepartoutKit.
//
//  PassepartoutKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  PassepartoutKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with PassepartoutKit.  If not, see <http://www.gnu.org/licenses/>.
//

internal import CPassepartoutOpenVPNOpenSSL
import Foundation
import PassepartoutKit

/// Provides methods to parse a ``OpenVPN/Configuration`` from an .ovpn configuration file.
///
/// The parser recognizes most of the relevant options and normally you should not face big limitations.
///
/// ### Unsupported options:
///
/// - UDP fragmentation, i.e. `--fragment`
/// - Compression via `--compress` other than empty or `lzo`
/// - Connecting via proxy
/// - External file references (inline `<block>` only)
/// - Static key encryption (non-TLS)
/// - `<connection>` blocks
/// - `net_gateway` literals in routes
///
/// ### Ignored options:
///
/// - Some MTU overrides
///     - `--link-mtu` and variants
///     - `--mssfix`
/// - Static client-side routes
///
/// Many other flags are ignored too but it's normally not an issue.
///
public final class StandardOpenVPNParser {

    // XXX: parsing is very optimistic

    /// Result of the parser.
    public struct Result {

        /// Original URL of the configuration file, if parsed from an URL.
        public let url: URL?

        /// The overall parsed ``OpenVPN/Configuration``.
        public let configuration: OpenVPN.Configuration

        /// Holds an optional `ConfigurationError` that didn't block the parser, but it would be worth taking care of.
        public let warning: StandardOpenVPNParserError?
    }

    /// The decrypter for private keys.
    private let decrypter: PrivateKeyDecrypter?

    public init(decrypter: PrivateKeyDecrypter? = nil) {
        self.decrypter = decrypter ?? OSSLTLSBox()
    }

    /// Parses a configuration from a .ovpn file.
    ///
    /// - Parameters:
    ///   - url: The URL of the configuration file.
    ///   - passphrase: The optional passphrase for encrypted data.
    /// - Returns: The ``Result`` outcome of the parsing.
    /// - Throws: If the configuration file is wrong or incomplete.
    public func parsed(
        fromURL url: URL,
        passphrase: String? = nil
    ) throws -> Result {
        let contents = try String(contentsOf: url)
        return try parsed(
            fromContents: contents,
            passphrase: passphrase,
            originalURL: url
        )
    }

    /// Parses a configuration from a string.
    ///
    /// - Parameters:
    ///   - contents: The contents of the configuration file.
    ///   - passphrase: The optional passphrase for encrypted data.
    ///   - originalURL: The optional original URL of the configuration file.
    /// - Returns: The ``Result`` outcome of the parsing.
    /// - Throws: If the configuration file is wrong or incomplete.
    public func parsed(
        fromContents contents: String,
        passphrase: String? = nil,
        originalURL: URL? = nil
    ) throws -> Result {
        let lines = contents.trimmedLines()
        return try parsed(
            fromLines: lines,
            isClient: true,
            passphrase: passphrase,
            originalURL: originalURL
        )
    }

    /// Parses a configuration from an array of lines.
    ///
    /// - Parameters:
    ///   - lines: The array of lines holding the configuration.
    ///   - isClient: Enables additional checks for client configurations.
    ///   - passphrase: The optional passphrase for encrypted data.
    ///   - originalURL: The optional original URL of the configuration file.
    /// - Returns: The ``Result`` outcome of the parsing.
    /// - Throws: If the configuration file is wrong or incomplete.
    public func parsed(
        fromLines lines: [String],
        isClient: Bool = false,
        passphrase: String? = nil,
        originalURL: URL? = nil
    ) throws -> Result {
        try privateParsed(
            fromLines: lines,
            isClient: isClient,
            passphrase: passphrase,
            originalURL: originalURL
        )
    }
}

private extension StandardOpenVPNParser {
    func privateParsed(
        fromLines lines: [String],
        isClient: Bool = false,
        passphrase: String? = nil,
        originalURL: URL? = nil
    ) throws -> Result {
        var builder = Builder(decrypter: decrypter)
        var isUnknown = true
        for line in lines {
            guard let result = Option.parsed(in: line) else {
                builder.putLine(line)
                continue
            }
            try builder.putOption(result.option, line: line, components: result.components)
            isUnknown = false
        }
        guard !isUnknown else {
            throw StandardOpenVPNParserError.invalidFormat
        }
        let result = try builder.build(isClient: isClient, passphrase: passphrase)
        return Result(
            url: originalURL,
            configuration: result.configuration,
            warning: result.warning
        )
    }
}

private extension String {
    func trimmedLines() -> [String] {
        components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s", with: " ", options: .regularExpression)
            }
            .filter {
                !$0.isEmpty
            }
    }
}

// MARK: - ConfigurationDecoder

extension StandardOpenVPNParser: ConfigurationDecoder {
    public func configuration(from string: String) throws -> OpenVPN.Configuration {
        try parsed(fromContents: string).configuration
    }
}

// MARK: - ModuleImporter

extension StandardOpenVPNParser: ModuleImporter {
    public func module(fromContents contents: String, object: Any?) throws -> Module {
        do {
            let passphrase = object as? String
            let result = try parsed(fromContents: contents, passphrase: passphrase)
            let builder = OpenVPNModule.Builder(configurationBuilder: result.configuration.builder())
            return try builder.tryBuild()
        } catch let error as StandardOpenVPNParserError {
            switch error {
            case .encryptionPassphrase:
                throw PassepartoutError(.OpenVPN.passphraseRequired)
            case .invalidFormat:
                throw PassepartoutError(.unknownImportedModule)
            default:
                throw error.asPassepartoutError
            }
        } catch {
            throw PassepartoutError(.parsing, error)
        }
    }
}
