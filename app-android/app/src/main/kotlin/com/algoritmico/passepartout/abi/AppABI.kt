// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import com.algoritmico.passepartout.Globals
import com.algoritmico.passepartout.abi.helpers.ABIResult
import com.algoritmico.passepartout.abi.models.AppPreferences
import io.partout.models.TaggedProfile

class AppABIProfile(
    private val library: PassepartoutWrapper
) : AppABIProfileProtocol {
    override suspend fun importText(text: String, filename: String) {
        ABIResult.await { completion ->
            library.appImportProfileText(text, filename, completion)
        }
    }

    override suspend fun remove(profileId: String) {
        ABIResult.await { completion ->
            library.appDeleteProfile(profileId, completion)
        }
    }

    override suspend fun remove(profileIds: Collection<String>) {
        ABIResult.await { completion ->
            library.appDeleteProfiles(profileIds.toTypedArray(), completion)
        }
    }

    override suspend fun profile(profileId: String): TaggedProfile? {
        val result = ABIResult.await { completion ->
            library.appFetchProfile(profileId, completion)
        }
        return result.payload?.let { json ->
            Globals.json.decodeFromString(json)
        }
    }
}

class AppABIKeyStore(
    private val library: PassepartoutWrapper
) : AppABIKeyStoreProtocol {
    override fun set(preferences: AppPreferences) {
        val json = Globals.json.encodeToString(preferences)
        library.appPreferencesSet(json)
    }
}
