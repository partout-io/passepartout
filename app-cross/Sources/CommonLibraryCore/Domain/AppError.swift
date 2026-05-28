// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum AppError: Error {
        case couldNotLaunch(reason: Error)

        case emptyProducts

        case emptyProfileName

        case encoding(reason: Error? = nil)

        case importError

        case incompatibleModules([Module])

        case incompleteModule(ModuleBuilder)

        case ineligibleProfile(Set<AppFeature>)

        case interactiveLogin

        case malformedModule(any ModuleBuilder, error: Error)

        case missingProviderEntity

        case moduleRequiresConnection(any Module)

        case noActiveModules

        case notFound

        case openVPNPassphraseRequired

        case other(Error)

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
                case .OpenVPN.passphraseRequired:
                    self = .openVPNPassphraseRequired
                case .Providers.missingEntity:
                    self = .missingProviderEntity
                case .unknownImportedModule:
                    self = .importError
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
