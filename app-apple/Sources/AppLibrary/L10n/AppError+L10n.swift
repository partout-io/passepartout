// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppStrings
import CommonLibrary
import Foundation

// MARK: App errors

extension ABI.AppError: StyledLocalizableEntity {
    public enum Style {
        case errorHandler
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .errorHandler:
            return forErrorHandler ?? Strings.Errors.App.other
        }
    }

    private var forErrorHandler: String? {
        let V = Strings.Errors.App.self
        switch self {
        case .binaryFile:
            return V.Import.binary
        case .corruptProviderModule(let reason):
            return V.corruptProviderModule(
                reason?.appLocalizedDescription ?? "?"
            )
        case .couldNotLaunch(let reason):
            return reason.localizedDescription
        case .emptyProducts:
            return V.emptyProducts
        case .emptyProfileName:
            return V.emptyProfileName
        case .encoding(let reason):
            return reason?.localizedDescription
        case .importError(let message):
            return V.parsing.appending(message, separator: " ")
        case .incompatibleModules:
            return V.incompatibleModules
        case .incompleteModule(let builder):
            return V.incompleteModule(builder.moduleType.localizedDescription)
        case .ineligibleProfile:
            return nil
        case .interactiveLogin:
            return nil
        case .invalidField(let stringKey):
            guard let stringKey else {
                return Strings.Errors.Modules.generic
            }
            return AppStrings.bundle.localizedString(forKey: stringKey, value: nil, table: nil)
        case .malformedModule(let module, let reason):
            return V.malformedModule(
                module.moduleType.localizedDescription,
                reason.appLocalizedDescription
            )
        case .missingProviderEntity:
            return V.missingProviderEntity
        case .missingProviderOption:
            // Should not happen, thrown by WireGuard providers (disabled)
            return nil
        case .moduleRequiresConnection(let module):
            return V.moduleRequiresConnection(
                module.moduleType.localizedDescription,
                ModuleType.connectionTypes
                    .map(\.localizedDescription)
                    .joined(separator: ", ")
            )
        case .multipleTunnels:
            // Should never happen in app (thrown by TunnelABI)
            return nil
        case .noActiveModules:
            return V.noActiveModules
        case .notFound:
            // Typically asserts
            return nil
        case .openVPNPassphraseRequired:
            // Handled manually
            return nil
        case .openVPNUnsupportedCompression(let option):
            return V.Openvpn.unsupportedCompression.appending(option, separator: "\n\n")
        case .other(let error):
            return V.other.appending(error?.localizedDescription, separator: " ")
        case .partout(let error):
            return V.partout(error.code.rawValue)
        case .permissionDenied:
            return V.permissionDenied
        case .rateLimit:
            // Handled manually
            return nil
        case .systemExtension:
            assertionFailure("ABI.AppError.systemExtension should be handled in AppCoordinator")
            return nil
        case .timeout:
            return V.timeout
        case .unexpectedResponse:
            // Handled manually
            return nil
        case .urlRequestUnavailable, .urlRequestFailed:
            return nil
        case .verificationReceiptIsLoading, .verificationRequiredFeatures:
            // Handled manually
            return nil
        case .webReceiver:
            return V.webReceiver
        case .webUploader(let status, let error):
            switch status {
            case 403:
                return Strings.WebUploader.Errors.incorrectPasscode
            case 404:
                return Strings.WebUploader.Errors.urlNotFound
            default:
                return error?.localizedDescription
            }
        case .wireGuardEmptyPeers:
            return V.Wireguard.emptyPeers
        }
    }
}

extension ABI.AppErrorCode: StyledLocalizableEntity {
    public enum Style {
        case connectionStatus
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .connectionStatus:
            let V = Strings.Errors.App.self
            switch self {
            case .ineligibleProfile:
                return V.ineligible
            default:
                return V.other
            }
        }
    }
}

extension ABI.AppError: @retroactive LocalizedError {
    public var errorDescription: String? {
        forErrorHandler
    }
}

private extension String {
    func appending(_ optional: String?, separator: String) -> String {
        [self, optional]
            .compactMap { $0 }
            .joined(separator: separator)
    }
}

private extension Error {
    var appLocalizedDescription: String {
        switch self {
        case let error as ABI.AppError:
            return error.localizedDescription
        case let error as PartoutError:
            return ABI.AppError(error).localizedDescription
        default:
            return localizedDescription
        }
    }
}

// MARK: - Partout errors

extension PartoutError.Code: StyledLocalizableEntity {
    public enum Style {
        case connectionStatus
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .connectionStatus:
            let V = Strings.Errors.Tunnel.self
            switch self {
            case .authentication:
                return V.auth
            case .crypto:
                return V.encryption
            case .dnsFailure:
                return V.dns
            case .timeout:
                return Strings.Global.Nouns.timeout
            case .openVPNCompressionMismatch:
                return V.compression
            case .openVPNNoRouting:
                return V.routing
            case .openVPNRecoverableAuthentication:
                return Strings.Entities.TunnelStatus.activating
            case .openVPNServerShutdown:
                return V.shutdown
            case .openVPNTLSFailure:
                return V.tls
            default:
                return V.generic
            }
        }
    }
}
