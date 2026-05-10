// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.abi

import com.algoritmico.passepartout.abi.helpers.awaitCompletion
import io.partout.abi.TaggedProfile

internal class AppABIProfile(
    private val library: PassepartoutWrapper
) : AppABIProfileProtocol {
    override suspend fun importText(text: String, filename: String) {
        awaitCompletion { completion ->
            library.appImportProfileText(text, filename, completion)
        }
    }

    override suspend fun remove(profileId: String) {
        awaitCompletion { completion ->
            library.appDeleteProfile(profileId, completion)
        }
    }

    override suspend fun remove(profileIds: Collection<String>) {
        awaitCompletion { completion ->
            library.appDeleteProfiles(profileIds.toTypedArray(), completion)
        }
    }

    override fun profile(profileId: String): TaggedProfile? {
        // FIXME: Implement through C/JNI App ABI.
        return null
    }
}
