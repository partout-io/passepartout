// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

extension ProfileEditor {
    public func load(_ profile: EditableProfile, isShared: Bool) {
        editableProfile = profile
        self.isShared = isShared
        removedModules = [:]
    }

    public func save(
        to profileObservable: ProfileObservable?,
        buildingWith observable: ModulesObservable,
        verifyingWith iapObservable: IAPObservable?,
        preferencesManager: PreferencesManager
    ) async throws -> ABI.AppProfile {
        let profileToSave = ABI.AppProfile(native: try buildAndUpdate(with: observable))

        // Verify profile (optional)
        if let iapObservable, !iapObservable.isBeta {
            do {
                try iapObservable.verify(profileToSave, extra: extraFeatures)
            } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {

                // still loading receipt
                guard !iapObservable.isLoadingReceipt else {
                    throw ABI.AppError.verificationReceiptIsLoading
                }

                // purchase required
                guard requiredFeatures.isEmpty else {
                    throw ABI.AppError.verificationRequiredFeatures(requiredFeatures)
                }
            }
        }

        // Persist (optional)
        try await profileObservable?.save(profileToSave, sharingFlag: isShared ? .shared : nil)

        // Clean up module preferences
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

    @available(*, deprecated, message: "#1594")
    public func legacySave(
        to profileManager: ProfileManager?,
        buildingWith registry: Registry,
        verifyingWith iapManager: IAPManager?,
        preferencesManager: PreferencesManager
    ) async throws -> Profile {
        let profileToSave = try buildAndUpdate(with: registry)

        // verify profile (optional)
        if let iapManager, !iapManager.isBeta {
            do {
                try iapManager.verify(profileToSave, extra: extraFeatures)
            } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {

                // still loading receipt
                guard !iapManager.isLoadingReceipt else {
                    throw ABI.AppError.verificationReceiptIsLoading
                }

                // purchase required
                guard requiredFeatures.isEmpty else {
                    throw ABI.AppError.verificationRequiredFeatures(requiredFeatures)
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
    var extraFeatures: Set<ABI.AppFeature> {
        var list: Set<ABI.AppFeature> = []
        if isShared {
            list.insert(.sharing)
            if isAvailableForTV {
                list.insert(.appleTV)
            }
        }
        return list
    }
}
