// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension AppABI {

    // Build a file-based configuration applier for the file at the given path,
    // or nil if the file does not exist or its format is unsupported.
    //
    // Platform-neutral: the core applier lives in CommonLibraryCore. Preferences
    // are applied via AppPreferencesStore.request(), which commits directly on
    // Apple and emits a "should update" event to the consumer on cross platforms.
    static func makeConfigFileApplier(
        configFilePath: String,
        preferences: AppPreferencesStore,
        profileManager: ProfileManager
    ) -> ConfigFileApplier? {
        guard FileManager.default.fileExists(atPath: configFilePath),
              let provider = try? ConfigProviderFactory.provider(forFileAtPath: configFilePath) else {
            return nil
        }
        return ConfigFileApplier(
            filePath: configFilePath,
            provider: provider,
            applyPreferences: { prefs in
                preferences.request(changesTo: [.relaxedVerification, .lastUsedProfileId]) {
                    $0.dnsFallsBack = prefs.dnsFallsBack
                    $0.extensiveLogging = prefs.extensiveLogging
                    $0.experimental = prefs.experimental
                    $0.logsPrivateData = prefs.logsPrivateData
                    $0.relaxedVerification = prefs.relaxedVerification
                    $0.skipsPurchases = prefs.skipsPurchases
                    if let id = prefs.lastUsedProfileId {
                        $0.lastUsedProfileId = id
                    }
                }
            },
            saveProfile: { profile in
                try await profileManager.save(profile, isLocal: true, remotelyShared: nil)
            }
        )
    }
}
