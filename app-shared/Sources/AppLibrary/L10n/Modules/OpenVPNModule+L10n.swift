// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import Foundation

extension OpenVPN.PullMask: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .routes:
            return Strings.Global.Nouns.routes

        case .dns:
            return Strings.Unlocalized.dns

        case .proxy:
            return Strings.Unlocalized.proxy

        @unknown default:
            return ""
        }
    }
}

extension OpenVPN.Cipher: LocalizableEntity {
    public var localizedDescription: String {
        description
    }
}

extension OpenVPN.Digest: LocalizableEntity {
    public var localizedDescription: String {
        description
    }
}

extension OpenVPN.CompressionFraming: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .disabled:
            return Strings.Global.Nouns.disabled

        case .compLZO:
            return Strings.Unlocalized.OpenVPN.compLZO

        case .compress, .compressV2:
            return Strings.Unlocalized.OpenVPN.compress

        @unknown default:
            return Strings.Global.Nouns.unknown
        }
    }
}

extension OpenVPN.CompressionAlgorithm: LocalizableEntity {
    public var localizedDescription: String {
        switch self {
        case .disabled:
            return Strings.Global.Nouns.disabled

        case .LZO:
            return Strings.Unlocalized.OpenVPN.lzo

        case .other:
            return Strings.Entities.Openvpn.CompressionAlgorithm.other

        @unknown default:
            return Strings.Global.Nouns.unknown
        }
    }
}

extension OpenVPN.ObfuscationMethod: StyledLocalizableEntity {
    public enum Style {
        case short

        case long
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .short:
            return shortDescription

        case .long:
            return longDescription
        }
    }

    private var shortDescription: String {
        let V = Strings.Unlocalized.OpenVPN.XOR.self
        switch self {
        case .xormask:
            return V.xormask.rawValue

        case .xorptrpos:
            return V.xorptrpos.rawValue

        case .reverse:
            return V.reverse.rawValue

        case .obfuscate:
            return V.obfuscate.rawValue

        @unknown default:
            return ""
        }
    }

    private var longDescription: String {
        switch self {
        case .xormask(let mask):
            return "\(shortDescription) \(mask.toHex())"

        case .obfuscate(let mask):
            return "\(shortDescription) \(mask.toHex())"

        default:
            return shortDescription
        }
    }
}

extension OpenVPN.Configuration.Builder: StyledLocalizableEntity {
    public enum Style {
        case tlsWrap

        case eku
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .tlsWrap:
            return tlsWrap.tlsWrapDescription

        case .eku:
            return checksEKU.ekuDescription
        }
    }
}

extension OpenVPN.Configuration.Builder: StyledOptionalLocalizableEntity {
    public enum OptionalStyle {
        case keepAlive

        case keepAliveTimeout

        case renegotiatesAfter

        case randomizeEndpoint

        case randomizeHostnames
    }

    public func localizedDescription(optionalStyle: OptionalStyle) -> String? {
        switch optionalStyle {
        case .keepAlive:
            return keepAliveInterval?.localizedDescription(style: .timeString)

        case .keepAliveTimeout:
            return keepAliveTimeout?.localizedDescription(style: .timeString)

        case .renegotiatesAfter:
            return renegotiatesAfter?.localizedDescription(style: .timeString)

        case .randomizeEndpoint:
            return randomizeEndpoint?.randomizeEndpointDescription

        case .randomizeHostnames:
            return randomizeHostnames?.randomizeHostnamesDescription
        }
    }
}

// MARK: - Raw types

private extension Optional where Wrapped == OpenVPN.TLSWrap {
    var tlsWrapDescription: String {
        guard let strategy = self?.strategy else {
            return Strings.Global.Nouns.disabled
        }
        switch strategy {
        case .auth:
            return "--tls-auth"
        case .crypt:
            return "--tls-crypt"
        @unknown default:
            return ""
        }
    }
}

private extension Optional where Wrapped == Bool {
    var ekuDescription: String {
        let V = Strings.Global.Nouns.self
        return (self ?? false) ? V.enabled : V.disabled
    }
}

private extension Bool {
    var randomizeEndpointDescription: String {
        let V = Strings.Global.Nouns.self
        return self ? V.enabled : V.disabled
    }

    var randomizeHostnamesDescription: String {
        let V = Strings.Global.Nouns.self
        return self ? V.enabled : V.disabled
    }
}
