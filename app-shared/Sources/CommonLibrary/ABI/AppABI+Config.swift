// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension AppABI {

    // Build a file-based configuration applier for the given path, or nil if the
    // format is unsupported. The file need not exist yet: loadAndApply() no-ops
    // when it is absent, so a file created after this point is still picked up on
    // the next apply.
    //
    // Platform-neutral: the core applier lives in CommonLibraryCore. Preferences
    // are applied via AppPreferencesStore.request(), which commits directly to
    // the backend.
    static func makeConfigFileApplier(
        configFilePath: String,
        preferences: AppPreferencesStore,
        profileManager: ProfileManager
    ) -> ConfigFileApplier? {
        guard let provider = try? ConfigProviderFactory.provider(forFileAtPath: configFilePath) else {
            return nil
        }
        return ConfigFileApplier(
            filePath: configFilePath,
            provider: provider,
            customHandler: ABI.AppConfiguration.customModuleHandler,
            applyPreferences: { prefs in
                preferences.overwrite {
                    // Overwrite every field unconditionally so the file is the
                    // source of truth; an absent value clears the preference.
                    $0.dnsFallsBack = prefs.dnsFallsBack
                    $0.extensiveLogging = prefs.extensiveLogging
                    $0.experimental = prefs.experimental
                    $0.logsPrivateData = prefs.logsPrivateData
                    $0.relaxedVerification = prefs.relaxedVerification
                    $0.skipsPurchases = prefs.skipsPurchases
                    $0.lastUsedProfileId = prefs.lastUsedProfileId
                }
            },
            saveProfile: { profile in
                try await profileManager.save(profile, isLocal: true, remotelyShared: nil)
            }
        )
    }
}
