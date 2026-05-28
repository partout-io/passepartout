// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1696, Wrap PartoutError
import Partout

extension ABI {
    public enum AppError: Error {
        case couldNotLaunch(reason: Error)

        case emptyProducts

        case emptyProfileName

        case encoding(reason: Error? = nil)

        case importError

        case ineligibleProfile(Set<AppFeature>)

        case interactiveLogin

        case malformedModule(any ModuleBuilder, error: Error)

        case missingProviderEntity

        case moduleRequiresConnection(any Module)

        case noActiveModules

        case notFound

        case other(Error)

        case partout(PartoutError)

        case permissionDenied

        case profileNotFound

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
                self = .partout(partoutError)
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
