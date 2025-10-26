// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ProfileEditor {
    public func load(_ profile: EditableProfile, isShared: Bool) {
        editableProfile = profile
        self.isShared = isShared
        removedModules = [:]
    }

    public func save(
        to profileManager: ProfileManager?,
        buildingWith registry: Registry,
        verifyingWith iapManager: IAPManager?,
        preferencesManager: PreferencesManager
    ) async throws -> Profile {
        let profileToSave = try build(with: registry)

        // verify profile (optional)
        if let iapManager, !iapManager.isBeta {
            do {
                try iapManager.verify(profileToSave, extra: extraFeatures)
            } catch AppError.ineligibleProfile(let requiredFeatures) {

                // still loading receipt
                guard !iapManager.isLoadingReceipt else {
                    throw AppError.verificationReceiptIsLoading
                }

                // purchase required
                guard requiredFeatures.isEmpty else {
                    throw AppError.verificationRequiredFeatures(requiredFeatures)
                }
            }
        }

        // persist (optional)
        try await profileManager?.save(profileToSave, isLocal: true, remotelyShared: isShared)

        // clean up module preferences
        removedModules.keys.forEach {
            do {
                pp_log_g(.App.profiles, .info, "Erase preferences for removed module \($0)")
                let repository = try preferencesManager.preferencesRepository(forModuleWithId: $0)
                repository.erase()
                try repository.save()
            } catch {
                pp_log_g(.App.profiles, .error, "Unable to erase preferences for removed module \($0): \(error)")
            }
        }
        removedModules.removeAll()

        return profileToSave
    }
}

private extension ProfileEditor {
    var extraFeatures: Set<AppFeature> {
        var list: Set<AppFeature> = []
        if isShared {
            list.insert(.sharing)
            if isAvailableForTV {
                list.insert(.appleTV)
            }
        }
        return list
    }
}
