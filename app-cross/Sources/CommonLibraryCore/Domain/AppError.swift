// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum AppError: Error {
        case corruptProviderModule(reason: Error?)

        case couldNotLaunch(reason: Error)

        case emptyProducts

        case emptyProfileName

        case encoding(reason: Error? = nil)

        case importError(message: String? = nil)

        case incompatibleModules([Module])

        case incompleteModule(ModuleBuilder)

        case ineligibleProfile(Set<AppFeature>)

        case interactiveLogin

        case invalidField(stringKey: String?)

        case malformedModule(any ModuleBuilder, error: Error)

        case missingProviderEntity

        case moduleRequiresConnection(any Module)

        case noActiveModules

        case notFound

        case openVPNPassphraseRequired

        case openVPNUnsupportedCompression(option: String?)

        case other(Error?)

        case partout(PartoutError)

        case permissionDenied

        case rateLimit

        case systemExtension(ExtensionInstallerResult)

        case timeout

        case unexpectedResponse

        case urlRequestFailed(reason: Error?)

        case urlRequestUnavailable

        case verificationReceiptIsLoading

        case verificationRequiredFeatures(Set<AppFeature>)

        case webReceiver(Error? = nil)

        case webUploader(Int?, Error?)

        case wireGuardEmptyPeers

        public init(_ error: Error) {
            if let spError = error as? AppError {
                self = spError
            } else if let partoutError = error as? PartoutError {
                // Specialize some codes
                switch partoutError.code {
                case .incompatibleModules:
                    let modules = partoutError.userInfo as? [Module] ?? []
                    self = .incompatibleModules(modules)
                case .incompleteModule:
                    guard let builder = partoutError.userInfo as? any ModuleBuilder else {
                        assertionFailure("Missing ModuleBuilder from .incompleteModule userInfo")
                        self = .partout(partoutError)
                        return
                    }
                    self = .incompleteModule(builder)
                case .invalidField:
                    guard let field = partoutError.userInfo as? PartoutError.ModuleField else {
                        self = .invalidField(stringKey: nil)
                        return
                    }
                    let stringKey = "errors.modules.\(field.key)"
                    self = .invalidField(stringKey: stringKey)
                case .noActiveModules:
                    self = .noActiveModules
                case .OpenVPN.passphraseRequired:
                    self = .openVPNPassphraseRequired
                case .OpenVPN.unsupportedCompression:
                    let option = partoutError.userInfo as? String
                    self = .openVPNUnsupportedCompression(option: option)
                case .parsing:
                    let message = partoutError.userInfo as? String ??
                        (partoutError.reason as? LocalizedError)?.localizedDescription
                    self = .importError(message: message)
                case .Providers.corruptModule:
                    let reason = partoutError.reason
                    self = .corruptProviderModule(reason: reason)
                case .Providers.missingEntity:
                    self = .missingProviderEntity
                case .timeout:
                    self = .timeout
                case .unhandled:
                    self = .other(partoutError.reason)
                case .unknownImportedModule:
                    self = .importError()
                case .WireGuard.emptyPeers:
                    self = .wireGuardEmptyPeers
                default:
                    self = .partout(partoutError)
                }
            } else {
                self = .other(error)
            }
        }
    }
}

extension PartoutError.Code {
    public enum App {
        public static let ineligibleProfile = PartoutError.Code("App.ineligibleProfile")

        public static let multipleTunnels = PartoutError.Code("App.multipleTunnels")
    }
}
