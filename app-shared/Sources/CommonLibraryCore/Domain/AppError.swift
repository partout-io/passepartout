// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum AppError: Error {
        case binaryFile

        case corruptProviderModule(reason: Error?)

        case couldNotLaunch(reason: Error)

        case emptyProducts

        case emptyProfileName

        case encoding(reason: Error? = nil)

        case importError(message: String? = nil)

        case incompatibleModules([Module])

        case incompleteModule(any ModuleBuilder)

        case ineligibleProfile(Set<AppFeature>)

        case interactiveLogin

        case invalidField(stringKey: String?)

        case malformedModule(any ModuleBuilder, reason: Error)

        case missingProviderEntity

        case missingProviderOption(String?)

        case moduleRequiresConnection(any Module)

        case multipleTunnels

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
            } else if let providerError = error as? PartoutProviderError {
                switch providerError {
                case .corruptModule(let reason):
                    self = .corruptProviderModule(reason: reason)
                case .missingEntity:
                    self = .missingProviderEntity
                case .missingOption(let option):
                    self = .missingProviderOption(option)
                }
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
                case .openVPNPassphraseRequired:
                    self = .openVPNPassphraseRequired
                case .openVPNUnsupportedCompression:
                    let option = partoutError.userInfo as? String
                    self = .openVPNUnsupportedCompression(option: option)
                case .parsing:
                    let message: String?
                    if let info = partoutError.userInfo as? String {
                        message = info
                    } else if let reason = partoutError.reason {
                        if let localizedReason = reason as? LocalizedError {
                            message = localizedReason.localizedDescription
                        } else {
                            message = String(describing: reason)
                        }
                    } else {
                        message = nil
                    }
                    self = .importError(message: message)
                case .timeout:
                    self = .timeout
                case .unhandled:
                    self = .other(partoutError.reason)
                case .unknownImportedModule:
                    self = .importError()
                case .wireGuardEmptyPeers:
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
