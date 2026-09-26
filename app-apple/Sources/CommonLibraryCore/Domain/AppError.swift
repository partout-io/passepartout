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

        case moduleRequiresConnection(any Module)

        case multipleTunnels

        case noActiveModules

        case notFound

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

        public init(_ error: Error) {
            if let spError = error as? AppError {
                self = spError
            } else if let partoutError = error as? PartoutError {
                // Specialize some codes
                switch partoutError.code {
                case .incompatibleModules:
                    guard case .incompatibleModules(let modules) = partoutError.context else {
                        self = .partout(partoutError)
                        return
                    }
                    self = .incompatibleModules(modules)
                case .incompleteModule:
                    guard case .incompleteModule(let builder) = partoutError.context else {
                        self = .partout(partoutError)
                        return
                    }
                    self = .incompleteModule(builder)
                case .invalidField:
                    guard case .invalidField(let field) = partoutError.context else {
                        self = .invalidField(stringKey: nil)
                        return
                    }
                    let stringKey = "errors.modules.\(field.key)"
                    self = .invalidField(stringKey: stringKey)
                case .noActiveModules:
                    self = .noActiveModules
                case .timeout:
                    self = .timeout
                case .unhandled:
                    self = partoutError.payload != nil ? .partout(partoutError) : .other(partoutError.reason)
                case .unknownImportedModule:
                    self = .importError()
                default:
                    // Keep .parsing wrapped to preserve ParseErrorInfo for localization and passphrase handling.
                    self = .partout(partoutError)
                }
            } else {
                self = .other(error)
            }
        }
    }
}

extension ABI.AppError {
    public var code: ABI.AppErrorCode {
        switch self {
        case .binaryFile:
            return .binaryFile
        case .corruptProviderModule:
            return .corruptProviderModule
        case .couldNotLaunch:
            return .couldNotLaunch
        case .emptyProducts:
            return .emptyProducts
        case .emptyProfileName:
            return .emptyProfileName
        case .encoding:
            return .encoding
        case .importError:
            return .importError
        case .incompatibleModules:
            return .incompatibleModules
        case .incompleteModule:
            return .incompleteModule
        case .ineligibleProfile:
            return .ineligibleProfile
        case .interactiveLogin:
            return .interactiveLogin
        case .invalidField:
            return .invalidField
        case .malformedModule:
            return .malformedModule
        case .moduleRequiresConnection:
            return .moduleRequiresConnection
        case .multipleTunnels:
            return .multipleTunnels
        case .noActiveModules:
            return .noActiveModules
        case .notFound:
            return .notFound
        case .other:
            return .other
        case .partout:
            return .partout
        case .permissionDenied:
            return .permissionDenied
        case .rateLimit:
            return .rateLimit
        case .systemExtension:
            return .systemExtension
        case .timeout:
            return .timeout
        case .unexpectedResponse:
            return .unexpectedResponse
        case .urlRequestFailed:
            return .urlRequestFailed
        case .urlRequestUnavailable:
            return .urlRequestUnavailable
        case .verificationReceiptIsLoading:
            return .verificationReceiptIsLoading
        case .verificationRequiredFeatures:
            return .verificationRequiredFeatures
        case .webReceiver:
            return .webReceiver
        case .webUploader:
            return .webUploader
        }
    }
}

extension ABI.AppErrorCode {
    public static func fromLastErrorCode(_ string: String) -> Self? {
        let comps = string.split(separator: ".")
        guard comps.count == 2 else { return nil }
        guard comps[0] == "App" else { return nil }
        return Self.init(rawValue: String(comps[1]))
    }

    public var toLastErrorCode: String {
        "App.\(rawValue)"
    }
}
