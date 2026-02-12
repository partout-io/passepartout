// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

// FIXME: #1678, Wrap PartoutError
import Partout

extension ABI {
    public enum AppError: Error {
        case couldNotLaunch(reason: Error)

        case emptyProducts

        case emptyProfileName

        case ineligibleProfile(Set<AppFeature>)

        case interactiveLogin

        case malformedModule(any ModuleBuilder, error: Error)

        case missingProviderEntity

        case moduleRequiresConnection(any Module)

        case notFound

        case partout(PartoutError)

        case permissionDenied

        case rateLimit

        case systemExtension(ExtensionInstallerResult)

        case timeout

        case unexpectedResponse

        case unknown

        case verificationReceiptIsLoading

        case verificationRequiredFeatures(Set<AppFeature>)

        case webReceiver(Error? = nil)

        case webUploader(Int?, Error?)

        public init(_ error: Error) {
            if let spError = error as? AppError {
                self = spError
            } else {
                self = .partout(PartoutError(error))
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
