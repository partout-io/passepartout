// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppStrings
import CommonLibrary
import Foundation

// MARK: ErrorHandler

// Typically displayed in ErrorHandler
extension ABI.AppError: @retroactive LocalizedError {
    public var errorDescription: String? {
        let V = Strings.Errors.App.self
        switch self {
        case .corruptProviderModule(let reason):
            return V.corruptProviderModule(reason?.localizedDescription ?? "?")
        case .couldNotLaunch(let reason):
            return reason.localizedDescription
        case .emptyProducts:
            return V.emptyProducts
        case .emptyProfileName:
            return V.emptyProfileName
        case .encoding(let reason):
            return reason?.localizedDescription
        case .importError(let message):
            return [V.parsing, message]
                .compactMap { $0 }
                .joined(separator: " ")
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
        case .malformedModule(let module, let error):
            return V.malformedModule(module.moduleType.localizedDescription, error.localizedDescription)
        case .missingProviderEntity:
            return V.missingProviderEntity
        case .moduleRequiresConnection(let module):
            return V.moduleRequiresConnection(
                module.moduleType.localizedDescription,
                ModuleType.connectionTypes
                    .map(\.localizedDescription)
                    .joined(separator: ", ")
            )
        case .noActiveModules:
            return V.noActiveModules
        case .notFound:
            // Typically asserts
            return nil
        case .openVPNPassphraseRequired:
            // Handled manually
            return nil
        case .openVPNUnsupportedCompression(let option):
            return [V.Openvpn.unsupportedCompression, option]
                .compactMap { $0 }
                .joined(separator: "\n\n")
        case .other(let error):
            return [V.other, error?.localizedDescription]
                .compactMap { $0 }
                .joined(separator: " ")
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

// MARK: - Tunnel errors

extension PartoutError.Code: StyledLocalizableEntity {
    public enum Style {
        case tunnel // Displayed in ConnectionStatusText
    }

    public func localizedDescription(style: Style) -> String {
        switch style {
        case .tunnel:
            let V = Strings.Errors.Tunnel.self
            switch self {
            case .App.ineligibleProfile:
                return V.ineligible
            case .authentication:
                return V.auth
            case .crypto:
                return V.encryption
            case .dnsFailure:
                return V.dns
            case .timeout:
                return Strings.Global.Nouns.timeout
            case .OpenVPN.compressionMismatch:
                return V.compression
            case .OpenVPN.noRouting:
                return V.routing
            case .OpenVPN.recoverableAuthentication:
                return Strings.Entities.TunnelStatus.activating
            case .OpenVPN.serverShutdown:
                return V.shutdown
            case .OpenVPN.tlsFailure:
                return V.tls
            default:
                return V.generic
            }
        }
    }
}
