// SPDX-FileCopyrightText: 2026 Davide De Rosa
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
        to profileObservable: ProfileObservable?,
        buildingWith registryObservable: RegistryObservable,
        verifyingWith iapObservable: IAPObservable?,
        preferencesManager: PreferencesManager
    ) async throws -> Profile {
        let profileToSave = try buildAndUpdate(with: registryObservable)

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
                pspLog(.profiles, .info, "Erase preferences for removed module \($0)")
                let repository = try preferencesManager.preferencesRepository(forModuleWithId: $0)
                repository.erase()
                try repository.save()
            } catch {
                pspLog(.profiles, .error, "Unable to erase preferences for removed module \($0): \(error)")
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
