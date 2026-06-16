// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

package com.algoritmico.passepartout.strategy

import android.util.Log
import com.algoritmico.passepartout.extensions.Globals
import com.algoritmico.passepartout.managers.VersionCheckerRateLimitException
import com.algoritmico.passepartout.managers.VersionCheckerStrategy
import com.algoritmico.passepartout.managers.VersionCheckerUnexpectedResponseException
import com.algoritmico.passepartout.managers.toSemanticVersionOrNull
import com.algoritmico.passepartout.models.SemanticVersion
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

class GitHubReleaseStrategy(
    private val logTag: String,
    private val releaseURL: String,
    private val rateLimit: Double,
    private val fetcher: suspend (String) -> ByteArray
) : VersionCheckerStrategy {
    override suspend fun latestVersion(sinceTimestamp: Long?): SemanticVersion {
        if (sinceTimestamp != null) {
            val elapsed = (System.currentTimeMillis() - sinceTimestamp) / 1000.0
            if (elapsed < rateLimit) {
                Log.d(logTag, "Version (GitHub): elapsed $elapsed < $rateLimit")
                throw VersionCheckerRateLimitException()
            }
        }
        val data = fetcher(releaseURL)
        val json = Globals.json.decodeFromString<VersionJSON>(data.decodeToString())
        val newVersion = json.name
        val semanticVersion = newVersion.toSemanticVersionOrNull()
        if (semanticVersion == null) {
            Log.e(logTag, "Version (GitHub): unparsable release name '$newVersion'")
            throw VersionCheckerUnexpectedResponseException()
        }
        return semanticVersion
    }

    @Serializable
    private data class VersionJSON(
        @SerialName("name")
        val name: String,

        @SerialName("tag_name")
        val tagName: String? = null
    )
}
