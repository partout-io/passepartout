// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: ProfileProcessor

final class DefaultProfileProcessor: ProfileProcessor, Sendable {
    private let iapManager: IAPManager?

    init(iapManager: IAPManager?) {
        self.iapManager = iapManager
    }

    func isIncluded(_ profile: Profile) -> Bool {
#if os(tvOS)
        profile.attributes.isAvailableForTV == true
#else
        true
#endif
    }

    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>? {
        do {
            try iapManager?.verify(profile)
            return nil
        } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {
            return requiredFeatures
        } catch {
            return nil
        }
    }
}

// MARK: - AppTunnelProcessor

final class DefaultAppTunnelProcessor: AppTunnelProcessor, Sendable {
    private let profileRepository: ProfileRepository
    private let extensionInstaller: ExtensionInstaller?

    init(
        profileRepository: ProfileRepository,
        extensionInstaller: ExtensionInstaller?
    ) {
        self.profileRepository = profileRepository
        self.extensionInstaller = extensionInstaller
    }

    nonisolated func willInstall(
        _ preProfile: Profile,
        connect: Bool,
        force: Bool
    ) async throws -> Profile? {
        var profile = preProfile

        // Trigger user input if profile is interactive
        if connect {
            guard !profile.isInteractive || force else {
                throw ABI.AppError.interactiveLogin
            }
        }

        // Install extension before proceeding
        if let extensionInstaller {
            if extensionInstaller.currentResult == .success {
                pspLog(.core, .info, "Extensions: already installed")
            } else {
                pspLog(.core, .info, "Extensions: install...")
                do {
                    let result = try await extensionInstaller.install()
                    switch result {
                    case .success:
                        break
                    default:
                        throw ABI.AppError.systemExtension(result)
                    }
                    pspLog(.core, .info, "Extensions: installation result is \(result)")
                } catch {
                    pspLog(.core, .error, "Extensions: installation error: \(error)")
                }
            }
        }

        // Persist the effective profile before installing or connecting
        try await profileRepository.persistProfile(profile)

        // Return processed profile
        return profile
    }
}
